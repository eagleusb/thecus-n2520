<?php  

require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'validate.class.php');
$words = $session->PageCode("nsync_target"); 
$gwords = $session->PageCode("global"); 

$id_dsa_pub_new="/etc/ssh/id_dsa.pub.new";
$id_dsa_new="/etc/ssh/id_dsa.new";

$rsync_target_enable=$_POST['_rsync_enable'];
$rsync_username=$_POST['_rsync_username'];
$rsync_password=$_POST['_rsync_password'];
$certificate=$_POST['_certificate'];
$pattern_username = '/[\/\ :;<=>?\[\]\\\\*\+\,]/';

if ($certificate=="2"){
    shell_exec("rm $id_dsa_pub_new");
    shell_exec("rm $id_dsa_new");
    shell_exec("/img/bin/rc/rc.rsyncd restart > /dev/null 2>&1");
    echo '{success:true, type:"upgradePrompt", msg:'.json_encode($words["restore_success"]).'}';
    exit;
}else if ($certificate=="3"){
  $dfile="/tmp/key.tar.gz";
  $dfilename="key.tar.gz";
  shell_exec("/img/bin/rc/rc.rsyncd tar_key > /dev/null 2>&1");
  
  header("Content-Type: application/octet-stream");
  header("Content-Disposition: attachment; filename=$dfilename;");
  header("Pragma: ");
  header("Cache-Control: ");
  header("Content-length: " . filesize($dfile));

  readfile($dfile);
  unlink('/tmp/key.tar.gz');
  die();
}

$db = new sqlitedb();

$rsync_post_key=array('_rsync_enable' ,'_rsync_username' ,'_rsync_password', '_sshd_enable', 'sshd_ip1', 'sshd_ip2', 'sshd_ip3');
$rsync_db_key=array("nsync_target_rsync_enable"=>"1",
                  "rsync_target_username"=>"",
                  "rsync_target_password"=>"",
                  "sshd_enable"=>"0",
                  "sshd_ip1"=>"",
                  "sshd_ip2"=>"",
                  "sshd_ip3"=>"");

$rsync_post_array=array();
foreach ($rsync_post_key as $k) 
	$rsync_post_array[]=$_POST[$k];

$rsync_db_array=array();
foreach ($rsync_db_key as $k=>$v) 
	$rsync_db_array[]=$db->getvar($k,$v);
	
unset($db);

//if not do any change,redirect to setting page
if (serialize($rsync_post_array)==serialize($rsync_db_array) && ($certificate=="0")){
  echo '{success:false, msg:'.json_encode($gwords['setting_confirm']).'}';
  exit;
}

if ($rsync_target_enable=="1"){
  if  (($rsync_username=="") || ($rsync_password=="")){
    echo '{success:false, msg:'.json_encode($words['rsync_name_passwd_empty']).'}';
    exit;
  }

  preg_match($pattern_username, $rsync_username, $matches);
  if($matches[0]){
    echo '{success:false, msg:'.json_encode($words['rsync_username_error']).'}';
    exit;
  }

  if(!$validate->check_userpwd($rsync_password)){
    echo '{success:false, msg:'.json_encode($words['rsync_pwd_error']).'}';
    exit;
  }

  if ($_POST['_sshd_enable']=="1"){
    if  (($_POST['sshd_ip1']=="") && ($_POST['sshd_ip2']=="") && ($_POST['sshd_ip3']=="")){
      echo '{success:false, msg:'.json_encode($words['ssh_ip_empty']).'}';
      exit;
    }    
    
    if (!$validate->ip_address($_POST['sshd_ip1']) && !$validate->check_empty($_POST['sshd_ip1'])){
      if(!$validate->ipv6_address($_POST['sshd_ip1'])){
          echo '{success:false, msg:'.json_encode($words['ssh_ip_error']).'}';
          exit;
      }
    }

    if (!$validate->ip_address($_POST['sshd_ip2']) && !$validate->check_empty($_POST['sshd_ip2'])){
      if(!$validate->ipv6_address($_POST['sshd_ip2'])){
        echo '{success:false, msg:'.json_encode($words['ssh_ip_error']).'}';
        exit;
      }
    }

    if (!$validate->ip_address($_POST['sshd_ip3']) && !$validate->check_empty($_POST['sshd_ip3'])){
      if(!$validate->ipv6_address($_POST['sshd_ip3'])){
        echo '{success:false, msg:'.json_encode($words['ssh_ip_error']).'}';
        exit;
      }
    }
  }

}

$db = new sqlitedb();
$db->setvar("nsync_target_rsync_enable",$rsync_target_enable);
if ($rsync_target_enable){
  $db->setvar("rsync_target_username",$rsync_username);
  $db->setvar("rsync_target_password",$rsync_password);
  
  $db->setvar("sshd_enable",$_POST['_sshd_enable']);
  if ($_POST['_sshd_enable']=="1"){
    $db->setvar("sshd_ip1",$_POST['sshd_ip1']);
    $db->setvar("sshd_ip2",$_POST['sshd_ip2']);
    $db->setvar("sshd_ip3",$_POST['sshd_ip3']);
  }
  
  if ($certificate=="1"){
	move_uploaded_file($_FILES['_public']['tmp_name'], $id_dsa_pub_new);
	move_uploaded_file($_FILES['_private']['tmp_name'], $id_dsa_new);
	shell_exec("chmod 600 ".$id_dsa_new);
	shell_exec("chmod 644 ".$id_dsa_pub_new);
  }
  
  shell_exec("/img/bin/rc/rc.rsyncd restart > /dev/null 2>&1");
}else{
  shell_exec("/img/bin/rc/rc.rsyncd stop > /dev/null 2>&1");
}

unset($db);
if ($msg_rsync=="")
  $msg_rsync = ($rsync_target_enable) ? $words["rsyncd_Enable"]:$words["rsyncd_Disable"];

echo '{success:true, type:"upgradePrompt", msg:'.json_encode($msg_rsync).'}';
exit;
?>
