<?
/*
include_once("../../inc/info/diskinfo.class.php");
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);
//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if(!$is_function){
  require_once("/var/www/html/inc/function.php");
  check_system("0","access_warning","about");
}
//#######################################################
*/
//require_once(DOC_ROOT.'utility/transferDB.class.php');
//$trans=new transDB();
//$trans->trans_bat("raid_conf","raid");
//$trans->trans_once("fsck","Raid_level","fsck","Raid_level");
//exit;

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'function.php');

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$db=new sqlitedb();
$ha_enable=$db->getvar("ha_enable","0");
$ha_role=$db->getvar("ha_role","0");
$ha_heartbeat = $db->getvar("ha_heartbeat", HA_HEARTBEAT); //eth2
unset($db);
//error_reporting(E_ALL^E_NOTICE^E_WARNING);
//ini_set('display_errors', '1');
get_sysconf();

$ha_btn = '0';
$ha = $sysconf['ha'];
if($ha=='1'){
    $ha_btn = '1';
}
$ha_btn_show = 0;
if(file_exists("/raidsys/0/ha_raid") && file_exists("/raidsys/0/ha_inited")){
    $ha_btn_show = 1;
}
if(trim(file_get_contents("/var/tmp/ha_role"))){
    $ha_btn_show = 0;
}
/**
 * Interface array
 */
$ha_heartbeat_txt = "LAN3"; 
$interface_num = 3;
$interfaces = array();
$check_bond_cmd="/img/bin/function/get_interface_info.sh 'check_eth_bond' ";
$ret=trim(shell_exec($check_bond_cmd."'".HA_HEARTBEAT."'"));
if( $ret == ""){
	array_push($interfaces,array('id'=>HA_HEARTBEAT,'name'=>'LAN3'));
}

$ph = popen("ifconfig", "r");
while (!feof($ph)){
	$line = fgets($ph, 4096);
	if (preg_match("/Link encap/i", $line, $match)){
		list($eth) = explode(" ",$line);
		if (preg_match("/^eth[4-99]/i", $eth, $match2)){
			$interface_num++;	
		}
	
		if (preg_match("/^geth/i", $eth, $match3)){
			$ret=trim(shell_exec($check_bond_cmd."'".$eth."'"));
			if( $ret == ""){
				$ethlist=file("/tmp/all_interface");
				foreach($ethlist as $v){
					$ethinfo=explode("|",$v);
					if( $ethinfo[0] == $eth){
						$interface_num=$ethinfo[1];
					}
				}
				$tengTxt = $gwords['10gbe'].$interface_num;
				array_push($interfaces, array('id'=>$eth, 'name'=>$tengTxt));
			
				//transfer ha_heartbeat lan3 wording
				if($ha_heartbeat == $eth){
					$ha_heartbeat_txt = $tengTxt;
				}
			}
		}
	}
}
pclose($ph);
$interfaces = json_encode($interfaces);

$ip = shell_exec("ifconfig eth0 |grep \"inet addr:\" |awk '{print $2}'|cut -c 6-"); 
$ipary = explode(".",$ip);
$ipexr = $ipary[0].'.'.$ipary[1].'.'.$ipary[2];

$randValue = rand(9999).time();
$gwords = $session->PageCode("global");
$rwords = $session->PageCode("raid");
$dwords = $session->PageCode("disk");

$total_raid_limit_msg=sprintf($rwords["total_raid_limit"],$sysconf["total_raid_limit"]);
$action=($_POST["action"]!="")?trim($_POST["action"]):trim($_GET["action"]);
if(($action =="getdisklist")||($action =="edit")||($action =="migration")||($action =="gethotspare")){
$class = new DISKINFO();
$disk_info=$class->getINFO();
$disk_list=$disk_info["DiskInfo"];
$max_index=$disk_info["max_index"];
}
//###########################################
//#  Expand initial setting
//###########################################
$miniexpandsize=1;
$expandsize=0;

//###########################################
//#  Parser Disk list
//###########################################
$disk=array();
$spare=array();
$current_disk=0;
if (NAS_DB_KEY == '1'){
  $total_tray=trim(shell_exec("/img/bin/check_service.sh total_tray"));
  $three_bay_on=trim(shell_exec('cat /proc/thecus_io | grep "3BAY:" | cut -d" " -f2'));
  if($three_bay_on == "ON"){
      $total_tray="3";
  }
}else{
  $total_tray=trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
}
$open_encrypt=trim(shell_exec("/img/bin/check_service.sh encrypt_raid"));
if($open_encrypt && trim($_POST["md_num"])!=""){
    check_encrypt(trim($_POST["md_num"]),1);
    check_usbkey_exist(trim($_POST["md_num"]),1);
}

