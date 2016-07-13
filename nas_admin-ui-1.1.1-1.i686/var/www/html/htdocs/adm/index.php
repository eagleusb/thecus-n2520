<?php 
require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'inittemplate.php');  
require_once(INCLUDE_ROOT.'session.php'); 
require_once(INCLUDE_ROOT.'publicfun.php'); 
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'nasstatus.class.php');
require_once(WEBCONFIG);

$db=new sqlitedb();
$disclaimer_enabled=$db->getvar("disclaimer_enabled","0");
$modupgrade_enabled = $db->getvar("modupgrade_enabled", "1"); 
$run_init = $db->getvar("run_init", "0");
$role_tmp = $db->getvar('ha_role');
$role_tmp = ($role_tmp=='0')?'active':'standby';
if ($run_init == "0") {
	// If there is any raid created, set run_init=1
	if (check_raid_exist() == 1) {
		$db->setvar("run_init", "1");
		$run_init = "1";
	}
}
unset($db);

$combo_fields="['value','display']"; 
$combo_lang = " [['en','English'], 
                ['ja','日本語'], 
                ['tw','正體中文'], 
                ['zh','簡体中文'], 
                ['fr','Français'], 
                ['de','Deutsch'], 
                ['it','Italiano'], 
                ['ko','Korean'], 
                ['es','Spanish'], 
                ['tr','Turkish'],
                ['ru','Russia'],
                ['pl','Polish'],
                ['pt','Portugal'],
                ['cz','Czech']]";
  
$randValue = rand(9999).time();
$gwords = $session->PageCode("global"); 
$vtypes = json_encode($session->PageCode("vtypes"));
$uxs = json_encode($session->PageCode("ux"));
$rwords = $session->PageCode("raid"); 
$dwords = $session->PageCode("disk");
$owords = $session->PageCode("online");   
$sdwords = $session->PageCode("sdrb"); 
$notif_words = $session->PageCode("notif");
$user_words = $session->PageCode("localuser");
$init_words = $session->PageCode("init");
$mwords = $session->PageCode("modupgrade");

/******************************************************
             init TreeMenu
*******************************************************/
$currentpage = initWebVar('currentpage');
$currentgroup='';
if($currentpage=='')
   $currentpage = 'shortcut'; 

require_once(WEBCONFIG);  
require_once(INCLUDE_ROOT.'treemenu.class.php');  
$tree = new Treemenu(); 
$treeview = $tree->getTreeMenuList(); 
$treelog =$tree->SearchByFun("log"); 
$treenews =$tree->SearchByFun("online"); 
$treereboot =$tree->SearchByFun("reboot");
$treeadmpwd =$tree->SearchByFun("adminpwd");
$treeshutdown= $treereboot;
$treereboot[0]["fun"] = $treereboot[0]["fun"]."&ac=reboot";
$treeshutdown[0]["fun"] = $treeshutdown[0]["fun"]."&ac=shutdown";
$treeraid =$tree->SearchByFun("raid"); 
$treedisks =$tree->SearchByFun("disks"); 

$fan = getStatus(openfile('fan')); 				//check fan
$ups = check_ups();           					//check_ups
$temp = getStatus(openfile('temperature'));  	//check_temperature

if($ups!="none"){
	$treeups =$tree->SearchByFun("ups");   
}
if($fan!="none"){
	$treesystatus =$tree->SearchByFun("systatus"); 
}
$logoLink=getLogoLink();

$tpl->assign('logo_link',$logoLink); 
$tpl->assign('show_ups',$ups); 
$tpl->assign('show_fan',$fan); 
$tpl->assign('show_temp',$temp);   
if (file_exists("/var/tmp/yum.upgrade.list")) {
    $tpl->assign('upgrade_list', file_get_contents("/var/tmp/yum.upgrade.list"));
} else {
    $tpl->assign('upgrade_list', json_encode(array()));
}
$tpl->assign('treelog',json_encode($treelog));
$tpl->assign('treenews',json_encode($treenews));
$tpl->assign('treeraid',json_encode($treeraid));
$tpl->assign('treedisks',json_encode($treedisks));
$tpl->assign('treesystatus',json_encode($treesystatus));
$tpl->assign('treeups',json_encode($treeups));
$tpl->assign('treereboot',json_encode($treereboot));
$tpl->assign('treeadmpwd',json_encode($treeadmpwd));
$tpl->assign('treeshutdown',json_encode($treeshutdown)); 

