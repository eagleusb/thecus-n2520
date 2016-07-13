<?
require_once("inifile.class.php");
require_once('foo.class.php');
require_once('info/raidinfo.class.php');
require_once('info/diskinfo.class.php');
//================================================
//  
//  By hubert_huang@thecus.com
//
//  create a new instance:
//  $raid=new raid();
//
//  To create:
//  $raid->create($post);
//  $raid->commit();
//
//  Array
//  (
//      [prefix] => raid
//      [_type] => 
//      [_chunk] => 64
//      [_notused] => Array
//      (
//      [0] => 
//      )
//  
//      [_inraid] => Array
//      (
//      [0] => 0
//      [1] => 1
//      )
//  
//      [_spare] => Array
//      (
//      [0] => 2
//      [1] => 3
//      )
//  
//  )
//================================================
class raid extends foo {
  const mdadm=MDADM_PATH;
  const mdstat="/proc/mdstat";
  const chunk_size=64;
  const thecus_io="/proc/thecus_io";
  const sata_driver="/proc/scsi/mvSata/0";
  const raidconf_old="/tmp/raid.old";
  const raidconf_new="/tmp/raid.new";
  const medata_version="1.0";
  const chkgpt_cmd="/img/bin/gptchk -c ";
  const gpt_act="/img/bin/gpt_act.sh";
  const gpt="GPT";
  const mbr="MBR";
  public static $devmd="/dev/md1";
  public static $mdname="md1";
  public static $mdnum="1";
  public static $swapmd="/dev/md0";
  public static $swapmd_name="md0";
  public static $sysmd="/dev/md11";
  static $raid_status="/var/tmp/rss";
  public static $disks=array("sda"=>1,"sdb"=>1,"sdc"=>1,"sdd"=>1,"sde"=>1,"sde"=>1,"sdf"=>1,"sdg"=>1,"sdh"=>1,"sdi"=>1);
  public static $raid_level=FALSE;
  public static $new_spare_list=FALSE;
  private static $ProgressBar=FALSE;
  protected static $r_d;
  protected static $s_d;
  protected static $r_devs;
  protected static $s_devs;
  protected static $devices;
  protected static $command;
  protected static $logmsg_success;
  protected static $logmsg_fail;
  protected static $logmsg_start;
  protected static $unused;
  protected static $rc="/etc/cfg/rc";
  protected static $cfg_mdadm_monitor="/etc/cfg/cfg_mdadm_monitor";
  protected static $cfg_run_raid_start="/etc/cfg/cfg_run_raid_start";
  protected static $satamtr="/img/bin/satamtr >/dev/null 2>&1 &";
  protected static $delay=60;
  protected static $error_pattern="'\(fail\|invalid\|error\|fatal\|segment.*fault\)'";
  protected static $error_code;
  protected static $success_or_fail;
  protected static $erase_cmd="/sbin/mdadm --zero-superblock %s";
  protected static $monitor_cmd="/img/bin/trigger_monitor >/dev/null 2>&1 &";
  const savelog=SAVE_LOG;
  protected static $log_r_devices;
  protected static $log_s_devices;
  protected static $log_devices;
  protected static $debug="1";
  public static $partition_type;
  //================================================
  //  constructor
  //================================================
  function __construct($md) {
    if (NAS_DB_KEY == '2'){
      self::$erase_cmd="/sbin/mdadm --zero-superblock %s";
      self::$devmd="/dev/md0";
      self::$mdname="md0";
      self::$mdnum="0";
      self::$swapmd="/dev/md10";
      self::$swapmd_name="md10";
    }
    
    if ($md == ""){
      if (NAS_DB_KEY == '2') $md = "md0";
      if (NAS_DB_KEY == '1') $md = "md1";
    }
    self::$devmd="/dev/".$md;
    self::$erase_cmd=self::mdadm." --zero-superblock %s";
    return;
  }
  
  //================================================
  //  Use to set devmd
  //================================================
  function mdSwitch($val) {
    self::$devmd="/dev/md".$val;
    self::$mdname="md".$val;
    self::$mdnum=$val;
    if (NAS_DB_KEY == '1'){
      self::$raid_status="/var/tmp/raid".($val-1)."/rss";
    }else{
      self::$raid_status="/var/tmp/raid".$val."/rss";
    }
    $swapsize=self::get_smallest_swapsize();
    
    return;
  }

  public function set_partition_type($disk){
    //shell_exec("/img/bin/resetSmbConf.sh");
    system(self::chkgpt_cmd." /dev/".$disk,$ret);
    if($ret == 2){ //GPT
      $this->partition_type=self::gpt;
    }else{
      $this->partition_type=self::mbr;
    }
  }

  public function get_raid_disk($md){
    $x=new RAIDINFO();
    $x->setmdselect(0);
    $t=$x->getINFO($md);
    $disk_dev=$t['RaidDisk'];
    $disk_dev_name=substr($disk_dev[0],0,-1);
    unset($x);
    unset($t);
    return $disk_dev_name;
  }
  
  public function set_raid_partition_type($md){
    $dev=self::get_raid_disk($md);
    self::set_partition_type($dev);
  }
  //================================================
  //  Use to CREATE raid, just to pass $_POST.
  //  But, remember to call $this->commit or
  //  it just buffer command into self::$command.
  //================================================
  public function remount_mod() {
    //$cmd="rmmod raid10 raid6 raid5 raid1 raid0 linear md_mod;";
    //$cmd=$cmd . "sleep 1;";
    $cmd=$cmd . "modprobe raid10;modprobe raid6;modprobe raid5;modprobe raid1;modprobe raid0;modprobe linear;";
    shell_exec($cmd);
  }
  //#######################################################
  //#  Get hidden log raid level
  //#######################################################
  public function get_savelog_raid_level($level){
    if($level=="linear" || $level=="J"){
      $raid_level="jbod";
    }else{
      $raid_level="raid".$level;
    }
    return $raid_level;
  }
  //#######################################################
  //#  Get hidden log disk tray
  //#######################################################
  public function get_savelog_disk_tray($devices){
    $disk_tray_array=explode(",",$devices);
    $all_disk_tray_array=array();
    foreach($disk_tray_array as $disk){
      $strExec="cat /proc/scsi/scsi | awk -F' ' '/Disk:".$disk."/{print \$2}' | awk -F':' '{print \$2}'";
      $all_disk_tray_array[]="Tray".trim(shell_exec($strExec));
    }
    $all_disk_tray=implode(",",$all_disk_tray_array);
    return $all_disk_tray;
  }
  //#######################################################
  //#  Get hidden log disk tray
  //#######################################################
  public function get_tray_from_file(){
    $all_disk_tray_array=file("/var/tmp/raid".(self::$mdnum-1)."/disk_tray");
    $tmp_disk_tray_array=array();
    foreach($all_disk_tray_array as $disk_tray){
      $disk_tray=trim($disk_tray);
      $tray_num=substr($disk_tray,1,strlen($disk_tray)-2);
      $tmp_disk_tray_array[]="Tray".$tray_num;
    }
    $all_disk_tray=implode(",",$tmp_disk_tray_array);
    return $all_disk_tray;
  }
  //#######################################################
  
