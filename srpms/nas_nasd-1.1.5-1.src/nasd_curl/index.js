'use strict';

function CUrl() {
    events.EventEmitter.call(this);
    
    var me = this,
        spawn = require('child_process').spawn,
        params = Array.prototype.slice.call(arguments),
        curl = spawn(
            'curl',
            params
        );
    
    curl.on('exit', function() {
        curl = undefined;
        me.emit('exit');
    });
    
    curl.stdout.setEncoding('utf8');
    curl.stdout.on('data', function (data) {
        me.emit('data', data);
    });

    curl.stderr.setEncoding('utf8');
    curl.stderr.on('data', function (data) {
        me.emit('error', data);
    });
}
inherits(CUrl, events.EventEmitter);

module.exports = CUrl;

