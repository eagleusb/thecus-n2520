<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');


class HighAvailabilityRPC
{
    static private function fireEvnet() {
        return func_get_args();
    }
    static function setPrimary($post){
        require_once(INCLUDE_ROOT.'session.php');
        global $session;
        $db = new sqlitedb();
        $ch = new validate();
        
        $gwords = $session->PageCode("global");
        $words = $session->PageCode("ha");
        
        /**
         * data check
         */
        // check hostname
        $hostname_error=0;
        $ha_primary_name = $db->getvar("nic1_hostname");
        if ( $ch->check_empty($post['ha_virtual_name']) || !$ch->check_ha_hostname($post['ha_virtual_name'])) $hostname_error=1; 
        if ( $ch->check_empty($post['ha_standy_name']) || !$ch->check_hostname($post['ha_standy_name'])) $hostname_error=1; 
        if ( trim($ha_primary_name) == trim($post['ha_standy_name']) ) $hostname_error=2; 
        if ( trim($post['ha_virtual_name']) == trim($post['ha_standy_name']) ) $hostname_error=2; 
        if ( trim($post['ha_virtual_name']) == trim($ha_primary_name) ) $hostname_error=2; 
        if ($hostname_error==1){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['invalid_hostname']);
        }
        if ($hostname_error==2){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['dup_hostname']);
        }

        $check_interface=trim($post['ha_virtual_ip_iface']);
        if (!strstr($check_interface,'bond')) {
            $check_interface_result=shell_exec('/img/bin/rc/rc.net get_network_info | awk -F\| \'/^'.$check_interface.'\|/{print $14}\'');
            if ($check_interface_result == 1){
                unset($ch);
                unset($db);
                return self::fireEvnet(false, $gwords['ha_dhcp_warning']);
            }
        }

        //ha_virtual_ip_iface, ha_heartbeat
        if ( trim($post['ha_virtual_ip_iface']) == trim($post['ha_heartbeat']) ){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, "Virtual interface can not be the same as Heartbeat interface.");
        }
        
        //check ip address      
        $ip_error=0;
        if ( $ch->check_empty($post['ha_virtual_ip_ipv4']) || !$ch->ip_address($post['ha_virtual_ip_ipv4']) )$ip_error=1;
        if ( $ch->check_empty($post['ha_standby_ip_ipv4']) || !$ch->ip_address($post['ha_standby_ip_ipv4']) )$ip_error=1;
        if ( $ch->check_empty($post['ha_primary_ip3']) || !$ch->ip_address($post['ha_primary_ip3']) )$ip_error=1;
        if ( $ch->check_empty($post['ha_standy_ip3']) || !$ch->ip_address($post['ha_standy_ip3']) )$ip_error=1;
        
        if ( trim($post['ha_virtual_ip_ipv4']) == trim($post['ha_primary_ip_ipv4']) )$ip_error=2;
        if ( trim($post['ha_virtual_ip_ipv4']) == trim($post['ha_standby_ip_ipv4']) )$ip_error=2;
        if ( trim($post['ha_standby_ip_ipv4']) == trim($post['ha_primary_ip_ipv4']) )$ip_error=2;
        
        if ( $ip_error==1 ){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['ip_error']);
        }else if ( $ip_error==2 ){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['ha_ip_dup']);
         }
         
        //ipv6_address
        $ip_error=0;
        if($post['ha_virtual_ip_ipv6']!=''){
            if (!$ch->ipv6_address($post['ha_virtual_ip_ipv6']) )$ip_error=1;
            if ( trim($post['ha_virtual_ip_ipv6']) == trim($post['ha_primary_ip_ipv6']) )$ip_error=2;
        }
        if($post['ha_standby_ip_ipv6']!=''){
            if (!$ch->ipv6_address($post['ha_standby_ip_ipv6']) )$ip_error=1;
            if ( trim($post['ha_virtual_ip_ipv6']) == trim($post['ha_standby_ip_ipv6']) )$ip_error=2;
            if ( trim($post['ha_standby_ip_ipv6']) == trim($post['ha_primary_ip_ipv6']) )$ip_error=2;
        }
        
        if ( $ip_error==1 ){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['ip_error']."(IPv6)");
        }else if ( $ip_error==2 ){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['ha_ip_dup']."(IPv6)");
         }
         
        if ( trim($post['ha_primary_ip3']) == trim($post['ha_standy_ip3'])){
               unset($ch);
               unset($db);
               return self::fireEvnet(false, $words['heartbeat_duplicate']);
        }
        
        //check heartbeat thresholds        
        $thresholds_error=0;
        if ( $ch->check_empty($post['ha_keepalive']) || $ch->check_empty($post['ha_deadtime']) )$thresholds_error=1;
        if ( $ch->check_empty($post['ha_warntime']) || $ch->check_empty($post['ha_initdead']) )$thresholds_error=1;
        if ( !$ch->numeric(4,'max',$post['ha_keepalive']) || !$ch->numeric(4,'max',$post['ha_deadtime']) )$thresholds_error=1;
        if ( !$ch->numeric(4,'max',$post['ha_warntime']) || !$ch->numeric(4,'max',$post['ha_initdead']) )$thresholds_error=1;
        if ( $thresholds_error==1 ){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['thresholds_fields']);
        }
        
        if((int)$post['ha_keepalive']<2){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['error_keep']);
        }
        if((int)$post['ha_deadtime']<10){
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['error_dead']);
        } 
        if((int)$post['ha_warntime'] < ((int)$post['ha_keepalive']*2)){
            unset($ch);
            unset($db);
            $msg = sprintf($words['error_warn'],$post['ha_keepalive']*2);
            return self::fireEvnet(false, $msg);
        }   
        if((int)$post['ha_initdead'] < ((int)$post['ha_deadtime']*2)){
            unset($ch);
            unset($db);
            $msg = sprintf($words['error_initd'],$post['ha_deadtime']*2);
            return self::fireEvnet(false, $msg);
        }      
        
        //check udp port   
        $port_error = 0;
        $udpport = (int)$post['ha_udpport'];
        if(!$ch->check_port($udpport))$port_error=1;
        if (($udpport!=694) && ($udpport<3694 || $udpport >3794))$port_error = 1;
        if($port_error) {
            unset($ch);
            unset($db);
            return self::fireEvnet(false, $words['port_range']);
        }  
    
        //post data
        $post_key = array('ha_enable','ha_role','ha_virtual_name','ha_virtual_ip',
                            'ha_primary_ip1',
                            'ha_standy_name','ha_standy_ip1',
                            'ha_keepalive','ha_deadtime','ha_warntime','ha_initdead',
                            'ha_udpport',
                            'ha_heartbeat',
                            'ha_auto_failback',
                            'ha_primary_ip3','ha_standy_ip3',
                            'ha_indicator_ip');
        $post_array = array();
        foreach ($post_key as $k){
            $post_array[$k] = ($post[$k] == null) ? '' : $post[$k];
        }
        
        //db data
        $db_key = array("ha_enable"=>"0","ha_role"=>"0", "ha_virtual_name"=>"", "ha_virtual_ip"=>"",
                    "ha_primary_ip1"=>"",
                    "ha_standy_name"=>"", "ha_standy_ip1"=>"",
                    "ha_keepalive"=>HA_KEEPALIVE, "ha_deadtime"=>HA_DEADTIME, "ha_warntime"=>HA_WARNTIME, "ha_initdead"=>HA_INITDEAD,
                    "ha_udpport"=>HA_UDPPORT,
                    "ha_heartbeat"=>"",
                    "ha_auto_failback"=>"0",
                    "ha_primary_ip3"=>"", "ha_standy_ip3"=>"", "ha_indicator_ip"=>"" );
        $db_array = array();
        foreach ($db_key as $k=>$v) {
            $db_array[] = $db->getvar($k, $v);
        }
        // save to db
        $i=0;
        if (serialize($post_array) != serialize($db_array)){
            foreach ($db_key as $k=>$v){
                $db->setvar($k, $post_array[$k]);
                $i++;
            }
        }
        unset($db);
        
        // execute ha shell script
        if(file_exists(HA_SCRIPT)){
            pclose(popen(HA_SCRIPT.' apply > /dev/null 2>&1 &', "r"));
        }
        return self::fireEvnet(true);
    }
    static function setSecondary($ip){
        // can not found shell script
        $db = new sqlitedb();
        $db->setvar('ha_enable','1');
        $db->setvar('ha_role','1');
        unset($db);
        // execute check script
        pclose(popen(HA_SCRIPT.' apply "'.$ip.'"> /dev/null 2>&1 &', "r"));
        return self::fireEvnet(true);
    }
    static function setDisable($together){
        if($together == '1') {
            pclose(popen(HA_SCRIPT.' disable', "r"));
            if (file_exists(HA_FLAG)){
                $result = trim(file_get_contents(HA_FLAG));
                $result = str_replace("\n","",$result);
                if( $result=="22") {
                    $db = new sqlitedb();
                    $db->setvar('ha_enable','0');
                    unset($db);
                    return self::fireEvnet(true, $together);
                }else if( $result == '122') {
                    return self::fireEvnet(false, $together);
                    
                }
            }
        }else{
            $db = new sqlitedb();
            $db->setvar('ha_enable','0');
            unset($db);
            return self::fireEvnet(true, $together);
        }
    }
    static function setTruncateLog(){
        @unlink(HA_LOG_PATH);
        @unlink("/var/log/ha-log");
        return self::fireEvnet(true);
    }
    static function getNetwork(){
        if(file_exists(HA_NETWORK_PATH)){
            $cline = file_get_contents(HA_NETWORK_PATH);
            $cline = str_replace("\n","",$cline);
            list($primary, $heartbeat, $secondary, $rebuild) = explode('|',$cline);
            return self::fireEvnet($primary, $heartbeat, $secondary, $rebuild);
        }else{
            return self::fireEvnet(1, 1, 1, '');
        }
    }
    static function getMonitor(){
        global $session;
        $tmprole='';
        $res = '';
        $msg = '';
        $dbrole = 1;
        if (file_exists(HA_ROLE)){ 
            $tmprole = trim(file_get_contents(HA_ROLE));
            $tmprole = str_replace("\n","",$tmprole); 
        }
        if (file_exists(HA_FLAG)){ 
            $gwords = $session->PageCode("global");
            $words = $session->PageCode("ha");
            $words['warn'] = $gwords['warn'];
            $words['success'] = $gwords['success'];
    
            $res = trim(file_get_contents(HA_FLAG));
            $res = str_replace("\n","",$res); 
            switch($res){
                case "5":
                        $db = new sqlitedb();
                        $db->setvar("ha_enable",'1');
                        unset($db); 
                case "4":
                        $db = new sqlitedb();
                        $dbrole = $db->getvar("ha_role");
                        unset($db); 
                    break;
                case "105":
                case "117":
                case "119":
                    if(file_exists(HA_HW_CONF)){
                        $line=trim(file_get_contents(HA_HW_CONF));
                        $line = str_replace("\n","",$line); 
                        if($line!=''){
                            list($key, $value) = explode('|', trim($line));
                            $ww = $words[trim($key)];
                            $msg = ($value!='')?vsprintf($ww, explode('^',$value)): $ww;
                        }
                    }
                    break;
            }
        } 
        $req = array(
             'dbrole'=>$dbrole, 
             'tmprole'=>$tmprole,
             'res'=>$res,  
             'msg'=>$msg,
             'wording'=>$words
             );
        return $req;
        die;
    }
    
    static function isHaRaidDamaged(){
        $count = shell_exec("grep '1|1' /tmp/www/ha_status | wc -l") + 0;
        //(standby/active) raid damaged
        if(file_exists('/tmp/ha_raid_damaged')){
            return self::fireEvnet(true, $count == 2);
        }else{
            return self::fireEvnet(false, $count == 2);
        }
    }
}
?>
