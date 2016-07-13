<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'setnic.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'function.php');

$words = $session->PageCode("network");
$gwords = $session->PageCode("global");

$rc_path="/img/bin/rc/";
$db=new sqlitedb();
$ch= new validate;

$update=0;

//modify $_POST for setinc.class.php

$_POST['interface'] = '1';
$_POST['prefix'] = 'nic2';
$_POST['tmp_dhcp'] = $_POST['_dhcp'];
$_POST['_jumbo'] = $_POST['_jumbo_selected'];
$prefix = 'nic2';
$formname = 'nic2';

$NIC=new SetNIC($_POST['prefix'],$_POST);
//$result = ($_POST['_dhcp']) ? 0:$NIC->canChange();
$result = $NIC->canChange();

//==========lan config==========
//post data
$lan_post_key=array( '_jumbo_selected', '_ip', '_netmask');
$lan_post_array=array();
foreach ($lan_post_key as $k) 
	$lan_post_array[]=$_POST[$k];
//db data
$lan_db_key=array(	"nic2_jumbo"=>"1500",
			"nic2_ip"=>"192.168.2.254",
			"nic2_netmask"=>"255.255.255.0");
$lan_db_array=array();
foreach ($lan_db_key as $k=>$v) 
	$lan_db_array[]=$db->getvar($k,$v);
	
if ($result==0){
    if (serialize($lan_post_array)!=serialize($lan_db_array) ){
        //==========  data check -- begin  ==========
        if ($ch->check_empty($_POST[_ip]) || !$ch->ip_address($_POST[_ip]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["lan_title"],$gwords["ip_error"]);
        }        
            
        if ($ch->check_empty($_POST[_netmask]) || !$ch->ip_address($_POST[_netmask]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["lan_title"],$gwords["netmask_error"]);
        }        

        if((check_dhcp_range($_POST[_ip],$_POST[_netmask],$_POST[_startip],$_POST[_endip])==-2) && ($_POST['_dhcp']==1))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["lan_title"],$words["ip_segment_error"]);
        }
                                                            
        //==========  data check -- end  ========== 
        
        $idx=0;
        foreach ($lan_db_key as $k=>$v){
  	        $db->setvar($k,$lan_post_array[$idx]);
  	        $idx++;
        }
    
        //$NIC=new SetNIC($_POST['prefix'],$_POST);
        $update=1;
    }
    
    //==========dhcpd config==========
    $dhcp_post_enable=$_POST['_dhcp'];
    $dhcp_db_enable=$db->getvar('nic2_dhcp','0');
    
    if ($dhcp_post_enable == '1'){
    	//post data
      $dhcp_post_key=array( '_dhcp', '_startip', '_endip', '_gateway');
      $dhcp_post_array=array();
      foreach ($dhcp_post_key as $k) 
        $dhcp_post_array[]=$_POST[$k];
    	//db data
        $dhcp_db_key=array(	"nic2_dhcp"=>"0",
            "nic2_startip"=>"192.168.2.1",
            "nic2_endip"=>"192.168.2.100",
			"nic2_gateway"=>"");
    				
      $dhcp_db_array=array();
      foreach ($dhcp_db_key as $k=>$v) 
        $dhcp_db_array[]=$db->getvar($k,$v);
        if (serialize($dhcp_post_array)!=serialize($dhcp_db_array)){
            //==========  data check -- begin  ==========
            if ($ch->check_empty($_POST[_startip]) || !$ch->ip_address($_POST[_startip]))
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["lan_title"],$words["startip_error"]);
            }        
                
            if ($ch->check_empty($_POST[_endip]) || !$ch->ip_address($_POST[_endip]))
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["lan_title"],$words["endip_error"]);
            }        
            
        if (!$ch->check_empty($_POST[_gateway]) && !$ch->ip_address($_POST[_gateway]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["lan_title"],$words["gateway_error"]);
        }        

            if(check_dhcp_range($_POST[_ip],$_POST[_netmask],$_POST[_startip],$_POST[_endip])==-1)
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["lan_title"],$words["range_error"]);
            } 
            
            if(check_dhcp_range($_POST[_ip],$_POST[_netmask],$_POST[_startip],$_POST[_endip])==-2)
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["lan_title"],$words["ip_segment_error"]);
            }
                                                                               
            //==========  data check -- end  ========== 
    
        $idx=0;
        foreach ($dhcp_db_key as $k=>$v){
          $db->setvar($k,$dhcp_post_array[$idx]);
          $idx++;
        }
    
        if ($update == 0)
          shell_exec($rc_path."rc.udhcpd_eth1 start > /tmp/udhcpd.tmp 2>&1 &");
    
        $update=2;
      }
    }else{
      if ($dhcp_post_enable != $dhcp_db_enable){
        $db->setvar('nic2_dhcp',$dhcp_post_enable);
        if ($update == '0')
          shell_exec($rc_path."rc.udhcpd_eth1 stop > /tmp/udhcpd.tmp 2>&1 &");
        $update=2;
      }
    }
}else{
  if($NIC->theSameIPError){
    $errmsg = $words['lan_ipExist'];
    if($NIC->internalError)
      $errmsg = $words['lan_internalError'];

    $update=-1; 
  }
  if($NIC->theSameSegmentError){
    $errmsg = $words['theSameSegment'];
    $update=-1; 
  }
}
			
unset($ch);
unset($db);


              
//return MessageBox(true,$dhcp_post_enable,$dhcp_db_enable);
if ($update>0){ 
  $NIC->Batch();
	//return MessageBox(true,$gwords['lan'],$words["lan_staticSuccess"]);
	$ary = array('ok'=>'redirect_reboot()');
	if (serialize($lan_post_array)!=serialize($lan_db_array) ){
		$strExec="/img/bin/logevent/event 997 423 info \"\" \"LAN2\" \"".$_POST['_ip']."\" \"".$_POST['_netmask']."\"";
		shell_exec($strExec);
	}
	
	if($dhcp_post_enable=="1"){
	  if (serialize($dhcp_post_array)!=serialize($dhcp_db_array)){
      $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='nic1_dns'\"";
      $dns=shell_exec($strExec);
			$strExec="/img/bin/logevent/event 997 424 info \"\" \"LAN2\" \"ON\" \", Start IP = ".$_POST[_startip]."\" \", End IP = ".$_POST[_endip]."\" \", Gateway = ".$_POST['_gateway']."\" \", DNS = ".$dns."\"";
			shell_exec($strExec);
  	}
  }else{
    if ($dhcp_post_enable != $dhcp_db_enable){
			$strExec="/img/bin/logevent/event 997 424 info \"\" \"LAN2\" \"OFF\"";
			shell_exec($strExec);
		}
	}	  
	  
	return  MessageBox(true,$gwords['lan'],$words["lan_staticSuccess"],'INFO','OK',$ary);
}else if ($update<0)
	return MessageBox(true,$gwords['lan'],$errmsg);
else
  return MessageBox(true,$gwords['lan'],$gwords["setting_confirm"]);

?>
