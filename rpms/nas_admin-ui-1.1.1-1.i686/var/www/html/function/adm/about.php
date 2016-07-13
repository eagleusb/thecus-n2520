<?php
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');
include_once(INCLUDE_ROOT.'info/sysinfo.class.php');
include_once(INCLUDE_ROOT.'status.class.php');
require_once(WEBCONFIG);

$words = $session->PageCode("info");
$words["producer"] = $gwords["producer"];
$words["product_no"] = $gwords["product_no"];

$sysinfo_class = new SYSINFO();
$sysinfo=$sysinfo_class->getINFO();

$raid_status = file('/var/tmp/rss');
if( preg_match("/Damaged/", $raid_status[0]) == 1 ) {
    $strExec = "awk '/Error/{errlog=sprintf(\"%sDISK #%d,\",errlog,substr($1,5,1));}END{printf(\"%s\",errlog)}' /tmp/TRAY*";
    $fail_disk = shell_exec($strExec);
    if( $fail_disk != "" ) {
        $fail_disk = substr($fail_disk, 0, strlen($fail_disk) - 1);
    }
    $fail_disk_flag = true;
    //$tpl->assign('fail_disk_flag', '1');
    //$tpl->assign('fail_disk', $fail_disk);
}

$fp = fopen("/etc/version", 'r');
if( $fp ){
    $ver = fread($fp, filesize("/etc/version"));
}  
fclose($fp);

$d = $sysinfo["Days"] > 1 ? "days" : "day";
$h = $sysinfo["Hours"] > 1 ? "hours" : "hour";
$m = $sysinfo["Min"] > 1 ? "minutes" : "minute";

$uptime = "";
if( $sysinfo["Days"] != 0 ) { $uptime .= $sysinfo["Days"]." ".$d; }
if( $sysinfo["Hours"] != 0 ){ $uptime .= " ".$sysinfo["Hours"]." ".$h; }
if( $sysinfo["Min"] != 0 )  { $uptime .= " ".$sysinfo["Min"]." ".$m; }

$device = array( array(
    array("key" => "producer", "value" => $webconfig['manufactur']),
    array("key" => "product_no", "value" => $webconfig['product_no']),
    array("key" => "SV", "value" => $ver),
    array("key" => "UPTime", "value" => $uptime)
));

$status = new Status();
$enclosures = $status->enclosureStatus();

for( $i = 0 ; $i < count($enclosures) ; ++$i ) {
    $device []= array(
        array("key" => "producer", "value" => $enclosures[$i]["vendor"]),
        array("key" => "product_no", "value" => $enclosures[$i]["product"]),
        array("key" => "SV", "value" => $enclosures[$i]["rev"]),
        array("key" => "position", "value" => $enclosures[$i]["product_no"])
    );
}

$tpl->assign('words', json_encode($words));
$tpl->assign('fail_disk_flag', json_encode($fail_disk_flag));
$tpl->assign('fail_disk', json_encode($fail_disk));
$tpl->assign('device', json_encode($device));
?>