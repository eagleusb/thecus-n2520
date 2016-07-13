<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
$words = $session->PageCode("raid");
$gwords = $session->PageCode("global");
$fn = array('ok'=>'execute_success("")');
$rc_path="/img/bin/rc/";

$iscsi=$_POST['_iscsi'];
$isns=$_POST['isns_enabled'];
$isns_ip=$_POST['_isns_ip'];
$db=new sqlitedb();

$o_iscsi=$db->getvar("iscsi","0");
$o_isns=$db->getvar("isns_enable","0");
$o_isns_ip=$db->getvar("isns_ip","");

if(($iscsi == $o_iscsi) && ($isns == $o_isns) && ($isns_ip == $o_isns_ip)){
  unset($db);
  return MessageBox(true,$gwords['iscsi'],$gwords["setting_confirm"]);
}else{
  if (($isns==0) && ($iscsi == 1)){
    shell_exec($rc_path."rc.iscsi del_cron_isns");
    shell_exec($rc_path."rc.iscsi isnsregi del");
  }
  
  if (($isns==1) && ($iscsi == 1)){
    if(!$validate->ip_address($isns_ip)){
      return  array("show"=>true,
                    "topic"=>$gwords['iscsi'],
                    "message"=>$gwords['ip_error'],
                    "icon"=>'ERROR',
                    "button"=>'OK',
                    "fn"=>'',
                    "prompt"=>'');
    }
    
    $db->setvar("isns_ip",$isns_ip);
  }
      
  $db->setvar("iscsi",$iscsi);
  $db->setvar("isns_enable",$isns);

  unset($db);
  
  if ($iscsi == 1){
    if ($o_iscsi != $iscsi){
      shell_exec($rc_path."rc.iscsi start");      
    }else{
      if ($isns==1){
        shell_exec($rc_path."rc.iscsi add_cron_isns");
        shell_exec($rc_path."rc.iscsi isnsregi");
      }
    }
    
    return  array("show"=>true,
                  "topic"=>$gwords['iscsi'],
                  "message"=>$words["iscsiEnable"],
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
  }else if ($iscsi == 0){
    shell_exec($rc_path."rc.iscsi stop ");
    
    return  array("show"=>true,
                  "topic"=>$gwords['iscsi'],
                  "message"=>$words["iscsiDisable"],
                  "icon"=>'INFO',
                  "button"=>'OK',
                  "fn"=>$fn,
                  "prompt"=>'');
  }
}