  public function create($post) {
    //echo "11111111111111";
    self::remount_mod();
    list($level,$raid,$spare,$chunk)=self::arrange($post);
    self::diskarr($raid,$spare,$level);
    $sd_disk=array();
    $dev=explode(" ",self::$devices);
    $isHV=false;
    foreach($dev as $sd){
      if($sd!=""){
        $sd_disk[]=trim(substr($sd,5,strlen($sd)-6));
        if(shell_exec("cat /proc/scsi/scsi | grep \"".trim(substr($sd,5,strlen($sd)-6))." \" | grep iSCSI") != "") $isHV=true;
      }
    }
    foreach($raid as $r) {
      self::sata_led($r,0);
    }
    foreach($spare as $s) {
      self::sata_led($s,0);
    }
    $savelog_raid_level=self::get_savelog_raid_level($level);
    $savelog_disk_tray=self::get_savelog_disk_tray(self::$log_devices);
    $this->partition_type=self::gpt;
    self::partition($raid,$spare);
    self::blind_erase_superblock($sd_disk);
    self::add_system($sd_disk);
    $chunk=($chunk=="")?self::chunk_size:$chunk;
    self::$logmsg_success=LOG_MSG_RAID_CREATE_SUCCESS;
    self::$logmsg_fail=LOG_MSG_RAID_CREATE_ERROR;
    self::$logmsg_start=LOG_MSG_RAID_CREATE_START;
    if($post["_assume_clean"]=="1")
      $cmd=self::savelog." conf_quick_raid ".$savelog_raid_level." ".$_SERVER['REMOTE_ADDR']." >/dev/null 2>&1;";
    $cmd.=self::savelog." conf_raid_create ".$savelog_raid_level.",".self::$log_devices." ".$_SERVER['REMOTE_ADDR']." >/dev/null 2>&1;";
    if($level!="50" && $level!="60"){
      if (NAS_DB_KEY == '1'){
        if($post["_assume_clean"]!="1")
          $cmd.=self::mdadm." --create ".self::$devmd." --force  -e ".self::medata_version." --chunk=".$chunk." --level=".$level. (($level=="5")?" --layout=ls":"") . " --metadata=1.2 --raid-devices=".self::$r_d." ".self::$r_devs;
        else
          $cmd.=self::mdadm." --create ".self::$devmd." --assume-clean --force  -e ".self::medata_version." --chunk=".$chunk." --level=".$level. (($level=="5")?" --layout=ls":"") . " --metadata=1.2 --raid-devices=".self::$r_d." ".self::$r_devs;
      }else{
        if($post["_assume_clean"]!="1")
          $cmd.=self::mdadm." --create ".self::$devmd." --chunk=".$chunk." --force --level=".$level. (($level=="5")?" --layout=ls":"") . " --metadata=1.2 --raid-devices=".self::$r_d." ".self::$r_devs;
        else
          $cmd.=self::mdadm." --create ".self::$devmd." --chunk=".$chunk." --assume-clean --force --level=".$level. (($level=="5")?" --layout=ls":"") . " --metadata=1.2 --raid-devices=".self::$r_d." ".self::$r_devs;
      }
    //$cmd.=self::mdadm." --create ".self::$devmd." --force --chunk=".$chunk." --level=".$level." --raid-devices=".self::$r_d." ".self::$devices;
      $cmd.=((int)self::$s_d>0 && ($level != "J" && (int)$level != 0))?" --spare-devices=".self::$s_d." ".self::$s_devs:"";
      $cmd.=" --run > /tmp/create_raid.log 2>&1 | grep -v -i ".self::$error_pattern." | grep -i 'mdadm: *array *.*start' ;";
    }elseif($level=="50"){
      $r_d_5a = intval(self::$r_d/2);
      $r_d_5b = self::$r_d - $r_d_5a;
      $r_count = 0;
      $r_devs_5a="";
      $r_devs_5b="";
      $dev=explode(" ",self::$r_devs);
      foreach($dev as $a) {
        if( $r_count < $r_d_5a){
          $r_devs_5a .= " ".$a;
        }
        else{
          $r_devs_5b .= " ".$a;
        }
        $r_count += 1;
      }
      
      $s_d_5a = intval(self::$s_d/2);
      $s_d_5b = self::$s_d - $s_d_5a;
      $s_count = 0;
      $s_devs_5a="";
      $s_devs_5b="";
      $dev=explode(" ",self::$s_devs);
      foreach($dev as $a) {
        if( $s_count < $s_d_5a){
          $s_devs_5a .= " ".$a;
        }
        else{
          $s_devs_5b .= " ".$a;
        }
        $s_count += 1;
      }
      $mdnum_5a=intval(self::$mdnum)*2+30;
      $mdnum_5b=intval(self::$mdnum)*2+31;


      if($post["_assume_clean"]!="1")
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5a." --force --chunk=".$chunk." --level=5 --layout=ls --raid-devices=".$r_d_5a." ".$r_devs_5a;
      else
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5a." --assume-clean --force --chunk=".$chunk." --level=5 --layout=ls --raid-devices=".$r_d_5a." ".$r_devs_5a;

      $cmd.=((int)self::$s_d>0 && ($level != "J" && (int)$level != 0))?" --spare-devices=".$s_d_5a." ".$s_devs_5a:"";
      $cmd.=" --run;";

      if($post["_assume_clean"]!="1")
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5b." --force --chunk=".$chunk." --level=5 --layout=ls --raid-devices=".$r_d_5b." ".$r_devs_5b;
      else
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5b." --assume-clean --force --chunk=".$chunk." --level=5 --layout=ls --raid-devices=".$r_d_5b." ".$r_devs_5b;

      $cmd.=((int)self::$s_d>0 && ($level != "J" && (int)$level != 0))?" --spare-devices=".$s_d_5b." ".$s_devs_5b:"";
      $cmd.=" --run;";
      
      $cmd.=self::mdadm." --create ".self::$devmd." --force --chunk=".$chunk." --level=0 --raid-devices=2 /dev/md".$mdnum_5a." /dev/md".$mdnum_5b;
      $cmd.=" --run > /tmp/create_raid.log 2>&1 | grep -v -i ".self::$error_pattern." | grep -i 'mdadm: *array *.*start' ;";
    }elseif($level=="60"){
      $r_d_5a = intval(self::$r_d/2);
      $r_d_5b = self::$r_d - $r_d_5a;
      $r_count = 0;
      $r_devs_5a="";
      $r_devs_5b="";
      $dev=explode(" ",self::$r_devs);
      foreach($dev as $a) {
        if( $r_count < $r_d_5a){
          $r_devs_5a .= " ".$a;
        }
        else{
          $r_devs_5b .= " ".$a;
        }
        $r_count += 1;
      }

      $s_d_5a = intval(self::$s_d/2);
      $s_d_5b = self::$s_d - $s_d_5a;
      $s_count = 0;
      $s_devs_5a="";
      $s_devs_5b="";
      $dev=explode(" ",self::$s_devs);
      foreach($dev as $a) {
        if( $s_count < $s_d_5a){
          $s_devs_5a .= " ".$a;
        }
        else{
          $s_devs_5b .= " ".$a;
        }
        $s_count += 1;
      }
      $mdnum_5a=intval(self::$mdnum)*2+30;
      $mdnum_5b=intval(self::$mdnum)*2+31;


      if($post["_assume_clean"]!="1")
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5a." --force --chunk=".$chunk." --level=6 --layout=ls --raid-devices=".$r_d_5a." ".$r_devs_5a;
      else
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5a." --assume-clean --force --chunk=".$chunk." --level=6 --layout=ls --raid-devices=".$r_d_5a." ".$r_devs_5a;

      $cmd.=((int)self::$s_d>0 && ($level != "J" && (int)$level != 0))?" --spare-devices=".$s_d_5a." ".$s_devs_5a:"";
      $cmd.=" --run;";

      if($post["_assume_clean"]!="1")
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5b." --force --chunk=".$chunk." --level=6 --layout=ls --raid-devices=".$r_d_5b." ".$r_devs_5b;
      else
        $cmd.=self::mdadm." --create /dev/md".$mdnum_5b." --assume-clean --force --chunk=".$chunk." --level=6 --layout=ls --raid-devices=".$r_d_5b." ".$r_devs_5b;

      $cmd.=((int)self::$s_d>0 && ($level != "J" && (int)$level != 0))?" --spare-devices=".$s_d_5b." ".$s_devs_5b:"";
      $cmd.=" --run;";

      $cmd.=self::mdadm." --create ".self::$devmd." --force --chunk=".$chunk." --level=0 --raid-devices=2 /dev/md".$mdnum_5a." /dev/md".$mdnum_5b;
      $cmd.=" --run > /tmp/create_raid.log 2>&1 | grep -v -i ".self::$error_pattern." | grep -i 'mdadm: *array *.*start' ;";
    }

    $rootfs_disk=str_replace("2","4",self::$devices);
    $cmd="sh -x /img/bin/expand_rootfs.sh \"" . $rootfs_disk . "\" > /tmp/expand_rootfs.log 2>&1;" . $cmd;
    
    if(!$isHV){
      $swap_disk=str_replace("2","1",self::$devices);
      $swap_count=self::$r_d + self::$s_d;
      //Make swap
      //$cmd="/img/bin/mkswap_md.sh " . $swap_count . " \"" . $swap_disk . "\";" . $cmd;
      $cmd="sh -x /img/bin/mkswap_md.sh " . $swap_count . " \"" . $swap_disk . "\" > /tmp/create_mkswap.log 2>&1;" . $cmd;
    }
    if (NAS_DB_KEY == '2'){
      $sys_disk=str_replace("2","3",self::$devices);
      $sys_count=self::$r_d + self::$s_d; 
      $cmd="sh -x /img/bin/mksinglesys_md.sh " . $sys_count . " \"" . $sys_disk . "\" " . self::$mdnum . " > /tmp/create_mksys.log 2>&1;" . $cmd;
    }
    //$swapcmd="/img/bin/mkswap_md.sh " . $swap_count . " \"" . $swap_disk . "\" >/tmp/mkswap_md1.tmp 2>&1 &";
    //$strout=exec($cmd);
    //echo "cmd=$cmd <br>";
    self::$command=$cmd;
    self::$error_code=RAID_CREATE_ERROR;
    self::$success_or_fail=SUCCESS_WILL_PRINT_ON_CONSOLE;
    
    return self::$command;
    //$strout=shell_exec($swapcmd);
  }


