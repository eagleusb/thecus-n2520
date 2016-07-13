<?php  
require_once("../../function/conf/localconfig.php");
require_once(INCLUDE_ROOT.'session.php');

		
// =============================== BEGIN HERE ==================================
if (isset($_POST['username'])) { 
        $session->login($_POST['username'],$_POST['pwd']); 
} 
?>
