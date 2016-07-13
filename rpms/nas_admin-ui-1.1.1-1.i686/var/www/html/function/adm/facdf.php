<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(WEBCONFIG);
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

if (NAS_DB_KEY == '1'){
	shell_exec("tar zxvf /etc/default.tar.gz -C /tmp");
	$db=new sqlitedb('/tmp/etc/cfg/conf.db');
}else{
	shell_exec("cp -rfd /img/bin/default_cfg/" . $thecus_io["MODELNAME"] . "/* /tmp");
	$db=new sqlitedb('/tmp/etc/cfg/conf.db');
}


$lan1_ip=$db->getvar("nic1_ip","");
$lan2_ip=$db->getvar("nic2_ip","");
$nic1_dhcp=$db->getvar("nic1_dhcp","1");
unset($db);

if (($sysconf["arch"] == 'oxnas') || ($nic1_dhcp == '1'))
    $lan1_ip="DHCP";

$default_ip = $webconfig['default_interface']=="lan1"? $lan1_ip : $lan2_ip;
$tpl->assign('default_ip',$default_ip);
$tpl->assign('interface',$webconfig['default_interface']);

$words = $session->PageCode("facdf");
$tpl->assign('words',$words);
?>

