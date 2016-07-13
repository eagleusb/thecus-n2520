<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("upnp");
$gwords = $session->PageCode("global");

$upnp=$_POST['_upnp'];
$upnp_desp=$_POST['_desp'];
$db=new sqlitedb();

$o_upnp=$db->getvar("httpd_nic1_upnp","0");

if (NAS_DB_KEY==1)
    $o_upnp_desp=$db->getvar("allset_desp","");
else
    $o_upnp_desp=$db->getvar("httpd_upnp_desp","");


if(($upnp==$o_upnp)&&($upnp_desp==$o_upnp_desp)){
    unset($db);
    return MessageBox(true,$words["upnp"],$gwords["setting_confirm"]);
}else{
    $db->setvar("httpd_nic1_upnp",$upnp);

    if (NAS_DB_KEY==1)
        $db->setvar("allset_desp",$upnp_desp);
    else
        $db->setvar("httpd_upnp_desp",$upnp_desp);
    
    unset($db);

    $rc_path="/img/bin/rc/";
    if ($upnp == 1){
        shell_exec($rc_path."rc.upnpd restart > /dev/null 2>&1");
        return MessageBox(true,$words['upnp'],$words["upnp_enable"]);
    }else if ($upnp == 0){
        shell_exec($rc_path."rc.upnpd stop > /dev/null 2>&1");
        return MessageBox(true,$words['upnp'],$words["upnp_disable"]);
    }
}
