<?
//#####################################
//##   Sysconf.txt
//#####################################
$open_iscsi=trim(shell_exec("/img/bin/check_service.sh iscsi_limit"));
$open_encrypt=trim(shell_exec("/img/bin/check_service.sh encrypt_raid"));

if($open_iscsi!=0){
include_once(INCLUDE_ROOT.'sqlitedb.class.php');
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
include_once(INCLUDE_ROOT.'function.php');
$open_snapshot=trim(shell_exec("/img/bin/check_service.sh snapshot"));
$hidden_column=0;
$md_num=$_POST["md"];
$select_action=$_POST["select_action"];
$select_type=$_POST["type"];
$o_iscsi_name=$_POST["iscsiname"];
$words=$session->PageCode("raid");
$gwords=$session->PageCode("global");
$raid_info=array();
$iscsi_info=array();
$lun_info=array();
$raid_combox_info=array();
$first_enter_flag=0;
$allocate_flag="1";
$unused_data=array();
$space_type=array('iscsi','lun','acl');
$iscsi_disable_flag=0;
$reserve_size=15; //reserve raid space

$db=new sqlitedb();
$iscsi_enabled=$db->getvar("iscsi","0");
$isns_enabled=$db->getvar("isns_enable","0");
$isns_ip=$db->getvar("isns_ip","");
unset($db);

$iscsi_block_size="512";
$lun_thin="0";

$iscsi_limit_size=16384;

if($md_num==''){  
  $first_enter_flag=1;
}

if($select_type==""){
  if($open_iscsi !=0) 
    $select_type = $space_type[0];
}

$iscsi_limit=$open_iscsi;
$open_mraid=trim(shell_exec("/img/bin/check_service.sh m_raid"));

if($open_mraid=="0"){
  $hidden_column=1;
}

$raid=new RAIDINFO();
$md_array=$raid->getMdArray();

if($first_enter_flag==1)
{
  foreach($md_array as $md_id){
    $raid_encrypt=1;
    $usb_key=1;
    
    if($open_encrypt==1){   
      //$raid_encrypt=check_encrypt($md_id,0);
      //$usb_key=check_usbkey_exist($md_id,0);
    }

    if($raid_encrypt==1 && $usb_key==1){
      $raid_data=$raid->getINFO($md_id);
      $raid_combox_info[]=array('md_num'=>$md_id,'raidid'=>$raid_data["RaidID"]);
    }
  }
}

$raid_count=count($raid_combox_info);
if($md_num==''){
  if(count($raid_combox_info)!=0){
   $md_num=$raid_combox_info[0]['md_num'];
  }else{
   $tpl->assign('no_raid_flag',1);
  } 
}

$raid_name="raid".($md_num);
$raidinfo=$raid->getINFO($md_num);  

$not_assign_disk=$raidinfo["NotAssignedList"];

$strExec="/bin/cat /var/tmp/raid".$md_num."/rss";
$status=trim(shell_exec($strExec));
if($status!="Degraded" && $status!="Healthy" ){
 $allocate_flag="0";
}

$raid_infos=array();
if($raidinfo["RaidMaster"]=="1"){
  $raid_info[0]['m_raid']="*";
}else{
  $raid_info[0]['m_raid']="";
}
$raid_info[0]['id']=$raidinfo["RaidID"];
$raid_info[0]['raid_level']=$raidinfo["RaidLevel"];
$raid_info[0]['status']=changeLanguage($raidinfo["RaidStatus"]);
$raid_info[0]['total_capacity']=$raidinfo["RaidTotal"];
$raid_info[0]['fs']=$raidinfo["RaidFS"];

$disk_data='';

for($i=0;$i<count($raidinfo["LocPosList"]);$i++){
  $disk_data.=$raidinfo["LocPosList"][$i];
  if($i<count($raidinfo["LocPosList"])-1){
    $disk_data.=",";
  }
}

foreach($raidinfo["Spare"] as $v){
 $disk_data=$disk_data.",".$v;
}

$raid_info[0]['udisks']=$disk_data;
if (file_exists("/raidsys/" . $md_num . "/HugeVolume"))
    $raid_info[0]['udisks']="VE";
 
if (file_exists("/tmp/ha_role")){
    $ha_role=trim(shell_exec("cat /tmp/ha_role"));
    if ($ha_role == "active")
        $raid_info[0]['udisks']="HA";
}

if($raidinfo["RaidUsage"]!="N/A" && $raidinfo["RaidData"]!="N/A"){
 $raid_info[0]['data_capacity']=$raidinfo["RaidUsage"]." GB / ".$raidinfo["RaidData"]." GB";
}else{
 $raid_info[0]['data_capacity']=$raidinfo["RaidData"];
}

//check if the iscsi table is exist
shell_exec("/img/bin/rc/rc.iscsi check_table '" . $md_num ."'");
//check if building LUN
$strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select name, enabled from iscsi\"";
$result=shell_exec($strExec);
$iscsi=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);
$build_status="";

foreach($iscsi as $iscsiname){
  list($target, $enabled) = explode('|', $iscsiname);
    
  $strExec="/img/bin/rc/rc.iscsi 'target_status' '$target' '$md_num'";
  $status=trim(shell_exec($strExec));
    
  if (strstr($status, 'Building LUN')){
    $build_status="iSCSI Target [" . $target . "]: " . $status;
  }
}

