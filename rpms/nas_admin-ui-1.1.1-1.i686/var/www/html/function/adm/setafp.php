<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
$words = $session->PageCode("afp");
$gwords = $session->PageCode("global");

$afp=$_POST['_afp'];
$afp_charset=$_POST['_charset_selected'];
$afp_zone=$_POST['_zone'];
$afp_tm=$_POST['_afptm'];
$tm_folder=$_POST['_folder_selected'];

$db=new sqlitedb();

if (NAS_DB_KEY == '1'){
	$o_afp=$db->getvar("httpd_nic1_afpd","0");
	$o_afp_charset=$db->getvar("httpd_charset","UTF8-MAC");
	$o_afp_zone=$db->getvar("httpd_nic1_afpd_zone","*");
	$o_afp_tm=$db->getvar("httpd_nic1_tm","0");
}else{
	$o_afp=$db->getvar("apple_talkd","0");
	$o_afp_charset=$db->getvar("apple_charset","UTF8-MAC");
	$o_afp_zone=$db->getvar("apple_zone","*");
	$o_afp_tm=$db->getvar("apple_tm","0");
	$o_afp_tm_folder=$db->getvar("apple_tm_folder","");
}

if(($tm_folder=="")&&($afp_tm=="1")){
    unset($db);
    return MessageBox(true,$gwords["afp"],$words["folder_empty"],'ERROR');
}

if(($afp==$o_afp)&& ($afp_charset==$o_afp_charset)&&($afp_zone==$o_afp_zone)&&($afp_tm==$o_afp_tm)&&($apple_tm_folder==$o_afp_tm_folder)){
  unset($db);
  return MessageBox(true,$words['afp'],$gwords["setting_confirm"]);
}else{
  if (NAS_DB_KEY == '1'){
    $db->setvar("httpd_nic1_afpd",$afp);
    $db->setvar("httpd_charset",$afp_charset);
    $db->setvar("httpd_nic1_afpd_zone",$afp_zone);
    if($afp==1)
    	$db->setvar("httpd_nic1_tm",$afp_tm);
    else 
    	$db->setvar("httpd_nic1_tm","0");
  }else{
    $db->setvar("apple_talkd",$afp);
    $db->setvar("apple_charset",$afp_charset);
    $db->setvar("apple_zone",$afp_zone);
    if($afp==1){
      $db->setvar("apple_tm",$afp_tm);
      $db->setvar("apple_tm_folder",$tm_folder);
    }else{
      $db->setvar("apple_tm","0");
      $db->setvar("apple_tm_folder","");
    }	
  }
  unset($db);  
  $rc_path="/img/bin/rc/";
  if ($afp == 1){
    shell_exec($rc_path."rc.atalk restart > /dev/null 2>&1 &");
    shell_exec($rc_path."rc.bonjour boot > /dev/null 2>&1 &");
    shell_exec("/img/bin/logevent/event 133 &");    
	return MessageBox(true,$words['afp'],$words["afp_enable"]);
  }else if ($afp == 0){
    shell_exec($rc_path.'rc.atalk stop > /dev/null 2>&1 &');
    shell_exec($rc_path."rc.bonjour boot > /dev/null 2>&1 &");
    shell_exec("/img/bin/logevent/event 134 &");    
	return MessageBox(true,$words['afp'],$words["afp_disable"]);
  }
}
