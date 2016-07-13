<?php   
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'stackable.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'function.php');
 
$stack=new stackable();  

$words = $session->PageCode("stackable");
$gwords = $session->PageCode("global");  

if (NAS_DB_KEY == 1){
  $smb_assemble="/img/bin/rc/rc.samba assemble > /dev/null 2>&1"; 
  $folder_path="/raid/stackable";
}else{
  $smb_assemble="/img/bin/rc/rc.samba reload > /dev/null 2>&1"; 
  $folder_path="/raid/data/stackable";
}
$database = SYSTEM_DB_ROOT."stackable.db";
$event="/img/bin/logevent/event";
$save_log="/img/bin/hlog /logfs/hlogfile";
$host_name=trim(shell_exec("hostname"));

$total_folder=array();
$action=trim($_POST["action"]);
$share=trim($_POST["_share"]);

$o_share=trim($_POST["_o_share"]);
  
get_sysconf();

$return_ary = array('ok'=>'onLoad_stackable()');
 
$db = new sqlitedb($database);  
$stack_info=$db->db_get_folder_info("stackable","*","where share='$share'");
if($o_share!=''){
   $o_stack_info=$db->db_get_folder_info("stackable","*","where share='$o_share'");
}
$all_stack_share_name=$db->db_get_folder_info("stackable","share",""); //#	Get stack folder name
$unique_info=$db->db_get_folder_info("stackable","ip,port,iqn","");
unset($db); 
    
  
   
   
  
//#######################################################
//#	Delete stack folder
//#######################################################
if($action=="remove" && $share!="" && $o_share==""){  
  $del_count=count($stack_info); 
  if($del_count<"1"){ 
    return MessageBox(true,$gwords["error"],$words["stack_not_exist"],'ERROR');
  }else{
    $del_info=array();
    foreach($stack_info as $k=>$data){
      $del_info["ip"]=$data["ip"];
      $del_info["port"]=$data["port"];
      $del_info["iqn"]=$data["iqn"];
      $del_info["share"]=$share;
    }
    $stack->set_default_value($del_info);
    $stack->stack_umount();
    $record=$stack->stack_check_session(); 
    if($record!=""){
      $stack->stack_logout($record);
    } 
    
    $db = new sqlitedb($database);  
    $db_return=$db->db_delete("stackable","where share='$share'");
    unset($db);  
    
    if($db_return){
      shell_exec($smb_assemble);  
      shell_exec("/img/bin/rc/rc.initiator cron_check");
      return MessageBox(true,$gwords["success"],$gwords["success"],'INFO','OK',$return_ary);
    }else{ 
      return MessageBox(true,$gwords["error"],$words["delete_failed"],'ERROR');
    }
  }
  
  exit; 
} 

//#######################################################
//#	Format stack target
//#######################################################
if($action=="format" && $share!="" && $o_share==""){  
  $format_count=count($stack_info);
  if($format_count<"1"){
     return MessageBox(true,$gwords["error"],$words["stack_not_exist"]." - [{$_POST['_share']}]",'ERROR');
  }else{
    foreach($stack_info as $k=>$data){
      if($data!=""){
        $format_info=$data;
      }
    }
    $stack->set_default_value($format_info);
    //################################
    //#	Check enabled
    //################################
    if($format_info["enabled"]=="0"){ 
         return MessageBox(true,$gwords["error"],$words["stackable_disabled"]." - [{$_POST['_share']}]",'ERROR');
    }else{
      //################################
      //# Check connect (check session)
      //################################
      $record=$stack->stack_check_session();
      if($record==""){//session not exist
         return MessageBox(true,$gwords["warning"],$words["stackable_connection_failed"]." - 1[{$_POST['_share']}]",'WARNING','OK',$return_ary);
      }else{
        //################################
        //# Check mount stack folder
        //################################
        $check_mount=$stack->check_mount();
        if(!$check_mount){//no mount point
          $format_ret=$stack->stack_format();
          if(!$format_ret){//format success
            $strExec=$event." 997 415 info \"\" \"".$share."\" \"".$host_name."\"";
            shell_exec($strExec);
            $mount_ret=$stack->stack_mount();
            if(!$mount_ret){//mount success
              $strExec=$event." 997 417 info \"\" \"".$share."\" \"".$host_name."\"";
              shell_exec($strExec);
              $stack->set_default_acl();
              shell_exec($smb_assemble);
              $Mesg=$words[$action."_stack_success"]." - [{$_POST['_share']}]";
              if($_POST['_guest_only']=='no'){
                  $Mesg.="- (".$words["add_stack_prompt"].")";
              } 
              return MessageBox(true,$gwords["success"],$Mesg,'INFO','OK',$return_ary); 
            }else{//mount failed
              $strExec=$event." 997 418 info \"\" \"".$share."\" \"".$host_name."\"";
              shell_exec($strExec);
               return MessageBox(true,$gwords["warning"],$words["unknow_file_system"]." - [{$_POST['_share']}]",'WARNING','OK',$return_ary);
            }
          }else{//format failed
            $strExec=$event." 997 416 info \"\" \"".$share."\" \"".$host_name."\"";
            shell_exec($strExec);
            return MessageBox(true,$gwords["error"],$words["format_failed"]." - [{$_POST['_share']}]",'ERROR');
          }
        }else{//have mount point
          return MessageBox(true,$gwords["error"],$words["mount_warning"]." - [{$_POST['_share']}]",'ERROR');
        }
      }
    }
  }
  $Mesg=$words[$action."_stack_success"]." - [{$_POST['_share']}]";
  if($_POST['_guest_only']=='no'){
      $Mesg.="- (".$words["add_stack_prompt"].")";
  } 
  
  
  return MessageBox(true,$gwords["success"],$Mesg,'INFO','OK',$return_ary); 
  exit;
} 
  
