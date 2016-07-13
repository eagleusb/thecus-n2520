<?
include_once("INFO.base.php");
class RAIDINFO extends INFO{
  var $raid_content = array();
  var $swapname="md0";
  var $sysname="";
  var $swapname2="md10";
  var $filesystem="ext3";
  var $mdselect="1"; //0:md[0-9], 1: first search md6[0-9], then md[0-9] 
  
  function setmdselect($num){
    if ($num!='1')
      $this->mdselect="0";
    else
      $this->mdselect="1";
  }
  
  function parse(){
    if (NAS_DB_KEY == '1'){
      $strExec="/img/bin/check_service.sh \"total_tray\"";
      $total_tray=trim(shell_exec($strExec));
      $three_bay_on=trim(shell_exec('cat /proc/thecus_io | grep "3BAY:" | cut -d" " -f2'));
      if($three_bay_on == "ON"){
            $total_tray="3";
      }
      $strexec="cat /proc/scsi/scsi |awk '/Thecus:/&&/Removable:0/{strdisk=sprintf(\"%s%s,%s2 \",strdisk,substr($2,6,3),substr($3,6,length($3)-5))}END{print strdisk}'";
    }else{
      $total_tray=trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
      $strexec="cat /proc/scsi/scsi |awk '/Thecus:/{strdisk=sprintf(\"%s%s,%s1 \",strdisk,substr($2,6,4),substr($3,6,4))}END{print strdisk}'";
    }

    $strdisk = trim(shell_exec($strexec));
    $tray_disk_list = explode(" ",$strdisk);//because sd*1 partition 200MB system reserve #Leon 2005/5/19
    $disk_list=array();
    $tray_map=array();
    foreach($tray_disk_list as $line){
      if($line!=""){
        $tray_disk_info=explode(",",$line);
        if(((trim($tray_disk_info[0])<=$total_tray)&&(trim($tray_disk_info[0])>0))||(trim($tray_disk_info[0])>52)){
          $tray_map[trim($tray_disk_info[0])]=trim($tray_disk_info[1]);
          $disk_list[]=trim($tray_disk_info[1]);
        }
      }
    }
    $this->content["DiskList"] = $disk_list;
    $this->content["TrayMap"] = $tray_map;
   
    $partition_list=file("/proc/partitions");
    $trash=array_shift($partition_list);
    $trash=array_shift($partition_list);
    foreach($partition_list as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      if($aryline[4]!=""){
        $this->partition[$aryline[4]]=array($aryline[1],$aryline[2],$aryline[3]);
      }
    }
   
    $this->raid_content = $this->getContent();
    $this->getTotalRaidDisk();
    $this->getRaidMaster();
    $this->getEncrypt();
    $this->getRaidFS();
    $this->getRaidID();
    $this->getRaidLevel();
    $this->getRaidassume();
    $this->getRaidStatus();
    $this->getRaidDisk();
    $this->getTotal();
    $this->getSyslv();
    $this->getData();
    $this->getSnapshot();
    $this->getUSB();
    $this->getiSCSI();
    $this->getUnUsed();
    $this->getSpareList();
    $this->getNotAssignedList();
    $this->getEmptySlot();
    $this->getChunkSize();
    $this->getAllRaidID();
  }
  
  function getMdArray(){
    
    if ($this->mdselect=='1'){
      $strExec="/bin/cat /proc/mdstat | awk -F: '/^md6[0-9] :/{printf(\"md%s\\n\", substr($1,3))}' | sort -u";
      $md_list=shell_exec($strExec);
    }
    
    if ($md_list == ""){
      $strExec="/bin/cat /proc/mdstat | awk -F: '/^md[0-9] :/{printf(\"md%s\\n\",  substr($1,3))}' | sort -u";
      $md_list=shell_exec($strExec);
    }
    
    $md_array_tmp=explode("\n",$md_list);
    foreach($md_array_tmp as $md_name){
      if (NAS_DB_KEY == '1'){
        if($md_name!="" && $md_name!=$this->swapname && $md_name!=$this->sysname){
          $md_array[]=trim(substr($md_name,2,strlen($md_name)-2));
        }
      }else{
        if($md_name!=""){
          $md_array[]=trim(substr($md_name,2,strlen($md_name)-2));
        }
      }
    }
    return $md_array;
  }
  
