 <?
/*
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if(!$is_function){
  require_once("/var/www/html/inc/function.php");
  check_system("0","access_warning","about");
}
//#######################################################
require_once("../../inc/raid.class.php");
require_once("../../inc/lvm.class.php");
require_once("../../inc/info/raidinfo.class.php");
*/

require_once(INCLUDE_ROOT.'smbconf.class.php');
require_once(INCLUDE_ROOT.'raid.class.php');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'thecusio.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(FUNCTION_CONF_ROOT.'raid_conf.inc');

get_sysconf();

$gwords = $session->PageCode("global");
$words = $session->PageCode("raid");

$action=($_POST["action"]!="")?trim($_POST["action"]):trim($_GET["action"]);
$lock=($_POST["lock"]!="")?trim($_POST["lock"]):trim($_GET["lock"]);
$md_num=trim($_POST["md_num"]);
$raid_id=trim($_POST["raid_id"]);
$ismasterraid=($_POST["master"]==""?"0":trim($_POST["master"]));
$raid_level=trim($_POST["type"]);
$zfs_status=check_zfs_count();
$fsmode=trim($_POST["filesystem"]);
$data_percent=trim($_POST["data_percent"]);
$data_percent=substr($data_percent,0,strlen($data_percent)-2);

if($action=="destroy" && $md_num!=""){
  set_time_limit(120);
  //===========================================================
  //
  //      By hubert_huang@thecus.com
  //
  //      Step 1  :       stop_service();
  //      Step 2  :       check_post_create();
  //      Step 3  :       umount_raid();
  //      Step 4  :       stop_raid();
  //      Step 5  :       blind_erase_superblock();
  //      Step 6  :       remove_swapdisk();
  //      Step 7  :       blind_gdisk();
  //      Step 8  :       set_noraid();
  //      Step 9  :       set master raid
  //      Step 10 :       remove rss tmp folder
  //      Step 11 :       start_service();
  //
  //===========================================================
  $addshare=FALSE;
  $SmbConf=FALSE;
  $raid=FALSE;
  $md=FALSE;
  $ary = array('ok'=>'window_raid_hide()');
  if (Stop_Steps($md_num)==0) {
    return  MessageBox(true,$words["raid_config_title"],$words["destroyRAIDFail"],ERROR,OK,$ary);
  }else{
    if ($sysconf["arch"] == 'oxnas')
    {
      $ary = array('ok'=>'redirect_reboot()');
      return  MessageBox(true,$words["raid_config_title"],$words["destroyRAIDReboot"],INFO,OK,$ary);
    }
    else
    {
      return  MessageBox(true,$words["raid_config_title"],$words["destroyRAID"],INFO,OK,$ary);
    }
  }
}
return  MessageBox(true,$words["raid_config_title"],$words["destroyRAIDFail"]."..",ERROR);

//===========================================================
//      Step 1 : Stop service
//===========================================================
function stop_service() {
  global $num;
  shell_exec("/img/bin/service stop > /dev/null 2>&1");
  if (file_exists("/opt/VisoGuard/shell/module.rc")) {
    shell_exec("/opt/VisoGuard/shell/module.rc remove ".$num." > /dev/null 2>&1");
  } else if (file_exists("/opt/VisoGuard")) {	// VisoGuard is uninstalled but Distribution exists
    shell_exec("rm -rf /opt/VisoGuard > /dev/null 2>&1");
  }
}
//===========================================================
//      Step 2 : Check post_create
//===========================================================
function check_post_create(){
  $strExec="/bin/ps | grep post_create | grep -v grep";
  $ret=shell_exec($strExec);
  if($ret==""){
    return 1;
  }else{
    return 0;
  }
}
//===========================================================
//      Step 3 : Umount RAID mount point
//===========================================================
function umount_raid(){
  global $num;
  if (NAS_DB_KEY == '1'){
    $cmd="/img/bin/stop_volumn.sh ".$num." > /tmp/stop_volumn.log 2>&1";
  }else{
    $cmd="/img/bin/stop_volume.sh ".$num." > /tmp/stop_volume.log 2>&1";
  }
  $result=shell_exec($cmd);
  if (preg_match("/Fail/",$result)) {
    echo $result . "<br>";
    return 0;
  } else {
    return 1;
  }
}
//===========================================================
//      Step 4 : Stop raid
//===========================================================
function stop_raid() {
  global $raid;
  shell_exec($raid->stop_raid());
}
//===========================================================
//      Step 5 : Erase RAID superblock
//===========================================================
function blind_erase_superblock() {
  global $raid,$sd;
  $raid->blind_erase_superblock($sd);
}
//===========================================================
//      Step 6 : Remove disk in swap
//===========================================================
function remove_swapdisk() {
  global $num,$sd;
  //first swapoff
  if (NAS_DB_KEY == '1'){
    $strExec="/sbin/swapoff /dev/md0";
  }else{
    $strExec="/sbin/swapoff /dev/md10";
  }
  shell_exec($strExec);
  if (NAS_DB_KEY == '1'){
    $temp="mdadm /dev/md0 --fail /dev/%s1 2>&1;mdadm /dev/md0 --remove /dev/%s1 2>&1";
  }else{
    $temp="mdadm /dev/md10 --fail /dev/%s1 2>&1;mdadm /dev/md10 --remove /dev/%s1 2>&1";
  }
  foreach($sd as $d) {
    if (NAS_DB_KEY == '1'){
      $strExec="mdadm -D /dev/md0 | awk '/${d}1/{print}'";
    }else{
      $strExec="mdadm -D /dev/md10 | awk '/${d}1/{print}'";
    }
    $raid_member=trim(shell_exec($strExec));
    if($raid_member!=""){
      $cmd=sprintf($temp,$d,$d);
      shell_exec($cmd);
    }
  }
  //Get MD0 info
  if (NAS_DB_KEY == '1'){
    $strExec="mdadm -D /dev/md0|awk -F: '/Active Devices/{printf(\"%d\",$2)}'";
  }else{
    $strExec="mdadm -D /dev/md10|awk -F: '/Active Devices/{printf(\"%d\",$2)}'";
  }
  $retval=shell_exec($strExec);
  //echo "retval=$retval <br>";
  if ($retval==0) {
    //remove swap raid ==> /dev/md0
    if (NAS_DB_KEY == '1'){
      $strExec="mdadm -S /dev/md0";
    }else{
      $strExec="mdadm -S /dev/md10";
    }
    shell_exec($strExec);
  }else {
    //Try to swapon
    if (NAS_DB_KEY == '1'){
      $strExec="/sbin/swapon /dev/md0";
    }else{
      $strExec="/sbin/swapon /dev/md10";
      if ($retval==1) {
        foreach($sd as $d) {
          $strExec2="mdadm -D /dev/md10 | awk '/${d}1/{print}'";
          $raid_member=trim(shell_exec($strExec2));
          if($raid_member!=""){ //remove fail
            $strExec="mdadm -S /dev/md10";
          }
        }
      }
    }
    shell_exec($strExec);
  }
}

