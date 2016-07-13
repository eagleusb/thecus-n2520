<?
  require_once(INCLUDE_ROOT."usbtool.class.php");
  $words = $session->PageCode("disk");
  $usbclass=new USBTOOL();
  if ($_POST["usb_disk_no"]!="") {
  $check_block_state=shell_exec("/bin/cat /var/tmp/HD/badblock_usb".$_POST["ej_usb_id"]." |awk -F'=' '/State/{print $2}'");
  
  if($check_block_state){
    shell_exec("/img/bin/block_scan.sh stop ".$_POST["usb_disk_no"]."  usb".$_POST["ej_usb_id"]." > /dev/null 2>&1 ");        
  }
  
  shell_exec("/bin/rm /var/tmp/HD/badblock_usb".$_POST["ej_usb_id"]);
  $ret=$usbclass->ejectusb($_POST["usb_disk_no"]);
    
  if($ret=="0"){
     return MessageBox(true,$words["disk_title"],$words["eject_success"]);
  }else{
    return MessageBox(true,$words["disk_title"],$words["eject_fail"]);
  }
}
?>
