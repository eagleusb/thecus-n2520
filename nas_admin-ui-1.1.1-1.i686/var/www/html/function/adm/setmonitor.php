<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

if( $_POST['action'] == 'save' ) {
    $db = new sqlitedb();
    $db->setvar("monitor", stripslashes($_POST['layout']));
    $tmp = json_decode(stripslashes($_POST['layout']), true);
    $db->db_close();
} else if( $_POST['action'] == 'history' ) {
    if( $_POST['params'] == 'reset' ) {
        unlink('/raid/sys/history.db');
        unlink('/raidsys/0/history.db');
        die();
    }
} else if( $_POST['action'] == 'reset' ) {
    $db = new sqlitedb();
    $db->setvar('monitor',null);
    $db->db_close();
    die();
} else if( $_POST['action'] == 'saveHistory' ) {
    $save = json_decode(stripslashes($_POST['params']), true);
    file_put_contents('/var/tmp/monitor/save', $save);
    $db = new sqlitedb();
    $db->setvar('save_history', $save);
    $db->db_close();
    die();
}
?>
