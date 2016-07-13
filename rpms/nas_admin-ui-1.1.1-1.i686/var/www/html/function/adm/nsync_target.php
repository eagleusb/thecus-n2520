<?php 
$words = $session->PageCode("nsync_target");

$db = new sqlitedb();
$nsync_target_enable = $db->getvar('nsync_target_enable','1');
unset($db);
        
$tpl->assign('nsync_target_enable',$nsync_target_enable);
$tpl->assign('words',$words);
$tpl->assign('set_url','setmain.php?fun=setnsync_target');  
?>
