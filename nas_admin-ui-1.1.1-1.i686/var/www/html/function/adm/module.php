<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'module.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(FUNCTION_CONF_ROOT.'webconfig');


$words = $session->PageCode("module");
$module_db_path= MODULE_ROOT . "cfg/module.db";

get_sysconf();

$action=($_POST["action"]!="")?trim($_POST["action"]):trim($_GET["action"]);

if($action=='changeshow'){
	$db = new sqlitedb($module_db_path, 'mod');
	$name=$_REQUEST['mod_name'];
	if($_REQUEST['newval']=="true"){
		$val=1;
	}else{
		$val=0;
	}
	$str=sprintf("select * from mod where module='%s' and predicate='Show'",$name);
	$show_info=$db->runSQLAry($str);
	if(count($show_info)==0){
	  $str=sprintf("insert into mod values('%s','1','Show',%s)",$name,$val);
	}else{
		$str=sprintf("update mod set object='%s' where module='%s' and predicate='Show'",$val,$name);
	}
	$db->exec($str);
	unset($db);
	die(
		json_encode(
				array(
					'moduleData'=>readNewModule($module_db_path)
				)
			)
		);	
}
elseif ($action == "status") {
	$module=new Module($words,'');
	$status_data = $module->check_status($_POST,$_GET);
	unset($module);
	if ($status_data['mod_lock_flag'] == "") {
		die(
			json_encode(
				array(
					'mod_status'=>$status_data['mod_status'],
					'mod_lock_flag'=>$status_data['mod_lock_flag'],
					'moduleData'=>readNewModule($module_db_path)
				)
			)
		);
	} else {
		die(
			json_encode(
				array(
					'mod_status'=>$status_data['mod_status'],
					'mod_lock_flag'=>$status_data['mod_lock_flag']
				)
			)
		);
	}
}

$moduleData = readNewModule($module_db_path);
$module=new Module($words,'');
$lock_type = $module->get_lock_type();
unset($module);

$tpl->assign('module_login',$webconfig['logintab']['module']);
$tpl->assign('lock_type', $lock_type);
$tpl->assign('rdf_version', $sysconf["rdf_version"]);
$tpl->assign('words',$words);
$tpl->assign('moduleData',$moduleData);
$tpl->assign('form_action','setmain.php?fun=setmodule');
$tpl->assign('lang',$session->lang);

function readNewModule($db_path) {
	$db = new sqlitedb($db_path);
	$mod_rs = "select module.name, module.version, module.description, module.enable, module.mode, module.ui, module.homepage , mod.object from module inner join mod on module.name=mod.module where mod.predicate='Name' and module.mode!='RPM'";
	$db->runPrepare($mod_rs);

	$i = 0;
	$moduleData="";
	
	require_once(WEBCONFIG);
	if ($webconfig['manufactur'] == 'THECUS') $webconfig['manufactur']='Thecus';
	
	while ($mod_info = $db->runNext()){
		list($mod_name,$mod_version,$mod_description,$mod_enable,$mod_mode,$mod_ui,$mod_homepage, $display_mod_name) = $mod_info;
		$sql = "select object as rdf_version from mod where predicate='ModuleRDFVer' and module='".$mod_name."'";
		$res = $db->runSQLAry($sql);
		$sql = "select object as show from mod where predicate='Show' and module='".$mod_name."'";
		$show_info = $db->runSQLAry($sql);
		$sql = "select object as publish from mod where predicate='Publish' and module='".$mod_name."'";
		$publish_info=$db->runSQLAry($sql);

		if($res){
			$rdf_version=$res[0]['rdf_version'];
		} else {
			$rdf_version="1.0.0";
		}

		if($show_info){
			$show=$show_info[0]['show'];
		} else {
			$show="0";
		}

		if($publish_info){
			$publish=$publish_info[0]['publish'];
		} else {
			$publish="0";
		}

		$moduleData .= $i . chr(27) . $mod_name . chr(27) . $display_mod_name . chr(27) . $mod_version . chr(27) . $mod_description. chr(27) . $mod_enable . chr(27).$mod_mode.chr(27).$mod_ui.chr(27).$mod_homepage.chr(27).$rdf_version.chr(27).$show.chr(27).$publish.chr(27);
		$i = $i + 1;
	}
	if ($i > 0) {
		$moduleData = substr($moduleData, 0, strlen($moduleData)-1);
	}
	
	unset($db);

	return $moduleData;
}

?>
