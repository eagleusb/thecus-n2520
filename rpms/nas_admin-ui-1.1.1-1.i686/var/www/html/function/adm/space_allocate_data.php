<?
$open_mraid=trim(shell_exec("/img/bin/check_service.sh m_raid"));
$open_target_usb=trim(shell_exec("/img/bin/check_service.sh target_usb"));
$open_thin=trim(shell_exec("/img/bin/check_service.sh thin_provision"));
$iscsi_method=trim(shell_exec("/img/bin/check_service.sh iscsi_method"));

include_once(INCLUDE_ROOT.'info/diskinfo.class.php');
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$md_num=$_POST["md"];
$type=$_POST['type'];
$lvname=$_POST["lv"];
//echo "num=".$md_num;
$space_type=array('iscsi','thin_iscsi','usb','thin_iscsi_mb','advance_form');
$raid=new RAIDINFO();
$info=$raid->getINFO($md_num);
$thin_lv="thinpool";
$iscsi_limit_size=16000;
$lun_data=array();
$words=$session->PageCode("raid");

if($info["RaidUnUsed"]<"0"){
  $info["RaidUnUsed"]="0";
}
$unused_percent=round(($info["RaidUnUsed"]/$info["RaidTotal"])*100);
//echo $unused_percent;
$desp=$words["iscsi_block_size_msg"]."<br>".$words["iscsi_block_size_4k"]."<br>".$words["iscsi_block_size_512"];
function get_unused_percent(){
  global $unused_percent,$unused_data,$unused_data_index;
  if($unused_percent<="1"){
    $unused_data[]=array('capacity'=>$unused_percent);
  }else{
    for($i=1;$i<$unused_percent;$i++){
      $unused_data[]=array('capacity'=>$i);
      if($i<"10"){
        contiune;
      }else{            
        $i=$i+4;
      }
    }        
  }
  $unused_data[]=array('capacity'=>$unused_percent);
  $unused_data_index=$unused_percent;
}

