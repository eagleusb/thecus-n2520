<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("ldap"); 
$gwords = $session->PageCode("global");

//$ldap_enabled=$_POST['_enable'];
$db = new sqlitedb();
$ldap_enabled=$db->getvar("ldap_enabled","0");
unset($db);
$ldap_ip=$_POST['_ldap_server_ip'];
$ldap_dmname=$_POST['_domain_name'];
$ldap_id=$_POST['_user_name'];
$ldap_passwd=$_POST['_user_passwd'];

if($ldap_enabled=="1"){
  if($ldap_ip!="" && $ldap_dmname!="" && $ldap_id!="" && $ldap_passwd!=""){
      $check_result=shell_exec("/usr/bin/ldapsearch -x -b \"$ldap_dmname\" -z 1000|grep sambaSamAccount|awk 'NR==1{print \$2}'");
      $check_result2=shell_exec("/usr/bin/ldapsearch -x -b \"$ldap_dmname\" -z 1000|grep posixAccount|awk 'NR==1{print \$2}'");
	    if($check_result=="" && $check_result2==""){
          return  MessageBox(true,$gwords['error'],$words["check_obj"],'Error');
      }elseif($check_result=="" && $check_result2!=""){
          return  MessageBox(true,$gwords['error'],$words["check_samba"],'Error');
      }elseif($check_result!="" && $check_result2==""){
          return  MessageBox(true,$gwords['error'],$words["check_posix"],'Error');
      }else{
          return  MessageBox(true,$words['deamon'],$words["check_OK"],'Info');
      }
  }else{
      return  MessageBox(true,$gwords['error'],$words["check_error"],'Error');
  }
}else{
      return  MessageBox(true,$words['deamon'],$words["enable_ldap"],'Info');
}
?>
