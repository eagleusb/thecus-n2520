<?
/*
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if(!$is_function){
  require_once("/var/www/html/inc/function.php");
  check_system("0","access_warning","about");
}
//#######################################################
*/

$import=trim($_GET["import"]);
if($import == "1"){
	shell_exec("/bin/rm -f /tmp/batch");
	move_uploaded_file($_FILES['batch_file']['tmp_name'],'/tmp/batch');
	if(file_exists("/tmp/batch")){
		$strExec="/bin/cat /tmp/batch";
		$batch_content=shell_exec($strExec);
	}else{
		$batch_content="";
	}
	$log=$_FILES['batch_path'];
	//echo '{success:true, content:'.json_encode("aaa").'}';
	echo '{success:true, content:'.json_encode($batch_content).'}';
	exit;
}
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(WEBCONFIG);

$words = $session->PageCode("batch");
$awords = $session->PageCode("localgroup");
//#######################################################
//#     User and Group limit name
//#######################################################
$system_users=array("root","sshd","nobody","ftp","admin");
$system_groups=array("root","bin","sys","tty","daemon","sshd","nobody","nogroup","ftp","admingroup");
//#######################################################

$batch=trim($_POST['batch_content']);
$batch=urldecode($batch);
$batch=stripslashes($batch);
	//return  MessageBox(true,$words['settingTitle'],$batch,"ERROR");

$sign="";
for($c=0;$c<strlen($batch);$c++){
	$char=substr($batch,$c,1);
	//return  MessageBox(true,$words['settingTitle'],ord(substr($batch,5,1)),"ERROR");
	if(ord($char)==13){
		$sign=chr(13);
		break;
	}
}
$sign.=chr(10);
//$sign=chr(13).chr(10);
//$sign=chr(10);
$batch_back=str_replace($sign,";",$batch);
//$batch_back=addslashes($batch_back);
//$batch_back=htmlspecialchars($batch_back,ENT_QUOTES);
//$batch_back=urldecode($batch_back);

	//return  MessageBox(true,$words['settingTitle'],$batch_back,"ERROR");
$batch_file=explode(";",$batch_back);
	//return  MessageBox(true,$words['settingTitle'],count($batch_file),"ERROR");
