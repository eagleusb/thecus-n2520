<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'httpd.class.php');

$words = $session->PageCode("httpd");
$gwords = $session->PageCode("global");

// SSL certificate files setting
$sslcrt_dir="/etc/httpd/ssl.d/now";
$server_crt=$sslcrt_dir."/server.crt";
$server_key=$sslcrt_dir."/server.key";
$ca_bundle=$sslcrt_dir."/ca-bundle.crt";

$ssl_restore=$_POST['_restore'];
if($ssl_restore==1){
    check_raid(0);
	shell_exec('/usr/sbin/mod_ssl.tool reset');
	$ary = array('ok'=>'redirect_reboot()');
	return MessageBox(true,$words["http_title"],$words["serviceSuccess"]);
}

$http_enabled=$_POST['_http'];
$http_port=$_POST['_port'];
$ssl_enabled=$_POST['_ssl'];
$ssl_port=$_POST['_sport'];
$ssl_certificate=$_POST['_certificate'];
$db=new sqlitedb();
$ch=new validate;

if (NAS_DB_KEY == '1'){
    $ftpPort=$db->getvar("ftpd_port","21");
}else{
    $ftpPort=$db->getvar("ftp_port","21");
}

//==========  data check -- begin  ==========
if ($ch->check_empty($http_port) && ($http_enabled=='1'))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["http_title"],$words["http_port_empty"]);
}
            
if ($ch->check_empty($ssl_port)&& ($ssl_enabled=='1'))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["ssl_title"],$words["ssl_port_empty"]);
}

if (!$ch->check_port($http_port) && ($http_enabled=='1'))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["http_title"], $words["http_port_error"]);
}

if (!$ch->check_port($ssl_port) && ($ssl_enabled=='1'))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["ssl_title"], $words["ssl_port_error"]);
}

if (str_replace(" ", "", $http_port) == str_replace(" ", "", $ssl_port))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["http_title"],$words["http_eq_ssl"]);
}

if (($http_enabled=='0') && ($ssl_enabled=='0'))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["http_title"],$words["choose_one_service"]);
}

$port1=str_replace(" ", "", $_POST['_port']);
$port2=str_replace(" ", "", $_POST['_sport']);

if (($port1!=80 && $port1<1024 && ($http_enabled=='1')) || $ch->check_used_port($port1) || ($port1 == $ftpPort))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["http_title"],$words["http_port_error"]);
}

if (($port2!=443 && $port2<1024 && ($ssl_enabled=='1')) || $ch->check_used_port($port2) || ($port2 == $ftpPort))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["ssl_title"],$words["ssl_port_error"]);
}

//==========  data check -- end  ==========
        
$o_http_enabled=$db->getvar("httpd_nic1_httpd","1");
$o_http_port=$db->getvar("httpd_port","80");
$o_ssl_enabled=$db->getvar("httpd_nic1_ssl","1");
$o_ssl_port=$db->getvar("httpd_ssl","443");

// validate SSL files
if($ssl_certificate=="1"){
	check_raid(0);

	exec("/usr/bin/openssl.tool all ".$_FILES['_crt']['tmp_name']." ".$_FILES['_key']['tmp_name']." ".$_FILES['_cacrt']['tmp_name']." > /dev/null",$tmp,$ret);

	shell_exec("echo ".$_FILES['_crt']['tmp_name']." > /dev/shm/upload");
	if( $ret == "0" ){
		// Update SSL files
  		shell_exec('rm -rf '.$sslcrt_dir.';mkdir -p '.$sslcrt_dir);
		move_uploaded_file($_FILES['_crt']['tmp_name'],$server_crt);
		move_uploaded_file($_FILES['_cacrt']['tmp_name'],$ca_bundle);
		move_uploaded_file($_FILES['_key']['tmp_name'],$server_key);
	}else{
		echo '{failure:true, msg:'.json_encode($words['ssl_crtfile_error']).'}';
		exit;
	}
}

// Check if config files needs to be updated
if(($http_enabled==$o_http_enabled)&&($http_port==$o_http_port)&&($ssl_enabled==$o_ssl_enabled)&&($ssl_port==$o_ssl_port)){
	unset($db);
	if ($ssl_certificate=="1"){
		echo '{success:true, msg:'.json_encode($words['serviceSuccess']).'}';
		exit;
	}else{
		return MessageBox(true,$words["http_title"],$gwords["setting_confirm"]);
	}
}else{
	// settings has been changed, store the new settings
	$db->setvar("httpd_nic1_httpd",$http_enabled);
	$db->setvar("httpd_port",$http_port);
	$db->setvar("httpd_nic1_ssl",$ssl_enabled);
	$db->setvar("httpd_ssl",$ssl_port);
	unset($db);
	$ary = array('ok'=>'redirect_reboot()');
	return  MessageBox(true,$words['http_title'],$words["serviceSuccess"],'INFO','OK',$ary);
}
