<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$words = $session->PageCode("online");
$gwords = $session->PageCode("global");

$action=trim($_POST["action"]);


if($action=="setoption"){
	$enabled=trim($_POST["_enabled"]);
	$send_hdd_info=trim($_POST["_send_hdd_info"]);
	$send_timezone_info=trim($_POST["_send_timezone_info"]);
	$database="/etc/cfg/conf.db";
	$db=new sqlitedb($database,"conf");
	set_conf($db,"online_enabled",$enabled);
	set_conf($db,"online_send_hdd_info",$send_hdd_info);
	set_conf($db,"online_send_timezone_info",$send_timezone_info);
	
	if($enabled=="1"){
		$strExec="/img/bin/online_register.sh";
		shell_exec($strExec);
	}
	/*
	if($send_hdd_info!=""){
		$db->setvar("online_send_hdd_info",$send_hdd_info);
	}
	*/
	
	die(
		json_encode(
			array(
				'online_enabled'=>$enabled,
				'online_send_hdd_info'=>$send_hdd_info,
				'online_send_timezone_info'=>$send_timezone_info
			)
		)
	);
	
}

$syspath="/raid/sys";
$database=${syspath}."/online_register.db";

$postdate=trim($_GET["postdate"]);

$db=new sqlitedb($database,"online_register");

$strSQL="select online1 from online_register where online9='${postdate}'";
$res=$db->runSQL($strSQL);
if($res!="1"){
	$strSQL="update online_register set online1='1' where online9='${postdate}'";
	$db->runSQL($strSQL);
}


function set_conf($db_tool,$key,$value){
	$old_value=$db_tool->getvar($key,"0");
	if($value==""){
		$value="0";
	}
	if($old_value!=$value){
		$db_tool->setvar($key,$value);
	}
}

?>
