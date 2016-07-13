<?php
require_once("smbconf.class.php");
require_once("../../function/conf/localconfig.php");

class GetNIC {

	//==========================================
	//	Below are vars pass by POST
	//==========================================
	var $ethtool="/sbin/ethtool";
	//var $ethtool="/etc/ethtool";

	//==========================================
	//	Below are vars defining system file path
	//==========================================
    	var $ifconfig="/sbin/ifconfig";
	var $route="/sbin/route";

	//==========================================
	//	Below define NIC
	//==========================================
	var $nic;
	var $cmd=array("sleep 5");

	//==========================================
	//	Constructor
	//==========================================
	function __construct($interface) {
		$this->nic=$interface;
    	if (NAS_DB_KEY=='2')
            $this->ethtool="/sbin/ethtool";
		return;
	}

	function GetStatus(){
		$strExec=$this->ethtool." ".$this->nic." | awk '/Link detected:/{printf $3}'";
		$result=shell_exec($strExec);
		return $result;
	}

	function GetSpeed(){
		$strExec=$this->ethtool." ".$this->nic." | awk '/Speed:/{printf $2}'";
		$result=shell_exec($strExec);
		return $result;
        }

}

?>
