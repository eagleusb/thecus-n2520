<?
/*
session_start();
if(!$_SESSION['admin_auth']){
		header('Location: /unauth.htm');
		exit;
}
*/
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'raid.class.php');

ignore_user_abort(FALSE);
set_time_limit(0);
error_reporting(E_ALL^E_NOTICE^E_WARNING);
ini_set('display_errors', '1');

$words = $session->PageCode("raid");
$gwords = $session->PageCode("global");
$class = new DISKINFO();
$disk_info=$class->getINFO();
$disk_list=$disk_info["DiskInfo"];

$dbpath = "/etc/cfg/conf.db";
shell_exec("/usr/bin/sqlite $dbpath 'delete from hot_spare'");

foreach($_POST["hotspare"] as $v){
  shell_exec("/usr/bin/sqlite $dbpath \"insert into hot_spare values('$v')\"");
}

$ary = array('ok'=>'gotoRaidInfo()');
return  MessageBox(true,$words["hot_spare_title"],$words["UpdateSuccess"],INFO,OK,$ary);

?>
