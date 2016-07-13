<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
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

?> 