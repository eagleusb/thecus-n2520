<?php
require_once('../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'inittemplate.php');  
require_once(INCLUDE_ROOT.'session.php'); 
require_once(INCLUDE_ROOT.'function.php'); 
require_once(INCLUDE_ROOT.'publicfun.php'); 
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(WEBCONFIG); 
if(check_fsck_flag()){
	die("<script>location.href='adm/index.php';</script>");
}
$gwords = $session->PageCode("global"); 
$tpl->assign('gwords',$gwords);  
$tpl->assign('login_php','adm/login.php');   
$tpl->assign('index_php','adm/index.php');   
if(isset($_SERVER['HTTP_REFERER'])){
	$u_lang=explode("eplang=",$_SERVER["HTTP_REFERER"]);
	$u_lang=$u_lang[1];
}
if($u_lang==""){
	if($_COOKIE["cookie_lang"]!=""){
		$u_lang=$_COOKIE["cookie_lang"];
	}else{
		define( '_EXT_PATH', dirname(__FILE__) );
		define( '_VALID_MOS', 1 );
		define( '_VALID_EXT', 1 );
		require_once('usr/eXtplorer/application.php');
		$u_lang =  ext_Lang::detect_lang();
	}
}
$tpl->assign('u_lang',$u_lang);
// Check if any login session existed
if ($session->logged_in && $session->admin_auth) {
        die("<script>location.href='adm/index.php';</script>");
//	header('Location: adm/index.php');
	exit;
}
$raidexist = check_raid_exist();
$smbservice = check_samba_service();
//$photo_module = "off";
//$webdisk_module = "off";
//$photo_login = "1"; // 0: unnecessary to authenticate, 1: necessary to authenticate
//$webdisk_login = "1"; // the same rule as the $photo_login

if($raidexist!="0" && file_exists(MODULE_ROOT . "cfg/module.db") ){
	// get module list which status is enabled and is allowed to show in login page
	$db = new sqlitedb(MODULE_ROOT . "cfg/module.db");
	$sql = "SELECT module.name, module.enable, module.icon, module.homepage, module.ui, mod.object FROM module INNER JOIN mod ON module.name=mod.module WHERE mod.predicate='Name' AND module.enable='Yes'";
	$db->runPrepare($sql);
	$modules=array();
	while ($mod_info = $db->runNext()){
		list($mod_name,$mod_enable,$mod_icon,$mod_homepage,$mod_ui,$mod_display_name) = $mod_info;
	
		// check if module is showed in login page
		$sql = "SELECT object AS show FROM mod WHERE predicate='Show' AND module='".$mod_name."'";
		$ret = $db->runSQLAry($sql);
		if ($ret[0]["show"] == "" || $ret[0]["show"] == "0") {
			continue;
		}
		
		// check if module needs to be authorized
		$sql = "SELECT object AS login FROM mod WHERE predicate='Login' AND module='".$mod_name."'";
		$ret = $db->runSQLAry($sql);
		if ($ret[0]["login"] == "") {
			$module["login"] = "0";
		} else {
			$module["login"]=$ret[0]["login"];
		}
		
		// N2520/4520 only allow Piczza and WebDisk(new one)
		if ($mod_name === "Piczza" || $mod_name === "WebDisk") {
			continue;
		}
	
		$module["name"]=$mod_name;
		$module["enable"]=$mod_enable;
		$module["homepage"]=$mod_homepage;
		$module["ui"]=$mod_ui;
		$module["displayname"]=$mod_display_name;
	
		if ( $mod_icon != "" && ( file_exists("/raid/data/module/".$mod_name."/www/".$mod_icon) || file_exists("/opt/".$mod_name."/www/".$mod_icon) ) ) {
			$module["icon"]="/modules/".$mod_name."/www/".$mod_icon;
		} else {
			$module["icon"]=URL_ROOT_IMG."login/module_default.png";
		}
		
		$modules[] = $module;
	}
}

$ha = trim(file_get_contents('/tmp/ha_role'));
$login_tab = ($webconfig['login_width']/2)-174;
$tab=array();

foreach($webconfig['logintab'] as $key=>$value){
	if($value=='1'){
		$webconfig[$key]['name']=$gwords[$webconfig[$key]['gwords']];
		if($webconfig[$key]['name']==''){
			$webconfig[$key]['name']='Admin';
		}
		
		if($ha == 'standby' && $key!='admin')
			continue;
		
		// N2520/4520 only allow Piczza and WebDisk(new one)
		if ($key == "photoserver" || $key == "webdisk") {
			continue;
		}
	
		$webconfig[$key]["iconpath"] = URL_ROOT_IMG."login/icon_".$webconfig[$key]["id"].".png";
		$webconfig[$key]["iconpath_over"] = URL_ROOT_IMG."login/icon_".$webconfig[$key]["id"]."_over.png";
		
		$tab[]=$webconfig[$key];
	}
}

/**
 * We have a new static class ModuleLogin which can list all modules can login via admin ui.
 * If possible, make new role for all modules to do login.
 */
require_once(INCLUDE_ROOT.'modulelogin.class.php');
$login_modules = ModuleLogin::getModuleStatus();
// Delete additional module icon
$tmp_module=0;
for ($i = 0 ; $i < count($login_modules) ; ++$i) {
    if($login_modules[$i]["module"] == "Module"){
        $tmp_module = $i;
        break;
    }
}
unset($login_modules[$tmp_module]);

for ($i = 0 ; $i < count($login_modules) ; ++$i) {
	$pkg = &$login_modules[$i];
	if ($pkg["status"]) {
		$pkg_name = $pkg["module"];
		$pkg_alias = $pkg_name;
		
		switch ($pkg_name) {
		case "WebDisk":
			$webdisk_module = "on";
			$webdisk_login = "1";
			$pkg_alias = "webdisk";
			$webconfig[$pkg_alias]["successurl"] = $webconfig[$pkg_alias]["successurl_2"];
			$webconfig[$pkg_alias]["url"] = "adm/login.php";
			$webconfig[$pkg_alias]["iconpath_over"] = "/modules/$pkg_name/www/over_basic.png";
			$webconfig[$pkg_alias]["iconpath"] = "/modules/$pkg_name/www/basic.png";
			break;
		case "Piczza":
			$photo_module = "on";
			$photo_login = "1";
			$pkg_alias = "photoserver";
			$webconfig[$pkg_alias]["successurl"] = $webconfig[$pkg_alias]["successurl_2"];
			$webconfig[$pkg_alias]["url"] = "adm/login.php";
			$webconfig[$pkg_alias]["iconpath_over"] = "/modules/$pkg_name/www/over_logo.png";
			$webconfig[$pkg_alias]["iconpath"] = "/modules/$pkg_name/www/logo.png";
			break;
		default:
		}
		
		$tab []= $webconfig[$pkg_alias];
	}
}

get_sysconf();
if($sysconf["new_module_install"]=="1"){
	$db_conf = new sqlitedb();
	if($photo_module=="off"){
		$db_conf->setvar("photoserver","0"); 
	}
	if($webdisk_module=="off"){
		$db_conf->setvar("webdisk","0"); 
	}
	unset($db_conf);
}


$strExec = "cat /proc/cmdline | awk '/domb/{print \$0}'";
$dombstart = shell_exec($strExec);
$strExec = "/img/bin/rc/rc.ddom_backup check_bdom";
$only_domb = trim(shell_exec($strExec));


//check multiple login:
$client_ip = $_SERVER['REMOTE_ADDR'];
$current_ip = trim(shell_exec("cat /tmp/admin 2>/dev/null"));
if($client_ip!=$current_ip && $current_ip!='') {
	$multi_logon='1';
} else {
	$multi_logon='0';
}

//Logo Link
$logoLink=getLogoLink();



$tpl->assign('webpage_title',$webconfig['hostname']);
$tpl->assign('logo_link',$logoLink);
$tpl->assign('multi_logon',$multi_logon);
$tpl->assign('tab',$tab);
$tpl->assign('modules',$modules);
$tpl->assign('webdisk_login',$webdisk_login);
$tpl->assign('photo_login',$photo_login);
$tpl->assign('raidexist',$raidexist);
$tpl->assign('dombstart',$dombstart);
$tpl->assign('only_domb',$only_domb);
$tpl->assign('smbservice',$smbservice);
$tpl->assign('login_width',$webconfig['login_width']);
$tpl->assign('login_height',$webconfig['login_height']);
$tpl->assign('login_tab',$login_tab);

$tpl->display('adm/login.tpl'); 
?>
