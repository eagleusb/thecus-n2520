<?php
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'hv.class.php');
$action = $_POST['action'];

if( method_exists('HugeVolumeRPC', $action) ) {
    $params = json_decode(stripslashes($_POST['params']), true);
    
    $result = call_user_func_array(array('HugeVolumeRPC', $action), $params);
    array_unshift($result, $action);
    die(json_encode($result));
}
/*
function statusEnum() {
    $refl = new ReflectionClass('HVStatus');
    return $refl->getConstants();
}
*/

/**
 * Query all public methods in HugeVolumeRPC class.
 * 
 * @return String[]
 */
function proceduresEnum() {
    $refl = new ReflectionClass('HugeVolumeRPC');
    $public = $refl->getMethods(ReflectionMethod::IS_PUBLIC);
    $methods = array();
    for( $i = 0 ; $i < count($public) ; $i++ ) {
        if( $public[$i]->name != "background" && $public[$i]->name != "frontground" ) {
            array_push($methods, $public[$i]->name);
        }
    }
    return $methods;
}

$hv_clients = Commander::frontground('i', '/img/bin/check_service.sh hv_client');

/*
 *nic_10G= 0:10G ready, 1:no 10G, 2:10G existed, but not ready
 */
$t_nic= Commander::frontground('s', '/sbin/ifconfig | grep ^geth');
$nic_10G=0;
if ($t_nic==""){
  $nic_10G=1;
}else{
  $t_nic= Commander::frontground('s', '/img/bin/rc/rc.hv nic');
  if ($t_nic==""){
     $nic_10G=2;
  }
}


$db=new sqlitedb();
$service=$db->getvar("hv_service","0");
$ha_enable=$db->getvar("ha_enable","0");
$hv_enable=$db->getvar("hv_enable","0");
unset($db);

$client_on_off=0;
$strExec="/bin/cat /proc/mdstat | awk -F: '/^md1[1-9] :/{printf(\"%s\\n\",  substr(\$1,3))}' | sort -u";
$md_list=trim(shell_exec($strExec));
if ($md_list!="")
  $client_on_off=1;

$tpl->assign('words', json_encode($session->PageCode("hv")));
$tpl->assign('procedures', json_encode(proceduresEnum()));
$tpl->assign('hv_clients', json_encode($hv_clients));
$tpl->assign('nic_10G', json_encode($nic_10G));
$tpl->assign('ha_enable', json_encode($ha_enable));
$tpl->assign('master_on_off', json_encode($hv_enable));
$tpl->assign('client_on_off', json_encode($client_on_off));
$tpl->assign('service', json_encode($service));
?>
