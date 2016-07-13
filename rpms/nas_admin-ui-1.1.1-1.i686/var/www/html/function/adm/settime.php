<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$ch= new validate;
$db=new sqlitedb();

$words = $session->PageCode("time");
$gwords = $session->PageCode("global");

$ntp_cfg_mode = $_REQUEST['_ntp_cfg_mode'];
$ntp_server_mode = $_REQUEST['_ntp_server_mode'];

$ontp_server_mode=$db->getvar("ntp_server_mode","0");

if ($ntp_cfg_mode == 'yes')
{
    if ($ch->is_simple_url($_REQUEST['_ntp_server']))
        $db->setvar("ntp_server",$_REQUEST['_ntp_server']);
    else
    {
        unset($ch);
        unset($db);
        return  MessageBox(true,$words['time_title'],$words['ntp_server_error']);
    }        
}

$db->setvar("ntp_cfg_mode",$ntp_cfg_mode);

$date_str = explode("/",str_replace("\n","",$_REQUEST['_date']));
$time_str = explode(":",str_replace("\n","",$_REQUEST['_time']));
$datetime = $date_str[0].$date_str[1].$time_str[0].$time_str[1].$date_str[2];

//Modify System Time Zone
if($_REQUEST['_timezone_selected']=="Asia/Beijing"){
    $timezone="Asia/Shanghai";
}else{
    $timezone=$_REQUEST['_timezone_selected'];
}
shell_exec("/bin/ln -sf /usr/share/zoneinfo/".$timezone." /etc/localtime");

$ret="";
if ($ntp_cfg_mode == 'no'){
  //Modify System Time Clock
    shell_exec("/bin/date '$datetime' && /sbin/hwclock -w --localtime");
} else {
    shell_exec("/img/bin/rc/rc.ntp stop");
    $ret=shell_exec("/img/bin/ntpdate.sh ". $_REQUEST['_ntp_server']);
}

if($ntp_server_mode != $ontp_server_mode){
    //echo "change ntp_server_mode to $nntp_server_mode<br>";
    $db->setvar("ntp_server_mode",$ntp_server_mode);
}

shell_exec("/img/bin/rc/rc.ntp stop > /dev/null 2>&1");
shell_exec("/img/bin/rc/rc.ntp start > /dev/null 2>&1");

unset($ch);
unset($db);

if ($ret=="")
  return  MessageBox(true,$words['time_title'],$words['timeSuccess']);
else
  return  MessageBox(true,$words['time_title'],$words['sync_ntp_server_fail']);
?> 
