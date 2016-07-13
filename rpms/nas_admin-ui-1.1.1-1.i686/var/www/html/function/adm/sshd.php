<?php
$Prefix="sshd";
$Words = $session->PageCode($Prefix);
$Cmd=IMG_BIN."/rc/rc.sshd 'get_value'";
$SshdInfo=trim(shell_exec($Cmd));
list($Enabled, $Port, $SftpEn) = explode("|", $SshdInfo);
$tpl->assign('words',$Words);
$tpl->assign($Prefix.'_enabled',$Enabled);
$tpl->assign($Prefix.'_port',$Port);
$tpl->assign($Prefix.'_sftpen',$SftpEn);
$tpl->assign('Prefix',$Prefix);
$tpl->assign('form_action','setmain.php?fun=set'.$Prefix);
?>
