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
//require_once(DOC_ROOT.'utility/transferDB.class.php');
//$trans=new transDB();
//$trans->trans_bat("fsck","fsck");
//exit;
$gwords = $session->PageCode("global");
$words = $session->PageCode("fsck");

$fs_zfs=trim(shell_exec("/img/bin/check_service.sh \"fs_zfs\""));
$encrypt_raid=trim(shell_exec("/img/bin/check_service.sh \"encrypt_raid\""));

$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setfsck');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('fs_zfs',$fs_zfs);
$tpl->assign('encrypt_raid',$encrypt_raid);
$yes_msg=sprintf($words["press_yes"],"<font color=red>".$gwords["yes"]."</font>");
$no_msg=sprintf($words["press_no"],"<font color=red>".$gwords["no"]."</font>");
$apply_msg=sprintf($words["press_yes"],"<font color=red>".$gwords["apply"]."</font>");
$confirm_msg=$words["ApplySuccess"]."<br><br>".$yes_msg."<br>".$no_msg."<br>";
$tpl->assign('confirm_msg',$confirm_msg);
$tpl->assign('apply_msg',$apply_msg);
?>
