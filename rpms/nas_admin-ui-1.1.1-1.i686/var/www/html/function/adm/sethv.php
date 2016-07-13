<?php
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');

require_once(INCLUDE_ROOT.'hv.class.php');
$action = $_POST['action'];

if( method_exists('HugeVolumeRPC', $action) ) {
    $params = json_decode(stripslashes($_POST['params']), true);
    
    $result = call_user_func_array(array('HugeVolumeRPC', $action), $params);
    array_unshift($result, $action);
    die(json_encode($result));
}
?>
