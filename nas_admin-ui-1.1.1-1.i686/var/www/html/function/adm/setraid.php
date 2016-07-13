<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'raid.class.php');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(FUNCTION_CONF_ROOT.'raid_conf.inc');
require_once(INCLUDE_ROOT.'validate.class.php');

get_sysconf();

$gwords = $session->PageCode("global");
$words = $session->PageCode("raid");
//$dwords = $session->PageCode("disk");

ignore_user_abort(FALSE);
set_time_limit(0);
error_reporting(E_ERROR);

$action=($_POST["action"]!="")?trim($_POST["action"]):trim($_GET["action"]);
$raid_id=trim($_POST["raid_id"]);
$hbip=trim($_POST["hbip"]);
$hbtype = trim($_POST['hbtype']);
if($action == 'harecover'){
    shell_exec("/img/bin/ha/script/raid.sh rebuild check \"$hbip\" \"$hbtype\" > /dev/null 2>&1 &");
    die("0");
}

$class=new RAIDINFO();
$class->setmdselect(0);
// for create wizard by Ellie 2010.09.03
// need to call unlockRaidWizard() when create wizard is ending
$wizard_lock_file = "/tmp/raidwizard_lock";
if (!isset($_POST["lock"]) && $_POST["lock"] != 1) {
  if ($action == "checkid") {
    if($ary = check_raidid($raid_id)){
      return  MessageBox(true,$ary[0],$ary[1],ERROR);
    }
    return  MessageBox(false,'','','','',"raidIdOk()");
  } else if ($action == "create") {
    // avoid the duplicate wizard of "Create Raid"
    $wizardlock = shell_exec("cat ".$wizard_lock_file);
    if ($wizardlock == 1 || check_raid_lock() == 0) {
      return  MessageBox(true,$words["raid_config_title"],$words["create_duplicate"],ERROR);
    }
    shell_exec("echo 1 > ".$wizard_lock_file);
  }
}

$lock=($_POST["lock"]!="")?trim($_POST["lock"]):trim($_GET["lock"]);
$md_num=trim($_POST["md_num"]);
$ismasterraid=($_POST["master"]==""?"0":trim($_POST["master"]));
$raid_level=trim($_POST["type"]);
$zfs_status=check_zfs_count();
$fsmode=trim($_POST["filesystem"]);
if (NAS_DB_KEY == '1'){
$data_percent=trim($_POST["data_percent"]);
  $data_percent=substr($data_percent,0,strlen($data_percent)-2);
}else{
  $data_percent=100;
}
$assume_option=trim($_POST["_assume_clean"]);
//return  MessageBox(true,$words["raid_config_title"],$data_percent,ERROR);

if($assume_option==""){
  $assume_option=0;
}

if($fsmode=="zfs"){
  if($zfs_status=="1"){
    $msg=sprintf($words["zfs_count_limit"],$zfs_limit);
    unlockRaidWizard();
    return MessageBox(true,$words["raid_config_title"],$msg,ERROR);
  }
}

$open_mraid=trim($sysconf["m_raid"]);
$raid=new raid();

//=====================================
//    Get Disk Tray
//=====================================
$disk_tray=array();//for setting disk tray in rss
$tray_id=array();//for compare not assign disk
$add_spare=array();
if($md_num!=""){
  $raidinfo=$class->getINFO($md_num);
  foreach($raidinfo["RaidList"] as $v){
    $disk_tray[]="\"$v\"";
  }
  foreach($raidinfo["Spare"] as $v){
    if($v!=""){
      $disk_tray[]="\"$v\"";
    }
  }
}else{
  $raidinfo=$class->getINFO();
}

//$inraid=explode(",",trim($_POST["inraid"]));
//$inraid=trim($_POST["inraid"]);
//$_POST["inraid"]=array();
//$_POST["inraid"]=$inraid;
$inraid= $_POST['inraid'];
if($_POST["inraid"]!=""){
  foreach($inraid as $k=>$v){
    if($v!=""){
      $tray="\"".($v)."\"";
      $disk_tray[]=$tray;
      $tray_id[]=$v;
      $add_spare[]=$tray;
    }
  }
}

$spare= $_POST['spare'];
if($_POST["spare"]!=""){
  foreach($spare as $v){
    if($v!=""){
      $tray="\"".($v)."\"";
      $disk_tray[]=$tray;
      $tray_id[]=$v;
      $add_spare[]=$tray;
    }
  }
}

