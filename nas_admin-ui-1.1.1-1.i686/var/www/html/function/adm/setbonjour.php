<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("bonjour");
$gwords = $session->PageCode("global");
$bonjour_enable=$_POST['_enable'];
$db=new sqlitedb();
$bonjour_enable_org=$db->getvar("bonjour_enable","1");

if($bonjour_enable == $bonjour_enable_org){
  unset($db);
  return MessageBox(true,$words['bonjour_title'],$gwords['setting_confirm']);
}else{
  $db->setvar("bonjour_enable",$bonjour_enable);
  unset($db);
  if ($bonjour_enable){
    shell_exec("/img/bin/rc/rc.bonjour start > /dev/null 2>&1");
    $msg= $words["bonjour_Enable"];
  }else{
    shell_exec("/img/bin/rc/rc.bonjour stop > /dev/null 2>&1");
    $msg= $words["bonjour_Disable"];
  }

  return MessageBox(true,$words['bonjour_title'],$msg);
}
?>
