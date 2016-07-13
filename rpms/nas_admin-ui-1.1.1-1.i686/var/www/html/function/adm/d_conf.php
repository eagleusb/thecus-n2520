<?

unlink('/tmp/confdownload.bin');
if (NAS_DB_KEY == '1'){
	shell_exec('/img/bin/model/makeDefaultConf.sh');
}
else
{
	shell_exec('/img/bin/makeDefaultConf.sh');
}
$dfile="/tmp/confdownload.bin";
$dfilename="conf.bin";

header("Content-Type: application/octet-stream");
header("Content-Disposition: attachment; filename=$dfilename;");
header("Pragma: ");
header("Cache-Control: ");
header("Content-length: " . filesize($dfile));

readfile($dfile);
unlink('/tmp/confdownload.bin');
die();
//echo '{success:true, file:'.json_encode($dfile).'}';
//	return MessageBox(false,$gwords["success"],$dfile);

?>
