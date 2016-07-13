<?php
require_once(INCLUDE_ROOT."commander.class.php");
require_once(INCLUDE_ROOT."rpc.class.php");
require_once(INCLUDE_ROOT."sqlitedb.class.php");

class cwireless extends Commander{
    static function getAPList(){
        //$conn = new PDO("sqlite:/etc/cfg/cwireless.db");
        //$sql = "select essid, channel, signal, keys from AP_LIST;";
        //$st = $conn->query($sql);
        //$result = $st->fetchAll(PDO::FETCH_CLASS);
        //$tt = json_encode($result);
        //var_dump($tt);
        //return $result[0];
        
        
        //$strExec="/img/bin/rc/rc.cwireless";
        //shell_exec($strExec);
        $database = "/etc/cfg/cwireless.db";
        $db = new sqlitedb($database);
        $result = $db->runSQLAry("select essid, channel, signal, keys from AP_LIST");
        return $result;        
    }
    
    
    static function getDeviceInfo() {
        $strExec="/img/bin/rc/rc.cwireless get_info";
        shell_exec($strExec);
        $conn = new PDO("sqlite:/etc/cfg/cwireless.db");
        $sql = "SELECT * FROM DEVICE_INFO;";
        $st = $conn->query($sql);
        $result = $st->fetchAll(PDO::FETCH_CLASS);
        return $result[0];
        
        //$database = "/etc/cfg/cwireless.db";
        //$db = new sqlitedb($database);
        //$result = $db->runSQLAry("select state, type, dev_hwaddr, ipv4, apip from DEVICE_INFO");
        //var_dump($result);
        //return $result;
    }
    
    
    static function dconnectToAP($AP_essid, $AP_keys, $AP_hwaddr){
        $strExec="/img/bin/rc/rc.cwireless connect '".$AP_essid."' '".$AP_hwaddr."' '".$AP_keys."'";
        $con_result = shell_exec($strExec);
        return $con_result;
    }
    
    static function rescan(){
        $strExec = "/img/bin/rc/rc.cwireless scan";
        shell_exec($strExec);
        $database = "/etc/cfg/cwireless.db";
        $db = new sqlitedb($database);
        $result = $db->runSQLAry("select essid, signal, keys, ap_hwaddr from AP_LIST");
        return $result;
        
    }
    
    static function disconnect_from_AP(){
        $strExec="/img/bin/rc/rc.cwireless disconnect";
        shell_exec($strExec);
    }
    

}


class cwirelessRPC extends RPC{
    
    function rescan_AP_list(){
        return self::fireEvent(cwireless::rescan());
        
    }
    
    function getcwirelessAPList(){
        return self::fireEvent(cwireless::getAPList());
        
    }
    
    function dconnect_to_AP($AP_essid, $AP_keys, $AP_hwaddr){
        return self::fireEvent(cwireless::dconnectToAP($AP_essid, $AP_keys, $AP_hwaddr));
        
    }
    
    function disconnect(){
        return self::fireEvent(cwireless::disconnect_from_AP());
        
    }
    
    function get_device_info(){
        return self::fireEvent(cwireless::getDeviceInfo());
        
    }
    
    function check_connect(){
        $database = "/etc/cfg/cwireless.db";
        $db = new sqlitedb($database);
        $result = $db->runSQLAry("select state from CON_STATE");
        return $result;
    }
    
}




?>
