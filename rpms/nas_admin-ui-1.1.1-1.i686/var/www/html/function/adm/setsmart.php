<?
$words = $session->PageCode("disk");
$diskno = $_POST["diskno"];
$smart_action = $_POST["smart_status"];
$test_type=trim($_POST["stype"]);
$smartdev=$_POST["smartdev"];
$trayno=$_POST["trayno"];

$strExec="/usr/sbin/smartctl -i -d $smartdev /dev/sd" . $diskno . "|awk -F':' '/Serial Number/{print substr($2,5,length($2))}'";
$HD_serial=trim(shell_exec($strExec));
 
if($HD_serial == "" || $HD_serial == "[No Information Found]")
  return MessageBox(true,$words["smart_test_title"],$words["no_disk"],'ERROR');
  
$strExec="/bin/cat /var/tmp/HD/badblock_".$trayno." | awk -F'=' '/State/{print $2}'";
$check_block_scanning=trim(shell_exec($strExec));

if($check_block_scanning == "1")
  return MessageBox(true,$words["smart_test_title"],$words["smart_dnot_test"],'ERROR');

if($smart_action == "1")
{
  $strExec="/img/bin/smart_test.sh start ".$diskno." ".$HD_serial." ".$smartdev." ".$test_type." > /dev/null 2>&1 &";
  $smart_exec=trim(shell_exec($strExec));  
}
else if($smart_action =="0")
{  
  $strExec="/img/bin/smart_test.sh stop ".$diskno." ".$HD_serial." ".$smartdev;
  $smart_exec=trim(shell_exec($strExec));
}  
return MessageBox(false,'','');
?>  