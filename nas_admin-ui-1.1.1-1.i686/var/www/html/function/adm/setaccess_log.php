<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("log");
$gwords = $session->PageCode("global");

if (($_POST[_folder_selected]=="") && ($_POST[_access_log]=="1")){
	return  MessageBox(true,$gwords['error'],$words["folder_error"],'Error');  
}

//check if post and db data are same 
$db=new sqlitedb();
$post_key = array("access_log_enabled","access_log_folder","apple_log","ftp_log","iscsi_log","smb_log","sshd_log");
foreach ($post_key as $k){
    if (($k=="access_log_enabled") || ($k=="access_log_folder")){
        $post_array[$k]=$_POST[$k];
    }else{
        $post_array[$k]=($_POST[$k]=="on")?'1':'0';
    }
}

$db_key=array(
        "access_log_enabled"=>"0",
        "access_log_folder"=>"NAS_Public",
        "apple_log"=>"0",
        "ftp_log"=>"0",
        "iscsi_log"=>"0",
        "smb_log"=>"0",
        "sshd_log"=>"0",
        "apple_talkd"=>"0",
        "ftp_ftpd"=>"0",
        "httpd_nic1_cifs"=>"0",
        "sshd_enable"=>"0");

foreach ($db_key as $k=>$v)
    $db_array[$k]=$db->getvar($k,$v);

// write configuration into database
if ($post_array['access_log_enabled']=="1"){ 
    foreach ($post_key as $k){
        $db->setvar($k,$post_array[$k]);
    }
    shell_exec("/img/bin/rc/rc.syslogd restart > /dev/null 2>&1");
    
    if (($db_array['apple_talkd']=="1") && ($db_array['apple_log'] != $post_array['apple_log']))
        shell_exec("/img/bin/rc/rc.atalk reload > /dev/null 2>&1");

    if (($db_array['ftp_ftpd']=="1") && ($db_array['ftp_log'] != $post_array['ftp_log']))
        shell_exec("/img/bin/rc/rc.ftpd restart > /dev/null 2>&1");

    if (($db_array['httpd_nic1_cifs']=="1") && ($db_array['smb_log'] != $post_array['smb_log']))
        shell_exec("/img/bin/rc/rc.samba restart > /dev/null 2>&1");

    if (($db_array['sshd_enable']=="1") && ($db_array['sshd_log'] != $post_array['sshd_log'])){
        shell_exec("/img/bin/rc/rc.sshd stop > /dev/null 2>&1");
        shell_exec("/img/bin/rc/rc.sshd start > /dev/null 2>&1");
    }
}else{
    $db->setvar("access_log_enabled",$post_array['access_log_enabled']);
    shell_exec("/img/bin/rc/rc.syslogd restart > /dev/null 2>&1");
}

return MessageBox(true,$words['Log'],$gwords["setting_success"]);

