<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("ddns");
$gwords = $session->PageCode("global");

$ch=new validate;

$ddns=$_POST['_ddns'];
$ddns_reg=$_POST['_reg_selected'];
$ddns_uname=$_POST['_uname'];
$ddns_password=$_POST['_password'];
$ddns_domain=$_POST['_domain'];

$db=new sqlitedb();

$o_ddns=$db->getvar("ddns_ddns","0");
$o_ddns_reg=$db->getvar("ddns_reg","dyndns@dyndns.org");
$o_ddns_uname=$db->getvar("ddns_uname","");
$o_ddns_password=$db->getvar("ddns_password","");
$o_ddns_domain=$db->getvar("ddns_domain","");

if(($ddns==$o_ddns)&&($ddns_reg==$o_ddns_reg)&&($ddns_uname==$o_ddns_uname)&&($ddns_password==$o_ddns_password)&&($ddns_domain==$o_ddns_domain)){
  unset($db);
  return MessageBox(true,$words['ddns'],$gwords["setting_confirm"]);
}else{
  $db->setvar("ddns_ddns",$ddns);
  $db->setvar("ddns_reg",$ddns_reg);
  $db->setvar("ddns_uname",$ddns_uname);
  $db->setvar("ddns_password",$ddns_password);
  $db->setvar("ddns_domain",$ddns_domain);
  unset($db);
  $rc_path="/img/bin/rc/";
  if ($ddns == 1){
    if ($ch->check_empty($ddns_uname)){
      unset($ch);
      return MessageBox(true,$words["ddns"],$words["uname_empty"]);
    }

    if ($ch->check_empty($ddns_password)){
      unset($ch);
      return MessageBox(true,$words["ddns"],$words["password_empty"]);
    }

    if ($ch->check_empty($ddns_domain)){
      unset($ch);
      return MessageBox(true,$words["ddns"],$words["domain_empty"]);
    }

    shell_exec($rc_path.'rc.ddns restart > /dev/null 2>&1 &');
    return MessageBox(true,$words['ddns'],$words["ddns_enable"]);
  }else if ($ddns == 0){
    shell_exec($rc_path.'rc.ddns stop > /dev/null 2>&1 &');
    return MessageBox(true,$words['ddns'],$words["ddns_disable"]);
  }
}
