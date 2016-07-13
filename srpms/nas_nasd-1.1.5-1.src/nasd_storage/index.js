'use strict';

/**
Storage

@class Storage
*/
function Storage() {
    events.EventEmitter.call(this);

    var self = this,
        fs = require('fs'),
        path = require('path'),
        shell = require('shelljs');

    var BASE = /^\/raid0\/data\/(NAS_Public$|NAS_Public\/)/;
    
    /**
    List raid usage
    
    @method capacity
    @return {Object}
    */
    function capacity() {
        var capacity = {};
        var df = getdfInfo();
        var md_list = getMdList('data');
        
        for (var i = 0 ; i < md_list.length ; ++i){
            var md_name = "/dev/" + md_list[i];
            
            capacity[df[md_name].mounted.replace(/^\//,"")] = {
                total: +df[md_name].blocks,
                used: +df[md_name].used,
                available: +df[md_name].available
            };
            
        }
        
        return {
            metadata: Nasd.Metadata.capacity(),
            raid: capacity
        };
    }
    self.capacity = capacity;
    
    /**
    Find system mdstat
    
    @private
    @method getMdList
    @return {Array}
    */
    function getMdList(type){
        
        var tmp = fs.readFileSync('/proc/mdstat', 'utf8');
        
        var md_list;
        
        switch(type){
            case 'all':
                md_list = tmp.match(/(md[0-9]+)/g);
                break;
            case 'data':
                md_list = tmp.match(/(md[0-9] )/g);
                for (var i = 0 ; i < md_list.length ; ++i){
                    md_list[i] = md_list[i].slice(0,-1);
                }
                break;
            case 'sys':
                md_list = tmp.match(/(md[0-9]0) /g);
                break;
            default:
                md_list = tmp.match(/(md[0-9]+)/g);
                break;
        }
        
        return md_list;
    }
    
    /**
    Find all device mount list and usage
    
    @private
    @method getdfInfo
    @return {Object} device mount list and usage
        <pre><code>
        {
            "/dev/md0": {
                available: "259036",
                blocks: "264545",
                mounted: "/raid0",
                use: "3",
                used: "5510"
            },
            "/dev/md50": {
                available: "480",
                blocks: "496",
                mounted: "/raidsys/0",
                use: "4",
                used: "17"
            }
        }
        <code></pre>
    */
    function getdfInfo() {
        var tmp = shell.exec('df -m', {silent: true}).output.split('\n');
        tmp.shift();
        tmp.pop();
        
        var df = {};
        for (var i = 0 ; i < tmp.length ; ++i){
            tmp[i] = tmp[i].match(/^([^ ]*) +([0-9]*) +([0-9]*) +([0-9]*) +([0-9]*)% (.*)/i);
            // skip XBMC module
            if (/.*\/XBMC/.test(tmp[i])){
                continue;
            }
            tmp[i].shift();
            var dev = tmp[i].shift();
            df[dev] = {
                blocks: tmp[i][0],
                used: tmp[i][1],
                available: tmp[i][2],
                use: tmp[i][3],
                mounted: tmp[i][4]
            };
        }
        
        return df;
    }
    
    function verify(dir) {
        dir = path.join(dir);
        if (!BASE.test(dir)) {
            return false;
        }
        
        if (!fs.existsSync(dir)) {
            return false;
        }
        
        var stat = fs.statSync(dir);
        if (!stat.isDirectory()) {
            return false;
        }
        
        return dir;
    }
    
    /**
    Like ls command, list will find out all dirs and files.
    
    @method list
    @param {String} dir full path string
    @param {Object} [opts]
    @return [Array] return sub dirs and files
    */
    function list(dir, opts) {
        dir = verify(dir);
        if (dir === false) {
            return null;
        }
        
        try {
            var data = fs.readdirSync(dir);
            var result = {};
            for (var i = 0 ; i < data.length ; ++i) {
                var stat = fs.statSync(path.join(dir, data[i]));
                data[i] = {
                    name: data[i]
                };
                if (stat.isDirectory()) {
                    data[i]['type'] = 'dir';
                }
                if (stat.isFile()) {
                    data[i]['type'] = 'file';
                }
            }
            return data;
        } catch (e) {}
        
        return null;
    }
    self.list = list;
    
    self._method = {
        list: list,
        capacity: capacity
    }
}
inherits(Storage, events.EventEmitter);

/**
@class Nasd
*/
/**
@property Storage
@type {Storage}
*/
module.exports = new Storage();
