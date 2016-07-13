<?php
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'upgrade.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$action = $_REQUEST['action'];
                                                                                                             
$upg = new Upgrade();

if( method_exists($upg, $action) ) {
    $result = call_user_func_array(array($upg, $action), $_REQUEST['params']);
    
    /**
     * All process will be killed during upgrade procedure.
     * PHP object's background shell will be killed, too.
     * Must use function call to fix that.
     */
    if( $action == 'setUpgrade' && $result != '' ) {
        pclose(popen("sh $result > /dev/null 2>&1 &", 'r'));
    }
}
die($upg->getProgress());

?>
