<?
/*
session_start();
require_once("../../inc/security_check.php");
check_admin($_SESSION);
require_once("../setlang/lang.html");

$words = PageCode("nsync");

$is_function=function_exists("check_system");
if($is_function){
  if(!isset($_REQUEST['act'])){
    check_url();
  }
  check_raid();
}else{
  require_once("../../inc/function.php");
  check_system("0","access_warning","about");
}
*/
//###############################################
//#     Check database and column
//###############################################
//require_once(DOC_ROOT.'utility/transferDB.class.php');
//$trans=new transDB();
//$trans->trans_bat("nsync_inprogress","nsync");
//exit;

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'nsync.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'info/SeparatePageAssistant.class.php');
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

$gwords = $session->PageCode("global");
$words = $session->PageCode("nsync");

$db_tool=new sqlitedb(SYSTEM_DB_ROOT."conf.db","nsync");
$db_tool->db_open();
$sql="select * from nsync";
$db_list=$db_tool->runSQLAry($sql);

if($db_list[0]['task_name']==""){
	$db_tool->db_alter2("nsync","nsync_mode","");
}else{
	foreach($db_list as $key=>$info){
		if($info != ""){
			if($info["nsync_mode"]==""){
				$db_tool->db_alter2("nsync","nsync_mode","0");
				break;
			}
		}
	}
}
$db_tool->db_close();
//###############################################

$nsync_task=new nsync();
$nsync_list=$nsync_task->GetNsyncList();
//echo "<pre>";print_r($nsync_list);exit;

$start=$_POST['start'];
$limit=$_POST['limit'];
$action=($_POST["action"])?trim($_POST["action"]):trim($_GET["action"]);