  //================================================
  //  Use to add spare devices to an existing raid
  //  But, remember to call $this->commit or
  //  it just buffer command into self::$command.
  //  [_spare] => Array
  //  (
  //    [0] => 3
  //  )
  //================================================
  public function add_spare($post) {
      if (NAS_DB_KEY == '2'){
      $devmd="/dev/md0";
      $mdname="md0";
      $mdnum="0";
      $swapmd="/dev/md10";
      $swapmd_name="md10";
    }
    $grow="";
    self::$success_or_fail=SUCCESS_WILL_PRINT_ON_CONSOLE;
    //$cmd_tail=" | grep -v -i ".self::$error_pattern." | grep -i 'mdadm: *hot added'";
    //$cmd_tail=" | grep -v -i ".self::$error_pattern." | grep -i 'mdadm:'";
    $cmd_tail=" | grep -v -i ".self::$error_pattern." | grep -i '\(mdadm: *hot added\|not large enough to join array\)'";
    $xType=self::get_raid_level();
    if($xType=="J") {
      $grow="--grow ";
      $inneed="_inraid";
      self::$success_or_fail=FAIL_WILL_PRINT_ON_CONSOLE;
      $cmd_tail="";
    }
    $map=self::slot_map_dev();
    $spare=isset($post["spare"]) ? $post["spare"]:$post["inraid"];
    foreach($spare as $s) {
      self::sata_led($s,0);
    }
    $isHV=false;
    $new_spare="";
    $new_swap="";
    $new_sys="";
    $new_rootfs="";
    self::$log_s_devices="";
    foreach($spare as $k=>$s) {
      if($s!="") {
        $spare[$k]="/dev/sd".$map[$s];
        $new_spare_dev[]="sd".$map[$s];
        $new_spare.=" "."/dev/sd".$map[$s]."2";
        $new_swap.=" "."/dev/sd".$map[$s]."1";
        $new_sys.=" "."/dev/sd".$map[$s]."3";
        $new_rootfs.=" "."/dev/sd".$map[$s]."4";
        if(shell_exec("cat /proc/scsi/scsi | grep \""."sd".$map[$s]." \" | grep iSCSI") != "") $isHV=true;
      }
    }
    if($new_spare != "") {
      self::$new_spare_list=$new_spare;
      self::$log_s_devices=str_replace("2","",trim($new_spare));
      self::$log_s_devices=str_replace(" ","_spare",self::$log_s_devices);
      self::$log_s_devices=str_replace("/dev/","",self::$log_s_devices);
    }
    self::set_raid_partition_type(self::$mdnum);
    foreach($spare as $s) {
      self::erase_single_superblock($s.'2');
      self::execute(self::partition_cmd(substr($s,5)));
    }
    self::$logmsg_success=LOG_MSG_RAID_ADD_SPARE_SUCCESS;
    self::$logmsg_fail=LOG_MSG_RAID_ADD_SPARE_ERROR;
    self::$logmsg_start=LOG_MSG_RAID_ADD_SPARE_START;
    self::set_rebuild_speed();
    $spare_dev=implode(",",$new_spare_dev);
    $savelog_raid_level=self::get_savelog_raid_level($xType);
    $savelog_disk_tray=self::get_savelog_disk_tray($spare_dev);
    $cmd=self::savelog." conf_raid_add_spare ".$savelog_raid_level.",".$savelog_disk_tray." ".$_SERVER['REMOTE_ADDR']." >/dev/null 2>&1;";
    if(($xType=="50")||($xType=="60")){
      //$cmd.=";/img/bin/jbod_resize.sh > /dev/null 2>&1 &";
      $mdnum_5a=intval(self::$mdnum)*2+30;
      $mdnum_5b=intval(self::$mdnum)*2+31;
      $disknum_5a=0;
      $disknum_5b=0;
      $spare_5a="";
      $spare_5b="";

      $cmd2="mdadm -D /dev/md$mdnum_5a";
      $content = shell_exec($cmd2);
      $content = explode("\n",$content);
      foreach($content as $v){
        if(preg_match("/active sync/", $v)){
          $disknum_5a++;
        }elseif(preg_match("/spare/", $v)){
          $disknum_5a++;
        }
      }

      $cmd2="mdadm -D /dev/md$mdnum_5b";
      $content = shell_exec($cmd2);
      $content = explode("\n",$content);
      foreach($content as $v){
        if(preg_match("/active sync/", $v)){
          $disknum_5b++;
        }elseif(preg_match("/spare/", $v)){
          $disknum_5b++;
        }
      }

      $arySpare=explode(" ",$new_spare);
      foreach($arySpare as $s) {
        if($disknum_5a <= $disknum_5b){
          $spare_5a.=" ".$s;
          $disknum_5a++;
        }else{
          $spare_5b.=" ".$s;
          $disknum_5b++;
        }
      }
      
      if($spare_5a != "")
        $cmd.=self::mdadm." ".$grow." /dev/md".$mdnum_5a." --add ".$spare_5a." 2>&1".$cmd_tail . ";";

      if($spare_5b != "")
        $cmd.=self::mdadm." ".$grow." /dev/md".$mdnum_5b." --add ".$spare_5b." 2>&1".$cmd_tail . ";";

    }else
      $cmd.=self::mdadm." ".$grow.self::$devmd." --add ".$new_spare." 2>&1".$cmd_tail . ";";

    $cmd.="sh -x /img/bin/expand_rootfs.sh \"".$new_rootfs."\" >/tmp/expand_rootfs.log 2>&1;";
    if($xType=="J"){
      //$cmd.=";/img/bin/jbod_resize.sh > /dev/null 2>&1 &";
      $cmd.="echo 'Please wait ... resizing ...' > /tmp/raid".self::$mdnum."/rss;";
      $cmd.="/img/bin/jbod_resize.sh ".self::$mdnum." > /tmp/jbod_resize.tmp 2>&1 &";
    }
    
    if(!$isHV)
      $cmd.=self::mdadm . " " . self::$swapmd . " --add " . $new_swap . ";";
    if (NAS_DB_KEY == '2'){
      $sysmd="/dev/md".sprintf("%d",self::$mdnum+50);
      $cmd.=self::mdadm . " " . $sysmd . " --add " . $new_sys . ";";
    }
    
    self::$command=$cmd;
    self::$error_code=RAID_ADD_SPARE_ERROR;
    return;
  }

  //================================================
  //  Call to execute self::$command
  //================================================
  public function commit($exec=FALSE) {
    //self::debug=true;
    if(self::$error_code==RAID_CREATE_ERROR) {
      self::execute(self::kill_monitor());
      self::execute(self::stop_raid());
    }
    $cmd=self::$command;
    if(self::debug){print $cmd;flush();}
    sleep(1);
    //echo "cmd=${cmd} <br>";
    
    $res=self::execute($cmd,self::$success_or_fail,self::$logmsg_start);
    //$res=1;
    //echo "raid res = ${res}<br>";
    if(preg_match("/not large enough to join array/",$res)){
      self::$error_code=RAID_ADD_SPARE_SIZE_ERROR;
      self::$logmsg_fail=LOG_MSG_RAID_ADD_SPARE_SIZE_ERROR;
    }
    //echo "raid error code = ".self::$error_code."<br>";
    //echo "raid log msg = ".self::$logmsg_fail."<br>";
    if($res=="0") {
      return 0;
    } else {
      return self::errorer(self::$error_code,self::$logmsg_fail);
    }
    return 0;
  }

  //================================================
  //  Call to retrieve unused disks array
  //  array like
  //  [sda1] => 1
  //  [sdb1] => 1
  //================================================
  public static function ret_unused_disks() {
    $line=shell_exec("/bin/cat ".self::mdstat." | ".self::awk." 'NR==2 {print}'");
    $fields=explode(" ",$line);
    $unused=self::$disks;
    foreach($unused as $k=>$u) {
      unset($unused[$k]);
      $unused[$k."2"]=$u;
    }
    foreach($fields as $f) {
      if(preg_match('/(sd[a-d]{1}2?)\[[0-9]{1}\]/',$f,$match)) {
        unset($unused[$match[1]]);
      }
    }
    return $unused;
  }

