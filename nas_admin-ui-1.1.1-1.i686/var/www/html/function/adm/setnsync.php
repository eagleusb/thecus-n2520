<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'nsync.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("nsync");

$action=($_POST["action"])?trim($_POST["action"]):trim($_GET["action"]);

$nsync_task=new nsync();
$task_list=$nsync_task->GetNsyncList();
//echo "<pre>";print_r($task_list);exit;
/*
die(
	json_encode(
		array(
			$_POST["time"]
		)
	)
);
*/
if($action=="start"){
	$task_name=trim($_POST["process_name"]);
	$db_tool=new sqlitedb(SYSTEM_DB_ROOT."conf.db","nsync");
	$db_tool->db_open();
	if($task_name!=""){
		$strExec="update nsync set status='Start VPN' where task_name='${task_name}'";
		$db_tool->runSQLAry($strExec);
		unset($db_tool);
		$nsync_task->excute_task($task_name,"start");
	}
	return MessageBox(false,'','');
}elseif($action=="stop"){
	$task_name=trim($_POST["process_name"]);
	$db_tool=new sqlitedb(SYSTEM_DB_ROOT."conf.db","nsync");
	if($task_name!=""){
		$nsync_task->excute_task($task_name,"stop");
	}
	$strExec="select status from nsync where task_name='${task_name}'";
	$last_status=$db_tool->runSQLAry($strExec);
	$last_status=$last_status['0']['status'];
	for($c=0;$c<30;$c++){
		if(preg_match("/Cancel/",$last_status)){
			break;
		}
		$last_status=$db_tool->runSQLAry($strExec);
		$last_status=$last_status['0']['status'];
		sleep(1);
	}
	unset($db_tool);
	die(json_encode(array('last_status'=>$last_status,'c'=>$c,'task_name'=>$task_name)));
	return MessageBox(false,'','');
}elseif($action=="restore"){
	$task_array=trim($_POST["process_name"]);
	$task=explode(chr(26),$task_array);
	foreach($task as $t){
		if($t!=""){
			$db_tool=new sqlitedb(SYSTEM_DB_ROOT."conf.db","nsync");
			$db_tool->db_open();
			$strExec="update nsync set status='Start VPN' where task_name='${t}'";
			$db_tool->runSQLAry($strExec);
			unset($db_tool);
			$nsync_task->excute_task($t,"restore");
		}
	}
	return MessageBox(false,'','');
}elseif($action=="delete"){
	$task_array=trim($_POST["process_name"]);
	$task=explode(chr(26),$task_array);
	foreach($task as $t){
		if($t!=""){
			$nsync_task->deleteTask($t);
			$strExec="/img/bin/logevent/event 997 123 info \"\" \"".$v."\" \"DELETED\"";
			shell_exec($strExec);
		}
	}
	return MessageBox(false,'','');
}elseif($action=="qos"){
	$bandwidth=trim($_POST["bandwidth"]);
	$db_tool=new sqlitedb();
	$db_tool->db_open();
	$db_tool->setvar("nsync_qos",$bandwidth);
	unset($db_tool);
	$strExec="/img/bin/nsync_qos.sh rate ${bandwidth}";
	shell_exec($strExec);
	//return  MessageBox(true,$words[${action}.'_nsync_title'],$bandwidth,ERROR);
	return MessageBox(false,'','');
}

