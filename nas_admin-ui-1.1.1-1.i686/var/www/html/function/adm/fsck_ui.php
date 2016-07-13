<?
require_once(INCLUDE_ROOT."info/raidinfo.class.php");

$gwords = $session->PageCode("global");
$words = $session->PageCode("fsck");
$rwords = $session->PageCode("raid");

if(file_exists("/tmp/lns.lock")){
	$fsck_lock="1";
	$fsck_dev=file("/tmp/fsck_dev");
	$fsck_dev=implode(",",$fsck_dev);
	$fsck_dev=str_replace("\n","",$fsck_dev);
	
}else{
	$fsck_lock="0";
}

if(trim($_GET["action"])=="getlog"){
    $data=array();
    if(file_exists("/tmp/lns_sys.log") || file_exists("/tmp/lns_lv.log") || file_exists("/tmp/lns.lock")){
        if(!is_file("/tmp/lns_sys.log")){
            $log_name="lns_lv";
            analysis_log($log_name,$words);
        }else{
            $log_name="lns_sys";
            analysis_log($log_name,$words);
        }
    }
    $e2fsck_exit_sys=trim(shell_exec('/usr/bin/awk -F] \'/\\[EXITCODE\\]/{print $2}\' /tmp/lns_sys.log'));
    $e2fsck_exit_lv=trim(shell_exec('/usr/bin/awk -F] \'/\\[EXITCODE\\]/{print $2}\' /tmp/lns_lv.log'));
    $fsck_result=' ';
    if(file_exists("/tmp/fsck.log")){
        //$result_list=file("/tmp/fsck.log");
        $fsck_result=shell_exec("cat /tmp/fsck.log");
    }
    
    die(
        json_encode(
            array(
                'fsck_lock'=>$fsck_lock,
                'e2fsck_exit_sys'=>$e2fsck_exit_sys,
                'e2fsck_exit_lv'=>$e2fsck_exit_lv,
                'fsck_status'=>$e2fsck_stat,
                'fsck_info'=>$e2fsck_latest20,
                'fsck_result'=>$fsck_result
            )
        )
    );
}else if(trim($_GET["action"])=="getstatus"){
    $class=new RAIDINFO();
    $fsck_list=fsck_list();
    die(json_encode($fsck_list));
}else{
    $open_mraid=trim(shell_exec("/img/bin/check_service.sh m_raid"));

    if($open_mraid=="0"){
        $hidden="visibility:hidden;position:absolute;";
    }
    
    $class=new RAIDINFO();
    
    $fs_zfs=trim(shell_exec("/img/bin/check_service.sh \"fs_zfs\""));
    $encrypt_raid=trim(shell_exec("/img/bin/check_service.sh \"encrypt_raid\""));
    $fsck_list=fsck_list();
    //if(file_exists("/tmp/lns.lock")){
    //  $fsck_log=$words["doing_fsck"];
    //}
}

$tpl->assign('gwords',$gwords);
$tpl->assign('words',$words);
$tpl->assign('rwords',$rwords);
$tpl->assign('form_action','setmain.php?fun=setfsck_ui');
$tpl->assign('geturl','getmain.php?fun=fsck_ui');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('fs_zfs',$fs_zfs);
$tpl->assign('encrypt_raid',$encrypt_raid);
$tpl->assign('fsck_lock',$fsck_lock);
$tpl->assign('fsck_dev',$fsck_dev);
$tpl->assign('fsck_list',json_encode($fsck_list));
//$tpl->assign('fsck_log',$fsck_log);

function fsck_list(){
  global $raid_info,$class,$words,$hidden;
  $fsck_array=array();
  $md_array=$class->getMdArray();
  $flag="1";
  foreach($md_array as $md_num){
    $list=array();
    $disks="";
    if (NAS_DB_KEY==1)
      $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='filesystem'\"";
    elseif (NAS_DB_KEY==2)
      $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='filesystem'\"";
      
    $filesystem=trim(shell_exec($strExec));
    
   if (NAS_DB_KEY==1)
      $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='encrypt'\"";
    else
      $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='encrypt'\"";
    
    $use_encrypt="0";
    
    if($filesystem=="zfs" || $use_encrypt=="1"){
      continue;
    }
    $md_name="md$md_num";
    $raid_info=$class->getINFO($md_num);
    //echo "<pre>";
    //print_r($raid_info);
    //echo "</pre>";
    
    if(trim($raid_info["RaidLevel"]) == "J"){
      $level="JBOD";
    }else{
      $level="RAID".trim($raid_info["RaidLevel"]);
    }
    
    for($i=0;$i<count($raid_info["LocPosList"]);$i++){
      $disks.=$raid_info["LocPosList"][$i];
      if($i<count($raid_info["LocPosList"])-1){
        $disks.=",";
      }
    }
    foreach($raid_info["LocPosSpare"] as $v){
      $disks.=",";
      $disks.="<font color='blue'>".$v."</font>";
    }
    $status=trim($raid_info["RaidStatus"]);
    
    $fs_status=get_fs_status($md_num);
    
    if($raid_info["RaidUsage"]!="N/A" && $raid_info["RaidData"]!="N/A"){
      $capacity=$raid_info["RaidUsage"]." GB / ".$raid_info["RaidData"]." GB";
    }else{
      $capacity=$raid_info["RaidData"];
    }
    if (NAS_DB_KEY==1)
        $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='fsck_last_time'\"";
    elseif (NAS_DB_KEY==2)
        $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='fsck_last_time'\"";
    
    $filesystem=shell_exec("/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='filesystem'\"");
    $raid_id=shell_exec("cat /tmp/raid".($md_num)."/raid_id");
    $fsck_last_time=shell_exec($strExec);
    $fsck_array[]=array(
    		'md_num'=>$md_num,
    		'raid_level'=>$level,
                'raid_id'=>$raid_id,
                'filesystem'=>$filesystem,
    		'disks'=>$disks,
    		'raid_status'=>$status,
    		'fs_status'=>$fs_status,
    		'capacity'=>$capacity,
    		'fsck_last_time'=>$fsck_last_time
    );
  }
  /*
    $fsck_array[]=array(
    		'md_num'=>$md_num+1,
    		'raid_level'=>$level,
    		'disks'=>$disks,
    		'raid_status'=>$status,
    		'fs_status'=>$fs_status,
    		'capacity'=>$capacity,
    		'fsck_last_time'=>$fsck_last_time
    );
    */
    return $fsck_array;
  
}

