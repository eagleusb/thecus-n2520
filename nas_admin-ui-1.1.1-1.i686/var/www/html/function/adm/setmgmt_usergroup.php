<?
$words = $session->PageCode("mgmt_usergroup");
$action=$_REQUEST['action_do'];

error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');

if ($action == 'Download'){
  $dfile="/tmp/usergroup.bin";
  $dfilename="usergroup.bin";

  unlink($dfile);
  shell_exec('/img/bin/mgmt_usergroup.sh backup');
  
  header("Content-type: application/octet-stream");
  header("Content-Disposition: attachment; filename=$dfilename");
  
  readfile($dfile);
  unlink($dfile);
  exit;
}else if($action == 'Upload'){
  include_once(INCLUDE_ROOT.'Vendor/vendor.class.php');
  $io = new VendorIO();
  
  // upload
  if (NAS_DB_KEY == '1'){
    $enckey="conf_n5200";
  }else{
    $enckey="conf_".$io->data["MODELNAME"];
  }
  move_uploaded_file($_FILES['config-path']['tmp_name'],'/tmp/usergroup.bin');
  //uncompress
  shell_exec('/usr/bin/des -k ' . $enckey . ' -D /tmp/usergroup.bin /tmp/usergroup.tar.gz 2>&1');
  shell_exec('/img/bin/mgmt_usergroup.sh restore');
  $result=trim(shell_exec('cat /tmp/restore_ret'));

  if($result=="0"){
    echo '{success:true, file:'.json_encode($_FILES['config-path']['name']).', msg:'.json_encode($words["restoresuccess"]).'}';
  }else{
    echo '{failure:true, file:'.json_encode($_FILES['config-path']['name']).', msg:'.json_encode($words["restorefail"]).'}';
  }
  
  shell_exec('rm -rf /tmp/restore_ret');
  exit;
}
?>
