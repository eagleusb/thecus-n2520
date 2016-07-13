<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$prefix=hsdpa;

$db=new sqlitedb();
$hsdpa_dial=$db->getvar("hsdpa_dial","*99#");
$hsdpa_apn=$db->getvar("hsdpa_apn","internet");

unset($db);

$words = $session->PageCode($prefix);

$tpl->assign('words',$words);
$tpl->assign($prefix.'_dial',$hsdpa_dial);
$tpl->assign($prefix.'_apn',$hsdpa_apn);

$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
