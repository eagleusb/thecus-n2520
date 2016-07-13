<?php
include_once(INCLUDE_ROOT.'info/meminfo.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

$words = $session->PageCode("notif");
$gwords = $session->PageCode("global");
$prefix=notif;

$auth_fields="['value','display']";
$auth_data="[['on','On'],['plain','PLAIN'],['cram-md5','CRAM-MD5'],['login','LOGIN'],['gmail','Gmail'],['off','Off']]";

$ssl_fields="['value','display']";
$ssl_data="[['off','Off'],['ssl','SSL'],['tls','StartTLS']]";

$level_fields="['value','display']";
$level_data="[['all','{$gwords["all"]}'],['warning','{$gwords["warning_error"]}'],['error','{$gwords["error"]}']]";

$db=new sqlitedb();
$beep=$db->getvar("notif_beep","0");
$warn_led=$db->getvar("notif_led","1");
$mail=$db->getvar("notif_mail","0");
$smtp=$db->getvar("notif_smtp","");
$smtport=$db->getvar("notif_smtport","");
$auth=$db->getvar("notif_auth","off");
$account=$db->getvar("notif_account","");
$password=$db->getvar("notif_password","");
$level=$db->getvar("notif_level","all");
$sender=$db->getvar("notif_from","");
$domain=$db->getvar("notif_domain","");
$ssl=$db->getvar("notif_ssl","off");
$addr1=$db->getvar("notif_addr1","");
$addr2=$db->getvar("notif_addr2","");
$addr3=$db->getvar("notif_addr3","");
$addr4=$db->getvar("notif_addr4","");

//get E-mail information 
if($_POST['ac']=='mailinfo'){
	$ary = array(	'smtp'=>$smtp,
			'smtport'=>$smtport,
			'auth'=>$auth,
			'account'=>$account,
			'password'=>$password,
			'level'=>$level,
			'sender'=>$sender,
			'domain'=>$domain,
			'ssl'=>$ssl,
			'addr1'=>$addr1,
			'addr2'=>$addr2,
			'addr3'=>$addr3,
			'addr4'=>$addr4	);
	die(json_encode($ary));
}

//When E-mail set "Disabled", the other information would display blank.
if($mail=='0'){
	$smtp=$smtport=$auth=$account=$password=$level=$sender=$domain=$ssl=$addr1=$addr2=$addr3=$addr4='';
}

$tpl->assign('words',$words);
$tpl->assign($prefix.'_beep',$beep);
$tpl->assign($prefix.'_mail',$mail);
$tpl->assign($prefix.'_smtp',$smtp);
$tpl->assign($prefix.'_smtport',$smtport);
$tpl->assign($prefix.'_auth',$auth);
$tpl->assign($prefix.'_auth_fields',$auth_fields);
$tpl->assign($prefix.'_auth_data',$auth_data);
$tpl->assign($prefix.'_account',$account);
$tpl->assign($prefix.'_password',$password);
$tpl->assign($prefix.'_level',$level);
$tpl->assign($prefix.'_level_fields',$level_fields);
$tpl->assign($prefix.'_level_data',$level_data);
$tpl->assign($prefix.'_sender',$sender);
$tpl->assign($prefix.'_domain',$domain);
$tpl->assign($prefix.'_ssl',$ssl);
$tpl->assign($prefix.'_ssl_fields',$ssl_fields);
$tpl->assign($prefix.'_ssl_data',$ssl_data);
$tpl->assign($prefix.'_addr1',$addr1);
$tpl->assign($prefix.'_addr2',$addr2);
$tpl->assign($prefix.'_addr3',$addr3);
$tpl->assign($prefix.'_addr4',$addr4);
$tpl->assign('buzzer',$sysconf["buzzer"]);

/*
$led = "0";
$oled = "/var/tmp/oled/STATUS_LED";
if(file_exists($oled)){
	$value = trim(file_get_contents($oled));
	if($value=="OK"){
		$led = "1";
	}
}
$tpl->assign('led',$led);
*/
$tpl->assign('led',$sysconf["warning_led"]);
$tpl->assign('warn_led',$warn_led);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
