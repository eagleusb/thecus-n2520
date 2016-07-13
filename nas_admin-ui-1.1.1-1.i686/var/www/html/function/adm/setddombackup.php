<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("ddom");
$gwords = $session->PageCode("global");
$db = new sqlitedb();
$error_file_path = "/raid/data/tmp/save_tmp/ERROR";
$cmd_path = "/img/bin/dom_backup.sh";

$act = $_POST["act"];
$ddom_on = ($_POST["ddom_on"]=="on")? 1 : 0;
$ddom_type = $_POST["ddom_type"];
$daily_time = $_POST["daily_time"];
$weekly_time = $_POST["weekly_time"];
$monthly_time = $_POST["monthly_time"];
$week_day = $_POST["week_day"];
$month_day = $_POST["month_day"];
$crond_week="*";
$crond_month="*";
$para="";

if(trim($act) == "ddom_mnaul"){
  $strExec = "/bin/ps www | grep ".$cmd_path." | grep -v grep";
  $is_processing = shell_exec($strExec); 
  if($is_processing != "" ){
    return MessageBox(true,$words["ddom_title"],$words["ddom_manual_error"],"ERROR");
  }else{
    $strExec = $cmd_path." MANUAL > /dev/null 2>&1 &";
    shell_exec($strExec);
    $manual_result['process_flag']='1';
    $manual_result['false']=true;
    return $manual_result;
  }
}else{
  if($ddom_on == 0){
    $db->setvar("dom_backup_enabled","0");
    unset($db);
    set_crond("clear");
    flush();
    return MessageBox(true,$words["ddom_title"],$words["ddom_disable_success"]);
  }else{
    $db->setvar("dom_backup_enabled","1");
    switch ($ddom_type){
		  case 'daily':
		    $times = explode(":",$daily_time);
		    $para = "SCHEDULE";
			  //$crond = "${times[1]} ${times[0]} * * * ".$cmd_path." SCHEDULE > /dev/null 2>&1\n";
			  $db->setvar("dom_backup_schedule",$ddom_type."_".$daily_time);
			  break;
		  case 'weekly':
		    $times = explode(":",$weekly_time);
		    $crond_week = $week_day;
		    $para = "SCHEDULE";
			 // $crond = "${times[1]} ${times[0]} * * ${week_day} ".$cmd_path." SCHEDULE > /dev/null 2>&1\n";
			  $db->setvar("dom_backup_schedule",$ddom_type."_".$week_day."_".$weekly_time);
			  break;
		  case 'monthly':
			  $times = explode(":",$monthly_time);
			  $crond_month = $month_day;
		    $para = "SCHEDULE";
			 // $crond = "${times[1]} ${times[0]} ${month_day} * * ".$cmd_path." SCHEDULE > /dev/null 2>&1\n";
			  $db->setvar("dom_backup_schedule",$ddom_type."_".$month_day."_".$monthly_time);
			  break;
			default:
			  $times = array( 0 => '*',
			                  1 => '0');
			  //$crond = "0 1 * * * ".$cmd_path." > /dev/null 2>&1\n";
			  $db->setvar("dom_backup_schedule",$ddom_type);
			  break;
	  }
	  $crond = "${times[1]} ${times[0]} ${crond_month} * ${crond_week} ${cmd_path} ${para} > /dev/null 2>&1\n";
	  set_crond($crond);	  
          unset($db);
	  flush();
	  return MessageBox(true,$words["ddom_title"],$words["ddom_enable_success"]);
  }
}

function set_crond($crond){
  global $cmd_path;
  $source=array();
  $file_content=file("/etc/cfg/crond.conf");  

  foreach($file_content as $line){
    if (!strpos($line,$cmd_path)) //look for $key in each line
      $source[]=$line;
  }
  
  if($crond!="clear"){
    $source[]=$crond;
  }
  $crond_result=join("",$source);  
  $fp=fopen("/etc/cfg/crond.conf","wb");
  fwrite($fp,$crond_result);  
  fclose($fp);
  shell_exec("cat /etc/cfg/crond.conf | crontab - -u root");
}

?>
