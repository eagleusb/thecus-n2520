<?php
//require_once("/etc/www/htdocs/setlang/lang.html");
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$prefix=ftp;

$db=new sqlitedb();
if (NAS_DB_KEY == '1'){
    $enabled=$db->getvar("ftpd_enabled","0");
    $ssl=$db->getvar("ftpd_ssl","0");
    $encode=$db->getvar("ftpd_encode","UTF-8");
    $port=$db->getvar("ftpd_port","21");
    $anon=$db->getvar("ftpd_anonymous","0");
    $rename=$db->getvar("ftpd_auto_rename","0");
    $bandwidth_upload=trim($db->getvar("ftpd_upload_bw",""));
    $bandwidth_download=trim($db->getvar("ftpd_download_bw",""));
    $port_range_begin=$db->getvar("ftpd_port_range_begin","30000");
    $port_range_end=$db->getvar("ftpd_port_range_end","32000");
}else{
    $enabled=$db->getvar("ftp_ftpd","0");
    $ssl=$db->getvar("ftp_ssl","0");
    $encode=$db->getvar("ftp_ftpd_encode","UTF-8");
    $port=$db->getvar("ftp_port","21");
    $passive_ip=$db->getvar("ftpd_passive_ip","");
    $anon=$db->getvar("ftp_ftpd_anon","0");
    $rename=$db->getvar("ftp_ftpd_rename","0");
    $bandwidth_upload=trim($db->getvar("ftp_ftpd_bandwidth_upload",""));
    $bandwidth_download=trim($db->getvar("ftp_ftpd_bandwidth_download",""));
    $port_range_begin=$db->getvar("ftp_port_range_begin","30000");
    $port_range_end=$db->getvar("ftp_port_range_end","32000");
}
unset($db);

$words = $session->PageCode($prefix);
$gwords = $session->PageCode('global');

$encode_value=array("BIG5", "GBK", "GB2312", "GB18030", "ISO_8859-1",
		"EUC-JP", "SHIFT-JIS", "EUC-KR", "CP1251", "KOI8-R", "UTF-8");
		
$encode_fields="['value','display']";
$encode_data="[";
foreach ($encode_value as $item){
	if ($item == "ISO_8859-1")
		$encode_data.="['".$item."','ISO'],";
	else
		$encode_data.="['".$item."','".$item."'],";
}
$encode_data = rtrim($encode_data,",");
$encode_data.="]";

$anon_fields="['value','display']";
$anon_data="[";
$anon_idx=0;

if (NAS_DB_KEY == '1')
    $anon_value=array($words['anonymous_upload_download'],$gwords['download'],$words['anonymous_not_access'],$gwords['upload']);
else
    $anon_value=array($words['anonymous_not_access'],$gwords['download'],$words['anonymous_upload_download'],$words['anonymous_upload_only']);

foreach ($anon_value as $item){
	$anon_data.="['".$anon_idx."',\"".$item."\"],";
		$anon_select.="<option value=\"".$anon_idx."\">".$item."</option>";
	$anon_idx++;
}
$anon_data = rtrim($anon_data,",");
$anon_data.="]";

$bandwidth_upload_value=0;
if (($bandwidth_upload != '')||($bandwidth_upload != '0'))
	$bandwidth_upload_value=$bandwidth_upload/1024;

$bandwidth_download_value=0;
if (($bandwidth_download != '')||($bandwidth_download != '0'))
	$bandwidth_download_value=$bandwidth_download/1024;

$tpl->assign('words',$words);
$tpl->assign($prefix.'_enabled',$enabled);
$tpl->assign($prefix.'_ssl',$ssl);
$tpl->assign($prefix.'_encode',$encode);
$tpl->assign($prefix.'_encode_fields',$encode_fields);
$tpl->assign($prefix.'_encode_data',$encode_data);
$tpl->assign($prefix.'_port',$port);
$tpl->assign($prefix.'_passive_ip',$passive_ip);
$tpl->assign($prefix.'_anon',$anon);
$tpl->assign($prefix.'_anon_fields',$anon_fields);
$tpl->assign($prefix.'_anon_data',$anon_data);
$tpl->assign($prefix.'_rename',$rename);
$tpl->assign($prefix.'_bandwidth_upload',$bandwidth_upload_value);
$tpl->assign($prefix.'_bandwidth_download',$bandwidth_download_value);
$tpl->assign($prefix.'_port_range_begin',$port_range_begin);
$tpl->assign($prefix.'_port_range_end',$port_range_end);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
