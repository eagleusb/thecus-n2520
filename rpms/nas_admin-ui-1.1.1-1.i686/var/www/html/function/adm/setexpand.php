<?
/*
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if($is_function){
  check_raid();
}else{
  require_once("/var/www/html/inc/function.php");
  check_system("0","access_warning","about");
}
//#######################################################
*/

require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'taskrunner.class.php');
require_once(INCLUDE_ROOT.'raid.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("raid");

get_sysconf();

$md_num=trim($_POST["md_num"]);
$capacity=trim(str_replace("GB","",trim($_POST["expand_capacity"])));
$lock=check_status_flag();
$raid_lock=check_raid_status($md_num); 
if($raid_lock=="1"){
   return  MessageBox(true,$words['raid_config_title'],$gwords["raid_nohealthy"],WARNING);
}
if($lock=="1"){
   return  MessageBox(true,$words['raid_config_title'],$gwords["raid_lock_warning"],WARNING);
}
//####################################################
//#  Check total capacity limitation
//####################################################
$raid=new RAIDINFO();
$raid->setmdselect(0);
$miniexpandsize=1;
$raid_info=$raid->getINFO($md_num);
$raid_file_system=$raid_info["RaidFS"];
$raid_date_size=$raid_info["RaidData_partition"];
$capacity_total=$raid_date_size + $capacity;
//####################################################
$raid_check=new raid();
$limitation=$raid_check->check_limitation($raid_file_system,$capacity_total);
if($limitation == 1){
  return  MessageBox(true,$words["raid_config_title"],$words["ext3_8t_size_limit"],ERROR);
}elseif($limitation == 2){
  return  MessageBox(true,$words["raid_config_title"],$words["ext4_16t_size_limit"],ERROR);
}

if (NAS_DB_KEY == '1'){
if($capacity <= $miniexpandsize){
  return  MessageBox(true,$words['raid_config_title'],$words["expand_fail"]);
}

$strExec="/img/bin/resize_raid.sh ".$md_num." ".$capacity." >/dev/null 2>&1 &";
}else{
  $strExec="/img/bin/jbod_resize.sh ".$md_num." >/dev/null 2>&1 &";
}
shell_exec($strExec);
$ary = array('ok'=>'gotoRaidInfo()');
return  MessageBox(true,$words['raid_config_title'],$words["expand_start"],INFO,OK,$ary);

die(
  json_encode(
    array(
      $_POST,
      $capacity
    )
  )
);
?>
