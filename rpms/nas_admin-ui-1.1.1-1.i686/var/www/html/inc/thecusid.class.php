<?php
require_once(INCLUDE_ROOT."commander.class.php");
require_once(INCLUDE_ROOT."rpc.class.php");
require_once(INCLUDE_ROOT."sqlitedb.class.php");



class Thecusid extends Commander{
    static function getDdns(){
        $ddns_fqdn_file_path="/tmp/ddns_fqdn";

        shell_exec("/img/bin/nas_ddns.sh 0");
        if(is_file($ddns_fqdn_file_path)){
            $handle = fopen($ddns_fqdn_file_path, "r");    
            if ($handle) {
                $contents = fgets($handle);
                $fqdn_result = explode("\t", $contents);
                $ddns_fqdn = array(
                    'fqdn'=>trim($fqdn_result[0]),
                    'ddns'=>trim($fqdn_result[1]),
                    'thecusid'=>trim($fqdn_result[2])
                    );
                return $ddns_fqdn;
            }
        }
    }
    
    static function Setddns($thecusid, $passwd, $ddns){
        shell_exec("/img/bin/nas_ddns.sh 2 " . $thecusid . " " . $passwd . " " . $ddns);
        $error_code = DecHex(shell_exec("cat /tmp/ddns.out"));
        return $error_code;
    }
    
    static function registerThecusid($thecusid, $passwd, $f_ame, $m_name, $l_name){
        shell_exec("/img/bin/nas_ddns.sh 1 " . $thecusid . " " . $passwd . " " . $f_ame . " " . $m_name . " " . $l_name);
        $error_code = DecHex(shell_exec("cat /tmp/ddns.out"));
        return $error_code;
    }
    
    static function Logout(){
        shell_exec("/img/bin/nas_ddns.sh 5");
        return 0;
    }
}

class ThecusidRPC extends RPC{
    function getDdns(){
        return self::fireEvent(Thecusid::getDdns());
    }
    
    function Setddns($thecusid, $passwd, $ddns){
        return self::fireEvent(Thecusid::Setddns($thecusid, $passwd, $ddns));
    }
    
    function registerThecusid($thecusid, $passwd, $f_ame, $m_name, $l_name){
        return self::fireEvent(Thecusid::registerThecusid($thecusid, $passwd, $f_ame, $m_name, $l_name));
    }
    
    function Logout(){
        return self::fireEvent(Thecusid::Logout());
    }
    
}


?>