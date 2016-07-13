<?php
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'commander.class.php');
require_once(INCLUDE_ROOT.'raid.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(FUNCTION_ADM_ROOT.'setdestroyraid.php');

abstract class HugeVolumeRPC extends Commander {
    static private function fireEvnet() {
        return func_get_args();
    }
    
    private function getUnusedDisk() {
        $disk = new DISKINFO();
        $disk_info = $disk->getINFO();
        $disk_list=$disk_info["DiskInfo"];
        $free = 0;
        for( $i = 0 ; $i < count($disk_list) ; ++$i ) {
            $d = &$disk_list[$i];
            if( $d[1] != "N/A" && $d[6] == "0" ) {
                $free += 1;
            }
        }
        return $free;
    }
    
    static function setVolumeExpansion($mode) {
        $db = new sqlitedb();
        if ($mode=="off"){
            $db->setvar("hv_service", "0");
            shell_exec("/img/bin/rc/rc.hv stop > /dev/null 2>&1");
        }else{
            $db->setvar("hv_service", "1");
            shell_exec("/img/bin/rc/rc.hv boot > /dev/null 2>&1");
        }
        unset($db);
                                                                        
        return self::fireEvnet(true); // success
        return self::fireEvnet(false); // fail
    }

    static function check_raidid($raid_id) {
      $class=new RAIDINFO();
      $class->setmdselect(0);
      $check_raidinfo=$class->getINFO("");
      foreach($check_raidinfo["AllRaidName"] as $v){
        if($v!=""){
          if($raid_id==$v){
            return self::fireEvnet(true);
          }
        }
      }
      return self::fireEvnet(false);
    }
        
    static function getManagment() {
        $md_num = -1;
        $hv_client_path="/tmp/hv_client/connect";
        $hv_raid_ip="/etc/hv_raid_ip";
        $volumes=array();
        $monitor = 0;
        $md_list = self::fg('a', "sed -rn 's/md([0-9] ).*/\\1/p' /proc/mdstat");
        foreach($md_list as $mdnum){
            if( $mdnum == "" ) break;
            $isHV=trim(file_get_contents("/raidsys/$mdnum/HugeVolume"));
            if ($isHV!=""){
                $md_num = $mdnum;
                $md=new RAIDINFO();
                $md = $md->getINFO($mdnum);

                $raidid=trim(shell_exec("cat /var/tmp/raid$mdnum/raid_id"));
                $ChunkSize=$md['ChunkSize'];
                $RaidFS=$md['RaidFS'];
                $raidlevel=trim(shell_exec("cat /var/tmp/raid$mdnum/raid_level"));
                $raidstatus=trim(shell_exec("cat /var/tmp/raid$mdnum/rss"));
                $RaidTotal=$md['RaidTotal'];
                $RaidUsage=$md['RaidUsage'];
                if($RaidUsage=="N/A") $RaidUsage=0;
                $RaidUnUsed=$md['RaidUnUsed'];
  
                $build_raid=trim(shell_exec("ps | grep '[/]app/bin/post_create' | grep ' ". $raidid ."' "));
                if (($raidstatus != "Healthy") || ($build_raid!=""))
                    $monitor = 1; // 0: nothing, 1: monitor raid, 2: monitor testing
                    
                //provider volume information
                $disklist=self::fg('a', "cat /var/tmp/raid$mdnum/disk_tray");
                
                foreach($disklist as $disk){
                    if( $disk == "" ) break;
                    $tdisk=str_replace('"','',$disk);
                    $devname=self::fg('s', "cat /proc/scsi/scsi |awk '/Thecus:/&&/Tray:$tdisk /{FS=\" \";print \$3}' | awk -F':' '{print \$2}'");
                    $dev=self::fg('s', "cat $hv_client_path/* | awk -F'|' '{if (\$4==\"$devname\") print \$0}'");
                    $dev=explode("|", $dev);
                    $rss=self::fg('s', "/img/bin/rc/rc.hv get_clientstatus '" . $dev[0] . "' '" . $dev[5] . "'");
                    $capacity=self::getCapacity($dev[3])." GB";
                    
                    if ($dev[4]!="N/A"){
                        $spare= explode(",", $dev[4]);
                    }else{
                        $spare=array();
                    }
                    
                    array_push($volumes,array("",$dev[0],$dev[2],$dev[5],$dev[6],$capacity,$spare,$rss));
                }

                break;
            }
        }
        
        if ($isHV==""){
            //provider volume information
            $ip_list=self::fg('a', "ls $hv_raid_ip");
                
            foreach($ip_list as $ip){
                if( $ip == "" ) break;
                if (file_exists("$hv_client_path/$ip")){
                    $dev=self::fg('s', "cat $hv_client_path/$ip");
                    $dev=explode("|", $dev);
                    $capacity=self::getCapacity($dev[3])." GB";
                    $rss="Online";
                }else{
                    $dev=self::fg('s', "cat $hv_raid_ip/$ip");
                    $dev=explode("|", $dev);
                    $capacity="N/A";
                    $rss="Offline";
                }
                
                $spare= explode(",", $dev[4]);    
                array_push($volumes,array("",$dev[0],$dev[2],$dev[5],$dev[6],$capacity,$spare,$rss));
            }
        }

        $info = array(
            $raidid,
            $ChunkSize, // Stripe
            $RaidFS, // File System
            $raidstatus, // Status
            $RaidTotal, // Capacity
            $RaidUsage, // Used
            $RaidUnUsed // Reserve
        );
        
        $db = new sqlitedb();
        $hv_enable=$db->getvar("hv_enable", "0");
        unset($db);
        
        if ($hv_enable=="0")
            $suspend = true;
        else
            $suspend = false;
        
        $test=shell_exec("ps|grep 'rc.hv speedTest' | grep -v 'grep'");
        if ($test!="")
            $monitor=2;
            
        return self::fireEvnet($info, $md_num, $volumes, $monitor, $suspend);
    }
    
    static function getAvaiableVolume() {
        $hv_mdnum="";
        $hv_client_path="/tmp/hv_client/connect";
        $hv_client_speed="/tmp/hv_client/speed";
        $volumes=array();
        $ip_list=self::fg('a', "cat $hv_client_path/*");
        
        $md_list = self::fg('a', "sed -rn 's/md([0-9] ).*/\\1/p' /proc/mdstat");
        foreach($md_list as $mdnum){
            if( $mdnum == "" ) break;

            $isHV=trim(file_get_contents("/raidsys/$mdnum/HugeVolume"));
            if ($isHV!=""){
                $hv_mdnum=$mdnum;
                break;
            }
        }


        /**
         * Grid store index
         * 0. ip
         * 1. iqn
         * 2. hostname
         * 3. spare(0/1)
         * 4. disk name
         * 5. raid id
         * 6. raid level
         */

        foreach($ip_list as $detail){
            if( $detail == "" ) break;
            $detail = explode("|", $detail);
            $available=self::fg('s', "cat /proc/mdstat | grep '^md$hv_mdnum :' | grep '". $detail[3] ."2'");
            
            if ($available!="")
                continue;
            
            $capacity=self::getCapacity($detail[3])." GB";
            $tray_num=self::fg('i', "sed -rn 's/.*Tray:([0-9]*) Disk:$detail[3] .*/\\1/p' /proc/scsi/scsi");
            $rss=self::fg('s', "/img/bin/rc/rc.hv get_clientstatus '" . $detail[0] . "' '" . $detail[5] . "'");
            
            if (file_exists($hv_client_speed."/".$detail[3])){
                $speed=trim(file_get_contents($hv_client_speed."/".$detail[3]));
                $speed=($speed/10);
                $speed=$speed." MB/s";
            }else
                $speed="";
            
            $spare=array();
            if ($detail[4]!="N/A"){
                $spare []= $detail[4];
            }
            
            $volumes[]=array($tray_num,$detail[0],$detail[2],$detail[5],$detail[6],$capacity,$spare,$rss,$speed);
        }
        $testing = false;
        return self::fireEvnet($volumes, $testing);
    }
    
    static function getRaid() {
        $volumes = array(
            array('172.16.64.189', 'HV01', 'RAID1', 'J', 100, false, 'Healthy'),
            array('172.16.64.190', 'HV02', 'RAID2', '5', 200, false, 'Healthy'),
            array('172.16.64.191', 'HV03', 'RAID3', 'J', 300, false, 'Healthy'),
            array('172.16.64.189', 'HV04', 'RAID4', '1', 400, false, 'Healthy')
        );
        
        return self::fireEvnet($volumes);
    }
    
    static function setRaid($id, $stripe, $fs, $volumes) {
        $success = true;
        $raid_id=$id;
        $md=new RAIDINFO();
        $md->setmdselect(0);
        $md_num=$md->getNewMdNum();
        $_POST["type"]="linear";
        $_POST["chunk"]=$stripe;
        $_POST["filesystem"]=$fs;
        $_POST["inraid"]=array();
        
        $hv_client=self::fg('i', "/img/bin/check_service.sh hv_client");
        if ($hv_client < count($volumes))
          return self::fireEvnet(false);
          
        shell_exec("/bin/mkdir /var/tmp/raid".$md_num);
        for( $i = 0 ; $i < count($volumes) ; $i++ ) {
          $dev_num=$volumes[$i][0];
          array_push($_POST["inraid"],$dev_num);
          shell_exec("echo -e '\"$dev_num\"' >> /var/tmp/raid".($md_num)."/disk_tray");
        }
        shell_exec("echo \"Constructing RAID ...\" > /var/tmp/raid".($md_num)."/rss");
        shell_exec("echo \"".$raid_id."\" > /var/tmp/raid".($md_num)."/raid_id");
        shell_exec("echo J > /var/tmp/raid".($md_num)."/raid_level");

        $raid=new raid();
        $raid->mdSwitch($md_num);
        $create_cmd=$raid->create($_POST);
        shell_exec("echo -e \"$create_cmd\" > /tmp/create_command.log");
        
        $ismasterraid=0;
        $md_list = self::fg('s', "sed -rn 's/md([0-9] ).*/\\1/p' /proc/mdstat");
        if($md_list == "") $ismasterraid=1;

        $strexec="echo 1 > /raidsys/".($md_num)."/HugeVolume;sh -x /img/bin/post_create ".$md_num." 100 ".$raid_id." ".$ismasterraid." ".$_POST["filesystem"]." 0 > /tmp/post_create.log & 2>&1;";
        self::bg($create_cmd.$strexec);
        
        $tmp=self::fg('s', "cat /var/tmp/raid$md_num/disk_tray");
        $tdisk=str_replace('"','',$tmp);
        shell_exec("/img/bin/rc/rc.hv cp_raidtray_ip '$tdisk'");
        
        return self::fireEvnet($success);
    }
    
    static function setExpand($mdnum, $volumes) {
        $success = false;
        $_POST["spare"]=array();
        
        $client=self::fg('i', "cat /var/tmp/raid$mdnum/disk_tray | wc -l");

        $hv_client=self::fg('i', "/img/bin/check_service.sh hv_client");
        if ($hv_client < count($volumes)+$client)
          return self::fireEvnet(false);
          
        for( $i = 0 ; $i < count($volumes) ; $i++ ) {
          $dev_num=$volumes[$i][0];
          array_push($_POST["spare"],$dev_num);
          shell_exec("echo -e '\"$dev_num\"' >> /var/tmp/raid".($mdnum)."/disk_tray");
        }
        $raid=new raid();
        $raid->mdSwitch($mdnum);
        $raid->add_spare($_POST);
        $result=$raid->commit();

        $tmp=shell_exec("cat /var/tmp/raid".($mdnum)."/disk_tray");
        $tdisk=str_replace('"','',$tmp);
        shell_exec("/img/bin/rc/rc.hv cp_raidtray_ip '$tdisk'");
        $strexec="/img/bin/jbod_resize.sh $mdnum > /dev/null & 2>&1 ";
        self::bg($strexec);
        $success=true;
        return self::fireEvnet($success);
    }
    
    static function setSuspend($md_num) {
        global $raid,$raidinfo,$sd,$num;
        $success = false;
        $isHV=trim(file_get_contents("/raidsys/$md_num/HugeVolume"));
        
        if ($isHV!=""){
          $num = $md_num;
          $info=new RAIDINFO();
          $info->setmdselect(0);
          $raidinfo=$info->getINFO($num);
          $raid=new raid();
          $raid->mdSwitch($num);
          stop_service();
          if(umount_raid()==0){
            $success = false;
          }else{
            stop_raid();
            $sd=array();
            foreach($raidinfo["RaidDisk"] as $d){
              $sd[]=substr($d,0,3);
            }
            foreach($raidinfo["SpareList"] as $d){
              $sd[]=substr($d,0,3);
            }
            remove_swapdisk();
            remove_sysdisk();
            set_noraid();
            shell_exec("rm -rf /var/tmp/raid".$num);
            start_service();
            $success = true;
          }
        }else{
            $success = true;
        }
        
        if ($success){
          shell_exec("/img/bin/rc/rc.hv setrole '0'");
          shell_exec("/img/bin/rc/rc.hv logout");
        }
        
        return self::fireEvnet($success);
    }
    
    static function setResume() {
        $success = true;
        shell_exec("/img/bin/rc/rc.hv setrole '1'");
        return self::fireEvnet($success);
    }
    
    static function setRaidRemove($md_num) {
        $success = true;
        $isHV=trim(file_get_contents("/raidsys/$md_num/HugeVolume"));
        if ($isHV!=""){
          if (Stop_Steps($md_num)==0) {
            $success=false;
          }else
            $md_num = -1;
        }
        
        if ($success){
          shell_exec("rm /etc/hv_raid_ip/*");
        }
        
        return self::fireEvnet($success);
    }
    
    static function setVolumeRemove($volumes) {
        global $raid,$raidinfo,$sd,$num;
        $success = true;
        $action="destroy" ;
        $fsmode="hv";
        for( $i = 0 ; $i < count($volumes) ; $i++ ) {
          $md_num=$volumes[$i][0];
          shell_exec("/img/bin/rc/rc.hv del_iscsi " . $md_num);
          if ($md_num >= 0){
            $num = $md_num;
            $info=new RAIDINFO();
            $info->setmdselect(0);
            $raidinfo=$info->getINFO($num);
            $raid=new raid();
            $raid->mdSwitch($num);
            if(umount_raid()==0){
              $success = false;
            }else{
              $raidid=trim(shell_exec("cat /var/tmp/raid$num/raid_id"));
              stop_raid();
              $sd=array();
              foreach($raidinfo["RaidDisk"] as $d){
                $sd[]=substr($d,0,3);
              }
              foreach($raidinfo["SpareList"] as $d){
                $sd[]=substr($d,0,3);
              }
              remove_swapdisk();
              remove_sysdisk();
              blind_erase_superblock();
              blind_gdisk();
              set_noraid();
              shell_exec("rm -rf /var/tmp/raid".$num);
              $success = true;
              shell_exec("/img/bin/logevent/event 997 813 'info' 'email' '". $raidid . "' 'removed'");
            }
          }
        }

        $strExec="/bin/cat /proc/mdstat | awk -F: '/^md1[1-9] :/{printf(\"%s\\n\",  substr(\$1,3))}' | sort -u";
        $md_list=trim(shell_exec($strExec));
        if ($md_list=="")
            shell_exec("/img/bin/rc/rc.hv cron_del");

        return self::fireEvnet($success);
    }
    
    /**
     * DD the $size of data to volumes and compute the average write speed of times.
     *
     * @param {Integer} $size
     * @param {Integer} $times
     * @param {Array} $volumes
     */
    static function setTest($size, $times, $volumes) {
        $devlist="";
        for( $i = 0 ; $i < count($volumes) ; $i++ ) {
            $devlist=trim("$devlist ".$volumes[$i][0]);
        }
        
        self::bg("/img/bin/rc/rc.hv speedTest '%s' '%d' '%d' > /dev/null & 2>&1", $devlist, $size, $times);
        $testing = true;
        return self::fireEvnet($testing);
    }
    
    static function setTestCancel() {
        $pid_list=self::fg('a', "ps|egrep 'rc.hv speedTest|dd if /dev/zero of /dev/sd' | grep -v 'grep' | awk '{print $1}'");
        foreach($pid_list as $pid){
            shell_exec("kill -9 $pid");
        }
        return self::fireEvnet(true);
    }
    
    static function getTestStage() {
        $hv_client_speed="/tmp/hv_client/speed";
        $tmp_status = self::fg('s', "cat $hv_client_speed/status");
        $status=explode(" ", $tmp_status);
        return self::fireEvnet(doubleval($status[0]), doubleval($status[1]), doubleval($status[2]), doubleval($status[3]));
    }
    
    static function getProvider() {
        $empth_ary=array();
        $volumes=array();
        $eths=array();
        $unused_num=0;
        $raid_exist=0;
        $monitor = false;
        
        $md_list = self::fg('a', "sed -rn 's/md(1[1-9]).*/\\1/p' /proc/mdstat");
        foreach($md_list as $num){
            if( $num == "" ) break;

            $database="/raidsys/$num/smb.db";
            if( file_exists($database) ) {
               $table = self::fg('s', "sqlite $database '.tables conf'");
               if($table==""){
                 return self::fireEvnet($empth_ary, $empth_ary, 0, true);
               }
            }

            $tmp_ary=self::getRaidStatus($num);
            if ($tmp_ary[0] != null)
                array_push($volumes,$tmp_ary);
                
            if ($tmp_ary[4]!="Healthy"){
              $monitor = true;
            }
            
            $raid_exist=1;
        }

        $sysmd_list = self::fg('s', "sed -rn 's/md(2[0-9]).*/\\1/p' /proc/mdstat");
        
        if (($raid_exist==0) && ($sysmd_list=="")){
            $unused_num=self::getUnusedDisk();
        }else if (($raid_exist==0) && ($sysmd_list!="")){
            $volumes=array();
            $monitor = true;
        } 
        
        $tmp=self::fg('a', "/img/bin/rc/rc.hv nic");
        foreach($tmp as $k => $nic){
            if( $nic == "" ) break;
            array_push($eths,explode("|", $nic));
        }
        
        return self::fireEvnet($volumes, $eths, $unused_num, $monitor);
    }
    
    static function getVolume() {
        $volumes=array();
        $md_list = self::fg('a', "sed -rn 's/md(1[1-9]).*/\\1/p' /proc/mdstat");
        foreach($md_list as $num){
            if( $num == "" ) break;
            $tmp_ary=self::getRaidStatus($num);
            array_push($volumes,$tmp_ary);
        }
        
        return self::fireEvnet($volumes);
    }
    
    /**
     * @param {} $volume The volume id
     * @param {String} $interface Network interface
     * @param {String} $target Target IP v4
     */
    static function setTarget($configure) {
        $msg=array();
        $result=true;
    
        for( $i = 0 ; $i < count($configure) ; $i++ ) {
            $t_mdnum=$configure[$i][0];
            $t_hv_nic=$configure[$i][1];
            $t_hv_mip=$configure[$i][2];

            shell_exec("/img/bin/rc/rc.hv del_iscsi '" . $t_mdnum . "'");
            $t_iqn=trim(shell_exec("/img/bin/rc/rc.hv m_iqn " . $t_hv_mip));
            if (($t_iqn=="100") || ($t_iqn=="101")){
                array_push($msg,$t_hv_mip);
                $result=false;
            }else{
                $database="/raidsys/".($t_mdnum)."/smb.db";
                $smb_db = new sqlitedb($database,'conf');
                $smb_db->setvar("hv_nic", $t_hv_nic);
                $smb_db->setvar("hv_mip", $t_hv_mip);
                $smb_db->setvar("hv_iqn", $t_iqn);
                unset($smb_db);
              
                shell_exec("/img/bin/rc/rc.hv build_iscsi '" . $t_mdnum . "' '" . $t_iqn ."'");
                shell_exec("/img/bin/rc/rc.hv check_conn");
                shell_exec("/img/bin/rc/rc.hv cron_add");
            }
        }

        /**
         * Grid store index
         * 0. setTarget Fail
         * 1. setTarget Success
         * msg=ip. Can't connect master
         */
        return self::fireEvnet($result, $msg);
    }
    
    static function disconnect($volumes) {
        // $volumes data same as reconnect
        $c_ip=self::fg('s', "/img/bin/function/get_interface_info.sh get_ip " . $volumes[0][1]);
        $ret=self::fg('i', "/img/bin/rc/rc.hv remove_master_disk '" . $volumes[0][2] . "' '" . $c_ip . "'");
        
        if ($ret==0){
            shell_exec("rm /raidsys/" . $volumes[0][0] . "/connect_ok");
            shell_exec("/img/bin/rc/rc.hv cron_del");
        }else
            $ret=1;
        
        return self::fireEvnet($ret);
    }
    
    static function reconnect($volumes) {
        shell_exec("/img/bin/rc/rc.hv check_conn");
        shell_exec("/img/bin/rc/rc.hv cron_add");
        
        return self::fireEvnet(true);
    }
    

    static function getRaidStatus($mdnum) {
        $mdnum=trim($mdnum);
        $database="/raidsys/".$mdnum ."/smb.db";
        
        if (file_exists($database)){
            $db = new sqlitedb($database,'conf');
            $raidid=trim(shell_exec("cat /var/tmp/raid$mdnum/raid_id"));
            
            $md=new RAIDINFO();
            $md = $md->getINFO($mdnum);
            
            $capacity=self::getCapacity("md$mdnum");
            $capacity=$capacity . " GB";
            
            $raidlevel=trim(shell_exec("cat /var/tmp/raid$mdnum/raid_level"));
            
            $spare=array();
            $spare=$md["LocPosSpare"];

            $raidstatus=trim(shell_exec("cat /var/tmp/raid$mdnum/rss"));
            $intf=$db->getvar("hv_nic","");
            $hv_mip=$db->getvar("hv_mip","");
        
            if ($intf==""){
                $tmp=trim(shell_exec("/img/bin/rc/rc.hv first_nic"));
                $t_array=explode("|",$tmp);
                $intf=$t_array[0];
            }

            $hvstatus=trim(shell_exec("/img/bin/rc/rc.hv initiatior_status $mdnum"));
            if ($hvstatus!="")
                $hvstatus=2;//"Connected";
            else
                $hvstatus=3;//"Disconnected";

            $tray_list = $md["LocPosList"];
            unset($db);
        }
            
        /**
         * Grid store index
         * 1. raid
         * 2. level
         * 3. capacity
         * 4. spare
         * 5. status
         * 6. interface
         * 7. target
         * 8. connection
         * 9. md
         * 10. tray[] list
         */
        return array($raidid,$raidlevel,$capacity,$spare,$raidstatus,$intf,$hv_mip,$hvstatus,$mdnum,$tray_list);
    }
    
    static function getCapacity($partition) {
        $partition=trim($partition);
      
        $strExec="cat /proc/partitions | awk '{if (\$4==\"" . $partition ."\") printf \$3}'";
        $capacity=shell_exec($strExec);
        if ($capacity==""){
            $capacity=0;
        }else{
            $capacity=round(($capacity/(1024*1024)), 1);
        }
      
        return $capacity;
    }
    
}

?>
