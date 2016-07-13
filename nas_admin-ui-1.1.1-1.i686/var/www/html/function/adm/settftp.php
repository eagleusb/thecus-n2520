<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$ch= new validate;
$db=new sqlitedb();

$words = $session->PageCode("tftp");
$gwords = $session->PageCode("global");
$post_key=array('_tftp','_ip','_port','_permission','_overwrite','_folder');
$post_array=array();

$interface_list=$_POST['nics'];
$_POST['_ip']=$interface_list;

$_POST['_permission'] = 0;
if (isset($_POST['_read']))
	$_POST['_permission'] |= TFTP_READ;
if (isset($_POST['_write']))
	$_POST['_permission'] |= TFTP_WRITE;
$_POST['_permission'] = strval($_POST['_permission']);

if (!isset($_POST['_overwrite']))
	$_POST['_overwrite'] = "0";
else
	$_POST['_overwrite'] = "1";


foreach ($post_key as $k) 
	$post_array[]=$_POST[$k];

$db_key=array(
	"tftpd_enabled"=>"0",
	"tftpd_ip"=>"0",
	"tftpd_port"=>"69",
	"tftpd_permission"=>"0",
	"tftpd_overwrite"=>"0",
	"tftpd_folder"=>"");
              
$db_array=array();
foreach ($db_key as $k=>$v) 
	$db_array[]=$db->getvar($k,$v);
	
if (serialize($post_array)==serialize($db_array)){
	unset($db);
	return MessageBox(true,$words['tftp'],$gwords["setting_confirm"], $icon);
}

// write TFTP configuration into database
$idx=0;
foreach ($db_key as $k=>$v){
	$db->setvar($k,$post_array[$idx]);
	$idx++;
}

// run TFTP command
$rc_path="/img/bin/rc/";
$tftp_result = "0";
$tftp_result_msg = "";
$icon = "INFO";
if ($post_array[0] == 1){
	system($rc_path."rc.tftp restart no > /dev/null 2>&1", $tftp_result);
	switch ($tftp_result) {
	case "0":
		$tftp_result_msg = $words["tftp_start_ok"];
		shell_exec("/img/bin/logevent/event 997 440 info email &");
		break;
	case "1":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_start_error"];
		break;
	case "2":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_folder_no_exist"];
		break;
	case "3":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_port_conflict"];
		break;
	case "4":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_folder_no_raid"];
		break;
	case "5":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_port_less"];
		break;
	case "6":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_port_reserved"];
		break;
	default:
		$tftp_result_msg = $tftp_result;
	}
}else if ($post_array[0] == 0){
	system($rc_path."rc.tftp stop no > /dev/null 2>&1", $tftp_result );
	switch ($tftp_result) {
	case "0":
		$tftp_result_msg = $words["tftp_stop_ok"];
		shell_exec("/img/bin/logevent/event 997 441 info email &");
		break;
	case "1":
		$icon = "ERROR";
		$tftp_result_msg = $words["tftp_stop_error"];
		break;
	default:
		$tftp_result_msg = $tftp_result;
	}
}

if($icon == "ERROR")  {
$db->setvar("tftpd_enabled",0);
}

unset($db);
return MessageBox(true,$words['tftp'],$tftp_result_msg, $icon);

