<?
/*
require_once("../../inc/security_check.php");
check_admin($_SESSION);
*/
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'setwlan.class.php');
//require_once(INCLUDE_ROOT.'conf.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("wireless");

//##########################################################################
//#	Check item
//##########################################################################
if($_POST["_dhcp"]=="1"){
	if($_POST["_startip"]=="" || !$validate->ip_address($_POST["_startip"])){
		return  MessageBox(true,$words["wireless_title"],$words["startip_error"],ERROR);
	}
	if($_POST["_endip"]=="" || !$validate->ip_address($_POST["_endip"])){
		return  MessageBox(true,$words["wireless_title"],$words["endip_error"],ERROR);
	}
	if(!check_range(trim($_POST["_ip"]),trim($_POST["_netmask"]),trim($_POST["_startip"]),trim($_POST["_endip"]))){
		return  MessageBox(true,$words['wireless_title'],$words["range_error"]);
	}
}
if($_POST["_ip"]=="" || !$validate->ip_address($_POST["_ip"])){
	return  MessageBox(true,$words["wireless_title"],$gwords["ip_error"],ERROR);
}
if($_POST["_netmask"]=="" || !$validate->ip_address($_POST["_netmask"])){
	return  MessageBox(true,$words["wireless_title"],$gwords["netmask_error"],ERROR);
}
$db_tool = new sqlitedb();
$wanip=$db_tool->getvar("nic1_ip","");
$lanip=$db_tool->getvar("nic2_ip","");
unset($db);
if(trim($_POST["_ip"])==trim($wanip) || trim($_POST["_ip"])==trim($lanip)){
	return  MessageBox(true,$words["wireless_title"],$words["same_ip_error"],ERROR);
}
if($_POST["_wep_enabled"]=="1" && $_POST["_authmode"]=="2"){
	$wep_index=trim($_POST["_wep_index"]);
	if((!iswepkey($_POST["_wepkey1"]) && $wep_index=="0") || (!iswepkey($_POST["_wepkey2"]) && $wep_index=="1") ||
	   (!iswepkey($_POST["_wepkey3"]) && $wep_index=="2") || (!iswepkey($_POST["_wepkey4"]) && $wep_index=="3")){
		return  MessageBox(true,$words["wireless_title"],$words["wepkeyerror"],ERROR);
	}
}
$strExec="ifconfig wlan0";
$interface_list=shell_exec($strExec);
preg_match("/addr:([^\s]+)/",$interface_list,$matches);
preg_match("/Mask:([^\s]+)/",$interface_list,$netmatches);
$current_ip=trim($matches[1]);
$current_netmask=trim($netmatches[1]);
$new_ip=trim($_POST["_ip"]);
$new_netmask=trim($_POST["_netmask"]);
if($current_ip!=$new_ip || $current_netmask!=$new_netmask){
	$change_ip="1";
}else{
	$change_ip="0";
}

//##########################################################################

$_POST['interface']='0';

$WLAN=new SetWLAN($_POST['prefix'],$_POST);
$result=($_POST['_dhcp']) ? 0:$WLAN->canChange();
$prefix=trim($_POST["prefix"]);
$formname=$prefix;
//$msg = array("type"=>"OKOnly");

