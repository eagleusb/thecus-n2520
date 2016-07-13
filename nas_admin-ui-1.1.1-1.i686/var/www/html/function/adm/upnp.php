<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(WEBCONFIG);
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$prefix=upnp;

$db=new sqlitedb();
$upnp_enabled=$db->getvar("httpd_nic1_upnp","0");

if (NAS_DB_KEY==1)
    $upnp_desp=$db->getvar("allset_desp",$webconfig['product_no']." IP Storage Server");
else
    $upnp_desp=$db->getvar("httpd_upnp_desp",$webconfig['product_no']." IP Storage Server");

unset($db);

$words = $session->PageCode($prefix);
$tpl->assign('words',$words);
$tpl->assign('upnp_enabled',$upnp_enabled);
$tpl->assign('upnp_desp',$upnp_desp);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
