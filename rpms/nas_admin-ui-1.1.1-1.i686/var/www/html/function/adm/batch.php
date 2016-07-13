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
*/
$gwords = $session->PageCode("global");
$words = $session->PageCode("batch");

$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setbatch');
$tpl->assign('form_onload','onLoadForm');
?>
