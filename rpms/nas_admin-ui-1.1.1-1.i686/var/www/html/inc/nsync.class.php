<?
require_once("../../function/conf/localconfig.php");
class nsync {
const conf_path="/raid/sys/nsync.conf";
const crond_script="/img/bin/nsync.sh ";
const status_path="/raid/sys/";
const db_path="/etc/cfg/conf.db";
public static $all_colum=array('task_name','manufacturer','ip','folder','username','passwd','crond','status','end_time','nsync_mode');
public static $colum_name=array('task_name','manufacturer','ip','folder','username','passwd','crond','status','nsync_mode');
public static $attribute=array();
var $sqlite_version=SQLITE_VERSION;


function __construct(){
	//if (file_exists('/lib/libsqlite3.so') || file_exists('/lib64/libsqlite3.so'))
	//	$this->sqlite_version=3;
	//echo 'sqlite version = ',$this->sqlite_version,'<br>';
	if(!$this->check_db_exists("nsync"))
                $this->Build_table();
	$this->GetNsyncList();
}

function check_db_exists($table){
	$table=sqlite_escape_string($table);
        if ($this->sqlite_version==2){
        	$db = sqlite_open(self::db_path);
        	$rs = sqlite_query($db,"SELECT name FROM sqlite_master WHERE type='table' AND name='$table'");
		unset($db);
	        return sqlite_num_rows($rs)>0;
        }else{
		$db=new PDO("sqlite:".self::db_path);
                /* counts the tables that match the name given */
                $strSQL="SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='$table'";
                $result = $db->query($strSQL)->fetchall();
		unset($db);

                /* casts into integer */
                $count = intval($result[0][0]);

                /* returns true or false */
                return $count > 0;
        }
}

function Build_table(){
	shell_exec("sqlite /etc/cfg/conf.db \"create table nsync (task_name nvarchar(255) PRIMARY KEY DEFAULT '',manufacturer nvarchar(255) DEFAULT '',ip nvarchar(255) DEFAULT '',folder nvarchar(255) DEFAULT '',username nvarchar(255) DEFAULT '',passwd nvarchar(255) DEFAULT '',crond varchar(255) DEFAULT '',status nvarchar(255) DEFAULT '', end_time nvarchar(255) DEFAULT '', nsync_mode nvarchar(255) DEFAULT '')\"");
}

function excute_task($taskname,$action){
	$cmd="";
	foreach(self::$attribute as $key=>$v){
		if($v['task_name']==$taskname){
			$task_name=$v['task_name'];
			$taskname=$key;
			break;
		}
	}
	$folder_name=addcslashes(self::$attribute[$taskname]['folder'],"($+{}'^)");
	switch($action){
	case "start":
		shell_exec("echo \"\" > \"/raid/sys/{$task_name}.status\"  > /dev/null 2>&1");
		shell_exec(self::crond_script ." \"" . self::$attribute[$taskname]['ip']."\" \"" . self::$attribute[$taskname]['username']."\" \"" . self::$attribute[$taskname]['passwd'] . "\" \"" . self::$attribute[$taskname]['task_name'] ."\" \"" . $folder_name."\" \"" . self::$attribute[$taskname]['manufacturer'] . "\" \"${action}\" > /dev/null 2>&1 &");
		break;
	case "stop":
		//if(file_exists(self::status_path . "{$task_name}.status")){
		$status=shell_exec("cat \"" . self::status_path . "{$task_name}.status\"|grep status| grep -v 'grep'|awk '{printf $2}'");
		$status=($status=="")?"in progress":$status;
			if($status=="in progress"){
				shell_exec(self::crond_script ." \"" . self::$attribute[$taskname]['ip']."\" \"" . self::$attribute[$taskname]['username']."\" \"" . self::$attribute[$taskname]['passwd'] . "\" \"" . self::$attribute[$taskname]['task_name'] ."\" \"" . $folder_name."\" \"" . self::$attribute[$taskname]['manufacturer'] . "\" \"${action}\" > /dev/null 2>&1 &");
			}
		//}	
		break;
	case "delete":
		if(!file_exists(self::status_path . "{$task_name}.status")){
			shell_exec(self::crond_script ." \"" . self::$attribute[$taskname]['ip']."\" \"" . self::$attribute[$taskname]['username']."\" \"" . self::$attribute[$taskname]['passwd'] . "\" \"" . self::$attribute[$taskname]['task_name'] ."\" \"" . $folder_name."\" \"" . self::$attribute[$taskname]['manufacturer'] . "\" \"${action}\" > /dev/null 2>&1 &");
		}
		break;
	case "restore":
		if(!file_exists(self::status_path . "{$task_name}.status")){
			shell_exec("echo \"\" > \"/raid/sys/{$task_name}.status\"  > /dev/null 2>&1");
			shell_exec(self::crond_script ." \"" . self::$attribute[$taskname]['ip']."\" \"" . self::$attribute[$taskname]['username']."\" \"" . self::$attribute[$taskname]['passwd'] . "\" \"" . self::$attribute[$taskname]['task_name'] ."\" \"" . $folder_name."\" \"". self::$attribute[$taskname]['manufacturer'] . "\" \"$action\" > /dev/null 2>&1 &");
		}
		break;
	}

}

function GetNsyncList(){
	$strSQL="SELECT * FROM nsync";
	if ($this->sqlite_version==2){
		$db = new SQLiteDatabase(self::db_path); 
		$query = $db->query($strSQL);
	}else{
		$db = new PDO("sqlite:".self::db_path);
		if ($query = $db->prepare($strSQL))
			$query->execute();
	}
	if ($query){
		while ($row = $query->fetch()){
			//print_r($row);
			$task_name=$row['task_name'];	
			foreach (self::$all_colum as $k => $v){
				self::$attribute[$task_name][$v]=$row[$v];
			}
			$tmp[]=self::$attribute[$task_name];
			self::$attribute=$tmp;
		}
	}
	unset($db);
	return self::$attribute;
}

function is_tag($arg){
	if($arg[0]=="["  && $arg[strlen($arg)-1]=="]")
		return true;
	return false;
}

function AddTask($task_name,$task){
	@unlink(self::status_path . "$task_name.status" );
	foreach($task as $k=>$v){
		self::$attribute[$task_name][$k]=$v;
	}
	
	foreach (self::$colum_name as $k => $v){
		$insert_k=$insert_k."'$v',";
		$insert_v=$insert_v."'" . sqlite_escape_string(self::$attribute[$task_name][$v]) ."',";
	}
	$cmd="insert into nsync ({$insert_k}'task_name') values({$insert_v}'" . sqlite_escape_string($task_name )."')";
	if ($this->sqlite_version==2){
		$db = sqlite_open(self::db_path);
		sqlite_query($db,$cmd);
		sqlite_close($db);
	}else{
		$db = new PDO("sqlite:".self::db_path);
		$db->exec($cmd);
		unset($db);
	}
	if(file_exists(self::status_path . "{$task_name}.status"))
	@unlink(self::status_path . "{$task_name}.status");
	$this->set_crond();
}

function ModifyTask($old_task_name,$new_task_name,$task){
	foreach(self::$attribute as $k=>$v){
		if($v['task_name']==$old_task_name){
			$old_key=$k;
		}
		if($v['task_name']==$new_task_name){
			$new_key=$k;
		}
	}
	if(trim($old_task_name)!=trim($new_task_name)){
		unset(self::$attribute[$old_key]);
	}
	
	foreach($task as $k=>$v){
		self::$attribute[$new_key][$k]=$v;
	}

	foreach (self::$colum_name as $k => $v){
		$modify_str="{$modify_str} {$v}='" . sqlite_escape_string(self::$attribute[$new_key][$v]) . "',";
	}
	$cmd="update nsync set " . substr($modify_str,0,-1) . "where task_name='". sqlite_escape_string($new_task_name ) ."'";
	if ($this->sqlite_version==2){
		$db = sqlite_open(self::db_path);
		sqlite_query($db,$cmd);
		sqlite_close($db);
	}else{
		$db = new PDO("sqlite:".self::db_path);
		$db->exec($cmd);
		unset($db);
	}
	$this->set_crond();
}

function deleteTask($task_name){
	if(!file_exists(self::status_path . "{$task_name}.status")){
	$cmd="delete from nsync where task_name='". sqlite_escape_string($task_name) ."'";
	if ($this->sqlite_version==2){
		$db = sqlite_open(self::db_path);
		sqlite_query($db,$cmd);
		sqlite_close($db);
	}else{
		$db = new PDO("sqlite:".self::db_path);
		$db->exec($cmd);
		unset($db);
	}
	foreach(self::$attribute as $key=>$v){
		if($v['task_name']==$task_name){
			$taskkey=$key;
			break;
		}
	}
	unset(self::$attribute[$taskkey]);
	@unlink(self::status_path . "{$task_name}.status");
	$this->set_crond();
	}
}

function update_crond(){
		shell_exec("cat /etc/cfg/crond.conf|crontab - -u root");
}

function set_crond(){
	$crond=shell_exec("cat /etc/cfg/crond.conf | grep -v " . self::crond_script);
	$crond_data=explode("\n",$crond);

	$write_out=array();
	foreach (self::$attribute as $task_k=>$task_v){
		if(isset(self::$attribute[$task_k]['folder']))
		  $folder_name=addcslashes($task_v['folder'],"($+{}'^)");
			$write_out[]="{$task_v['crond']} " . self::crond_script . " \"{$task_v['ip']}\" \"{$task_v['username']}\" \"{$task_v['passwd']}\" \"{$task_v['task_name']}\" \"{$folder_name}\" \"{$task_v['manufacturer']}\" \"start\"\n";
	}
	$conf=$crond . join($write_out);
	$fp=fopen("/etc/cfg/crond.conf","wb");
	fwrite($fp,$conf);
	fclose($fp);
	$this->update_crond();
}

}
function add_slash($str){
  $len=strlen($str);
  for($i=0;$i<$len;$i++){
    $char=substr($str,$i,1);
    $a_char=ord($char);
    if($a_char=="34" || $a_char=="36" || $a_char=="92"){
      $char=chr(92).chr($a_char);
    }else{
      $char=chr($a_char);
    }
    $tmp.=$char;
  }
  return $tmp;
}
?>