for($i=0;$i<count($batch_file);$i++){
	if($batch_file[$i]!=""){
		$tmp_batch[]=$batch_file[$i];
	}
}
unset($batch_file);
//return  MessageBox(true,$words['settingTitle'],$tmp_batch["0"],"ERROR");
if(count($tmp_batch)=="0"){
	$topic.="<font color=red>".$words['user_empty']."</font>";
	shell_exec("/img/bin/logevent/event 997 623 error \"\"");
	return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
	exit;
}
$batch_file=$tmp_batch;
$batch_unique=array_unique($batch_file);
//return  MessageBox(true,$words['settingTitle'],count($batch_file).count($tmp_batch).count($batch_unique),"ERROR");
$user_info=array();
$create_user_count="0";
$strExec="/bin/cat /etc/passwd | awk -F':' '{if($3>=" . $webconfig["user_id_limit_begin"] . "){print}}' | wc -l";
$now_user_count=trim(shell_exec($strExec));
$strExec="/bin/cat /etc/group | awk -F':' '{if($3>=" . $webconfig["group_id_limit_begin"] . "){print}}' | wc -l";
$now_group_count=trim(shell_exec($strExec));
//#################################################################
//#	Check data duplicate
//#################################################################
//return  MessageBox(true,$words['settingTitle'],count($batch_unique).count($batch_file),"ERROR");
if(count($batch_unique) != count($batch_file)){
	$topic.="<font color=red>".$words['duplicate']."</font>";
	shell_exec("/img/bin/logevent/event 997 620 error \"\"");
	return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
	exit;
}
//#################################################################
//#	Check item
//#################################################################
for($i=0;$i<count($batch_file);$i++){
	//#################################################################
	//#	Check data format, must have only two ","
	//#################################################################
	$line_format=substr_count($batch_file[$i],",");
	if($line_format!=2){
		//return  MessageBox(true,$words['settingTitle'],$line_format,"ERROR");
		$topic.="<font color=red>".$words["data_format_error"]." (in line ".($i+1).")</font>";
		shell_exec("/img/bin/logevent/event 997 621 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	list($name[],$passwd[],$member[])=explode(",",$batch_file[$i]);
	//#################################################################
	//#	Check user name duplicate
	//#################################################################
	$name_unique=array_unique($name);
	if(count($name_unique)!=count($name)){
		$topic.="<font color=red>".$words['user_duplicate']." (in line ".($i+1).")</font>";
		shell_exec("/img/bin/logevent/event 997 622 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	//#################################################################
	//#	Check System user name
	//#################################################################
	foreach($system_users as $v){
		if($v!=""){
			if($name[$i]==$v){
				$msg=sprintf($words["system_user_limit"],$name[$i]);
				$topic.="<font color=red>".$msg." (in line ".($i+1).")</font>";
				shell_exec("/img/bin/logevent/event 997 647 error \"\" ".escapeshellarg($name[$i]));
				return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
				exit;
			}
		}
	}
	//#################################################################
	//#	Check user name whether empty!
	//#################################################################
	if($name[$i]==""){
		$topic.="<font color=red>".$words['user_empty']." (in line ".($i+1).")</font>";
		shell_exec("/img/bin/logevent/event 997 623 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	//#################################################################
	//#	Check charactory
	//#	return code = 0 => No error
	//#	              1 => Charactor error
	//#	              2 => Length error
	//#################################################################
	$check_name=check_char($words,"name",$name[$i]);
	$check_passwd=check_char($words,"passwd",$passwd[$i]);
	$check_member=check_char($words,"member",$member[$i]);
	//return  MessageBox(true,$words['settingTitle'],"chk = ".$check_member." a = ".$member[$i]." len = ".strlen($member[$i]));
	//#################################################################
	//#	Check user name format
	//#################################################################
	if($check_name){
		if($check_name==1){
			$topic.="<font color=red>".$words['user_error']." (in line ".($i+1).")</font>";
		}else{
			$topic.="<font color=red>".$words['user_lenght_error']." (in line ".($i+1).")</font>";
		}
		shell_exec("/img/bin/logevent/event 997 624 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	//#################################################################
	//#	Check password format
	//#################################################################
	if($check_passwd){
		if($check_passwd==1){
			$topic.="<font color=red>".$words['pwd_worng_rule']." (in line ".($i+1).")</font>";
		}else{
			$topic.="<font color=red>".$words['pwd_lenght_error']." (in line ".($i+1).")</font>";
		}
		shell_exec("/img/bin/logevent/event 997 625 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	//#################################################################
	//#	Check group name format
	//#################################################################
	if($check_member){
		if($check_member==1){
			$topic.="<font color=red>".$words['group_error']." (in line ".($i+1).")</font>";
		}else{
			$topic.="<font color=red>".$words['group_lenght_error']." (in line ".($i+1).")</font>";
		}
		shell_exec("/img/bin/logevent/event 997 626 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	//#################################################################
	//#	Create user name and password array
	//#################################################################
	$user_exist=shell_exec("/bin/cat /etc/passwd | cut -d: -f1 | grep \"${name[$i]}:\"");
	if($user_exist==""){
		$user_info[]=$name[$i].",".$passwd[$i];
		$create_user_count++;
	}
	//#################################################################
	//#	Check user account count
	//#################################################################
	$total_count=$now_user_count+$create_user_count;
	if($total_count > $webconfig["user_limit"]){
		$topic.="<font color=red>".$words['user_limit']."</font>";
		shell_exec("/img/bin/logevent/event 997 627 error \"\"");
		return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
		exit;
	}
	//#################################################################
	//#	Create group member array
	//#################################################################
	$tmp_group=explode(":",$member[$i]);
	for($j=0;$j<count($tmp_group);$j++){
		unset($tmp_user_group);
		unset($group_list);
		//#################################################################
		//#	Check System group name
		//#################################################################
		foreach($system_groups as $v){
			if($v!=""){
				if($tmp_group[$j]==$v){
					$msg=sprintf($words["system_group_limit"],$tmp_group[$j]);
					$topic.="<font color=red>".$msg." (in line ".($i+1).")</font>";
					shell_exec("/img/bin/logevent/event 997 648 error \"\" ".escapeshellarg($tmp_group[$j]));
					return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
					exit;
				}
			}
		}
		$tmp_user_group[]=$name[$i];
		if($tmp_group[$j]==""){
			$tmp_group[$j]="users";
		}
		$tmp_user_group[]=$tmp_group[$j];
		$user_group[]=$tmp_user_group;
		$tmp_group_list[]=$tmp_group[$j];
		$group_list=array_unique($tmp_group_list);
	}
	//#################################################################
	//#     Check group account count
	//#################################################################
	$total_count=$now_group_count+count($group_list);
	if($total_count > $webconfig["group_limit"]){
	  $topic.="<font color=red>".$awords['group_limit']."</font>";
	  return  MessageBox(true,$words['settingTitle'],$topic,"ERROR");
	  exit;
	}
	//#################################################################
}
$create_count=count($user_info);
$uid_data=shell_exec("/bin/cat /etc/passwd | cut -d: -f3");
$uid_array=explode("\n",$uid_data);
$now_uid=1002;
foreach($user_info as $line){
	if($line!=""){
		$line_info=explode(",",$line);
		$name=trim($line_info[0]);
		$passwd=trim($line_info[1]);
		    while(true){
		      if (array_search($now_uid,$uid_array) == ""){
		        break;
		      }else{
		        $now_uid++;
		      } 
		    }
        if (NAS_DB_KEY == 1)
            $strExec="/usr/sbin/adduser -D -G smbusers -s /dev/null -h /dev/null -u ".$now_uid." ".escapeshellarg(${name});
        else
            $strExec="/usr/sbin/adduser -D -G users -s /dev/null -h /dev/null -H -g" . escapeshellarg(${name}) . " " . escapeshellarg(${name});
		$now_uid++;
   	shell_exec($strExec);
		
		$name_tmp=str_replace("'","\'\''",$name);
		$name_tmp=str_replace('"','\"',$name_tmp);
		
		if (NAS_DB_KEY == 1)
            $strExec="/usr/bin/makepasswd -e shmd5 -p ".escapeshellarg($passwd)." | awk '{print \"$name_tmp:\"$2}'|/usr/bin/chpasswd -e";
		else
            $strExec="/usr/bin/passwd " . $name_tmp . " " . escapeshellarg($passwd);
		
		shell_exec($strExec);
		smbUserModify($name,"new",rmPostslash($passwd));
		joinMember("users",$name);
	}
}
for($i=0;$i<count($user_group);$i++){
	$tmp="";
	unset($tmp_group_user);
	if($group_list[$i]==""){
		continue;
	}
	$tmp_group_user[]=$group_list[$i];
	for($j=0;$j<count($user_group);$j++){
		if($user_group[$j][1]==$group_list[$i]){
			if($tmp==""){
				$tmp=$user_group[$j][0];
			}else{
				$tmp=$tmp.",".$user_group[$j][0];
			}
		}
	}
	$tmp_group_user[]=$tmp;
	$group_user[]=$tmp_group_user;
}
for($i=0;$i<count($group_user);$i++){
	if($group_user[$i][0]!="users"){
	     joinMember($group_user[$i][0],$group_user[$i][1]);
	}
}
$topic.=$words['batchSuccess'];
shell_exec("/bin/rm -f /tmp/batch");
shell_exec("/img/bin/logevent/event 997 412 info \"\"");
return  MessageBox(true,$words['settingTitle'],$topic);
exit;


function check_char($words,$flag,$string){
  $string_len=strlen($string);
  if($string_len=="0"){
    return 2;
    exit;
  }elseif($flag=="name" && $string_len>64){
    return 2;
    exit;
  }elseif($flag=="member"){
    $member=explode(":",$string);
    foreach($member as $v){
      if($v==""){
        return 1;
        exit;
      }else{
        $group_length=strlen($v);
        if($group_length>64){
          return 2;
          exit;
        }
      }
    }
  }
  $count="0";
  for($c=0;$c<$string_len;$c++){
    $char=substr($string,$c,1);
    if($flag=="name" && $char==chr(58)){
      return 1;
      exit;
    }
    if($flag=="name" || $flag=="member"){
      //if($char==chr(32) || $char==chr(34) || $char==chr(39) || $char==chr(47) || $char==chr(96)){
      //if($char==chr(32) || $char==chr(34) || $char==chr(42) || $char==chr(44) || $char==chr(47)){
      if($char==chr(32) || $char==chr(42) || $char==chr(44) || $char==chr(47)){
        return 1;
        exit;
      }
      if($char>=chr(59) && $char<=chr(64)){
        return 1;
        exit;
      }
      if($char>=chr(91) && $char<=chr(93)){
        return 1;
        exit;
      }
      if($flag=="name"){
        if($char==chr(58)){
          return 1;
          exit;
        }
      }
      if($flag=="member"){
        if($char==chr(33) || $char==chr(40) || $char==chr(41) || $char==chr(94)){
          return 1;
          exit;
        }
        if($char>=chr(35) && $char<=chr(38)){
          return 1;
          exit;
        }
        if($char>=chr(123) && $char<=chr(126)){
          return 1;
          exit;
        }
      }
    }
    if($flag=="passwd"){
      if($string_len<4 || $string_len>16){
        return 2;
        exit;
      }
      if($char>chr(255)){
        echo $words['pwd_multi_bytes'];
        exit;
      }
      if(!($char>=chr(32) && $char<=chr(126)) || $char==chr(44) || $char==chr(59)){
        return 1;
        exit;
      }
      /*
      if(!(($char>=chr(48) && $char<=chr(57)) || ($char>=chr(65) && $char<=chr(90)) || ($char>=chr(97) && $char<=chr(122)))){
        return 1;
        exit;
      }
      */
    }
  }
  return 0;
}


function rmPostslash($query){
  $query = str_replace("\\\\","\t",$query);
  $query = str_replace("\\","",$query);
  $query = str_replace("\t","\\",$query);
  return $query;
}
?>
