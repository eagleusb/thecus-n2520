<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$prefix=afp;
$rc_path="/img/bin/rc/";

$db=new sqlitedb();
//NAS DEPEND
if (NAS_DB_KEY == '1'){
    $enabled=$db->getvar("httpd_nic1_afpd","0");
    $charset=$db->getvar("httpd_charset","UTF8-MAC");
    $zone=$db->getvar("httpd_nic1_afpd_zone","*");
    $tmenabled=$db->getvar("httpd_nic1_tm","0");
}else{
    $enabled=$db->getvar("apple_talkd","0");
    $charset=$db->getvar("apple_charset","UTF8-MAC");
    $zone=$db->getvar("apple_zone","*");
    $tmenabled=$db->getvar("apple_tm","0");
    $folder_tm=$db->getvar("apple_tm_folder","");
    $check_folder=trim(shell_exec($rc_path."rc.atalk check \"$folder_tm\""));
    if($check_folder=="0"){
       $db->setvar("apple_tm_folder","");
    }
}
unset($db);

$words = $session->PageCode($prefix);

$charset_fields="['value','display']";

$charset_value=array("MAC_CENTRALEUROPE",
		"MAC_CHINESE_TRAD",
		"MAC_CHINESE_SIMP",
		"MAC_CYRILLIC",
		"MAC_ROMAN",
		"MAC_GREEK",
		"MAC_HEBREW",
		"MAC_JAPANESE",
		"MAC_KOREAN",
		"MAC_TURKISH",
		"UTF8-MAC");

$charset_data="[";
foreach ($charset_value as $item){
	$charset_data.="['".$item."','".$words[$item]."'],";
}
$charset_data = rtrim($charset_data,",");
$charset_data.="]";

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



$tpl->assign('words',$words);
$tpl->assign($prefix.'_enabled',$enabled);
$tpl->assign($prefix.'_charset',$charset);
$tpl->assign($prefix.'_charset_fields',$charset_fields);
$tpl->assign($prefix.'_charset_data',$charset_data);
$tpl->assign($prefix.'_zone',$zone);
$tpl->assign("tm_folder",$folder_tm);
$tpl->assign("Time_Machine_folder",json_encode($share));
$tpl->assign($prefix.'_tmenabled',$tmenabled);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
