<?
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$event="/img/bin/logevent/event";
$iscsi_limit_size=16384;
$md_num = $_REQUEST["md"];
$raid_name = "raid".($md_num);
$words = $session->PageCode("raid");
$gwords = $session->PageCode("global");
$space_type = array('iscsi','lun','acl');
//Create
$type = $_POST["now_add_id"];
$type_is_modify = strstr($type,"_modify");
$is_delete = strstr($type,"_delete");

//iSCSI
$target_iscsi = $_POST["target_iscsi"];
$iscsi_name = $_POST["iscsi_name"];
$iscsi_enable = $_POST["enable"];
$iscsi_year = $_POST["iscsi_year"];
$iscsi_month = $_POST["iscsi_month"];

$iscsi_chap = $_POST["auth"];
$iscsi_username = $_POST["username"];
$iscsi_password = $_POST["password"];
$iscsi_cpassword = $_POST["password_comfirm"];
$mutual_iscsi_chap = $_POST["mutual_auth"];

if ($mutual_iscsi_chap == "")
  $mutual_iscsi_chap="0";
$mutual_iscsi_username = $_POST["mutual_username"];
$mutual_iscsi_password = $_POST["mutual_password"];
$mutual_iscsi_cpassword = $_POST["mutual_password_comfirm"];

//LUN
$target_lun=$_POST["target_lun"];
$lun_thin = $_POST["lun_thin"];
$lun_name = $_POST["lun_name"];
$percent = $_POST["percent"];
$lun_id = $_POST["lun_id"];
$lun_block_size=$_POST['advance_iscsi_block_size'];

//iSCSI Advanced
$crc_data = $_POST["crc_data"];
$crc_header = $_POST["crc_header"];
$connection_id= $_POST["connection_id"];
$error_recovery_id= $_POST["error_recovery_id"];
$initR2T_id= $_POST["initR2T_id"];

if ($iscsi_name!=""){
  $fn = array('ok'=>'execute_success("'.$iscsi_name.'")');
}else{
  $fn = array('ok'=>'execute_success("'.$target_iscsi.'")');
}

switch($type){
  case $space_type[0].'_add':
    $title=$words["iscsi_title_create"];
    break;
  case $space_type[1].'_add':
    $title=$words["lun_title_create"];
    break;
  case $space_type[0].'_modify':
    $title=$words["iscsi_title_modify"];
    break;
  case $space_type[1].'_modify':
    $title=$words["lun_title_modify"];
    break;
  case $space_type[1].'_expand':
    $title=$words["lun_title_expand"];
    break;
  default:
    $title=$gwords['iscsi_target']; 
    break;
}
if ($iscsi_name!=""){
    $iscsi_data=$iscsi_name;
}else{
    $iscsi_data=$target_iscsi;
}
$strExec="/img/bin/dataguard/iscsi.sh get_iscsi_use ".($iscsi_data)."";
$iscsi_status=trim(shell_exec($strExec));
if ($iscsi_status=="1"){
   $iscsi_check1="the iscsi name is backup or restore";
   return  array("show"=>true,
                 "topic"=>$title,
                 "message"=>$iscsi_check1,
                 "icon"=>'ERROR',
                 "button"=>'OK',
                 "fn"=>$fn,
                 "prompt"=>'');
}
$status=trim(shell_exec($strExec));
$strExec="/bin/cat /var/tmp/raid".($md_num)."/rss";
$status=trim(shell_exec($strExec));

$class = new RAIDINFO();
$raidinfo = $class->getINFO($md_num);
$md_array=$class->getMdArray();

