<?
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
$class = new DISKINFO();
if ($_POST["_diskpower"]!="") {
  $class->setspintime($_POST["_diskpower"]);

return MessageBox(false,'','');  
}
?>
