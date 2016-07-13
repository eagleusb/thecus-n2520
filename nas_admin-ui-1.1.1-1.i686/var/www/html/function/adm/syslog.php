<?php 
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("syslog");
$gwords = $session->PageCode("global");

$level_fields="['value','display']";
$level_data="[['all','{$gwords["all"]}'],['warning','{$gwords["warning_error"]}'],['error','{$gwords["error"]}']]";

$db = new sqlitedb(); 
$syslogd_enabled=$db->getvar("syslogd_enabled","0");  
$syslogd_target=$db->getvar("syslogd_target","0");
$syslogd_level=$db->getvar("syslogd_level","all");
$syslogd_ip=$db->getvar("syslogd_ip","0");
$syslogd_server=$db->getvar("syslogd_server","0");
$syslogd_folder=$db->getvar("syslogd_folder","");

unset($db);

//#################################################
//#	Load public share folder
//#################################################
$raid_class=new RAIDINFO();
$md_array=$raid_class->getMdArray(); 
$share = array();
foreach($md_array as $num){
	$raid_data_result = "0";
	if (NAS_DB_KEY == '1'){          
		$database="/raid".($num-1)."/sys/raid.db";
		$strExec="/bin/mount | grep '/raid".($num-1)."/data'";
		$raid_data_result=shell_exec($strExec);
	}else{
		$database="/raid".($num)."/sys/smb.db"; 
		$strExec="/bin/mount | grep '/raid".$num."'";
		$raid_data_result=shell_exec($strExec);
	}
	if($raid_data_result==""){
		continue;
	}

	$db = new sqlitedb($database,'conf'); 
//	$raid_id=$db->getvar("raid_name");
	$ismaster=$db->getvar("raid_master");
	$file_system=$db->getvar("filesystem");
	if(!$file_system)
		$file_system='ext3';
	if (NAS_DB_KEY == '1'){
		$db_list=$db->db_getall("folder");
	}else{
		if ($ismaster=="1"){
		  $db_lista=$db->db_getall("smb_specfd");
		}else{
		  $db_lista="";
		}
		
		$db_listb=$db->db_getall("smb_userfd");
		if (($db_lista=="") && ($db_listb != 0)){
			$db_list=$db_listb;
		}else if (($db_lista!="") && ($db_listb != 0)){
			$db_list=array_merge($db_lista,$db_listb);
		}else{
			$db_list=$db_lista;
		}
	}  

	foreach($db_list as $k=>$list){
		if($list==""){
			continue;
		}
		$share[]=array("folder_name"=>$list["share"]);
		
	}
	unset($db);
}
$tpl->assign('syslogd_enabled',$syslogd_enabled);
$tpl->assign('syslogd_target',$syslogd_target);
$tpl->assign('syslogd_level',$syslogd_level);
$tpl->assign('_level_fields',$level_fields);
$tpl->assign('_level_data',$level_data);
$tpl->assign('syslogd_server',$syslogd_server);
$tpl->assign("server_data",json_encode($share));
$tpl->assign("log_folder",$syslogd_folder);
$tpl->assign('syslogd_ip',$syslogd_ip);
$tpl->assign('words',$words);
$tpl->assign('set_url','setmain.php?fun=setsyslog');  
?>
