<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$db=new sqlitedb();
$schedule_on=$db->getvar("schedule_on","0");
$words = $session->PageCode("schedule");
$gwords = $session->PageCode("global");
if (NAS_DB_KEY==1)
  $weeks=array("sun"=>"sunday","mon"=>"monday","tue"=>"tuesday","wed"=>"wednesday","thu"=>"thursday","fri"=>"friday","sat"=>"saturday");
else
  $weeks=array("Sun"=>"sunday","Mon"=>"monday","Tue"=>"tuesday","Wed"=>"wednesday","Thu"=>"thursday","Fri"=>"friday","Sat"=>"saturday");

$db_data=array();

foreach($weeks as $name=>$value)
  $db_data[$name][0]=$gwords[$value];

foreach($weeks as $name=>$value){
  $db_data[$name][1]=$db->getvar("power_schedule_".$name."1","2");  
  $db_data[$name][2]=$db->getvar("power_schedule_".$name."1_hh","00");
  $db_data[$name][3]=$db->getvar("power_schedule_".$name."1_mm","00");
  $db_data[$name][4]=$db->getvar("power_schedule_".$name."2","2");
  $db_data[$name][5]=$db->getvar("power_schedule_".$name."2_hh","00");
  $db_data[$name][6]=$db->getvar("power_schedule_".$name."2_mm","00");

}

$tpl->assign('schedule_on',$schedule_on);
$tpl->assign('weeks',$weeks);
$tpl->assign('db_data',$db_data);
$tpl->assign('words',$words);
$tpl->assign('power_action','[[2,"None"],[1,"'.$words["power_on"].'"],[0,"'.$words["power_off"].'"]]');
$tpl->assign('form_action','setmain.php?fun=setpower');
unset($db);
?>
