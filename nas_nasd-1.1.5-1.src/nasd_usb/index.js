'use strict';

function USB() {
    var USBCOPY_FOLDER = '/raid/data/USBCopy',
        BACKUP_FOLDER = '/raid/data/NAS_Public/USB_BACKUP',
        SYSCONF = new (require('Vendor')).Config(),
        PATCH_PREFIX = SYSCONF.data.patch_prefix,
        SD_READER;
    
    events.EventEmitter.call(this);
    
    var me = this,
        exec = require('child_process').exec,
        spawn = require('child_process').spawn,
        popen = require('child_process').popen,
        fs = require('fs'),
        path = require('path'),
        task = -1,
        queue = [],
        rsync;
    
    (function () {
        var Vendor = require('Vendor'),
            scsi2x = new Vendor.ScsiScsi();
        for (var i = 0 ; i < scsi2x.data.length ; ++i ) {
            if (scsi2x.data[i].Model === 'Card  Reader') {
                SD_READER = scsi2x.data[i].Disk;
                break;
            }
        }
    }());
    
    Nasd.Rpcd.on('discoveried', function() {
        rsync = new Nasd.Rsync();
        rsync.on('progress', onRsyncProgress);
        rsync.on('exit', processTaskQueue);
    });
    
    function onRsyncProgress(value) {
        queue[task].progress = value;
        me.emit('progress', queue);
    }
    
    function processTaskQueue(code) {
        task++;
        if (task > 0) {
            spawn('chown', ['nobody:nogroup', '-R', queue[task - 1].destnation]);
        }
        if (task < queue.length) {
            Nasd.History.insertLog({$action: 'USB Copy'});

            spawn('/img/bin/pic.sh', ['LCM_USB', 2, 0]);
            if (SD_READER && queue[task].dev.match(SD_READER)) {
                Nasd.Hardware.led.sd.blink();
            } else {
                Nasd.Hardware.led.u.blink();
            }
            
            rsync.copy(
                queue[task].source,
                queue[task].destnation,
                queue[task].option
            );
        } else {
            ejectDevice(code, queue[task-1].dev, queue[task -1].source);
            task = -1;
            queue.splice(0, queue.length);
            me.emit('finish');
        }
    }
    
    function checkProgress() {
        return queue;
    }
    
    function mountList(fn) {
        var child = spawn('mount'),
            data = '';
        
        child.stdout.setEncoding('utf8');
        child.stdout.on('data', function (out) {
            data = out.match(/(.*) on (.*USB.*) type (.*) \(.*\)/g);
            
            for (var i = 0 ; data && i < data.length ; ++i) {
                data[i] = data[i].match(/(.*) on (.*USB.*) type (.*) \(.*\)/);
                data[i] = {
                    dev: data[i][1],
                    path: data[i][2],
                    type: data[i][3]
                };

                if (existUSBPatchFile(data[i].dev, data[i].path)) {
                    return;
                }
            }
            
            if (fn && data) {
                spawn('/img/bin/pic.sh', ['LCM_USB', 2, 0]);
                fn(data);
            } else {
                spawn('/img/bin/pic.sh', ['LCM_USB', 5, 0]);
            }
        });
    }
    
    function generateTask(data) {
        var now = new Date().toJSON().replace(/[T]/g, ' ').replace(/[:Z]/g, ''),
            dst = path.join(BACKUP_FOLDER, now),
            stat;
        
        if (!fs.existsSync(BACKUP_FOLDER)) {
            fs.symlinkSync(USBCOPY_FOLDER, BACKUP_FOLDER);
            spawn('chown', ['nobody:nogroup', BACKUP_FOLDER]);
        }
        
        try {
            fs.mkdirSync(dst, '0755');
        } catch(e) {}
        spawn('chown', ['nobody:nogroup', dst]);
        
        stat = fs.lstatSync(BACKUP_FOLDER);
        if (stat.isDirectory() || stat.isSymbolicLink()) {
            for (var i = 0 ; i < data.length ; ++i) {
                var src = data[i].path.split('/');
                var dev = data[i].dev.split('/');
                    
                src.splice(5, src.length - 5);
                src = src.join('/');

                dev = dev[dev.length -1];

                queue.push({
                    source: src,
                    destnation: dst,
                    option: ['-a'],
                    progress: 0,
                    dev: dev
                });
            }
        }
        
        if (queue.length > 0) {
            me.emit('progress', queue);
        }
        
        processTaskQueue();
    }

    function existUSBPatchFile(dev,mount_path) {
        var cmd = format('ls %s | grep -E "^THECUS\\.%s\\.(FAC|FAC\\.md5|PATCH)$"', mount_path, PATCH_PREFIX),
            patch = popen(cmd).trim().split('\n');
        if (patch.length === 3) {
            (function copyPatch(){
                exec(format('mount %s /mnt', dev));
                exec(format('cp -rf %s /tmp/patch.sh', path.join(mount_path, patch[2])), execPatch);
                
                function execPatch(){
                    Nasd.Hardware.lcm.press.esc();
                    spawn('/img/bin/pic.sh', ['LCM_MSG', 'Patch Mode:', 'Patching...']);
                    exec('sh /tmp/patch.sh', cleanEnv);
                }
                
                function cleanEnv() {
                    var src = mount_path.split('/');
                    src.splice(5, src.length - 5);
                    src = src.join('/');
                    
                    spawn('/img/bin/pic.sh', ['LCM_USB', 3, 0]);
                    ejectDevice(999, dev, src);
                }
            }());
            return true;
        }
        return false;
    }

    function ejectDevice(code, dev, src) {
        (function doDiskSync() {
            exec('/bin/sync ; /bin/sync ; /bin/sync', finishDiskSync);
        }());
        
        function finishDiskSync() {
            spawn('umount', ['/mnt']);
            spawn('umount', [src]).on('exit', doEject);
        }
        
        function doEject() {
            spawn('eject', [dev]).on('exit', doRemoveTempFolder);
        }
        
        function doRemoveTempFolder() {
            exec(format('rmdir %s/* %s', src, src), cleanHardwareStatus(code, dev));
        }
    }
    
    function cleanHardwareStatus(code, dev) {
        Nasd.Hardware.led.off();
        switch (code) {//rsync return value
            case 0:
                spawn('/img/bin/pic.sh', ['LCM_USB', 3, 0]);
                spawn('/img/bin/logevent/event', [128]);
                break;
            case 999: //case for no rsync copy
                spawn('/img/bin/logevent/event', [322]);
                break;
            default: //case for return value is not zero
                spawn('/img/bin/pic.sh', ['LCM_USB', 4, 0]);
                spawn('/img/bin/logevent/event', [322]);
                if (SD_READER && dev.match(SD_READER)) {
                    Nasd.Hardware.led.sdf.on();
                } else {
                    Nasd.Hardware.led.uf.blink();
                }
                Nasd.Hardware.buzzer.on();
                
                setTimeout(turnOffAll, 5000);
        }
    }
    
    function turnOffAll() {
        Nasd.Hardware.led.off();
        Nasd.Hardware.buzzer.off();
    }

    function copy() {
        if (queue.length > 0) {
            return false;
        }
        mountList(generateTask);
        
        return true;
    }
    me.copy = copy;
    
    me._method = {
        copy: copy,
        checkProgress: checkProgress
    };
    
    me._event = [
        'progress',
        'finish'
    ];
}
inherits(USB, events.EventEmitter);

module.exports = new USB();
