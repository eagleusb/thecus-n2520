<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$ch= new validate;
$db=new sqlitedb();

$words = $session->PageCode("ftp");
$gwords = $session->PageCode('global');

if ($_POST['_bandwidth_upload'] == 'Unlimited')
	$_POST['_bandwidth_upload']='';
else
	$_POST['_bandwidth_upload']=substr($_POST['_bandwidth_upload'],0,-4)*1024;
	
if ($_POST['_bandwidth_download'] == 'Unlimited')
	$_POST['_bandwidth_download']='';
else
	$_POST['_bandwidth_download']=substr($_POST['_bandwidth_download'],0,-4)*1024;
	
if (!isset($_POST['_rename']))
	$_POST['_rename']=0;
else
	$_POST['_rename']=1;

$post_key=array('_ftp','_ssl','_encode_selected','_port','_passive_ip','_anon_selected','_rename','_bandwidth_upload','_bandwidth_download','_range_begin','_range_end');
$post_array=array();

foreach ($post_key as $k) 
	$post_array[]=$_POST[$k];

if (NAS_DB_KEY == '1'){
	$db_key=array("ftpd_enabled"=>"0",
	      "ftpd_ssl"=>"0",
	      "ftpd_encode"=>"UTF-8",
	      "ftpd_port"=>"21",
	      "ftpd_anonymous"=>"0",
	      "ftpd_auto_rename"=>"0",
              "ftpd_upload_bw"=>"",
              "ftpd_download_bw"=>"",
              "ftpd_port_range_begin"=>"30000",
              "ftpd_port_range_end"=>"32000");
}else{
	$db_key=array("ftp_ftpd"=>"0",
	      "ftp_ssl"=>"0",
	      "ftp_ftpd_encode"=>"UTF-8",
	      "ftp_port"=>"21",
	      "ftpd_passive_ip"=>"",
	      "ftp_ftpd_anon"=>"0",
	      "ftp_ftpd_rename"=>"0",
              "ftp_ftpd_bandwidth_upload"=>"",
              "ftp_ftpd_bandwidth_download"=>"",
              "ftp_port_range_begin"=>"30000",
              "ftp_port_range_end"=>"32000");
}
              
$db_array=array();
foreach ($db_key as $k=>$v) 
	$db_array[]=$db->getvar($k,$v);
	
if (serialize($post_array)==serialize($db_array)){
  unset($db);
}else{
    //==========  data check -- begin  ==========
    if ($_POST['_ftp']=='1'){
        $range_begin=str_replace(" ", "", $_POST['_range_begin']);
        $range_end=str_replace(" ", "", $_POST['_range_end']);
	if ( $ch->check_empty($_POST['_range_begin']) || $ch->check_empty($_POST['_range_end']) ){
            unset($ch);
            unset($db);
            return MessageBox(true,$words["ftpd_title"],$words["port_range_empty"]);
	}    	
	if ( !$ch->check_port($_POST['_range_begin']) || !$ch->check_port($_POST['_range_end']) || $range_begin < 30000 || $range_begin > 32000 || $range_end < 30000 || $range_end > 32000 || $range_begin > $range_end ){
            unset($ch);
            unset($db);
            return MessageBox(true,$words["ftpd_title"], $words["port_range_error"]);
        } 
    }
    
    if ($ch->check_empty($_POST['_port']) && ($_POST['_ftp']=='1'))
    {
        unset($ch);
        unset($db);
        return MessageBox(true,$words["ftpd_title"],$words["ftp_port_empty"]);
    }

    if (!$ch->check_port($_POST[_port]) && ($_POST['_ftp']=='1'))
    {
        unset($ch);
        unset($db);
        return MessageBox(true,$words["ftpd_title"], $words["ftp_port_error"]);
    }

    if ($_POST['_passive_ip']!="")
    {
        if (!$ch->ip_address($_POST['_passive_ip']) && ($_POST['_ftp']=='1'))
        {
           unset($ch);
           unset($db);
           return MessageBox(true,$words["ftpd_title"],$gwords["ip_error"]);
  	}
    }

    $port1=str_replace(" ", "", $_POST['_port']);

    if (($port1!=21 && $port1<1024 && ($_POST['_ftp']=='1')) || $port1==3689 )
    {
        unset($ch);
        unset($db);
        return MessageBox(true,$words["ftpd_title"],$words["ftp_port_error"]);
    }
    //==========  data check -- end  ==========


  $idx=0;
  foreach ($db_key as $k=>$v){
  	$db->setvar($k,$post_array[$idx]);
  	$idx++;
  }
  unset($db);
  $rc_path="/img/bin/rc/";
  if ($post_array[0] == 1){
    shell_exec($rc_path."rc.ftpd restart > /dev/null 2>&1");
    shell_exec("/img/bin/logevent/event 131 &");
    return MessageBox(true,$words['ftpd'],$words["ftpdEnable"]);
  }else if ($post_array[0] == 0){
    shell_exec($rc_path."rc.ftpd stop > /dev/null 2>&1");
    shell_exec("/img/bin/logevent/event 132 &");
    return MessageBox(true,$words['ftpd'],$words["ftpdDisable"]);
  }
}
