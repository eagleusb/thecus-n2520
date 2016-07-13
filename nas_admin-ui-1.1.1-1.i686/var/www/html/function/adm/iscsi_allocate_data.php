<?
$open_mraid=trim(shell_exec("/img/bin/check_service.sh m_raid"));
$open_target_usb=trim(shell_exec("/img/bin/check_service.sh target_usb"));

include_once(INCLUDE_ROOT.'info/diskinfo.class.php');
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$md_num=$_POST["md"];
$type=$_POST['type'];
$target_iscsi=$_POST["target_iscsi"];
$target_lun=$_POST["target_lun"];
$target_iqn=$_POST["target_iqn"];
//echo "num=".$md_num;
$space_type=array('iscsi','lun','acl');
$raid=new RAIDINFO();
$info=$raid->getINFO($md_num);
$thin_lv="thinpool";
$iscsi_limit_size=16384;
$lun_data=array();
$connection_data=array();
$error_recovery_data=array();
$initR2T_data=array();
$words=$session->PageCode("raid");
$reserve_size=15; //reserve raid space

$raid_free=intval($info["RaidData"]-$info["RaidUsage"]);
$unused_size=$raid_free;
//echo $unused_percent;
$desp=$words["iscsi_block_size_msg"]."<br>".$words["iscsi_block_size_4k"]."<br>".$words["iscsi_block_size_512"];

if ($info["RaidFS"]=="xfs"){
  $iscsi_limit_size=65536;
}

if ($unused_size > $iscsi_limit_size){
  if ($info["RaidFS"]!="xfs"){
    $unused_size=$iscsi_limit_size-$reserve_size;
  }else{
    $unused_size=$unused_size-$reserve_size;
  }
}else{
  if ($unused_size > $reserve_size)
    $unused_size=$unused_size-$reserve_size;
  else{
    $unused_size=0;
    $raid_free=0;
  }
}

if($_REQUEST['querycapacity']) {
  die(json_encode(array(
                          'unused_size'=>$unused_size
                  ))
      );
}

