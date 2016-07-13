<?php
require_once(INCLUDE_ROOT."status.class.php");
InvokeRPC('StatusRPC');

$nic = Commander::fg("a", "/img/bin/rc/rc.net get_network_info | sed -nr 's/(g?eth[0-9]+|bond)\\|([^\\|]*).*/\"\\1\":\"\\2\"/p'");
array_pop($nic);
for( $i = 0 ; $i < count($nic); ++$i ) {
    if( preg_match("/\"bond\":\"(.*)\"/", $nic[$i], $tmp) ) {
        $nic[$i] = sprintf("\"bond%d\":\"LINK%d\"", $tmp[1], $tmp[1]+1);
    }
}
$nic = sprintf("{%s}", join(",", $nic));

$monitor_flag = trim(shell_exec("/img/bin/check_service.sh monitor"));

$words = $session->PageCode("status");
$words["running"] = $gwords["running"];
$words["stop"] = $gwords["stop"];
$tpl->assign('words', json_encode($words));
$tpl->assign('nic', $nic);
$tpl->assign('monitor_flag', $monitor_flag);
?> 
