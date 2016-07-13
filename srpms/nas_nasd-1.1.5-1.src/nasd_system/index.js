'use strict';

function System() {
    events.EventEmitter.call(this);
    
    var INITIAL_FILE  = '/etc/initial';
    
    var me = this,
        fs = require('fs'),
        os = require('os'),
        exec = require('child_process').exec,
        popen = require('child_process').popen,
        spawn = require('child_process').spawn,
        Vendor = require('Vendor'),
        vendor_io = new Vendor.IO(),
        vendor_config = new Vendor.Config(),
        initialed = fs.existsSync(INITIAL_FILE);
    
    var yum_timer;
    
    var data = {
        initialed: initialed,
        os: fs.readFileSync('/etc/version', 'utf8').replace(/\n/g, ''),
        cpu: os.cpus()[0].model,
        model: vendor_config.model,
        memory: Math.round(os.totalmem()/1024/1024),
        kernel: os.release(),
        config: vendor_config.data
    };


    function getTimezone() {
        var fs = require('fs');
        var zoneinfo = fs.realpathSync('/etc/localtime').replace(/^.*zoneinfo\//,'');
        return zoneinfo;
        // return (new Date()).toString().match(/(GMT.*) /)[1];
    }

    function setTimezone(tz, fn) {
       console.info(tz);
       var fs = require('fs');
       fs.unlink('/etc/localtime');
       fs.symlink('/usr/share/zoneinfo/'+tz,'/etc/localtime'); 
    }

    function getTotalTrayDisks() {
        var scsi2x = new Vendor.ScsiScsi(),
            c = 0;
        for (var i = 0 ; i < scsi2x.data.length ; ++i) {
            if (scsi2x.data[i].Tray <= vendor_config.data['total_tray']) {
                c++;
            }
        }
        return c;
    }
    
    function existsDataRaid() {
        var ln = popen('readlink /raid/data');
        return (ln[0] === '.');
    }
    
    me.auth = require('./build/Release/auth').auth;
    
    function systemInfo() {
        apply(data, {
            disks: getTotalTrayDisks(),
            hostname: os.hostname(),
            data_raid: existsDataRaid(),
            httpd: +popen('sqlite /etc/cfg/conf.db "select v from conf where k =\'httpd_port\'"'),
            thecus_id: popen('sqlite /etc/cfg/conf.db "select v from conf where k =\'thecus_id\'"').trim()
        });
    
        return apply(data, Nasd.DDNS.getDDNSName());
    }
    me.systemInfo = systemInfo;
    
    me.getModelName = function () {
        return vendor_config.model;
    }
    
    function checkSoftwareUpdate(fn) {
        var YUM_STATUS = '/var/tmp/yum.status';
        
        if (typeof fn !== 'function') {
            return;
        }
        
        if (fs.existsSync(YUM_STATUS)) {
            fn(JSON.parse(fs.readFileSync(YUM_STATUS, 'utf8')));
        } else {
            var child = spawn('/img/bin/yumex', ['--check-update']),
                status = '';
            
            child.stdout.setEncoding('utf8');
            child.stdout.on('data', function(data) {
                status += data;
            });
            child.on('exit', function (code) {
                fn(JSON.parse(status));
            });
        }
    }
    me.checkSoftwareUpdate = checkSoftwareUpdate;
    
    function upgradeSoftware() {
        var nohup = require('nohup');
        nohup('/img/bin/yumex', ['--update-all']);
        
        yum_timer = setInterval(yumUpdateStatus, 10000);
    }
    me.upgradeSoftware = upgradeSoftware;
    
    function yumUpdateStatus() {
        if (fs.existsSync('/var/run/yumex.lock')) {
            try {
                var status = JSON.parse(fs.readFileSync('/var/run/yumex.lock', 'utf8'));
                me.emit('yum updating', status);
            } catch(e) {}
        } else {
            me.emit('yum updated', status);
            clearInterval(yum_timer);
        }
    }
    
    function packageList(fn) {
        if (typeof fn !== 'function') {
            return;
        }
        
        exec(
            'rpm -qa | awk -F \"-\" \'{print $1}\'',
            function(e, out, err) {
                fn(out.trim().split('\n'));
            }
        );
    }
    
    function initial() {
        var params = Array.prototype.slice.call(arguments),
            config,
            fn;
        
        if (typeof params[params.length - 1] === 'function') {
            fn = params.pop();
        } else {
            return;
        }
        
        if (params[0]) {
            config = params[0];
        } else {
            fn(false);
        }
        
        if (fs.existsSync(INITIAL_FILE)) {
            fn(false);
        }
        
        (function addUserAccount() {
            var child = spawn(
                '/img/bin/add_user.sh',
                [ '-l', '-s', '-p', config.passwd, config.user]
            );
            child.on('exit', finishCreateAccount);
        }());
        
        function saveHostname(name) {
            var sqlite3 = require('sqlite3').verbose();
            var db = new sqlite3.Database('/etc/cfg/conf.db');
            
            db.serialize(function() {
                var stmt = db.prepare('UPDATE conf SET v = (?) WHERE k = "nic1_hostname";');
                stmt.run(name);
                stmt.finalize();
            });
            
            db.close();
            
            var hostname = fs.readFileSync('/etc/HOSTNAME', 'utf8');
            hostname = hostname.split('.');
            hostname[0] = name;
            fs.writeFileSync('/etc/HOSTNAME', hostname.join('.'), 'utf8');
        }
        
        function finishCreateAccount() {
            spawn(
                'hostname',
                [config.name]
            );
            
            saveHostname(config.name);
            
            delete config.passwd;
            fs.writeFileSync(
                INITIAL_FILE,
                JSON.stringify(config),
                'utf8'
            );
            
            data.initialed = initialed = true;
            fn(true);
        }
    }
    
    me._method = {
        info: systemInfo,
        getTime: getTimezone,
        setTime: setTimezone
    };
    
    me._async_method = {
        checkSoftwareUpdate: checkSoftwareUpdate,
        upgradeSoftware: upgradeSoftware,
        packageList: packageList
    };
    
    if (!initialed) {
        me._async_method = {
            initial: initial
        }
    }
    
    me._event = [
        'yum updating',
        'yum updated'
    ]
}
inherits(System, events.EventEmitter);

module.exports = new System();