sort($disk_tray);
sort($tray_id);


//########################################################
//#  Check Disk is exist
//########################################################
foreach($disk_tray as $num){
  if($num!=""){
    $tray_num=substr($num,1,strlen($num)-2);
    $strExec="cat /proc/scsi/scsi | grep \"Thecus: Tray:${tray_num} Disk:\"";
    $ret=shell_exec($strExec);
    if($ret==""){
      unlockRaidWizard();
      return  MessageBox(true,$words["raid_config_title"],$words["disk_not_exist"],ERROR);
    }
  }
}
//########################################################
//#  Check Check tray id whether in the not assign disk
//########################################################
$check_post_notassigndisk=$class->check_post_notassigndisk($tray_id);
if($check_post_notassigndisk){
  unlockRaidWizard();
  return  MessageBox(true,$words["raid_config_title"],$words["disk_is_be_assigned"].$check_post_notassigndisk,ERROR);
}
//########################################################
//#  Check migration whether start
//########################################################
if (NAS_DB_KEY == '1'){
  if ($raid->chk_migrate_start()==1) {
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$words["createRAIDError"],ERROR);
  }
}
//########################################################
//#  Check total capacity limitation function
//########################################################
$total_capacity=$raid->get_total_capacity($_POST,$raidinfo,$tray_id);
//echo "total_capacity=$total_capacity<br>";
$limitation=$raid->check_limitation($fsmode,$total_capacity);
if($limitation == 1){
  unlockRaidWizard();
  return  MessageBox(true,$words["raid_config_title"],$words["ext3_8t_size_limit"],ERROR);
}elseif($limitation == 2){
  unlockRaidWizard();
  return  MessageBox(true,$words["raid_config_title"],$words["ext4_16t_size_limit"],ERROR);
}