$unused_disk_count=$disk_info["unused_disk_count"];


//###########################################
//echo "<pre>";print_r($disk);exit;
$raid=new RAIDINFO();
$raid->setmdselect(0);
$raid_list=raid_list();

$action=($_POST["action"]!="")?trim($_POST["action"]):trim($_GET["action"]);
$md_num=($_POST["md_num"]!="")?trim($_POST["md_num"]):"";
if (NAS_DB_KEY == '1'){
  $raid_no="raid".($md_num-1);
}else{
  $raid_no="raid".($md_num);
}
if (NAS_DB_KEY == '1'){
  $raid_db="/".$raid_no."/sys/raid.db";
}else{
  $raid_db="/".$raid_no."/sys/smb.db";
}

//#####Button disable analysis

$new_button="1";
$config_button="1";
$allocate_button="1";
$md_array=$raid->getMdArray();
$total_raid_count=count($md_array);

$not_assign_count="0";
foreach($md_array as $num){
  $info=$raid->getINFO($num);
  $not_assign_count=$not_assign_count+count($info["NotAssignedList"]);
}

if($md_array){
  $md_count=count($md_array);
  if($not_assign_count){
    $new_count="0";
    foreach($md_array as $num){
      if (NAS_DB_KEY == '1'){
        $strExec="/bin/cat /var/tmp/raid".($num-1)."/rss";
      }else{
        $strExec="/bin/cat /var/tmp/raid".($num)."/rss";
      }
      $status=trim(shell_exec($strExec));
      if($status=="Healthy" || $status=="Degraded"){
        $new_count++;
      }
    }
    if($new_count==$md_count && $sysconf["m_raid"]!="0"){
      $new_button="1";
    }else{
      $new_button="0";
    }
  }else{
    $new_button="0";
  }  
}else{
  $new_button="1";
  $config_button="0";
  $allocate_button="0";
}


