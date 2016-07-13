<?php
error_reporting(E_ERROR | E_PARSE);
ini_set("display_errors", "On");

require_once(INCLUDE_ROOT."thecusid.class.php");

$tpl->assign("WORDS", json_encode($session->PageCode("thecusid")));
$tpl->assign("METHODS", json_encode(EnumRPC("ThecusidRPC")));




//$ddns_fqdn_file_path="/tmp/ddns_fqdn";
//
//shell_exec("/img/bin/nas_ddns.sh 0");
//if(is_file($ddns_fqdn_file_path)){
//    $handle = fopen($ddns_fqdn_file_path, "r");    
//    if ($handle) {
//        $contents = fgets($handle);
//        $fqdn_result = explode("\t", $contents);
//        $ddns_fqdn = array(
//		'fqdn'=>trim($fqdn_result[0]),
//		'ddns'=>trim($fqdn_result[1]),
//		'thecusid'=>trim($fqdn_result[2])
//		);
//    }
//}
//
//
//$tpl->assign('ddns_fqdn',json_encode($ddns_fqdn));
//

?>
