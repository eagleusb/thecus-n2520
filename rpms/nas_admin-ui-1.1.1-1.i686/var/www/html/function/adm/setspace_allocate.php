<?
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$md_num = $_REQUEST["md"];
$raid_name = "raid".($md_num-1);
$words = $session->PageCode("raid");
$gwords = $session->PageCode("global");
$class = new RAIDINFO();
$raidinfo = $class->getINFO($md_num);
$md_array=$class->getMdArray();
$ismaster = $raidinfo["RaidMaster"];
$space_type = array('iscsi','thin_iscsi','usb','thin_iscsi_mb','advance_form');
//Create
$type = $_POST["now_add_id"];
$type_is_expand = strstr($type,"_expand");
$thin_lv = "thinpool";
$thin_iscsi_lv = "thin";
$type_is_thin_mb = strstr($type,$space_type[3]);
$thin_is_delete = strstr($type,"_delete");
$type_is_thin_space = strstr($type,$space_type[1]);
$session_path= "/proc/net/iet/session";
  
if(trim($type_is_expand) == "")
  if($type == $space_type[3]."_add"){
    $virtual_value = explode(' ',$_POST["virtual_size"]);
    $virtual_size = $virtual_value[0];
    $provision = 1;
  }else{
    $capacitys = explode(' ',$_POST["use_capacity"]);
  }  
else{
  $capacitys = explode(' ',$_POST["expand_capacity"]);
}

$capacity = $capacitys[0];
$percent = $_POST["percent"];

//iSCSI
$max_iscsi = 16;
$iscsi_lv = $_POST["lvname"];
$iscsi_name = $_POST["iscsi_name"];
$iscsi_enable = $_POST["enable"];
$iscsi_chap = $_POST["auth"];
$iscsi_username = $_POST["username"];
$iscsi_password = $_POST["password"];
$iscsi_cpassword = $_POST["password_comfirm"];
$iscsi_year = $_POST["iscsi_year"];
$iscsi_month = $_POST["iscsi_month"];
$lun_id = $_POST["lun_id"];
if($lun_id==""){
  $lun_id=0;
}
//Delete
$lvname = $_POST["lvname"];
$fn = array('ok'=>'execute_success(1)');

switch($type){
  case $space_type[0].'_add':
    $title=$words["iscsi_title_create"];
    break;
  case $space_type[1].'_add':
    $title=$words["thin_space_title_create"];
    break;
  case $space_type[2].'_add':
    $title=$words["usb_title"];  
    break;
  case $space_type[3].'_add':
    $title=$words["thin_iscsi_title_create"];
    break;
  case $space_type[0].'_modify':
    $title=$words["iscsi_title_modify"];
    break;
  case $space_type[3].'_modify':
    $title=$words["thin_iscsi_title_modify"];
    break;
  case $space_type[0].'_expand':
    $title=$words["iscsi_expand_title"];
    break;
  case $space_type[1].'_expand':
    $title=$words["thin_space_title_expand"];
    break;
  default:
    $title=$gwords['space_allocate']; 
    break;
}

function iscsi_space_create($lv){
  global $md_num,$capacity;
  $strExec="/sbin/lvcreate -L ".$capacity."G -n ".$lv." vg".($md_num-1)." 2>&1";
  exec($strExec,$out,$ret);
  if($ret == 0){
    $strExec="dd if=/dev/zero of=/dev/vg".($md_num-1)."/".$lv." bs=1M count=2";
    shell_exec($strExec);
    $strExec="lvdisplay /dev/vg".($md_num-1)."/".$lv." --units m|awk '/LV Size/{printf(\"%d\",$3-1)}'";
    $lv_back_site=trim(shell_exec($strExec));
    $strExec="dd if=/dev/zero of=/dev/vg".($md_num-1)."/".$lv." seek=${lv_back_site} bs=1M count=2";
    shell_exec($strExec);
  }
  return $ret;
}

function delete_iscsi($lvname){
  global $session_path,$md_num;
  $strExec="/img/bin/check_service.sh iscsi_method";
  $check_iscsi=shell_exec($strExec);
  if($check_iscsi == 1){
      $strExec="cat ".$session_path." | awk '/".$lvname.".vg".($md_num-1)."/{print \$1}'";
      $tid_data=shell_exec($strExec);
      $tid_info=explode(":",$tid_data);
      if ($tid_info[1]!=""){
           shell_exec("/img/bin/rc/rc.iscsi delete ".$lvname." ".($md_num-1)." 2>&1");  
      }     
  }elseif($check_iscsi == 2){
      shell_exec("/img/bin/rc/rc.iscsi delete ".$lvname." ".($md_num-1)." 2>&1");
  }else{
      echo "ERROR!!";
      return 1;
  }
}