$tpl->assign('currentgroup',$currentgroup);
$tpl->assign('treeview_count',count($treeview));
$tpl->assign('treeview',$treeview);
$tpl->assign('treeview_obj',json_encode($treeview));
$tpl->assign('currentpage',$currentpage);
$tpl->assign('var_js','var currentpage="'.$currentpage.'";');
$tpl->assign('max_tray',$thecus_io["MAX_TRAY"]);



$words = $session->PageCode('index');

//Read System Version
$fwVersion=getFWVersion();
$aryManifest=getManifest();
$fwType=$aryManifest["FWTYPE"];
$fwProducer=$aryManifest["FWPRODUCER"];

//Permission to block page 
$entryflag=($session->loginid=='admin')?1:0;
if($entryflag==1){
	if($disclaimer_enabled=="0" && $fwProducer=="THECUS" && $_SESSION["disclaimer_flag"]!="1"){
		$entryflag="2";
		//print_r($_SESSION);	
	}
} 

// for raid wizard
get_sysconf();
//check webconfig for module upgrade window
if($sysconf["new_module_window"]=="0"){
	// disable window
	$modupgrade_enabled = "0";
}
$_SESSION["new_module_install"] = $sysconf["new_module_install"];
$_SESSION["modupgrade_enabled"] = $modupgrade_enabled;
$open_encrypt=trim(shell_exec("/img/bin/check_service.sh encrypt_raid"));
	
$strExec = "cat /etc/manifest.txt|awk '/producer/{print \$2}'";
$manifest = trim(shell_exec($strExec));
$disclaimer_content = sprintf($gwords["disclaimer_content"],$manifest,$manifest,$manifest,$manifest);
$online_disclaimer = sprintf($owords["online_disclaimer"],$manifest);

$rurl=$_SESSION['currenturl'];       
$tpl->assign('entryflag',$entryflag);
$tpl->assign('rurl',$rurl);

$tpl->assign('FW_VERSION',$fwVersion);	
$tpl->assign('FWTYPE',$fwType);	
$tpl->assign('FWPRODUCER',$fwProducer);	


$tpl->assign('words',$words);  
$tpl->assign('gwords',$gwords);  
$tpl->assign('rwords',$rwords);  
$tpl->assign('dwords',$dwords);
$tpl->assign('owords',$owords);  
$tpl->assign('uxs', $uxs);
$tpl->assign('vtypes',$vtypes);
$tpl->assign('sdwords',$sdwords);  
$tpl->assign('mwords',$mwords);
$tpl->assign('role_tmp',$role_tmp);
$tpl->assign('combo_lang',$combo_lang);  
$tpl->assign('combo_fields',$combo_fields);  
$tpl->assign('lang',$session->lang);  
$tpl->assign('webpage_title',$webconfig['hostname']);
$tpl->assign('randValue',$randValue);   
$tpl->assign('logout_php','logout.php');   
$tpl->assign('login_php','login.php');   
$tpl->assign('index_php','index.php');   
$tpl->assign('getmain_php','getmain.php');   
$tpl->assign('head_height',$webconfig['head_height']);   
$tpl->assign('footer_height',$webconfig['footer_height']);   
$tpl->assign('menu_width',$webconfig['menu_width']);   
$tpl->assign('menu_maxwidth',$webconfig['menu_maxwidth']);   
$tpl->assign('menu_minwidth',$webconfig['menu_minwidth']);   
$tpl->assign('language_position',$webconfig['language_position']);
$tpl->assign('disclaimer_enabled',$disclaimer_enabled);
$tpl->assign('disclaimer_content',$disclaimer_content);
$tpl->assign('online_disclaimer',$online_disclaimer);
$tpl->assign('disclaimer_url','setmain.php?fun=setdisclaimer');
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY); 
$tpl->assign('notif_words',$notif_words);
$tpl->assign('user_words',$user_words);
$tpl->assign('init_words',$init_words);
$tpl->assign('run_init',$run_init);
$tpl->assign('open_encrypt',$open_encrypt);
$tpl->assign('MBTYPE',$thecus_io["MBTYPE"]);
$tpl->assign('sysconf',$sysconf);

/**
* get webconfig by ODM
*/
$ui_item = getWebConfigODM($webconfig,$gwords);
$tpl->assign('ui_item',$ui_item);

if(check_fsck_flag()){ 
        $tpl->display('adm/fsck_index.tpl');
}else if(!$session->logged_in){
        die("<script>location.href='../index.php';</script>");
}else{
	switch($entryflag) {
	case "1":
		$tpl->display('adm/index.tpl'); 
		break;
	case "2":
		$tpl->display('adm/disclaimer.tpl');
		break;
	default:
		$tpl->display('adm/permission_warning.tpl');
	}
}


?>
