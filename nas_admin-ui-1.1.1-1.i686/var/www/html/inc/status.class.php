<?php
require_once(INCLUDE_ROOT.'commander.class.php');
require_once(INCLUDE_ROOT.'rpc.class.php');
require_once(INCLUDE_ROOT.'Vendor/vendor.class.php');

final class Status extends Commander {
    private static $meminfo;
    static function fanStatus() {
        $fan = self::fg("a", "sed -nr 's/(.*_FAN.*),(.*)/\"\\1\":\"\\2\"/p' /var/tmp/monitor/Fan_Info");
        array_pop($fan);
        return json_decode(sprintf("{%s}", join(",", $fan)), true);
    }
    
    static function tmpStatus() {
        $tmp = self::fg("a", "sed -nr 's/(.*_TEMP.*),(.*)/\"\\1\":\"\\2\"/p' /var/tmp/monitor/Temp_Info");
        array_pop($tmp);
        return json_decode(sprintf("{%s}", join(",", $tmp)), true);
    }
    
    static function nicStatus() {
        $nic = self::fg("a", "sed -nr 's/(g?eth[0-9]+|bond[0-9]+),(.*),(.*)/\"\\1\":{\"rx\":\"\\2\",\"tx\":\"\\3\"}/p' /var/tmp/monitor/Network_Info");
        array_pop($nic);
        return json_decode(sprintf("{%s}", join(",", $nic)), true);
    }
    
    static function sysStatus() {
        $sys = self::fg("s", "sed -nr 'n;s/.*,(.*),(.*)/{\"CPU\":\"\\1\",\"MEM\":\"\\2\"}/p' /var/tmp/monitor/Service_Info");
        return json_decode($sys, true);
    }
    
    static function enclosureStatus() {
        $scsix2 = new VendorSCSIx2();
        $enclosures = $scsix2->grep("/D16000/");
        
        for( $i = 0 ; $i < count($enclosures) ; ++$i ) {
            $buf = array();
            $buf["vendor"] = $enclosures[$i]["Vendor"];
            $buf["product"] = $enclosures[$i]["Model"];
            $buf["rev"] = $enclosures[$i]["Rev"];
            $buf["product_no"] = $enclosures[$i]["Loc"];
            $tray = &$enclosures[$i]["Tray"];
            $status = self::fg("a", "sg_ses -p 0x02 /dev/sg$tray | sed ':a;N;$!ba;s/\\n/ /g;s/El/\\n/g' | sed -nr 's/.*us: [CO].*Id.*(sp.*|Te\\w*)=([0-9]+) .*/\\1:\\2/p;'");
            array_pop($status);
            array_pop($status);
            
            $type = "";
            for( $s = 0 ; $s < count($status) ; ++$s ) {
                $status[$s] = explode(":", $status[$s]);
                if( $type != $status[$s][0] ) {
                    $type = $status[$s][0];
                    $idx = 1;
                } else {
                    $idx++;
                }
                if( $type == "speed" ) {
                    $buf["FAN $idx"] = $status[$s][1] + 0;
                } else {
                    $buf["TEMP $idx"] = $status[$s][1] + 0;
                }
            }
            $enclosures[$i] = $buf;
        }
        
        return $enclosures;
    }
    
    static function services() {
	$daemon_list = array(
            "afp" => "afpd",
            "nfs" => "nfsd",
            "smb" => "smbd",
            "pure-ftp" => "pure-ftpd",
            "tftp" => "opentftpd",
            "upnp" => "upnpd",
            "netsnmp" => "snmpd",
            "ncpserv" => "ncpserv",
            "mediaserver" => "mediaserver",
            "rsync" => "rsyncd"
	);
	
        $daemons = array();
        $sysConfig = new VendorConfig();
        foreach($daemon_list as $key => $val){
            if( $sysConfig->data[$key] != 0 || $sysConfig->data[$key] == NULL ) {
                $daemons[$val] = false;
            }
        }
        $re = join("|", array_keys($daemons));
        $services = self::fg("a", "ps w | sed '/.*sed.*/d' | sed -nr 's/.*($re).*/\\1/p'");
        
        for( $i = 0 ; $i < count($services) ; ++$i ) {
    	    if ($services[$i]=="smbd"){
                $sambs_enable=trim(shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='httpd_nic1_cifs'\""));
                if ($sambs_enable=="1")
                    $daemons[$services[$i]] = true;
                else
                    $daemons[$services[$i]] = false;
            }else{
                $daemons[$services[$i]] = true;
	    }
        }
        
