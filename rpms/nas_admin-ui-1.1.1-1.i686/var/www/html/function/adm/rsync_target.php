<?php 
$words = $session->PageCode("nsync_target");

$db = new sqlitedb();
$target_rsync_enable = $db->getvar('nsync_target_rsync_enable','1');
$rsync_target_username = $db->getvar('rsync_target_username','');
$rsync_target_password = $db->getvar('rsync_target_password','');
$sshd_enable = $db->getvar('sshd_enable','0');
$sshd_ip1 = $db->getvar('sshd_ip1','');
$sshd_ip2 = $db->getvar('sshd_ip2','');
$sshd_ip3 = $db->getvar('sshd_ip3','');
unset($db);

$tpl->assign('target_rsync_enable',$target_rsync_enable);
$tpl->assign('rsync_target_username',$rsync_target_username);
$tpl->assign('rsync_target_password',$rsync_target_password);
$tpl->assign('words',$words);
$tpl->assign('sshd_enable',$sshd_enable);
$tpl->assign('sshd_ip1',$sshd_ip1);
$tpl->assign('sshd_ip2',$sshd_ip2);
$tpl->assign('sshd_ip3',$sshd_ip3);
$tpl->assign('set_url','setmain.php?fun=setrsync_target');  
?>
