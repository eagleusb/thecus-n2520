<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once("/var/www/html/inc/info/raidinfo.class.php");
$unmount_all_flag=$_POST['unmount_all_flag'];
$iso_data=stripcslashes(trim($_POST['umount_iso_data']));
$root=$_POST['root'];

$raidinfo=new RAIDINFO();
$md_count=$raidinfo->getMdarray();
$words = $session->PageCode("isomount");
$isomount_list=array();

if (NAS_DB_KEY == '1')
{
  $database="/etc/cfg/isomount.db";
  $db=new sqlitedb($database,"isomount");
  $mountTable = "isomount";
}
elseif (NAS_DB_KEY == '2')
{
  $db=new sqlitedb();
  $mountTable = "mount";
}
  
$umount_count=0;
$umount_fail_count=0;
$message="";

function unmount_iso(){
  global $isomount_list,$md_count,$db,$umount_count,$message,$words,$umount_fail_count,$mountTable;  
  
  if (NAS_DB_KEY == '1')
    $strExec="mount | grep '/dev/loop/loop' | cut -d ' ' -f 3- | sed -n 's/ type iso9660 (ro,nosuid,nodev,noexec//gp'";
  elseif (NAS_DB_KEY == '2'){
    $strExec="mount | grep '/dev/loop' |cut -d ' ' -f 3- |sed -n 's/ type iso9660 .*//gp'";
    $strExec2="mount | grep '/dev/loop' |cut -d ' ' -f 3- |sed -n 's/ type udf .*//gp'";
  }
    
  $mount_list=shell_exec($strExec);
  foreach ($isomount_list as $isomount){
    $iso_array=explode("/",$isomount);

    if (NAS_DB_KEY == '1'){
      $share_name=escapeshellstring("awk",$iso_array[1]);
      $strExec="cat /tmp/smb.conf | awk -F'/' '/\/".$share_name."$/&&/path = /{print $2}'";  
    }elseif (NAS_DB_KEY == '2'){
      $share_name=addcslashes($iso_array[1],"($+{}'^)");
      $strExec="cat /etc/samba/smb.conf | awk -F'/' '/\/".$share_name."$/&&/path = /{print $2}'";
    }
    
    //$strExec="cat /tmp/smb.conf | grep path | awk -F '/' '/${share_name}$/{print $2}'";
    $raidno=trim(shell_exec($strExec));
    //$tab->add( TabAlert::getBehavior($raidno." ".$words['unmount_success']) );
    //$strExec="df | grep \"".addcslashes($isomount,"`![]^$")."$\" | awk '{print $1}'";
    if (NAS_DB_KEY == '1'){
      $tmp_name=escapeshellstring("awk",$isomount);
      $strExec="df | awk '/ \/".$raidno."\/data".$tmp_name."$/{print $1}'";
    }elseif (NAS_DB_KEY == '2'){
      $tmp_name=addcslashes($isomount,"()+{}^$/[]*?|\\");
      $tmp_exec=escapeshellarg("/".$tmp_name."$/{print $1}");
      $strExec="df | awk ".$tmp_exec;
    }
    $loop_device=shell_exec($strExec);
    $pos = strpos($mount_list, $isomount);
    if ($pos == ''){
          $mount_list=shell_exec($strExec2);
          $pos = strpos($mount_list, $isomount);
    }    

    if ($pos == false) {
      $result = 0;
    }else{
      //$cmd='/bin/umount "/raid/data/ftproot'.$isomount.'"';
      $cmd="/bin/umount ".$loop_device;
      system($cmd,$result);      
    }
    if ($result == 0){
      $cmd='/sbin/losetup -d '.${loop_device};
      shell_exec($cmd);
      $message=$message.$isomount." ".$words['unmount_success']."<br>";
      //rmdir("/raid/data/ftproot".$isomount);
      rmdir("/${raidno}/data".$isomount);
      $rs=$db->db_delete($mountTable,"where point=\"".$isomount."\"");
      $umount_count++;
    }else{
      $umount_fail_count++;
      //$message=$message.$isomount." ".$words['unmount_error']."<br>";
    }  
  }    
}


if($unmount_all_flag==0){
  $isomount_list=explode(chr(26),urldecode($iso_data));
  $umount_total_count=sizeof($isomount_list);
  unmount_iso();

/*  if ($umount_count == $umount_total_count){
    $message=$words['unmount_success'];
  //  return  MessageBox(true,$words['isomount_title'],$words['unmount_success'],'INFO','OK',$fn); 
  }else{
    $message=$words['unmount_error'];
 //   return  MessageBox(true,$words['isomount_title'],$words['unmount_error'],'ERROR');
  }
*/    
}else{

  if($root=='')
    $isomount_list_tmp=$db->db_get_folder_info($mountTable,"point","");
  else
    $isomount_list_tmp=$db->db_get_folder_info($mountTable,"point","where label='".$root."'");
  
  
  foreach($isomount_list_tmp as $k=>$v){
    $isomount_list[$k]=$v["point"];
  }
  $umount_total_count =sizeof($isomount_list);  
  unmount_iso();

  if ($umount_total_count == $umount_count){
 //   return  MessageBox(true,$words['isomount_title'],$words['unmount_all_success'].$isomount_count); 
    $message=$words['unmount_all_success'];
  }else{
    $message=$words['unmoumt_all_error'];
 //   return  MessageBox(true,$words['isomount_title'],$words['unmoumt_all_error'].$isomount_count,'ERROR');
  }
    
}

unset($db);

$fn=array('ok'=>'update_grid_data(3)');
//if ($umount_count == $umount_total_count){
    $message=$umount_count." ".$words['unmount_success'];
    if($umount_fail_count!=0) $message=$message."<br>".$umount_fail_count." ".$words["unmount_error"];
    return  array("show"=>true,
                  "topic"=>$words['isomount_title'],
                  "message"=>$message,
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>''); 
/*  }else{
    //return  MessageBox(true,$words['isomount_title'],$words['unmount_error'],'ERROR','OK',$fn);
  
    return  array("show"=>true,
                  "topic"=>$words['isomount_title'],
                  "message"=>$message,
                  "icon"=>'ERROR',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
  }
*/
?>
