'use strict';

/**
DDNS
@class DDNS
*/
function DDNS() {
    events.EventEmitter.call(this);
    
    var NIC_ETH0_MAC = '/sys/class/net/eth0/address',
        DDNS_UTILITY = "/usr/bin/ddns_client";
    
    var me = this,
        fs = require('fs'),
        spawn = require('child_process').spawn,
        sqlite3 = require('sqlite3').verbose(),
        mac_addr = fs.readFileSync(NIC_ETH0_MAC, 'utf8').trim(),
        ddns_fqdn = '',
        default_ddns_hostname = 'N' + mac_addr.replace(/(^.{8}|:|\n)/g, '').toUpperCase(),
        default_ddns_fqdn = [default_ddns_hostname, 'thecuslink', 'com'].join('.');
    
    (function () {
        var db = new sqlite3.Database('/etc/cfg/conf.db');
        
        db.get('SELECT v AS fqdn FROM conf WHERE k = "thecus_ddns_fqdn";', function (err, data) {
            ddns_fqdn = data.fqdn;
        });
        
        db.close();
    }());
    
    /**
    Get Thecus ddns name
    @method getDDNSHostName
    @return obj {Object} Both hostname and fqdn will be return
    */
    function getDDNSName() {
        return {
            default_fqdn: default_ddns_fqdn,
            fqdn: ddns_fqdn
        };
    }
    me.getDDNSName = getDDNSName;
    
    /**
    Create Thecus ID
    @method create_account
    @param info {Object} email, password, and name of new account
    @param fn {Function} only return DDNS_UTILITY command result code
    */
    function create_account(info, fn) {
        fn = fn || function() {};
        
        var child = spawn(
            DDNS_UTILITY,
            [
                1,
                info.email,
                info.passwd,
                info.fname,
                info.mname,
                info.lname
            ]
        );
        
        child.on('exit', function (code) {
            fn(+code);
        });
    }
    
    /**
    Save Thecus ID into database
    @method save_account_info
    @param info {Object} email, password, and name of new account and fqdn for ddns
    @param fn {Function} only return DDNS_UTILITY command result code
    */
    function save_account_info(info,fn) {
        var db = new sqlite3.Database('/etc/cfg/conf.db');
        
        db.serialize(function() {
            var stmt = db.prepare('INSERT or REPLACE into conf VALUES((?), (?));');
            stmt.run('thecus_ddns', '1');
            stmt.run('thecus_id', info.email);
            stmt.run('thecus_pwd', info.passwd);
            stmt.run('thecus_fname', info.fanme);
            stmt.run('thecus_mname', info.mname);
            stmt.run('thecus_lname', info.lname);
            stmt.run('thecus_ddns_fqdn', info.fqdn);
            stmt.finalize();
        });
        
        db.close();
        db.on('close',function(){
            fn();
        });
    }
    
    /**
    Auth Thecus ID
    @method auth
    @param info {Object} email, password
    @param fn {Function} only return DDNS_UTILITY command result code
    */
    function auth(info, fn) {
        fn = fn || function() {};
        
        var child = spawn(DDNS_UTILITY, [2, info.email, info.passwd, mac_addr, info.fqdn]),
            response = '';
        
        child.stdout.setEncoding('utf8');
        child.stdout.on('data', function (data) {
            response += data;
        });
        
        child.on('exit', function (code) {
            if (code === 0) {
                info.fqdn = response.match(/FQDN\t([^\n]*)/)[1] || '';
                info.fname = response.match(/FirstName\t([^\n]*)/)[1] || '';
                info.mname = response.match(/MiddleName\t([^\n]*)/)[1] || '';
                info.lname = response.match(/LastName\t([^\n]*)/)[1] || '';
                
                fn=fn.bind(null ,+code, info);
                save_account_info(info,fn);
                update_ddns(info);
            } else {
                fn(+code, info);
            }
            
            ddns_fqdn = info.fqdn;
            delete info.passwd;
        });
    }
    
    /**
    Update DDNS
    @method update_ddns
    @param info {Object} email and password
    @param fn {Function} only return DDNS_UTILITY command result code
    */
    function update_ddns(info, fn) {
        fn = fn || function() {};
        
        var child = spawn(DDNS_UTILITY, [3, info.email, info.passwd, mac_addr]);
        
        child.on('exit', function (code) {
            fn(+code);
        });
    }
    
    /**
    Send Activation Email
    @method send_verify_email
    @param info {Object} email address which you want to send to
    @return ret {Number} return value of DDNS_UTILITY command
    */
    function send_verify_email(info, fn) {
        fn = fn || function() {};
        
        var child = spawn(DDNS_UTILITY, [4, info.email]);
        
        child.on('exit', function (code) {
            fn(+code);
        });
    }
    
    /**
    Reset password
    @method reset_passwd
    @param info {Object} email
    @param fn {Function} only return DDNS_UTILITY command result code
    */
    function reset_passwd(info, fn) {
        fn = fn || function() {};
        
        var child = spawn(DDNS_UTILITY, [5, info.email]);
        
        child.on('exit', function (code) {
            fn(+code);
        });
    }
    
    /**
    Modify password
    @method modify_passwd
    @param info {Object} email, old password and new password
    @param fn {Function} only return DDNS_UTILITY command result code
    */
    function modify_passwd(info, fn) {
        fn = fn || function() {};
        
        var child = spawn(DDNS_UTILITY, [6, info.email, info.passwd, info.new_passwd]);
        
        child.on('exit', function (code) {
            fn(+code);
        });
    }

    /**
    Check if the ports of NAS can be access through internet.
    @method check_port
    @param fn {Function} only return DDNS_UTILITY command result code
    @return ret {Number} return value of DDNS_UTILITY command
    */
    function check_port(fn) {
        fn = fn || function() {};
        var child = spawn('/img/bin/nas_ddns.sh', ['6']);

        child.on('exit', function (code) {
            if (code != 0) {
                fn(false); //child is failed after executed
            } else {
                switch (fs.readFileSync('/tmp/ddns.out', 'utf8').trim()){
                    case '70':
                        fn(true); //The ports is available on internet
                        break;
                    case '71':
                        fn(false); //The ports is unavailable on internet
                        break;
                    default:
                        fn(null);
                }
            }
        });
    }
    
    me._async_method = {
        create_account: create_account,
        auth: auth,
        update_ddns: update_ddns,
        send_verify_email: send_verify_email,
        reset_passwd: reset_passwd,
        modify_passwd: modify_passwd,
        check_port: check_port
    };
}
inherits(DDNS, events.EventEmitter);

module.exports = new DDNS();
