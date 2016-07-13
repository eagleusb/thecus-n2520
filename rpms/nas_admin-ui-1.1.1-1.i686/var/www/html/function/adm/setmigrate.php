<?
/*
session_start();
if(!$_SESSION['admin_auth']){
    header('Location: /unauth.htm');
    exit;
}
*/
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'raid.class.php');

$words = $session->PageCode("raid");
$gwords = $session->PageCode("global");
$lock=check_status_flag();
$md_num=trim($_POST["md_num"]);
$raid_lock=check_raid_status($md_num);
if($raid_lock=="1"){
   return  MessageBox(true,$words['raid_config_title'],$gwords["raid_nohealthy"],WARNING);
}
if($lock=="1"){
   return  MessageBox(true,$words['raid_config_title'],$gwords["raid_lock_warning"],WARNING);
}
$add_migrate_count=count($_POST["spare"]);

if ( $add_migrate_count < 1 ) {
    return  MessageBox(true,$words["raid_config_title"],$words["warn_nosel"],WARNING);
}

if(($add_migrate_count<2)&& ($_POST["_type"] == "5_6")){
  return  MessageBox(true,$words["raid_config_title"],$words["warn_sel2"],WARNING);
}
if(($add_migrate_count<4)&&($_POST["_type"] == "50_60")){
  return  MessageBox(true,$words["raid_config_title"],$words["warn_sel4"],WARNING);
}

if ( $_POST["check"] == "1" ) {
   die(json_encode(null));//return 1;
}

$migrate=array();
foreach($_POST["spare"] as $v){
  if($v!=""){
    $migrate[]=$v;
   }
}

//$_POST["_migrate_disk"]=$_POST["spare"];


ignore_user_abort(FALSE);
set_time_limit(0);
error_reporting(E_ERROR);
$Migrate_Status=shell_exec("ps");
if(preg_match("/raidreconf/",$Migrate_Status)){
  $Migrate_Status="1";
} else {
  $Migrate_Status="0";
}

if ($Migrate_Status=="1") {
  //Migration is progress ....
  return  MessageBox(true,$words["raid_config_title"],$words["migrate_is_progress"]." [ ".$errcode." ]",ERROR);
}

$class = new RAIDINFO();
$class->setmdselect(0);
$raid_info = $class->getINFO($md_num);
$RaidType=trim($raid_info['RaidLevel']);
$ChunkSize=trim($raid_info['ChunkSize']);

$class2 = new DISKINFO();
$disk_info=$class2->getINFO();
$disk_list=$disk_info["DiskInfo"];

foreach($raid_info["RaidList"] as $v){
  if($v!=""){
    $migrate[]=json_decode($v);
  }
}

$_POST["_migrate_disk"]=array();
foreach($migrate as $v){
  if($v!=""){
    $_POST["_migrate_disk"][]=$disk_list[$v][4];
  }
}
/*
die(
  json_encode(
    array(
      $_POST,
      $_POST["_migrate_disk"],
      $migrate,
      $disk_list,
      count($raid_info["RaidList"])
    )
  )
);

*/
if (($RaidType=="J") || ($RaidType=="10")) {
  //Not support Migrate  ....
  return  MessageBox(true,$words["raid_config_title"],$words["no_support"]." [ ".$errcode." ]",ERROR);
}else{
  $migrate_count=count($_POST["_migrate_disk"]);
  $type_array=explode("_",$_POST["_type"]);
  $current_type=trim($type_array[0]);
  $migrate_type=trim($type_array[1]);
  //return  MessageBox(true,$words["raid_config_title"],$words["warn_RAID6_1"],WARNING);
  if($migrate_type=="0" || $migrate_type=="1"){
    if($migrate_count<2){
      if($migrate_type=="0"){
        return  MessageBox(true,$words["raid_config_title"],$words["warn_toofew"],WARNING);
      }else{
        return  MessageBox(true,$words["raid_config_title"],$words["warn_RAID1_1"],WARNING);
      }
    }
  }elseif($migrate_type=="5"){
    if($migrate_count<3){
      return  MessageBox(true,$words["raid_config_title"],$words["warn_RAID5_1"],WARNING);
    }
  }elseif($migrate_type=="6"){
    if($migrate_count<4){
      return  MessageBox(true,$words["raid_config_title"],$words["warn_RAID6_1"],WARNING);
    }
  }elseif($migrate_type=="50"){
    if($migrate_count<6 || $add_migrate_count % 2){
      return  MessageBox(true,$words["raid_config_title"],$words["warn_RAID50_1"],WARNING);
    }
  }elseif($migrate_type=="60"){
    if($migrate_count<8 || $add_migrate_count % 2){
      return  MessageBox(true,$words["raid_config_title"],$words["warn_RAID60_1"],WARNING);
    }
  }
}

