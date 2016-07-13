<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'rsync.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("rsync");
$rsync = new Rsync();
$msgbox = array('show'=>true, 'topic'=>'', 'msg'=>'', 'icon'=>'INFO', 'btn'=>'OK', 'fn'=>'', 'prompt'=>false);
$action=$_REQUEST["action"];
switch ($action) {
	case "modify":
	case "add":
		$task = getTaskInfoFromUI($_POST);
		$errcode = validation($task);
		$msgbox["topic"] = $words["msg_".$action.'_title'];
		if (!empty($errcode)) {
			$msgbox["msg"] = getErrorMsg($errcode, $action);
			$msgbox["icon"] = ERROR;
			break;
		}
		$ret = $rsync->setTask($task);
		if ($ret === false) {
			$msgbox["msg"] = getErrorMsg(-6, $action);
			$msgbox["icon"] = ERROR;
			break;
		}
		if ($action == "add") {
			$strExec = EVENT_SH." 997 ".EVENT_INFO_RSYNC_STATUS." info email \"".$task_name."\" \"Create\"";
		} else {
			$strExec = EVENT_SH." 997 ".EVENT_INFO_RSYNC_STATUS." info email \"".$task_name."\" \"Modify\"";
		}
		shell_exec($strExec);
		
		$msgbox["msg"] = $words[$action."_success"];
		$msgbox["fn"] = array('ok'=>'window_rsync_hide()');
		break;
	case "start":
		$taskname = $_POST['taskname'];
		$task_data = $rsync->getTaskData($taskname);
		if (empty($task_data)) {
			break;
		}
		$cmd = BACKUP_SH_PATH." \"".$taskname."\" start > /dev/null 2>&1 &";
		shell_exec(BACKUP_SH_PATH." \"".$taskname."\" start > /dev/null 2>&1 &");
		break;
	case "stop":
		$taskname = $_POST['taskname'];
		$task_data = $rsync->getTaskData($taskname);
		if (empty($task_data)) {
			break;
		}
		shell_exec(BACKUP_SH_PATH." \"".$taskname."\" stop > /dev/null 2>&1 ");
		break;
	case "delete":
		$tasklist = $_POST["tasklist"];
		$taskary = explode(RSYNC_FOLDER_SEP,$tasklist);
		$rsync->delTask($taskary);
		break;
	default:
}
return MessageBox($msgbox["show"], $msgbox["topic"], $msgbox["msg"], $msgbox["icon"], $msgbox["btn"], $msgbox["fn"], $msgbox["prompt"]);

function validation($task) {
	global $rsync, $sysconf, $validate;
	
	//check task name is empty
	if(trim($task["taskname"]) == ""){
		return -2;
	}

	if ($task["action"] == "add") {
		//check now task_count > task limit
		$task_count = $rsync->getTaskCount();
		if($task_count >= $sysconf["rsync_task_limit"]){
			return -1;
		}
		//check task name is duplicate
		$task_data = $rsync->getTaskData($task["taskname"]);
		if (!empty($task_data)) {
			return -3;
		}
	}

	
	//check task name format
	preg_match("/[^a-zA-Z0-9_]/",$task["taskname"],$match);
	if( $match[0] != ""){
		return -4;
	}
	
	// check passwrod, single byte only
	if ($task["pwd_change"] == 1) {
		if(!$validate->limitstrlen(4,16,$task["passwd"]) || !$validate->check_userpwd($task["passwd"])) {
			return -7;
		}
	}
		
	return "";
}

function getErrorMsg($errcode, $action) {
	global $gwords, $words, $sysconf;
	$msg = "";
	switch ($errcode) {
		case 0:
			$msg = $words[$action."_success"];
			break;
		case -1:
			$msg = sprintf($words["limit_error"],$sysconf["rsync_task_limit"]);
			break;
		case -2:
			$msg = $words["task_name_empty"];
			break;
		case -3:
			$msg = $words["task_duplicate"];
			break;
		case -4:
			$msg = $words["taskname_error"];
			break;
		case -5:
			$msg = $words["no_space"];
			break;
		case -6:
			$msg = $words[$action."_fail"];
			break;
		case -7:
			$msg = $gwords["encryptkey_error"];
			break;
		case -8:
			$msg = $words["task_no_existed"];
			break;
		default:
	}
	
	return $msg;
}

function getTaskInfoFromUI($post) {
	$task = array();
	// key name is the same as the field name in database table
	$task["taskname"] = trim($post["taskname"]);
	$task["desp"] = trim($post["rsync_desp"]);
	$task["folder"] = trim($post["src_folder"]);
	$task["log_folder"] = trim($post["rsync_log_folder"]);
	$task["ip"] = trim($post["rsync_dest_ip"]);
	$task["port"] = trim($post["rsync_dest_port"]);
	if (empty($task["port"])) {
		$task["port"] = "873";
	}
	$task["dest_folder"] = trim($post["rsync_dest_folder"]);
	$task["subfolder"] = trim($post["rsync_subfolder"]);
	$task["username"] = trim($post["rsync_user"]);
	$task["passwd"] = $post["rsync_pwd"];
	$task["backup_enable"] = trim($post["rsync_schedule"]);
	$task["backup_time"] = trim($post["backup_time"]);
	$task["model"] = trim($post["rsync_mode"]);
	$task["pwd_change"] = $post["pwd_change"];
	$task["action"] = $post["action"];

	$task["encrypt_on"]="0";
	if ($post["rsync_encrypt_on"] == "on")
	 $task["encrypt_on"]="1";

	$task["compression"]="0";
	if ($post["rsync_compression"] == "on")
	 $task["compression"]="1";

	$task["sparse"]="0";
	if ($post["rsync_sparse"] == "on")
	 $task["sparse"]="1";

	return $task;
}

?>
