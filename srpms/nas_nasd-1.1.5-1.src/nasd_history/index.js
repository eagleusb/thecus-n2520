'use strict';

function History() {
    events.EventEmitter.call(this);
    
    var DB_FILE = '/raid/data/tmp/access.db';
    
    var me = this,
        fs = require('fs'),
        sqlite3 = require('sqlite3');
    
    var DB_INIT = [
        'CREATE TABLE IF NOT EXISTS access_info(', 
            [
                'Connection_type',
                'Date_time',
                'Users',
                'Source_ip',
                'Computer_name',
                'size',
                'Event',
                'tmp',
                'level',
                'filetype',
                'action'
            ].join(','),
        ')'
    ].join('');
    
    function showLog() {
        var fn,
            opts,
            params = Array.prototype.slice.call(arguments);
        
        if (typeof params[params.length - 1] === 'function') {
            fn = params.pop();
        } else {
            return;
        }
        
        opts = params[0] || {};
        applyIf(opts, {
            type: 'all',
            time: '',
            limit: 20,
            device: '',
            ip: ''
        });
        
        var querycmd = genQueryCmd(opts);
        
        var db = new sqlite3.Database(DB_FILE);
        db.serialize(function () {
            db.run(DB_INIT);
            db.all(querycmd, fn);
        });
        db.close();
    }
    me.showLog = showLog;
    
    function genQueryCmd(opts) {
        var cmd = "SELECT * FROM access_info";
        
        if (opts.type !== 'all'){
            cmd = cmd + " WHERE Connection_type='" + opts.type + "'";
        }
        if (opts.time !== ''){
            if (opts.type === 'all'){
                cmd = cmd + " WHERE Date_time LIKE '%" + opts.time +"%'";
            }
            else{
                cmd = cmd + " AND Date_time LIKE '%" + opts.time + "%'";
            }
        }
        if (opts.device !== ''){
            if ( (opts.type === 'all') && (opts.time === '') ){
                cmd = cmd + " WHERE Computer_name='" + opts.device +"'";
            }
            else{
                cmd = cmd + " AND Computer_name='" + opts.device +"'";
            }
        }
        if (opts.ip !== ''){
            if ( (opts.type === 'all') && (opts.time === '') && (opts.device === '') ){
                cmd = cmd + " WHERE Source_ip='" + opts.ip +"'";
            }
            else{
                cmd = cmd + " AND Source_ip='" + opts.ip +"'";
            }
        }
        cmd = cmd + " ORDER BY Date_time DESC";
        cmd = cmd + " LIMIT " + opts.limit;
        
        return cmd;
    }

    function clearLog() {
        var fn,
            opts,
            params = Array.prototype.slice.call(arguments);
        
        if (typeof params[params.length - 1] === 'function') {
            fn = params.pop();
        }
        
        opts = params[0] || {};
        
        opts = opts || {};
        applyIf(opts, {
            type: 'all',
            level: 'all'
        });
        
        var delcmd = genDelCmd(opts);
        
        var db = new sqlite3.Database(DB_FILE);
        db.serialize(function () {
            db.run(DB_INIT);
            db.run(delcmd, function (err) {
                if (fn) {
                    fn(err);
                }
            });
        });
        db.close();
    }
    me.clearLog = clearLog;
    
    function genDelCmd(opts) {
        var cmd = "DELETE FROM access_info";
        
        if (opts.type !== 'all'){
            cmd = cmd + " WHERE Connection_type='" + opts.type + "'";
        }
        if (opts.level !== 'all'){
            if (opts.type === 'all'){
                cmd = cmd + " WHERE level='" + opts.level + "'";
            }
            else{
                cmd = cmd + " AND level='" + opts.level + "'";
            }
        }
        return cmd;
    }
    
    function insertLog(record, fn){
        record = record || {};
        
        applyIf(record, {
            $conn: '',
            $user: '',
            $sip: '',
            $name: '',
            $size: '',
            $event: '',
            $tmp: '',
            $level: '',
            $type: '',
            $action: ''
        });
        
        var db = new sqlite3.Database(DB_FILE);
        db.serialize(function () {
            db.run(DB_INIT);
            db.run(
                'INSERT INTO access_info VALUES($conn, datetime("now", "localtime"), $user, $sip, $name, $size, $event, $tmp, $level, $type, $action)',
                record,
                function (err) {
                    if (typeof fn === 'function') {
                        fn(err);
                    }
                }
            );
        });
        db.close();
    }
    me.insertLog = insertLog;
    
    function lastLogDate(type, days, fn) {
        if (typeof fn !== 'function') {
            return;
        }
        var db = new sqlite3.Database(DB_FILE),
            result = [];
        
        db.serialize(function() {
            var stmt = db.prepare([
                'SELECT STRFTIME("%Y-%m-%d", Date_time) as date FROM access_info',
                'WHERE',
                    'action=(?)',
                'AND',
                    'DATETIME(Date_time) >= DATETIME("now", "localtime", (?))',
                'GROUP BY date',
                'ORDER BY Date_time'
            ].join(' '));
            stmt.each(type, format('-%d days', days), function (err, record) {
                result.push(record.date);
            });
            stmt.finalize(function () {
                fn(result);
            });
        });
        db.close();
    }

    me._async_method = {
        log  : showLog,
        clear: clearLog,
        lastLogDate: lastLogDate
    }

}
inherits(History, events.EventEmitter);

module.exports = new History();
