<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'rsync.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'info/SeparatePageAssistant.class.php');
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

$gwords = $session->PageCode("global");
$words = $session->PageCode("rsync");
$rsync = new Rsync();
$action=$_REQUEST["action"];
switch ($action) {
	case "task_default":
		$taskname = $rsync->getTaskDefaultName();
		$retAry = array('taskname'=>$taskname);
		break;
	case "task_data":
		$task_data = $rsync->getTaskData($_POST["taskname"]);
		if (empty($task_data)) {
			$task_data = "";
		} else {
			$task_data["folder"] = parseSrcList($task_data["folder"]);
		}
		$retAry = array('task_data'=>$task_data);
		break;
	case "log":
		$start=$_POST['start'];
		$limit=$_POST['limit'];
		$taskname = rawurldecode($_GET["taskname"]);
		$log_info = $rsync->getTaskLog($taskname, $limit, $start);
		$retAry = array('total_count'=>$log_info["total_count"],'log_data'=>$log_info["log_data"]);
		break;
	case "progress":
		$taskname = rawurldecode($_GET["taskname"]);
		$dest_folder = $_GET["dest_folder"];
		$progress = $rsync->getTaskProgress($taskname, $dest_folder);
		if (empty($progress)) {
			$retAry = array('close'=>1);
		} else {
			$retAry = array('progress'=>$progress);
		}
		break;
	case "monitor":
		$list = $rsync->getRsyncList();
		$reload = $rsync->isRsyncRunning()?1:0;
		$rsync_task = parseTaskList($list);
		$retAry = array('rsync_task'=>$rsync_task,'reload'=>$reload);
		break;
	case "src_folder":
		$retAry = array('src_folder'=>getShareList());
		break;
	case "test":
		$task["taskname"] = trim($_POST["taskname"]);
		$task["folder"] = trim($_POST["src_folder"]);
		$task["ip"] = trim($_POST["rsync_dest_ip"]);
		$task["port"] = trim($_POST["rsync_dest_port"]);
		if (empty($task["port"])) {
			$task["port"] = "873";
		}
		$task["dest_folder"] = trim($_POST["rsync_dest_folder"]);
		$task["username"] = trim($_POST["rsync_user"]);
		$task["passwd"] = $_POST["rsync_pwd"];
		$task["pwd_change"] = $_POST["pwd_change"];
		
		$task["encrypt_on"]="0";
		if ($_POST["rsync_encrypt_on"] == "on")
		  $task["encrypt_on"]="1";
	 
		$retAry = array('post'=>$_POST, 'rsync_test_msg'=>$rsync->connTest($task));
		break;
	default:
		$list = $rsync->getRsyncList();
		$rsync_task = parseTaskList($list);
		$reload = $rsync->isRsyncRunning()?1:0;
		$day = getDayStore();
		$week = getWeekStore($gwords);
		$time = getTimeStore();
		$share = getShareStore();
}

if (!empty($retAry)) {
	die(json_encode($retAry));
}

$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setrsync');
$tpl->assign('geturl','getmain.php?fun=rsync');
$tpl->assign('urlimg',URL_ROOT_IMG);
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('day_fields',$day["day_fields"]);
$tpl->assign('day_data',$day["day_data"]);
$tpl->assign('week_fields',$week["week_fields"]);
$tpl->assign('week_data',$week["week_data"]);
$tpl->assign('hour_fields',$time["hour_fields"]);
$tpl->assign('hour_data',$time["hour_data"]);
$tpl->assign('min_fields',$time["min_fields"]);
$tpl->assign('min_data',$time["min_data"]);
$tpl->assign('rsync_task',json_encode($rsync_task));
$tpl->assign('share_fields',$share["share_fields"]);
$tpl->assign('share_data',$share["share_data"]);
$tpl->assign('default_folder',$share["default_folder"]);
$tpl->assign('default_pwd', RSYNC_DEFAULT_PWD);
$tpl->assign('folder_sep', RSYNC_FOLDER_SEP);
$tpl->assign('reload', $reload);
$tpl->assign('lang',$session->lang);

