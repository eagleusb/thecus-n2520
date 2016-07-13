<?php
require_once("smbconf.class.php");
//==========================================
//
//	create a new instance:
//	(string) $nic
//	(array) $_POST
//	$n=new SetNIC($nic,$_POST);
//	$n->Batch();//do set
//
//	Prefix:
//	_cmd_:execute shell command
//	_rc_:edit /etc/cfg/rc config file
//	_conf_:edit config file except rc
//
//==========================================
class SetWLAN {

	//==========================================
	//	Below are vars pass by POST
	//==========================================
	var $ip;
	var $netmask;
	var $wepkey1;
	var $wepkey2;
	var $wepkey3;
	var $wepkey4;
	var $startip;
	var $endip;
	var $wlan;
	var $cmd=array("sleep 5");
	function canChange() {
	}
	function Batch() {
	}

	//==========================================
	//	Constructor
	//==========================================
	
	//==========================================
	//	Final batch execution
	//==========================================
	
	//==========================================
	//	This func picks out the $_POST we need
	//==========================================
	
	//==========================================
	//	This func write config value back
	//==========================================
	
	//==========================================
	//	This func will set nic down on boot
	//==========================================
	
	//==========================================
	//	End of class
	//==========================================

}

?>
