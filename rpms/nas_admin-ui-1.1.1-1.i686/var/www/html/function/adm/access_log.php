<?php

require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'Vendor/vendor.class.php');
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');
$sysconf = new VendorConfig();
$prefix="access_log";
$words = $session->PageCode("log");
$iwords = $session->PageCode("index");
$sys_access_log = $sysconf->grep("/iscsi_limit/");

$db=new sqlitedb();
$db_key=array(
        "access_log_enabled"=>"0",
        "access_log_folder"=>"NAS_Public",
        "apple_log"=>"0",
        "ftp_log"=>"0",
        "iscsi_log"=>"0",
        "smb_log"=>"0",
        "sshd_log"=>"0");

foreach ($db_key as $k=>$v)
    $db_array[$k]=$db->getvar($k,$v);

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


$tpl->assign('prefix',$prefix);
$tpl->assign('words',$words);
$tpl->assign('iwords',$iwords);
$tpl->assign('access_log_enabled',$db_array['access_log_enabled']);
$tpl->assign('access_log_folder',$db_array['access_log_folder']);
$tpl->assign('apple_log',$db_array['apple_log']);
$tpl->assign('ftp_log',$db_array['ftp_log']);
$tpl->assign('iscsi_log',$db_array['iscsi_log']);
$tpl->assign('smb_log',$db_array['smb_log']);
$tpl->assign('sshd_log',$db_array['sshd_log']);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
$tpl->assign("server_data",json_encode($share));
$tpl->assign("sys_access_log",json_encode($sys_access_log));

?>
