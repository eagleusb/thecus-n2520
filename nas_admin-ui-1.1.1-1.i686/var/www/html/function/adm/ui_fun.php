<?php
error_reporting(E_ERROR | E_PARSE);
ini_set("display_errors", "On");
require_once(INCLUDE_ROOT."modulelogin.class.php");

$words = $session->PageCode("ui_fun");
$words["setting_confirm"] = $gwords["setting_confirm"];
$words["enable"] = $gwords["enable"];
$words["disable"] = $gwords["disable"];
$words["confirm"] = $gwords["confirm"];
$words["apply"] = $gwords["apply"];


$tpl->assign("METHODS", json_encode(EnumRPC("ModuleLoginRPC")));
$tpl->assign("WORDS", json_encode($words));
?>
