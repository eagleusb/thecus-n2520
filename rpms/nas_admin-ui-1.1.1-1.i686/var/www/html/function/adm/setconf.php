<?
include_once(INCLUDE_ROOT.'Vendor/vendor.class.php');
$words = $session->PageCode("conf");
$action=$_REQUEST['action_do'];
$sysconf = new VendorConfig();

if ($action == 'Download'){
        unlink('/tmp/confdownload.bin');
	shell_exec('/img/bin/makeDefaultConf.sh');
	$dfile="/tmp/confdownload.bin";
	$dfilename="conf.bin";

	header("Content-Type: application/octet-stream");
	header("Content-Disposition: attachment; filename=$dfilename;");
	header("Pragma: ");
	header("Cache-Control: ");
	header("Content-length: " . filesize($dfile));

	readfile($dfile);
	unlink('/tmp/confdownload.bin');
	echo '{success:true, file:'.json_encode($dfile).'}';
//	return MessageBox(false,$gwords["success"],$dfile);
} 
elseif($action == 'Upload'){
	// upload
	if (NAS_DB_KEY == '1'){
		$enckey="conf_n5200";
	}else{
		$enckey="conf_".$sysconf->data["key"];
	}
	move_uploaded_file($_FILES['config-path']['tmp_name'],'/tmp/confupload.bin');
	//uncompress
	shell_exec('/usr/bin/des -k ' . $enckey . ' -D /tmp/confupload.bin /tmp/conf.tar.gz 2>&1');
	exec('mkdir -p /tmp/conf;tar zxf /tmp/conf.tar.gz -C /tmp/conf',$stdout,$result);

	if($result){
		echo '{failure:true, file:'.json_encode($_FILES['config-path']['name']).', msg:'.json_encode($words["fileError"]).'}';
		exit;
		//return MessageBox(true,$words["fileError"],$gwords["fail"]);
	}
	else{
	    if (NAS_DB_KEY == '1'){
			$isProduct = shell_exec('cat /tmp/conf/etc/manifest.txt')==shell_exec('cat /etc/manifest.txt');
		}else{
	        $isProduct = trim(shell_exec('cat /tmp/conf/etc/manifest.txt'))==trim(shell_exec('cat /etc/manifest.txt'));
		}
		$isProduct = trim(shell_exec('cat /tmp/conf/etc/manifest.txt'))==trim(shell_exec('cat /etc/manifest.txt'));
		preg_match("/([^\-]*)/",shell_exec('cat /tmp/conf/etc/version'),$confVersion);
		preg_match("/([^\-]*)/",shell_exec('cat /etc/version'),$nowVersion);
		
		if($isProduct && $confVersion[1]==$nowVersion[1]){
			shell_exec('mv /tmp/conf.tar.gz /etc');
			shell_exec('rm -rf /tmp/conf /tmp/confupload.bin /tmp/confupload.tar.gz');
			echo '{success:true, file:'.json_encode($_FILES['config-path']['name']).', msg:'.json_encode($words["confSuccess"]).'}';
			//return MessageBox(true,$words["confSuccess"],$gwords["success"]);
		}
		else{
			shell_exec('rm -rf /tmp/conf /tmp/confupload.bin /tmp/confupload.tar.gz');
			echo '{failure:true, file:'.json_encode($_FILES['config-path']['name']).', msg:'.json_encode($words["versionError"]).'}';
			//return MessageBox(true,$words["versionError"],$gwords["fail"]);
		}
		exit;
	}
}
?>