if($action=="getraidlist"){
  die(
    json_encode(
      array('raid_list'=>$raid_list)
    )
  );
}elseif($action=="gethotspare"){
  $disk=$class->get_all_disk_data();
  $spare=$class->get_spare_disk_data();
  die(
    json_encode(
      array(
        //'spare_list'=>$spare,
		'result' => $spare
      )
    )
  );
}elseif($action=="getdisklist"){
  $total_tray=trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
  $disk=$class->get_all_disk_data();
  die(
    json_encode(
      array(
        'disk_list'=>$disk,
        'current_disk'=>$current_disk
      )
    )
  );
}elseif($action=="edit" && $md_num!=""){
  $info=$raid->getINFO($md_num);
  $percentage=sprintf("%s",round(($info["RaidData_partition"]*100)/$info["RaidTotal"]));
  $lock=check_status_flag();
  $raid_lock=check_raid_status($md_num);
    //check exists ha raid
  $exists_ha_raid = 0;
  if (file_exists("/raidsys/$md_num/ha_raid")){
        $exists_ha_raid = 1;
  }
  /*
  $db=new sqlitedb($raid_db,"conf");
  $percentage=$db->getvar("percent_data","");
  $db->db_close();
  */
  die(
    json_encode(
      array(
        'md_num'=>$md_num,
        'percentage'=>$percentage,
        'raid_info'=>$info,
        'disk_list'=>$disk,
        'current_disk'=>$current_disk,
        'lock'=>$lock,
        'raid_lock'=>$raid_lock,
        'unused_disk_count'=>$unused_disk_count,
  'ha_enable'=>$ha_enable,
  'ha_raid'=>$exists_ha_raid
      )
    )
  );
}elseif($action=="check_zfs"){
  $zfs_status=check_zfs_count();
  $msg=sprintf($rwords["zfs_count_limit"],$zfs_limit);
  $fsmode=trim($_POST["fsmod"]);
  if($fsmode=="zfs" && $zfs_status=="1"){
    die(
      json_encode(
        array(
          'zfs_status'=>$zfs_status,
          'msg'=>$msg
        )
      )
    );
  }else{
    die(
      json_encode(
        array(
          'zfs_status'=>"0",
          'msg'=>$msg
        )
      )
    );
  }
}elseif($action=="expand" && $md_num!=""){
  $miniexpandsize=1;
  $info=$raid->getINFO($md_num);
  $expandsize=$info["RaidUnUsed"];
  $unused_percent=round(($info["RaidUnUsed"]/$info["RaidTotal"])*100);
  $max_size_for_ext3=8*1024;//UNIT: GB
  $raid_file_system=$info["RaidFS"];
  $raid_data_size=$info["RaidData_partition"];
  if($expandsize < $miniexpandsize){
    $expand=0;
  }else{
    $expand=1;
  }
  die(
    json_encode(
      array(
        'unused_size'=>$expandsize,
        'unused_percent'=>$unused_percent,
        'max_size_for_ext3'=>$max_size_for_ext3,
        'fsmod'=>$raid_file_system,
        'raid_data_size'=>$raid_data_size,
        'expand'=>$expand
      )
    )
  );
}elseif($action=="migration" && $md_num!=""){
  $info=$raid->getINFO($md_num);
  die(
    json_encode(
      array(
        'md_num'=>$md_num,
        'raid_info'=>$info,
        'disk_list'=>$disk,
        'current_disk'=>$current_disk
      )
    )
  );
}elseif($action=="getAccessStatus" && $md_num==""){
  $mke2fs_cmd="/sbin/mke2fs -j -m 0 -b 4096 -i 4096";
  $strExec="/bin/ls -al /var/tmp/";
  $dir_list=shell_exec($strExec);
  $dir_array=explode("\n",$dir_list);
  $status_dir=array();
  $dir_num=array();
  foreach($dir_array as $list){
    $aryline=preg_split("/[\s ]+/",$list);
    if(preg_match("/raid[0-9]$/",$aryline[8]) && $aryline[8]!="raidlock"){
      $status_dir[]=$aryline[8];
      $dir_num[]=$aryline[8][4];
    }
  }
  foreach($status_dir as $raid){
    $reload=0;
    $edit=0;
    $num=substr($raid,4,strlen($raid)-4);
    $status="";
    $old_status="";
    $strExec="/bin/cat /var/tmp/$raid/rss";
    $status=trim(shell_exec($strExec));
    $strExec="/bin/cat /var/tmp/$raid/old_rss";
    $old_status=trim(shell_exec($strExec));
    $strExec="/bin/cat /var/tmp/raidlock";
    $lock=trim(shell_exec($strExec));
    if($status!=$old_status){
      $strExec="echo -e \"".$status."\" > /var/tmp/$raid/old_rss";
      shell_exec($strExec);
      $reload=1;
    }

    $JBOD_Status=shell_exec("/bin/ps");

    if(preg_match("/jbod_resize.sh [0-9]/",$JBOD_Status))
      $reload=1;
    if(preg_match("/post_create [0-9]/",$JBOD_Status))
      $reload=1;
    if(preg_match("/raid_build [0-9]/",$JBOD_Status))
      $reload=1;
    if(preg_match("/raid_rebuild [0-9]/",$JBOD_Status))
      $reload=1;
      
    if(preg_match("/e2fsck/",$JBOD_Status)){
      preg_match_all("/\s*=*\s*[\\/|-]\s*(\d*\.\d*%)/",$status,$matches);
      $prompt = (trim($matches[1][count($matches[1])-1])=="")? $gwords["wait"]."...":$matches[1][count($matches[1])-1];
      $status = "Check Disk ".$prompt;
      $reload=1;
    }

    if(preg_match("/resize2fs/",$JBOD_Status)){
      $prompt = (substr_count($status,"X")==0)? $gwords["wait"]."...":round(substr_count($status,"X")/160,2)*100 ." %";
      $status = "Resize Disk ".$prompt;
      $reload=1;
    }
    
    if( preg_match("/Migrating/", $status) ) {
        $reload=1;
    }
    
    if($status != "Healthy"){
      $strExec="/bin/cat /var/tmp/$raid/raid_id";
      $raid_id=trim(shell_exec($strExec));
      $div_status="<font color='red'>".changeLanguage($status)."</font>";
      $div_value.=sprintf($rwords["global_status"],$raid_id,$div_status);
      break;
    }
  }
  
  if($status=="Healthy" && $reload=="1"){
    $status=$gwords["wait_msg"];
    $div_status="<font color='red'>".changeLanguage($status)."</font>";
    $div_value.=sprintf($rwords["global_status"],"",$div_status);
  }

  if(($status=="Healthy" && $reload=="0")||($status=="Degraded")){
    $edit=1;
  }

  die(
    json_encode(
      array(
        'status_dir'=>$status_dir,
        'dir_num'=>$dir_num,
        'div_value'=>$div_value,
        'status'=>$status,
        'edit'=>$edit,
        'reload'=>$reload,
        'res'=>$res,
        'total_raid_limit'=>$sysconf["total_raid_limit"],
        'create_btn'=>$new_button,
        'ha_enable'=>$ha_enable,
        'total_haraid_limit'=>$sysconf["total_haraid_limit"]
      )
    )
  );
}


