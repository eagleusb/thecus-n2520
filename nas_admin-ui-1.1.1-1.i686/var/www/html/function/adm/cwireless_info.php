<?php

require_once(INCLUDE_ROOT."info/wireless.class.php");
$wireless=new WIRELESS();
$wireless_info=$wireless->GetList();
$id=trim($_POST["id"]);
die(json_encode(array("wireless_info"=>$wireless_info[$id])));
?>
