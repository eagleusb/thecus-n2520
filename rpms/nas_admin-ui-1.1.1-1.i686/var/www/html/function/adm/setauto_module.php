<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'module.class.php');

$words = $session->PageCode("module");
$gwords = $session->PageCode("global");
$rc="/img/bin/rc/rc.automodule";

if($_REQUEST['prefix']=='check_lock'){
	$module=new Module($words,$gwords);
	$lock_exist=$module->lock_exist();
	if ( $lock_exist == "0"){
		echo '{success:true, lock:true}';
	}else{
		echo '{success:true, lockt:false}';
	}
	unset($module);
	exit;
}elseif($_REQUEST['prefix']=='install_hdd'){
    shell_exec("sh ".$rc." install '".$_REQUEST['modname']."' '".$_REQUEST['display_name']."' > /dev/null 2>&1 &");
    exit;
} elseif($_REQUEST['prefix'] == 'install_air'){
    shell_exec("sh ".$rc." online '".$_REQUEST['modname']."' '".$_REQUEST['modurl']."' '".$_REQUEST['display_name']."' > /dev/null 2>&1 &");
    exit;
} elseif($_REQUEST['prefix'] == 'show_guide'){
    $guide = '/raid/data/module/.module/'.$_REQUEST['modname'].'/Configure/Guide.pdf';
    if (file_exists($guide)) {
    	header('Content-type: application/pdf');
    	header('Content-Disposition: attachment; filename="'.$guide.'"');
        ob_clean();
    	flush();
    	readfile($pdf);
    }
    exit;
} elseif($_REQUEST['prefix'] == 'show_note'){
    $note = '/raid/data/module/.module/'.$_REQUEST['modname'].'/Configure/Note';
    if (file_exists($note)) {
    	header('Content-type: application/txt');
    	header('Content-Disposition: attachment; filename="'.$note.'"');
        ob_clean();
    	flush();
    	readfile($note);
    }
    exit;
} elseif($_REQUEST['prefix'] == 'remove_mod'){
    shell_exec("sh ".$rc." remove '".$_REQUEST['modname']."'");
    $moduleData=trim(shell_exec("sh ".$rc." list | tr -d \'"));
    die(json_encode(array('moduleData2'=>$moduleData, 'msg'=>'')));
    exit;
} elseif($_REQUEST['prefix'] == 'upload'){
    move_uploaded_file($_FILES['module_package']['tmp_name'], MODULE_TMP.'modulepackage.zip');
    shell_exec("sh ".$rc." upload");
    shell_exec("sh ".$rc." scan");
    echo '{success:true, type:"upgradePrompt", msg:'.json_encode($gwords['success']).'}';
    exit;
} elseif($_REQUEST['prefix'] == 'rescan'){
    shell_exec("sh ".$rc." scan");
    echo '{success:true, type:"upgradePrompt", msg:'.json_encode($gwords['success']).'}';
    exit;
} else {
    $moduleData=trim(shell_exec("sh ".$rc." list | tr -d \'"));
    die(json_encode(array('moduleData2'=>$moduleData, 'msg'=>'')));
exit;
}

?>
