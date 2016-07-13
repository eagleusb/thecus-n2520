<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("ddom");
$gwords = $session->PageCode("global"); 
$process = "/img/bin/dom_backup.sh";
$backup_file_path = "/raid/data/_SYS_TMP/dual_dom/save/";
//$status_path = "/raid/data/_SYS_TMP/dual_dom/ddom_status";
$success_file_path = "/raid/data/_SYS_TMP/dual_dom/save_tmp/SUCCESS";
$rsuccess_file_path = "/raid/data/_SYS_TMP/dual_dom/save_tmp/REAL_SUCCESS";
$status_path = "/tmp/ddom_status";
$backup_file_data = array();
$ddom_status = "";
$update = $_GET["update"];
$rand = $_GET["rand"];

//analyse Doul dom status
$strExec = "/bin/ps www | grep ".$process." | grep -v grep";
$is_processing = shell_exec($strExec);
$status = file($status_path);
if($is_processing != ""){  
  $process_flag = 1;  
  $is_manual = strpos($is_processing,"MANUAL");
  $is_schedule = strpos($is_processing,"SCHEDULE");
  if ($is_manual !="" || $is_schedule !="" || !is_file($success_file_path)){
    $ddom_status = $words["ddom_manual_start"];
    if (trim($status[0]) != "2"){
      $fp = fopen($status_path,"w+");
      fwrite($fp,"2");
      fclose($fp);
    }
  }  
}else{
  $process_flag = 0;    
  
  if(trim($status[0]) !=""){
    $fp = fopen($status_path,"w+");  

    if(trim($status[0]) == "2"){
      if(is_file($rsuccess_file_path))
        $ddom_status = $words["ddom_backup_finish"];
      else
        $ddom_status = $words["ddom_backup_fail"];
      fwrite($fp,"1\n".$rand);
      if ($update == 1){
        get_backup_list();
      }    
    }elseif(trim($status[0]) == "1"){
      if($status[1] != $rand){
        if(is_file($rsuccess_file_path))
          $ddom_status = $words["ddom_backup_finish"];
        else
          $ddom_status = $words["ddom_backup_fail"];
      }  
      fwrite($fp,"0");  
    }  
    fclose($fp);
  }  
}

if ($update == 1){
  die(json_encode(array('ddom_status'=> $ddom_status,
                        'list_store'=> $list_data,
                        'process_flag'=> $process_flag)
                  ));

}

$db = new sqlitedb();
$ddom_enable = $db->getvar('dom_backup_enabled','1');
$ddom_schedule = $db->getvar('dom_backup_schedule','auto');
//dual dom default setting value
$ddom_default_setting = array(
  "type" => "auto",
  "d_time" => "00:00",
  "w_default" => "0",
  "w_time" => "00:00",
  "m_default" => "1",
  "m_time" => "00:00"
);

//day 1 - 31
$day_fields = "['display', 'value']";
$day_data = "[";
for($i=1; $i <= 31; $i++){
	//$_hour = $i < 10 ? "0".$i : $i;
	$_day = $i;
	$day_data .= "['$_day','$_day']";
	if ($i<31)
		$day_data .= ",";
}
$day_data .= "]";

//week 0-6
$week_fields = "['display', 'value']";
$week_day_list = array(
	"0"=>$gwords['sunday'],
	"1"=>$gwords['monday'],
	"2"=>$gwords['tuesday'],
	"3"=>$gwords['wednesday'],
	"4"=>$gwords['thursday'],
	"5"=>$gwords['friday'],
	"6"=>$gwords['saturday']
);
$week_data = "[";

foreach($week_day_list as $value=>$display){
	if($display != ""){
		if($default_week == ""){
			$default_week = $display;
		}
		$week_data .= "['$display','$value'],";
	}
}
$week_data = substr($week_data,0,strlen($week_data)-1);
$week_data .= "]";

//analyse DB Dual dom value
$schedule_data = explode("_",$ddom_schedule);
$ddom_default_setting["type"] = $schedule_data[0];

switch($schedule_data[0]){
    case "daily" :
      $ddom_default_setting["d_time"] = $schedule_data[1];
      break;
    case "weekly" :
      $ddom_default_setting["w_default"] = $schedule_data[1];
      $ddom_default_setting["w_time"] = $schedule_data[2];
      break;
    case "monthly" :    
      $ddom_default_setting["m_default"] = $schedule_data[1];
      $ddom_default_setting["m_time"] = $schedule_data[2];
      break;
    default :
      break;
}

get_backup_list();

unset($db);
$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('day_fields',$day_fields);
$tpl->assign('day_data',$day_data);
$tpl->assign('week_fields',$week_fields);
$tpl->assign('week_data',$week_data);
$tpl->assign('default_week',$default_week);
$tpl->assign('ddom_default_setting',$ddom_default_setting);
$tpl->assign('ddom_enable',$ddom_enable);
$tpl->assign('item_type',json_encode($item_type));
$tpl->assign("process_flag",$process_flag);
$tpl->assign("list_store",json_encode($list_data));
$tpl->assign("ddom_status",$ddom_status);

function get_backup_list(){
  global $list_data,$backup_file_path;
  //analyse dual dom backup file info
  $strExec="ls $backup_file_path";
  $file_array=shell_exec($strExec);
  $file_list=explode("\n",$file_array);

  for($i=0; $i<=count($file_list)-2; $i++){
    $file_data = explode("_",$file_list[$i]);
    $list_data[] = array('task'=>$file_data[0]."_".$file_data[2],
                       'date'=>substr($file_data[3],0,4)."/".substr($file_data[3],4,2)."/".substr($file_data[3],6,2)." ".substr($file_data[3],8,2).":".substr($file_data[3],10,2),
                       'fw'=>$file_data[4]
                       );
  }
  
  sort($list_data,SORT_STRING);
}
?>
