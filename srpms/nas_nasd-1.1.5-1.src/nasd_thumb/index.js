#!/usr/bin/env node

'use strict';

function Thumb() {
    var me = this;
    
    me._async_method = {
        doThumb: me.doThumb,
        readThumbData: me.readThumbData
    };
}

Thumb.prototype.doThumb = function (src, fn) {
    fn = fn || function () {};
    var me = this;
    
    me.readThumbData(src, function (data) {
        data ? fn(true) : fn(false);
    });
}

Thumb.prototype.readThumbData = function (src, fn) {
    fn = fn || function () {};
    
    var ENCODING = 'base64';
    
    var fs = require('fs'),
        gm = require('gm'),
        path = require('path'),
        buf = '';
    
    var dir = path.dirname(src),
        file = path.basename(src),
        dir = path.join(dir, '.thumb'),
        dst;
    
    try {
        fs.mkdirSync(dir);
    } catch(e) {}
    
    dst = path.join(dir, file + '.thumb');
    
    if (!fs.existsSync(src)) {
        try {
            fs.unlinkSync(dst);
        } catch(e) {}
        fn(null);
        return null;
    }
    
    if (fs.existsSync(dst)) {
        fn(fs.readFileSync(dst, 'ascii'));
    } else {
        gm(src).scale('320', '240>').stream('PNG', function (error, out, err) {
            out.setEncoding('binary');
            out.on('data', function (data) {
                buf += data;
            });
            out.on('end', function() {
                if (!buf) {
                    fn(null);
                    return;
                }
                var data = 'data:image/png;base64,' + (new Buffer(buf, 'binary')).toString(ENCODING);
                
                if (dst) {
                    var stream = fs.createWriteStream(dst, {encoding: 'ascii'});
                    stream.end(data, 'ascii');
                }
                
                fn(data);
            });
        });
    }
    return null;
}

module.exports = new Thumb();