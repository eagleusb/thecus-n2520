<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$prefix=nfs;

$db=new sqlitedb();
if (NAS_DB_KEY==1)
    $nfs_enabled=$db->getvar("httpd_nic1_nfs","0");
else
    $nfs_enabled=$db->getvar("nfsd_nfsd","0");

unset($db);

$masterRaid = shell_exec("ls -l /var/tmp/rss | awk -F'/' '{printf($7)}'");
$words = $session->PageCode($prefix);
$tpl->assign('words',$words);
$tpl->assign('nfs_enabled',$nfs_enabled);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
$tpl->assign('masterRaid', $masterRaid);
?>
