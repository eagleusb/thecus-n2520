#!/usr/bin/env node

var fs = require('fs'),
    util = require('util'),
    emitter = require('events').EventEmitter,
    model;

function VendorBase() {
    var me = this;
    
    if (!model) {
        model = fs.readFileSync('/etc/manifest.txt', 'utf8');
        model = model.match(/type\s*(.*)\n/)[1];
    }
    
    me.model = model;
}

VendorBase.prototype.data = {};
VendorBase.prototype.model = '';

VendorBase.prototype.grep = function (re) {
    var me = this,
        result = {};
    
    for (var k in me.data) {
        if (re.test(k) || re.test(me.data[k])) {
            result[k] = me.data[k];
        }
    }
    return result;
}

/**
   Vendor IO
**/
function VendorIO() {
    VendorBase.call(this);
    
    var me = this,
        io = fs.readFileSync('/proc/thecus_io', 'utf8'),
        io = io.split('\n');
    
    for (var i = 0; i < io.length - 1 ; ++i) {
        var tmp = io[i].match(/^(.*): (.*)$/);
        if (isNaN(+tmp[2])) {
            me.data[tmp[1]] = tmp[2];
        } else {
            me.data[tmp[1]] = +tmp[2];
        }
    }
    
    me.data['MODELNAME'] = me.model;
}
util.inherits(VendorIO, VendorBase);

/**
  VendorConfig
**/
function VendorConfig() {
    VendorBase.call(this);
    
    var me = this,
        file = util.format('/img/bin/conf/sysconf.%s.txt', me.model);
        conf = fs.readFileSync(file, 'utf8');
    
    conf.replace(/((.*)=(.*))\n/g, function(pat1, pat2, k, v) {
        if (isNaN(+v)) {
            me.data[k] = v;
        } else {
            me.data[k] = +v;
        }
    });
}
util.inherits(VendorConfig, VendorBase);

/**
  VendorMemory
**/
function VendorMemory() {
    VendorBase.call(this);
    
    var me = this;
        info = fs.readFileSync('/proc/meminfo', 'utf8');
    
    info.replace(/(.*): *(\d+) kB\n/g, function(pat, k, v) {
        me.data[k] = +v;
    });
}
util.inherits(VendorMemory, VendorBase);

/**
  VendorScsiScsi
**/
function VendorScsiScsi() {
    VendorBase.call(this);
    
    var t = 0,
        me = this,
        data = fs.readFileSync('/proc/scsi/scsi', 'utf8');
    
    data.replace(/(Host.*\n.*\n.*\n.*Pos:\d*)\n/g, function (pat, dev) {
        dev = dev.replace(/ANSI  SCSI/, '');
        dev = dev.replace(/\n/g, ' ').replace(/ *(\w*:)/g, function (pat, field) {
            return '\n' + field;
        });
        
        dev = dev.split(/(.*): *(.*) *\n?/g);
        dev.shift();
        
        me.data[t] = {};
        for (var i = 0 ; i < dev.length ; i += 3) {
            if (isNaN(+dev[i+1])) {
                me.data[t][dev[i]] = dev[i+1];
            } else {
                me.data[t][dev[i]] = dev[i+1]? +dev[i+1] : null;
            }
        }
        t++;
    });
}
util.inherits(VendorScsiScsi, VendorBase);

VendorScsiScsi.prototype.data = [];
VendorScsiScsi.prototype.grep = function (re) {
    var me = this,
        result = [];
    
    for (var i = 0 ; i < me.data.length ; ++i) {
        var dev = me.data[i],
            tmp;
        for (var k in dev) {
            if (re.test(k) || re.test(dev[k])) {
                tmp = tmp || {};
                tmp[k] = dev[k];
            }
        }
        
        if (tmp) {
            result.push(tmp);
        }
    }
    
    return result;
}

module.exports = {
    IO: VendorIO,
    Config: VendorConfig,
    Memory: VendorMemory,
    ScsiScsi: VendorScsiScsi
}
