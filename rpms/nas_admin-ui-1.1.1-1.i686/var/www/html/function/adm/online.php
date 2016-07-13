<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$words = $session->PageCode("online");
$gwords = $session->PageCode("global");
$twords = $session->PageCode("time");

//##########################################################
//#	Check system folder
//##########################################################
if (NAS_DB_KEY==1){
  $strExec="ls -l /raid/sys | awk '{print $11}' | awk -F'/' '{print $2}'";
  $master_raid=trim(shell_exec($strExec));
  $vg_name="vg".trim(substr($master_raid,4,1));
  $strExec="mount | grep \"/dev/${vg_name}/syslv\" | grep rw | wc -l";
}elseif (NAS_DB_KEY==2)
  $strExec="ls -l /raid/sys/ 2>/dev/null | wc -l";
  
//##########################################################
$syspath=(shell_exec($strExec)==0)?"/var/log":"/raid/sys";

$database=${syspath}."/online_register.db";
if(file_exists($database)){
	$db=new sqlitedb($database,"online_register");
}
$db2=new sqlitedb("/etc/cfg/conf.db","conf");


$online_enabled=$db2->getvar("online_enabled","0");
$online_send_hdd_info=$db2->getvar("online_send_hdd_info","0");
$online_send_timezone_info=$db2->getvar("online_send_timezone_info","0");

$count=0;
$file=array();
$start=$_POST['start'];
$limit=$_POST['limit'];
$sort=$_POST['sort'];
$info_type=($_POST['info_type']!="")?$_POST['info_type']:"all";
$type=($_POST['type'])?$_POST['type']:"all";
$sort_style=$_POST['dir'];
$log_file=$_POST['log_file'];

function get_data($type){
  global $file,$database,$db;
  if(file_exists($database)){
  	if($type!="all"){
  		$strSQL="select online1,online4,online6,online9 from online_register where online2='${type}'";
  	}else{
  		$strSQL="select online1,online4,online6,online9 from online_register";
  	}
  	$files=$db->runSQLAry($strSQL);

  	foreach($files as $list){
  		array_push($file,array(
  			'flag'=>$list["online1"],
  			'postdate'=>$list["online9"],
  			'msg'=>$list["online4"],
  			'download_url'=>$list["online6"]
  		));
  	}
  }
}

function sort_data($sort,$sort_type){
  global $file,$db,$database;
  /*
  $sort_order = SORT_DESC;
  if($sort_type=='ASC')
    $sort_order = SORT_ASC;
	*/
	if(file_exists($database)){
		if($sort_type==""){
			$sort_type="DESC";
		}
		//$sort_order="DESC";
		if($sort=="all" || $sort==""){
			$strSQL="select online1,online4,online6,online9 from online_register order by online9 ${sort_type}";
		}else{
			$strSQL="select online1,online4,online6,online9 from online_register where online2='${sort}' order by online9 ${sort_type}";
		}
		$files=$db->runSQLAry($strSQL);
  	
 		foreach($files as $list){
			array_push($file,array(
  			'flag'=>$list["online1"],
  			'postdate'=>$list["online9"],
  			'msg'=>$list["online4"],
  			'download_url'=>$list["online6"]
  		));
  	} 
  }
}

//get_data($type);

$tpl->assign('words',$words);
$tpl->assign('twords',$twords);
$tpl->assign('url','/adm/getmain.php?fun=online');
$tpl->assign('setmain','/adm/setmain.php?fun=setonline');
$tpl->assign('online_enabled',$online_enabled);
$tpl->assign('online_send_hdd_info',$online_send_hdd_info);
$tpl->assign('online_send_timezone_info',$online_send_timezone_info);

if($limit=='')
  $tpl->assign('limit',13);
else
  $tpl->assign('limit',$limit);
  
$tpl->assign('news_length',100);
$tpl->assign('type',$type);
$tpl->assign('start',$start);

//sort_data($sort,$sort_style);
sort_data($info_type,$sort_style);

$count=sizeof($file);
$data=array();

if(($limit+$start) > $count){
  $current_count=$count;
}else{
  $current_count=$limit+$start;
} 

if($start!=''){
  for($i=$start;$i<$current_count;$i++){
   $data[]= $file[$i];   
  }
  $ary = array('totalcount'=>$count,'topics'=>$data);
  die(json_encode($ary));
}
?>
