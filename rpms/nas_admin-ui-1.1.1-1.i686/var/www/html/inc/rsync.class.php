<?php
include_once(INCLUDE_ROOT.'dataguard.class.php');
include_once(INCLUDE_ROOT.'info/SeparatePageAssistant.class.php');

define("RSYNC_TABLE", "rsyncbackup");
define("RSYNC_DB_PATH", "/etc/cfg/conf.db");
define("BACKUP_SH_PATH", "/img/bin/backup.sh");
define("REMOTE_BACKUP_SH_PATH", "/img/bin/dataguard/remote_backup.sh");
define("RSYNC_ENABLE_FILE", "/tmp/rsyncbackup.enable");
define("RSYNC_TASK_DEFAULT_PREFIX_NAME", "Rsync_task_");
define("RSYNC_FOLDER_SEP", chr(58).chr(58));
define("RSYNC_DEFAULT_PWD", chr(26).chr(26).chr(26).chr(26));
define("RSYNC_LOG_FILE_PREFIX", "/raid/data/tmp/rsync_backup.%s");
define("RSYNC_FILE_PREFIX", "/tmp/rsync_backup_");
define("RSYNC_STATUS_FILE", RSYNC_FILE_PREFIX."%s.status");
define("RSYNC_SRC_COUNT_FILE", RSYNC_FILE_PREFIX."%s.count");


/**
 * Rsync class
 * @author Ellie Chien
 * 
 * @property db_columns (static) : column fields of rsyncbackup table
 * @property errcode (static) : customized errcode for rsync error
 *
 * @method getCrondStr(): Get all rsync task data from database
 * @method checkTableExists(): Check if rsyncbackup table has been existed in /etc/cfg/conf.db
 * @method buildTable(): Create rsyncbackup table into /etc/cfg/conf.db
 * @method setTask(): Set task data into /etc/cfg/conf.db, including [add] and [modify] action
 * @method delTask(): Remove the selected tasks from /etc/cfg/conf.db and remove the related crond setup
 * @method getTaskLog(): Get the related log of the task
 * @method getTaskProgress(): Get the task’s progress
 * @method parseCrondStr(): Parse crond data into crond format (Ex: 00 00 * * *)
 * @method getRsyncStatusKey(): Get the status wording key for the task
 * @method isRsyncRunning(): Check if any rsync task is running
 * @method getTaskCount(): Get how many rsync tasks are
 * @method getTaskDefaultName(): Get the default name of rsync task
 * @method getTaskData(): Get the selected task data
 * @method connTest(): Connection test and return the result
 */
class Rsync {
	public static $db_columns = "taskname,desp,model,folder,ip,port,dest_folder,subfolder,username,passwd,log_folder,backup_enable,backup_time,tmp1,tmp2,tmp3";
	public static $errcode = array(
		"7"=>"bkp_success",
		"9"=>"dest_ro",
		"10"=>"server_disconnect",
		"12"=>"no_space",
		"15"=>"user_cancel",
		"16"=>"src_no_exist",
		"23"=>"io_err",
		"24"=>"src_deleted",
		"30"=>"timeout",
		"31"=>"task_skip",
		"32"=>"auth_err",
		"37"=>"dest_no_exist",
		"38"=>"connect_limit",
		"997"=>"encry_fail",
		"998"=>"encry_conn_fail",
		"999"=>"unknow_err"
	);
	

	function __construct() {
		if (!$this->checkTableExists(RSYNC_TABLE)) {
			$this->buildTable();
		}
	}

	function getRsyncList(){
		$db = new sqlitedb(RSYNC_DB_PATH);
		$sql = "SELECT * FROM ".RSYNC_TABLE;
		$taskList = $db->runSQLAry($sql);
		$count = count($taskList);
		if ($count == 0) {
			$db->db_close();
			return "";
		}
		$db->db_close();
		
		return $taskList;
	}

	function checkTableExists($table){
		$sql = "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'";
		$db = new sqlitedb(RSYNC_DB_PATH);
		$ret = false;
		$tablename = $db->runSQL($sql);
		if (!empty($tablename)) {
			$ret = true;
		}
		
		$db->db_close();
		return $ret;
	}
	
	function buildTable(){
		$cmd = "/usr/bin/sqlite ".RSYNC_DB_PATH." \"CREATE TABLE ".RSYNC_TABLE." (taskname CHAR DEFAULT '',desp TEXT DEFAULT '',model DEFAULT '',folder TEXT DEFAULT '',ip DEFAULT '',port DEFAULT '',dest_folder DEFAULT '',subfolder DEFAULT '',username DEFAULT '',passwd DEFAULT '',log_folder DEFAULT '', backup_enable DEFAULT '',backup_time DEFAULT '',end_time DEFAULT '',status DEFAULT '',tmp1 DEFAULT '',tmp2 DEFAULT '',tmp3 DEFAULT '',tmp4 DEFAULT '',tmp5 DEFAULT '')\"";
		shell_exec($cmd);
	}