if (($type==$space_type[2]."_add") || ($type==$space_type[2]."_modify")){
  $init_lun_data=array();
  $md_array=$raid->getMdArray();
  
  foreach($md_array as $md_id){
    $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select target,name from lun order by target\"";
    $result=shell_exec($strExec);
    $initlun=preg_split("/[\s\n]/",$result, -1, PREG_SPLIT_NO_EMPTY);

    foreach($initlun as $target){
        list($iscsiname, $lunname) = explode('|', $target);
        $acl_write=0;
        $acl_read=0;
        $acl_deny=0;
        
        if ($type==$space_type[2]."_modify"){
          $strExec = "/usr/bin/sqlite /raid".$md_id."/sys/smb.db \"select privilege from lun_acl where init_iqn='$target_iqn' and lunname='$lunname'\"";
          $result=shell_exec($strExec);
          
          if ($result[0]=="0"){
            $acl_write=1;
          }elseif ($result[0]=="1"){
            $acl_read=1;
          }elseif ($result[0]=="2"){
            $acl_deny=1;
          }else{
            $acl_deny=1;
          }
        }else{
          $acl_deny=1;
        }

        $init_lun_data[] = array('iscsiname'=>$iscsiname,
                                 'lunname'=>$lunname,
                                 'write'=>$acl_write,
                                 'read'=>$acl_read,
                                 'deny'=>$acl_deny
                                 );
    }
  }
  
  die(json_encode(array(
                          'init_lun_data'=>$init_lun_data,
                          'type'=>$type,
                          'iqn_name'=>$target_iqn
                       ))
      );
}else if($type==$space_type[0].'_expand'){
  $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select * from iscsi where name='".$target_iscsi."'\"";
  $db_info=shell_exec($strExec);
  $db_array=explode("|",$db_info);
  $crc_data=$db_array[11];
  $crc_header=$db_array[12];
  $connection=$db_array[13];
  $error_recovery=$db_array[14];
  $initR2T=$db_array[15];
  
  for($i=1; $i <= 8 ; $i++){
    $connection_data[] = array('connection_id'=>$i);
  }  
  
  for($i=0; $i <= 2 ; $i++){
    $error_recovery_data[] = array('error_recovery_id'=>$i);
  }
  
  $initR2T_data[] = array('initR2T_id'=>'Yes');
  $initR2T_data[] = array('initR2T_id'=>'No');
  
  if ($connection==""){
    $connection=8;
  }
  
  if ($error_recovery==""){
    $error_recovery=2;
  }

  if ($initR2T==""){
    $initR2T="No";
  }
      
  die(json_encode(array('crc_data'=>$crc_data,
                        'crc_header'=> $crc_header,
                        'connection_data'=>$connection_data,
                        'error_recovery_data'=>$error_recovery_data,
                        'initR2T_data'=>$initR2T_data,
                        'connection'=>$connection,
                        'error_recovery'=>$error_recovery,
                        'initR2T'=>$initR2T,
                        'unused_size'=>0,
                        'type'=>$type
                        ))
    );
}else if($type==$space_type[1].'_expand'){
  $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select * from lun where target='".$target_iscsi."' and name='".$target_lun."'\"";
  $db_info=shell_exec($strExec);
  $db_array=explode("|",$db_info);
  $lun_percent=$db_array[4];
  $lun_thin=$db_array[2];
  
  if (($lun_thin==1) || (($unused_size + $lun_percent)>= $iscsi_limit_size))
    $unused_size=$iscsi_limit_size- $lun_percent;
  
  $lv_capacity=$raid->getCapacity($md_num,$target_iscsi);
  $desp=$words["iscsi_expend_note"];
  die(json_encode(array('raidunused'=> $unused_size,
                      'iscsi_limit_size'=>$iscsi_limit_size,
                      'lun_name'=>$target_lun,
                      'unused_size'=>$unused_size,
                      'type'=>$type,
                      'lv_capacity'=>$lv_capacity,
                      'desp'=>$desp)
                      ));
}else{
  //######This LV info#####################################
  $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select * from iscsi where name='".$target_iscsi."'\"";
  $db_info=shell_exec($strExec);
  $db_array=explode("|",$db_info);
  $iscsi_name=$db_array[1];
  $enable=$db_array[2];
  $auth=$db_array[3];
  $username=$db_array[4];
  $password=$db_array[5];
  $mutual_auth=$db_array[6];
  $mutual_username=$db_array[7];
  $mutual_password=$db_array[8];
  $lv_capacity=$raid->getCapacity($md_num,$target_iscsi);
  //########################################################
  
  //########################################################
  //##    iSCSI Status & Initiator
  //########################################################
  $strExec="/img/bin/rc/rc.iscsi read_initiator $target_iscsi $md_num";
  $init_info=trim(shell_exec($strExec));
  $strExec="/img/bin/rc/rc.iscsi read_iqn $target_iscsi $md_num";
  $iscsi_iqn=trim(shell_exec($strExec));
  
  if($target_iscsi==""){
    $act="add";
    $year=date(Y);
    $month=date(m);
    $iscsi_block_size="512";
    $lun_thin="0";
  }else{
    $act="modify";
    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select year from iscsi where name='".$target_iscsi."'\"";
    $year=trim(shell_exec($strExec));
    $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select month from iscsi where name='".$target_iscsi."'\"";
    $month=trim(shell_exec($strExec));
    
    if($target_lun==""){
      $lun_thin="0";
    }else{
      $strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select * from lun where target='".$target_iscsi."' and name='".$target_lun."'\"";
      $db_info=shell_exec($strExec);
      $db_array=explode("|",$db_info);
      $lun_thin=$db_array[2];
      $lun_id=$db_array[3];
      $lun_percent=$db_array[4];
      $lun_block=$db_array[5];
    }
  }
  
  $year_data=array();  
  for($i=1990;$i<=2033;$i++){
    $year_data[]=array('year'=>$i);
    if($i==$year){
      $year_index=$i;
    }
  } 
  $month_data=array();
  for($i=1;$i<=12;$i++){
    if($i<10){
      $month_data[] = array('month'=>$i,'display'=>'0'.$i);
    }else
     $month_data[] = array('month'=>$i,'display'=>$i);
    if($i == $month){
      $month_index = $i;
    }  
  
  }
  if($enable=="0"){
    $enable = 0;
  }else{
    $enable = 1;
  }
  if($auth){
    $auth = 1;
  }else{
    $auth = 0;
  }

$lun_use_total_array=array();
$strExec="/usr/bin/sqlite /raid".$md_num."/sys/smb.db \"select id from lun where target='".$target_iscsi."'\"";
$lun_use_list=shell_exec($strExec);
$lun_use_array=explode("\n",$lun_use_list);
$lun_use_total_array=array_merge($lun_use_total_array,$lun_use_array);

$lun_index_flag=0;
for($i=0; $i <= 254 ; $i++){
  if(in_array("$i",$lun_use_total_array) == "" || trim($lun_id)==trim($i)){    
    $lun_data[] = array('lun_id'=>$i);
    if($lun_index_flag == 0){
      $lun_index = $i;
      $lun_index_flag = 1;
    }
  } 
}

if(trim($lun_id) != "")
   $lun_index = $lun_id;

die(json_encode(array('raidunused'=> $unused_size,
                      'raidid'=>$info["RaidID"],
                      'enable'=>$enable,
                      'auth'=>$auth,
                      'username'=>$username,
                      'password'=>$password,
                      'mutual_auth'=>$mutual_auth,
                      'mutual_username'=>$mutual_username,
                      'mutual_password'=>$mutual_password,
                      'iscsi_name'=>$iscsi_name,
                      'iscsi_iqn'=>$iscsi_iqn,
                      'init_info'=>$init_info,
                      'year_data'=>$year_data,
                      'month_data'=>$month_data,
                      'year_index'=>$year_index,
                      'month_index'=>$month_index,
                      'unused_size'=>$unused_size,
                      'iscsi_limit_size'=>$iscsi_limit_size,
                      'lv_capacity'=>$lv_capacity,
                      'target_iscsi'=>$target_iscsi,
                      'lunname'=>$target_lun,
                      'type'=>$type,
                      'thin_space'=>$thin_space,
                      'thin_max_space'=>$virtual_size_max,
                      'space_index'=>$space_index,
                      'lun_data'=>$lun_data,
                      'lun_index'=>$lun_index,
                      'desp'=>$desp,
                      'iscsi_block_size'=>$iscsi_block_size,
                      'lun_thin'=>$lun_thin,
                      'lun_id'=>$lun_id,
                      'lun_percent'=>$lun_percent,
                      'lun_block'=>$lun_block)
                      ));

}
?>