if($_POST["action"]=="add" || $_POST["action"]=="edit" || $_POST["action"]=="test"){
	$task_name=trim($_POST['task_name']);
	$manufacturer=trim($_POST['manufacturer']);
	$ip=trim($_POST['ip']);
	$task_id=trim($_POST['task_id']);
	$pwd=trim($_POST['task_pwd']);
	if($_POST["action"]=="add"){
	   if (count($nsync_list)>=$sysconf["nsync_task_limit"]){
		die(
			json_encode(
				array(
					'task_name'=>"0"
				)
			)
		);
	   }
	
		$new_task_name="Nsync_task_".(count($nsync_list)+1);
		die(
			json_encode(
				array(
					'task_name'=>$new_task_name
				)
			)
		);
	}elseif($_POST["action"]=="edit"){
		foreach($nsync_list as $key=>$val){
			//echo $val["task_name"];
			if($val["task_name"]==$task_name){
				$edit_item=$val;
				break;
			}
		}
		$manufacturer=trim($edit_item["manufacturer"]);
		$ip=trim($edit_item["ip"]);
		$folder=trim($edit_item["folder"]);
		$username=trim($edit_item["username"]);
		$passwd=trim($edit_item["passwd"]);
		$crond=trim($edit_item["crond"]);
		$crond=explode(" ",str_replace("\n","",$crond));
		if (strncmp($crond[0],"#",1) == 0){
			$min=substr(trim($crond[0]), 1);
			$nsync_schedule="0";
		}else{
			$nsync_schedule="1";
			$min=trim($crond[0]);
		}
		$hour=trim($crond[1]);
		$time="${hour}:${min}";
		$day=trim($crond[2]);
		$week=trim($crond[4]);
		
		$nsync_mode=trim($edit_item["nsync_mode"]);
		die(
			json_encode(
				array(
					'task_name'=>$task_name,
					'manufacturer'=>$manufacturer,
					'ip'=>$ip,
					'folder'=>$folder,
					'username'=>$username,
					'passwd'=>$passwd,
					'crond'=>$crond,
					'nsync_schedule'=>$nsync_schedule,
					'time'=>$time,
					'day'=>$day,
					'week'=>$week,
					'nsync_mode'=>$nsync_mode
				)
			)
		);
	}elseif($_POST["action"]=="test"){
		$msg="";
		if($ip=="" || !$validate->ip_address($ip)){
		//if($_POST['ip']==""){
			$msg.=$words['nsync_ip_err'];
		}
		//if(($task_id=="") || !$validate->check_username($task_id) || ($pwd=="") || !$validate->check_userpwd($pwd)){
		if(($task_id=="") || ($pwd=="")){
			if($msg==""){
				$msg.=$words['nsync_auth_empty'];
			}else{
				$msg.="\n".$words['nsync_auth_empty'];
			}
		}
		
		shell_exec("echo \"source=" . $pwd . "\" > /tmp/nsync.test1");
		$pwd=stripslashes($pwd);
		$len=strlen($pwd);
		shell_exec("echo ".$len."  >> /tmp/nsync.test1");
		for($i=0;$i<$len;$i++){
			$char=substr($pwd,$i,1);
			$a_char=ord($char);
			shell_exec("echo \"" . $a_char . "\" >> /tmp/nsync.test1");
			if($a_char=="34" || $a_char=="92"){
				$char=chr(92).chr($a_char);
			}elseif($a_char=="36"){
				$char=chr(92).chr($a_char);
			}else{
				$char=chr($a_char);
			}
			$tmp.=$char;
			shell_exec("echo \"tmp=" . $tmp . "\" >> /tmp/nsync.test1");
		}
		$pwd="\"".$tmp."\"";
		shell_exec("echo \"" . $pwd . "\" >> /tmp/nsync.test1");
		if($msg!=""){
			send_msg($msg);
		}
		$msg="/img/bin/nsync/nsync_test.sh"." '".$ip."' '".$manufacturer."' '".$task_name."' '".$task_id."' ".$pwd;
		shell_exec("echo " . $msg . " >> /tmp/nsync.test1");
		shell_exec("echo \"" . $msg . "\" > /tmp/nsync.test");
		$msg=exec($msg);
		send_msg($msg);
	}
}elseif($action=="start"){
	$write_count=0;
	foreach($nsync_list as $k=>$attribute){
		$taskname=$attribute['task_name'];
		if(isset($attribute['folder'])){
			$status_file="/raid/sys/";
			$status_file="${status_file}${taskname}.status";
			if(file_exists("$status_file")){
				$nsync_status=shell_exec("cat \"$status_file\"|grep -i 'status'|awk '{printf $2}'");
				if($nsync_status!="inprogress"){
					$nsync_status=($nsync_status=="")?"inprogress":$nsync_status;
					//$strExec="echo \"status inprogress\" > $status_file";
					//shell_exec($strExec);
					if($nsync_status=="inprogress"){
						$attribute['status']="In Progress";
					}
				}
				if($nsync_status=="start_vpn"){
					$nsync_status="Start VPN";
				}
				if($nsync_status!="inprogress"){
					$attribute['status']=$nsync_status;
				}
				if($nsync_status!="inprogress"){
					$attribute['status']=$nsync_status;
					$attribute['end_time']=date("Y/m/d H:i", filectime($status_file));
					$nsync_task->ModifyTask($taskname,$taskname,$attribute);
					if($nsync_status=="fail"){
						if(file_exists("$status_file")){
							unlink("$status_file");
						}
					}
				}
				$write_count++;
				$attribute['action']="1";
			}else{
                if (NAS_DB_KEY == '1')
                {
                    $strExec="cat /tmp/smb.conf | awk -F' = ' '(/\/".escapeshellstring("awk",$attribute['folder'])."$/||/\/".escapeshellstring("awk",$attribute['folder'])."\//)&&/path = /{print $2}'";
                    //$raidno=trim(shell_exec($strExec));
                }
                elseif (NAS_DB_KEY == '2')
                {
                    $strExec="cat /etc/samba/smb.conf | awk -F' = ' '(/\/".addcslashes($attribute['folder'],"($+{}'^)")."$/||/\/".addcslashes($attribute['folder'],"($+{}'^)")."\//)&&/path = /{print $2}'";
                    //$raidno=trim(shell_exec($strExec));
                }
                
		$folder_path=trim(shell_exec($strExec));
				if(!is_dir($folder_path))
                    $attribute['status']=$words['source_folder_error'];
                
                $attribute['action']="0";
			}
		}
		$nsync_list[$k]=$attribute;
	}
	if($write_count==0){
		$nsync_flag="1";
	}
	$nsync_status=$nsync_list;
	
	/*
	$strExec="select * from nsync";
	$status=$db_tool->runSQLAry($strExec);
	$db_tool->db_close();
	*/
	
	
	die(
		json_encode(
			array(
				'task_name'=>$task_name,
				'nsync_flag'=>$nsync_flag,
				'nsync_status'=>$nsync_status
			)
		)
	);
	
}elseif($_GET["action"]=="getlog"){
	$task_name=rawurldecode($_GET['task_name']);
	$list = array('/var/log/error','/var/log/warning','/var/log/information','/raid/sys/error','/raid/sys/warning','/raid/sys/information');
	$spa = new SeparatePageAssistant($list, 100000, true);
	$page_content = $spa->getPage(1);
	$nsync_log=array();
	foreach ($page_content as $v){
	if(preg_match("/Network Synchronization/",$v) && strstr($v," : Task ".$task_name." ")){		
	//	if(preg_match("/Network Synchronization/",$v) && preg_match("/$task_name/",$v)){
			array_push($nsync_log,array('log_msg'=>$v));
			//array_push($nsync_log,array('log_msg'=>$task_name));
		}
	}
	$total_count=count($nsync_log);
	
	if(($limit+$start) > $total_count){
		$current_count=$total_count;
	}else{
		$current_count=$limit+$start;
	}
	
	if($start!=""){
		shell_exec("echo ${start} > /tmp/test");
		shell_exec("echo ${current_count} >> /tmp/test");
		for($c=$start;$c<$current_count;$c++){
			$log[]=$nsync_log[$c];
		}
	}
	
	die(
		json_encode(
		       	array(
		       		'total_count'=>$total_count,
		       		//'log_data'=>$nsync_log
		       		'log_data'=>$log
		       	)
		)
	);
}elseif($_GET["action"]=="getprogress"){
	$task_name=rawurldecode($_GET['task_name']);
	//$task_name=$_GET['task_name'];
	$nsync_status=shell_exec("cat \"/raid/sys/{$task_name}.status\"|grep 'status' |awk '{printf $2}'");
	$nsync_status=($nsync_status=="")?"in progress":$nsync_status;
	if($nsync_status!="in progress" && !preg_match("/File:/",$nsync_status)) {
		unset($task);
		@unlink("/raid/sys/{$task_name}.status");
		$close="1";
		die(json_encode(array('close'=>$close)));
	}
	foreach($nsync_list as $k=>$attribute){
		if($attribute['task_name']==$task_name){
			$data=$nsync_list[$k];
			break;
		}
	}
	/*
	if(!isset($data['folder'])){
		$close="1";
		die(json_encode(array('close'=>$close)));
	}
	*/
	$pid="/raid/sys/ftp.pid/${task_name}";
	if(!file_exists($pid)){
		$close="1";
		die(json_encode(array('close'=>$close)));
	}
	$task_start_time=date("Y/m/d H:i", filectime($pid));
	$task_progress=shell_exec("cat \"/raid/sys/{$task_name}.status\"|grep -v 'status' |grep -iv 'file'");
	$trans_file=explode("\/",$task_progress);
	$all=$trans_file[1];
	$trans=$trans_file[0];
	unset($trans_file);
	$task_progress="{$trans}/{$all}";
	$proceed=trim(shell_exec("cat \"/raid/sys/{$task_name}.status\"|grep -i 'file'|cut -d\":\" -f2"));
	if($trans=="" || $all==""){
		$task_progress=$gwords["wait_msg"];
		$proceed=$gwords["wait_msg"];
	}

  $rsync_log="/tmp/${task_name}_log";
  if(file_exists($rsync_log)){
    $all=trim(shell_exec("cat \"/tmp/${task_name}_count\""));
    $trans=shell_exec("cat \"${rsync_log}\" | egrep '>f|<f|cd' | awk '{print NR}'| tail -1 ");
    if($trans=="")
      $trans=0;
    $task_progress="{$trans}/{$all}";
    $proceed=shell_exec("cat \"${rsync_log}\" | egrep '>f|<f|cd' | tail -1 | awk -F '\+\+\+\+\+\+\+\+\+ ' '{print \$NF}'"); 
    if($proceed=="")
      $proceed=$gwords["wait_msg"];
  }

	die(
		json_encode(
			array(
				'task_name'=>$task_name,
				'ip'=>$data['ip'],
				'start_time'=>$task_start_time,
				'task_progress'=>$task_progress,
				'proceed'=>$proceed
			)
		)
	);
}
//#################################################
//#	Get share folder
//#################################################
$strExec="sed -nr \"/^\[[^\\n]*\]/p\" /etc/samba/smb.conf";
$smbconf = shell_exec($strExec);
$share_list = explode("\n",$smbconf);
$share_length=count($share_list)-1;
$share=array();
$default_folder="";