if($select_type == $space_type[0]){
  $type=$words["iscsi_type"];
  $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select name, enabled from iscsi\"";
  $result=shell_exec($strExec);
  $iscsi=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);
  
  foreach($iscsi as $iscsiname){
    list($target, $enabled) = explode('|', $iscsiname);
    
  $strExec="/img/bin/rc/rc.iscsi 'target_status' '$target' '$md_num'";
  $status=trim(shell_exec($strExec));
    
  if (strstr($status, 'Building LUN')){
    $build_status="iSCSI Target [" . $target . "]: " . $status;
  }
/*  
    if (($enabled=="1") && ($iscsi_enabled==1)){
      $enabled="Enabled";
    }else{
      $enabled="Disabled";
    }
*/
    $iscsi_info[]=array('type'=>$type,
                        'name'=>$target,
                        'capacity'=>$status,
                        'modify_flag'=>1,
                        'lv'=>"111");
                        
    if (count($lun_info)==0){
      if ($o_iscsi_name!=""){
        $target=$o_iscsi_name;
      }
      
      $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select name, percent,thin from lun where target='".$target."'\"";
      $result=shell_exec($strExec);
      $lun=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);
      
      foreach($lun as $lunitem){
        list($lunname, $percent, $thin) = explode('|', $lunitem);
        if ($thin==0)
          $thin=$words["instant_allocation"];
        else
          $thin=$words["thin_provision"];
        
        $lun_info[]=array('type'=>$words["lun"],
                          'name'=>$lunname,
                          'capacity'=>$percent,
                          'modify_flag'=>$thin,
                          'lv'=>$target);
      }
    }
  }
  
  $iscsi_count="0";
  foreach($md_array as $md_id){
    $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select count(name) from iscsi\"";
    $iscsi_count=$iscsi_count+trim(shell_exec($strExec));
  }
}elseif ($select_type == $space_type[1]){
  $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select name, percent,thin from lun where target='".$o_iscsi_name."'\"";
  $result=shell_exec($strExec);
  $lun=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);

  foreach($lun as $lunitem){
    list($lunname, $percent, $thin) = explode('|', $lunitem);
    
    if ($thin==0)
      $thin=$words["instant_allocation"];
    else
      $thin=$words["thin_provision"];
      
    $lun_info[]=array('type'=>$words["lun"],
                      'name'=>$lunname,
                      'capacity'=>$percent,
                      'modify_flag'=>$thin,
                      'lv'=>$o_iscsi_name);
  }
}

if($iscsi_count >= $iscsi_limit && $select_type == $space_type[0]){
  $iscsi_disable_flag=1;
}

$init_iqn_data=array();
foreach($md_array as $md_id){
  $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select distinct init_iqn from lun_acl\"";
  $result=shell_exec($strExec);
  $initiqn=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);

  foreach($initiqn as $target){
    if (!(in_array(array('init_iqn'=>$target), $init_iqn_data, true))) {
      $init_iqn_data[] = array('init_iqn'=>$target);
    }
  }
}

$raid_free=$raidinfo["RaidData"]-$raidinfo["RaidUsage"];
if ($raid_free <= $reserve_size){
  $raid_free=0;
}
  
if($select_action==1){
  if($select_type == $space_type[0]){
    die(json_encode(array('raid_info'=>$raid_info,
                          'iscsi_info'=>$iscsi_info,
                          'build_status'=>$build_status,
                          'lun_info'=>$lun_info,
                          'allocate_flag'=>$allocate_flag,
                          'now_md'=>$md_num,
                          'raidunused'=>$raid_free,
                          'has_usb'=>$has_usb,
                          'iscsi_disable_flag'=>$iscsi_disable_flag,
                          'thin_iscsi_info'=>$thin_iscsi_info,
                          'thin_disable_flag'=>$thin_disable_flag,
                          'iscsi_block_size'=>$iscsi_block_size,
                          'lun_thin'=>$lun_thin
                         ))
       );
  }elseif ($select_type == $space_type[1]){
    die(json_encode(array('lun_info'=>$lun_info,
                          'build_status'=>$build_status
                         ))
       );
  }else{
    die(json_encode(array('raid_info'=>$raid_info,
                          'init_iqn_data'=>$init_iqn_data,
                          'init_lun_data'=>$init_lun_data,
                          'build_status'=>$build_status,
                          'now_md'=>$md_num
                       ))
      );
  }    
}

if($open_iscsi == "")
  $open_iscsi = 0;

$tpl->assign('words',$words);
$tpl->assign('open_snapshot',$open_snapshot);
$tpl->assign('open_iscsi',$open_iscsi);
$tpl->assign('hidden_column',$hidden_column);
$tpl->assign('raid_count',$raid_count);
$tpl->assign('raid_info',json_encode($raid_info));
$tpl->assign('iscsi_info',json_encode($iscsi_info));
$tpl->assign('build_status',$build_status);
$tpl->assign('lun_info',json_encode($lun_info));
$tpl->assign('raid_combox_info',json_encode($raid_combox_info));
$tpl->assign('allocate_flag',$allocate_flag);
$tpl->assign('now_md',$md_num);
$tpl->assign('raidunused',$raid_free);
$tpl->assign('space_type',json_encode($space_type));
$tpl->assign('thin_capacity_min',100);
$tpl->assign('block_size_data','[[4096,"'.$words['iscsi_4k'].'"],[512,"'.$words['iscsi_512'].'"]]');
$tpl->assign('iscsi_block_size',$iscsi_block_size);
$tpl->assign('lun_thin',$lun_thin);
$tpl->assign('init_iqn_data',json_encode($init_iqn_data));
$tpl->assign('iscsi_connection',json_encode($init_iqn_data));
$tpl->assign('iscsi_enabled',$iscsi_enabled);
$tpl->assign('isns_enabled',$isns_enabled);
$tpl->assign('isns_ip',$isns_ip);
$tpl->assign('iscsi_limit_size',$iscsi_limit_size);
}
?>
