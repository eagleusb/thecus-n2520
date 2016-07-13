<?php
require_once(INCLUDE_ROOT."sqlitedb.class.php");
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$prefix=tftp;	
	
// Get TFTP configuration from database
$db=new sqlitedb();
$enabled=$db->getvar("tftpd_enabled","0");
$ip=$db->getvar("tftpd_ip", "");
$port=$db->getvar("tftpd_port","69");
$permission=$db->getvar("tftpd_permission", "0");
$overwrite=$db->getvar("tftpd_overwrite", "0");
$folder=$db->getvar("tftpd_folder", "");
$ha_enable=$db->getvar("ha_enable", "");
$ha_heartbeat=$db->getvar("ha_heartbeat", "");
unset($db);
$onbaordnetcount=trim(shell_exec("/img/bin/check_service.sh onbaordnetcount"));

$interface=trim(shell_exec("ifconfig|grep HWaddr|awk '{print $1}'"));

$count=1;
$bond_count=1;
$vlan_count=1;
$array_ip=explode("|",$ip);
$interface=explode("\n",$interface);
$interface_list = array();
foreach($interface as $inf){
    if ($inf == ""){
       continue;
    }
    $wan_ip=str_replace("\n", "", shell_exec("/img/bin/function/get_interface_info.sh get_ip $inf"));    
    $wan_ipv6=str_replace("\n", "", shell_exec("/img/bin/function/get_interface_info.sh get_ipv6 $inf"));
    $mac=str_replace("\n", "", shell_exec("/img/bin/function/get_interface_info.sh get_mac $inf"));
    $eth=trim(shell_exec("echo $inf |sed 's/eth[0-9]*/eth./g'"));
    $get_ip_match="$eth-$mac";
    
    foreach($array_ip as $list){
      $string_match=trim(shell_exec("echo $list |grep '$get_ip_match'"));
      if ($string_match!=""){
        $check_enable=1;
        break;
      }else{
        $check_enable=0;
      }
    }
    
    if ($wan_ipv6!=""){
      $wan="$wan_ip/$wan_ipv6";
    }else{
      $wan=$wan_ip;
    }
    
    if (in_array($wan,$interface_list)){
      $wan="";
    }
    
    if ($ha_enable == "1" && $inf == $ha_heartbeat){
      $count++;
      continue;
    }
    
    $check_name=trim(shell_exec("echo $inf |grep '^geth'"));
    if ($check_name == ""){
        $check_name_bond=trim(shell_exec("echo $inf |grep '^bond'"));
        $check_sign=trim(shell_exec("echo $inf |grep ':'"));
        if ($check_name_bond != "" ){
          if ($check_sign == ""){
            $name_interface="Link$bond_count";
            $bond_count++;
          }else{
            $name_interface="Virtual Lan$vlan_count";
            $vlan_count++;
          }
        }else{
          $check_bond=str_replace("\n", "", shell_exec("/img/bin/function/get_interface_info.sh check_eth_bond $inf"));
          if ($check_bond != ""){
            $count++;
            continue;
          }
          if($check_sign != ""){
            $name_interface="Virtual Lan$vlan_count";
            $vlan_count++;
          }else if($count=="1" && $check_sign==""){
            $name_interface="WAN/LAN1";
            $count++;
          }else if($count>"$onbaordnetcount" && $check_sign==""){
            $name_interface="Additional LAN$count";
            $count++;
          }else{
            $name_interface="LAN$count";
            $count++;
          }
        }
    }else{
        $check_bond=str_replace("\n", "", shell_exec("/img/bin/function/get_interface_info.sh check_eth_bond $inf"));
        if ($check_bond != ""){
            $count++;
            continue;
        }  
        $name_interface="Additional LAN$count";
        $count++;
    }
    array_push($interface_list,array($check_enable,$mac,$wan,$inf,$name_interface)); 
}

$words = $session->PageCode($prefix);
$gwords = $session->PageCode("global");

//#################################################
//#	Load public share folder
//#################################################
$raid_class=new RAIDINFO();
$md_array=$raid_class->getMdArray(); 
$share = array();
foreach($md_array as $num){
	$raid_data_result = "0";
	if (NAS_DB_KEY == '1'){          
		$database="/raid".($num-1)."/sys/raid.db";
		$strExec="/bin/mount | grep '/raid".($num-1)."/data'";
		$raid_data_result=shell_exec($strExec);
	}else{
		$database="/raid".($num)."/sys/smb.db"; 
		$strExec="/bin/mount | grep '/raid".$num."'";
		$raid_data_result=shell_exec($strExec);
	}
	if($raid_data_result==""){
		continue;
	}

	$db = new sqlitedb($database,'conf'); 
//	$raid_id=$db->getvar("raid_name");
	$ismaster=$db->getvar("raid_master");
	$file_system=$db->getvar("filesystem");
	if(!$file_system)
		$file_system='ext3';
	if (NAS_DB_KEY == '1'){
		$db_list=$db->db_getall("folder");
	}else{
		if ($ismaster=="1"){
		  $db_lista=$db->db_getall("smb_specfd");
		}else{
		  $db_lista="";
		}
		
		$db_listb=$db->db_getall("smb_userfd");
		if (($db_lista=="") && ($db_listb != 0)){
			$db_list=$db_listb;
		}else if (($db_lista!="") && ($db_listb != 0)){
			$db_list=array_merge($db_lista,$db_listb);
		}else{
			$db_list=$db_lista;
		}
	}  

	foreach($db_list as $k=>$list){
		if($list==""){
			continue;
		}
		if (NAS_DB_KEY == '1'){
		  if ($list["guest_only"] != "yes") {
			continue;
		  }
		}else{
		  if ($list["guest only"] != "yes") {
			continue;
		  }
		}
		$share[]=array("folder_name"=>$list["share"]);
		
	}
	unset($db);
}


$tpl->assign("words",$words);
$tpl->assign($prefix."_enabled",$enabled);
$tpl->assign($prefix."_port",$port);
$tpl->assign($prefix."_read", ($permission & TFTP_READ)?true:false);
$tpl->assign($prefix."_write", ($permission & TFTP_WRITE)?true:false);
$tpl->assign($prefix."_overwrite",$overwrite);
$tpl->assign($prefix."_folder",$folder);
$tpl->assign("folder_list",json_encode($share));
$tpl->assign("share2",json_encode($share2));
$tpl->assign("strExec",$strExec);
$tpl->assign("md_num",$md_num);
$tpl->assign("interface_list",json_encode($interface_list));
$tpl->assign("form_action","setmain.php?fun=set".$prefix);
?>
