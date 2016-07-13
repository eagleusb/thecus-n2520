<?php
error_reporting(E_ERROR | E_PARSE);
ini_set("display_errors", "On");

require_once(INCLUDE_ROOT."cwireless.class.php");

$tpl->assign("WORDS", json_encode($session->PageCode("cwireless")));
$tpl->assign("METHODS", json_encode(EnumRPC("cwirelessRPC")));
?>