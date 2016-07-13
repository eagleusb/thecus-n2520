<?php
//error_reporting(E_ERROR | E_PARSE);
//ini_set("display_errors", "On");
require_once(INCLUDE_ROOT."log.class.php");
require_once(INCLUDE_ROOT.'Vendor/vendor.class.php');


$services_tmp = new VendorConfig();
$services = $services_tmp->grep('/iscsi_limit/');
$words = $session->PageCode("log");
$iscsi_limit=$sysconf['iscsi_limit'];
$tpl->assign("config",json_encode(AccessLog::getRole()));
$tpl->assign("procs", json_encode(EnumRPC("AccessLogRPC")));
$tpl->assign("words", json_encode($words));
$tpl->assign("services", json_encode($services));

?>