//#######################################################
//#	Reconnect stack target
//#######################################################
if($action=="reconnect" && $share!="" && $o_share==""){ 
  $reconnect_count=count($stack_info);
  if($reconnect_count<"1"){
     return MessageBox(true,$gwords["error"],$words["stack_not_exist"]." - [{$_POST['_share']}]",'ERROR');
  }else{
    foreach($stack_info as $k=>$data){
      if($data!=""){
        $reconnect_info=$data;
      }
    }
    $stack->set_default_value($reconnect_info); 
    //################################
    //#	Check enabled
    //################################
    if($reconnect_info["enabled"]=="0"){
         return MessageBox(true,$gwords["error"],$words["stackable_disabled"]." - [{$_POST['_share']}]",'ERROR');
    }else{
      //################################
      //# Check connect (check session)
      //################################
      $record=$stack->stack_check_session();
      if($record==""){//session not exist
        $connect_ret=$stack->stack_connect();//reconnect
        if($connect_ret!="0"){//connect failed
         return MessageBox(true,$gwords["warning"],$words["stackable_connection_failed"]." - [{$_POST['_share']}]",'WARNING','OK',$return_ary);
        }
      }
      //################################
      //# Mount stack folder
      //################################
      $check_mount=$stack->check_mount();
      if(!$check_mount){//no mount point
        $mount_ret=$stack->stack_mount();//0=ok,1=false
        if($mount_ret){//mount failed
          $strExec=$event." 997 418 info \"\" \"".$share."\" \"".$host_name."\"";
          shell_exec($strExec);
          return MessageBox(true,$gwords["warning"],$words["unknow_file_system"]." - [{$_POST['_share']}]",'WARNING','OK',$return_ary);
        }else{//mount success
          $strExec=$event." 997 417 info \"\" \"".$share."\" \"".$host_name."\"";
          shell_exec($strExec);
          $stack->set_default_acl();
          shell_exec($smb_assemble);
          $Mesg=$words[$action."_stack_success"]." - [{$_POST['_share']}]";
          if($_POST['_guest_only']=='no'){
              $Mesg.="- (".$words["add_stack_prompt"].")";
          } 
          return MessageBox(true,$gwords["success"],$Mesg,'INFO','OK',$return_ary); 
        }
      }else{//have mount point
         return MessageBox(true,$gwords["error"],$words["mount_warning"]." - [{$_POST['_share']}]",'ERROR');
      }
    }
  }
  $Mesg=$words[$action."_stack_success"]." - [{$_POST['_share']}]";
  if($_POST['_guest_only']=='no'){
      $Mesg.="- (".$words["add_stack_prompt"].")";
  } 
  return MessageBox(true,$gwords["success"],$Mesg,'INFO','OK',$return_ary); 
  exit;
}
 
//#######################################################
//#  Get stack folder info from database (for old value)
//#######################################################
if($action=="edit" && $o_share!="" && $share!=""){ 
  if($o_stack_info==""){ 
    return MessageBox(true,$gwords["error"],$words["access_error"],'ERROR');
  }
  $o_enabled=trim($o_stack_info[0]["enabled"]);
  $o_username=trim($o_stack_info[0]["user"]);
  $o_password=trim($o_stack_info[0]["pass"]);
  $o_comment=trim($o_stack_info[0]["comment"]);
  $o_browseable=trim($o_stack_info[0]["browseable"]);
  $o_guest_only=trim($o_stack_info[0]["guest_only"]);
  $o_quota_limit=trim($o_stack_info[0]["quota_limit"]);
}
 