//#####Global status analysis
$strExec="/bin/ls -al /var/tmp/";
$dir_list=shell_exec($strExec);
$dir_array=explode("\n",$dir_list);
$status_dir=array();
foreach($dir_array as $list){
  $aryline=preg_split("/[\s ]+/",$list);
  if(preg_match("/raid/",$aryline[8]) && $aryline[8]!="raidlock"){
    $status_dir[]=$aryline[8];
  }
}
$raid_count=count($status_dir);
$status_count="0";
foreach($status_dir as $dir){
  $strExec="/bin/cat /var/tmp/".$dir."/rss";
  $global_status=trim(shell_exec($strExec));
  if($global_status=="Healthy" || $global_status=="Degraded" || $global_status=="N/A" || $global_status==""){
    $status_count++;
  }
}

if($status_count==$raid_count){
  $global_status="1";
}else{
  $global_status="0";
}

$strExec="/bin/cat /var/tmp/raidlock";
$lock=trim(shell_exec($strExec));

//#############################################################
//#  Chunk size value
//#############################################################
$chunk_fields="['value', 'display']";
$chunk_data="[";
$chunk_data.="['32','32'],";
$chunk_data.="['64','64'],";
$chunk_data.="['128','128'],";
$chunk_data.="['256','256'],";
$chunk_data.="['512','512'],";
$chunk_data.="['1024','1024'],";
$chunk_data.="['2048','2048'],";
$chunk_data.="['4096','4096']";
$chunk_data.="]";
$default_chunk="64";
//#############################################################
//#  All File System
//#############################################################
$fs_zfs = $sysconf["fs_zfs"];
$fs_fields="['value', 'display']";
$fs_data="[";
//$fs_data.="['ext3','".$gwords["ext3"]."'],";
$fs_data.="['ext4','".$gwords["ext4"]."']";
if($sysconf["fs_zfs"]=="1"){
   $fs_data.="['zfs','".$gwords["zfs"]."'],";
} 
if($sysconf["fs_btrfs"]=="1"){
   $fs_data.="['btrfs','".$gwords["btrfs"]."'],";
}
//$fs_data.="['xfs','".$gwords["xfs"]."']";
$fs_data.="]";
$default_fs="ext4";
//#############################################################

//$raid_list["raid_list"]=$raid;
//echo "<pre>";print_r($raid_list);exit;

//#############################################################
//#  Transfer to template
//#############################################################
$tpl->assign('gwords',$gwords);
$tpl->assign('rwords',$rwords);
$tpl->assign('dwords',$dwords);
$tpl->assign('ha_btn',$ha_btn);
$tpl->assign('ha_btn_show',$ha_btn_show);
$tpl->assign('ha_enable', $ha_enable);
$tpl->assign('ipexr',$ipexr);
$tpl->assign('randValue',$randValue);
$tpl->assign('form_action','setmain.php?fun=setraid');
$tpl->assign('form_action2','setmain.php?fun=setdestroyraid');
$tpl->assign('action_expand','setmain.php?fun=setexpand');
$tpl->assign('action_migrate','setmain.php?fun=setmigrate');
$tpl->assign('action_hot_spare','setmain.php?fun=sethotspare');
$tpl->assign('geturl','getmain.php?fun=raid');
$tpl->assign('sysconf',$sysconf);
$tpl->assign('total_raid_limit_msg',$total_raid_limit_msg);
$tpl->assign('chunk_fields',$chunk_fields);
$tpl->assign('chunk_data',$chunk_data);
$tpl->assign('default_chunk',$default_chunk);
$tpl->assign('fs_fields',$fs_fields);
$tpl->assign('fs_data',$fs_data);
$tpl->assign('default_fs',$default_fs);
$tpl->assign('create_button',$new_button);
$tpl->assign('config_button',$config_button);
$tpl->assign('disk_count',$current_disk);
$tpl->assign('lock',json_encode($lock));
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY);
$tpl->assign('display_pie_chart',$sysconf["display_pie_chart"]);
$tpl->assign('max_tray',$thecus_io["MAX_TRAY"]);
$tpl->assign('open_encrypt',$open_encrypt);
$tpl->assign('lang',$session->lang);
$tpl->assign('offline_migrate',$sysconf["offline_migrate"]);
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('recover_show',$_REQUEST['recover_show']);
$tpl->assign("interface_data",$interfaces);
$tpl->assign("interface_default",$ha_heartbeat);
//#############################################################