  //================================================
  //   To determine mdadm execution fail or success
  //================================================
  public static function boolean($stderr) {
    if($stderr=="") {
      return FALSE;
    } else {
      return TRUE;
    }
  }

  //================================================
  //  Use to compose the RAID & SPARE devices string
  //================================================
  protected static function diskarr($raid,$spare,$level) {
    $map=self::slot_map_dev();
    $r_devs="";$s_devs="";
    $r_d=0;$s_d=0;
    foreach($raid as $r) {
      if($r!="") {
        $r="/dev/sd".$map[$r]."2";
        $r_devs.=$r." ";
        $r_d++;
      }
    }
    self::$log_r_devices=str_replace("2","",trim($r_devs));   // remove 2
    self::$log_r_devices=str_replace(" ",",",self::$log_r_devices); 
    self::$log_r_devices=str_replace("/dev/","",self::$log_r_devices); 
    if($level != "J" && (int)$level != 0) {
      foreach($spare as $s) {
        if($s!="") {
          $s="/dev/sd".$map[$s]."2";
          $s_devs.=$s." ";
          $s_d++;
        }
      }
    }
    self::$log_s_devices=str_replace("2","",trim($s_devs));
    self::$log_s_devices=str_replace(" ","_spare",self::$log_s_devices);
    self::$log_s_devices=str_replace("/dev/","",self::$log_s_devices);
    unset($map);
    self::$r_d=$r_d;
    self::$s_d=$s_d;
    self::$devices=trim($r_devs)." ".trim($s_devs);
    self::$s_devs=trim($s_devs);
    self::$r_devs=trim($r_devs);
    if(self::$log_s_devices == "")
      self::$log_devices=self::$log_r_devices;
    else
      self::$log_devices=self::$log_r_devices.",".self::$log_s_devices;

  }

