<?
require_once(INCLUDE_ROOT.'disk.class.php');
InvokeRPC('DiskRPC');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'commander.class.php');
$words = $session->PageCode("disk");
$gwords = $session->PageCode("global");
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();
//#################################################################
//#  Check sysconf value
//#################################################################
if (NAS_DB_KEY == '1'){
	$total_tray=trim(shell_exec("/img/bin/check_service.sh total_tray"));
	$three_bay_on=trim(shell_exec('cat /proc/thecus_io | grep "3BAY:" | cut -d" " -f2'));
	if($three_bay_on == "ON"){
	    $total_tray="3";
	}
}else{
	$total_tray=trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
}

$spindown=trim(shell_exec("/img/bin/check_service.sh spindown"));
$esata_tray=trim(shell_exec("/img/bin/check_service.sh esata"));
$esata_count=trim(shell_exec("/img/bin/check_service.sh esata_count"));
$esata_data = $esata_tray;
for($t=1;$t<$esata_count;$t++)
  $esata_data .= ":".sprintf($esata_tray+$t);
$esata_list=explode(':',$esata_data);
sort($esata_list);
//#################################################################
$class = new DISKINFO();
$disk_info=$class->getINFO();
$disk_list=$disk_info["DiskInfo"];
$spin_time=$class->getspintime();
$max_index=$disk_info["max_index"];
$total_size=0;
$spin_list="";
//$disk_data=array();
$edisk_data=array();
$usb_data=array();
$smartdev = $class->SMARTDevice();
$b_status='';
$badblock='';
$edisk_count=0;
$usb_count=0;
$usb_start_index=0;
$disk_total_capacity=0;

function get_hd_scan_value($hd_type,$hd_id){  
  global $b_status,$badblock,$disk_list,$smartdev,$gwords,$words;
  
  if($hd_type=="0"){
    //$strExec="/usr/sbin/smartctl -i -d $smartdev /dev/sd" . $disk_list[$hd_id][4] . "|awk -F':' '/Serial Number/{print substr($2,5,length($2))}'";
    //$HD_serial=trim(shell_exec($strExec));
    //$badblock_list=file("/var/tmp/HD/badblock_".$HD_serial);
    $badblock_list=file("/var/tmp/HD/badblock_".$hd_id);
  }else{
    $badblock_list=file("/var/tmp/HD/badblock_usb".$hd_id);
  }
  
  for($t=0;$t<sizeof($badblock_list);$t++)
    $badblock_scan[$t]=explode("=",trim($badblock_list[$t]));

  if(trim($badblock_scan[0][1]) == "1"){
    //$tmp_str=sprintf($words["disk_scanning"],$badblock_scan[1][1],"%");
      $b_status=sprintf($words["disk_scanning"],$badblock_scan[1][1],"%");
      $badblock='1';
  }else{
    $badblock='0';
    if(trim($badblock_scan[0][1]) == ""){ //status
       $b_status=$words["disk_no_scan"];
    }else{
      if(trim($badblock_scan[0][1]) == "2"){        
        $b_status=$words["abort_scan"];
      }else{
        if(trim($badblock_scan[2][1]) == "0" || trim($badblock_scan[2][1]) == ""){ //result
          $b_status=$gwords["healthy"];
        }else{
           $b_status = sprintf($words["disk_error"],$badblock_scan[2][1]);
        }
      }
    }
  }
}

$disk_data=$class->get_all_disk_data();
$disk_total_capacity=$total_size." (GB)";

foreach ($esata_list as $esata){
  if(($disk_list[$esata][5]=='0')&&($disk_list[$esata][1]!='N/A')&&($disk_list[$esata][2]!='N/A')){
    $edisk_count++;
    if($disk_list[$esata][5]=='0'){
      $diskno=$disk_list[$esata][4];
      $edisk_data[]=array('trayno'=>$esata,
                        'capacity'=>number_format($disk_list[$esata][0], 0)." GB",
                        'model'=>$disk_list[$esata][1],
                        'fireware'=>$disk_list[$esata][2],
                        'eject'=>$words["usb_eject"],
                        'b_status'=>$b_status,
                        'badblock'=>$badblock,
                        'diskno'=>$diskno,
                        'disk_type'=>'1',
                        'usb_sindex'=>$usb_start_index
                  );
    }
  }
}

for($i=0;$i< $max_index;$i++){
  if ($disk_list[$i][5] == "1"){
    $device="/dev/sd".trim($disk_list[$i][4]);//"/dev/sdx"
    $strExec="df | grep \"".$device."\"";
    $mount_exist=shell_exec($strExec);
    $diskno=$disk_list[$i][4];
    
    if($mount_exist != ""){
      $usb_count++;
      get_hd_scan_value('1',($i-$usb_start_index+1));
      $usb_data[]=array('trayno'=>$i,
                        'capacity'=>number_format($disk_list[$i][0], 0)." GB",
                        'model'=>$disk_list[$i][1],
                        'fireware'=>$disk_list[$i][2],
                        'eject'=>$words["usb_eject"],
                        'b_status'=>$b_status,
                        'badblock'=>$badblock,
                        'diskno'=>$diskno,
                        'disk_type'=>'1',
                        'usb_sindex'=>$usb_start_index
                  );        
    }else{
      $usb_start_index++;
    }
  }else{
    $usb_start_index++;
  }  
}


if($_GET['update']==1){
  die(json_encode(array('disk_data'=>$disk_data,
                        'edisk_data'=>$edisk_data,
                        'usb_data'=>$usb_data,
                        'edisk_count'=>$edisk_count,
                        'usb_count'=>$usb_count,
                        'disk_total_capacity'=>$disk_total_capacity)
                  )
     ); 
  exit;
}
if($NAS_DB_KEY == '1'){
	$disk_power_data="[[0,'OFF'],[241,'30'],[242,'60'],[243,'90'],[244,'120'],[245,'150'],[246,'180'],[247,'210'],[248,'240'],[249,'270'],[250,'300']]";
}else{
	$disk_power_data="[[0,'OFF'],[241,'30'],[242,'60'],[243,'90'],[244,'120']]";
}
$tpl->assign('display_hdd_photo',$sysconf['display_hdd_photo']);
$tpl->assign('words',$words);
$tpl->assign('capacity',$gwords['capacity']);
$tpl->assign('max_index',$max_index);
$tpl->assign('disk_list',json_encode($disk_list));
$tpl->assign('disk_data',json_encode($disk_data));
$tpl->assign('spindown',$spindown);
$tpl->assign('edisk_data',json_encode($edisk_data));
$tpl->assign('usb_data',json_encode($usb_data));
$tpl->assign('edisk_count',$edisk_count);
$tpl->assign('usb_count',$usb_count);
$tpl->assign('smartdev',$smartdev);
$tpl->assign('spin_time',$spin_time);
$tpl->assign('disk_power_data',$disk_power_data);
$tpl->assign('disk_total_capacity',$disk_total_capacity);
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY);
$tpl->assign('badblock_scan',$sysconf["badblock_scan"]);
$tpl->assign('MBTYPE',$thecus_io["MBTYPE"]);
$tpl->assign('lang',$session->lang);
?>
