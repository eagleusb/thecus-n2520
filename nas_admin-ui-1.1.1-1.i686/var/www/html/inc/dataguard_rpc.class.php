<?php
require_once(INCLUDE_ROOT.'dataguard.class.php');
require_once(INCLUDE_ROOT.'rpc.class.php');

class DataGuardRPC extends RPC {
    const SUCCESS   = 0;
    const FAIL      = 0x08010000;
    const LINK_PATH = "/raid/data/ftproot";
    
    function ListTask() {
        return self::fireEvent(self::SUCCESS, DataGuard::listTask());
    }
    
    function CheckTaskName($tid, $name) {
        $id = DataGuard::getTaskId($name);
        if( $id == 0 || $id == $tid ) {
            $result = true;
        } else {
            $result = false;
        }
        return self::fireEvent(self::SUCCESS, $result);
    }
    
    function CreateTask($config) {
        $config["tid"] += 0;
        
        $guard = DataGuard::create($config);
        if( !$guard ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        
        return self::fireEvent(self::SUCCESS, $guard->getTid(), $guard->status());
    }
    
    function ModifyTask($config) {
        $config["tid"] += 0;
        $guard = DataGuard::load($config["tid"]);
        if( !$guard || !$guard->modify($config) ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $guard->getTid(), $guard->status());
    }
    
    function RemoveTask($tid) {
        $tid += 0;
        $guard = DataGuard::load($tid);
        if( $guard == null ) {
            return self::fireEvent(self::SUCCESS, $tid);
        }
        if( !$guard || !$guard->remove() ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $tid);
    }
    
    function StartTask($tid) {
        $tid += 0;
        $guard = DataGuard::load($tid);
        if( !$guard || !$guard->start() ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $guard->getTid(), $guard->status());
    }
    
    function StopTask($tid) {
        $tid += 0;
        $guard = DataGuard::load($tid);
        if( !$guard || !$guard->stop() ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $guard->getTid(), $guard->status());
    }
    
    function RestoreTask($tid) {
        $tid += 0;
        $guard = DataGuard::load($tid);
        if( !$guard || !$guard->restore() ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $guard->getTid(), $guard->status());
    }
    
    function GetLog($tid, $file) {
        $tid += 0;
        $guard = DataGuard::load($tid);
        if( !$guard ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $guard->getLog($file));
    }
    
    function ListLog($tid) {
        $tid += 0;
        $guard = DataGuard::load($tid);
        if( !$guard ) {
            return self::fireEvent(DataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $guard->listLog());
    }
    
    function TestRemoteHost($host, $port, $dest_folder, $id, $password, $path, $folder, $encrypt = 0) {
        require_once(INCLUDE_ROOT.'remoteguard.class.php');
        if( !RemoteDataGuard::testConnection($host, $port, $dest_folder, $id, $password, $path, $folder, $encrypt) ) {
            return self::fireEvent(RemoteDataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS);
    }
    
    function S3ConnTest($dest_folder, $id, $password) {
        require_once(INCLUDE_ROOT.'S3.class.php');
        if( !S3DataGuard::testConnection($dest_folder, $id, $password) ) {
            return self::fireEvent(S3DataGuard::getLastError());
        }

        return self::fireEvent(self::SUCCESS);
    }
    
    function ListLogFolder() {
        $list = array();
        $folders = Commander::fg("a", "ls -1lF /raid/data/ftproot | sed -nr 's/^.{39}(.*) -> \\/raid[0-9]+\\/data\\/.*\\/$/\\1/p'");
        for( $i = 0 ; $i < count($folders) - 1 ; ++$i ) {
            array_push($list, array($folders[$i]));
        }
        
        return self::fireEvent(self::SUCCESS, $list);
    }
    
    private function ScsiDevice() {
        // Device List
        $scsi = Commander::fg("a", "sed -nr '1n;N;N;N;s/\\n//g;s/.*/\\0/p' /proc/scsi/scsi");
        $dev = array();
        for( $i = 0 ; $i < count($scsi) - 1 ; ++$i) {
            preg_match("/^Host: (.*) Channel: (.*) Id: (.*) Lun: (.*)  Vendor: (.*) Model: (.*) Rev: (.*) Type: .* revision: (.*) Thecus: Tray:(.*) Disk:(.*) Model:.*Intf:(.*) LinkRate:(.*)$/", $scsi[$i], $scsi[$i]);
            $dev[$scsi[$i][10]] = array(
                "host"      => $scsi[$i][1],
                "channel"   => $scsi[$i][2],
                "id"        => $scsi[$i][3],
                "lun"       => $scsi[$i][4],
                "vendor"    => trim($scsi[$i][5]),
                "model"     => trim($scsi[$i][6]),
                "rev"       => trim($scsi[$i][7]),
                "revision"  => trim($scsi[$i][8]),
                "try"       => $scsi[$i][9],
                "disk"      => $scsi[$i][10],
                "intf"      => trim($scsi[$i][11]),
                "linkrate"  => $scsi[$i][12]
            );
        }
        return $dev;
    }
    
    private function MountUUIDs() {
        $mdadm = Commander::fg("a", "sed -nr 's/(\\[.*\\])//g;s/(md[0-9]) : active (linear|raid[0-9]) (.*)/\\1 \\3/p;' /proc/mdstat | sort");
        $mdmap = array();
        for( $i = 0 ; $i < count($mdadm) - 1 ; ++$i ) {
            $mdadm[$i] = explode(" ", $mdadm[$i]);
            $md = &$mdadm[$i][0];
            $dev = &$mdadm[$i][1];
            $mdmap[$md] = $dev;
        }
        
        $uuid = array();
        $list = Commander::fg("a", "blkid | sed -nr 's/\\/dev\\/(.*): .*UUID=\"([^\"]*)\".*/\\1 \\2/p' | sort -r");
        for( $i = 0 ; $i < count($list) - 1 ; ++$i ) {
            $list[$i] = explode(" ", $list[$i]);
            
            preg_match("/([a-zA-Z]+)([0-9]*)/", $list[$i][0], $list[$i][0]);
            if( $list[$i][0][1] == "loop" ) {
                $encrypt = $mdmap["md".($list[$i][0][2] - 50)];
                $list[$i][0] = "emd".($list[$i][0][2] - 50);
            } else {
                $list[$i][0] = $list[$i][0][0];
            }
            if( $encrypt || $mdmap[$list[$i][0]] ) {
                if( $encrypt ) {
                    $uuid[$list[$i][0]] = $uuid[$encrypt];
                } else {
                    $uuid[$list[$i][0]] = $uuid[$mdmap[$list[$i][0]]];
                }
                unset($encrypt);
            } else {
                $uuid[$list[$i][0]] = $list[$i][1];
            }
        }
        return $uuid;
    }
    
    private function MountList() {
        $uuid = self::MountUUIDs();
        $mount = Commander::fg("a", "mount | sed -nr 's/\\/dev\\/(.*) on (\\/raid[0-9]+.*) type (.*) \\(([^,]*),.*\\)/\\1 \\3 \\4 \\2/p'");
        $list = array();
        for( $i = 0 ; $i < count($mount) - 1; ++$i ) {
            $m = &$mount[$i];
            preg_match("/^([^ ]*) ([^ ]*) ([^ ]*) (.*)$/", $m, $m);
            preg_match("/([a-zA-Z]+)([0-9]*)/", $m[1], $m[1]);
            if( $m[1][1] == "loop" ) {
                $m[1] = "emd".($m[1][2]-50);
            } else  {
                $m[1] = $m[1][0];
            }
            $list[$m[1]] = array(
                "fs" => $m[2],
                "mode" => $m[3],
                "path" => $m[4],
                "uuid" => $uuid[$m[1]]
            );
        }
        return $list;
    }
    
    private function GetDeviceList() {
        $dev = self::ScsiDevice();
        $mount = self::MountList();
        
        // Mount List
        $df = Commander::fg("a", "df -h | sed -nr 's/\\/dev\\/([^ l]*|loop[0-9]{,2}) .* \\/raid[0-9]+.*/\\0/p'");
        $list = array();
        for( $i = 0 ; $i < count($df) - 1 ; ++$i ) {
            $disk = &$df[$i];
            $iscsi = null;
            preg_match("/^.*% (.*)$/", $disk, $full_path);
            $full_path = $full_path[1];
            preg_match("/^\/dev\/([^ ]*)[ ]*([^ ]*)[ ]*([^ ]*)[ ]*([^ ]*)[ ]*([^ ]*) (.*)$/", $disk, $disk);
            array_shift($disk);
            preg_match("/([a-zA-Z]+)([0-9]*)/", $disk[0], $device);
            $device[2] += 0;
            $d = $device[1] == "sr" ? $device[0] : $device[1];
            if( $d == "loop" ) {
                $device[2] -= 50;
                $d = "emd";
                $disk[0] = $device[0] = $d.$device[2];
            }
            $path = preg_replace("/\/raid[0-9]+\/data/", "", $disk[5]);
            if( $d == "md" || $d == "emd" ) {
                if( Commander::fg("s", "sqlite /etc/cfg/conf.db \"SELECT * FROM mount WHERE point='".$path."'\"") == '' ) {
                    if( $d == "md" && Commander::fg("s", "egrep \"(Healthy|Degraded)\" /var/tmp/".$path."/rss") == '' ) {
                        continue;
                    }
                    $model = Commander::fg("s", "sqlite $path/sys/smb.db \"select v from conf where k='raid_name'\"");
                    $path .= "/data";
                    $full_path .= "/data";
                } else {
                    continue;
                }
                $iscsi = Commander::fg("a", "sqlite $path/sys/smb.db \"select name from iscsi\"");
            } else {
                if($dev[$d]["vendor"] != "" || $dev[$d]["model"] != "")
                    $model = $dev[$d]["vendor"]."_".$dev[$d]["model"];
                else
                    $model = "Partition";

                if( $device[1] != "sr" ) {
                    $model .= $device[2];
                }
            }
            
            if( preg_match("/\/raid[0-9]+\/data\/stackable\/(.*)/", $disk[5], $type) > 0 ) {
                $model = $type[1];
                $disk[0] = "stack_".$disk[0];
                $type = "stack";
                $path .= "/data";
                $full_path .= "/data";
            } else if( preg_match("/\/raid[0-9]+\/data\/(USB|eSATA)HDD\/(usb|esata|CD).*/", $disk[5], $type) > 0 ) {
                $type = strtolower($type[2]);
            } else {
                $type = "raid";
            }
            
            $list[$disk[0]] = array(
                "dev"       => $disk[0],
                "model"     => $model,
                "size"      => $disk[1],
                "used"      => $disk[2],
                "available" => $disk[3],
                "percent"   => $disk[4],
                "path"      => $path,
                "full_path" => $full_path,
                "type"      => $type,
                "mode"      => $mount[$device[0]]["mode"],
                "fs"        => $mount[$device[0]]["fs"],
                "uuid"      => $mount[$device[0]]["uuid"]
            );
            
            if( count($iscsi) > 1 ) {
                for( $j = 0 ; $j < count($iscsi) - 1 ; ++$j ) {
                    $iscsi_dev = "iscsi_".$iscsi[$j];
                    $list[$iscsi_dev] = array(
                        "dev"       => $iscsi_dev,
                        "model"     => "iSCSI_".$iscsi[$j],
                        "size"      => $disk[1],
                        "used"      => $disk[2],
                        "available" => $disk[3],
                        "percent"   => $disk[4],
                        "path"      => $path."/iSCSI_".$iscsi[$j],
                        "full_path" => $full_path."/iSCSI_".$iscsi[$j],
                        "type"      => "iscsi",
                        "mode"      => $mount[$device[0]]["mode"],
                        "fs"        => $mount[$device[0]]["fs"],
                        "uuid"      => $mount[$device[0]]["uuid"]
                    );
                }
            }
        }
        
        
        return $list;
    }
    
    function ListFolder($dev, $path) {
        $result = array();
        $devices = self::GetDeviceList();
        
        
        if( !$devices[$dev] ) {
            foreach($devices as $dev => $info ) {
                array_push($result, $info);
            }
            return self::fireEvent(self::SUCCESS, $result);
        }
        
        $info = &$devices[$dev];
        $mount = $info["path"];
        //$re = str_replace("/", "\/", $mount);
        $re = preg_quote($mount, "/");
        
        if( preg_match("/\/\.{2,}\/?|\/~\/?|\"/", $path) || !preg_match("/^$re.*$/", $path) ) {
            $path = $mount;
        }
        
        if( preg_match("/^e?md[0-9]+$/", $dev) ) {
            /**
             * Raid Devices
             */

            $paths = explode("/", $path);
            if( count($paths) <= 3 ) {
                array_push($result, array(
                    "dev" => "",
                    "name" => "..",
                    "path" => ""
                ));
                $folders = Commander::fg("a", "ls -1lF /raid/data/ftproot | sed -nr 's/^.{39}(.*) -> $re.*\\/$/\\1/p'");
                
                for( $i = 0 ; $i < count($folders) - 1 ; ++$i ) {
                    if( !preg_match("/USBHDD|eSATAHDD|iSCSI_/", $folders[$i]) ) {
                        array_push($result, array(
                            "dev" => $dev,
                            "model" => $info["model"],
                            "uuid" => $info["uuid"],
                            "name" => $folders[$i],
                            "type" => 'dir',
                            "path" => $path."/".$folders[$i]
                        ));
                    }
                }
            } else {
                $d = Commander::fg("s", "df ".escapeshellarg($path)." | sed -nr '1n;s/(\\/dev\\/)?([^ ]*).*/\\2/p'");
                array_pop($paths);
                array_push($result, array(
                    "dev" => $dev,
                    "name" => "..",
                    "path" => join("/", $paths)
                ));

                if(substr($dev,0,3)=="emd"){
                    $tmp_dev="loop".(50+substr($dev,3));
                }else{
                    $tmp_dev=$dev;
                }

                if( $tmp_dev != $d ) {
                    return self::fireEvent(self::SUCCESS, $result, "df ".escapeshellarg($path)." | sed -nr '1n;s/(\\/dev\\/)?([^ ]*).*/\\2/p'");
                }
                
                $folders = Commander::fg("a", "ls -1F ".escapeshellarg($path)." | sed -nr 's/(.*)\\/$/\\1/p'");
                //$folders = Commander::fg("a", "ls -1F \"$path\" | sed -nr 's/(.*)\\/$/\\1/p'");
                for( $i = 0 ; $i < count($folders) - 1 ; ++$i ) {
                    if( Commander::fg("s", "sqlite /etc/cfg/conf.db \"SELECT * FROM mount WHERE point LIKE '%%".$folders[$i]."'\"") == '' ) {
                        array_push($result, array(
                            "dev" => $dev,
                            "model" => $info["model"],
                            "uuid" => $info["uuid"],
                            "name" => $folders[$i],
                            "type" => 'dir',
                            "path" => $path."/".$folders[$i]
                        ));
                    }
                }
            }
        } else if( preg_match("/^iscsi_.*$/", $dev) ) {
            $paths = explode("/", $path);
            array_pop($paths);
            if( count($paths) <= 3 ) {
                array_push($result, array(
                    "dev" => "",
                    "name" => "..",
                    "path" => ""
                ));
            } else {
                array_push($result, array(
                    "dev" => $dev,
                    "name" => "..",
                    "path" => join("/", $paths)
                ));
            }
            
//            $folders = Commander::fg("a", "ls -1F \"$path\" | sed -nr 's/(.*)\\/$/\\1/p'");
            $folders = Commander::fg("a", "ls -1F ".escapeshellarg($path)." | sed -nr 's/(.*)\\/$/\\1/p'");
            for( $i = 0 ; $i < count($folders) - 1 ; ++$i ) {
                array_push($result, array(
                    "dev" => $dev,
                    "model" => $info["model"],
                    "uuid" => $info["uuid"],
                    "name" => $folders[$i],
                    "type" => 'dir',
                    "path" => $path."/".$folders[$i]
                ));
            }
        } else if ( preg_match("/^\/stackable\/.*$/", $path) ) {
            $paths = explode("/", $path);
            array_pop($paths);
            if( count($paths) <= 3) {
                array_push($result, array(
                    "dev" => "",
                    "name" => "..",
                    "path" => ""
                ));
            } else {
                array_push($result, array(
                    "dev" => $dev,
                    "name" => "..",
                    "path" => join("/", $paths)
                ));
            }
            
//            $folders = Commander::fg("a", "ls -1F /raid/data\"$path\" | sed -nr 's/(.*)\\/$/\\1/p'");
            $folders = Commander::fg("a", "ls -1F /raid/data".escapeshellarg($path)." | sed -nr 's/(.*)\\/$/\\1/p'");
            for( $i = 0 ; $i < count($folders) - 1 ; ++$i ) {
                array_push($result, array(
                    "dev" => $dev,
                    "model" => $info["model"],
                    "uuid" => $info["uuid"],
                    "name" => $folders[$i],
                    "type" => 'dir',
                    "path" => $path."/".$folders[$i]
                ));
            }
        } else {
            /**
             * External Devices
             */
//            $d = Commander::fg("s", "df \"/raid/data/ftproot/$path\" | sed -nr '1n;s/(\\/dev\\/)?([^ ]*).*/\\2/p'");
            $d = Commander::fg("s", "df ".escapeshellarg("/raid/data/ftproot/".$path)." | sed -nr '1n;s/(\\/dev\\/)?([^ ]*).*/\\2/p'");
            
            if( $path == $mount ) {
                array_push($result, array(
                    "dev" => "",
                    "name" => "..",
                    "path" => ""
                ));
            }
            
            if( $path != $mount || $dev != $d ) {
                $paths = explode("/", $path);
                array_pop($paths);
                array_push($result, array(
                    "dev" => $dev,
                    "name" => "..",
                    "path" => join("/", $paths)
                ));
            }
            
            if( $dev != $d ) {
                return self::fireEvent(self::SUCCESS, $result);
            }
            
//            $folders = Commander::fg("a", "ls -1F \"/raid/data/ftproot/$path\" | sed -nr 's/(.*)\\/$/\\1/p'");
            $folders = Commander::fg("a", "ls -1F ".escapeshellarg("/raid/data/ftproot/".$path)." | sed -nr 's/(.*)\\/$/\\1/p'");
            
            for( $i = 0 ; $i < count($folders) - 1 ; ++$i ) {
                array_push($result, array(
                    "dev" => $dev,
                    "model" => $info["model"],
                    "uuid" => $info["uuid"],
                    "name" => $folders[$i],
                    "type" => 'dir',
                    "path" => $path."/".$folders[$i]
                ));
            }
        }

        return self::fireEvent(self::SUCCESS, $result);
    }

    function ListNasConfig($config) {
        require_once(INCLUDE_ROOT.'remoteguard.class.php');
        $result = RemoteDataGuard::listNasConfig($config);
        
        if( $result === null ) {
            return self::fireEvent(RemoteDataGuard::getLastError());
        }
        
        return self::fireEvent(self::SUCCESS, $result);
    }

    function GetNasConfig($config, $file) {
        require_once(INCLUDE_ROOT.'remoteguard.class.php');
        if( !RemoteDataGuard::getNasConfig($config, $file) ) {
            return self::fireEvent(RemoteDataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS);
    }

    function CheckNasConfig() {
        require_once(INCLUDE_ROOT.'remoteguard.class.php');
        $result = RemoteDataGuard::checkNasConfig();
        if( $result === null ) {
            return self::fireEvent(RemoteDataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS, $result);
    }

    function RestoreNasConfig($raid = null) {
        require_once(INCLUDE_ROOT.'remoteguard.class.php');
        if( !RemoteDataGuard::restoreNasConfig($raid) ) {
            return self::fireEvent(RemoteDataGuard::getLastError());
        }
        return self::fireEvent(self::SUCCESS);
    }

    function MonitorTask($task) {
         $result = array();
         for( $i = 0; $i < count($task) ; ++$i ) {
             $tid = $task[$i];
             $guard = DataGuard::load($tid);
             if( !$guard ) {
                 array_push($result, array($tid, DataGuard::getLastError()));
             } else {
                 array_push($result, array($tid, $guard->status()));
             }
         }
         return self::fireEvent(self::SUCCESS, $result);
     }
    
    function GetRaidInfo() {
        require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
        $raid = new RAIDINFO();
        $md = $raid->getMdArray();
        
        $info = array();
        foreach( $md as $m ) {
            $tmp = $raid->getINFO($m);
            array_push( $info, array($m, $tmp["RaidID"]));
            unset($tmp);
        }
        
        return self::fireEvent(self::SUCCESS, $info);
    }

    function GetFolderCount($stack = false) {
        require_once(INCLUDE_ROOT.'sharefolder.class.php');

        return self::fireEvent(self::SUCCESS, ShareFolder::getFolderCount($stack));
    }

    private function ParseDevList($dev_info){
        $folder_list=explode("/",$dev_info["folder"]);
        for( $i = 0 ; $i < count($folder_list) ; ++$i) {
            if($folder_list[$i] != ""){
                preg_match("/^([^:]*):?(.*)$/", $folder_list[$i], $dev_list[$i]);
             }
        }
        return $dev_list;
    }

    private function ParsePathInfo($dev_info){
        $info=array();
        $dev_list=self::ParseDevList($dev_info);

        $all_list=self::GetDeviceList();
        for($i=0;$i<count($dev_list);$i++){
            if($dev_info["dev"]=="" && $dev_info["path"]==""){
                $dev=$all_list[$dev_list[$i][1]];
                $info["path"][]=$dev["full_path"];
                $info["nic_name"][]=$dev["model"];
            }else{
                $dev=$all_list[$dev_info["dev"]];
                $preg="/^".preg_quote($dev["path"], "/")."/";
                $info["path"][]=preg_replace($preg, $dev["full_path"], $dev_info["path"])."/".$dev_list[$i][1];
                $info["nic_name"][]=preg_replace($preg, $dev["model"], $dev_info["path"])."/".$dev_list[$i][1];
            }
            $info["model"][]=$dev["model"];
            $info["mount_path"][]=$dev["full_path"];
            $info["type"][]=$dev["type"];
            $info["mode"][]=$dev["mode"];
        }

        return $info;
    }

    private function getRenewDev($type,$uuid,$dev,$tid){
        $all_list=self::GetDeviceList();
        $result=array("exist"=>"1",
                      "new_dev" => null);
        if(substr($dev,0,2)=="md" || substr($dev,0,3)=="emd"){
            foreach( $all_list as $full_info){
                if($uuid!=$full_info["uuid"] ||
                  !(substr($full_info["dev"],0,2)=="md" || substr($full_info["dev"],0,3)=="emd"))
                {
                    continue;
                }else{
                    $result["exist"]="0";
                    break;
                }
            }
        }elseif(substr($dev,0,5)=="iscsi"){
            foreach( $all_list as $full_info){
                if($uuid!=$full_info["uuid"] ||
                   substr($full_info["dev"],0,5)!="iscsi")
                {
                    continue;
                }else{
                    $result["exist"]="0";
                    break;
                }
            }
        }elseif(substr($dev,0,5)=="stack"){
            foreach( $all_list as $full_info){
                if($uuid!=$full_info["uuid"]){
                    continue;
                }else{
                    $result["exist"]="0";
                    break;
                }
            }
        }else{
            if($type=="src"){
                foreach( $all_list as $full_info){
                    if($uuid!=$full_info["uuid"]){
                        continue;
                    }else{
                        $result["exist"]="0";
                        break;
                    }
                }
            }else{
                $full_path=trim(shell_exec("/img/bin/rc/rc.lbackup search_target_tag ".$tid));
                if($full_path!=""){
                    $result["exist"]="0";
                    $external_dev=trim(shell_exec("df '".$full_path."' | awk '/^\/dev\//{printf(\"%s\",substr($1,6))}'"));
                    $new_dev=$external_dev;
                    $full_info=$all_list[$new_dev];
                }
            }
        }

        if($result["exist"]=="0"){
            $result["new_dev"]=$full_info;
        }
        return $result;
    }

    private function RassembleRoot($type,$dev_info,$tid){
        $all_list=self::GetDeviceList();
        $new=array("dev" => "",
                   "path" => "",
                   "folder" => "",
                   "uuid"   => "",
                   "model"  => ""
             );
        if(trim($dev_info["folder"])=="")
            return $new;
        $all_old_dev=explode("/",trim($dev_info["folder"]));
        $all_old_uuid=explode("/",trim($dev_info["uuid"]));

        for($i=0;$i<count($all_old_dev);$i++){
            $new_folder="";
            $old_dev_ary=explode(":",$all_old_dev[$i]);
            $dev=$old_dev_ary[0];
            $uuid=$all_old_uuid[$i];
            $result=self::getRenewDev($type,$uuid,$dev,$tid);

            if($result["exist"]=="0"){
                $full_info=$result["new_dev"];
                $new_folder=$full_info["dev"].":".$full_info["model"];
                $new_uuid=$full_info["uuid"];
                if($new["folder"]==""){
                    $new["folder"]=$new_folder;
                    $new["uuid"]=$new_uuid;
                }else{
                    $new["folder"].="/".$new_folder;
                    $new["uuid"].="/".$new_uuid;
                }
            }
        }
        return $new;
    }

    private function RassembleNotRoot($type,$dev_info,$tid){
        $dev=$dev_info["dev"];
        $uuid=$dev_info["uuid"];
        $folder_list=explode("/",$dev_info["folder"]);
        $new=array("dev" => "",
                   "path" => "",
                   "folder" => "",
                   "uuid"   => $uuid,
                   "model"  => ""
             );
        $exist="1";
        $result=self::getRenewDev($type,$uuid,$dev,$tid);
        if($result["exist"]=="0"){
            $full_info=$result["new_dev"];
        }

        if(substr($dev,0,2)=="md" || substr($dev,0,3)=="emd"){
            if($result["exist"]=="0"){
                if($full_info["dev"]==$dev){
                    $new["dev"]=$dev;
                    $new["path"]=$dev_info["path"];
                }else{
                    $new["dev"]=$full_info["dev"];
                    if(substr($dev,0,2)=="md")
                        $mdnum=substr($dev,2);
                    else {
                        $mdnum=substr($dev,3);
                    }
                    $preg="/^".preg_quote("/raid".$mdnum."/data", "/")."/";
                    $new["path"]=preg_replace($preg, $full_info["path"], $dev_info["path"]);
                }
                $new["model"]=$full_info["model"];
                $full_path=$new["path"];
            }
        }elseif(substr($dev,0,5)=="iscsi"){
            if($result["exist"]=="0"){
                $new["dev"]=$full_info["dev"];
                $new["path"]=$dev_info["path"];
                $new["model"]=$full_info["model"];
                $full_path=self::LINK_PATH.$new["path"];
            }
        }elseif(substr($dev,0,5)=="stack"){
            if($result["exist"]=="0"){
                $new["dev"]=$full_info["dev"];
                $new["path"]=$dev_info["path"];
                $new["model"]=$full_info["model"];
                $master_path=readlink("/raid");
                $master_folder_list=explode("/",$master_path);
                $full_path="/".$master_folder_list[1]."/data".$new["path"];
            }
        }else{
            if($type=="src"){
                if($result["exist"]=="0"){
                    $new["dev"]=$full_info["dev"];
                    $new["model"]=$full_info["model"];
                    $dev_path_count=count(explode("/",$full_info["path"]));
                    $org_split_path=explode("/",$dev_info["path"]);
                    $new_path[]=$full_info["path"];
                    for($i=$dev_path_count;$i<count($org_split_path);$i++){
                        $new_path[]=$org_split_path[$i];
                    }
                    $new["path"]=implode("/",$new_path);
                    $full_path=self::LINK_PATH.$new["path"];
                }
            }else{
                $full_path=trim(shell_exec("/img/bin/rc/rc.lbackup search_target_tag ".$tid));
                if($full_path!=""){
                    $result["exist"]="0";
                    $external_dev=trim(shell_exec("df '".$full_path."' | awk '/^\/dev\//{printf(\"%s\",substr($1,6))}'"));
                    $new["dev"]=$external_dev;
                    $full_path=substr($full_path,0,strlen($full_path)-strlen(strrchr($full_path,'/')));
                    $path_ary=preg_split('/^\/raid[0-9]\/data\//',$full_path);
                    $new["path"]="/".$path_ary[1];
                    $new["uuid"]=trim(shell_exec("blkid /dev/".$new["dev"]." | sed -nr 's/\/dev\/(.*): .*UUID=\"([^\"]*)\".*/\\2/p'"));
                    $new["model"]=$full_info["model"];
                }
            }
        }

        if($result["exist"]=="0"){
            for($i=0;$i<count($folder_list);$i++){
                if(file_exists($full_path."/".$folder_list[$i])){
                    if($new["folder"]==""){
                        $new["folder"]=$folder_list[$i];
                    }else{
                        $new["folder"].="/".$folder_list[$i];
                    }
                }
            }
        }else{
            $new["uuid"]="";
        }

        return $new;
    }

    private function RescanDevInfo($type,$dev_info,$tid){
        $new=null;
        if($dev_info["dev"]=="" && $dev_info["path"]==""){
            $new=self::RassembleRoot($type,$dev_info,$tid);
        }else{
            $new=self::RassembleNotRoot($type,$dev_info,$tid);
        }
        return $new;
    }

    function RassembleDevInfo($src,$dest,$tid){
/*        $src=array("dev"=>"md1",
                   "uuid"=>"70daa311-cea5-4140-286b-09b63679279d",
                   "path"=>"/raid0/data/_NAS_Module_Source_",
                   "folder"=>"dfasdf/NAS_Public");*/
/*        $src=array("dev"=>"iscsi_iscsi",
                   "uuid"=>"70daa311-cea5-4140-286b-09b63679279d",
                   "path"=>"/iSCSI_iscsi",
                   "folder"=>"_NAS_Module_Source_/test/NAS_Public");*/
/*        $dest=array("dev"=>"sdy1",
                    "uuid"=>"7A5F-2702",
                    "path"=>"/USBHDD/usb25/1/enian",
                    "folder"=>"eeee");*/
/*$src=array ( "dev" => "sdx1",
             "uuid" => "7A5F-2702",
             "path" => "/USBHDD/usb25/1/boot",
             "folder" => "grub");*/
        //$tid="3";
       
/*               $src=array("dev"=>"",
                   "uuid"=>"70daa311-cea5-4140-286b-09b63679279d",
                   "path"=>"",
                   "folder"=>"iscsi_iscsi:iSCSI_iscsi");
       */
        
        $dev["src"]=self::RescanDevInfo("src",$src,$tid);
        $dev["dest"]=self::RescanDevInfo("dest",$dest,$tid);
        //var_dump($dev);
        return self::fireEvent(self::SUCCESS, $dev);
    }

    private function parseTarget($path,$type){
        $path_list=explode("/",$path);
        if($type=="stack"){
            $new_list[]="/".$path_list[4];
            $start=6;
        }else{
            $new_list[]="/".$path_list[3];
            $start=4;
        }

        for($i=$start;$i<count($path_list);$i++){
            $new_list[]=$path_list[$i];
        }

        $after_path=implode("/", $new_list);

        return $after_path;
    }

    private function CheckTargetPath($dev_info, $backup, $act, $disk,$tid){
        $msg=array();
        $exclude_type=array("copy","import","import_iscsi");
        if(!($backup=="import" || $backup=="import_iscsi")){
            $task_list = DataGuard::listTask();
            for($i=0;$i<count($task_list);$i++){
                if($tid!=$task_list[$i]["tid"] &&
                   $disk==$task_list[$i]["opts"]["device_type"] 
                   && (!in_array($task_list[$i]["back_type"],$exclude_type)) 
                   && $task_list[$i]["act_type"]=="local"){
                    $other_target_list=explode("//",$task_list[$i]["opts"]["target"]);
                    if($disk=="1"){
                        for($j=0;$j<count($other_target_list);$j++){
                            for($k=0;$k<count($dev_info["mount_path"]);$k++){
                                if(file_exists($dev_info["mount_path"][$k]."/".$other_target_list[$j]."/".$task_list[$i]["opts"]["target_tag"])){
                                    //$msg="1";
                                    $msg[]=$task_list[$i]["task_name"];
                                    //break;
                                }
/*                                if($msg == "1"){
                                    break;
                                }*/
                            }
                        }
                    }else{
                        for($j=0;$j<count($other_target_list);$j++){
                            for($k=0;$k<count($dev_info["path"]);$k++){
                                $target=self::parseTarget($dev_info["path"][$k],$dev_info["type"][$k]);
                                $preg_target=preg_quote($target, "/");
                                $preg_other_target=preg_quote($other_target_list[$j], "/");
                                //var_dump("/^".$preg_other_target."$/||/^".$preg_other_target."\//");
                                //var_dump($target);
                                if(preg_match("/^".$preg_target."($|\/)/",$other_target_list[$j])||
                                   preg_match("/^".$preg_other_target."($|\/)/",$target)){
                                    //$msg="1";
                                    //break;
                                    $msg[]=$task_list[$i]["task_name"];
                                }
                            }
                        }

/*                        if($msg == "1"){
                            break;
                        }*/
                    }
/*                    if($msg == "1"){
                        break;
                    }*/
                }
            }
        }
        return $msg;
    }

    function RenameFolder($path,$folder){
        $index=1;
        $new_folder=$folder;
        $real_path=trim(shell_exec("ls -l ".$path."| egrep -i ".escapeshellarg("/".$new_folder."$|/".$new_folder."/data$"). " |  sed -nr 's/.* -> (\/.*)$/\\1/p'"));
        while($real_path!=""){
            $new_folder=$folder."-".$index;
            $real_path=trim(shell_exec("ls -l ".$path."| egrep -i ".escapeshellarg("/".$new_folder."$|/".$new_folder."/data$"). " |  sed -nr 's/.* -> (\/.*)$/\\1/p'"));
            $index++;
            
        }

        return $new_folder;
    }

    function CheckContainPath($src, $dst, $backup, $act, $disk, $task_name, $create_sub, $tid) {
        /**
         * Both src and dst must be formated as follow:
         $src = {
            dev: '',
            uuid: '',
            path: '',
            model: '',
            folder: [],
            type: 'raid/iscsi/external',
            backup :'import/iscsi/copy/realtime/schedule',
            act: backup/restore,
         }
         */
//         $target_path=self::ParseDevInfo($dst);//parse_target_path
//         $source_path=self::ParseDevInfo($src);//parse_source_path
         $target_info=self::ParsePathInfo($dst);//parse_target_path
         $source_info=self::ParsePathInfo($src);//parse_source_path
         $msg["iscsi_exist"]="0";
//         var_dump(count($target_info["path"])."---".count($source_info["path"]));
         switch($backup){
         case "import":
             $folder_list=explode("/",$src["folder"]);
             for($i=0;$i<count($folder_list);$i++){
                 $real_path=trim(shell_exec("ls -l ".self::LINK_PATH."| egrep -i ".escapeshellarg("/".$folder_list[$i]."$|/".$folder_list[$i]."/data$"). " |  sed -nr 's/.* -> (\/.*)$/\\1/p'"));
//                 $real_path=readlink("/raid/data/ftproot/".$folder_list[$i]);
                 if ($real_path != ""){
                     $folder=explode("/",$real_path);
                     if ($folder[3]!="stackable")
                         //$name=trim(shell_exec("sqlite /".$folder[1]."/sys/smb.db \"select v from conf where k='raid_name'\""));
                         $name=self::RenameFolder(self::LINK_PATH,$folder_list[$i]);
                     else
                         $name="stackable(".$folder[4].")";
                     $msg["rename"][]=array($folder_list[$i],$name);
                 }
             }
             break;
         case "copy":
             if($disk == "2"){
                 if($src["dev"]=="" && $src["folder"]==""){
                     $dev=explode("/",$src["folder"]);
                     for($i=0;$i<count($dev);$i++){
                         $dev_info=explode(":",$dev[$i]);
                         $folder_list[]=$dev_info[1]."_".$dev_info[0];
                     }
                 }else{
                     $folder_list=explode("/",$src["folder"]);
                 }
             }else{
                 $folder_list=explode("/",$src["folder"]);
             }

             for($i=0;$i<count($folder_list);$i++){
                 for($j=0;$j<count($target_info["path"]);$j++){
                     $target_path=$target_info["path"][$j];
                     $target_mode=$target_info["mode"][$j];
                     if(!mkdir($target_path."/".$folder_list[$i])){
                         if(file_exists($target_path."/".$folder_list[$i])){
                             $msg["dup"][]=$folder_list[$i];
                         }else{
                             if($target_mode != "ro")
                                 $msg["err_folder"][]=$folder_list[$i];
                         }
                     }else{
                         rmdir($target_path."/".$folder_list[$i]);
                     }
                 }
             }
             break;
         case "iscsi":
             $item_list=explode("/",$src["folder"]);
             for($i=0;$i<count($item_list);$i++){
                 $dev_list=explode(":",$item_list[$i]);
                 for($j=0;$j<count($target_info["path"]);$j++){
                     $target_path=$target_info["path"][$j];
                     $target_mode=$target_info["mode"][$j];
                     if(!mkdir($target_path."/".$dev_list[1])){
                         if(file_exists($target_path."/".$dev_list[1])){
                             $msg["dup"][]=$dev_list[1];
                         }else{
                             if($target_mode != "ro")
                                 $msg["err_folder"][]=$dev_list[1];
                         }
                     }else{
                         rmdir($target_path."/".$dev_list[1]);
                     }
                 }
             }
             break;
         case "schedule":
             if($create_sub=="1"){
                 $folder_list[]=$task_name;
             }else{
                 $folder_list=explode("/",$src["folder"]);
             }

             for($i=0;$i<count($folder_list);$i++){
                 for($j=0;$j<count($target_info["path"]);$j++){
                     $target_path=$target_info["path"][$j];
                     $target_mode=$target_info["mode"][$j];
                     if(!mkdir($target_path."/".$folder_list[$i])){
                         if(file_exists($target_path."/".$folder_list[$i])){
                             $msg["dup"][]=$folder_list[$i];
                         }else{
                             if($target_mode != "ro")
                                 $msg["err_folder"][]=$folder_list[$i];
                         }
                     }else{
                         rmdir($target_path."/".$folder_list[$i]);
                     }
                 }
             }
             break;
         case "realtime":
             for($k=0;$k<count($source_info["path"]);$k++){
                 $source_path=$source_info["path"][$k];
                 $list=scandir($source_path);
                 for($i=0;$i<count($list);$i++){
                     if ($list[$i]!="." && $list[$i]!=".."){
                         if(is_dir($source_path."/".$list[$i])){
                             for($j=0;$j<count($target_info["path"]);$j++){
                                $target_path=$target_info["path"][$j];
                                $target_mode=$target_info["mode"][$j];
                                if(!mkdir($target_path."/".$list[$i])){
                                    if(file_exists($target_path."/".$list[$i])){
                                        $msg["dup"][]=$list[$i];
                                    }else{
                                        if($target_mode != "ro")
                                             $msg["err_folder"][]=$list[$i];
                                    }
                                }else{
                                    rmdir($target_path."/".$list[$i]);
                                }
                             }
                         }
                     }
                 }
             }
             break;
         case "import_iscsi":
             for($k=0;$k<count($source_info["path"]);$k++){
                 $source_path=$source_info["path"][$k];
                 $iscsi_name=trim(shell_exec("/img/bin/dataguard/iscsi.sh get_iscsiname '".$source_path."'"));
                 if(trim($iscsi_name) != ""){
                     $real_path=readlink(self::LINK_PATH."/iSCSI_".$iscsi_name);
                     if ($real_path){
                         $folder=explode("/",$real_path);
                         $name=self::RenameFolder(self::LINK_PATH,"iSCSI_".$iscsi_name);
                     //$name=trim(shell_exec("sqlite /".$folder[1]."/sys/smb.db \"select v from conf where k='raid_name'\""));
                         $msg["rename"][]=array($iscsi_name,substr($name,6));
                     }
                 }else{
                     $msg["iscsi_exist"]="1";
                 }
             }
         }

        $msg["same"]=self::checkTargetPath($target_info,$backup,$act,$disk,$tid);
        ///var_dump(print_r($msg));
        // Iff folder(s) exist then return those as array otherwise null.
        //$msg["dup"][]
        //$msg["same"][]
        //$msg["rename"]
        //$msg["err_folder"][]
        //$msg["iscsi_exist"]="0/1"
        return self::fireEvent(self::SUCCESS, $msg);
    }

    function CheckOneTaskCount($back_type){
        $count = Commander::fg("i", "sqlite /etc/cfg/backup.db \"select count(*) from task where back_type='".$back_type."'\"");
        return self::fireEvent(self::SUCCESS, $count);
        //return $count;
    }
}
?>
