<?php
$prefix="thumbnail";
$words = $session->PageCode("$prefix");
$db=new sqlitedb();
$enabled=$db->getvar("thumbnail","1");
unset($db);
$tpl->assign('words',$words);
$tpl->assign($prefix.'_enabled',$enabled);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>

