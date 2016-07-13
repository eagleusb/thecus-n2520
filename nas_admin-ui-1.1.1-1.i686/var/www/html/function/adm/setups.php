<?php
/*session_start();
if(!$_SESSION['admin_auth']){
    header('Location: /unauth.htm');
    exit;
}*/
ob_start();
require_once(INCLUDE_ROOT.'info/sysinfo.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
$words = $session->PageCode("ups");

//Save UPS info
$ups_conf="/etc/ups/ups.conf";
$ups_port="/dev/ttyS0";
$ups_host="localhost";
$ups_mon_conf="/etc/ups/upsmon.conf";
$ups_mon_tmpconf="/etc/ups/upsmon.conf.tmp";
  
//STOP UPS
$strExec="/img/bin/rc/rc.ups stop";
shell_exec($strExec);
  
$ups_use=$_POST["_ups_use"];
$ups_usems=$_POST["_ups_usems"];
$ups_ip=$_POST["_ups_ip"];
$ups_brand=$_POST["_ups_brand"];
$ups_model=$_POST["_ups_model"];
$ups_pollfreq=substr($_POST["_ups_pollfreq"],0,strlen($_POST["_ups_pollfreq"])-1);
$ups_pollfreqalert=substr($_POST["_ups_pollfreqalert"],0,strlen($_POST["_ups_pollfreqalert"])-1);
$ups_finaldelay=substr($_POST["_ups_finaldelay"],0,strlen($_POST["_ups_finaldelay"])-1);
  
$ups_option=$_POST["ups_option"];

if (preg_match("/=/",$ups_option)){
  $aryups_option=explode(" ",$ups_option);
}else{
  $aryups_option[0]=$ups_option;
}

if(!$validate->ip_address($ups_ip)){
   if($validate->ipv6_address($ups_ip)){
      $ups_ip="[$ups_ip]";
      $ip_type="1"; //ipv6
   }
}else{
   $ip_type="2";
}

if(($ups_ip=="")&&($ups_usems=="1")&&($ups_use=="1")){
    return MessageBox(true,$words['ups_Info'],$words["ip_empty"],'ERROR');
}else if(($ups_use=="1")&&($ups_usems=="1")){
     $result=shell_exec("/usr/bin/upsc ". $ups_option ."@" . $ups_ip);
     if($result==""){
       return MessageBox(true,$words['ups_Info'],$words['setting_fail'],'ERROR');
     } 
}



if( ($aryups_option[0]=="usbhid-ups")||($aryups_option[0]=="megatec_usb")||($aryups_option[0]=="energizerups")||($aryups_option[0]=="bcmxcp_usb")||($aryups_option[0]=="tripplite_usb") ){
    $ups_port="auto";    
}
$db=new sqlitedb();
$old_ups_use=$db->getvar("ups_use","0");
$old_ups_ip=$db->getvar("ups_ip","");
$old_ups_brand=$db->getvar("ups_brand","Powercom");
$old_ups_model=$db->getvar("ups_model","BNT-1000AP");
$old_ups_pollfreq=$db->getvar("ups_pollfreq","5");
$old_ups_pollfreqalert=$db->getvar("ups_pollfreqalert","20");
$old_ups_finaldelay=$db->getvar("ups_finaldelay","5");

if (($old_ups_brand!=$ups_brand)||($old_ups_model!=$ups_model)||($old_ups_pollfreq!=$ups_pollfreq)||($old_ups_pollfreqalert!=$ups_pollfreqalert)||($old_ups_finaldelay!=$ups_finaldelay)||($old_ups_ip!=$ups_ip)) {
  $tmpmon_conf=file($ups_mon_tmpconf);
  
  if ($ups_usems=="1") {
     $tmpmon_conf[]=sprintf("MONITOR %s@%s 1 nutups nutups \"slave\"\n",$aryups_option[0],$ups_ip);
  }else{
     $tmpmon_conf[]=sprintf("MONITOR %s@localhost 1 nutups nutups \"master\"\n",$aryups_option[0]);
  }
  $tmpmon_conf[]=sprintf("POLLFREQ %s\n",$ups_pollfreq);
  $tmpmon_conf[]=sprintf("POLLFREQALERT %s\n",$ups_pollfreqalert);
  $tmpmon_conf[]=sprintf("LOWBATT_PERCENT %s\n",$ups_finaldelay);
  
  file_put_contents($ups_mon_conf,$tmpmon_conf);
  
  $ups_conf_content=array();
  $ups_conf_content[]=sprintf("[%s]\n",$aryups_option[0]);
  $ups_conf_content[]=sprintf("  driver=%s\n",$aryups_option[0]);
  $ups_conf_content[]=sprintf("  port=%s\n",$ups_port);
  
  $i=0;
  foreach ($aryups_option as $item) {
    if ($i>0) {
      $ups_conf_content[]=sprintf("  %s\n",$item);
    }
    $i++;
  }
  $ups_conf_content[]=sprintf("  desc=%s monitor\n",$aryups_option[0]);
  
  file_put_contents($ups_conf,$ups_conf_content);
}
  
$db->setvar("ups_use",$ups_use);
if($ups_use=="0"){
  $db->setvar("ups_usems","0");
  $db->setvar("ups_ip","");
}else{
  $ups_ip=$_POST["_ups_ip"];
  $db->setvar("ups_usems",$ups_usems);
  $db->setvar("ups_ip",$ups_ip);
  if($ip_type=="1"){
     $ups_ip="[$ups_ip]";     
  }
}
$db->setvar("ups_brand",$ups_brand);
$db->setvar("ups_model",$ups_model);
$db->setvar("ups_pollfreq",$ups_pollfreq);
$db->setvar("ups_pollfreqalert",$ups_pollfreqalert);
$db->setvar("ups_finaldelay",$ups_finaldelay);

if ($ups_use=="1") {
  $strExec="/img/bin/rc/rc.ups start";
} else {
  $strExec="/img/bin/rc/rc.ups stop";
}  
shell_exec($strExec);
sleep(5);
$battery_use="";
$power_stat="";
if ($ups_usems=="1") {
  $exeResult=shell_exec("/usr/bin/upsc ". $ups_option ."@" . $ups_ip);
}else{
  $exeResult=shell_exec("/usr/bin/upsc ". $ups_option ."@localhost");
}

$ary_result=explode("\n",$exeResult);
foreach ($ary_result as $item) {
    $ary_item=explode(":",$item);
    $varkey=trim($ary_item[0]);
    if ($varkey=="battery.charge") {
        $battery_use=1;
    }
    
    if ($varkey=="ups.status") {
        $aryupsstat=explode(" ",trim($ary_item[1]));
        foreach ($aryupsstat as $upsstat) {
            $conn_stat=trim($upsstat);
            if ($conn_stat=="OB") {
                $power_stat="1"; 
                break;
            }
            
            if ($conn_stat=="OL") {
                $power_stat="1";
                break;
            }
        }
    }  
}
 
if($battery_use=='' && $power_stat=='' && $ups_use=="1"){
  $strExec="/img/bin/rc/rc.ups stop";
  shell_exec($strExec);
  $db->setvar("ups_use","0");
  $db->setvar("ups_ip","");
  unset($db);
  
  return MessageBox(true,$words['ups_Info'],$words['setting_fail'],'ERROR');
}else{
  unset($db);

  return MessageBox(true,$words['ups_Info'],$words['save_success']);
}
?>