	function setTask($task) {
		if (empty($task)) {
			return false;
		}
		if ($task["action"] == "add") {
			$ret = $this->addTask($task);
		} else {
			$ret = $this->modifyTask($task);
		}
		
		return $ret;
	}
	
	private function addTask($task_data) {
		$values = "'".$task_data["taskname"]."','".$task_data["desp"]."','".$task_data["model"]."','".$task_data["folder"]."','".$task_data["ip"]."','".$task_data["port"]."','".$task_data["dest_folder"]."','".$task_data["subfolder"];
		$values .= ("','".$task_data["username"]."','".$task_data["passwd"]."','".$task_data["log_folder"]."','".$task_data["backup_enable"]."','".$task_data["backup_time"]."','".$task_data["encrypt_on"]."','".$task_data["compression"]."','".$task_data["sparse"]."'");
		$db = new sqlitedb(RSYNC_DB_PATH);
		$ret = $db->db_insert(RSYNC_TABLE,self::$db_columns,$values);
		$db->db_close();
		if ($ret != "1") {
			return false;
		}
		
		if($task_data["backup_enable"] == "1") {
			$crond_job = sprintf("%s \"%s\" start > /dev/null 2>&1", BACKUP_SH_PATH, $task_data["taskname"]);
			addCrondJob($crond_job, $task_data["backup_time"]);
			resetCrond();
		}
		
		return true;
	}
	
	private function modifyTask($task_data) {
		$items = "desp='".$task_data["desp"]."',backup_enable='".$task_data["backup_enable"]."',backup_time='".$task_data["backup_time"]."',model='".$task_data["model"]."',ip='".$task_data["ip"]."',port='".$task_data["port"]."',dest_folder='".$task_data["dest_folder"];
		$items .= ("',subfolder='".$task_data["subfolder"]."',username='".$task_data["username"]."',log_folder='".$task_data["log_folder"]."',tmp1='".$task_data["encrypt_on"]."',tmp2='".$task_data["compression"]."',tmp3='".$task_data["sparse"]."'");
		if ($task_data["pwd_change"] == "1") {
			$items .= ",passwd='".$task_data["passwd"]."'";
		}
		if (!empty($task_data["folder"])) {
			$items .= ",folder='".$task_data["folder"]."'";
		}
		
		$db = new sqlitedb(RSYNC_DB_PATH);
		$ret = $db->db_update(RSYNC_TABLE,$items,"where taskname='".$task_data["taskname"]."'");
		$db->db_close();
		
		if($ret != "1"){
			return false;
		}

		$crond_job = sprintf("%s \"%s\" start > /dev/null 2>&1", BACKUP_SH_PATH, $task_data["taskname"]);
		if($task_data["backup_enable"] == "1"){
			modifyCrondSchedule($crond_job, $task_data["backup_time"]);
			resetCrond();
		}else{
			delCrondJob($crond_job);
			resetCrond();
		}
		
		return true;
	}
	
	function delTask($task_list) {
		if (empty($task_list)) {
			return false;
		}
		
		$db = new sqlitedb(RSYNC_DB_PATH);
		foreach ($task_list as $k=>$v){
			$db->db_delete("rsyncbackup","where taskname='".$v."'");
			$crond_job = sprintf("%s \"%s\" start > /dev/null 2>&1", BACKUP_SH_PATH, $v);
			delCrondJob($crond_job);
			$strExec = EVENT_SH." 997 ".EVENT_INFO_RSYNC_STATUS." info email \"".$v."\" \"Deleted\"";
			shell_exec($strExec);
		}
		resetCrond();
		$db->db_close();
		
		return true;
	}
	
	function getTaskLog($taskname, $limit, $start) {
		if (empty($taskname)) {
			return "";
		}

		$list = array('/var/log/error','/var/log/warning','/var/log/information','/raid/sys/error','/raid/sys/warning','/raid/sys/information','/raid/sys/information','/syslog/error','/syslog/warning','/syslog/information');
		$spa = new SeparatePageAssistant($list, 10000, true);
		$page_content = $spa->getPage(1);
	
		$rsync_log = array();
		foreach ($page_content as $v){
			if(preg_match("/Rsync Backup : Task \[ $taskname/",$v)) {
				array_push($rsync_log,array('log_msg'=>$v));
			}
		}
		
		$total_count = count($rsync_log);
		
		if(($limit+$start) > $total_count){
			$current_count = $total_count;
		}else{
			$current_count = $limit+$start;
		}
		
		$logs = array();
		if($start != ""){
			for($c = $start; $c < $current_count; $c++){
				$logs[] = $rsync_log[$c];
			}
		}
		
		return array(
			"total_count"=>$total_count,
			"log_data"=>$logs
		);
	}
	
