<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'getnic.class.php');

get_sysconf();                 

function get_default_ip_num(){
  global $prefix,$db;
  
  if (substr($prefix,0,3)=="eth"){
    $nickname="eth";
  }else{
    $nickname="geth";
  }
  
  $default_value="192.168.";
  $ip_list=array();

  for($i=0;$i<2;$i++){    
    $ip_list[]=$db->getvar('nic'.($i+1).'_ip');
  }
  $ip_list[]=$db->getvar('wireless_ip');

  $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select * from conf where k like '".$nickname."%_ip' and k not like '".$prefix."%_ip'\" | egrep '".$nickname."._ip|".$nickname.".._ip' | awk -F'|' '{print $2}'";
  $tengb_array=shell_exec($strExec);
  $tengb_list=explode("\n",$tengb_array);
  $ip_list=array_merge($ip_list,$tengb_list);
  for($i=4;$i<=254;$i++){
    $exit_flag=0;
    foreach ($ip_list as $ip_value){
      if(trim(strpos($ip_value,$default_value.$i.".")) != ""){
        $exit_flag=1;
        break;
      }
    }
    
    if($exit_flag==0)
      break;      
  }
  
  return $i;
}

$prefix=$_REQUEST["tid"];

$getnic=new GetNIC($prefix);
$link_detect=$getnic->GetStatus();
if($link_detect=="yes"){
	$link_speed=$getnic->GetSpeed();
}else{
	$link_speed="";
}

$num=$_REQUEST["num"];
$db=new sqlitedb();
$db_status=$db->runSQL("select v from conf where k='".$prefix."_ip'");
$s_ip=get_default_ip_num();
$default_ip="192.168.".$s_ip.".254";
$default_mask="255.255.255.0";
$default_sdbcp="192.168.".$s_ip.".1";
$default_edbcp="192.168.".$s_ip.".100";
$default_jumbo="1500";
$max_jumbo_file="/tmp/tengb_jumbo";

//first restart tengb
/*if(trim($db_status[0])==""){
  $is_exist=trim(shell_exec("/sbin/ifconfig | awk '/^".$prefix."/{print $1}'"));
  if($is_exist==""){
    shell_exec("/sbin/ifconfig ".$prefix." up");
    shell_exec("/sbin/ifconfig ".$prefix." ".$default_ip." netmask ".$default_mask." broadcast +");
    shell_exec("/img/bin/rc/rc.samba restart");
  }  
}*/

$tengb_list=get_tengb($prefix);
$tengb_info=$tengb_list[0];
$words = $session->PageCode('network');
$jumbo=$db->getvar($prefix."_jumbo",$default_jumbo);
$ip=$db->getvar($prefix."_ip",$default_ip);
$netmask=$db->getvar($prefix."_netmask",$default_mask);
$dhcp=$db->getvar($prefix."_dhcp","0");
$dhcp_startip=$db->getvar($prefix."_startip",$default_sdbcp);
$dhcp_endip=$db->getvar($prefix."_endip",$default_edbcp);
$strExec="ifconfig ".trim($tengb_info)." | grep HWaddr |awk '{print \$5}'";
$real_mac=trim(shell_exec($strExec));
$mac=$db->getvar($prefix."_mac",$real_mac);
unset($db);
//  $gateway[$i]=$db->getvar($prefix."_gateway","");
//$ip_sharing=$db->getvar("nic1_ip_sharing","0");  

$bytes = ' '.$words['bytes'];
$jombo_frame_max=trim(shell_exec("cat ".$max_jumbo_file." | awk '/^".$prefix."/{print $2}'"));
$jumbo_fields="['value','display']";
$jumbo_data="[['$default_jumbo','Disable']";

for ($jumbo_idx=2000;$jumbo_idx<=$jombo_frame_max;$jumbo_idx+=1000){
  $jumbo_data.=",['${jumbo_idx}','${jumbo_idx}']";
}

if(($jombo_frame_max % 1000) !=0)
  $jumbo_data.=",['${jombo_frame_max}','${jombo_frame_max}${bytes}']";

$jumbo_data.="]";



if($fh = fopen("/etc/resolv.conf", "r")){
	$dns_entries = array();
	while (!feof($fh)){
		if (preg_match("/nameserver [^ ]*/i", fgets($fh, 4096), $match)){
			$dns_entries[] = trim(preg_replace("/nameserver /i", "", $match[0]));
		}
	}
	fclose($fh);
	$dns=$dns_entries[0];
	for ($idx=1;$idx<3;$idx++)
		$dns.='\n'.$dns_entries[$idx];
}

$title=sprintf($words["10gbe_title"],$num);
$warn_jumbo=sprintf($words["warn_jumbo"],$default_jumbo+1,$jombo_frame_max);
$limit=sprintf($words["jumbo_frame_limit"],$default_jumbo+1,$jombo_frame_max);

$tpl->assign('words',$words);
$tpl->assign('tengb_mac',$real_mac);
$tpl->assign('tengb_jumbo',$jumbo);
$tpl->assign('tengb_jumbo_fields',$jumbo_fields);
$tpl->assign('tengb_jumbo_data',$jumbo_data);
$tpl->assign('tengb_default_jumbo',$default_jumbo);
$tpl->assign('tengb_jombo_frame_max',$jombo_frame_max);
$tpl->assign('warn_jumbo',$warn_jumbo);
$tpl->assign('limit',$limit);
$tpl->assign('tengb_ip',$ip);
$tpl->assign('tengb_netmask',$netmask);
$tpl->assign('tengb_dhcp',$dhcp);
$tpl->assign('tengb_dhcp_startip',$dhcp_startip);
$tpl->assign('tengb_dhcp_endip',$dhcp_endip);
$tpl->assign('tengb_dns0',$dns_entries[0]);
$tpl->assign('tengb_dns1',$dns_entries[1]);
$tpl->assign('tengb_dns2',$dns_entries[2]);
$tpl->assign('prefix',$prefix);
$tpl->assign('default_ip',$default_ip);
$tpl->assign('default_sdbcp',$default_sdbcp);
$tpl->assign('default_edbcp',$default_edbcp);
$tpl->assign('default_mask',$default_mask);
$tpl->assign('default_jumbo',$default_jumbo);
$tpl->assign('db_mac',$mac);
$tpl->assign('form_action','setmain.php?fun=settengb');
$tpl->assign('num',$num);
$tpl->assign('title',$title);
$tpl->assign('link_detect',$link_detect);
$tpl->assign('link_speed',$link_speed);
//$tpl->assign('ip_sharing',$ip_sharing);
//$tpl->assign($prefix.'tengb_gateway',$gateway);
?>