function parseTaskList($rsync_list) {
	global $gwords,$words;
	global $rsync;
	$cTask = 0;
	$new_list = array();
	
	if (!empty($rsync_list)) {
		$cTask = count($rsync_list);
	}
	
	for ($i = 0; $i < $cTask; $i++) {
		$task = $rsync_list[$i];
		if (empty($rsync_list[$i]["status"])) {
			$task["task_status"] = "";
		} else {
			$status_key = $rsync->getRsyncStatusKey($rsync_list[$i]["taskname"], $rsync_list[$i]["status"]);
			if (empty($status_key)) {
				$task["task_status"] = "";
			} else {
				$task["task_status"] = $words[$status_key];
			}
		}
		if (empty($rsync_list[$i]["subfolder"])) {
			$task["dest_path"] = $rsync_list[$i]["ip"]."/".$rsync_list[$i]["dest_folder"];
		} else {
			$task["dest_path"] = $rsync_list[$i]["ip"]."/".$rsync_list[$i]["dest_folder"]."/".$rsync_list[$i]["subfolder"];
		}
		$task["src_folder"] = parseSrcList($rsync_list[$i]["folder"]);
		$task["crond_str"] = $rsync->parseCrondStr($rsync_list[$i]["backup_time"]);
		array_push($new_list, $task);
	}
	
	return $new_list;
}

function parseSrcList($src_list) {
	$src_folders = explode(RSYNC_FOLDER_SEP,$src_list);
	$cFolder = count($src_folders);
	for ($j = 0; $j < $cFolder; $j++) {
		$src_folders[$j] = "[".$src_folders[$j]."]";
	}
	
	return implode(",", $src_folders);
}

function getShareStore() {
	global $validate;
	
	$share_fields="['display', 'value']";
	$strExec="sed -nr \"/^\[[^\\n]*\]/p\" /etc/samba/smb.conf";
	$smbconf = shell_exec($strExec);
	$share_list = explode("\n",$smbconf);
	$share_length=count($share_list)-1;
	$default_folder="";
	
	if ($share_length == 0) {
		$share_data = "[]";
	} else {
		$share_data = "[";
		for($i=1;$i<$share_length;$i++){
			$share_name=substr($share_list[$i],1,strlen($share_list[$i])-2);
			if($validate->hide_system_folder($share_name)){
				continue;	
			}	
			if(($share_name!="nsync")&&($share_name!="snapshot")&&($share_name!="usbhdd")&&($share_name!="usbcopy")){
				if($default_folder==""){
					$default_folder=$share_name;
				}
				$share_data .= "['".$share_name."','".$share_name."'],";
			}
		}
		$share_data = substr($share_data,0,strlen($share_data)-1);
		$share_data .= "]";
	}
	return array(
		"share_fields"=>$share_fields,
		"share_data"=>$share_data,
		"default_folder"=>$default_folder
	);
}

function getShareList() {
	global $validate;
	
	$strExec="sed -nr \"/^\[[^\\n]*\]/p\" /etc/samba/smb.conf";
	$smbconf = shell_exec($strExec);
	$share_list = explode("\n",$smbconf);
	$new_list = array();
	
	foreach ($share_list as $v) {
		if (empty($v)) {
			continue;
		}
		$share_name=substr($v,1,strlen($v)-2);
		if($validate->hide_system_folder($share_name)){
			continue;	
		}	
		if(($share_name == "global") || ($share_name == "nsync") || ($share_name == "snapshot") || ($share_name == "usbhdd") || ($share_name == "usbcopy")){
			continue;
		}
		
		$share["src_folder"] = $share_name;
		array_push($new_list, $share);
	}
	
	return $new_list;
}

?>
