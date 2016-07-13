<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();
$db=new sqlitedb();

$words = $session->PageCode("hwctrl"); 
$gwords= $session->PageCode("global"); 

$count = $sysconf['gpiocount'];
$gpio = array();
for($i=1;$i<=$count;$i++){
    $define = $db->getvar("gpio".$i,'1');
    array_push($gpio,array("id"=>$i, "define"=>$define));
}
unset($db) ;
$tpl->assign('gpio', json_encode($gpio));
$tpl->assign('words', $words);
$tpl->assign('gwords', $gwords);
?>
