<?php
/*session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if($is_function){
  check_system($sysconf["schedule_poweron"],"permission_warning","about");
}else{
  require_once("/var/www/html/inc/function.php");
  check_system("0","access_warning","about");
}*/
//#######################################################

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("schedule");
$db=new sqlitedb();

if (NAS_DB_KEY==1)
  $week=array("sun","mon","tue","wed","thu","fri","sat");
else
  $week=array("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
$schedule_on=$_POST['_schedule_on'];

if($schedule_on != "on"){
  $db->setvar("schedule_on","0");
  $message.=$words["schedule_disable_success"];
  unset($db);
  set_crond("clear");
  flush();
  if (NAS_DB_KEY==1)
    shell_exec("sh -x /img/bin/set_poweron.sh > /tmp/set_poweron.log 2>&1");
//  else
//    shell_exec("/img/bin/chk_power.sh");
  flush();
  return MessageBox(true,$words["schedule"],$message);
}else{

  $db->setvar("schedule_on","1");

  for($c=0;$c<7;$c++){
    $tmp=$week[$c]."1";
    $tmp2=$week[$c]."2";
    ${$tmp}=$_REQUEST[$tmp];
    $time1=explode(':',$_REQUEST[$tmp."_tt"]);  
    ${$tmp."_hh"}=$time1[0];
    ${$tmp."_mm"}=$time1[1];
    ${$tmp2}=$_REQUEST[$tmp2];
    $time2=explode(':',$_REQUEST[$tmp2."_tt"]);    
    ${$tmp2."_hh"}=$time2[0];
    ${$tmp2."_mm"}=$time2[1];
//  echo ${$tmp} ."  ".${$tmp."_hh"}." ".${$tmp."_mm"}." ".${$tmp2}." ".${$tmp2."_hh"}." ".${$tmp2."_mm"};
//  exit;
    if(${$tmp}!="2" && ${$tmp2}!="2"){
      if((${$tmp."_hh"}==${$tmp2."_hh"} && ${$tmp."_mm"}>${$tmp2."_mm"}) || ${$tmp."_hh"}>${$tmp2."_hh"}){
        $temp=${$tmp};
        $temp_hh=${$tmp."_hh"};
        $temp_mm=${$tmp."_mm"};
        ${$tmp}=${$tmp2};
        ${$tmp."_hh"}=${$tmp2."_hh"};
        ${$tmp."_mm"}=${$tmp2."_mm"};
        ${$tmp2}=$temp;
        ${$tmp2."_hh"}=$temp_hh;
        ${$tmp2."_mm"}=$temp_mm;
      }
    }
    if(${$tmp}=="0"){
      $crond[]=${$tmp."_mm"}." ".${$tmp."_hh"}." * * ".$c;
    }
    if(${$tmp2}=="0"){
      $crond[]=${$tmp2."_mm"}." ".${$tmp2."_hh"}." * * ".$c;
    }
    if(${$tmp}=="2"){
      ${$tmp."_hh"}="00";
      ${$tmp."_mm"}="00";
    }
    if(${$tmp2}=="2"){
      ${$tmp2."_hh"}="00";
      ${$tmp2."_mm"}="00";
    }
    $db->setvar("power_schedule_".$tmp,${$tmp});
    $db->setvar("power_schedule_".$tmp."_hh",${$tmp."_hh"});
    $db->setvar("power_schedule_".$tmp."_mm",${$tmp."_mm"});
    $db->setvar("power_schedule_".$tmp2,${$tmp2});
    $db->setvar("power_schedule_".$tmp2."_hh",${$tmp2."_hh"});
    $db->setvar("power_schedule_".$tmp2."_mm",${$tmp2."_mm"});
  }
  set_crond($crond);
  unset($db);
  flush();
  if (NAS_DB_KEY==1)
    shell_exec("sh /img/bin/set_poweron.sh > /dev/null 2>&1");
  else
    shell_exec("/img/bin/chk_power.sh");
  flush();

  $message .= $words["schedule_enable_success"];
  return MessageBox(true,$words["schedule"],$message);
}

/*
* set crond table schedule.
* @param crond - data in crond table now
* @returns none.
*/   
function set_crond($crond){    
  $source=array();
  $key = "#power schedule";
  $file_content=file("/etc/cfg/crond.conf");  
  foreach($file_content as $line){
    if (!strpos($line,$key)) //look for $key in each line
      $source[]=$line;
  }
  if($crond!="clear"){
    for($i=0;$i<count($crond);$i++){
      if (NAS_DB_KEY==1)
        $crond[$i]=$crond[$i]." /img/bin/logevent/information 999 \"Schedule Power Off\";/img/bin/model/sysdown.sh poweroff > /dev/null 2>&1 #power schedule\n";
      else
        $crond[$i]=$crond[$i]." /img/bin/sys_halt schedule > /dev/null 2>&1 #power schedule\n";
    }
    $crond=implode("",$crond);
    $source[]=$crond;
  }
  $crond_result=join("",$source);
  
  $fp=fopen("/etc/cfg/crond.conf","wb");
  fwrite($fp,$crond_result);  
  fclose($fp);
  shell_exec("cat /etc/cfg/crond.conf | crontab - -u root");
}
?>
