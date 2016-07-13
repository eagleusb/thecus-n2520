<?php  
$words = $session->PageCode("printer");
$gwords = $session->PageCode("global");

$act=$_REQUEST['act'];

ob_start();

if($act=="restart"){
  shell_exec('/img/bin/rc/rc.cupsd restart > /dev/null 2>&1');
  return MessageBox(true,$words['restart_title'],$words['restart_success']); 
}else{
  shell_exec('/img/bin/rc/rc.cupsd stop > /dev/null 2>&1');
  shell_exec('/bin/rm -rf /raid/sys/spool/cups/*');
  shell_exec('/img/bin/rc/rc.cupsd start > /dev/null 2>&1');
  return MessageBox(true,$gwords['remove'],$words['remove_success']);
}

?> 