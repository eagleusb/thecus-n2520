<?
/*
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

require_once("../setlang/lang.html");
$words = PageCode("fsck");
//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if($is_function){
  $check_proc_ret=check_process("Formatting,Migrating,Expand");
  check_raid();
}else{
  require_once("/var/www/html/inc/function.php");
  check_system("0","access_warning","about");
}
//#######################################################
//#	Show critical process running
//#######################################################
if($check_proc_ret=="1"){
  require_once("../../inc/msgbox.inc.php");
  $msg=$words["fsck_fail"];
  $url="/adm/getform.html?name=raid";
  $a=new msgBox($msg,"OKOnly",$words["fsck_title"]);
  $a->makeLinks(array($url));
  $a->showMsg();
  exit;
}
//#######################################################
*/
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

$gwords = $session->PageCode("global");
$words = $session->PageCode("fsck");

if($_GET['reboot']!=""){
  if(file_exists("/etc/fsck_flag")){
    $strExec="rm -f /etc/fsck_flag";
    shell_exec($strExec);
  }
  //$strExec="/bin/touch /etc/fsck_flag";
  $strExec="echo \"1\" > /etc/fsck_flag";
  shell_exec($strExec);
  
  if (NAS_DB_KEY == '1'){
    $command = "/img/bin/model/sysdown.sh reboot > /dev/null 2>&1 &";
  }else{
    $command = "/img/bin/sys_reboot > /dev/null 2>&1 &";
  }
  shell_exec($command);
  
  return  ProgressBar(true,$words['fsck_title'],$gwords["reboot"],"ProgressBar",1,intval($sysconf["boot_time"]));
  header('Location: /adm/sdrb.html?action=reboot');
  exit;
}
exit;
?>
