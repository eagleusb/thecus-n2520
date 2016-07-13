<?php
/**
 * Process Logout request
 */

require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'session.php');
$session->logout();  
header('Location: /index.php');
?>