for($i=1;$i<$share_length;$i++){
	$share_name=substr($share_list[$i],1,strlen($share_list[$i])-2);
	if($validate->hide_system_folder($share_name)){
		continue;	
	}	
	if(($share_name!="nsync")&&($share_name!="snapshot")&&($share_name!="usbhdd")&&($share_name!="usbcopy")){
		if($default_folder==""){
			$default_folder=$share_name;
		}
		$share[]=array('folder_name'=>$share_name);
	}
}
//$share[]=$tmp;
//echo "<pre>";print_r($share);
//#################################################
//#	Get time value
//#################################################
$day_fields="['display', 'value']";
$day_data="[";
for($i=1;$i <=31;$i++){
	//$_hour = $i < 10 ? "0".$i : $i;
	$_day=$i;
	$day_data .= "['$_day','$_day']";
	if ($i<31)
		$day_data .= ",";
}
$day_data .= "]";

$week_fields="['display', 'value']";
$week_day_list=array(
	"0"=>$gwords['sunday'],
	"1"=>$gwords['monday'],
	"2"=>$gwords['tuesday'],
	"3"=>$gwords['wednesday'],
	"4"=>$gwords['thursday'],
	"5"=>$gwords['friday'],
	"6"=>$gwords['saturday']
);
$week_data="[";
foreach($week_day_list as $value=>$display){
	if($display!=""){
		if($default_week==""){
			$default_week=$display;
		}
		$week_data.="['$display','$value'],";
	}
}
$week_data=substr($week_data,0,strlen($week_data)-1);
$week_data.="]";

