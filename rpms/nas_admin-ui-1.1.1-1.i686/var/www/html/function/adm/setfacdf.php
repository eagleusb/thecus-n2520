<?
$gwords = $session->PageCode("global");
$words = $session->PageCode("facdf");

$lang='en';
if (isset($_SESSION['lang'])) $lang=$_SESSION['lang'];

shell_exec('/img/bin/resetDefault.sh > /dev/null 2>&1 &');
return MessageBox(true,$words["settingTitle"],$gwords["success"]);
?>
