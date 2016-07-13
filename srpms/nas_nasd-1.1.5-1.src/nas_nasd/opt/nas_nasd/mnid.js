#!/usr/bin/env node

'use strict';

var AGENT_IN    = '/tmp/mnid.agent.in',
    AGENT_OUT   = '/tmp/mnid.agent.out',
    DAEMON_PID  = '/tmp/mnid.pid';

var OS = require('os'),
    FS = require('fs'),
    Zlib = require('zlib'),
    Util = require('util'),
    Dgram = require('dgram'),
    Events = require("events"),
    Process = require('child_process');

function mkfifo(file) {
    if (FS.existsSync(file) && !FS.statSync(file).isFIFO()) {
        console.error('%s exist but not fifo file.', file);
        process.exit(1);
    }
    
    Process.spawn('mkfifo', ['-m', '666', file]);
    while (true) {
        try {
            FS.statSync(file);
            break;
        } catch (e) {}
    }
}

function Mni(booting) {
    Events.EventEmitter.call(this);
    
    var PORT = 11002,
        NIC_HOSTS = {
            '*': true
        },
        NIC_INFO = {};
    
    var me = this,
        udp = Dgram.createSocket('udp4'),
        assist = undefined,
        status,
        model,
        version,
        hostname;
    
    (function () {
        var nics = OS.networkInterfaces();
        for (var nic in nics) {
            var info = nics[nic];
            for (var i = 0 ; i < info.length ; ++i) {
                if (info[i].family === 'IPv6' || info[i].address === '127.0.0.1') {
                    continue;
                }
                NIC_HOSTS[info[i].address] = true;
                //generate NIC info
                NIC_INFO[nic] = {};
                NIC_INFO[nic]['address'] = info[i].address;
                NIC_INFO[nic]['MAC'] = FS.readFileSync('/sys/class/net/' + nic + '/address', 'utf8').trim();
            }
        }
    }());
    
    booting = !!booting; // Ensure flag is a boolean variable
    
    if (booting) {
        status = 'BOOTING';
        mkfifo(AGENT_IN);
        mkfifo(AGENT_OUT);
        
        try {
            model = FS.readFileSync('/etc/manifest.txt', 'utf8').match(/type(.*)\n/)[1].trim();
            hostname = model;
        } catch(e) {}
    } else {
        status = 'ONLINE';
        try {
            model = FS.readFileSync('/etc/manifest.txt', 'utf8').match(/type(.*)\n/)[1].trim();
            version = FS.readFileSync('/etc/version', 'utf8').trim();
            hostname = FS.readFileSync('/proc/sys/kernel/hostname', 'utf8').trim();
        } catch(e) {}
    }
    
    function start() {
        try {
            udp.bind(PORT);
        } catch (e) { setTimeout(start, 200); }
    }
    me.start = start;
    
    function stop() {
        udp.close();
        
        try {
            FS.unlink(AGENT_IN);
        } catch(e) {}
        try {
            FS.unlink(AGENT_OUT);
        } catch(e) {}
    }
    me.stop = stop;
    
    function receiveData(raw, remote) {
        Zlib.inflateRaw(raw, inflated.bind(me, remote));
    }
    
    function inflated(remote, err, data) {
        if (err) { return; } // Ignore this packet
        
        try {
            data = data.toString().replace(/^[^{]*/, '');
            data = JSON.parse(data);
        } catch(e) { return; } // Drop this packet
        
        if (!NIC_HOSTS[data.HOST]) { return; } // Ignore this packet
        
        switch(data.CMD) {
        case 'DISCOVERY':
            Zlib.deflateRaw(
                JSON.stringify({
                    MODEL: model,
                    HOSTNAME: hostname,
                    VERSION: version,
                    CMD: 'DISCOVERY',
                    NIC_INFO: NIC_INFO,
                    ASSIST: assist,
                    STATUS: status,
                    BOOTING: booting
                }),
                deflated.bind(me, remote)
            );
            break;
        default:
            if (!booting || !assist) { return; } // On normal system mode or no assist
            var answer = Util.format('[%s]', data.CHOOSE);
            FS.appendFile(AGENT_OUT, answer, 'utf8');
            assist = undefined;
        }
    }
    
    function deflated(remote, err, data) {
        if (err) { return; } // Why cannot deflate data
        
        udp.send(data, 0, data.length, remote.port, remote.address);
    }
    
    (function readQuest() {
        if (!booting) { return; } // On normal system mode
        
        var agent_in = FS.createReadStream(AGENT_IN, {encoding: 'utf8', bufferSize: 1024 * 1024});
        
        agent_in.on('data', function (data) {
            data = data.trim().split('\n');
            // If shell give message too fast, just process the last line
            data = data.pop();
            data = data.split(/\[([^[]*)\]/g);
            
            if (!data) { return; }
            
            status = data[1];
            
            if (data.length === 3) {
                return;
            }
            
            assist = {
                EVENT: data[3],
                OPTIONS: data[5].split(','),
                DEFAULT: data[7]
            };
        });
        
        agent_in.on('end', function () {
            readQuest();
        });
    }());
    
    udp.on('message', receiveData);
}
Util.inherits(Mni, Events.EventEmitter);

(function () {
    function clean(mni) {
        mni.stop();
        try {
            FS.unlink(DAEMON_PID);
        } catch (e) {}
        process.exit(0);
    }
    
    if (process.argv[1] && /nasd\.js$/.test(process.argv[1])) {
        module.exports = new Mni();
    } else {
        if (process.send) {
            var mni = new Mni(true);
            mni.start();
            
            FS.writeFile(DAEMON_PID, process.pid);
            
            process.on('SIGINT', clean.bind(null, mni));
            process.on('SIGTERM', clean.bind(null, mni));
        } else {
            Process.fork(process.argv[1]);
            process.exit();
        }
    }
}());