//#######################################################
//#     Setting POST value and insert and update array
//#######################################################
$enabled=trim($_POST["_enable"]);
$target_ip=($_POST["_target_ip"]=="")?trim($stack_info[0]["ip"]) : trim($_POST["_target_ip"]);
$target_port=($_POST["_target_port"]=="")?trim($stack_info[0]["port"]) : trim($_POST["_target_port"]);
$iqn=($_POST["_iqn_select"]=="")?trim($stack_info[0]["iqn"]) : trim($_POST["_iqn_select"]);
$username=trim($_POST["_username"]);
$password=trim($_POST["_password"]);
$share=trim($_POST["_share"]);
$o_share=trim($_POST["_o_share"]);
$comment=trim($_POST["_comment"]);
$browseable=trim($_POST["_browseable"]);
$guest_only=trim($_POST["_guest_only"]);
$quota_limit=trim($_POST["_quota_limit"]);

if(!$validate->check_username($username) && $username!=''){
  $uwords = $session->PageCode('localuser');
   return MessageBox(true,$gwords['error'],$uwords['user_error'],'ERROR');
}

$aswords = $session->PageCode('addshare');
if(empty($share)){
     return MessageBox(true,$gwords['error'],$aswords['ERROR_SHARENAME_BLANK'],'ERROR');
}
if(!$validate->check_stackablefolder($share) && $share!=''){
  return MessageBox(true,$gwords['error'],$validate->errmsg,'ERROR'); 
} 


//#######################################################
//#	Get total folder name
//#######################################################

$total_folder=get_total_folder(); 
  
$stack_count=count($all_stack_share_name);
//#######################################################
//#	Check POST folder name (duplicate)
//#######################################################
foreach($total_folder as $folder){
  if($folder!="" && strtolower($folder)!=strtolower($o_share)){
    if(strtolower($share)==strtolower($folder)){
      foreach($all_stack_share_name as $data){
        if($data!=""){
          if(strtolower($share)==strtolower($data["share"])){
            return MessageBox(true,$gwords["error"],$words["stack_duplicate"]." - [{$_POST['_share']}]",'ERROR');
          }
        }
      }
      return MessageBox(true,$gwords["error"],$words["share_duplicate"]." - [{$_POST['_share']}]",'ERROR');
    }
  }
}

$ret=$validate->in_system_folder($share);
if($ret){
	return MessageBox(true,$gwords["error"],$words["share_duplicate"]." - [{$_POST['_share']}]",'ERROR');	
}

//#######################################################
//#	Check IP+Port+iqn is unique
//#######################################################
if($action=="add" && $share!="" && $o_share==""){
  $unique_item="$target_ip,$target_port,$iqn";
  foreach($unique_info as $k=>$data){
    if($data!=""){
      $compare_item=$data["ip"].",".$data["port"].",".$data["iqn"];
      if($unique_item==$compare_item){
        return MessageBox(true,$gwords["error"],$words["unique_ip_port_iqn"]." - [{$_POST['_share']}]",'ERROR');
      }
    }
  }
  //#######################################################
  //#	Check Stackable add limit
  //#######################################################
  if($stack_count>=$sysconf["stackable"]){
     $msg=sprintf($words["add_stack_limit"],$sysconf["stackable"]);
     return MessageBox(true,$gwords["error"],$msg,'ERROR');
  }
}

//#######################################################
//#	Setting stackable class default value
//#######################################################
$class_info=array();
$class_info["ip"]=$target_ip;
$class_info["port"]=$target_port;
$class_info["iqn"]=$iqn;
$class_info["user"]=$username;
$class_info["pass"]=$password;
$class_info["share"]=$share;
$class_info["guest_only"]=$guest_only;
$class_info["o_guest_only"]=$o_guest_only;
$stack->set_default_value($class_info);
//#######################################################
//#	Start to setting stackable info
//#######################################################
//#  Check whether update database and restart samba
//#######################################################
$update_db="";
$restart="";
$compare_all = array("enabled","username","password","share","browseable","comment","guest_only");
$compare_1 = array("enabled","share","username","password");
$compare_2 = array("browseable","comment","guest_only");
foreach($compare_1 as $v){
  if(${$v}!=${"o_".$v}){
    $update_db="1";
    $restart="1";
    if($v=="share"){
      $stack->stack_umount();
    }
    if($v=="username" || $v=="password"){
      $record=$stack->stack_check_session();
      $stack->stack_logout($record);
    }
    break;
  }
}
foreach($compare_2 as $v){
  if(${$v}!=${"o_".$v}){
    $update_db="1";
    break;
  }
}
//#######################################################
//#	Setting stackable database command
//#######################################################
$set="enabled='".$enabled."',user='".$username."',pass='".$password."',share='".$share."',";
$set.="comment='".$comment."',browseable='".$browseable."',guest_only='".$guest_only."'";
$where="where share='".$o_share."'";
$columns="enabled,ip,port,iqn,user,pass,share,comment,browseable,guest_only";
$values="'".$enabled."','".$target_ip."','".$target_port."','".$iqn."','".$username."','".$password."',";
$values.="'".$share."','".$comment."','".$browseable."','".$guest_only."'";
//#######################################################
//#	Update database (edit)
//#######################################################
if($action=="edit" && $update_db=="1"){   
  $db = new sqlitedb($database);  
  $db_return=$db->db_update('stackable',$set,$where);
  unset($db);      
  
  if(!$db_return){ 
    return MessageBox(true,$gwords["error"],$words[$action."_stack_error"]." - [{$_POST['_share']}]",'ERROR'); 
  }
}
//#######################################################
//#	Check disabled
//#######################################################
 
