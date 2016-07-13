<?
$backupcmd=IMG_BIN."/acl_backup.sh";
$cmd=sprintf("%s 'get_download_path'",$backupcmd);
$file_path=trim(shell_exec($cmd));
$cmd=sprintf("%s 'backup' '%s'",$backupcmd,$_REQUEST['mdnum']);
unlink($file_path);
shell_exec($cmd);
$dfilename="folder_acl.bin";

header("Content-Type: application/octet-stream;charset=utf-8");
header("Content-Disposition: attachment; filename=$dfilename");
header("Pragma: ");
header("Cache-Control: ");
header("Content-length: " . filesize($file_path));
readfile($file_path);
unlink($file_path);
die();
?>