  function getHVArray(){

    $strExec="/bin/cat /proc/mdstat | awk -F: '/^md1[1-9] :/{printf(\"md%s\\n\",  substr($1,3))}' | sort -u";
    $hv_list=shell_exec($strExec);

    $hv_array_tmp=explode("\n",$hv_list);
    foreach($hv_array_tmp as $hv_name){
      if($hv_name!=""){
        $hv_array[]=trim(substr($hv_name,2,strlen($hv_name)-2));
      }
    }
    return $hv_array;
  }
  
  function getContent(){
    $cmd="mdadm -D " . $this->mddisk;
    $content = shell_exec($cmd);
    $content = explode("\n",$content);
    return $content;
  }

  function getTotalRaidDisk(){
    $strExec="/bin/cat /proc/scsi/scsi | awk -F' '  '/Tray:/{printf(\"%s %s\\n\",$2,$3)}'";
    $scsi_list=trim(shell_exec($strExec));
    $scsi_list=explode("\n",$scsi_list);    
    $cmd="mdadm -D /dev/md[0-9];mdadm -D /dev/md[3-4][0-9]";
     $content = shell_exec($cmd);
     $content = explode("\n",$content);
     $active_raid_disk = array();
     foreach($content as $v){
       if(preg_match("/active sync/", $v)){
         $active_raid_disk[] = $v;
       }elseif(preg_match("/spare/", $v)){
         $active_raid_disk[] = $v;
       }
     }

     $total_raid_disk = array();
     foreach($active_raid_disk as $v){
       $v = explode(" ",$v);
       $stack = array();
       foreach($v as $k1 => $v1){
         if ($v1 !=""){
           $stack[]=$this->filter($v1);
         }
       }
       foreach($stack as $i){
        if(preg_match("/\/dev\/sd/",$i)){
           $total_raid_disk_tmp=str_replace("/dev/","",$i);
          for($c=0;$c<count($scsi_list);$c++){
            if(preg_match("/Disk:" . substr($total_raid_disk_tmp,0,strlen($total_raid_disk_tmp)-1) . "$/", $scsi_list[$c])){
             $total_raid_disk[] = $total_raid_disk_tmp;
           }
         }
       }
     }
    }
    $total_raid_disk_tray=array();
    foreach($total_raid_disk as $d){
      foreach($this->content["TrayMap"] as $k=>$v){
        if(trim($d)==trim($v)){
          $total_raid_disk_tray[]=$k;
          break;
        }
      }
    }
    $this->content["TotalRaidDisk"] = $total_raid_disk;
    $this->content["TotalRaidDiskTray"] = implode(",",$total_raid_disk_tray);
  }
  
  function getRaidMaster(){
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /".$this->raid_folder."/sys/raid.db \"select v from conf where k='raid_master'\"";
    }else{
      $strExec="/usr/bin/sqlite /raidsys/".$this->md_num."/smb.db \"select v from conf where k='raid_master'\"";
    }