/*
if($status!="Degraded" && $status!="Healthy" ){
  return  array("show"=>true,
               "topic"=>$title,
               "message"=>$gwords["raid_lock_warning"],
               "icon"=>'ERROR',
               "button"=>'OK',
               "fn"=>$fn,
               "prompt"=>''); 
}
*/
if(trim($type_is_modify) == "" && trim($is_delete) == "" && $type==($space_type[1].'_expand')){
  if($raidinfo["RaidUnUsed"] < "0"){
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["capacity_too_small"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }
}

//#####################################
//##   Sysconf.txt
//#####################################
$iscsi_limit = trim(shell_exec("/img/bin/check_service.sh iscsi_limit"));

//################################
//##    Delete
//################################
if($target_iscsi != "" && trim($is_delete) != ""){
  $strExec = "/img/bin/rc/rc.iscsi delete ".$target_iscsi." ".$md_num;
  shell_exec($strExec);
  shell_exec("/img/bin/rc/rc.iscsi isnsregi del");

  if($type == $space_type[1]."_delete"){
    $strExec = "/img/bin/rc/rc.iscsi del_lun ".$target_iscsi." ".$md_num . " " . $target_lun;  
    shell_exec($strExec);

    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"delete from lun_acl where lunname ='$target_lun'\"";
    shell_exec($strExec);

    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"delete from lun where name='$target_lun'\"";
    shell_exec($strExec);

    $strExec = "/img/bin/rc/rc.iscsi add ".$target_iscsi." ".$md_num;
    shell_exec($strExec);
    $msg=$words["lun_del_success"];
    
    $strExec=$event." 997 462 info \"\" \"Delete\" \"".$target_lun."\" \"".$target_iscsi."\"";
    shell_exec($strExec);
  }else{
    $strExec = "/img/bin/rc/rc.iscsi del_lun ".$target_iscsi." ".$md_num;  
    shell_exec($strExec);
  
    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"delete from lun_acl where lunname in (select name from lun where target='$target_iscsi')\"";
    shell_exec($strExec);

    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"delete from iscsi where name='$target_iscsi'\"";
    shell_exec($strExec);

    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"delete from lun where target='$target_iscsi'\"";
    shell_exec($strExec);
    $msg=$words["iscsi_del_success"];

    $strExec=$event." 997 461 info \"\" \"Delete\" \"".$target_iscsi."\"";
    shell_exec($strExec);
  }

  shell_exec("/img/bin/rc/rc.iscsi isnsregi");
  return array("show"=>true,
               "topic"=>$title,
               "message"=>$msg,
               "icon"=>'INFO',
               "button"=>'OK',
               "fn"=>$fn,
               "prompt"=>'');     
}

//################################
//##    Create/Modify iSCSI and LUN
//################################
if(($type == ($space_type[1]."_add")) || ($type == ($space_type[1]."_modify")) || ($type == ($space_type[1]."_expand"))){
  if($type == ($space_type[1]."_add")){
    if(!$validate->check_iscsi_targetname($lun_name) || $lun_name==''){  
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["lun_name_err"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(6)'),
                    "prompt"=>'');   
    }
    
    $lun_count=0;
    foreach($md_array as $md_id){
      $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from lun where name='$lun_name'\"";
      $lun_count=$lun_count+trim(shell_exec($strExec));
    }
  
    if($lun_count > 0){
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["lun_name_dup"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(6)'),
                    "prompt"=>''); 
    }
    
    $iscsi_serial=trim(shell_exec("/usr/bin/uuidgen"));
    $uuid_ok=0;
    while ($uuid_ok==0){
      //check if uuid is existed
      foreach($md_array as $md_id){
        $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from lun where serial='$iscsi_serial'\"";
        $uuid_count=trim(shell_exec($strExec));
      }
      
      if ($uuid_count>0){
        $iscsi_serial=trim(shell_exec("/usr/bin/uuidgen"));
      }else{
        $uuid_ok=1;
      }
    }

    $msg_lun_more_16t="";
    if ($percent > $iscsi_limit_size){
      $msg_lun_more_16t="<BR>".$words["lun_more_16t"];
    }
    
    $col="target,name,thin,id,percent,block,serial";
    $values="'".$target_iscsi."','".$lun_name."','".$lun_thin."','".$lun_id."','".$percent."','".$lun_block_size."','".$iscsi_serial."'";
    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"insert into lun(".$col.") values(".$values.")\"";
    shell_exec($strExec);

    shell_exec("/img/bin/rc/rc.iscsi add_lun ".$target_iscsi." ".$md_num . " " . $lun_name. " > /dev/null 2>&1 &");
    
    $strExec=$event." 997 462 info \"\" \"Create\" \"".$lun_name."\" \"".$target_iscsi."\"";
    shell_exec($strExec);
    
    shell_exec("sleep 3");
    $msg=$words["lun_title_create_success"]." ".$words["addlunPrompt"]." ".$msg_lun_more_16t;

    return  array("show"=>true,
                  "type"=>"",
                  "topic"=>$title,
                  "message"=>$msg,
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
  }elseif ($type == ($space_type[1]."_modify")){
    $strExec = "/img/bin/rc/rc.iscsi delete ".$target_iscsi." ".$md_num;
    shell_exec($strExec);

    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"update lun set id='".$lun_id."' where name='".$target_lun."'\"";
    shell_exec($strExec);

    $strExec = "/img/bin/rc/rc.iscsi add ".$target_iscsi." ".$md_num;
    shell_exec($strExec);
    $msg=$words["lun_title_modify_success"];
    
    $strExec=$event." 997 462 info \"\" \"Modify\" \"".$target_lun."\" \"".$target_iscsi."\"";
    shell_exec($strExec);
  }elseif ($type == ($space_type[1]."_expand")){
    $strExec = "/img/bin/rc/rc.iscsi delete ".$target_iscsi." ".$md_num;
    shell_exec($strExec);
    
    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select percent from lun where name='".$target_lun."'\"";
    $percent=$percent+trim(shell_exec($strExec));

    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"update lun set percent='".$percent."' where name='".$target_lun."'\"";
    shell_exec($strExec);

    shell_exec("/img/bin/rc/rc.iscsi expand_lun ".$target_iscsi." ".$md_num . " " . $target_lun . " > /dev/null 2>&1 &");

    $strExec=$event." 997 462 info \"\" \"Expand\" \"".$target_lun."\" \"".$target_iscsi."\"";
    shell_exec($strExec);
    
    shell_exec("sleep 3");
    $msg=$words["lun_title_expand_success"];

    return  array("show"=>true,
                  "type"=>"",
                  "topic"=>$title,
                  "message"=>$msg,
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
  }

  return array("show"=>true,
               "topic"=>$title,
               "message"=>$msg,
               "icon"=>'INFO',
               "button"=>'OK',
               "fn"=>$fn,
               "prompt"=>''); 
}elseif ($type == ($space_type[0]."_expand")){
  $strExec = "/img/bin/rc/rc.iscsi delete ".$target_iscsi." ".$md_num;
  shell_exec($strExec);
  
  $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"update iscsi set crc_data='$crc_data',crc_header='$crc_header',v1='$connection_id',v2='$error_recovery_id', v3='$initR2T_id' where name='$target_iscsi'\"";
  shell_exec($strExec);
  
  $strExec = "/img/bin/rc/rc.iscsi add ".$target_iscsi." ".$md_num;
  shell_exec($strExec);

  return array("show"=>true,
               "topic"=>$title,
               "message"=>$words["advanced_setting_success"],
               "icon"=>'INFO',
               "button"=>'OK',
               "fn"=>$fn,
               "prompt"=>''); 
}else{
  if(!$validate->check_iscsi_targetname($iscsi_name) || $iscsi_name==''){  
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["iscsi_name_err"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(2)'),
                  "prompt"=>'');   
  }
  
  if($iscsi_chap){
    if(!$validate->check_iscsi_username($iscsi_username) || $iscsi_username==''){
      return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["username_err"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(3)'),
                  "prompt"=>'');   
    }
    
    if(!$validate->limitstrlen(12,16,$iscsi_password)){
      return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["warn_password_length"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(4)'),
                  "prompt"=>'');  
    
    }
    
    
    if(!$validate->check_iscsi_password($iscsi_password) || $iscsi_password==""){
      return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["warn_password"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(4)'),
                  "prompt"=>'');  
    
    }

    if(trim($iscsi_cpassword)!=trim($iscsi_password)){
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["warn_password_confirm"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(1)'),
                    "prompt"=>'');  
    }  
  }

  if($mutual_iscsi_chap){
    if(!$validate->check_iscsi_username($mutual_iscsi_username) || $mutual_iscsi_username==''){
      return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["mutual_username_err"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(3)'),
                  "prompt"=>'');   
    }
    
    if(!$validate->limitstrlen(12,16,$mutual_iscsi_password)){
      return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["warn_password_length"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(4)'),
                  "prompt"=>'');  
    
    }
    
    if(!$validate->check_iscsi_password($mutual_iscsi_password) || $mutual_iscsi_password==""){
      return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["warn_password"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>array('ok'=>'error_status(4)'),
                  "prompt"=>'');  
    
    }

    if(trim($mutual_iscsi_cpassword)!=trim($mutual_iscsi_password)){
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["mutual_warn_password_confirm"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(1)'),
                    "prompt"=>'');  
    }  
  }
  
  $iscsi_count="0";
  foreach($md_array as $md_id){
    $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from iscsi\"";
    $iscsi_count=$iscsi_count+trim(shell_exec($strExec));
  }
  $limit_count = $iscsi_limit;
  
  if($iscsi_count >= $limit_count && $target_iscsi == ""){
    $msg = sprintf($words["iscsi_too_more"],$limit_count);
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$msg,
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }


  if ($iscsi_name!=$target_iscsi){
    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select count(name) from iscsi where name='$iscsi_name'\"";
    $iscsi_name_count = trim(shell_exec($strExec));
    if($iscsi_name_count != 0){
      return  MessageBox(true,$title,$words["iscsi_name_duplicate"],'ERROR','OK');    
    }
  }
  
  if($target_iscsi == ""){
      $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select * from iscsi where name='$iscsi_name'\"";
  }else{
      $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select * from iscsi where name='$target_iscsi'\"";
  }

  $iscsi_exist = shell_exec($strExec);

  if($iscsi_exist != ""){
    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select name,enabled,chap,user,pass,chap_mutual,user_mutual,pass_mutual,year,month from iscsi where name='$target_iscsi'\"";
    $db_data = shell_exec($strExec);
    $new_data = $iscsi_name."|".$iscsi_enable."|".$iscsi_chap."|".$iscsi_username."|".$iscsi_password."|".$mutual_iscsi_chap."|".$mutual_iscsi_username."|".$mutual_iscsi_password."|".$iscsi_year."|".$iscsi_month;
    if(trim($db_data) != trim($new_data)){
      if ($iscsi_name != $target_iscsi){
        $iscsi_folder_dup="0";
        $iscsi_stackable_dup="0";
        foreach($md_array as $md_id){
            $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(share) from smb_userfd where share='iSCSI_". $iscsi_name ."'\"";
            $iscsi_folder_dup=$iscsi_folder_dup+trim(shell_exec($strExec));
        }
                            
        if($iscsi_folder_dup != 0){
            return  MessageBox(true,$title,$words["iscsi_share_dup"],'ERROR','OK');
        }
      
        $strExec = "/usr/bin/sqlite /etc/cfg/stackable.db \"select count(share) from stackable where share='iSCSI_". $iscsi_name ."'\"";
        $iscsi_stackable_dup=$iscsi_folder_dup+trim(shell_exec($strExec));
        if($iscsi_stackable_dup != 0){
            return  MessageBox(true,$title,$words["iscsi_stackable_dup"],'ERROR','OK');
        }
      }

      shell_exec("/img/bin/rc/rc.iscsi delete ".$target_iscsi." ".$md_num);
      shell_exec("/img/bin/rc/rc.iscsi isnsregi del");       

      if ($iscsi_name != $target_iscsi){
        $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"update lun set target='$iscsi_name' where target='$target_iscsi'\"";
        shell_exec($strExec);
        
        $strExec = "/img/bin/user_folder.sh 'modify' 'iSCSI_".$target_iscsi."' '$md' 'iSCSI_".$iscsi_name."'";
        shell_exec($strExec);
      }

      $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"update iscsi set name='$iscsi_name',enabled='$iscsi_enable',chap='$iscsi_chap',user='$iscsi_username',pass='$iscsi_password',chap_mutual='$mutual_iscsi_chap',user_mutual='$mutual_iscsi_username',pass_mutual='$mutual_iscsi_password',year='$iscsi_year',month='$iscsi_month' where name='$target_iscsi'\"";
      shell_exec($strExec);
      
      if(trim($iscsi_enable) == "1"){
        shell_exec("/img/bin/rc/rc.iscsi add ".$iscsi_name." ".$md_num);
        shell_exec("/img/bin/rc/rc.iscsi isnsregi");       
      }

      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["iscsi_modify_success"],
                    "icon"=>'INFO',
                    "button"=>'OK',
                    "fn"=>$fn,
                    "prompt"=>''); 
    }else{
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$gwords["setting_confirm"],
                    "icon"=>'INFO',
                    "button"=>'OK',
                    "fn"=>$fn,
                    "prompt"=>'');       
    }    
  }else{

    if(!$validate->check_iscsi_targetname($lun_name) || $lun_name==''){  
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["lun_name_err"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(6)'),
                    "prompt"=>'');   
    }
  
    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select id from lun where id='$lun_id' and target='$iscsi_name'\"";  
    $check_lunid=shell_exec($strExec);
        
    if(trim($check_lunid) != ""){
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["lun_id_error"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(5)'),
                    "prompt"=>'');       
    }  

    $iscsi_folder_dup="0";
    $iscsi_stackable_dup="0";
    foreach($md_array as $md_id){
      $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(share) from smb_userfd where share='iSCSI_". $iscsi_name ."'\"";
      $iscsi_folder_dup=$iscsi_folder_dup+trim(shell_exec($strExec));
    }
    
    if($iscsi_folder_dup != 0){
      return  MessageBox(true,$title,$words["iscsi_share_dup"],'ERROR','OK');    
    }
    
    $strExec = "/usr/bin/sqlite /etc/cfg/stackable.db \"select count(share) from stackable where share='iSCSI_". $iscsi_name ."'\"";
    $iscsi_stackable_dup=$iscsi_folder_dup+trim(shell_exec($strExec));
    
    if($iscsi_stackable_dup != 0){
      return  MessageBox(true,$title,$words["iscsi_stackable_dup"],'ERROR','OK');    
    }
    
    $lun_count=0;
    $iscsi_count=0;
    foreach($md_array as $md_id){
      $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from lun where name='$lun_name'\"";
      $lun_count=$lun_count+trim(shell_exec($strExec));

      $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from iscsi where name=$iscsi_name'\"";
      $iscsi_count=$iscsi_count+trim(shell_exec($strExec));
    }
  
    if($iscsi_count > 0){
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["iscsi_name_duplicate"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(2)'),
                    "prompt"=>''); 
    }

    if($lun_count > 0){
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["lun_name_dup"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>array('ok'=>'error_status(6)'),
                    "prompt"=>''); 
    }
    
    $col = "name,enabled,chap,user,pass,chap_mutual,user_mutual,pass_mutual,year,month";
    $values = "'".$iscsi_name."','".$iscsi_enable."','".$iscsi_chap."','".$iscsi_username."','".$iscsi_password."','".$mutual_iscsi_chap."','".$mutual_iscsi_username."','".$mutual_iscsi_password."','".$iscsi_year."','".$iscsi_month."'";
    $strExec = "/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"insert into iscsi(".$col.") values(".$values.")\"";
    shell_exec($strExec);
    
    $iscsi_serial=trim(shell_exec("/usr/bin/uuidgen"));
    $uuid_ok=0;
    while ($uuid_ok==0){
      //check if uuid is existed
      foreach($md_array as $md_id){
        $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from lun where serial='$iscsi_serial'\"";
        $uuid_count=trim(shell_exec($strExec));
      }
      
      if ($uuid_count>0){
        $iscsi_serial=trim(shell_exec("/usr/bin/uuidgen"));
      }else{
        $uuid_ok=1;
      }
    }

    $msg_lun_more_16t="";
    if ($percent > $iscsi_limit_size){
      $msg_lun_more_16t="<BR>".$words["lun_more_16t"];
    }

    $col="target,name,thin,id,percent,block,serial";
    $values="'".$iscsi_name."','".$lun_name."','".$lun_thin."','".$lun_id."','".$percent."','".$lun_block_size."','".$iscsi_serial."'";
    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"insert into lun(".$col.") values(".$values.")\"";
    shell_exec($strExec);

    $db=new sqlitedb();
    $iscsi_service=$db->getvar("iscsi","0");
    unset($db);

    if ((trim($iscsi_enable) == "1") && ($iscsi_service == "1")){
      shell_exec("/img/bin/rc/rc.iscsi isnsregi del");
      shell_exec("/img/bin/rc/rc.iscsi add ".$iscsi_name." ".$md_num." > /dev/null 2>&1 &");
      shell_exec("/img/bin/rc/rc.iscsi isnsregi");        
    }else{
      shell_exec("/img/bin/rc/rc.iscsi add_lun ".$iscsi_name." ".$md_num . " " . $lun_name." > /dev/null 2>&1 &");
    }
    
    $strExec=$event." 997 461 info \"\" \"Create\" \"".$iscsi_name."\"";
    shell_exec($strExec);
    shell_exec("sleep 3");
    $msg=$words["iscsi_create_success"]." ".$words["addlunPrompt"].$msg_lun_more_16t;

    return  array("show"=>true,
                  "type"=>"",
                  "topic"=>$title,
                  "message"=>$msg,
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
  }
}

?>