if(isset($_POST["lockm"]) && $_POST["lockm"]==1) {
  //===============================================================
  //  Then into real add spare mode
  //===============================================================
  
  $raid=new RAIDINFO();
  $raid->setmdselect(0);
  $miniexpandsize=1;
  $raid_info=$raid->getINFO($md_num);
  $raid_file_system=$raid_info["RaidFS"];
  $raid_date_size=$raid_info["RaidData_partition"];
 
  $raid=new raid();
  $limitation=$raid->check_limitation($raid_file_system,$raid_date_size);
  
  if($limitation == 1){
    return  MessageBox(true,$words["raid_config_title"],$words["ext3_8t_size_limit"],ERROR);
  }elseif($limitation == 2){
    return  MessageBox(true,$words["raid_config_title"],$words["ext4_16t_size_limit"],ERROR);
  }
  
  $raid->mdSwitch($md_num);
  if($migrate_type=="50" || $migrate_type=="60"){
    $result=$raid->nest_migrate($_POST);
  }else{
    $result=$raid->migrate($_POST);
  }

  $ary=array('ok'=>'gotoRaidInfo()');
  if($result!=0){
    //return $result;
    $Msg=getMsg($result);
    if(($result==100)||($result==101)){
      return  MessageBox(true,$words["raid_config_title"],$Msg,INFO,OK,$ary);
    }else{
      return  MessageBox(true,$words["raid_config_title"],$Msg,ERROR);
    }
  }
  return  MessageBox(true,$words["raid_config_title"],$words["createRAIDSuccess"],INFO,OK,$ary);
} else {
  return  MessageBox(true,$words["raid_config_title"],$words["migrate_is_progress"]." [ ".$errcode." ]",ERROR);
}

function getMsg($errcode){
  global $words;
  switch ($errcode){
    case 1:
      $msg=$words["migrate_is_progress"]." [ ".$errcode." ]";
      break;
    case 2:
      $msg=$words["no_support"]." [ ".$errcode." ]";
      break;
    case 3:
      $msg=$words["migrate_type_warning"]." [ ".$errcode." ]";
      break;
    case 4:
      $msg=$words["old_type_diff"]." [ ".$errcode." ]";
      break;
    case 5:
      $msg=$words["type_diff"]." [ ".$errcode." ]";
      break;
    case 6:
      $msg=$words["old_conf_not_open"]." [ ".$errcode." ]";
      break;
    case 7:
      $msg=$words["new_conf_not_open"]." [ ".$errcode." ]";
      break;
    case 10:
      $msg=$words["size_error"]." [ ".$errcode." ]";
      break;
    case 11:
      $msg=$words["not_migrate_type"]." [ ".$errcode." ]";
      break;
    case 12:
      $msg=$words["not_migrate_type"]." [ ".$errcode." ]";
      break;
    case 13:
      $msg=$words["size_not_enough"]." [ ".$errcode." ]";
      break;
    case 100:
      $msg=$words["createRAIDSuccess_online"];
      break;
    case 101:
      $msg=$words["createRAIDSuccess_offline"];
      break;
    default:
      $msg=$words["createRAIDError"] . "[" . $errcode. "]";
  }
  return $msg;
}

?>
