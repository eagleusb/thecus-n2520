<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("syslog"); 
$gwords = $session->PageCode("global");  

$syslogd_enabled=$_POST['_syslogd_enabled'];
$syslogd_target=$_POST['_syslogd_target'];
$syslogd_level=$_POST['_level_selected'];
$syslogd_ip=$_POST['_syslogd_ip'];
$syslogd_folder=$_POST['_folder_selected'];
$syslogd_server=$_POST['_syslogd_server'];
 
$db = new sqlitedb(); 
//****************************************
//   	      get old data
//****************************************
$o_syslogd_enabled=$db->getvar("syslogd_enabled","0");
$o_syslogd_target=$db->getvar("syslogd_target","0");
$o_syslogd_level=$db->getvar("syslogd_level","all");
$o_syslogd_ip=$db->getvar("syslogd_ip","");
$o_syslogd_folder=$db->getvar("syslogd_folder","");
$o_syslogd_server=$db->getvar("syslogd_server","0");

$sys_path=shell_exec("/bin/ls -l /raid/sys | awk -F' ' '{printf $11}'");
$data_path=shell_exec("/bin/ls -l /raid/data | awk -F' ' '{printf $11}'");
if (!($syslogd_target=="1" && $syslogd_server=="0") && $syslogd_enabled=="1"){
  if($sys_path=="" && $data_path==""){
        return  MessageBox(true,$gwords['warning'],$gwords["raid_exist_warning"],'Warning');
  }
}

if($syslogd_folder=="" && $syslogd_server=="1" && $syslogd_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["folder_error"],'Error');  
}
if($syslogd_folder=="" && $syslogd_server=="0" && $syslogd_target=="0" && $syslogd_enabled=="1"){
	return  MessageBox(true,$gwords['error'],$words["folder_error"],'Error');  
}
//*******************************************************
//   	check:  data was not change....alert message
//*******************************************************
if($syslogd_enabled==$o_syslogd_enabled && $syslogd_target==$o_syslogd_target && $syslogd_level==$o_syslogd_level && $syslogd_ip==$o_syslogd_ip && $o_syslogd_folder==$syslogd_folder && $syslogd_server==$o_syslogd_server){
	return  MessageBox(true,$words['deamon'],$gwords["setting_confirm"],'INFO'); 
} 

//**************************************** 
//   	check: ip 
//**************************************** 
$validate= new validate();
if(!$validate->ip_address($syslogd_ip) && !$validate->ipv6_address($syslogd_ip) && $syslogd_target == "1"){
	return  MessageBox(true,$gwords['error'],$gwords["ip_error"],'Error');
}


//**************************************** 
//   	update db
//**************************************** 
$db->setvar("syslogd_enabled",$syslogd_enabled);
if($syslogd_enabled=="1"){
  $db->setvar("syslogd_target",$syslogd_target);
  $db->setvar("syslogd_level",$syslogd_level);
  $db->setvar("syslogd_server",$syslogd_server);
  $db->setvar("syslogd_folder",$syslogd_folder);

  if($syslogd_target=="1"){
    $db->setvar("syslogd_ip",$syslogd_ip);
    $db->setvar("syslogd_folder","");
  }
}else{
  $db->setvar("syslogd_folder","");
}
unset($db);
	

//**************************************** 
//   	execute shell
//**************************************** 
$result=shell_exec("/img/bin/rc/rc.syslogd restart");


//**************************************** 
//   	result message
//**************************************** 
$result=trim($result); 
if($result=="1"){
  $topic=$gwords["error"]." ".$words["raid_error"];
}else{
  $topic= ($syslogd_enabled) ? $words["deamon"]." ".$gwords["enable"]." ".$gwords["success"]:$words["deamon"] . " " . $gwords["disable"]; 
}  

return  MessageBox(true,$words['deamon'],$topic,'INFO');
?> 
