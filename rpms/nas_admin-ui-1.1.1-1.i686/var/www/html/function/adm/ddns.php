<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$prefix=ddns;

$db=new sqlitedb();
$ddns=$db->getvar("ddns_ddns","0");
$reg=$db->getvar("ddns_reg","dyndns@dyndns.org");
$uname=$db->getvar("ddns_uname","");
$password=$db->getvar("ddns_password","");
$domain=$db->getvar("ddns_domain","");
$db->db_close();

$words = $session->PageCode($prefix);

$reg_fields="['value','display']";

$reg_value=array("dyndns@dyndns.org",
		"custom@dyndns.org",
		"statdns@dyndns.org",
		"default@zoneedit.com",
		"default@no-ip.com");

$reg_data="[";
foreach ($reg_value as $item){
	$reg_data.="['".$item."','".$words[$item]."'],";
}
$reg_data = rtrim($reg_data,",");
$reg_data.="]";

$tpl->assign('words',$words);
$tpl->assign($prefix.'_ddns',$ddns);
$tpl->assign($prefix.'_reg',$reg);
$tpl->assign($prefix.'_reg_fields',$reg_fields);
$tpl->assign($prefix.'_reg_data',$reg_data);
$tpl->assign($prefix.'_uname',$uname);
$tpl->assign($prefix.'_password',$password);
$tpl->assign($prefix.'_domain',$domain);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
