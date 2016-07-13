<?php
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');

require_once(INCLUDE_ROOT.'ha.class.php');
$action = $_POST['action'];
if( method_exists('HighAvailabilityRPC', $action) ) {
    $params = json_decode(stripslashes($_POST['params']), true);
    
    $result = call_user_func_array(array('HighAvailabilityRPC', $action), $params);
    array_unshift($result, $action);
    die(json_encode($result));
}
?>