$task_name=($_POST["task_name"])?trim($_POST["task_name"]):trim($_POST["task_name1"]);
$task_name1=trim($_POST["task_name1"]);
$manufacturer=trim($_POST["manufacturer"]);
$folder=trim($_POST["folder"]);
$folder1=trim($_POST["folder1"]);
$ip=trim($_POST["ip"]);
$task_id=trim($_POST["task_id"]);
$task_pwd=trim($_POST["task_pwd"]);
$nsync_schedule=trim($_POST["nsync_schedule"]);
$time=$_POST["time"];
$times=$_POST["times"];
$timeAry=explode(":",$time);
$hours=$timeAry[0];
$mins=$timeAry[1];
$nsync_type=trim($_POST["nsync_type"]);
$week_day=trim($_POST["week_day"]);
$days=trim($_POST["days"]);
$nsync_mode=trim($_POST["nsync_mode"]);
$crond=trim($_POST["crond"]);
//return  MessageBox(true,$words['success'],$time." == ".$times." == ".$nsync_type." == ".$week_day." == ".$days." == ".$crond);
//########################################################
//#	Check Item
//########################################################
$raid_status=str_replace(" ","",shell_exec("cat /var/tmp/raid*/rss | grep -i 'healthy' | wc -l"));
if(trim($raid_status)=="0"){
	return  MessageBox(true,$words[${action}.'_nsync_title'],$words["raid_not_ready"],ERROR);
}

if($action=='add'){
	foreach($task_list as $k=>$v){
		if(isset($v['task_name'])){
			if($v['task_name']==$task_name){
				return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_taskname_duplicate"],ERROR);
			}
		}
	}
	if($folder==""){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_no_share"],ERROR);
	}
	if($task_name==""){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_empty_taskname"],ERROR);
	}elseif(!$validate->check_nsynctaskname($task_name)){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_taskname_format_err"],ERROR);
	}
}elseif($action=='edit'){
	foreach($task_list as $k=>$v){
		if(isset($v['task_name'])){
			if($v['task_name']==$task_name && $task_name!=$task_name1){
			//if($v['task_name']==$task_name){
				return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_taskname_duplicate"],ERROR);
				break;
			}
		}
	}
	if($folder1==""){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_no_share"],ERROR);
	}
}

if($ip=="" || !$validate->ip_address($ip)){
	return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_ip_err"],ERROR);
}

if($task_id=="" || $task_pwd==""){
	return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_auth_empty"],ERROR);
}else{
	if(!$validate->check_username($task_id)){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["nsync_username_error"],ERROR);
	}
}


//########################################################
if($nsync_schedule=="0"){
	$crond = str_replace(","," ",$crond);
	if($crond[0]!="#")
		$crond = "#{$crond}";
}else{
	
	$hour_length=strlen($hours);
	$min_length=strlen($mins);
	if($hour_length!=2 || $min_length!=2){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["time_format_error"]."1",ERROR);
	}
	$h=$hours;
	$m=$mins;
	
	if($hours[0]=="0"){
		$h=$hours[1];
	}
	if($mins[0]=="0"){
		$m=$mins[1];
	}
	
	if($h < "0" || $h > "23" || $m < "0" || $m > "59"){
		return  MessageBox(true,$words[${action}.'_nsync_title'],$words["time_format_error"]."2",ERROR);
	}
	
	$crond="${mins} ${hours}";
	switch ($nsync_type){
		case 'daily':
			$crond  = "{$crond} * * * ";
			break;
		case 'weekly':
			$crond  = "{$crond} * * ${week_day} ";
			break;
		case 'monthly':
			$crond  = "{$crond} ${days} * * ";
			break;
	}
}
$taskname=$task_name;
$task['task_name']=$task_name;
$task['manufacturer']=$manufacturer;
$task['ip']=$ip;
if($action=="add")
	$task['folder']=$folder;
else
	$task['folder']=$folder1;
$task['username']=$task_id;
$task['passwd']=add_slash($task_pwd);
$task['crond']=$crond;
$task['nsync_mode']=$nsync_mode;
$nsync_task=new nsync();
if($action=="add"){
	$nsync_task->AddTask($taskname,$task);
	$strExec="/img/bin/logevent/event 997 123 info \"\" \"${taskname}\" \"ADDED\"";
}else{
	$a=$nsync_task->ModifyTask($task_name,$taskname,$task);
	$strExec="/img/bin/logevent/event 997 123 info \"\" \"${taskname}\" \"MODIFIED\"";
}
shell_exec($strExec);
$ary = array('ok'=>'Window_nsync_hide()');
return  MessageBox(true,$words[${action}.'_nsync_title'],$gwords["success"],INFO,OK,$ary);
?>