	function getTaskProgress($taskname, $dest_folder) {
		if (empty($taskname)) {
			return "";
		}
	
		$status_file = sprintf(RSYNC_STATUS_FILE, $taskname);
		$log_file = sprintf(RSYNC_LOG_FILE_PREFIX, $taskname);
		if(!file_exists($status_file)){
			return "";
		}
	
		$task_start_time=date("Y/m/d H:i", filectime($status_file));
		$count_file = sprintf(RSYNC_SRC_COUNT_FILE, $taskname);
		$all_count = file($count_file);
		$trans = trim(shell_exec("cat \"".$log_file."\" | egrep '>f|<f|cd'| wc -l "));
		if (empty($all_count)) {
			$all_count = 0;
		} else {
			$all_count = trim($all_count[0]);
		}
		$task_progress = $trans."/".$all_count;
		$proceed = shell_exec("cat \"$log_file\" | egrep '>f|<f|cd' | tail -1 | awk -F '\+\+\+\+\+\+\+\+\+ ' '{print \$NF}'");
		if (empty($proceed)) {
			$proceed = "";
		}
		
		return array(
			"taskname"=>$taskname,
			"dest_folder"=>$dest_folder,
			"start_time"=>$task_start_time,
			"process_file"=>$task_progress,
			"status"=>$proceed
		);
	}
	
	function parseCrondStr($crond_data,$gwords){
		$crond_conf = explode(" ",$crond_data);
		if($crond_conf[4] != "*"){
			$week = array($gwords['sunday'],$gwords['monday'],$gwords['tuesday'],$gwords['wednesday'],$gwords['thursday'],$gwords['friday'],$gwords['saturday']);
			$crond_str=$week[$crond_conf[4]];
		}elseif($crond_conf[2] != "*"){
			$crond_str=$gwords['monthly']." (".$crond_conf[2].")";
		}else{
			$crond_str=$gwords['daily'];
		}
	
		$cron_str=$cron_str."   ".$cron_conf[1].":".$cron_conf[0];
		return $cron_str;
	}

	function getRsyncStatusKey($taskname, $status_no) {
		$status_file = sprintf(RSYNC_STATUS_FILE, $taskname);
		if (file_exists($status_file)) {
			$status_key = "task_running";
		} else {
			if (empty($status_no)) {
				return "";
			}
			$status_key = self::$errcode[$status_no];
		}
		
		if (empty($status_key)) {
			return "";
		}
		
		return $status_key;
	}
	
	function isRsyncRunning() {
		$cmd = "ls ".RSYNC_FILE_PREFIX."*.status > /dev/null 2>&1";
		exec($cmd, $out, $ret);
		if ($ret == 0) {
			return true;
		} else {
			return false;
		}
	}
	
	function getTaskCount() {
		$db = new sqlitedb(RSYNC_DB_PATH);
		$sql = "SELECT count(*) FROM ".RSYNC_TABLE;
		$ret = $db->runSQL($sql);
		$db->db_close();
		
		return $ret[0];
	}
	
	function getTaskDefaultName() {
		$count = $this->getTaskCount();
		
		return RSYNC_TASK_DEFAULT_PREFIX_NAME.($count+1);
	}
	
	function getTaskData($taskname) {
		$db = new sqlitedb(RSYNC_DB_PATH);
		$sql = "SELECT * FROM ".RSYNC_TABLE." WHERE taskname='".$taskname."'";
		$task = $db->runSQL($sql);
		$db->db_close();
		
		return $task;
	}
	
	function connTest($task) {
		if (!empty($task["dest_folder"])) {
			$folder_list = explode(RSYNC_FOLDER_SEP, $task["dest_folder"]);
		} else if (empty($task["folder"])) {
			// folder list has not been changed, drawing the original folder list from database
                        $task_data = $this->getTaskData($task["taskname"]);
                        $folder_list = explode(RSYNC_FOLDER_SEP, $task_data["folder"]);
		} else {
			$folder_list = explode(RSYNC_FOLDER_SEP, $task["folder"]);
		}
		if ($task["pwd_change"] == "0") {
			$task["passwd"] = $task_data["passwd"];
		}
		
		$alloutput="";
		foreach($folder_list as $folder){
			$cmd = IMG_BIN.'/rsync_test.sh "'.$task["taskname"]. '" "'.$task["ip"]. '" "'.$task["port"]. '" "'.escapeshellcmd($folder). '" "'.$task["username"]. '" "'.$task["passwd"]. '" "'.$task["encrypt_on"]. '"';
                        $output = shell_exec($cmd);
			$ret = trim(substr( strrchr( $output, " " ), 1 ));
			if (($ret=="700") || ($ret=="701") || ($ret=="702") || ($ret=="709")){
				$alloutput = substr($output, 0, strrpos($output, " "));
				break;
			}else{
				if ($ret!="707"){
					if ($alloutput=="")
						$alloutput = substr($output, 0, strrpos($output, " "));
					else
						$alloutput = $alloutput . "\n" . substr($output, 0, strrpos($output, " "));
				}else{
					$success_str = substr($output, 0, strrpos($output, " "));
				}
			}
		}
		
		if ($alloutput == "") {
			$alloutput = $success_str;
		}
		
		return $ret;
	}

}

?>


