<?php
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'commander.class.php');

get_hwinfo();

$words = $session->PageCode("hwinfo"); 

$info = array(
    "general" => array(),
    "nic" => array(),
    "usb" => array(),
    "dc" => array()
);

for($i = 0; $i < count($hwinfo); $i++) {
    $hw_array = explode(",", $hwinfo[$i]);
    $key = &$hw_array[0];
    $value = &$hw_array[1];
    if( $value == "" )
        continue;
    if( preg_match("/^.AN.*/", $key) ) {
        array_push($info["nic"], array( "key" => $key, "value" => $value) );
    } else if( preg_match("/^USB.*/", $key) ) {
        array_push($info["usb"], array( "key" => $key, "value" => $value) );
    } else if( preg_match("/^(SATA|SAS).*/", $key) ) {
        array_push($info["dc"], array( "key" => $key, "value" => $value) );
    } else {
        array_push($info["general"], array( "key" => $key, "value" => $value) );
    }
}

unset($db) ;
$tpl->assign('info', json_encode($info));
$tpl->assign('words', json_encode($words));
?>
