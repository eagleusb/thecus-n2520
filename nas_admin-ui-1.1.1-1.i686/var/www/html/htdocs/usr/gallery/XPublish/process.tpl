<?
    @session_start();
    function eecho($str){
	//shell_exec('echo "'.$str.'" >> /tmp/pu.log');
    }
    require_once("../GlobalVars.html");

    $album = $_GET['album'];

    // Test if the filename of the temporary uploaded picture is empty
    if ($_FILES['userpicture']['tmp_name'] == '') eecho('no_pic_uploaded');
    // Create destination directory for pictures
    $dest_dir = AlbumRoot.$_GET['id'].'/' . $album . '/';

    // Check that target dir is writable
    if (!is_writable($dest_dir)) eecho('dest_dir_ro'.$dest_dir);

    $matches = array();
    //$picture_name = $_FILES['userpicture']['name'];
    $picture_name = $_GET['PicName'];
    if (!preg_match("/(.+)\.(.*?)\Z/", $picture_name, $matches)) {
        $matches[1] = 'invalid_fname';
        $matches[2] = 'xxx';
    }

    $username = $_GET['id'];
    $group = 'smbusers';
    if ($username == ''){
	$username = 'nobody';
	$group = 'nogroup';
    }	

    // Create a unique name for the uploaded file
    $nr = 0;
    $picture_name = $matches[1] . '.' . $matches[2];
    while (file_exists($dest_dir . $picture_name)) {
      	$picture_name = $matches[1] . '~' . $nr++ . '.' . $matches[2];
    }
    $uploaded_pic = $dest_dir . $picture_name;

    // Move the picture into its final location
    if (is_uploaded_file($_FILES['userpicture']['tmp_name'])){
        if (!copy($_FILES['userpicture']['tmp_name'],$uploaded_pic)) {
            @unlink($_FILES['userpicture']['tmp_name']);
            eecho('err_move '.$picture_name.' to '.$dest_dir.' '.$_FILES['userpicture']['tmp_name']);
            exit;
	}
	@unlink($_FILES['userpicture']['tmp_name']);
        chown($uploaded_pic,$username);
        chgrp($uploaded_pic,$group);
    }

    $_GET['PicName'] = $picture_name;
    include('../GetPic.html');

    eecho ("SUCCESS");
    exit;
?>
