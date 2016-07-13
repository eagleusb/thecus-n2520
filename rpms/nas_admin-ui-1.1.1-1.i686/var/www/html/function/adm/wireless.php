<?
//require_once("../../inc/security_check.php");
//check_admin($_SESSION);

require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("wireless");

$wireless=array();

$db_tool=new sqlitedb();
$wireless["enabled"]=trim($db_tool->getvar("wireless_enable","0"));
$wireless["ip"]=trim($db_tool->getvar("wireless_ip",""));
$wireless["netmask"]=trim($db_tool->getvar("wireless_netmask",""));
$wireless["essid"]=trim($db_tool->getvar("wireless_essid",""));
$wireless["essid_broadcast"]=trim($db_tool->getvar("wireless_essid_broadcast","0"));
$wireless["channel"]=trim($db_tool->getvar("wireless_channel","11"));
$wireless["authmode"]=trim($db_tool->getvar("wireless_authmode","0"));
$wireless["wep_enabled"]=trim($db_tool->getvar("wireless_wep_enabled","0"));
$wireless["wep_key_length"]=trim($db_tool->getvar("wireless_wep_key_length","1"));
$wireless["length"]=trim($db_tool->getvar("wireless_length","10"));
$wireless["wep_index"]=trim($db_tool->getvar("wireless_wep_index","0"));
$wireless["wepkey1"]=trim($db_tool->getvar("wireless_wepkey1",""));
$wireless["wepkey2"]=trim($db_tool->getvar("wireless_wepkey2",""));
$wireless["wepkey3"]=trim($db_tool->getvar("wireless_wepkey3",""));
$wireless["wepkey4"]=trim($db_tool->getvar("wireless_wepkey4",""));
$wireless["dhcp"]=trim($db_tool->getvar("wireless_dhcp","0"));
$wireless["startip"]=trim($db_tool->getvar("wireless_startip","0"));
$wireless["endip"]=trim($db_tool->getvar("wireless_endip","0"));

/*
$wireless_enabled=trim($db_tool->getvar("wireless_enable","0"));
$wireless_ip=trim($db_tool->getvar("wireless_ip",""));
$wireless_netmask=trim($db_tool->getvar("wireless_netmask",""));
$wireless_essid=trim($db_tool->getvar("wireless_essid",""));
$wireless_essid_broadcast=trim($db_tool->getvar("wireless_essid_broadcast","0"));
$wireless_channel=trim($db_tool->getvar("wireless_channel","11"));
$wireless_authmode=trim($db_tool->getvar("wireless_authmode","0"));
$wireless_wep_enabled=trim($db_tool->getvar("wireless_wep_enabled","0"));
$wireless_wep_key_length=trim($db_tool->getvar("wireless_wep_key_length","1"));
$wireless_length=trim($db_tool->getvar("wireless_length","10"));
$wireless_wep_index=trim($db_tool->getvar("wireless_wep_index","0"));
$wireless_wepkey1=trim($db_tool->getvar("wireless_wepkey1",""));
$wireless_wepkey2=trim($db_tool->getvar("wireless_wepkey2",""));
$wireless_wepkey3=trim($db_tool->getvar("wireless_wepkey3",""));
$wireless_wepkey4=trim($db_tool->getvar("wireless_wepkey4",""));
$wireless_dhcp=trim($db_tool->getvar("wireless_dhcp","0"));
$wireless_startip=trim($db_tool->getvar("wireless_startip","0"));
$wireless_endip=trim($db_tool->getvar("wireless_endip","0"));
*/

$dns=trim($db_tool->getvar("nic1_dns",""));
/*
$dns=str_replace("\r\n","\t",$dns);
$dns=str_replace("\n","\t",$dns);
$dns=str_replace("\r","\t",$dns);
$dns=str_replace("\t"," ",$dns);
$dns=str_replace("\t","\n",$dns);
*/
$dns=explode("\n",$dns);

$strExec="ifconfig wlan0 | grep HWaddr | awk '{print \$5}'";
$wireless["mac"]=str_replace("\n","",shell_exec($strExec));

$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setwireless');
$tpl->assign('form_onload','onLoadForm');

$tpl->assign('wireless',$wireless);
$tpl->assign('dns1',$dns[0]);
$tpl->assign('dns2',$dns[1]);
$tpl->assign('dns3',$dns[2]);

?>
