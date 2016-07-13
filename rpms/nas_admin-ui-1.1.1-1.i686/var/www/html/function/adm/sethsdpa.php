<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("hsdpa");
$gwords = $session->PageCode("global");

$hsdpa_dial=$_POST['_dial'];
$hsdpa_apn=$_POST['_apn'];

$db=new sqlitedb();
$o_hsdpa_dial=$db->getvar("hsdpa_dial","*99#");
$o_hsdpa_apn=$db->getvar("hsdpa_apn","internet");


if(($hsdpa_dial==$o_hsdpa_dial)&&($hsdpa_apn==$o_hsdpa_apn)){
  unset($db);
  return MessageBox(true,$words['hsdpa'],$gwords["setting_confirm"]);
}else{

    $db->setvar("hsdpa_dial",$hsdpa_dial);
    $db->setvar("hsdpa_apn",$hsdpa_apn);

  unset($db);
  $rc_path="/img/bin/rc/";

    shell_exec($rc_path.'rc.hsdpa restart > /dev/null 2>&1 &');
    return MessageBox(true,$words['hsdpa'],$words["set_success"]);

}
?>
