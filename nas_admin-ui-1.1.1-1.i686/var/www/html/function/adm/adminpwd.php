<?php
require_once(INCLUDE_ROOT.'function.php');
$words = $session->PageCode("adminpwd");
get_sysconf();

$tpl->assign('words',$words);
$tpl->assign('lcd_passwd_have',$sysconf["atmega168"]|$sysconf["pic24"]);
$tpl->assign('form_action','setmain.php?fun=setadminpwd');
?>
