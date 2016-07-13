<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'validate.class.php');
$words = $session->PageCode("nsync_target"); 
$gwords = $session->PageCode("global"); 

$rsync_target_enable=$_POST['_rsync_enable'];
$rsync_username=$_POST['_rsync_username'];
$rsync_password=$_POST['_rsync_password'];

$db = new sqlitedb();
$o_rsync_enable = $db->getvar('nsync_target_rsync_enable','1');
$o_rsync_username = $db->getvar('rsync_target_username','');
$o_rsync_password = $db->getvar('rsync_target_password','');
unset($db);

//if not do any change,redirect to setting page
if (( $nsync_target_enable == $o_enable )) { 
    return  MessageBox(true,$words['nsync_target_title'],$gwords['setting_confirm']); 
}

$db = new sqlitedb();
$db->setvar("nsync_target_enable",$nsync_target_enable);
$db->setvar("nsync_target_rsync_enable",$rsync_target_enable);
$db->setvar("rsync_target_username",$rsync_username);
$db->setvar("rsync_target_password",$rsync_password);
unset($db);

if ($nsync_target_enable){
   shell_exec("/img/bin/rc/rc.nsyncd restart > /dev/null 2>&1");
}else{
   shell_exec("/img/bin/rc/rc.nsyncd stop > /dev/null 2>&1");
}

$msg = ($nsync_target_enable) ? $words["nsyncd_Enable"]:$words["nsyncd_Disable"];
return  MessageBox(true,$words['nsync_target_title'],$msg);
 
?> 