<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');                                                                                                                                       
get_sysconf();

$db=new sqlitedb();

$wol_enabled = 0;
$wol_wan = 0;
$wol_lan = 0;

if (NAS_DB_KEY==1)
{
    $wol_enabled=$db->getvar("wol_enabled","0");

    if($wol_enabled=='' || $wol_enabled==0)
        $wol_enabled=1;
    else
        $wol_enabled=0;
}
else
{
    $wol_wan=$db->getvar("wol_wan","0");
    $wol_lan=$db->getvar("wol_lan","0");

    if($wol_wan=='' || $wol_wan==0)
        $wol_wan=1;
    else
        $wol_wan=0;

    if($wol_lan=='' || $wol_lan==0)
        $wol_lan=1;
    else
        $wol_lan=0;
}

unset($db);

$words = $session->PageCode("wakeUP");
$tpl->assign('words',$words);
$tpl->assign('wol_enabled',$wol_enabled);
$tpl->assign('wol_wan',$wol_wan);
$tpl->assign('wol_lan',$wol_lan);
$tpl->assign('wan_lan',NAS_DB_KEY);
$tpl->assign('form_action','setmain.php?fun=setwol');
$tpl->assign('lang',$session->lang);
$tpl->assign('wkonlan',$sysconf['wkonlan']);
?>