if(!$result){
	$db_tool=new sqlitedb();
	$db_tool->setvar("wireless_ip",trim($_POST["_ip"]));
	$db_tool->setvar("wireless_netmask",trim($_POST["_netmask"]));
	$db_tool->setvar("wireless_essid",trim($_POST["_essid"]));
	$db_tool->setvar("wireless_essid_broadcast",trim($_POST["_essid_broadcast"]));
	$db_tool->setvar("wireless_channel",trim($_POST["_channel"]));
	$db_tool->setvar("wireless_wep_enabled",trim($_POST["_wep_enabled"]));
	$db_tool->setvar("wireless_authmode",trim($_POST["_authmode"]));
	$db_tool->setvar("wireless_wep_key_length",trim($_POST["_wep_key_length"]));
	$db_tool->setvar("wireless_wep_index",trim($_POST["_wep_index"]));
	$db_tool->setvar("wireless_wepkey1",trim($_POST["_wepkey1"]));
	$db_tool->setvar("wireless_wepkey2",trim($_POST["_wepkey2"]));
	$db_tool->setvar("wireless_wepkey3",trim($_POST["_wepkey3"]));
	$db_tool->setvar("wireless_wepkey4",trim($_POST["_wepkey4"]));
	$db_tool->setvar("wireless_dhcp",trim($_POST["_dhcp"]));
	if(trim($_POST["_dhcp"])=="0"){
		$db_tool->setvar("wireless_startip",trim($_POST["_startip"]));
		$db_tool->setvar("wireless_endip",trim($_POST["_endip"]));
	}
	unset($db_tool);
	if(!$change_ip){
		$url = isset($_SERVER['HTTPS']) ? "https://" : "http://";
		//$url .= $_SERVER['SERVER_ADDR'] . ":" . $_SERVER['SERVER_PORT'];
		//$url .= "/adm/getform.html?name=wireless";
		//$msg['links'] = array($url);
	}else{
		//$url = isset($_SERVER['HTTPS']) ? "https://" : "http://";
		//$url .= $_SERVER['SERVER_ADDR'] . ":" . $_SERVER['SERVER_PORT'];
		//$url .= "/adm/getform.html?name=sdrb";
		//$msg['links'] = array($url);
		shell_exec("/img/bin/wlanchg.sh");
	}
}else{
	$errmsg=$words["internalError"];
	if($WLAN->theSameIPError){
		if($WLAN->internalError){
			$errmsg=$words["internalError"];
		}
		$errmsg=$words["ipExist"];
	}
	return  MessageBox(true,$words['wireless_title'],$errmsg,'ERROR');
}
$ary = array('ok'=>'redirect_reboot()');
if((!$_POST["_dhcp"]) && !$change_ip){
	return  MessageBox(true,$words['wireless_title'],$words["staticSuccess"]."<br>".$words["noInterrupt"],'INFO','OK',$ary);
}elseif(($_POST["_dhcp"]) && !$change_ip){
	$db_tool=new sqlitedb();
	$db_tool->setvar("httpd_nic1_upnp","1");
	unset($db_tool);
	return  MessageBox(true,$words['wireless_title'],$words["dhcpSuccess"],'INFO','OK',$ary);
}else{
	return  MessageBox(true,$words['wireless_title'],$words["ipSuccess"],'INFO','OK',$ary);
}

function iswepkey($key){
	global $_POST;
	if(trim($_POST["_wep_key_length"])=="1"){
		$len="10";
	}else{
		$len="26";
	}
	if(strlen($key)!=$len){
		return false;
	}
	for($c=0;$c<strlen($key);$c++){
		$tmp=substr($key,$c,1);
		if(($tmp<=chr(47) || $tmp>=chr(58)) && ($tmp<=chr(64) || $tmp>=chr(71)) && ($tmp<=chr(96) || $tmp>=chr(103))){
			return false;
		}
	}
	return true;
}

function check_range($ip,$netmask,$startip,$endip){
	if($startip==$endip){
		return false;
	}
	$mask_item=explode(".",$netmask);
	$ip_item=explode(".",$ip);
	for($c=0;$c<count($mask_item);$c++){
		if(intval($mask_item[$c])!=255){
			$subnet=$c;
			break;
		}
	}
	$range=intval($mask_item[$subnet]) ^ 255;
	$startip_item=explode(".",$startip);
	$endip_item=explode(".",$endip);
	
	for($c=0;$c<$subnet;$c++){
		if(intval($startip_item[$c])!=intval($ip_item[$c]) || intval($endip_item[$c])!=intval($ip_item[$c])){
			//return "RANGE ERROR";
			return false;
		}
	}
	for($c=$subnet;$c<4;$c++){
		$sip_item=intval($startip_item[$c]);
		$eip_item=intval($endip_item[$c]);
		if($sip_item==$eip_item){
			$subnet++;
			$range=255;
		}
		if(($sip_item > $eip_item) || ($sip_item > $range) || ($eip_item > $range)){
			//return "ERROR RANGE".$sip_item." == ".$eip_item." == ".$range;
			return false;
		}
		
	}
	return true;
}
?>
