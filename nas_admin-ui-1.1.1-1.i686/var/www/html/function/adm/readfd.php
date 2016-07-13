<?
session_cache_limiter('none'); //*Use before session_start()
session_start();
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$module_db_path= MODULE_ROOT . "cfg/premod.db";

$type = $_GET["type"];
$name = $_GET["name"];

$db = new sqlitedb($module_db_path, 'module');
$mod_rs = "select count(*) from module where name='".$name."'";
$rs=$db->runSQL($mod_rs);
unset($db);

if ($rs[0] == 1){
    if ($type == 'guide'){
        _Download(MODULE_ROOT.".module/".$name."/Configure/Guide.pdf", $name."_guide.pdf");
    }else if ($type == 'note'){
        _Download(MODULE_ROOT.".module/".$name."/Configure/Note", $name."_note.txt");
    }   
}

function _Download($f_location,$f_name){
    header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
    header('Content-Description: File Transfer');
    header('Content-Type: application/octetstream');
    header('Content-Length: ' . filesize($f_location));
    header('Content-Disposition: attachment; filename=' . basename($f_name));
    readfile_chunked($f_location);
}

function readfile_chunked($filename,$retbytes=true) {
  $chunksize = 1*(1024*1024); // how many bytes per chunk
  $buffer = '';
  $cnt =0;
  $handle = fopen($filename, 'rb');
  if ($handle === false) {
      return false;
  }
  while (!feof($handle)) {
      $buffer = fread($handle, $chunksize);
      echo $buffer;
      ob_flush();
      flush();
      if ($retbytes) {
          $cnt += strlen($buffer);
      }
  }
      $status = fclose($handle);
  if ($retbytes && $status) {
      return $cnt; // return num. bytes delivered like readfile() does.
  }
  return $status;
}
?>