function raid_list(){
  global $raid_info,$raid,$sysconf,$ha_enable,$ha_role;
  $md_array=$raid->getMdArray();
  $raid_list=array();
  
  $ha_status='N/A';

  foreach($md_array as $k=>$md_num){
    if (file_exists("/raidsys/$md_num/HugeVolume")) continue;
    $k=count($raid_list);
    if($md_num <200 ){ // while migrating temp raid is 200 + mdnum
      $raid_info=$raid->getINFO($md_num);
      $raid_list[$k]["md_num"]=$md_num;
      //########## md select
      $select_md=$_COOKIE["select_md"];
      //########## raid master
      if($raid_info["RaidMaster"]=="1") {
          $raid_master="*";
      }else{
          $raid_master="";
      }
      $raid_list[$k]["master"]=$raid_master;
      //########## raid id
      $raid_id=$raid_info["RaidID"];
      $raid_list[$k]["raid_id"]=$raid_id;
      //########## raid level
      $raid_level=$raid_info["RaidLevel"];
      $raid_list[$k]["raid_level"]=$raid_level;
      //########## raid status
      $raid_status=$raid_info["RaidStatus"];
      $raid_list[$k]["raid_status"]=$raid_status;
      //########## raid disk list
      $raid_disk="";
      for($i=0;$i<count($raid_info["LocPosList"]);$i++){
        $raid_disk.=$raid_info["LocPosList"][$i];
        if($i<count($raid_info["LocPosList"])-1){
          $raid_disk.=",";
        }
      }
      //########## raid spare disk
      foreach($raid_info["LocPosSpare"] as $v){
        if($v!=""){
          $raid_disk.=",<span style='color:gray'>".$v."</span>";
          //$raid_disk.="aa";
        }
      }
      if (strncmp($raid_info["RaidStatus"],"Migrating",9) == 0){
        $raid_info_temp=$raid->getINFO($md_num+200); // while migrating temp raid num is mdnum+200
          foreach($raid_info_temp["LocPosList"] as $v){
            if($v!=""){
                  $raid_disk.=",".$v;
                }
          }
      }
      $raid_list[$k]["raid_disk"]=$raid_disk;
      //########## Total capacity
      $total_capacity=$raid_info["RaidTotal"]." GB";
      $raid_list[$k]["total_capacity"]=$total_capacity;
      //########## Raid data capacity
      if(($raid_info["RaidUsage"]!="N/A") && ($raid_info["RaidData"]!="N/A")){
        $data_capacity=$raid_info["RaidUsage"]." GB / ".$raid_info["RaidData"]." GB";
      }else{
        if (file_exists("/raidsys/$k/ha_raid")){
          $data_capacity = "Used for HA";
        }else{
          $data_capacity=$raid_info["RaidData"]." GB";
	}
        if(($raid_info["RaidData"] == "N/A")&&($raid_list[$k]["raid_status"] == "Healthy")){
          if (!file_exists("/raidsys/$k/ha_raid")){
            $raid_list[$k]["raid_status"] = "N/A";
          }
        }
      }
      $raid_list[$k]["data_capacity"]=$data_capacity;
      //########## USB capacity
      if($sysconf["target_usb"]=="1"){
        $usb_capacity=$raid_info["RaidUSB"];
        if($raid_info["RaidUSB"]!="N/A"){
          $usb_capacity.=" GB";
        }
      }
      $raid_list[$k]["usb_capacity"]=$usb_capacity;
       //########## iSCSI target capacity
       if($sysconf["iscsi_limit"]!="0"){
         $iscsi_capacity=$raid_info["RaidiSCSI"];
         if($raid_info["RaidiSCSI"]!="N/A"){
          $iscsi_capacity.=" GB";
        }
      }
      $raid_list[$k]["iscsi_capacity"]=$iscsi_capacity;
      //########## Data partition and unused
      $raid_list[$k]["data_partition"]=$raid_info["RaidData_partition"];
      $raid_list[$k]["unused"]=$raid_info["RaidUnUsed"];
      $raid_list[$k]["encrypt"]=$raid_info["Encrypt"];
      $raid_list[$k]["filesystem"]=$raid_info["RaidFS"];
    }
   }
  return $raid_list;
}
?>
