'use strict';

function Rsync() {
    events.EventEmitter.call(this);
    
    var me = this,
        spawn = require('child_process').spawn,
        progress = 0,
        file,
        child;
    
    function onData(data) {
        var total, finish, current;
        // For rsync 3.0.8, the string is "to-check=58/6293"
        // For rsync 3.1.0, the string is "to-chk=58/6293" or "ir-chk=58/6293"
        data = data.split(/.*-ch[e]*[c]*k=(\d*)\/(\d*)\)/);

        if (data && +data[1] && +data[2]) {
            total = +data[2];
            finish = total - (+data[1]);
            
            current = Math.floor(finish / total * 1000) / 10;
            if (current > progress) {
                progress = current;
                me.emit('progress', progress);
            }
        }
    }
    
    function onExit(code) {
        child = undefined;
        progress = 0;
        me.emit('exit', code);
    }
    
    me.copy = function (src, dst, options) {
        if (child) {
            return false;
        }
        
        progress = 0;
        
        options = [].concat(
            '--progress',
            options,
            src,
            dst
        );
        
        child = spawn(
            'rsync',
            options
        );

        child.on('exit', onExit);
        child.stdout.setEncoding('utf8');
        child.stdout.on('data', onData);
        return true;
    };
    
    me.getProgress = function () {
        return progress;
    };
}
inherits(Rsync, events.EventEmitter);

module.exports = Rsync;
