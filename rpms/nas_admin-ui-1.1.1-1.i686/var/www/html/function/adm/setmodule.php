<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'module.class.php');
$words = $session->PageCode("module");
$gwords = $session->PageCode("global");
$module_db_path= MODULE_ROOT.'cfg/module.db';
$mod_rs = "select * from module";

$module=new Module($words,$gwords);
$prefix = $_REQUEST['prefix'];
if($prefix=='getlock'){
	$lock_exist=$module->lock_exist();
	if ( $lock_exist == "0"){
		echo '{result:"fail"}';
	}else{
		$lock_type = $_REQUEST['lock_type'];
		$module->create_lock($lock_type);
		echo '{result:"ok"}';
	}
	unset($module);
	exit;
} elseif ($prefix == 'check_lock') {
	$lock_exist=$module->lock_exist();
	if ( $lock_exist == "0"){
		echo '{lock:"yes"}';
	}else{
		echo '{lock:"no"}';
	}
	unset($module);
	exit;
} elseif($prefix == 'install'){
	$module->create_lock(2);
	$module_service=$sysconf["plugin_module"];
	if($module_service == "0"){
		$module->set_msg($words['no_module_service']);
		$module->del_lock();
		unset($module);
		exit;
	}else{
		if (!file_exists($module_db_path)){
			include_once(INCLUDE_ROOT.'function.php');
			$raid_exist=check_raid_exist();
			if ($raid_exist=="1"){
				$db = new SQLiteDatabase($module_db_path);
				$db->queryExec("create table mod (module text, gid numeric, predicate text, object text)");
				$db->queryExec("create table module (name text, version text, description text, enable text, updateurl text, icon text, mode text, homepage text, ui text)");
				shell_exec("/img/bin/logevent/event 997 664 error email");
			}else{
				$module->set_msg($gwords['raid_exist_warning']);
				$module->del_lock();
				unset($module);
				exit;
			}
		}
	}	
	$module->set_msg($words['module_install_start'],false);
	$mod_folder=$module->upload_file($_FILES['module_package']['tmp_name']);
	if ($mod_folder == "") {
		$module->set_msg($words['module_upload_fail']);
		$module->del_lock();
		unset($module);		
		unset($db);
		exit;
	}
	$mod_name=$module->set_mod_name($mod_folder);
	$module->copy_del_db();
	$module->parser_rdf();
	$module->set_basic_msg();
	$module->check_install_type();
	$ret=$module->compare_conf();
	if($ret==1){
		$module->restore();
	}else{
		$module->execute_install();
	}	
	unset($module);
	unset($db);
	exit;
}elseif($prefix == 'uninstall'){
	//echo('into action = '.$_POST['action'].'<br>');
	$module->create_lock(0);
	$chk_idx=0;
	$undata="";
	$db = new sqlitedb($module_db_path, 'module');
	$db->runPrepare($mod_rs);

	while($mod_info = $db->runNext()){
		$mod_check='check_'.$chk_idx++;
		if (isset($_REQUEST["$mod_check"])){
			$undata=$undata." ".$chk_idx;
		}
	}
	$undata.=" ";
	unset($db);
	$module->execute_uninstall($undata);
	unset($module);
}elseif($prefix == 'enable' || $prefix == 'disable'){
	$lock_exist=$module->lock_exist();
	if ( $lock_exist == "0"){
		echo '{result:"fail", msg:"'.$words['lock_warn'].'"}';
		unset($module);
		exit;
	}
	
	$module->create_lock(1);
	$errmsg='';
	$chk_idx=0;
	$modAry=array();
	$undata="";
	$db = new sqlitedb($module_db_path, 'module');
	$db->runPrepare($mod_rs);

	while($mod_info = $db->runNext()){
		$mod_check='check_'.$chk_idx++;
		if (isset($_REQUEST["$mod_check"])){
			$undata=$undata." ".$chk_idx;
		}
	}
	$undata.=" ";
	unset($db);
	$module->execute_enable($undata);
	unset($module);
	echo '{result:"ok"}';
	exit;
}

function install_statement_handler(
	&$user_data,
	$subject_type,
	$subject,
	$predicate,
	$ordinal,
	$object_type,
	$object,
	$xml_lang )
{
	$rdf_type='http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
	$rdf_mod='http://127.0.0.1/module/schema#';
	global $mod_name;

	++$user_data;

	$id = substr($subject,6);

	if (strcmp($predicate,$rdf_type)==0){
		$pred = 'type';
	}else{
		$pred = substr($predicate,strlen($rdf_mod));
	}

	switch( $object_type ){
	case RDF_OBJECT_TYPE_RESOURCE:
		$object=substr($object,strlen($rdf_mod));
		break;
	case RDF_OBJECT_TYPE_LITERAL:
		break;
	}

	$module_db_path= MODULE_ROOT.'cfg/module.db';

	if (file_exists($module_db_path)) {
		$db2 = new sqlitedb($module_db_path, 'module');
		$db2->exec("insert into mod (module,gid,predicate,object) values ('$mod_name','$id','$pred','$object')");
		unset($db2);
	}
}
?>
