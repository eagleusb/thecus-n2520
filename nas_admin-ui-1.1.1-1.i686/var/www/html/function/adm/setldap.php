<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("ldap"); 
$gwords = $session->PageCode("global");  

$ldap_enabled=$_POST['_enable'];
$ldap_ip=$_POST['_ldap_server_ip'];
$ldap_dmname=$_POST['_domain_name'];
$ldap_id=$_POST['_user_name'];
$ldap_passwd=$_POST['_user_passwd'];
$ldap_user_dn=$_POST['_user_dn'];
$ldap_group_dn=$_POST['_group_dn'];
$ldap_tls=$_POST['_tls'];
 
$db = new sqlitedb(); 
//****************************************
//   	      get old data
//****************************************
$o_ldap_enabled=$db->getvar("ldap_enabled","0");
$o_ldap_ip=$db->getvar("ldap_ip","");
$o_ldap_dmname=$db->getvar("ldap_dmname","");
$o_ldap_id=$db->getvar("ldap_id","");
$o_ldap_passwd=$db->getvar("ldap_passwd","");
$o_ldap_user_dn=$db->getvar("ldap_user_dn","");
$o_ldap_group_dn=$db->getvar("ldap_group_dn","");
$o_ads_enabled=$db->getvar("winad_enable","0");
$o_ldap_tls=$db->getvar("ldap_tls","");

if($ldap_ip=="" && $ldap_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["ip_error"],'Error');  
}
if($ldap_dmname=="" && $ldap_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["domain"],'Error');  
}
if($ldap_id=="" && $ldap_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["id_error"],'Error');  
}
if($ldap_passwd=="" && $ldap_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["passwd_error"],'Error');  
}

if($ldap_user_dn=="" && $ldap_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["user_dn_error"],'Error');  
}

if($ldap_group_dn=="" && $ldap_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["group_dn_error"],'Error');  
}

//*******************************************************
//   	check:  data was not change....alert message
//*******************************************************
if($ldap_enabled==$o_ldap_enabled && $ldap_ip==$o_ldap_ip && $ldap_dmname==$o_ldap_dmname && $ldap_user_dn==$o_ldap_user_dn && $ldap_group_dn==$o_ldap_group_dn && $ldap_id==$o_ldap_id && $ldap_passwd==$o_ldap_passwd && $ldap_tls==$o_ldap_tls){
	return  MessageBox(true,$words['deamon'],$gwords["setting_confirm"],'INFO'); 
} 

//**************************************** 
//   	update db
//**************************************** 
$db->setvar("ldap_enabled",$ldap_enabled);
if($ldap_enabled=="1"){
  $db->setvar("ldap_ip",$ldap_ip);
  $db->setvar("ldap_dmname",$ldap_dmname);
  $db->setvar("ldap_id",$ldap_id);
  $db->setvar("ldap_passwd",$ldap_passwd);
  $db->setvar("ldap_user_dn",$ldap_user_dn);
  $db->setvar("ldap_group_dn",$ldap_group_dn);
  $db->setvar("ldap_tls",$ldap_tls);
}

$ldap_enabled=$db->getvar("ldap_enabled","0");
$ldap_tls=$db->getvar("ldap_tls","");
//**************************************** 
//   	execute shell
//**************************************** 
if($ldap_enabled){
  shell_exec("/usr/bin/sqlite /raid/sys/ad_account.db \"delete from acl\"");
  $result=shell_exec("/img/bin/rc/rc.ldap start");
}else{
  shell_exec("/usr/bin/sqlite /raid/sys/ad_account.db \"delete from acl\"");
  shell_exec("rm -rf /etc/openldap/ldap.conf");
  $result=shell_exec("/img/bin/rc/rc.ldap stop");
}

//**************************************** 
//   	result message
//**************************************** 
$result=trim($result);
if($result=="255"){
  if($ldap_tls!="SSL"){
     $topic=$words["ip_error_msg"];
  }else{
     $topic=$words["ssl_error"];
  }
  shell_exec("/img/bin/logevent/event 997 694 error email &");
  $msg="Error";
}elseif($result=="49"){
  $topic=$words["user_passwd_error"];
  shell_exec("/img/bin/logevent/event 997 694 error email &");
  $msg="Error";
}elseif($result=="34"){
  $topic=$words["DN_error"];
  shell_exec("/img/bin/logevent/event 997 694 error email &");
  $msg="Error";
}elseif($result=="1"){
  $topic=$words["tls_error"];
  shell_exec("/img/bin/logevent/event 997 694 error email &");
  $msg="Error";
}else{
  //$topic= ($ldap_enabled) ? $words["ldap"]." ".$gwords["enable"]." ".$gwords["success"]:$words["ldap"] . " " . $gwords["disable"];
  if($ldap_enabled){
      $topic= $words["ldap"]." ".$gwords["enable"]." ".$gwords["success"];
      $gid_check=shell_exec("/usr/bin/ldapsearch -x -b \"$ldap_dmname\" -z 1000|grep gidNumber|awk '{if ($2<20000) print $2}'");      
      $uid_check=shell_exec("/usr/bin/ldapsearch -x -b \"$ldap_dmname\" -z 1000|grep uidNumber|awk '{if ($2<20000) print $2}'");
      if($gid_check!="" || $uid_check!=""){
        $topic=$words["check_id"];
      }
      shell_exec("/img/bin/logevent/event 997 467 info email &");
      $msg="INFO";
  }else{
      $topic= $words["ldap"] . " " . $gwords["disable"];
      shell_exec("/img/bin/logevent/event 997 468 info email &");
      $msg="INFO";
  } 
}
if($result=="255" || $result=="49" || $result=="34" || $result=="1"){
  $db->setvar("ldap_enabled","0");
  $db->setvar("ldap_ip","");
  $db->setvar("ldap_dmname","");
  $db->setvar("ldap_id","");
  $db->setvar("ldap_passwd","");
  $db->setvar("ldap_user_dn","");
  $db->setvar("ldap_group_dn","");
  $db->setvar("ldap_tls","none");
  shell_exec("/img/bin/rc/rc.ldap stop");
}
unset($db);	
return  MessageBox(true,$words['ldap'],$topic,$msg);
?> 
