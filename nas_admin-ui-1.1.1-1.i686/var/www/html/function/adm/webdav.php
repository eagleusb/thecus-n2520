<?php

require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$prefix="webdav";
$words = $session->PageCode($prefix);

$db=new sqlitedb();
$webdav_enable=$db->getvar("webdav_enable","1");
$webdav_port=$db->getvar("webdav_port","9800");
$webdav_ssl_enable=$db->getvar("webdav_ssl_enable","1");
$webdav_ssl_port=$db->getvar("webdav_ssl_port","9802");
$webdav_browser_view=$db->getvar("webdav_browser_view","1");
unset($db);

$tpl->assign('words',$words);
$tpl->assign('webdav_enable',$webdav_enable);
$tpl->assign('webdav_port',$webdav_port);
$tpl->assign('webdav_ssl_enable',$webdav_ssl_enable);
$tpl->assign('webdav_ssl_port',$webdav_ssl_port);
$tpl->assign('webdav_browser_view',$webdav_browser_view);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);

?>
