<?
/*
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if($is_function){
	check_raid();
	$samba_enabled=check_samba();
	check_system($samba_enabled,"samba_warning","httpd");
}else{
	require_once("/var/www/html/inc/function.php");
	check_system("0","access_warning","about");
}
//#######################################################
*/
$gwords = $session->PageCode("global");
$words = $session->PageCode("ads");

require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$db_tool=new sqlitedb();
$enabled=addslashes(trim($db_tool->getvar("winad_enable","0")));
$domain=addslashes(trim($db_tool->getvar("winad_domain","")));
$admin_id=addslashes(trim($db_tool->getvar("winad_admid","")));
$admin_pwd=addslashes(trim($db_tool->getvar("winad_admpwd","")));
$pwd_confirm=addslashes(trim($db_tool->getvar("winad_admpwd_confirm","")));
$ip=addslashes(trim($db_tool->getvar("winad_ip","")));
$realm=addslashes(trim($db_tool->getvar("winad_realm","")));
$hybrid=addslashes(trim($db_tool->getvar("winad_hybrid","")));
$wins=addslashes(trim($db_tool->getvar("winad_wins","")));
$wins=str_replace(" ","\n",$wins);
$auth_type=addslashes(trim($db_tool->getvar("winad_AuthType","ads")));
unset($db_tool);

//disable the NT suppoert in N0503, don't display NT
if (NAS_DB_KEY == '2')
{
    $words["realm"] = str_replace("/NT", "", $words["realm"]);
    $words["WindowsADSAccounts"] = str_replace("/NT", "", $words["WindowsADSAccounts"]);
    $words["ads_title"] = str_replace("/NT", "", $words["ads_title"]);
    $words["server_name"] = str_replace("/NT", "", $words["server_name"]);
}

//######################################################
//#	Html template part
//######################################################
$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setads');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('enabled',$enabled);
$tpl->assign('enable_checked',$enable_checked);
$tpl->assign('disable_checked',$disable_checked);
$tpl->assign('domain',$domain);
$tpl->assign('admin_id',$admin_id);
$tpl->assign('admin_pwd',$admin_pwd);
$tpl->assign('pwd_confirm',$pwd_confirm);
$tpl->assign('ip',$ip);
$tpl->assign('realm',$realm);
$tpl->assign('hybrid',$hybrid);
$tpl->assign('wins',$wins);
$tpl->assign('auth_type',$auth_type);
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY);

?>
