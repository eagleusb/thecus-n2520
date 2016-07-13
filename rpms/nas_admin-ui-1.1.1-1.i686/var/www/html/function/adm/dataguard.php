<?php
//error_reporting(E_ERROR | E_PARSE);
//ini_set('display_errors', 'On');

require_once(INCLUDE_ROOT.'dataguard_rpc.class.php');
require_once(INCLUDE_ROOT.'Vendor/vendor.class.php');

$config = new VendorConfig();

$amazon_s3=trim(shell_exec("/img/bin/check_service.sh amazon_s3"));

$tpl->assign('Procs', json_encode(EnumRPC('DataGuardRPC')));
$tpl->assign('amazon_s3', $amazon_s3);
$words = $session->PageCode("dataguard");
$rsync_target_words = $session->PageCode("nsync_target");
$mines = json_decode(file_get_contents("/img/bin/dataguard/type.list"));
$tpl->assign('Words', json_encode($words));
$tpl->assign('rsync_target_words', $rsync_target_words);
$tpl->assign('Mines', json_encode($mines));
$tpl->assign('iSCSI', json_encode(+$config->data["iscsi_limit"]));
?>
