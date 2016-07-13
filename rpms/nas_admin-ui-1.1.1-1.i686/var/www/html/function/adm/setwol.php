<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("wakeUP");
$gwords = $session->PageCode("global");
$wol_enabled=$_POST['_wol_enabled'];
$db=new sqlitedb();

if (NAS_DB_KEY==1)
{
    $o_wol_enabled=$db->getvar("wol_enabled","0");

    if($wol_enabled == $o_wol_enabled){
        unset($db);
        return MessageBox(true,$words['wol'],$gwords['setting_confirm']);
    }else{
        $db->setvar("wol_enabled",$wol_enabled);
        $db->setvar("wol_wan",$wol_wan);
        $db->setvar("wol_lan",$wol_lan);
  
        unset($db);
        $msg .= ($wol_enabled) ? $words["wol_enable_success"]:$words["wol_disable_success"];

        return MessageBox(true,$words['wol'],$msg);
    }
}
else
{
    $wol_wan=$_POST['_wan_wol_enabled'];
    $wol_lan=$_POST['_lan_wol_enabled'];
    $o_wol_wan=$db->getvar("wol_wan","0");
    $o_wol_lan=$db->getvar("wol_lan","0");

    if(($wol_wan == $o_wol_wan) && ($wol_lan == $o_wol_lan)){
        unset($db);
        return MessageBox(true,$words['wol'],$gwords['setting_confirm']);
    }else{
        $db->setvar("wol_enabled",$wol_enabled);
        $db->setvar("wol_wan",$wol_wan);
        $db->setvar("wol_lan",$wol_lan);
  
        unset($db);
        return MessageBox(true,$words['wol'],$words["wol_set_success"]);
    }
}
?>
