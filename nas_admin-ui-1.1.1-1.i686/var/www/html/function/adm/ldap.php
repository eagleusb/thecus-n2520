<?
$gwords = $session->PageCode("global");
$words = $session->PageCode("ldap");

require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$db=new sqlitedb();
$enabled=$db->getvar("ldap_enabled","0");
$ldap_domain=$db->getvar("ldap_dmname","");
$ldap_id=$db->getvar("ldap_id","");
$ldap_pwd=$db->getvar("ldap_passwd","");
$ldap_user_dn=$db->getvar("ldap_user_dn","");
$ldap_group_dn=$db->getvar("ldap_group_dn","");
$ip=$db->getvar("ldap_ip","");
$ldap_tls=$db->getvar("ldap_tls","none");
unset($db);

$tls_fields="['display', 'value']";
$tls_data = "[['none', 'none'],";
$tls_data .= "['TLS','TLS'],";
$tls_data .= "['SSL','SSL']]";

$samba_sid=trim(shell_exec("/img/bin/rc/rc.ldap get_sambasid"));

//######################################################
//#	Html template part
//######################################################
$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setldap');
$tpl->assign('form_action2','setmain.php?fun=check_ldap');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('enabled',$enabled);
$tpl->assign('domain_name',$ldap_domain);
$tpl->assign('user_name',$ldap_id);
$tpl->assign('user_passwd',$ldap_pwd);
$tpl->assign('user_dn',$ldap_user_dn);
$tpl->assign('group_dn',$ldap_group_dn);
$tpl->assign('ldap_server_ip',$ip);
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY);
$tpl->assign('tls_data',$tls_data);
$tpl->assign('tls_fields',$tls_fields);
$tpl->assign('tls_value',$ldap_tls);
$tpl->assign('samba_sid',$samba_sid);
?>