  //================================================
  //  Use to write rc auto command
  //================================================
  public function enable_auto_detect() {
    $cmd="echo 1 > ".self::$cfg_run_raid_start;
    return self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE,LOG_MSG_RAID_ASSEMBLER_ENABLE);
  }

  //================================================
  //  Use to write rc auto command
  //================================================
  public function disable_auto_detect($md) {
    $cmd="echo 0 > ".self::$cfg_run_raid_start;
    return self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE,LOG_MSG_RAID_ASSEMBLER_DISABLE);
  }

  //================================================
  //  Use to get raid level
  //================================================
  public function get_raid_level() {
    require_once('info/raidinfo.class.php');
    $x=new RAIDINFO();
    $x->setmdselect(0);
    $t=$x->getINFO(self::$mdnum);
    $xType=trim($t['RaidLevel']);
    unset($x);
    unset($t);
    self::$raid_level=$xType;
    return $xType;
  }

  //================================================
  //  Use to get raid level
  //================================================
  public function jbod_add_list() {
    return self::$new_spare_list;
  }

  //================================================
  //  Use to modify rc auto command
  //  $device_array must be "sdd1" style
  //================================================
  public function expand_auto_detect($md,$device_array) {
    $larr=file(self::$rc);
    $pattern="@^".self::mdadm." \-A.*".$md."\s+@";
    foreach($larr as $k=>$v) {
      if(preg_match($pattern,$v)) {
        $v=trim($v);
        foreach($device_array as $d) {
          $v.=" ".$d;
        }
        $larr[$k]=trim($v)."\n";
      }
    }
    self::WriteBack(self::$rc,$larr);
  }

  //================================================
  //  Use to modify rc auto command
  //================================================
  public function shrink_auto_detect($md,$device_array) {
    $larr=file(self::$rc);
    $pattern="@^".self::mdadm." \-A.*".$md."\s+@";
    foreach($larr as $k=>$v) {
      if(preg_match($pattern,$v)) {
        $v=trim($v);
        foreach($device_array as $d) {
          $v=str_replace($d,"",$v); 
        }
        $v=ereg_replace(" +"," ",$v);
        $larr[$k]=trim($v)."\n";
      }
    }
    self::WriteBack(self::$rc,$larr);
  }

  //================================================
  //  Use to get raid level
  //================================================
  public function get_smallest_swapsize() {
    $small_swapsize=2048000;
    if ($_POST["md_num"] != "") {
      $strExec="cat /proc/mdstat | awk '/md" . $_POST["md_num"] . "/'";    //get sdname
      self::$swapmd_name=explode(" ",shell_exec($strExec));
      foreach (self::$swapmd_name as $v) {
        if(substr($v,0,2) == "sd") {
          $strExec="cat /proc/partitions | awk '/" . substr($v,0,3) . "1/{print $3}'";
          $swapsize=trim(shell_exec($strExec));    //get swapsize
          if ($swapsize < $small_swapsize) {
            $small_swapsize=$swapsize;
          }
        }
      }
    } else {
      $strExec="cat /proc/partitions |awk '/md0/{print $3}'";
      $small_swapsize=trim(shell_exec($strExec));
    }
    $small_swapsize=$small_swapsize/1024;
    return $small_swapsize;
  }
  
  //================================================
  //  Use to compose init_disk command
  //================================================
  public function partition_cmd($disk) {
    
    $cmd="/img/bin/init_disk.sh ".$disk." >/tmp/init_".$disk."_log 2>&1";
    return $cmd;
  }

  //================================================
  //  Drive  partition
  //================================================
  public function partition($raid,$spare) {
    $sata = shell_exec("cat /proc/scsi/scsi"); 
    
    //echo "sata=$sata <br>";
    if (NAS_DB_KEY == '1'){
      preg_match_all("/Tray:(\d{1,2})\s*Disk:sd(\w)\s*Model:(.+)Rev:(.+)Removable:([^\n]+)/",$sata,$hdd_info);
    }else{
      preg_match_all("/Tray:(\d{1,3})\s*Disk:sd(\w+)\s*Model:(.+)Rev:(.+)Intf:(.+)LinkRate:(.+)Loc:(.+)Pos:([^\n]+)/",$sata,$hdd_info);
    }
    //echo "count(hdd_info[1])=" . count($hdd_info[1]) . "<br>";
    $max_index=0;
    $aryhdd=array();
    for($i=0;$i<count($hdd_info[1]);$i++){
      $aryhdd[$hdd_info[1][$i]]=$hdd_info[2][$i];
    }

    //$map=array_keys(self::$disks);
    foreach($raid as $r) {
      //echo "$r = " . $aryhdd[$r] . "<br>";
      self::execute(self::partition_cmd("sd" . $aryhdd[$r]));
    }
    foreach($spare as $s) {
      //echo "$s = " . $aryhdd[$s] . "<br>";
      self::execute(self::partition_cmd("sd" . $aryhdd[$s]));
    }
  }

  //================================================
  //  Pick out and arrange the $_POST
  //================================================
  private static function arrange($post) {
    $result=array();
    foreach($post as $k => $v) {
      if($k=="type") $result[0]=$v;
      if($k=="inraid") $result[1]=$v;
      if($k=="spare") $result[2]=$v;
      if($k=="chunk") $result[3]=$v;
    }
    return $result;
  }

  //================================================
  //  Call to fulfill buffer of Mac's Safary browser
  //================================================
  public static function fulfillbuf($num=1000) {
    $span="";$spanc=0;
    while($spanc<(int)$num) {
      $span.="<span></span>";
      $spanc++;  
    }
    echo $span."\n";
    flush();
  }

  //================================================
  //  Use to list mdadm monitor process
  //  Will return an array
  //================================================
  public function mdadm_process() {
    $pattern="\"mdadm.*monitor.*".self::$devmd."\"";
    $cmd="/bin/ps axw 2>&1 | grep ".$pattern." | grep -v grep | ".self::awk." '{print \$1}'";
    $buf=shell_exec($cmd);
    return explode("\n",trim($buf));
  }

  //================================================
  //  Call to stop raid
  //================================================
  public function kill_monitor() {
    $pattern="\"mdadm.*monitor.*".self::$devmd."\"";
    $cmd="/bin/kill `/bin/ps axw | grep ".$pattern." | grep -v grep | ".self::awk." '{print \$1}'` 2>&1";
    return $cmd;
  }

  //================================================
  //  Return mdadm monitor command
  //================================================
  public function trigger_monitor() {
    $cmd=self::$monitor_cmd;
    return $cmd;
  }

  //================================================
  //  Append monitor command to rc
  //================================================
  public function append_rc_monitor() {
    $cmd=self::trigger_monitor();
    return self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE,LOG_MSG_RAID_MONITOR_ENABLE);
  }

  //================================================
  //  Run satamtr
  //================================================
  public function append_satamtr() {
    $cmd=self::$satamtr;
    return self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE,LOG_MSG_RAID_MONITOR_ENABLE);
  }

  //================================================
  //  To list all raid member
  //  raw return is:  
  //  sda1
  //  sdb1
  //  sdc1
  //  sdd1
  //
  //================================================
  public function list_all_raid_member() {
     $cmd="cat ".self::mdstat." | ".self::awk." 'NR==2{for(i=NF;i>=1;i--){if(\$i~/\[.*\]/)print \$i;}}'";
     $tmp=explode("\n",trim(shell_exec($cmd)));
     $buf=array();
     foreach($tmp as $t) {
       $tmp=preg_replace("@\[.*\]@","",trim($t));
       if($tmp!="") $buf[]=$tmp;
     }
     return $buf;
  }

  //================================================
  //  To erase raid member device superblock
  //================================================
  public function erase_superblock() {
    $devices=self::list_all_raid_member();
    if(self::debug){print count($devices);flush();print "\n<hr>\n";}
    foreach($devices as $d) {
      $cmd=sprintf(self::$erase_cmd,"/dev/".$d);
      if(self::debug){print $cmd;flush();print "\n<hr>\n";}
      self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
    }
  }

  //================================================
  //  To BLIND erase raid member device superblock
  //================================================
  public function blind_erase_superblock($diskmap) {
    foreach($diskmap as $a) {
      if (NAS_DB_KEY == '2'){
        $cmd=self::mdadm." --zero-superblock /dev/".$a."3";
        self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
      }
      $cmd=self::mdadm." --zero-superblock /dev/".$a."2";
      self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
      $cmd=self::mdadm." --zero-superblock /dev/".$a."1";
      self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
      if(self::debug){print $cmd;flush();print "\n<hr>\n";}
    }
  }

  public function add_system($diskmap) {
    $cmd="";
    $devices=self::list_all_raid_member();
    foreach($diskmap as $d) {
      $cmd.=" /dev/".$d."4";
    }
    $cmd="/sbin/mdadm --add /dev/md70 ".$cmd;
    self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }
  //================================================
  //  To BLIND erase raid member device superblock
  //================================================
  public function erase_single_superblock($d) {
      $cmd=self::mdadm." --zero-superblock ".$d;
      self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  To grep fail devices
  //================================================
  public function grep_fail_device() {
    $devices=self::list_all_raid_member();
    $pattern="@\(F\)$@";
    $buf=array();
    foreach($devices as $d) {
      if(preg_match($pattern,trim($d))) $buf[]=str_replace("(F)","",$d);
    }
    return $buf;
  }

  //================================================
  //  To hot remove failed devices
  //================================================
  public function hot_remove_failed() {
    $fail_arr=self::grep_fail_device();
    $tmplate=self::mdadm." ".self::$devmd." --remove %s 2>&1 | grep -i ".self::$error_pattern."";
    foreach($fail_arr as $f) {
      $cmd=sprintf($tmplate,"/dev/".$f);
      self::execute($cmd,0);
    }
    return $fail_arr;
  }

  //================================================
  //  To fot remove failed devices
  //================================================
  public function hot_remove_failed_and_reduce_assembler() {
    $fail_arr=self::grep_fail_device();
    $tmplate=self::mdadm." ".self::$devmd." --remove %s 2>&1 | grep -i ".self::$error_pattern."";
    foreach($fail_arr as $f) {
      $cmd=sprintf($tmplate,"/dev/".$f);
      self::execute($cmd,0);
    }
    self::shrink_auto_detect(self::$devmd,$fail_arr);
    return $fail_arr;
  }

  //================================================
  //  Append monitor command to rc
  //================================================
  public function delete_rc_monitor() {
    $larr=file(self::$rc);
    $pattern="@^".self::mdadm.".*monitor.*".self::$devmd."@";
    foreach($larr as $k=>$v) {
      if(preg_match($pattern,$v)) {
        unset($larr[$k]);
      }
    }
    self::WriteBack(self::$rc,$larr);
  }

  //================================================
  //  Call to stop raid
  //================================================
  public function stop_raid() {
    $level=self::get_raid_level();
    $savelog_raid_level=self::get_savelog_raid_level($level);
    $savelog_disk_tray=self::get_tray_from_file();
    $cmd=self::savelog." raid_destroy \"".$savelog_raid_level.",".$savelog_disk_tray."\" ".$_SERVER['REMOTE_ADDR']." >/dev/null 2>&1;";
    $cmd.=self::mdadm." --stop ".self::$devmd . ";";
    $cmd.=self::mdadm." --stop ".sprintf("/dev/md%d",30+self::$mdnum*2) . ";";
    $cmd.=self::mdadm." --stop ".sprintf("/dev/md%d",31+self::$mdnum*2) . ";";
    
    //stop swap
    //$cmd.="/sbin/swapoff " . self::$swapmd . ";" . self::mdadm . " --stop " . self::$swapmd;

    return $cmd;
  }

  //================================================
  //  To grep information from intel drivers
  //
  //  if slot is not conneted
  //  # cat /proc/scsi/gd31244/0 | awk 'BEGIN{OFS=","}/^Port/{counter=NR;disk=$2}(NR==counter+4){if($1~/^Serial/)print disk,$3}'
  //  0,"5JVF5GVJ"
  //  1,"5JVF6DKV"
  //  2,"5JVF5GWZ"
  //  #
  //  #cat /proc/scsi/gd31244/0 | awk 'BEGIN{OFS=","}/^Port/{counter=NR;disk=$2}(NR==counter+4){if($1~/^Serial/){gsub(/"/,"",$3);print disk,$3}}'
  //  #0,5JVF5GVJ
  //  #1,5JVF6DKV
  //  #2,5JVF5GWZ
  //
  //  #cat /proc/scsi/gd31244/0 | awk 'BEGIN{OFS=","}/^Port/{counter=NR;disk=$2}(NR==counter+4){if($1~/^Serial/)match($3,/\".*\"/);print disk,substr($3,2,RSTART+RLENGTH-3)}'
  //
  //
  //================================================
  public function record_sata_serial() {
    $cmd="cat /proc/scsi/gd31244/0 | awk 'BEGIN{OFS=\",\"}/^Port/{counter=NR;disk=$2}(NR==counter+4){if($1~/^Serial/){gsub(/\"/,\"\",$3);print disk,$3}}'";
    $lines=explode("\n",trim(shell_exec($cmd)));
    $arr=array();
    foreach($lines as $l) {
      list($key,$value)=explode(",",$l);
      $arr[$key]=$value;
    }
    return $arr;
  }

  //================================================
  //  Mapping slot and devices
  //  this function will return an array
  //  Array
  //  (
  //    [1] => a
  //    [3] => c
  //    [4] => d
  //  )
  //  key is slot number, value is device file(a,b,c)
  //  Do remember, array starts at 1 !!
  //================================================
  public function slot_map_dev() {
    $sata = shell_exec("cat /proc/scsi/scsi");
    preg_match_all("/Tray:(\d+) Disk:sd(\w+) Model:(.+) Rev:([^\n]+)/",$sata,$disklist);
    for($i=0;$i<count($disklist[0]);$i++){
      $dev[$disklist[1][$i]]=$disklist[2][$i];
    }
    return $dev;
  }

  //================================================
  //  Call to make led light
  //================================================
  public function sata_led($disk,$action=1) {
    $cmd='/img/bin/model/led_light.sh S_LED'.$disk.' '.$action.' > '.self::thecus_io;
    self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  Call to make buzzer alarm and then mute
  //================================================
  public function buzzer_alarm($seconds=60) {
    self::buzzer_on();
    sleep($seconds);
    self::buzzer_off();
  }

  //================================================
  //  Call to make buzzer alarm
  //================================================
  public function buzzer_on() {
    //$cmd='echo "Buzzer 1" > '.self::thecus_io;
    $cmd="/img/bin/buzzer.sh 1";
    self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  Call to make buzzer mute
  //================================================
  public function buzzer_off() {
    //$cmd='echo "Buzzer 0" > '.self::thecus_io;
    $cmd="/img/bin/buzzer.sh 0";
    self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  Call to make buzzer mute
  //================================================
  public function commit_fail() {
    if(self::$ProgressBar) {
      self::$ProgressBar->fail();
    }
  }

  //================================================
  //  Killall satamtr
  //================================================
  public function killall_satamtr() {
    $cmd="killall satamtr";
    return self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  Killall raid_status/status_update
  //================================================
  public function killall_raid_status_update() {
    $cmd="killall raid_status;killall status_update";
    return self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  Killall post_create
  //================================================
  public function killall_post_create() {
    $cmd="killall post_create";
    return self::execute($cmd,SUCCESS_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  set no raid
  //================================================
  public function set_noraid() {
    $cfg=self::$raid_status;
    $cmd="echo 'N/A' > ".$cfg;
    return self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }

  //================================================
  //  set rebuild speed
  //================================================
  public function set_rebuild_speed() {
    $cmd="echo '6000000' > /proc/sys/dev/raid/speed_limit_max";
    return self::execute($cmd,FAIL_WILL_PRINT_ON_CONSOLE);
  }

  //
  
  public function chk_migrate_start() {
    $Migrate_Status=shell_exec("/bin/ps");
    if(preg_match("/raidreconf/",$Migrate_Status)){
      $Migrate_Status="1";
    } else {
      if(preg_match("/migrate_raid/",$Migrate_Status)){
        $Migrate_Status="1";
      } else {
        if(preg_match("/migrate_start/",$Migrate_Status)){
          $Migrate_Status="1";
        } else {
          $Migrate_Status="0";
        }
      }
    }
    
    //Check RAID Type 
    if ($Migrate_Status=="1") {
      //Migration is progress ....
      return 1;
    } else return 0;
  }
  
  //Get Device Size from partition
  public function get_devicesize($device) {
    $tmpExec="awk '{if ($4==\"%s\") print $3}' /proc/partitions";
    $strExec=sprintf($tmpExec,$device);
    $retval=shell_exec($strExec);
    return $retval;
  }
  
  //================================================
  //  Migrate RAID
  //================================================
  public function migrate($post) {
    $x = new RAIDINFO();
    $x->setmdselect(0);
    $x = $x->getINFO(self::$mdnum);
    $xType=trim($x['RaidLevel']);//old raid type
    $xChunkSize=trim($x['ChunkSize']);
    //echo "<pre>";
    //print_r($post);
    //print_r($x);

    //Check migrating ....
    if (self::chk_migrate_start()) {
      //Migration is progress ....
      return 1;
    }
    
    //Check Migrate Data
    if (($xType=="J") ||($xType=="10")) {
      //Not support Migrate  ....
      return 2;
    }
    
    if ($xType=="1") {
      $xChunkSize=64;
    }
    
    //0_0(raid type in before_after
    $aryTran=explode("_",$post["_type"]);
    //echo "type=" . $post["_type"] . "<br>";
    //echo "xType=" . $xType . " aryTran[0]=" . $aryTran[0] . "  aryTran[1]=" . $aryTran[1] . "<br>";
    if (!$aryTran) {
      //Migrate Type Warning  ....
      return 3;
    }
    
    if ($aryTran[0]!=$xType) {
      //Migrate Old Type different  ....
      return 4;
    }
    if (($aryTran[1]!="0") && ($aryTran[1]!="5") && ($aryTran[1]!="6")) {
      //Not support Migrate Type different  ....
      return 5;
    }
    if($aryTran[1]=="6"){
      if(($aryTran[0]!="1") && ($aryTran[0]!="5") && ($aryTran[0]!="6")){
        //Not support Migrate Type different  ....
        return 5;
      }
    }
    
    $newType=$aryTran[1];//new raid type
    
    //general OLD raid conf
    unlink(self::raidconf_old);
    unlink(self::raidconf_new);
    
    //################################################################
    //#  RAID conf template
    //################################################################
    $conf_template="";
    $conf_template=$conf_template . "raiddev		%s\n";
    $conf_template=$conf_template . "raid-level		%d\n";
    $conf_template=$conf_template . "nr-raid-disks		%d\n";
    $conf_template=$conf_template . "chunk-size		%d\n";
    $conf_template=$conf_template . "persistent-superblock		1\n";
    //################################################################
    //#  Assemble old raid conf (/tmp/raid.old)
    //################################################################
    $raid_count=0;
    $conf_template_old=$conf_template;
    $conf_template_old=$conf_template_old . (($xType=="5")?"parity-algorithm		left-symmetric\n":"");
    
    $xType=trim($xType);
    
    if ($xType=="1" && $newType=="0") { //Use the smaller one to do migration
      $mindevice="";
      $i=0;
      $lastsize=0;
      foreach ($x['RaidDisk'] as $d){
        $devicename=$d;
        $devicesize=self::get_devicesize($devicename);
        if ($i==0) {
          $mindevice=$devicename;
          $lastsize=$devicesize;
        }
        if ($devicesize < $mindevice) {
          $mindevice=$devicename;
          $lastsize=$devicesize;
        }
        $i++;
      }
            $xType="0"; //Cheating raidreconf
      //printf("mindevice=%s lastsize=%s <br>",$mindevice,$lastsize);
      $conf_template_old=$conf_template_old . "device		/dev/" . $mindevice . "\n";
      $conf_template_old=$conf_template_old . "raid-disk  " . $raid_count . "\n";
      $raid_count++;
    } else {
      foreach ($x['RaidDisk'] as $d){
        $conf_template_old=$conf_template_old . "device		/dev/" . $d . "\n";
        $conf_template_old=$conf_template_old . "raid-disk  " . $raid_count . "\n";
        $raid_count++;
      }
    }
    $old_raid_count=$raid_count;
    
    $rcount=0;
    foreach ($x['RaidDisk'] as $d){
      $use_disk=$use_disk . ",'" . $d . "'";
      $rcount++;
    }
    

    $chunksize=(trim($x['ChunkSize'])!="")?trim($x['ChunkSize']):"64";
    
    //$oldconf_data=sprintf($conf_template_old,self::$devmd,(($xType=="1")?"0":$xType),$raid_count,$chunksize);
    $oldconf_data=sprintf($conf_template_old,self::$devmd,$xType,$raid_count,$chunksize);
    //echo "[" . self::raidconf_old . "] oldconf_data=" . $oldconf_data . "<br>";
    $oldconf = fopen(self::raidconf_old, "w+");
    if ($oldconf) {
      fwrite($oldconf, $oldconf_data);
      fclose($oldconf);
    } else {
      return 6;
    }
    
    //################################################################
    //#  Assemble old raid conf (/tmp/raid.old)
    //################################################################
    $raid_count=0;
    $conf_template_new=$conf_template;
    $conf_template_new=$conf_template_new . (($newType=="5")?"parity-algorithm    left-symmetric\n":"");
    foreach ($post['_migrate_disk'] as $mdisk){
      $conf_template_new=$conf_template_new . "device		/dev/sd" . $mdisk . "2\n";
      $conf_template_new=$conf_template_new . "raid-disk  " . $raid_count . "\n";
      $raid_count++;
    }
    $new_raid_count=$raid_count;

    $newconf_data=sprintf($conf_template_new,self::$devmd,$newType,$raid_count,$chunksize);
    //echo "[" . self::raidconf_new . "] newconf_data=" . $newconf_data . "<br>";
    $newconf = fopen(self::raidconf_new, "w+");
    if ($newconf) {
      fwrite($newconf, $newconf_data);
      fclose($newconf);
    } else {
      return 7;
    }
    //################################################################
    //#  Check RAID0=>RAID0 and RAID5=>RAID5 and RAID6=>RAID6
    //################################################################
    if($post["_type"]=="0_0" || $post["_type"]=="5_5" || $post["_type"]=="6_6"){
      if($new_raid_count==$old_raid_count){
        return 11;
      }
    }
    //################################################################
    //#  Check if to migrate on line:
    //#  On_line migration support
    //# 1. R1 -> R5 or R6
    //#  2. R5 -> R5 or R6 -> R6
    //#    i.  the size of any added disk can't be smaller than the minimum disk of original raid
    //#    ii. if not, return error(12)
    //################################################################
    $is_on_line_migrate=0;
    $min_size_added_disk=0;
    $min_size_used_disk=0;
    if($post["_type"]=="1_5" || $post["_type"]=="1_6" || $post["_type"]=="5_5" || $post["_type"]=="5_6" || $post["_type"]=="6_6"){
      $is_on_line_migrate=1;
      if($post["_type"]=="1_5" || $post["_type"]=="5_5" || $post["_type"]=="5_6" || $post["_type"]=="6_6"){
        //check the size
        foreach ($post['_migrate_disk'] as $mdisk){
          $pos = strpos($use_disk, "'sd" . $mdisk . "2'");
          //echo "pos=" . $pos . "  use_disk=$use_disk  mdisk=$mdisk <br>" ;
          $disk_size_tmp=shell_exec("awk '/sd".$mdisk."$/{printf(\"%d\",$3/1024)}' /proc/partitions");
                    $disk_size_tmp=(int)$disk_size_tmp;
          if ($pos<=0) {
            //added disk
            if( ($min_size_added_disk == 0) || ($min_size_added_disk > $disk_size_tmp) ){
              $min_size_added_disk=$disk_size_tmp;
            }
          } else {
            //used disk
            if( ($min_size_used_disk == 0) || ($min_size_used_disk > $disk_size_tmp) ){
              $min_size_used_disk=$disk_size_tmp;
            }
          }
          //echo (($pos<=0)?"Add":"Use")."=$disk_size_tmp,min_size_added_disk=$min_size_added_disk,min_size_used_disk=$min_size_used_disk<br>";
        }
        
        if($min_size_added_disk < $min_size_used_disk){
          //return error(12)
          return 13;
        }
        
      }
    }
    //echo "is_on_line_migrate=$is_on_line_migrate<br>";
    //################################################################    
    
    //partition split .....
    $match_count=0;
    $targetcount=0;
    $strexec="";
    //print_r($post['_migrate_disk']);
    self::set_raid_partition_type(self::$mdnum);
    foreach ($post['_migrate_disk'] as $mdisk){
      $pos = strpos($use_disk, "'sd" . $mdisk . "2'");
      //echo "pos=" . $pos . "  use_disk=$use_disk  mdisk=$mdisk <br>" ;
      if ($pos<=0) {
        $strexec=$strexec . self::partition_cmd("sd" . $mdisk) . ";";
      } else {
        $match_count++;
      }
      $strsize.="/sd" . $mdisk . "2/||";
      $targetcount++;
    }
    $strsize=($strsize!="")?substr($strsize,0,strlen($strsize)-2):$strsize;
    
    //echo "match_count=" . $match_count . "  rcount=" . $rcount . "<br>";
    if ($match_count!=$rcount){
      return $rcount."111";
      //return 9;  //Must include original all disk 
    }
    //echo "strexec=$strexec <br>"; 
    if ($strexec!="") shell_exec($strexec);
    $strexec="pvdisplay --units g " . self::$devmd . "|awk '/PV Size/{printf(\"%d\",$3)}'";
    $current_size=shell_exec($strexec);
    if ($newType=="0") {
      $strsize="cat /proc/partitions|awk '" . $strsize . "{disksize=disksize+$3}END{printf(\"%d\",disksize/1024/1024)}'";
    } elseif ($newType=="5") {
      $strsize="cat /proc/partitions|awk '" . $strsize . "{disksize=$3;if (lsize<=0) lsize=disksize;if (disksize < lsize) lsize=disksize;}END{printf(\"%d\",lsize*" . ($targetcount-1) . "/1024/1024)}'";
    } elseif ($newType=="6") {
      $strsize="cat /proc/partitions|awk '" . $strsize . "{disksize=$3;if (lsize<=0) lsize=disksize;if (disksize < lsize) lsize=disksize;}END{printf(\"%d\",lsize*" . ($targetcount-2) . "/1024/1024)}'";
    }
    $target_size=shell_exec($strsize);
    //echo "1.[" . $current_size . "]" . $strexec . "<br>";
    //echo "2.[" . $target_size . "]" . $strsize . "<br>";
    
    if ($target_size < $current_size) {
      //target less than original size
      return 10;
    }
    
    //Start Migrate the RAID
    if($is_on_line_migrate==1){
      $strExec="sh -x /img/bin/migrate_raid_online.sh " . self::$mdnum . " >/tmp/migrate_online.log 2>&1 &";
      //return 100;
    }else{
      $strExec="sh -x /img/bin/migrate_raid.sh " . self::$mdnum . " >/tmp/migrate_offline 2>&1";
    }
    //echo "strExec=$strExec <br>";
    system($strExec);
    //shell_exec("sleep 5");
    //Check migrating ....  
    if($is_on_line_migrate==1){
      return 100;
    }else{
      if (self::chk_migrate_start()==0) {
        //Migration is progress ....
        echo "Migration not success !!<br>";
        return 8;
      }
      return 0;
    }
    
    return 0;
  }


  
  public function nest_migrate($post) {
    $raidconf_a_old="/tmp/raid_a.old";
    $raidconf_b_old="/tmp/raid_b.old";
    $raidconf_a_new="/tmp/raid_a.new";
    $raidconf_b_new="/tmp/raid_b.new";
    $xType=trim($x['RaidLevel']);//old raid type
    $xChunkSize=trim($x['ChunkSize']);

    $aryTran=explode("_",$post["_type"]);
    $newType=$aryTran[1];//new raid type

    unlink($raidconf_a_old);
    unlink($raidconf_b_old);
    unlink($raidconf_a_new);
    unlink($raidconf_b_new);
    //################################################################
    //#  RAID conf template
    //################################################################
    $conf_template="";
    $conf_template=$conf_template . "raiddev		%s\n";
    $conf_template=$conf_template . "raid-level		%d\n";
    $conf_template=$conf_template . "nr-raid-disks		%d\n";
    $conf_template=$conf_template . "chunk-size		%d\n";
    $conf_template=$conf_template . "persistent-superblock		1\n";

    $raid_count=0;
    $conf_template_old=$conf_template;
    $conf_template_old=$conf_template_old . (($xType=="50")?"parity-algorithm		left-symmetric\n":"");

    $x = new RAIDINFO();
    $x->setmdselect(0);
    $class2 = new DISKINFO();
    $disk_info=$class2->getINFO();
    $disk_list=$disk_info["DiskInfo"];
    self::$devmd="/dev/md".(self::$mdnum*2+30);
    $x = $x->getINFO(self::$mdnum*2+30);
    foreach ($x['RaidDisk'] as $d){
      $conf_template_old=$conf_template_old . "device		/dev/" . $d . "\n";
      $conf_template_old=$conf_template_old . "raid-disk  " . $raid_count . "\n";
      $raid_count++;
    }
    $old_raid_count=$raid_count;

    $rcount=0;
    foreach ($x['RaidDisk'] as $d){
      $use_disk=$use_disk . ",'" . $d . "'";
      $rcount++;
    }

    $chunksize=(trim($x['ChunkSize'])!="")?trim($x['ChunkSize']):"64";

    $oldconf_data=sprintf($conf_template_old,self::$devmd,substr($xType,0,1),$raid_count,$chunksize);
    $oldconf = fopen($raidconf_a_old, "w+");
    if ($oldconf) {
      fwrite($oldconf, $oldconf_data);
      fclose($oldconf);
    } else {
      return 6;
    }

    //################################################################
    //#  Assemble old raid conf (/tmp/raid.old)
    //################################################################
    $raid_count=0;
    $min_size_used_disk = 0;
    $min_size_added_disk = 0;
    $conf_template_new=$conf_template;
    $conf_template_new=$conf_template_new . (($aryTran[1]=="50")?"parity-algorithm		left-symmetric\n":"");
    foreach ($x['RaidDisk'] as $d){
      $conf_template_new=$conf_template_new . "device		/dev/" . $d . "\n";
      $conf_template_new=$conf_template_new . "raid-disk  " . $raid_count . "\n";
      $raid_count++;
      $device=substr($d,0,strlen($d)-1);
      $disk_size_tmp=shell_exec("awk '/".$device."$/{printf(\"%d\",$3/1024)}' /proc/partitions");
      if( ($min_size_used_disk == 0) || ($min_size_used_disk > $disk_size_tmp) ){
          $min_size_used_disk=$disk_size_tmp;
      }
    }
    $migrate_count=count($_POST["spare"]);
    $count=1;
    foreach ($_POST["spare"] as $mdisk){
      if($count <= $migrate_count/2){
        $conf_template_new=$conf_template_new . "device		/dev/sd" . $disk_list[$mdisk][4] . "2\n";
        $conf_template_new=$conf_template_new . "raid-disk  " . $raid_count . "\n";
        $raid_count++;
        $disk_size_tmp=shell_exec("awk '/sd".$disk_list[$mdisk][4]."$/{printf(\"%d\",$3/1024)}' /proc/partitions");
        if( ($min_size_added_disk == 0) || ($min_size_added_disk > $disk_size_tmp) ){
          $min_size_added_disk=$disk_size_tmp;
        }
      }
      $count++;
    }
    $new_raid_count=$raid_count;

    $newconf_data=sprintf($conf_template_new,self::$devmd,substr($newType,0,1),$raid_count,$chunksize);
    //echo "[" . self::raidconf_new . "] newconf_data=" . $newconf_data . "<br>";
    $newconf = fopen($raidconf_a_new, "w+");
    if ($newconf) {
      fwrite($newconf, $newconf_data);
      fclose($newconf);
    } else {
      return 7;
    }

    //check the size
    if($min_size_added_disk < $min_size_used_disk){
      return 13;
    }

    $raid_count=0;
    $conf_template_old=$conf_template;
    $conf_template_old=$conf_template_old . (($xType=="50")?"parity-algorithm    left-symmetric\n":"");

    $x = new RAIDINFO();
    $x->setmdselect(0);
    self::$devmd="/dev/md".(self::$mdnum*2+31);
    $x = $x->getINFO(self::$mdnum*2+31);
    foreach ($x['RaidDisk'] as $d){
      $conf_template_old=$conf_template_old . "device		/dev/" . $d . "\n";
      $conf_template_old=$conf_template_old . "raid-disk  " . $raid_count . "\n";
      $raid_count++;
    }
    $old_raid_count=$raid_count;

    $rcount=0;
    foreach ($x['RaidDisk'] as $d){
      $use_disk=$use_disk . ",'" . $d . "'";
      $rcount++;
    }

    $chunksize=(trim($x['ChunkSize'])!="")?trim($x['ChunkSize']):"64";

    $oldconf_data=sprintf($conf_template_old,self::$devmd,substr($xType,0,1),$raid_count,$chunksize);
    $oldconf = fopen($raidconf_b_old, "w+");
    if ($oldconf) {
      fwrite($oldconf, $oldconf_data);
      fclose($oldconf);
    } else {
      return 6;
    }

    //################################################################
    //#  Assemble old raid conf (/tmp/raid.old)
    //################################################################
    $raid_count=0;
    $min_size_used_disk = 0;
    $min_size_added_disk = 0;
    $conf_template_new=$conf_template;
    $conf_template_new=$conf_template_new . (($aryTran[1]=="50")?"parity-algorithm		left-symmetric\n":"");
    foreach ($x['RaidDisk'] as $d){
      $conf_template_new=$conf_template_new . "device		/dev/" . $d . "\n";
      $conf_template_new=$conf_template_new . "raid-disk  " . $raid_count . "\n";
      $raid_count++;
      $device=substr($d,0,strlen($d)-1);
      $disk_size_tmp=shell_exec("awk '/".$device."$/{printf(\"%d\",$3/1024)}' /proc/partitions");
      if( ($min_size_used_disk == 0) || ($min_size_used_disk > $disk_size_tmp) ){
          $min_size_used_disk=$disk_size_tmp;
      }
    }
    $migrate_count=count($_POST["spare"]);
    $count=1;
    foreach ($_POST["spare"] as $mdisk){
      if($count > $migrate_count/2){
        $conf_template_new=$conf_template_new . "device		/dev/sd" . $disk_list[$mdisk][4] . "2\n";
        $conf_template_new=$conf_template_new . "raid-disk  " . $raid_count . "\n";
        $raid_count++;
        $disk_size_tmp=shell_exec("awk '/sd".$disk_list[$mdisk][4]."$/{printf(\"%d\",$3/1024)}' /proc/partitions");
        if( ($min_size_added_disk == 0) || ($min_size_added_disk > $disk_size_tmp) ){
          $min_size_added_disk=$disk_size_tmp;
        }
      }
      $count++;
    }
    $new_raid_count=$raid_count;

    $newconf_data=sprintf($conf_template_new,self::$devmd,substr($newType,0,1),$raid_count,$chunksize);
    //echo "[" . self::raidconf_new . "] newconf_data=" . $newconf_data . "<br>";
    $newconf = fopen($raidconf_b_new, "w+");
    if ($newconf) {
      fwrite($newconf, $newconf_data);
      fclose($newconf);
    } else {
      return 7;
    }

    //check the size
    if($min_size_added_disk < $min_size_used_disk){
      return 13;
    }

    $strExec="sh -x /img/bin/nest_migrate_raid_online.sh " . (self::$mdnum) . " >/tmp/nest_migrate_online.log 2>&1 &";
    system($strExec);

    return 101;
  }  

  //########################################################
  //#  Check total capacity limitation function
  //########################################################
  public function get_sum_of_hd_size($array_disk_size){
    $sum_of_hd_size=0;
    foreach($array_disk_size as $v){
      $sum_of_hd_size+=$v;
    }
    //echo "sum_of_hd_size=".$sum_of_hd_size."<br>";
    return $sum_of_hd_size;
  }

  public function get_min_hd_size($array_disk_size){
    $i=0;
    $min_hd_size=0;
    foreach($array_disk_size as $v){
      if($i++==0){
        $min_hd_size=$v;
      }else{
        if($min_hd_size > $v){
          $min_hd_size=$v;
        }
      }
    }
    //echo "min_hd_size=".$min_hd_size."<br>";
    return $min_hd_size;
  }

  public function get_raid_10_hd_size($array_disk_size){
    $i=0;
    $sum_of_hd_size=0;
    $min_hd_size=0;
    foreach($array_disk_size as $v){
      if($i++%2==0){
        $min_hd_size=$v;
      }else{
        if($min_hd_size > $v){
          $min_hd_size=$v;
        }
        $sum_of_hd_size+=$min_hd_size;
      }
      //echo "min=".$min_hd_size."<br>";
      //echo "sum=".$sum_of_hd_size."<br>";
    }
    //echo "sum_of_hd_size=".$sum_of_hd_size."<br>";
    return $sum_of_hd_size;
  }

  public function get_capacity($datapercet,$raid_level,$array_disk_size){
    //echo "per=".$datapercet."<br>";
    $capacity=0;
    switch ($raid_level) {
      case "J":
        $capacity=(self::get_sum_of_hd_size($array_disk_size))*$datapercet/100;
        break;
      case "0":
        $capacity=(self::get_sum_of_hd_size($array_disk_size))*$datapercet/100;
        break;
      case "1":
        $capacity=(self::get_min_hd_size($array_disk_size))*$datapercet/100;
        break;
      case "5":
        $capacity=(count($array_disk_size)-1)*(self::get_min_hd_size($array_disk_size))*$datapercet/100;
        break;
      case "6":
        $capacity=(count($array_disk_size)-2)*(self::get_min_hd_size($array_disk_size))*$datapercet/100;
        break;
      case "10":
        $capacity=(self::get_raid_10_hd_size($array_disk_size))*$datapercet/100;
        break;
    }
    return number_format($capacity,2,".","");
  }

  public function get_total_capacity($_POST,$raidinfo,$tray_id){
    $fsmode=trim($_POST["filesystem"]);
    if ($fsmode == "ext3" || $fsmode == "ext4"){
      $data_percent=trim($_POST["data_percent"]);
      $raid_level=trim($_POST["type"]);
      $spare= $_POST['spare'];

      $unit_GB=1024*1024;
      $swap_size=2;//UNIT:GB Swap Size=2048000/1024/1024

      $disk_size=array();
      $disk_map=$raidinfo["TrayMap"];

      foreach($tray_id as $v){
        if(! in_array($v-1, $spare)){
          $device=substr($disk_map[$v],0,strlen($disk_map[$v])-1);
          $disk_size[]=number_format((self::get_devicesize($device)/($unit_GB)),2,".","") - $swap_size;
          //echo number_format(($raid->get_devicesize($device)/($unit_GB)),2,".","")."<br>";
        }
      }
      //print_r($disk_size);
      //echo "<br>";
      $total_capacity=self::get_capacity($data_percent,$raid_level,$disk_size);
      return $total_capacity;
    }
  }

  public function check_limitation($fsmode,$total_capacity){
    if($total_capacity != 0 ){
      switch ($fsmode) {
        case "ext3":
          $max_size_for_ext3=8*1024;//UNIT:GB
          if($total_capacity > $max_size_for_ext3){
            return 1;
          }
          break;
//        case "ext4":
//          $max_size_for_ext4=16*1024;//UNIT:GB
//          if($total_capacity > $max_size_for_ext4){
//            return 2;
//          }
//          break;
        default:
          return 0;
          break;
      }
    }
  }
  
  /** 
   * Return the master RAID id on system. 
   * @return Master RAID id. 
   */ 
   public static function getMasterRaid(){ 
        $link = readlink('/var/tmp/rss'); 
        $masterRaid = explode('/', $link); 
        return $masterRaid[3]; 
    }
}

?>