function get_fs_status($md_num){
  global $words;
  $status="";
  $month=array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
  $limit_day="180";
  $limit_time=${limit_day}*24*60*60;
  if (NAS_DB_KEY==1)
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='encrypt'\"";
  else
    $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='encrypt'\"";

  $use_encrypt=trim(shell_exec($strExec));
  //###############################################
  //#	Check data volume mount point
  //###############################################
  if (NAS_DB_KEY==1)
  {
    $vg_name="vg".($md_num-1);
    $strExec="df | awk '/\/dev\/${vg_name}\/lv0/{print}'";
  }
  elseif (NAS_DB_KEY==2)
  {
    if($use_encrypt=="1")
      $vg_name="loop".($md_num+50);
    else
      $vg_name="md".($md_num);
    $strExec="df | awk '/\/dev\/${vg_name}/{print}'";
  }
  
  $mount_point=shell_exec($strExec);
  if($mount_point==""){
    $status="<font color='red'><b>".$words["data_not_mount"]."</b></font>";
    return $status;
  }
  
  //###############################################
  //#	Check system volume mount point
  //###############################################
  if (NAS_DB_KEY==1)
      $strExec="df | awk '/\/dev\/${vg_name}\/syslv/{print}'";
  elseif (NAS_DB_KEY==2)
      $strExec="df | awk '/\/dev\/${vg_name}/{print}'";

  $mount_point=shell_exec($strExec);
  if($mount_point==""){
    $status="<font color='red'><b>".$words["sys_not_mount"]."</b></font>";
    return $status;
  }
  
  //###############################################
  //#	Check data volume dirty?
  //###############################################
  $strExec="dumpe2fs -h /dev/${vg_name}/lv0 | awk '/Filesystem state:/{print $3}'";
  $status=trim(shell_exec($strExec));
  if($status=="dirty"){
    $status="<font color='red'><b>".$words["data_dirty"]."</b></font>";
    return $status;
  }
  
  //###############################################
  //#	Check system volume dirty?
  //###############################################
  $strExec="dumpe2fs -h /dev/${vg_name}/syslv | awk '/Filesystem state:/{print $3}'";
  $status=trim(shell_exec($strExec));
  if($status=="dirty"){
    $status="<font color='red'><b>".$words["sys_dirty"]."</b></font>";
    return $status;
  }
  
  //###############################################
  //#	Check data volume how long not fsck
  //###############################################
  $strExec="dumpe2fs -h /dev/${vg_name}/lv0 | awk -F'checked:' '/Last checked:/{print $2}'";
  $last_date=trim(shell_exec($strExec));
  $last_time=strtotime($last_date);
  $now_time_array=gettimeofday();
  $now_time=$now_time_array[sec];
  $how_long=$now_time-$last_time;
  if($how_log > $limit_time){
    $status=sprintf($words["data_long_time"],$limit_day);
    $status="<font color='red'><b>".$status."</b></font>";
    return $status;
  }
  
  //###############################################
  //#	Check system volume how long not fsck
  //###############################################
  $strExec="dumpe2fs -h /dev/${vg_name}/syslv | awk -F'checked:' '/Last checked:/{print $2}'";
  $last_date=trim(shell_exec($strExec));
  $last_time=strtotime($last_date);
  $now_time_array=gettimeofday();
  $now_time=$now_time_array[sec];
  $how_long=$now_time-$last_time;
  if($how_log > $limit_time){
    $status=sprintf($words["sys_long_time"],$limit_day);
    $status="<font color='red'><b>".$status."</b></font>";
    return $status;
  }
  //###############################################
  $status="<font color='green'><b>".$words["normal"]."</b></font>";
  return $status;
}

function analysis_log($log_name,$words){
	global $gwords,$log_name,$words,$e2fsck_latest20,$e2fsck_stat,$e2fsck_exit;
	shell_exec('/bin/cp -f /tmp/'.$log_name.'.log /tmp/'.$log_name.'.tmp');
	if(trim(shell_exec('/bin/cat /tmp/'.$log_name.'.tmp | /usr/bin/wc -l'))){
		$e2fsck_stat=trim(shell_exec('/usr/bin/awk -F] \'/\\[STATUS\\]/{print $2}\' /tmp/'.$log_name.'.log'));
		//$e2fsck_latest20=trim(shell_exec('/usr/bin/awk \'NR==2,NR==21{if (NR==2){printf "%s<br>",$0}else{printf "&nbsp;%s<br>",$0}}\' /tmp/'.$log_name.'.tmp'));
		$e2fsck_latest20=trim(shell_exec('/usr/bin/awk \'NR==2,NR==21{printf "%s\n",$0}\' /tmp/'.$log_name.'.tmp'));
	}else{
		$e2fsck_stat=$gwords['wait_msg'];
		$e2fsck_latest20="";
	}
}
?>
