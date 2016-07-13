<?
//#####################################
//##   Sysconf.txt
//#####################################
$open_iscsi=trim(shell_exec("/img/bin/check_service.sh iscsi_limit"));
$open_target_usb=trim(shell_exec("/img/bin/check_service.sh target_usb"));
$open_thin=trim(shell_exec("/img/bin/check_service.sh thin_provision"));
$open_encrypt=trim(shell_exec("/img/bin/check_service.sh encrypt_raid"));

if($open_iscsi!=0 || $open_target_usb==1){
include_once(INCLUDE_ROOT.'sqlitedb.class.php');
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
include_once(INCLUDE_ROOT.'function.php');
$open_snapshot=trim(shell_exec("/img/bin/check_service.sh snapshot"));
$hidden_column=0;
$md_num=$_POST["md"];
$select_action=$_POST["select_action"];
$select_type=$_POST["type"];
$words=$session->PageCode("raid");
$gwords=$session->PageCode("global");
$raid_info=array();
$iscsi_info=array();
$thin_iscsi_info=array();
$raid_combox_info=array();
$first_enter_flag=0;
$allocate_flag="1";
$unused_data=array();
//$has_usb=0;
$space_type=array('iscsi','thin_iscsi','usb','thin_iscsi_mb','advance_form');
$iscsi_disable_flag=0;
$thin_disable_flag=0;
$db=new sqlitedb();
$iscsi_block_size=$db->getvar("advance_iscsi_block_size","9");
$iscsi_crc=$db->getvar("advance_iscsi_crc","0");
unset($db);
$thin_lv="thinpool";
$iscsi_limit_size=16000;

if($md_num==''){  
  $first_enter_flag=1;
}

if($select_type==""){
  if($open_iscsi !=0) 
    $select_type = $space_type[0];
  elseif($open_target_usb !=0)
    $select_type = $space_type[1];
  elseif($open_thin != 0)
    $select_type = $space_type[2];
}

$iscsi_limit=$open_iscsi;
$thin_limit=$open_thin;
$uab_limit=$open_target_usb;
$open_mraid=trim(shell_exec("/img/bin/check_service.sh m_raid"));

if($open_mraid=="0"){
  $hidden_column=1;
}

//#####################################

/*$class = new DISKINFO();
$disk_info=$class->getINFO();
$disk_list=$disk_info["DiskInfo"];
//echo "<pre>";
//print_r($disk_info);
//echo "</pre>";
//$spin_time=$class->getspintime();
$max_index=$disk_info["max_index"];
*/
$raid=new RAIDINFO();
$md_array=$raid->getMdArray();

if($first_enter_flag==1)
{
  foreach($md_array as $md_id){
    $raid_encrypt=1;
    $usb_key=1;
    
    if($open_encrypt==1){   
      $raid_encrypt=check_encrypt($md_id,0);
      $usb_key=check_usbkey_exist($md_id,0);
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

$raid_name="raid".($md_num-1);
$raidinfo=$raid->getINFO($md_num);  
//iscsi count
$strExec="/usr/bin/sqlite /$raid_name/sys/raid.db \"select count(*) from iscsi\"";
$iscsi_count=trim(shell_exec($strExec));
//echo "<pre>";
//print_r($raidinfo);
//echo "</pre>";
//#####Global status analysis
/*$strExec="/bin/ls -al /var/tmp/";
$dir_list=shell_exec($strExec);
$dir_array=explode("\n",$dir_list);
$status_dir=array();

/*foreach($dir_array as $list){
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

//#####Button disable analysis
$new_button="1";
$config_button="1";
$allocate_button="1";
$md_array=$raid->getMdArray();

*/
$not_assign_disk=$raidinfo["NotAssignedList"];

$strExec="/bin/cat /var/tmp/raid".($md_num-1)."/rss";
$status=trim(shell_exec($strExec));
if($status!="Degraded" && $status!="Healthy" ){
 $allocate_flag="0";
}
/*if(!$md_array){
 $allocate_flag="0";
}
/*if($md_array){
  $md_count=count($md_array);
  if($not_assign_disk){
    $new_count="0";
    foreach($md_array as $num){
            //$a=preg_match("/Hea/",$status);
      //echo "a=".$a;
      if($status=="Healthy" || $status=="Degraded"){
        $new_count++;
      }
    }
  }else{
    $new_button="0";
  }  
}else{
  $allocate_flag="0";
}*/

$raid_infos=array();
if($raidinfo["RaidMaster"]=="1"){
  $raid_info[0]['m_raid']="*";
}else{
  $raid_info[0]['m_raid']="";
}
$raid_info[0]['id']=$raidinfo["RaidID"];
$raid_info[0]['raid_level']=$raidinfo["RaidLevel"];
$raid_info[0]['status']=$raidinfo["RaidStatus"];
$raid_info[0]['total_capacity']=$raidinfo["RaidTotal"];

$disk_data='';

for($i=0;$i<count($raidinfo["RaidList"]);$i++){
  $disk_data.=$raidinfo["RaidList"][$i];
  if($i<count($raidinfo["RaidList"])-1){
    $disk_data.=",";
  }
}

foreach($raidinfo["Spare"] as $v){
 $disk_data=$disk_data.",".$v;
}

$raid_info[0]['udisks']=$disk_data;

if($raidinfo["RaidUsage"]!="N/A" && $raidinfo["RaidData"]!="N/A"){
 $raid_info[0]['data_capacity']=$raidinfo["RaidUsage"]." GB / ".$raidinfo["RaidData"]." GB";
}else{
 $raid_info[0]['data_capacity']=$raidinfo["RaidData"];
}

if($open_snapshot=="1"){
  $raid_info[0]['snapshot_capacity']=$raidinfo["RaidSnapshot"];
  if($raidinfo["RaidSnapshot"]!="N/A"){
    $raid_info[0]['snapshot_capacity'].=" GB";
  }
}

if($open_target_usb=="1"){
  $raid_info[0]['usb_capacity']=$raidinfo["RaidUSB"];
  if($raidinfo["RaidUSB"]!="N/A"){
    $raid_info[0]['usb_capacity'].=" GB";
  }
}

if($open_iscsi!="0"){
  $raid_info[0]['iscsi_capacity']=$raidinfo["RaidiSCSI"];
  if($raidinfo["RaidiSCSI"]!="N/A"){
    $raid_info[0]['iscsi_capacity'].=" GB";
  }
}

$strExec = "/usr/bin/sqlite /".$raid_name."/sys/raid.db \"select sum(v2) from iscsi where v1='1'\"";
$virtual_size_use= shell_exec($strExec);
if($virtual_size_use == "") 
  $virtual_size_use = 0;
$virtual_size_max = $iscsi_limit_size - $virtual_size_use;    


//print_r($raid_info);
$lvname=array("lv1","snapshot","iscsi",$thin_lv);
$lv_name=array();

foreach($lvname as $v){
    $strExec="/bin/ls -l /dev/vg".($md_num-1)." | grep ".$v;
    $lv_info=shell_exec($strExec);
    $lv_array=explode("\n",$lv_info);
    foreach($lv_array as $list){
      $aryline=preg_split("/[\s ]+/",$list);
      if($list!=""){
        $lv_name[]=trim($aryline[8]);
      }
    }
}

foreach($lv_name as $lv){
  if(preg_match("/iscsi/",$lv)){
    $iSCSICapacity=$raid->getCapacity($md_num,$lv);
  }   

  if($lv=="lv1"){
    if($select_type == $space_type[2]){
      $iscsi_info[]=array('type'=>$gwords["target_usb"],
                          'name'=>$gwords["target_usb"],
                          'capacity'=>$raidinfo["RaidUSB"]." GB",
                          'modify_flag'=>0,
                          'lv'=>$lv);
      break;
    }
  }elseif($lv==$thin_lv){
    if($select_type == $space_type[1]){
      $strExec="ls -al /dev/mapper/vg".($md_num-1)."-".$thin_lv;
      $ret=shell_exec($strExec);
      if(trim($ret)!=""){
        $iscsi_info[]=array('type'=>$words["thin_space_title"],
                            'name'=>$words["thin_space_title"],
                            'capacity'=>$raid->getCapacity($md_num,$thin_lv)." GB",
                            'modify_flag'=>0,
                            'lv'=>$lv);
    
        $type=$words["thin_iscsi"];                
        $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select lvname,name,v2 from iscsi where v1='1'\"";
        $thin_infos=shell_exec($strExec); 
        $thin_data=array();
        $thin_items=explode("\n",$thin_infos);
        for($i=0 ; $i < count($thin_items)-1 ; $i++){
           $thin_data=explode("|",$thin_items[$i]);
           $thin_lv=$thin_data[0];
           $thin_iscsi_info[]=array('type'=>$type,
                                    'name'=>$thin_data[1],
                                    'capacity'=>$thin_data[2]." GB",
                                    'modify_flag'=>1,
                                    'lv'=>$thin_lv);                                    
        }
      }
      break;
    }    
  }elseif($select_type == $space_type[0]){
    $type=$words["iscsi_type"];
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select name from iscsi where lvname='$lv'\"";
    $name=shell_exec($strExec);
    if(preg_match("/iscsi/",$lv))
      $capacity=$iSCSICapacity." GB";
  
    $iscsi_info[]=array('type'=>$type,
                        'name'=>$name,
                        'capacity'=>$capacity,
                        'modify_flag'=>1,
                        'lv'=>$lv);
  }
}

if ($select_type == $space_type[0]){
  $iscsi_count="0";
  foreach($md_array as $md_id){
    $strExec = "/usr/bin/sqlite /raid".($md_id-1)."/sys/raid.db \"select count(name) from iscsi where v1=''\"";
    $iscsi_count=$iscsi_count+trim(shell_exec($strExec));
  }
}else{
  $iscsi_count=count($iscsi_info);
}

//$strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select count(name) from iscsi\"";
//$iscsi_count=trim(shell_exec($strExec));
if($iscsi_count >= $iscsi_limit && $select_type == $space_type[0]){
  $iscsi_disable_flag=1;
}elseif($iscsi_count == 1 && $select_type == $space_type[1]){
  $iscsi_disable_flag=1;
  if ($iscsi_count >= $thin_limit && $select_type == $space_type[3])
    $thin_disable_flag=1;
}elseif($iscsi_count >= $uab_limit && $select_type == $space_type[2]){
    $iscsi_disable_flag=1;
}

if($select_action==1){
  if($select_type != $space_type[4]){
    die(json_encode(array('raid_info'=>$raid_info,
                          'iscsi_info'=>$iscsi_info,
                          'allocate_flag'=>$allocate_flag,
                          'now_md'=>$md_num,
                          'raidunused'=>$raidinfo["RaidUnUsed"],
                          'has_usb'=>$has_usb,
                          'iscsi_disable_flag'=>$iscsi_disable_flag,
                          'thin_iscsi_info'=>$thin_iscsi_info,
                          'thin_max_space'=>$virtual_size_max,
                          'thin_disable_flag'=>$thin_disable_flag
                         ))
       );
  }else{
    die(json_encode(array('iscsi_block_size'=>$iscsi_block_size,
                        'iscsi_crc'=>$iscsi_crc,
                        'now_md'=>$md_num,
                        'raid_info'=>$raid_info
                       ))
      );
  }    
}

if($open_iscsi == "")
  $open_iscsi = 0;


if($open_target_usb == "")
  $open_target_usb = 0;
  
  
if($open_thin == "")
  $open_thin = 0;

$tpl->assign('words',$words);
$tpl->assign('open_snapshot',$open_snapshot);
$tpl->assign('open_target_usb',$open_target_usb);
$tpl->assign('open_iscsi',$open_iscsi);
$tpl->assign('hidden_column',$hidden_column);
$tpl->assign('raid_count',$raid_count);
$tpl->assign('iscsi_disable_flag',$iscsi_disable_flag);
$tpl->assign('raid_info',json_encode($raid_info));
$tpl->assign('iscsi_info',json_encode($iscsi_info));
$tpl->assign('raid_combox_info',json_encode($raid_combox_info));
$tpl->assign('allocate_flag',$allocate_flag);
$tpl->assign('now_md',$md_num);
$tpl->assign('raidunused',$raidinfo["RaidUnUsed"]);
$tpl->assign('has_usb',$has_usb);
$tpl->assign('block_size_data','[[12,"'.$words['iscsi_4k'].'"],[9,"'.$words['iscsi_512'].'"]]');
$tpl->assign('crc_data','[[1,"'.$gwords['enable'].'"],[0,"'.$gwords['disable'].'"]]');
$tpl->assign('iscsi_block_size',$iscsi_block_size);
$tpl->assign('iscsi_crc',$iscsi_crc);
$tpl->assign('space_type',json_encode($space_type));
$tpl->assign('open_thin',$open_thin);
$tpl->assign('thin_capacity_min',100);
$tpl->assign('thin_max_space',$virtual_size_max);  
$tpl->assign('thin_increment',100);  
$tpl->assign('thin_iscsi_info',$thin_iscsi_info); 
$tpl->assign('max_size_for_lv',$max_size_for_lv);
$tpl->assign('thin_disable_flag',$thin_disable_flag);
$tpl->assign('lang',$session->lang);
//$tpl->assign('unused_data'=>json_enconde($unused_data));
//$tpl->assign('unused_percent'=>$unused_percent);
}
?>