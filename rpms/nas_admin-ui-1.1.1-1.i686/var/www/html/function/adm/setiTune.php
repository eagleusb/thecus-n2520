<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(WEBCONFIG);
$words = $session->PageCode("iTune");
$gwords = $session->PageCode("global");

$ch= new validate;
$db=new sqlitedb();

$update=0;

//==========notif config==========
//post data
$iTune_post_key=array( '_iTune', '_servername', '_passwd', '_rescan_interval_selected', '_encode_selected');
$iTune_post_array=array();
foreach ($iTune_post_key as $k)
	$iTune_post_array[]=$_POST[$k];
//db data
$iTune_db_key=array("iTune_iTune"=>"0",
			"iTune_servername"=>$webconfig['product_no'],
			"iTune_passwd"=>"",
			"iTune_rescan_interval"=>"1800",
			"iTune_encode"=>"ISO_8859-1");
			
$iTune_db_array=array();
foreach ($iTune_db_key as $k=>$v)
	$iTune_db_array[]=$db->getvar($k,$v);

//check if the length of server's name is correct.
if (!$ch->limitstrlen(0, 63, $_POST['_servername']))
{
    unset($ch);
    unset($db);
    return MessageBox(true,$words["iTune"],$words["servername_error"]);
}

if (serialize($iTune_post_array)!=serialize($iTune_db_array) ){
  $idx=0;
  if($_POST[_iTune]){
    foreach ($iTune_db_key as $k=>$v){
	    $db->setvar($k,$iTune_post_array[$idx]);
	  	$idx++;
    }
  }
  else{
    	$db->setvar("iTune_iTune",$_POST[_iTune]);
  }
  //$NIC=new SetNIC($_POST['prefix'],$_POST);
  $update=1;
}

unset($ch);
unset($db);
	
//return MessageBox(true,$dhcp_post_enable,$dhcp_db_enable);
if ($update==1)
{
	if($_POST[_iTune]){
		shell_exec("/bin/rm -fr /var/cache/mt-daapd/songs.gdb");
		shell_exec("/img/bin/rc/rc.daapd restart > /dev/null 2>&1");
		return MessageBox(true,$words["iTune"],$words["ituneChange"]);
	}
	else{
		shell_exec("/bin/rm -fr /var/cache/mt-daapd/songs.gdb");
		shell_exec("/img/bin/rc/rc.daapd stop > /dev/null 2>&1");
		return MessageBox(true,$words["iTune"],$words["ituneDisable"]);
	}
}
else
    return MessageBox(true,$words["iTune"],$gwords["setting_confirm"]);
?>