if($enabled=="0"){
  if($action=="add" && $o_share=="" && $share!=""){ 
    $db = new sqlitedb($database);  
    //$db_exist=$db->db_get_single_value('stackable',"count(*)","where share='$share'"); 
    $db_exist_array=$db->runSQL("select count(*) from stackable where share='$share'"); 
    $db_exist=$db_exist_array[0];
    if($db_exist=="0"){
      $db_return=$db->db_insert("stackable",$columns,$values);
    }
    unset($db);
    $record=$stack->stack_check_session();
    if($record!=""){
      $stack->stack_logout($record);
    }
    if($db_return){ 
       return MessageBox(true,$gwords["warning"],$words["stackable_disabled"]." - [{$_POST['_share']}]",'WARNING','OK',$return_ary); 
    }else{
        return MessageBox(true,$gwords["error"],$words[$action."stack_error"]." - [{$_POST['_share']}]",'ERROR'); 
    }
  }else{
    $record=$stack->stack_check_session();
    if($record!=""){
      $stack->stack_umount();
      $stack->stack_logout($record);
    }
    shell_exec($smb_assemble);
    shell_exec("/img/bin/rc/rc.initiator cron_check");
    return MessageBox(true,$gwords["warning"],$words["stackable_disabled"]." - [{$_POST['_share']}]",'WARNING','OK',$return_ary); 
  }
}


//#######################################################
//#	Beginning connect
//#######################################################
$record=$stack->stack_check_session();
if($record=="0"){//session not exist
  $connect_ret=$stack->stack_connect();
  if($connect_ret!="0"){ 
    return MessageBox(true,$gwords["error"],$words["stackable_connection_failed"]." - [{$_POST['_share']}]",'ERROR');  
  }
}
 
//#######################################################
//#	Mount stack folder into system
//#######################################################
$check_mount=$stack->check_mount();
if(!$check_mount){//no mount point
  $mount_ret=$stack->stack_mount();
  if($mount_ret!="0"){//mount failed
    if($action=="add" && $o_share=="" && $share!=""){ 
      $db = new sqlitedb($database,'stackable');   
      $db_return=$db->db_insert("stackable",$columns,$values); 
      unset($db); 
    }
    $strExec=$event." 997 418 info \"\" \"".$share."\" \"".$host_name."\"";
    shell_exec($strExec);
    shell_exec("/img/bin/rc/rc.initiator cron_check");
    return MessageBox(true,$gwords["warning"],$words["unknow_file_system"]." - [{$_POST['_share']}]",'WARNING','OK',$return_ary);  
  }else{//mount success
    $strExec=$event." 997 417 info \"\" \"".$share."\" \"".$host_name."\"";
    shell_exec($strExec);
    $stack->set_default_acl();
  }
}else{
  if($guest_only!=$o_guest_only){
    $stack->set_acl();
  }
}
//#######################################################
//#	Insert database (add)
//#######################################################
if($action=="add" && $o_share=="" && $share!=""){
    $db = new sqlitedb($database);  
    //$db_exist=$db->db_get_single_value('stackable',"count(*)","where share='$share'"); 
    $db_exist_array=$db->runSQL("select count(*) from stackable where share='$share'"); 
    $db_exist=$db_exist_array[0];
    if($db_exist=="0"){
      $db_return=$db->db_insert("stackable",$columns,$values);
    }
    unset($db); 
  if($db_return!="1"){
     return MessageBox(true,$gwords["error"],$words[$action."_stack_error"]." - [{$_POST['_share']}]",'ERROR'); 
  }
}
//#######################################################
shell_exec($smb_assemble);

shell_exec("/img/bin/rc/rc.initiator cron_check");
$Mesg=$words[$action."_stack_success"]." - [{$_POST['_share']}]";
return MessageBox(true,$gwords["success"],$Mesg,'INFO','OK',$return_ary); 
   /*
   return MessageBox(true,$gwords['error'],'1','ERROR');
 
 */
    
?> 
