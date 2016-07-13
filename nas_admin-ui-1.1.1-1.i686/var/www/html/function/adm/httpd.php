<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$prefix=httpd;
$words = $session->PageCode("httpd");
$db=new sqlitedb();
$http_enabled=$db->getvar("httpd_nic1_httpd","1");
$http_port=$db->getvar("httpd_port","80");
$ssl_enabled=$db->getvar("httpd_nic1_ssl","1");
$ssl_port=$db->getvar("httpd_ssl","443");
unset($db);

$command="cat /tmp/ssl.conf | awk '/SSLCertificateFile/{FS=\"/\";printf(\"%s\\n\",substr(\$2,1))}'";
$ssl_folder=trim(shell_exec($command));

$ssl_file=file_exists("/raid/sys/httpd/server.crt");
$ssl_filetime=date("Y-m-d H:i:s",filemtime("/raid/sys/httpd/server.crt"));

if($ssl_enabled=="1"){
	if($ssl_folder=="opt" && $ssl_file=="1"){
		$ssl_log=sprintf($words["ssl_crtfile_error"],$ssl_filetime);
	}elseif($ssl_folder=="raid"){
		$ssl_log=sprintf($words["ssl_crtfile_success"],$ssl_filetime);
	}
}

$words = $session->PageCode($prefix);
$tpl->assign('words',$words);
$tpl->assign('http_enabled',$http_enabled);
$tpl->assign('http_port',$http_port);
$tpl->assign('ssl_enabled',$ssl_enabled);
$tpl->assign('ssl_port',$ssl_port);
$tpl->assign('ssl_log',$ssl_log);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