//########################################################
//  if $_POST["_lock"] is set
//   _lock == 0 ,meaning no any raid exist (create)
//   _lock == 1 ,meaning have raid exist (edit)
//########################################################
if(isset($_POST["lock"]) && $_POST["lock"]==1) {
  //########################################################
  //  Update Disk Tray
  //########################################################
  if (NAS_DB_KEY == '1'){
    $strExec="/bin/rm -rf /var/tmp/raid".($md_num-1)."/disk_tray";
  }else{
    $strExec="/bin/rm -rf /var/tmp/raid".($md_num)."/disk_tray";
  }
  shell_exec($strExec);
  foreach($disk_tray as $num){
    $spare_array_count=count($add_spare);
    $spare_count="0";
    for($c=0;$c<$spare_array_count;$c++){
      if(preg_match("/$add_spare[$c]/",$num)){
        $spare_count++;
      }
    }
    if($spare_count=="0"){
      if (NAS_DB_KEY == '1'){
        $strExec="echo -e '$num' >> /var/tmp/raid".($md_num-1)."/disk_tray";
      }else{
        $strExec="echo -e '$num' >> /var/tmp/raid".($md_num)."/disk_tray";
      }
      shell_exec($strExec);
    }
  }
  //########################################################
  
  //print_r($disk_tray);
  //echo "<pre>";print_r($_POST);exit;
  $raid->mdSwitch($md_num);
  $raid_level=$raid->get_raid_level();
  if($raid_level=="J"){
    $count_spare=count($inraid);
  }else{
    $count_spare=count($spare);
  }
  if (NAS_DB_KEY == '1'){
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='raid_name'\"";
  }else{
    $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='raid_name'\"";
  }
  $o_raid_id=trim(shell_exec($strExec));
  if (NAS_DB_KEY == '1'){
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='raid_master'\"";
  }else{
    $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='raid_master'\"";
  }
  $o_raid_master=trim(shell_exec($strExec));
  if($raid_id!=$o_raid_id || $ismasterraid!=$o_raid_master){
  
    //#############################################################
    //#  Check RAID ID
    //#############################################################
    if($raid_id!=$o_raid_id &&  ($ary = check_raidid($raid_id)))
      return  MessageBox(true,$ary[0],$ary[1],ERROR);
  
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"update conf set v='".$raid_id."' where k='raid_name'\"";
    }else{
      $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"update conf set v='".$raid_id."' where k='raid_name'\"";
    }
    shell_exec($strExec);
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"update conf set v='".$ismasterraid."' where k='raid_master'\"";
      shell_exec($strExec);
    }elseif($ismasterraid!=$o_raid_master){
      shell_exec("/img/bin/service stop > /dev/null 2>&1");
      $strExec="/img/bin/set_masterraid.sh ".$md_num;
      shell_exec($strExec);
      $strExec="/opt/VisoGuard/shell/module.rc change ".$md_num;
      shell_exec($strExec);
      shell_exec("/img/bin/service start > /dev/null 2>&1");
    }
    if (NAS_DB_KEY == '1'){
      $strExec="echo -e \"$raid_id\" > /var/tmp/raid".($md_num-1)."/raid_id";
    }else{
      $strExec="echo -e \"$raid_id\" > /var/tmp/raid".($md_num)."/raid_id";
    }
    shell_exec($strExec);
  }
  
  if($count_spare=="0"){
    $ary = array('ok'=>'window_raid_hide()');
    return  MessageBox(true,$words["raid_config_title"],$words["UpdateSuccess"],INFO,OK,$ary);
  }
  //########################################################
  //  Then into real add spare mode
  //########################################################
  $raid->add_spare($_POST);
  $result=$raid->commit();
  ignore_user_abort(TRUE);//meaning if php script interrupt,ignore it to continue run it to complete
  //echo "result = ${result}<br>";
  if($result!=0){
    if($result=="505"){
      return  MessageBox(true,$words["raid_config_title"],$words["add_spare_fail"],ERROR);
    }elseif($result=="509"){
      return  MessageBox(true,$words["raid_config_title"],$words["add_spare_fail"].", ".$words["add_spare_size_fail"],ERROR);
    }else{
      return  MessageBox(true,$words["raid_config_title"],$words["createRAIDError"],ERROR);
    }
    return $result;
  }
  shell_exec("/img/bin/raid_status >/dev/null 2>&1 &");
  foreach($add_spare as $spare){
    if (NAS_DB_KEY == '1'){
      $strExec="echo -e '$spare' >> /var/tmp/raid".($md_num-1)."/disk_tray";
    }else{
      $strExec="echo -e '$spare' >> /var/tmp/raid".($md_num)."/disk_tray";
    }
    shell_exec($strExec);
  }
  $dbpath = "/etc/cfg/conf.db";
  $disk_map=$raid->slot_map_dev();
  foreach($tray_id as $v){
    $device=substr($disk_map[$v],0,strlen($disk_map[$v])-1);
    shell_exec("echo \"$device\" >> /tmp/test");
    $Serial=trim(shell_exec('/usr/sbin/smartctl -i /dev/sd'.$device." | grep 'Serial [Nn]umber' | awk '{print $3}'"));
    shell_exec("/usr/bin/sqlite $dbpath \"delete from hot_spare where spare='$Serial'\"");
  }
  $ary = array('ok'=>'gotoRaidInfo()');
  return  MessageBox(true,$words["raid_config_title"],$words["createRAIDSuccess"],INFO,OK,$ary);
}else{//Create RAID
  //#############################################################
  //#  Check RAID ID
  //############################################################# 
  if($ary = check_raidid($raid_id)){
    unlockRaidWizard();
    return  MessageBox(true,$ary[0],$ary[1],ERROR);
  }

  if($_POST["_encrypt"]=="on"){
    $ret=shell_exec("/img/bin/check_usbrw.sh");
    if(!$ret){
      unlockRaidWizard();
      return  MessageBox(true,$words["raid_config_title"],$gwords["usbkey_ro"],ERROR);
    }
    //=====================================
    //    Handle Encrypt Key
    //=====================================
    $encrypt_key=($_POST['_encryptkey']);

    // add slash for special characters, for example: " '
    $tmp_key = '';
    for($i=0;$i<strlen($encrypt_key);$i++){
      $char=substr($encrypt_key,$i,1);
      if(ord($char)=="34" || ord($char)=="96"){
        $char=chr(92).$char;
      }
      $tmp_key.=$char;
    }
    $encrypt_key=$tmp_key;
  }
  //#############################################################
  //#  Check total raid limit
  //#############################################################
  $total_raid_limit=trim($sysconf["total_raid_limit"]);
  
  $md_array=$class->getMdArray();
  $total_raid_count=count($md_array);
  $handle = popen("find /raidsys/ -name ha_raid | wc -l",'r');
  $ha_raid = trim(fread($handle, 4096));
  $total_raid_count=$total_raid_count-$ha_raid;
  if($total_raid_count >= $total_raid_limit){
    $msg=sprintf($words["total_raid_limit"],$total_raid_limit);
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$msg,ERROR);
  }
  //#############################################################
  if(count($raidinfo["TotalRaidDisk"])!="0" && $open_mraid=="0"){
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$words["createRAIDError"],ERROR);
  }
  if($md_num=="" || $md_num=="0"){
    $md=new RAIDINFO();
    $md->setmdselect(0);
    if($fsmode=="hv"){
      $md_num=$md->getNewHVNum();
    }else{
      $md_num=$md->getNewMdNum();
    }
  }else{
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$words["createRAIDError"].$md_num,ERROR);
  }
  //#################################################
  //#  Check MD
  //#################################################
  if (NAS_DB_KEY == '1'){
    $raid_name="raid".($md_num-1);
    $vg_path="/dev/vg".($md_num-1);
  }else{
    $raid_name="raid".($md_num);
  }

  $strExec="df | awk -F' ' '/\/$raid_name\/data/{print $1}'";
  $mount_ret=shell_exec($strExec);
  if($mount_ret!=""){
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$words["raid_exist"],ERROR);
  }
  $strExec="df | awk -F' ' '/\/$raid_name\/sys/{print $1}'";
  $mount_ret=shell_exec($strExec);
  if($mount_ret!=""){
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$words["raid_exist"],ERROR);
  }
  $strExec="df | awk -F' ' '/\/$raid_name\/data\/target_usb/{print $1}'";
  $mount_ret=shell_exec($strExec);
  if($mount_ret!=""){
    unlockRaidWizard();
    return  MessageBox(true,$words["raid_config_title"],$words["raid_exist"],ERROR);
  }
  if (NAS_DB_KEY == '1'){
    $strExec="ls -1 ".$vg_path."/|awk -F@ '!/lv0/ && !/syslv/ && !/lv1/ && !/iscsi/{print $1}'";
    $snapshot_list=shell_exec($strExec);
    if($snapshot_list!=""){
      unlockRaidWizard();
      return  MessageBox(true,$words["raid_config_title"],$words["raid_exist"],ERROR);
    }
  }

  //#################################################
  $raid->mdSwitch($md_num);
  if(count($inraid)=="0"){
    unlockRaidWizard();
    $ary = array('ok'=>"raidWizardFinal()");
    return  MessageBox(true,$words["raid_config_title"],$words["UpdateSuccess"],INFO,OK,$ary);
  }

  //#################################################
  //#  Stop Service
  //#################################################
  if($ismasterraid == 1)
  shell_exec("/img/bin/service stop &");
  //#################################################
  $ret=shell_exec("/bin/ls -al /dev/md".$md_num." | awk -F ' ' '{printf($10)}'");
  if($ret==""){
    $strExec="/bin/mknod /dev/md".$md_num." b 9 ".$md_num;
    shell_exec($strExec);
  }

  //#################################################
  //  First, we should complete the RAID part
  //#################################################
  if($_POST["type"]=="J") $_POST["type"]="linear";

  if($total_raid_count == 0) $ismasterraid=1;
  //$raid->fulfillbuf(200);
  //return  MessageBox(true,$words["raid_config_title"],$words["createRAIDSuccess"]);
  $create_cmd=$raid->create($_POST);
  shell_exec("echo -e \"$create_cmd\" > /tmp/create_command.log");

  ignore_user_abort(TRUE);
  //#################################################  
  //#  set raid speed limit max
  //#################################################
  shell_exec("echo '".$raid_id."' > /tmp/tmp_raidname");
  //$strexec="sh -x /img/bin/post_create \"" . $md_num . "\" \"" . $data_percent . "\" \"" . $raid_id . "\" " . $ismasterraid . " \"" . $_POST["filesystem"] . "\" > /tmp/post_create.log 2>&1;";
  if($_POST["_encrypt"]=="on"){
    $strexec="sh -x /img/bin/post_create \"" . $md_num . "\" \"" . $data_percent . "\" \"" . $raid_id . "\" " . $ismasterraid . " \"" . $_POST["filesystem"] . "\" " .$assume_option. " \"".$encrypt_key."\" > /tmp/post_create.log 2>&1;";
    //echo "\"".$strexec."\"";
  }else{
    $strexec="sh -x /img/bin/post_create \"" . $md_num . "\" \"" . $data_percent . "\" \"" . $raid_id . "\" " . $ismasterraid . " \"" . $_POST["filesystem"] . "\" ". $assume_option . " > /tmp/post_create.log 2>&1;";
  }

  //================================================================================
  //  Set Default Status
  //================================================================================
  if (NAS_DB_KEY == '1'){
    shell_exec("/bin/mkdir /var/tmp/raid".($md_num-1));
    $strcmd="echo \"Constructing RAID ...\" > /var/tmp/raid".($md_num-1)."/rss";
  }else{
    shell_exec("/bin/mkdir /var/tmp/raid".($md_num));
    $strcmd="echo \"Constructing RAID ...\" > /var/tmp/raid".($md_num)."/rss";
  }
  shell_exec($strcmd);
  if (NAS_DB_KEY == '1'){
    $strcmd="echo \"".$raid_id."\" > /var/tmp/raid".($md_num-1)."/raid_id";
  }else{
    $strcmd="echo \"".$raid_id."\" > /var/tmp/raid".($md_num)."/raid_id";
  }
  shell_exec($strcmd);
  foreach($disk_tray as $num){
    if (NAS_DB_KEY == '1'){
      $strExec="echo -e '$num' >> /var/tmp/raid".($md_num-1)."/disk_tray";
    }else{
      $strExec="echo -e '$num' >> /var/tmp/raid".($md_num)."/disk_tray";
    }
    shell_exec($strExec);
  }
  $dbpath = "/etc/cfg/conf.db";
  $disk_map=$raid->slot_map_dev();
  foreach($tray_id as $v){
    $device=substr($disk_map[$v],0,strlen($disk_map[$v])-1);
    shell_exec("echo \"$device\" >> /tmp/test");
    $Serial=trim(shell_exec('/usr/sbin/smartctl -i /dev/sd'.$device." | grep 'Serial [Nn]umber' | awk '{print $3}'"));
    shell_exec("/usr/bin/sqlite $dbpath \"delete from hot_spare where spare='$Serial'\"");
  }  
  if (NAS_DB_KEY == '1'){
    $strExec1="echo \"".$raid_level."\" > /var/tmp/raid".($md_num-1)."/raid_level";
  }else{
    $strExec1="echo \"".$raid_level."\" > /var/tmp/raid".($md_num)."/raid_level";
  }
  shell_exec($strExec1);
  //=================================================================================
  if (NAS_DB_KEY == '1'){
    $strExec="/img/bin/model/backup_superblock.sh \"BC_\"";
    shell_exec($strExec);
  }
  $cmd="(" . $create_cmd . $strexec . ") >/dev/null 2>&1 &";
  $strout=exec($cmd);
