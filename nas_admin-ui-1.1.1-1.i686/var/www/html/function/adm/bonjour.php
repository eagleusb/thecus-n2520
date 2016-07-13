<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$db=new sqlitedb();
$bonjour_enabled=$db->getvar("bonjour_enable","1");
unset($db);

if($bonjour_enabled=='' || $bonjour_enabled==0)
  $bonjour_enabled=1;
else
  $bonjour_enabled=0;
$words = $session->PageCode("bonjour");
$tpl->assign('words',$words);
$tpl->assign('bonjour_enabled',$bonjour_enabled);
$tpl->assign('form_action','setmain.php?fun=setbonjour');
?>