if($type==$space_type[2]."_add" || $type==$space_type[1]."_add"){
get_unused_percent();
if($type==$space_type[2]."_add"){
  $desp=$words["usb_desp"];
}
die(json_encode(array('unused_percent'=>$unused_percent,
                      'raidunused'=>$info["RaidUnUsed"],
                      'unused_data'=>$unused_data,
                      'raidid'=>$info["RaidID"],
                      'unused_data_index'=>$unused_data_index,
                      'type'=>$type,
                      'desp'=>$desp)
    ));
//}else if($type==$space_type[0].'_expand'){
}else if(trim(strstr($type,"_expand")) != ""){
  get_unused_percent();
  if($type==$space_type[0].'_expand'){
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select * from iscsi where lvname='".$lvname."'\"";
    $db_info=shell_exec($strExec);
    $db_array=explode("|",$db_info);
    $iscsi_name=$db_array[1];
  }else{
    $iscsi_name=$info["RaidID"];
  }
  
  $lv_capacity=$raid->getCapacity($md_num,$lvname);
  $desp=$words["iscsi_expend_note"];
  die(json_encode(array('unused_percent'=>$unused_percent,
                      'raidunused'=> $info["RaidUnUsed"],
                      'unused_data'=>$unused_data,
                      'iscsi_name'=>$iscsi_name,
                      'unused_data_index'=>$unused_data_index,
                      'type'=>$type,
                      'lv_capacity'=>$lv_capacity,
                      'desp'=>$desp)
                      ));
//}else if($type==$space_type[0].'_add' || $type==$space_type[0].'_modify'){
}else{
  if(trim(strstr($type,$space_type[3]))){
    $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select sum(v2) from iscsi where v1='1'\"";
    $virtual_size_use= shell_exec($strExec);
    if($virtual_size_use == "") 
      $virtual_size_use = 0;
    $virtual_size_max = $iscsi_limit_size - $virtual_size_use;    
    $thin_space=$raid->getCapacity($md_num,$thin_lv);
    if ($type == $space_type[3]."_add"){
      $space_index = $thin_space;
    }else{
      $strExec = "/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v2 from iscsi where lvname='".$lvname."'\"";
      $space_index = shell_exec($strExec);
    }  
  }
  //echo "num=".$md_num;
  //######This LV info#####################################
  $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select * from iscsi where lvname='".$lvname."'\"";
  $db_info=shell_exec($strExec);
  $db_array=explode("|",$db_info);
  $iscsi_name=$db_array[1];
  $enable=$db_array[2];
  $auth=$db_array[3];
  $username=$db_array[4];
  $password=$db_array[5];
  $iscsi_percent=$db_array[6];
  $provision=$db_array[10];
  $virtual_size=$db_array[11];
  $lun_id=$db_array[12];
  $lv_capacity=$raid->getCapacity($md_num,$lvname);
  //########################################################
  
  //########################################################
  //##    iSCSI Status & Initiator
  //########################################################
  $strExec="/img/bin/check_service.sh iscsi_method";  
  $check_iscsi=shell_exec($strExec);
 
  if($check_iscsi == 1){
    $iscsi_session=file("/proc/net/iet/session");
  }
  $this_iscsi=array();
  $num=$md_num-1;
  
  if($iscsi_percent!=""){
    $unused_data[]=array('capacity'=>$iscsi_percent);
    $unused_data_index=$iscsi_percent;
  }else{
    get_unused_percent();
  }
  
  $iscsi_iqn="";
  $init_info="";
  
  if($check_iscsi == 1){
  
    if ( trim($lvname) != ""){
      for($c=0;$c<count($iscsi_session);$c++){
          if(preg_match("/tid:/",$iscsi_session[$c])){
            $this_tid_info=explode(" ",$iscsi_session[$c]);
            $this_tid=$this_tid_info[0];
          }else{
            $iscsi_session[$c]=$this_tid." ".$iscsi_session[$c];
          }
        $dev_name=$lvname.".vg".$num;
        if(preg_match("/$dev_name/",$iscsi_session[$c])){
          $tid_info=explode(" ",$iscsi_session[$c]);
          $tid=trim($this_tid_info[0]);
        }
        if(preg_match("/$tid/",$iscsi_session[$c]) && $this_tid==$tid){
          $this_iscsi[]=trim(str_replace($tid,"",trim($iscsi_session[$c])));
        }
    
      }
      $target_iqn=explode(":",$this_iscsi[0]);
      if($target_iqn[1]!="" && $target_iqn[2]!=""){
        $iscsi_iqn=$target_iqn[1].":".$target_iqn[2];
      }
      foreach($this_iscsi as $k=>$v){
        if($v!="" && $k!="0"){
          if(preg_match("/sid/",$v)){
            $init_array=explode(" ",$v);
            $init=$init_array[1];
          }
          if(preg_match("/cid/",$v)){
            $info_array=explode(" ",$v);
            $ip=$info_array[1];
            $status=$info_array[2];
          } 
          if($init!="" && $ip!="" && $status!=""){
            $init_info.=$init."\n";
            $init_info.=$ip."\n";
            $init_info.=$status."\n";
            $init="";
            $ip="";
            $status="";
          }
        }
      }
    }

  }elseif($check_iscsi == 2){ 

    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='raid_name'\"";
    $raid_name=trim(shell_exec($strExec));

    $strExec="ls /sys/kernel/scst_tgt/targets/iscsi/|grep ".($raid_name).".".$lvname.".vg".($md_num-1);
    $iscsi_iqn=trim(shell_exec($strExec));
  
    $strExec="ls /sys/kernel/scst_tgt/targets/iscsi/".($iscsi_iqn)."/sessions/";
    $initiator_array=shell_exec(trim($strExec));
    $array=explode("\n",$initiator_array);
    $loop=count($array);
    for($c=0;$c<($loop-1);$c++){
      if($array[$c] != "")
      {
        $init_info=$init_info."initiator: ".$array[$c]."\n";
        $strExec="ls /sys/kernel/scst_tgt/targets/iscsi/".($iscsi_iqn)."/sessions/".$array[$c]." |awk '/[*.*.*.*]/{print $1}'";
        $ip=trim(shell_exec($strExec));
        $init_info=$init_info."ip:".$ip."\n";
        $strExec="cat /sys/kernel/scst_tgt/targets/iscsi/".($iscsi_iqn)."/sessions/".$array[$c]."/".$ip."/state"; 
        $state=shell_exec(trim($strExec));
        $init_info=$init_info."state:".$state."\n\n";
      }
    }
  }else{
    echo "ERROR!!";
    return 1;
  }
  
  if($lvname==""){
    $year=date(Y);
    $month=date(m);
  }else{
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select year from iscsi where lvname='$lvname'\"";
    $year=trim(shell_exec($strExec));
    $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select month from iscsi where lvname='$lvname'\"";
    $month=trim(shell_exec($strExec));
  }
  
  if($lvname==""){
   $act="add";
  }else{
   $act="modify";
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
  if($enable){
    $enable = 1;
  }else{
    $enable = 0;
  }
  if($auth){
    $auth = 1;
  }else{
    $auth = 0;
  }

$raidunused = $info["RaidUnUsed"];
$lun_use_total_array=array();
$md_array=$raid->getMdArray();
foreach($md_array as $md_id){
  $strExec="/usr/bin/sqlite /raid".($md_id-1)."/sys/raid.db \"select v3 from iscsi \"";
  $lun_use_list=shell_exec($strExec);
  $lun_use_array=explode("\n",$lun_use_list);
  $lun_use_total_array=array_merge($lun_use_total_array,$lun_use_array);
}

$lun_index_flag=0;
$lun_data[] = array('lun_id'=>0);



$LUN_limit=254;
$show_lun=1;

for($i=1; $i<=$LUN_limit; $i++){
   if(in_array("$i",$lun_use_total_array) == "" || trim($lun_id)==trim($i)){    
     $lun_data[] = array('lun_id'=>$i);
     if($lun_index_flag == 0){
       $lun_index = 0;
       $lun_index_flag = 1;
     }
   }  
}

if(trim($lun_id) != "")
   $lun_index = $lun_id;
 
/*if($info["RaidUnUsed"] >= 1)
  $raidunused =  round($info["RaidUnUsed"],1);
else
  $raidunused =  floor($info["RaidUnUsed"]);
*/  
die(json_encode(array('unused_percent'=>$unused_percent,
                      'raidunused'=> $raidunused,
                      'unused_data'=>$unused_data,
                      'raidid'=>$info["RaidID"],
                      'enable'=>$enable,
                      'auth'=>$auth,
                      'username'=>$username,
                      'password'=>$password,
                      'iscsi_name'=>$iscsi_name,
                      'iscsi_iqn'=>$iscsi_iqn,
                      'init_info'=>$init_info,
                      'year_data'=>$year_data,
                      'month_data'=>$month_data,
                      'year_index'=>$year_index,
                      'month_index'=>$month_index,
                      'unused_data_index'=>$unused_data_index,
                      'lv_capacity'=>$lv_capacity,
                      'lvname'=>$lvname,
                      'type'=>$type,
                      'thin_space'=>$thin_space,
                      'thin_max_space'=>$virtual_size_max,
                      'space_index'=>$space_index,
                      'lun_data'=>$lun_data,
                      'lun_index'=>$lun_index,
                      'show_lun'=>$show_lun,
                      'desp'=>$desp)
                      ));

}
?>