        return $daemons;
    }
    
    static function getAll() {
        $vio = new VendorIO();
        return array(
            "sys" => self::sysStatus(),
            "fan" => self::fanStatus(),
            "tmp" => self::tmpStatus(),
            "nic" => self::nicStatus(),
            "vio" => $vio->data,
            "enc" => self::enclosureStatus(),
            "svs" => self::services()
        );
    }
}

class StatusRPC extends RPC {
    function update() {
        $status = Status::getAll();
        $result = array();
        
        // Service
        $services = array();
        $result []= array(
            "key" => "service_title",
            "value" => &$services
        );
        foreach( $status["svs"] as $key => $value ) {
            if( !preg_match("/afpd|nfsd|smbd|pure-ftpd|opentftpd|upnpd|snmpd|rsync/", $key) ) {
                continue;
            }
            $services []= array(
                "key" => "service_$key",
                "value" => $value ? "running" : "stop",
                "css" => $value ? "x-run-text" : "x-stop-text"
            );
        }
        
        // Local Machine
        $model = array();
        $result []= array(
            "key" => $status["vio"]["MODELNAME"],
            "value" => &$model
        );
        foreach( $status["sys"] as $key => $value ) {
            $key = preg_match("/CPU/", $key) ? "cpu_loading" : "mem_loading";
            $model []= array(
                "key" => $key,
                "value" => $value." %"
            );
        }
        
        $i = 1;
        foreach( $status["fan"] as $key => $value ) {
            $key = preg_match("/CPU_FAN/", $key) ? "cpu_fan" : "sys_fan ".$i++;
            $model []= array(
                "key" => $key,
                "value" => $value." RPM",
                "css" => $value == "0" ? "x-stop-text" : ""
            );
        }
        
        $i = 1;
        foreach( $status["tmp"] as $key => $value ) {
            $key = preg_match("/CPU_TEMP/", $key) ? "cup_temp" : "sys_temp ".$i++;
            $c = $value + 0;
            $f = $c * (9/5) + 32;
            $model []= array(
                "key" => $key,
                "value" => "$c °C/$f °F"
            );
        }
        
        $sysConfig = new VendorConfig();
        if( isset($sysConfig->data["psu"]) && $sysConfig->data["psu"] + 0 > 1) {
            $psu = $status["vio"]["GPIO57"] == "HIGH" ? "OK" : "Fail";
            $css = $status["vio"]["GPIO57"] == "HIGH" ? "" : "x-stop-text";
            $model []= array(
                "key" => "psu",
                "value" => $psu,
                "css" => $css
            );
        }
        
        foreach( $status["nic"] as $key => $nic ) {
            $rx = $nic["rx"];
            $tx = $nic["tx"];
            $model []= array(
                "key" => $key,
                "value" => sprintf('RX: %.1f, TX: %.1f MB/s', $rx / 1024, $tx / 1024)
            );
        }
        
        // D16000 or other
        for( $i = 0 ; $i < count($status["enc"]) ; ++$i ) {
            $enc = &$status["enc"][$i];
            $key = $enc["product"] . "- " . $enc["product_no"];
            $value = array();
            for( $idx = 1 ; isset($enc["FAN ".$idx]) ; ++$idx ) {
                $value []= array(
                    "key" => "sys_fan ".$idx,
                    "value" => $enc["FAN ".$idx]." RPM",
                    "css" => $enc["FAN ".$idx] == "0" ? "x-stop-text" : ""
                );
            }
            
            for( $idx = 1 ; isset($enc["TEMP ".$idx]) ; ++$idx ) {
                $c = $enc["TEMP ".$idx] + 0;
                $f = $c * (9/5) + 32;
                $value []= array(
                    "key" => "sys_temp ".$idx,
                    "value" => "$c °C/$f °F"
                );
            }
            
            $result []= array(
                "key" => $key,
                "value" => $value
            );
        }
        
        return self::fireEvent($result);
    }
}
?>
