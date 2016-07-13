<?php
require_once(INCLUDE_ROOT.'upgrade.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$action = $_REQUEST['action'];

$upg = new Upgrade();

if( method_exists($upg, $action) ) {
    call_user_func_array(array($upg, $action), json_decode($_REQUEST['params']));
    die($upg->getProgress());
} else {
    if( NAS_DB_KEY != 1 ) {
        $backupDom = -1;
    } else {
        $db=new sqlitedb();
        $backupDom = $db->getvar('backup_dom', '1'); //default is true
    }
    
    $words = $session->PageCode("updfw");
    
    $tpl->assign('backupDom', $backupDom);
    $tpl->assign('isOEM', $_SESSION["isOEM"]);
    $tpl->assign('words', $words);
}

?>
