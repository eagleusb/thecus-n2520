<?php
$ac = $_REQUEST['ac'];
$words = $session->PageCode("sdrb");


$status=shell_exec("/bin/ps | /bin/grep 'up.sh' | /bin/grep -v 'grep'| /usr/bin/wc -l");
$lock = ($status == 0)?"0":"1";


$db = new sqlitedb();
$ha_role = $db->getvar("ha_role",0);
$ha_enable = $db->getvar("ha_enable",0);
unset($db);


$standby="1";
$together='0';
$ha_role_current="";

if (file_exists(HA_FLAG)){
    $startup=trim(file_get_contents(HA_FLAG));
    $startup = str_replace("\n","",$startup);
}

// ha enable
if($ha_enable=='1'){
    //standby disconnect
    if(file_exists(HA_NETWORK_PATH)){
	$cline = file_get_contents(HA_NETWORK_PATH);
	$cline = str_replace("\n","",$cline);
	list($active, $heartbeat, $standby, $rebuild) = explode('|',$cline);
	if($active=='0' && $standby=='0' && $heartbeat=='0'){
		$together='1';
	}
    }
}else{
    $ha_enable =  (file_exists(HA_ROLE))? "1": "0"; 
}

if(file_exists(HA_ROLE)){
    $ha_role_current = (trim(shell_exec("cat ".HA_ROLE))=='active')?'0':'1';
}

if($startup=='5' || $startup=='22'){
    $together='1';
}
$raid_damaged='0';
if(file_exists("/tmp/ha_raid_damaged")){
    $raid_damaged='1';
}
$fw_upgraded = "";
if (file_exists("/tmp/upgrade_result.log")){
    $cont = trim(file_get_contents("/tmp/upgrade_result.log"));
    $cont = str_replace("\n","",$cont);
    if($cont == "FINISH|0|"){
        $fw_upgraded = "1";
    }
}

$tpl->assign('ha_role_current',$ha_role_current);
$tpl->assign('fw_upgraded',$fw_upgraded);
$tpl->assign('ha_enable',$ha_enable);
$tpl->assign('together',$together);
$tpl->assign('words',$words);
$tpl->assign('index_ac',$ac);
$tpl->assign('ha_role',$ha_role);
$tpl->assign('startup',$startup);
$tpl->assign('lock',$lock);
$tpl->assign('raid_damaged',$raid_damaged);
?>
