<?php
//error_reporting(E_ERROR | E_PARSE);
//ini_set('display_errors', 'On');

require_once(INCLUDE_ROOT.'log.class.php');
InvokeRPC('AccessLogRPC');

$params = json_decode(stripslashes($_GET['params']), true);
AccessLogRPC::download($params);
die();
?>