// Don't call post_create and "service start" at same time, 
// because there is "service stop" in post_create which is not finished. 
// "service start" will be called at the end of post_create.
//  if($ismasterraid == 1)
//    shell_exec("/img/bin/service start > /dev/null 2>&1 &");
  unlockRaidWizard();
  return  MessageBox(false,'','','','',"raidWizardFinal()");
}
//########################################################
return  MessageBox(
  true,
  "test",
  $action."=".$lock."=".$md_num."=".$raid_id."=".$ismasterraid."=".$raid_level."=".$zfs_status."=".$fsmode."=".$total_raid_limit
);

//#############################################################
//#  Check RAID ID
//############################################################# 
function check_raidid($raid_id){ 
  global $class,$words,$validate;
  if($raid_id=="" || (!$validate->check_raid_id($raid_id))){
    return  array($words["raid_config_title"],$words["warn_raidid"]);
  }
  $check_raidinfo=$class->getINFO(""); 
  foreach($check_raidinfo["AllRaidName"] as $v){
    if($v!=""){
      if($raid_id==$v){ 
        return  array($words["raid_config_title"],$words["warn_duplicate"]); 
      }
    }
  }
  return false;
}  
//########################################################

function unlockRaidWizard() {
  global $wizard_lock_file;
  unlink($wizard_lock_file);
}
?>