    $master=trim(shell_exec($strExec));
    $this->content["RaidMaster"]=$master;
  }

  function getEncrypt(){
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /".$this->raid_folder."/sys/raid.db \"select v from conf where k='encrypt'\"";
    }else{
      $strExec="/usr/bin/sqlite /raidsys/".$this->md_num."/smb.db \"select v from conf where k='encrypt'\"";
    }
    $encrypt=trim(shell_exec($strExec));
    $this->content["Encrypt"]=$encrypt;
    $this->encrypt=$this->content["Encrypt"];
  }
  
  function getRaidFS(){
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /".$this->raid_folder."/sys/raid.db \"select v from conf where k='filesystem'\"";
    }else{
      $strExec="/usr/bin/sqlite /raidsys/".$this->md_num."/smb.db \"select v from conf where k='filesystem'\"";
    }
    $FSMode=trim(shell_exec($strExec));
    $this->content["RaidFS"]=($FSMode==""?"N/A":$FSMode);
    $this->filesystem=$this->content["RaidFS"];
  }
  
  function getRaidID(){
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /".$this->raid_folder."/sys/raid.db \"select v from conf where k='raid_name'\"";
    }else{
      $strExec="/usr/bin/sqlite /raidsys/".$this->md_num."/smb.db \"select v from conf where k='raid_name'\"";
    }
    $id=trim(shell_exec($strExec));
    $this->content["RaidID"]=$id;
  }
  
  function getRaidassume(){
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /".$this->raid_folder."/sys/raid.db \"select v from conf where k='assume_clean'\"";
    }else{
      $strExec="/usr/bin/sqlite /raidsys/".$this->md_num."/smb.db \"select v from conf where k='assume_clean'\"";
    }
    $assume_clean=trim(shell_exec($strExec));
    $this->content["Assume_clean"]=$assume_clean;
  }
  
  function getRaidLevel(){
    $strExec="/bin/cat /var/tmp/".$this->raid_folder."/raid_level";
    $level=trim(shell_exec($strExec));
    $this->content["RaidLevel"] = $level;
    return;
    $content = '';
    foreach($this->raid_content as $v){
      if(ereg('Raid Level', $v)){
        $content = $v;
      }
    }
    $content = explode(" ",$content);
    $stack = array();
    foreach($content as $k1 => $v1){
      if ($v1 !=""){
        $stack[]=$v1;
      }
    }
    $level=trim($stack[3]);
    if($level=="linear"){
      $level="J";
    }elseif($level=="raid10"){
      $level="10";
    }else{
      $level=$level[4];
    }
    $this->content["RaidLevel"] = $level;
  }
  
  function getRaidStatus(){
    $strExec="/bin/cat /var/tmp/".$this->raid_folder."/rss";
    $status=trim(shell_exec($strExec));
    if($this->encrypt)
      $JBOD_Status=shell_exec("/bin/ps | grep loop".strval($this->md_num+50));
    else
      $JBOD_Status=shell_exec("/bin/ps | grep $this->mddisk");
    if(preg_match("/e2fsck/",$JBOD_Status)){
      preg_match_all("/\s*=*\s*[\\/|-]\s*(\d*\.\d*%)/",$status,$matches);
      $prompt = (trim($matches[1][count($matches[1])-1])=="")? "Wait....":$matches[1][count($matches[1])-1];
      $status = "Check Disk ".$prompt;
    }
    elseif(preg_match("/resize2fs/",$JBOD_Status)){
      $prompt = (substr_count($status,"X")==0)? "Wait....":round(substr_count($status,"X")/160,2)*100 ." %";
      $status = "Resize Disk ".$prompt;
    }
    $this->content["RaidStatus"]=$status;
  }
  
  function getRaidDisk(){
    $strExec="/bin/cat /proc/scsi/scsi | awk -F' '  '/Tray:/{printf(\"%s %s\\n\",$2,$3)}'";
    $scsi_list=trim(shell_exec($strExec));
    $scsi_list=explode("\n",$scsi_list);
    $f = array();
    foreach($this->raid_content as $v){
      if(preg_match("/active sync/", $v)){
        $f[] = $v;
      }
    }
    $raid_list = array();
    $raid_disk = array();
    $locpos_list = array();
    foreach($f as $v){
      $v = explode(" ",$v);
      $stack = array();
      foreach($v as $k1 => $v1){
        if ($v1 !=""){
          $stack[]=$this->filter($v1);
        }
      }
      foreach($stack as $disk){
        if(preg_match("/dev\/sd/",$disk)){
          $raid_disk[]=str_replace("/dev/","",$disk);
          $raid_disk_tmp=str_replace("/dev/","",$disk);
          for($c=0;$c<count($scsi_list);$c++){
            if(preg_match("/Disk:" . substr($raid_disk_tmp,0,strlen($raid_disk_tmp)-1) . "$/", $scsi_list[$c])){
              //$raid_list[] = $scsi_list[$c][5];
              $scsi_list2=explode(" ",$scsi_list[$c]);
              $raid_list[] = substr($scsi_list2[0],5);
              $loc=floor((int)substr($scsi_list2[0],5)/26)-1;
              $pos=(int)substr($scsi_list2[0],5)-($loc+1)*26;
              $locpos_list[] = $loc > 0 ? "J".$loc."-".$pos : $pos;
            }
          }
        }else{
          if(preg_match("/dev\/md/",$disk)){
            $nesmd_content = array();
            $cmd="mdadm -D " . $disk;
            $nesmd_content = shell_exec($cmd);
            $nesmd_content = explode("\n",$nesmd_content);
            $nes_f = array();
            foreach($nesmd_content as $v){
              if(preg_match("/active sync/", $v)){
                $nes_f[] = $v;
              }
            }
            foreach($nes_f as $v){
              $v = explode(" ",$v);
              $nes_stack = array();
              foreach($v as $k1 => $v1){
                if ($v1 !=""){
                  $nes_stack[]=$this->filter($v1);
                }
              }
              foreach($nes_stack as $disk){
                if(preg_match("/dev\/sd/",$disk)){
                  $raid_disk[]=str_replace("/dev/","",$disk);
                  $raid_disk_tmp=str_replace("/dev/","",$disk);
                  for($c=0;$c<count($scsi_list);$c++){
                    if(preg_match("/Disk:" . substr($raid_disk_tmp,0,strlen($raid_disk_tmp)-1) . "$/", $scsi_list[$c])){
                      //$raid_list[] = $scsi_list[$c][5];
                      $scsi_list2=explode(" ",$scsi_list[$c]);
                      $raid_list[] = substr($scsi_list2[0],5);
                      $loc=floor((int)substr($scsi_list2[0],5)/26)-1;
                      $pos=(int)substr($scsi_list2[0],5)-($loc+1)*26;
                      $locpos_list[] = $loc > 0 ? "J".$loc."-".$pos : $pos;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    $this->content["RaidListTray"]=implode(",",$raid_list);
    $this->content["RaidList"] = $raid_list;
    $this->content["RaidDisk"] = $raid_disk;
    $this->content["LocPosList"] = $locpos_list;
  }
  
  function getTotal(){
    $total=round((floatval($this->partition[$this->mdname][2])/1024/1024)*10)/10;
    $this->content["RaidTotal"]=($this->partition[$this->mdname]!="")?$total : "N/A";
  }
  
  function getData(){
    if (NAS_DB_KEY == '1'){
      if($this->filesystem=="zfs"){
        $df_table=shell_exec("/usr/bin/zfs list");
      }else{
        $df_table=shell_exec("df -k");
      }
      $dflist_array=explode("\n",$df_table);
      $trash=array_shift($dflist_array);
      foreach($dflist_array as $line){
        $aryline=preg_split("/[\s ]+/",$line);
        if($this->filesystem=="zfs"){
          $zfshead=substr($aryline[0],7);
        }
        $fs="";
        if (preg_match("/zfspool/",$aryline[0])) {
          //printf("A aryline[0]=%s <br>",$aryline[0]);
          $fs="ZFS";
          if (!preg_match("/[\/]/",$aryline[0])) {
            $dfkey=$aryline[0];
            //printf("C dfkey=%s <br>",$dfkey);
          } else {
            $dfkey="";
          }
        }else{
          $dfkey=str_replace("/","-",substr($aryline[0],5));
        }

        //echo "B aryline[0]=" . $aryline[0] . " dfkey=$dfkey <br>";
        if($dfkey!=""){
          //printf("D dfkey=%s <br>",$dfkey);
          if($this->filesystem=="zfs"){
            $df_array[$dfkey]=array($aryline[1],"",$aryline[2],$aryline[3],$aryline[4],$fs);
          }else{
            $df_array[$dfkey]=array($aryline[1],$aryline[2],$aryline[3],$aryline[4],$aryline[5],$fs);
          }
        }
      }
      $lvsize="0";
      $datakey="";
      //echo "<pre>";
      //print_r($df_array);
      foreach($df_array as $df_key => $df_value){
        //printf("A dfkey=%s zfspoolname=%s <br>",$df_key,$this->zfspoolname);
        if ($df_key==$this->zfspoolname) {
          $datakey=$this->zfspoolname;
        }else{
          if($this->encrypt){
            $datakey="loop".($this->md_num-1);
          }else{
            $datakey=$this->data_lvname;
          }
        }
        if($df_key==$datakey){
          if(trim($df_value[5])=="ZFS"){
            $strExec="/usr/bin/zfs get -Hp used,available ${df_key} | awk '{printf(\"%s-%s\",$3)}'";
            $size_info=trim(shell_exec($strExec));
            $size_array=explode("-",$size_info);
            $lvsize=($size_array[0]+$size_array[1])/1024;
            $lvusage=$size_array[0]/1024;
          }else{
            $lvsize=trim($df_value[0]);
            $lvusage=trim($df_value[1]);
          }
          $lvpercent=trim($df_value[3]);
          $lvmount=trim($df_value[4]);
          $df_fs=trim($df_value[5]);
          break;
        }
      }
      $usage=round($lvusage/1024/1024,1);
      $this->content["RaidUsage"]=($df_array[$datakey]!="")?strval($usage) : "N/A";
      $data=round($lvsize/1024/1024,1);
      //printf("B dfkey=%s zfspoolname=%s usage=%d data=%d <br>",$df_key,$this->zfspoolname,$usage,$data);
      $this->content["RaidData"]=($df_array[$datakey]!="")?strval($data) : "N/A";
      //printf("C RaidUsage=%s RaidData=%s <br>",$this->content["RaidUsage"],$this->content["RaidData"]);
      //#####Partition#####
      if($this->encrypt){
        $strExec="/bin/ls -al /dev/loop".($this->md_num-1);
        $data_info=shell_exec($strExec);
        $data_array=explode("\n",$data_info);
        foreach($data_array as $list){
          $aryline=preg_split("/[\s ]+/",$list);
          $datakey=substr($aryline[9],5);
          if($datakey!=""){
            $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
            $lvminor=$aryline[5];
            $lvsize=0;
            foreach($this->partition as $part_key =>$part_value){
            //echo "Part Value:$part_value[2]";
              if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
                $lvsize=$part_value[2];
                break;
              }
            }
          }else{
            /// Data volume may not mounted. Just call lvdisplay to get info
            $strExec="lvdisplay --unit k /dev/vg".($this->md_num-1)."/lv0 | awk '/LV Size/{print \$3}'";
            $lvsize=shell_exec($strExec);
          }
        }
      }else{
        $strExec="/bin/ls -al /dev/mapper/".$this->vg_name."-lv0";
        $data_info=shell_exec($strExec);
        $data_array=explode("\n",$data_info);
        foreach($data_array as $list){
          $aryline=preg_split("/[\s ]+/",$list);
          $datakey=substr($aryline[9],12);
          if($datakey!=""){
            $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
            $lvminor=$aryline[5];
            $lvsize=0;
            foreach($this->partition as $part_key =>$part_value){
              if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
                $lvsize=$part_value[2];
                break;
              }
            }
          }
        }
      }
      $data=round($lvsize/1024/1024,1);
      $sys=$this->content["RaidSyslv"];
      $data_partition=$data+$sys;
      $this->content["RaidData_partition"]=($data_partition!="0" || $data_partition!="")?$data_partition : "N/A";
    }else{
      $RPercentage_cmd="df -m | grep /raid". $this->md_num ." |head -1| awk 'BEGIN{OFS=\",\"}{print $3,$4,$2}'";
      $RPercentage=trim(shell_exec($RPercentage_cmd));
      $sizearray=explode(",",$RPercentage);
      $UsageSize=$sizearray[0];
      $UsageSize=round($UsageSize/1024,1);
      $this->content["RaidUsage"]=($UsageSize!="0" || $UsageSize!="")?$UsageSize : "N/A";
      $Datasize=$sizearray[2];
      $Datasize=round($Datasize/1024,1);
      $this->content["RaidData"]=($Datasize!="0" || $Datasize!="")?$Datasize : "N/A";
      $Partitionsize=$sizearray[2];
      $Partitionsize=round($Partitionsize/1024,1);
      $this->content["RaidData_partition"]=($Partitionsize!="0" || $Partitionsize!="")?$Partitionsize : "N/A";
    }
  }
  
  function getSnapshot(){
    $strExec="/bin/ls -al /dev/mapper/".$this->vg_name."-snap-cow";
    $snapshot_info=shell_exec($strExec);
    $snapshot_array=explode("\n",$snapshot_info);
    foreach($snapshot_array as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      $snapshotkey=substr($aryline[9],12);
      if($snapshotkey!=""){
        $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
        $lvminor=$aryline[5];
        $lvsize=0;
        foreach($this->partition as $part_key =>$part_value){
          if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
            $lvsize=$part_value[2];
            break;
          }
        }
      }
    }
    $snapshot=round($lvsize/1024/1024,1);
    $this->content["RaidSnapshot"]=($snapshot!="0" || $snapshot!="")?$snapshot : "N/A";
  }
  
  function getUSB(){
    $strExec="/bin/ls -al /dev/mapper/".$this->vg_name."-lv1";
    $usb_info=shell_exec($strExec);
    $usb_array=explode("\n",$usb_info);
    foreach($usb_array as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      $usbkey=substr($aryline[9],12);
      if($usbkey!=""){
        $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
        $lvminor=$aryline[5];
        $lvsize=0;
        foreach($this->partition as $part_key =>$part_value){
          if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
            $lvsize=$part_value[2];
            break;
          }
        }
      }
    }
    $usb=round($lvsize/1024/1024,1);
    $this->content["RaidUSB"]=($usb!="0" || $usb!="")?$usb : "N/A";
  }
  
  function getiSCSI(){
    $strExec="/bin/ls -al /dev/mapper/".$this->vg_name."-iscsi*";
    $iscsi_info=shell_exec($strExec);
    $iscsi_array=explode("\n",$iscsi_info);
    $lvsize=0;
    foreach($iscsi_array as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      $iscsikey=substr($aryline[9],12);
      if($iscsikey!=""){
        $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
        $lvminor=$aryline[5];
        foreach($this->partition as $part_key =>$part_value){
          if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
            $lvsize=$lvsize+$part_value[2];
            break;
          }
        }
      }
    }
    
    $strExec="/bin/ls -al /dev/mapper/".$this->vg_name."-thinpool";
    $thin_info=shell_exec($strExec);

    if($thin_info != ""){
      $aryline=preg_split("/[\s ]+/",$thin_info);
      $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
      $lvminor=$aryline[5];
      foreach($this->partition as $part_key =>$part_value){
        if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
          $lvsize=$lvsize+$part_value[2];
          break;
        }
      }
    }
    
    $iscsi=round($lvsize/1024/1024,1);
    $this->content["RaidiSCSI"]=($iscsi!="0" || $iscsi!="")?$iscsi : "N/A";
  }
  
  function getSyslv(){
    $strExec="/bin/ls -al /dev/mapper/".$this->vg_name."-syslv";
    $syslv_info=shell_exec($strExec);
    $syslv_array=explode("\n",$syslv_info);
    $lvsize=0;
    foreach($syslv_array as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      $syslvkey=substr($aryline[9],12);
      if($syslvkey!=""){
        $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
        $lvminor=$aryline[5];
        foreach($this->partition as $part_key =>$part_value){
          if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
            $lvsize=$lvsize+$part_value[2];
            break;
          }
        }
      }
    }
    $syslv=round($lvsize/1024/1024,1);
    $this->content["RaidSyslv"]=($syslv!="0" || $syslv!="")?$syslv : "N/A";
  }
  
  function getUnUsed(){
    $unused=$this->content["RaidTotal"]-$this->content["RaidData_partition"]-$this->content["RaidSnapshot"]-$this->content["RaidUSB"]-$this->content["RaidiSCSI"];
    switch ($this->content["RaidFS"]) {
    case "xfs":
      $unused=$unused - $this->content["RaidTotal"]*0.0005;
      break;
    case "ext3":
    case "ext4":
      $unused=$unused - $this->content["RaidTotal"]*0.0625;
      break;
    case "btrfs":
      break;
    }
    if($unused<0) $unused=0;
    $this->content["RaidUnUsed"]=$unused;
  }
  
  function getSpareList(){
    $strExec="/bin/cat /proc/scsi/scsi | awk -F' '  '/Tray:/{printf(\"%s %s\\n\",$2,$3)}'";
    $scsi_list=trim(shell_exec($strExec));
    $scsi_list=explode("\n",$scsi_list);
    $f=array();
    $f2=array();
    foreach($this->raid_content as $v){
      if(preg_match("/spare/", $v)){
        $f[] = $v;
      }
      if(preg_match("/active sync/", $v)){
        $f2[] = $v;
      }
    }
    $spare_list = array();
    $spare = array();
    $locpos_list = array();
    foreach($f as $v){
      $v = explode(" ",$v);
      $stack = array();
      foreach($v as $k1 => $v1){
        if($v1 !=""){
          $stack[]=$this->filter($v1);
        }
      }
      if($stack[5]!="rebuilding"){
        $spare_list[] = str_replace("/dev/","",$stack[5]);
        $spare_tmp=str_replace("/dev/","",$stack[5]);
      }else{
        $spare_list[] = str_replace("/dev/","",$stack[6]);
        $spare_tmp=str_replace("/dev/","",$stack[6]);
      }
      for($c=0;$c<count($scsi_list);$c++){
        if(preg_match("/Disk:" . substr($spare_tmp,0,strlen($spare_tmp)-1) . "$/", $scsi_list[$c])){
          $scsi_list2=explode(" ",$scsi_list[$c]);
          //if(substr($scsi_list2[0],5) < 100)
            $spare[] = substr($scsi_list2[0],5);
            $loc=floor((int)substr($scsi_list2[0],5)/26)-1;
            $pos=(int)substr($scsi_list2[0],5)-($loc+1)*26;
            $locpos_list[] = $loc > 0 ? "J".$loc."-".$pos : $pos;
        }
      }
    }
    
    foreach($f2 as $v){
      $v = explode(" ",$v);
      $stack = array();
      foreach($v as $k1 => $v1){
        if ($v1 !=""){
          $stack[]=$this->filter($v1);
        }
      }
      foreach($stack as $disk){
        if(preg_match("/dev\/md/",$disk)){
          $nesmd_content = array();
          $cmd="mdadm -D " . $disk;
          $nesmd_content = shell_exec($cmd);
          $nesmd_content = explode("\n",$nesmd_content);
          $nes_f = array();
          foreach($nesmd_content as $v){
            if(preg_match("/spare/", $v)){
              $nes_f[] = $v;
            }
          }
          foreach($nes_f as $v){
            $v = explode(" ",$v);
            $stack = array();
            foreach($v as $k1 => $v1){
              if($v1 !=""){
                $stack[]=$this->filter($v1);
              }
            }
            if($stack[5]!="rebuilding"){
              $spare_list[] = str_replace("/dev/","",$stack[5]);
              $spare_tmp=str_replace("/dev/","",$stack[5]);
            }else{
              $spare_list[] = str_replace("/dev/","",$stack[6]);
              $spare_tmp=str_replace("/dev/","",$stack[6]);
            }
            for($c=0;$c<count($scsi_list);$c++){
              if(preg_match("/Disk:" . substr($spare_tmp,0,strlen($spare_tmp)-1) . "$/", $scsi_list[$c])){
                $scsi_list2=explode(" ",$scsi_list[$c]);
                if(substr($scsi_list2[0],5) < 100)
                  $spare[] = substr($scsi_list2[0],5);
                $loc=floor((int)substr($scsi_list2[0],5)/26)-1;
                $pos=(int)substr($scsi_list2[0],5)-($loc+1)*26;
                $locpos_list[] = $loc > 0 ? "J".$loc."-".$pos : $pos;
              }
            }
          }
        }
      }
    }
    
    $this->content["SpareList"] = $spare_list;
    $this->content["Spare"] = $spare;
    $this->content["SpareTray"] = implode(",",$spare);
    $this->content["LocPosSpare"] = $locpos_list;
  }
  
  function getNotAssignedList(){
    $not_assigned_list = $this->content["DiskList"];
    $raid_list = $this->content["RaidDisk"];
    $spare_list = $this->content["SpareList"];
    $total_raid_disk = $this->content["TotalRaidDisk"];
    foreach($raid_list as $k => $v){
      if(in_array($v,$not_assigned_list)){
        $key = array_search($v,$not_assigned_list);
        unset($not_assigned_list[$key]);
      }
    }
    foreach($spare_list as $k => $v){
      if(in_array($v,$not_assigned_list)){
        $key = array_search($v,$not_assigned_list);
        unset($not_assigned_list[$key]);
      }
    }
    foreach($total_raid_disk as $k => $v){
      if(in_array($v,$not_assigned_list)){
        $key = array_search($v,$not_assigned_list);
        unset($not_assigned_list[$key]);
      }
    }
    $this->content["NotAssignedList"] = $not_assigned_list;
  }
  
  //#############################################################
  //#  Compare tray id whether in the not assign disk
  //#  Input:
  //#    $tray_id:Tray id array from POST
  //#  Output:0/1
  //#    0:False
  //#    1:True
  //#############################################################
  function check_post_notassigndisk($tray_id){
    $tray_id_count=count($tray_id);
    $c="0";
    foreach($tray_id as $v){
      $dev=$this->content["TrayMap"][$v];
      foreach($this->content["NotAssignedList"] as $not_assign){
        if($dev==$not_assign){
          $c++;
          continue;
        }
      }
    }
    if($c==$tray_id_count){
      return 0;//no error
    }else{
      return 1;//error
    }
  }
  //#############################################################
  
  function getEmptySlot(){
    if (NAS_DB_KEY == '1'){
      $maxdisk=trim(shell_exec("/img/bin/check_service.sh total_tray"));
    }else{
      $maxdisk=trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
    }
    $empty_list=array();
    for ($i=1 ;$i <= $maxdisk;$i++){
      $empty_list[$i]=array(1 => $i,2 => $i);
    }
    $sata = shell_exec("cat /proc/scsi/scsi");
    if (NAS_DB_KEY == '1'){
      preg_match_all("/Tray:(\d{1,2})\s*Disk:sd(\w)\s*Model:(.+)Rev:(.+)Removable:([^\n]+)/",$sata,$hdd_info);
    }else{
      preg_match_all("/Tray:(\d{1,3})\s*Disk:sd(\w+)\s*Model:(.+)Rev:(.+)Intf:(.+)LinkRate:(.+)Loc:(.+)Pos:([^\n]+)/",$sata,$hdd_info);
    }
    for($i=0;$i<count($hdd_info[1]);$i++){
      if($hdd_info[5][$i]=='0'){
        unset($empty_list[$hdd_info[1][$i]]);
      }
    }
    $this->content["EmptySlotList"] = $empty_list;
  }
  
  function getChunkSize(){
    $this->content["ChunkSize"] = '';
    foreach($this->raid_content as $v){
      if(trim($this->content["RaidLevel"]) == 'J' ){
        if( preg_match_all("/Rounding : (\d+)/",$v,$result)){
         $this->content["ChunkSize"] = $result[1][0];
        }
      }else{
        if( preg_match_all("/Chunk Size : (\d+)/",$v,$result)){
         $this->content["ChunkSize"] = $result[1][0];
        }
      }
    }
  }
  
  function getAllRaidID(){
    $md_array=$this->getMdArray();
    $count=count($md_array);
    $raid_id=array();
    foreach($md_array as $num){
      if($num!=$this->md_num){
        if (NAS_DB_KEY == '1'){
          $strExec="/usr/bin/sqlite /raid".($num-1)."/sys/raid.db \"select v from conf where k='raid_name'\"";
        }else{
          $strExec="/usr/bin/sqlite /raidsys/".$num."/smb.db \"select v from conf where k='raid_name'\"";
        }
        $raid_name=shell_exec($strExec);
        $raid_id[]=trim($raid_name);
      }
    }
    $hv_array=$this->getHVArray();
    $count=count($hv_array);
    foreach($hv_array as $num){
      if($num!=$this->md_num){
        if (NAS_DB_KEY == '1'){
          $strExec="/usr/bin/sqlite /raid".($num-1)."/sys/raid.db \"select v from conf where k='raid_name'\"";
        }else{
          $strExec="/usr/bin/sqlite /raidsys/".$num."/smb.db \"select v from conf where k='raid_name'\"";
        }
        $raid_name=shell_exec($strExec);
        $raid_id[]=trim($raid_name);
      }
    }
    $this->content["AllRaidName"] = $raid_id;
  }
  
  function getNewMdNum(){
    $md_array=$this->getMdArray();
    if (NAS_DB_KEY == '1'){
      for($i=1;$i<10;$i++){
        $count="0";
        foreach($md_array as $md){
          if($i==$md){
            $count=$count+1;
          }
        }
        if($count=="0"){
          $md_num=$i;
          break;
        }
      }
    }else{
      for($i=0;$i<10;$i++){
        $count="0";
        foreach($md_array as $md){
          if($i==$md){
            $count=$count+1;
          }
        }
        if($count=="0"){
          $md_num=$i;
          break;
        }
      }
    }
    return $md_num;
  }
  
  function getNewHVNum(){
    $hv_array=$this->getHVArray();

    for($i=11;$i<19;$i++){
      $count="0";
      foreach($hv_array as $hv){
        if($i==$hv){
          $count=$count+1;
        }
      }
      if($count=="0"){
        $hv_num=$i;
        break;
      }
    }

    return $hv_num;
  }
  
  function getCapacity($num,$lvname){
    if (NAS_DB_KEY == '1'){
      $strExec="/bin/ls -al /dev/mapper/vg".($num-1)."-".$lvname;
    }else{
      $strExec="/bin/ls -al /dev/mapper/vg".($num)."-".$lvname;
    }
    $iscsi_info=shell_exec($strExec);
    $iscsi_array=explode("\n",$iscsi_info);
    $lvsize=0;
    foreach($iscsi_array as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      $iscsikey=substr($aryline[9],12);
      if($iscsikey!=""){
        $lvmajor=substr($aryline[4],0,strlen($aryline[4])-1);
        $lvminor=$aryline[5];
        foreach($this->partition as $part_key =>$part_value){
          if(($lvmajor==$part_value[0]) && ($lvminor==$part_value[1])){
            $lvsize=$lvsize+$part_value[2];
            break;
          }
        }
      }
    }
    $iscsi=round($lvsize/1024/1024,1);
    return $iscsi;
  }
}
?>
