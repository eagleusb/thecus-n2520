<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'getnic.class.php');

get_sysconf();
$prefix=lan;

$getnic=new GetNIC("eth1");
$link_detect=$getnic->GetStatus();
if($link_detect=="yes"){
	$link_speed=$getnic->GetSpeed();
}else{
	$link_speed="";
}

$default_jumbo=1500;

$mac=trim(shell_exec("ifconfig eth1|grep HWaddr|awk '{print $5}'"));
$db=new sqlitedb();
$jumbo=$db->getvar("nic2_jumbo","$default_jumbo");
$ip=$db->getvar("nic2_ip","192.168.2.254");
$netmask=$db->getvar("nic2_netmask","255.255.255.0");
$dhcp=$db->getvar("nic2_dhcp","0");
$dhcp_startip=$db->getvar("nic2_startip","192.168.2.1");
$dhcp_endip=$db->getvar("nic2_endip","192.168.2.100");
$gateway=$db->getvar("nic2_gateway","");
$ip_sharing=$db->getvar("nic1_ip_sharing","0");


/**
* examine 0823ad opened, closing LAN set.
* / 
*/
$value_8023ad=$db->getvar("nic1_mode_8023ad","none");
$set_8023ad=($value_8023ad=='none')?0:1;
unset($db);

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

$words = $session->PageCode('network');
$bytes = ' '.$words['bytes'];

$jombo_frame_max=$sysconf['jombo_frame_max'];

$jumbo_fields="['value','display']";
$jumbo_data="[['$default_jumbo','Disable']";
for ($jumbo_idx=2000;$jumbo_idx<=$jombo_frame_max;$jumbo_idx+=1000){
        $jumbo_data.=",['${jumbo_idx}','${jumbo_idx}']";
}
$jumbo_data.="]";
        
//$jumbo_data="[['$default_jumbo','Disable'],['4000','4000${bytes}'],['7000','7000${bytes}']]";
//$jumbo_data="[['$default_jumbo','Disable'],['4000','4000${bytes}'],['8000','8000${bytes}'],['12000','12000${bytes}'],['16000','16000${bytes}']]";

$warn_jumbo=sprintf($words["warn_jumbo"],$default_jumbo+1,$jombo_frame_max);
$limit=sprintf($words["jumbo_frame_limit"],$default_jumbo+1,$jombo_frame_max);

$tpl->assign('words',$words);
$tpl->assign($prefix.'_mac',$mac);
$tpl->assign($prefix.'_jumbo',$jumbo);
$tpl->assign($prefix.'_jumbo_fields',$jumbo_fields);
$tpl->assign($prefix.'_jumbo_data',$jumbo_data);
$tpl->assign($prefix.'_default_jumbo',$default_jumbo);
$tpl->assign($prefix.'_jombo_frame_max',$jombo_frame_max);
$tpl->assign('warn_jumbo',$warn_jumbo);
$tpl->assign('limit',$limit);
$tpl->assign($prefix.'_ip',$ip);
$tpl->assign($prefix.'_netmask',$netmask);
$tpl->assign($prefix.'_gateway',$gateway);
$tpl->assign('ip_sharing',$ip_sharing);
$tpl->assign($prefix.'_dhcp',$dhcp);
$tpl->assign($prefix.'_dhcp_startip',$dhcp_startip);
$tpl->assign($prefix.'_dhcp_endip',$dhcp_endip);
//$tpl->assign($prefix.'_dns',$dns);
$tpl->assign($prefix.'_dns0',$dns_entries[0]);
$tpl->assign($prefix.'_dns1',$dns_entries[1]);
$tpl->assign($prefix.'_dns2',$dns_entries[2]);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
$tpl->assign('link_detect',$link_detect);
$tpl->assign('link_speed',$link_speed);
$tpl->assign('set_8023ad',$set_8023ad);
?>
