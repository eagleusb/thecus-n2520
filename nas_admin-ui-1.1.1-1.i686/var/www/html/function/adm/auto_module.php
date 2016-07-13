<?php
require_once(INCLUDE_ROOT.'module.class.php');

$words = $session->PageCode("module");

$action=($_POST["action"]!="")?trim($_POST["action"]):trim($_GET["action"]);
if ($action == "status") {
	$module=new Module($words,'', '/img/bin/rc/rc.automodule');
	$status_data = $module->check_status($_POST,$_GET);
	if ($status_data['mod_lock_flag'] == "") {
		die(
			json_encode(
				array(
					'mod_status'=>$status_data['mod_status'],
					'mod_lock_flag'=>$status_data['mod_lock_flag'],
					'moduleData'=>trim(shell_exec("sh /img/bin/rc/rc.automodule list | tr -d \'"))
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
} else {
	$moduleData=trim(shell_exec("sh /img/bin/rc/rc.automodule list | tr -d \'"));
}

$module=new Module($words,'', '/img/bin/rc/rc.automodule');
$lock_type = $module->get_lock_type();
unset($module);

$tpl->assign('lock_type', $lock_type);
$tpl->assign('words',$words);
$tpl->assign('moduleData',$moduleData);
$tpl->assign('form_action','setmain.php?fun=setauto_module');



?>