$hour_fields="['display', 'value']";
$hour_data="[";
for($i=0;$i < 24;$i++){
	//$_hour = $i < 10 ? "0".$i : $i;
	$_hour=$i;
	$hour_data .= "['$_hour','$_hour']";
	if ($i<23)
		$hour_data .= ",";
}
$hour_data .= "]";

$min_fields="['display', 'value']";
$min_data="[";
for($i=0;$i < 60;$i++){
	//$_min = $i < 10 ? "0".$i : $i;
	$_min=$i;
	$min_data .= "['$_min','$_min']";
	if ($i<59)
		$min_data .= ",";
}
$min_data .= "]";
//echo $min_data;
//echo $day_data."<br>".$hour_data;
//#################################################
//#	Set bandwidth
//#################################################
$bandwidth_fields="['value', 'display']";
$bandwidth_data="[['1gbit','Unlimited'],['512mbit','512 Mbits'],['256mbit','256 Mbits'],['128mbit','128 Mbits'],['100mbit','100 Mbits'],['25mbit','25 Mbits'],['10mbit','10 Mbits'],['1mbit','1 Mbits']]";
//#################################################
//#	Get bandwidth setting
//#################################################
$db = new sqlitedb();
$db->db_open();
$bandwidth=$db->getvar("nsync_qos","1gbit");

if (NAS_DB_KEY == '1')
    $ipshare_enabled=$db->getvar("nic1_ip_sharing","0");
elseif (NAS_DB_KEY == '2')
    $ipshare_enabled=$db->getvar("nic1_nat","0");

$db->db_close();
//#################################################


//$tmp[]=$nsync_list[0];
//$nsync_list[0]['task_name']="Nsync_task_2";
//$tmp[]=$nsync_list[0];

$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setnsync');
$tpl->assign('geturl','getmain.php?fun=nsync');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('default_folder',$default_folder);
$tpl->assign('day_fields',$day_fields);
$tpl->assign('day_data',$day_data);
$tpl->assign('week_fields',$week_fields);
$tpl->assign('week_data',$week_data);
$tpl->assign('default_week',$default_week);
$tpl->assign('hour_fields',$hour_fields);
$tpl->assign('hour_data',$hour_data);
$tpl->assign('min_fields',$min_fields);
$tpl->assign('min_data',$min_data);
$tpl->assign('bandwidth_fields',$bandwidth_fields);
$tpl->assign('bandwidth_data',$bandwidth_data);
$tpl->assign('ipshare_enabled',$ipshare_enabled);
$tpl->assign('default_bandwidth','Unlimited');
$tpl->assign('bandwidth',$bandwidth);
$tpl->assign('nsync',json_encode($nsync_list));
//$tpl->assign('nsync',json_encode($tmp));
//print_r(json_encode($share));
$tpl->assign('folder_list',json_encode($share));
//echo "<pre>";print_r($nsync_list);exit;
$tpl->assign('lang',$session->lang);

function send_msg($msg){
	global $_POST;
	die(
		json_encode(
			array(
				'post'=>$_POST,
				'nsync_test_msg'=>$msg
			)
		)
	);
}
?>
