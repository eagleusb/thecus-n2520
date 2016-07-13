<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("led_control");
$gwords = $session->PageCode("global");
$LOGO1_enable=$_POST['_enable'];
$db=new sqlitedb();
$LOGO1_enable_org=$db->getvar("LOGO1_LED","1");

if($LOGO1_enable == $LOGO1_enable_org){
  unset($db);
  return MessageBox(true,$words['led_control_title'],$gwords['setting_confirm']);
}else{
  $db->setvar("LOGO1_LED",$LOGO1_enable);
  unset($db);
  if ($LOGO1_enable){
    shell_exec("/img/bin/ctrl_thecus_io.sh LOGO1_LED:1");
    $msg= $words["led_control_Enable"];
  }else{
    shell_exec("/img/bin/ctrl_thecus_io.sh LOGO1_LED:0");
    $msg= $words["led_control_Disable"];
  }

  return MessageBox(true,$words['led_control_title'],$msg);
}
?>
