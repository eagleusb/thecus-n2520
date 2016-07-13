<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$db=new sqlitedb();
$LOGO1_enabled=$db->getvar("LOGO1_LED","1");
unset($db);

if($LOGO1_enabled=='' || $LOGO1_enabled==0)
  $LOGO1_enabled=1;
else
  $LOGO1_enabled=0;
$words = $session->PageCode("led_control");
$tpl->assign('words',$words);
$tpl->assign('LOGO1_enabled',$LOGO1_enabled);
$tpl->assign('form_action','setmain.php?fun=setled_control');
?>