function remove_sysdisk() {
  global $num,$sd,$sysnum;
  //first umount
  $strExec="rm -rf /raidsys/$num/*";
  shell_exec($strExec);
  if ($num > 10)
    $sysnum=$num+10;
  else
    $sysnum=$num+50;
  $strExec="/bin/umount /dev/md".sprintf("%d",$sysnum);
  $retval=shell_exec($strExec);
  //echo "retval=$retval <br>";
  if ($retval==0) {
    $strExec="mdadm -S /dev/md".sprintf("%d",$sysnum);
    shell_exec($strExec);
  }
}
//===========================================================
//      Step 7 : Blind gdisk
//===========================================================

function blind_gdisk() {
  global $num,$sd;
  $temp="/usr/sbin/sgdisk -oZ /dev/%s ";
  foreach($sd as $d) {
    $cmd=sprintf($temp,$d);
    shell_exec($cmd);
  }
}

//===========================================================
//      Step 8 : Update raid status
//===========================================================
function set_noraid() {
  global $raid;
  $raid->set_noraid();
}
//===========================================================
//      Step 11 : start service
//===========================================================
function start_service() {
  shell_exec("/img/bin/service start > /dev/null 2>&1");
}
//================================================
//      Execute sync system call
//================================================
function sync() {
  shell_exec("sync;sync;sync");
}
//===========================================================
//      Useless : Erase RAID superblock
//===========================================================
function erase_superblock() {
  global $raid;
  $raid->erase_superblock();
}

function delete_snapshot_cron($num){
  if (NAS_DB_KEY == '1'){
    shell_exec("/img/bin/rc/rc.snapshot del_raid \"".($num-1)."\" > /dev/null 2>&1");
  }else{
    shell_exec("/img/bin/rc/rc.snapshot del_raid \"".($num)."\" > /dev/null 2>&1");
  }
}
//===========================================================
//      steps
//===========================================================
function Stop_Steps($md_num) {
  global $thecusio,$raid,$raidinfo,$addshare,$SmbConf,$num,$sd;
  $num=$md_num;
  $thecusio=new THECUSIO();
  $info=new RAIDINFO();
  $info->setmdselect(0);
  $raidinfo=$info->getINFO($num);

  if (NAS_DB_KEY == '1'){
    $strExec="/img/bin/model/backup_superblock.sh \"RR_\"";
  }else{
    $strExec="/img/bin/backup_superblock.sh \"RR_\"";
  }
  shell_exec($strExec);

  $raid=new raid();
  $raid->mdSwitch($num);
  $thecusio->setLED("Busy","1");
  stop_service();
  $ret=check_post_create();
  if($ret){
    if(umount_raid()==0){
      $thecusio->setLED("Busy","0");
      return 0;
    }
    stop_raid();
    $sd=array();
    foreach($raidinfo["RaidDisk"] as $d){
      $sd[]=substr($d,0,strlen($d)-1);
    }
    if (NAS_DB_KEY == '2'){
      foreach($raidinfo["SpareList"] as $d){
        $sd[]=substr($d,0,strlen($d)-1);
      }
    }
    remove_swapdisk();
    if (NAS_DB_KEY == '2'){
      remove_sysdisk();
    }
    blind_erase_superblock();
    //blind_gdisk();
    sync();
    set_noraid();
    sync();
    if($raidinfo["RaidMaster"]){
      $md_array=$info->getMdArray();
      $total_raid_count=count($md_array);
      if($total_raid_count > 0){
        shell_exec("/img/bin/set_masterraid.sh $md_array[0]");
        sync();
      }
    }
    if (NAS_DB_KEY == '1'){
      shell_exec("rm -rf /var/tmp/raid".($num-1));
    }else{
      shell_exec("rm -rf /var/tmp/raid".$num);
    }
    delete_snapshot_cron($num);   
//    if($raidinfo["RaidMaster"])
//      if(count($raidinfo["TotalRaidDisk"])-count($raidinfo["RaidDisk"])>0){

    shell_exec("/img/bin/logevent/event 158 ".$raidinfo["RaidID"]." >/dev/null 2>&1 &");
    shell_exec("/img/bin/logevent/event 232 ".$raidinfo["RaidID"]." >/dev/null 2>&1 &");
    start_service();
//      }
    $thecusio->setLED("Busy","0");
    return 1;
  }else{
    $thecusio->setLED("Busy","0");
    return 0;
  }
}
?>
