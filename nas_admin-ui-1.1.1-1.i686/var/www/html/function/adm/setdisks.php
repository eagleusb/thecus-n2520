<?
$words = $session->PageCode("disk");
$smartdev = $_POST["smartdev"];
$disk_no = $_POST["disk_no"];
$disk_type = $_POST["disk_type"];
$usb_id = $_POST["usb_id"];
$disk_id = $_POST["disk_id"];

if($disk_no!=""){
  if($disk_type==0){
    $strExec="/usr/sbin/smartctl -i -d $smartdev /dev/sd" . $disk_no . "|awk -F':' '/Serial Number/{print substr($2,5,length($2))}'";
    $HD_serial=trim(shell_exec($strExec));

//   if($HD_serial == "" || $HD_serial == "[No Information Found]")
//     return MessageBox(true,$words["disk_title"],$words["no_disk"],'ERROR');
  
    $strExec="/bin/cat /var/tmp/HD/smart_".$HD_serial." | awk -F'=' '/State/{print $2}'";
    $check_smart_testing=trim(shell_exec($strExec));
  
    if($check_smart_testing == "1")
      return MessageBox(true,$words["disk_title"],$words["disk_dont_scan"],'ERROR');
    $HD_serial = $disk_id;  
  }else{
    $HD_serial="usb".$usb_id;
  }

  $badblock_list=file("/var/tmp/HD/badblock_".$HD_serial);
  $badblock_scan=explode("=",trim($badblock_list[0]));
     
  if(trim($badblock_scan[1]) == "1"){
    $strExec="/img/bin/block_scan.sh stop ".$disk_no." ".$HD_serial." > /dev/null 2>&1 &";
    $block_exec=trim(shell_exec($strExec));
    sleep(1);
  }else{
    $strExec="/img/bin/block_scan.sh start ".$disk_no." ".$HD_serial." ".$smartdev." > /dev/null 2>&1 &";
    $block_exec=trim(shell_exec($strExec));
    sleep(1);
  }  
  return MessageBox(false,'','');
}
else
  return MessageBox(true,$words["disk_title"],$words["no_disk"],'ERROR');
?>  