$strExec="/bin/cat /var/tmp/raid".($md_num-1)."/rss";
$status=trim(shell_exec($strExec));

if($status!="Degraded" && $status!="Healthy" ){
  return  array("show"=>true,
               "topic"=>$title,
               "message"=>$gwords["raid_lock_warning"],
               "icon"=>'ERROR',
               "button"=>'OK',
               "fn"=>$fn,
               "prompt"=>''); 
}

if(trim($type_is_thin_mb) == "" && trim($thin_is_delete) == ""){
  if($raidinfo["RaidUnUsed"] < "0"){
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["capacity_too_small"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }
  
  if($capacity < 1){
    if($type == "iscsi_expand")
      $msg = $words["expand_fail"];
    else
      $msg = $words["capacity_too_small"];
    
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$msg,
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }
}elseif($type == $space_type[3]."_add" && trim($thin_is_delete) == ""){
   if($virtual_size < 1){
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
$thin_iscsi_limit = trim(shell_exec("/img/bin/check_service.sh thin_provision"));
//#####################################

//################################
//##    Delete
//################################
if($lvname != "" && trim($thin_is_delete) != ""){
  $mnt = "/mnt/iscsi/raid".($md_num-1)."/".$thin_lv."/";
  
  if($ismaster && $lvname == "lv1"){
    shell_exec("killall file-storage-ga");
    shell_exec("rmmod g_file_storage");
  }
  
  if ($type == $space_type[1]."_delete"){
    $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select lvname from iscsi where v1='1'\"";
    $thin_mb_info=shell_exec($strExec);
    $thin_list=explode("\n",$thin_mb_info);
    foreach ($thin_list as $v){     
      if($v !="")      
        delete_iscsi($v);        
    }
    shell_exec("umount /mnt/iscsi/raid".($md_num-1)."/thinpool");   
    $strExec = "/sbin/lvremove -f /dev/vg".($md_num-1)."/".$lvname." 2>&1";
    exec($strExec,$out,$ret);
  }elseif (trim($type_is_thin_mb) == ""){       
    delete_iscsi($lvname);
    $strExec = "/sbin/lvremove -f /dev/vg".($md_num-1)."/".$lvname." 2>&1";
    exec($strExec,$out,$ret);
  }else{
    delete_iscsi($lvname);
    $strExec = "/bin/rm -f ".$mnt.".".$lvname.".img";
    exec($strExec,$out,$ret);
  }  
  //foreach($out as $v){
  //  $output=$v;
  //}
  if($ret == "0"){
    if($lvname == "lv1"){
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"update conf set v='0' where k='percent_tu'\"";
      shell_exec($strExec);
      $msgbox= array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["usb_del_success"],
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
    }elseif($type == $space_type[1]."_delete"){
      $strExec = "/bin/rm -rf ".$mnt;
      exec($strExec,$out,$ret);
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"delete from iscsi where v1='1'\"";
      shell_exec($strExec);
      shell_exec("/img/bin/iscsi_assemble.sh");
      $msgbox= array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["thin_del_success"],
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');                
    }else{
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"delete from iscsi where lvname='$lvname'\"";
      shell_exec($strExec);
      shell_exec("/img/bin/iscsi_assemble.sh");
      $msgbox= array("show"=>true,
                     "topic"=>$title,
                     "message"=>$words["iscsi_del_success"],
                     "icon"=>'INFO',
                     "button"=>'OK',
                     "fn"=>$fn,
                     "prompt"=>'');
    }
    
//    shell_exec("/img/bin/rc/rc.iscsi start"); 
//    return $msgbox;
  }else{
//    shell_exec("/img/bin/rc/rc.iscsi start");
    if(lvname == "lv1"){
      $msgbox= array("show"=>true,
                     "topic"=>$title,
                     "message"=>$words["usb_del_failed"],
                     "icon"=>'ERROR',
                     "button"=>'OK',
                     "fn"=>'',
                     "prompt"=>''); 
    }elseif($type == $space_type[1]."_delete"){
      $msgbox= array("show"=>true,
                     "topic"=>$title,
                     "message"=>$words["thin_del_failed"],
                     "icon"=>'ERROR',
                     "button"=>'OK',
                     "fn"=>'',
                     "prompt"=>'');                
    }else{
      $msgbox= array("show"=>true,
                     "topic"=>$title,
                     "message"=>$words["iscsi_del_failed"],
                     "icon"=>'ERROR',
                     "button"=>'OK',
                     "fn"=>'',
                     "prompt"=>'');   
    }  
  //  return MessageBox(true,title,$words["usb_del_failed"],'ERROR'); 
  }
//  shell_exec("/img/bin/rc/rc.iscsi start"); 
  return $msgbox;
}

//################################
//##    Create
//################################
if($type == ($space_type[2]."_add")){
  $strExec = "/sbin/lvcreate -L ".$capacity."G -n lv1 vg".($md_num-1)." 2>&1";
  //shell_exec($strExec);
  exec($strExec,$out,$ret);
  //foreach($out as $v){
  //  $output=$v;
  //}
  if($ret == "0"){
    $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"update conf set v='$percent' where k='percent_tu'\"";
    shell_exec($strExec);
    if($ismaster){
      shell_exec("killall file-storage-ga");
      shell_exec("rmmod g_file-storage");
      //$strExec="insmod /lib/modules/2.6.13N5200/kernel/drivers/usb/gadget/g_file_storage.ko file=/dev/vg".($md_num-1)."/lv1";
      $strExec = "modprobe g_file_storage file=/dev/vg".($md_num-1)."/lv1";
      shell_exec($strExec);
    }   
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["usb_create_success"],
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 

  }else{
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["usb_create_failed"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }
}elseif($type == ($space_type[1]."_add")){
  $ret = iscsi_space_create($thin_lv);
  if($ret == 0){
//    shell_exec("/img/bin/rc/rc.iscsi stop");
//    shell_exec("/img/bin/rc/rc.iscsi start");    
    return array("show"=>true,
                 "topic"=>$title,
                 "message"=>$words["thin_space_create_success"],
                 "icon"=>'INFO',
                 "button"=>'OK',
                 "fn"=>$fn,
                 "prompt"=>''); 
  }else{
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$words["thin_space_create_failed"],
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }        
}elseif(trim($type_is_expand) != ""){
  $strExec = "/img/bin/iscsi_resize.sh ".$md_num." ".$iscsi_lv." ".$capacity." >/dev/null 2>&1 ";
	shell_exec($strExec);
 
  return  array("show"=>true,
                "topic"=>$title,
                "message"=>$words["iscsi_expand_success"],
                "icon"=>'INFO',
                "button"=>'OK',
                "fn"=>$fn,
                "prompt"=>'');   
}else{
  require_once(INCLUDE_ROOT.'validate.class.php');
  
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
  $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select count(name) from iscsi where name='$iscsi_name' and lvname!='$iscsi_lv'\"";
  $iscsi_name_count = trim(shell_exec($strExec));
  if(trim($type_is_thin_mb) == ""){    
    $iscsi_count="0";
    foreach($md_array as $md_id){
      $strExec = "/usr/bin/sqlite /raid".($md_id-1)."/sys/raid.db \"select count(name) from iscsi where v1=''\"";
      $iscsi_count=$iscsi_count+trim(shell_exec($strExec));
    }
    $limit_count = $iscsi_limit;
  }else{
    $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select count(name) from iscsi where v1='1'\"";
    $iscsi_count = trim(shell_exec($strExec));
    $limit_count = $thin_iscsi_limit;    
  }
  
  if($iscsi_count >= $limit_count && $iscsi_lv == ""){
    $msg = sprintf($words["iscsi_too_more"],$limit_count);
    return  array("show"=>true,
                  "topic"=>$title,
                  "message"=>$msg,
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
  }
  if($iscsi_name_count != 0){
    return  MessageBox(true,$title,$words["iscsi_name_duplicate"],'ERROR','OK');    
  }
  if($lun_id != '0'){
    foreach($md_array as $md_id){
      $strExec = "/usr/bin/sqlite /raid".($md_id-1)."/sys/raid.db \"select v3 from iscsi where v3='$lun_id' and lvname!='$iscsi_lv'\"";  
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
    }
  }
  if($iscsi_lv != ""){
    $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select name,enabled,chap,user,pass,year,month,v3 from iscsi where lvname='$iscsi_lv'\"";
    $db_data = shell_exec($strExec);
    $new_data = $iscsi_name."|".$iscsi_enable."|".$iscsi_chap."|".$iscsi_username."|".$iscsi_password."|".$iscsi_year."|".$iscsi_month."|".$lun_id;
    if(trim($db_data) != trim($new_data)){
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"update iscsi set name='$iscsi_name',enabled='$iscsi_enable',chap='$iscsi_chap',user='$iscsi_username',pass='$iscsi_password',year='$iscsi_year',month='$iscsi_month',v3='$lun_id' where lvname='$iscsi_lv'\"";
      delete_iscsi($iscsi_lv);
      shell_exec($strExec);
      if(trim($iscsi_enable) == "1"){
        shell_exec("/img/bin/iscsi_assemble.sh");
        shell_exec("sh -x /img/bin/rc/rc.iscsi add ".$iscsi_lv." ".($md_num-1)." 2>&1");       
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
    $strExec = "/bin/ls -l /dev/vg".($md_num-1)." | grep iscsi";
    $iscsi = shell_exec($strExec);
    if($iscsi == ""){
      $c = "0";
    }else{
      $iscsi_array = explode("\n",$iscsi);
      $iscsi_num = array();
      foreach($iscsi_array as $list){
        $aryline = preg_split("/[\s ]+/",$list);
        if($list != ""){
          $iscsi_num[] = trim(substr($aryline[8],5,strlen($aryline[8])-5));
        }
      }
      for($c=0 ; $c < 99 ; $c++){
        $flag = "0";
        foreach($iscsi_num as $v){
          if($c == $v){
            $flag = "1";
            break;
          }
        }
        if($flag != "1"){
          break;
        }
      }
    }
    
    if($type == $space_type[3]."_add"){      
      $iscsi_lvname = $thin_iscsi_lv."1";
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select lvname from iscsi where v1='1'\"";
      $thin_lists = shell_exec($strExec);
      $thin_list = explode("\n",$thin_lists);

      for($j=1; $j <= 99 ;$j++){
        if(trim(array_search($thin_iscsi_lv.$j,$thin_list)) == ""){
          $iscsi_lvname = $thin_iscsi_lv.$j;
          break;
        }          
      }
      
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select count(*) from iscsi where v1='1'\"";
      $thin_total_count=shell_exec($strExec);
      if($thin_total_count == 0)
        $strExec = "/img/bin/iscsi_thin.sh ".$md_num." ".$iscsi_lvname." ".$virtual_size." "."Format";
      else 
        $strExec = "/img/bin/iscsi_thin.sh ".$md_num." ".$iscsi_lvname." ".$virtual_size;
      shell_exec($strExec);
      $ret = 0;
    }else{
      $iscsi_lvname = "iscsi".$c;  
      $ret = iscsi_space_create($iscsi_lvname);
    }
        
    if($ret == 0){
      $col = "lvname,name,enabled,chap,user,pass,percent,comment,year,month,v1,v2,v3";
      $values = "'".$iscsi_lvname."','".$iscsi_name."','".$iscsi_enable."','".$iscsi_chap."','".$iscsi_username."','".$iscsi_password."','".$percent."','".$iscsi_comment."','".$iscsi_year."','".$iscsi_month."','".$provision."','".$virtual_size."','".$lun_id."'";
//      $col="lvname,name,enabled,chap,user,pass,percent,comment,year,month";
//      $values="'".$iscsi_lvname."','".$iscsi_name."','".$iscsi_enable."','".$iscsi_chap."','".$iscsi_username."','".$iscsi_password."','".$percent."','".$iscsi_comment."','".$iscsi_year."','".$iscsi_month."'";
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"insert into iscsi(".$col.") values(".$values.")\"";
      shell_exec($strExec);
//      shell_exec("/img/bin/rc/rc.iscsi stop");
//      shell_exec("/img/bin/rc/rc.iscsi start");
      if(trim($iscsi_enable) == "1"){
        shell_exec("/img/bin/iscsi_assemble.sh");
        shell_exec("sh -x /img/bin/rc/rc.iscsi add ".$iscsi_lvname." ".($md_num-1)." 2>&1");
      } 
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["iscsi_create_success"],
                    "icon"=>'INFO',
                    "button"=>'OK',
                    "fn"=>$fn,
                    "prompt"=>''); 
    }else{
      return  array("show"=>true,
                    "topic"=>$title,
                    "message"=>$words["iscsi_create_failed"],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>$fn,
                    "prompt"=>''); 
    }
  }
}

?>
