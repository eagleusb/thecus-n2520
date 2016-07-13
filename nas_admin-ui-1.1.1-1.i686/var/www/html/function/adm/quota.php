<?php 
include_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'quota.class.php');

$action = $_REQUEST['action'];

if( method_exists('Quota', $action) ) {
    $params = json_decode(stripslashes($_REQUEST['params']), TRUE);
    $result = call_user_func_array(
        array('Quota', $action),
        array($params)
    );

    die(json_encode($result));
}

$words = $session->PageCode("quota");
$db = new sqlitedb();
$quota_enable = $db->getvar('quota','0');
$ads_enabled = $db->getvar("winad_enable","0");
if( !$ads_enabled ) {
    $ads_enabled=$db->getvar("ldap_enabled","0");
}

$RaidSync = Quota::getSync();
$configure = array(
    quotaEnabled => $quota_enable,
    ad_show => $ads_enabled,
    HasSynced => false,
    status => Quota::getAction(),
    RaidSync => $RaidSync['result']
);

$tpl->assign('raid_count',$raid_count);
$tpl->assign('configure', json_encode($configure));
$tpl->assign('words', json_encode($words));
?>
