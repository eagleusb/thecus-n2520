<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'setnic.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("network");
$gwords = $session->PageCode("global");

$rc_path="/img/bin/rc/";
$db=new sqlitedb();
$ch=new validate();

$update=0;

//modify $_POST for setinc.class.php

$_POST['interface'] = '1';
$num=$_POST['num'];
$_POST['_jumbo'] = $_POST['_jumbo_selected'];
$prefix = $_POST['prefix'];
$NIC=new SetNIC($_POST['prefix'],$_POST);
//$result = ($_POST['_dhcp']) ? 0:$NIC->canChange();
$result = $NIC->canChange();

//==========lan config==========
//post data
#$tengb_post_key=array( '_jumbo_selected', '_ip', '_netmask','_gateway');
$tengb_post_key=array( '_jumbo_selected', '_ip', '_netmask', '_mac');
$tengb_post_array=array();
$title=sprintf($words['10gbe_title'],$num);

foreach ($tengb_post_key as $k) 
	$tengb_post_array[]=$_POST[$k];
//db data
$tengb_db_key=array($prefix."_jumbo"=>$_POST['_default_jumbo'],
			$prefix."_ip"=>$_POST['_default_ip'],
			$prefix."_netmask"=>$_POST['_default_mask'],
			$prefix."_mac"=>$_POST['_db_mac']/*,
			$prefix."_gateway"=>""*/);
$tengb_db_array=array();
foreach ($tengb_db_key as $k=>$v) 
	$tengb_db_array[]=$db->getvar($k,$v);

if ($result==0){
    if (serialize($tengb_post_array)!=serialize($tengb_db_array) ){
        //==========  data check -- begin  ==========
        if ($ch->check_empty($_POST[_ip]) || !$ch->ip_address($_POST[_ip]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$title,$gwords["ip_error"],'ERROR');
        }        
            
        if ($ch->check_empty($_POST[_netmask]) || !$ch->ip_address($_POST[_netmask]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$title,$gwords["netmask_error"],'ERROR');
        }        

/*        if (!$ch->check_empty($_POST[_gateway]) && !$ch->ip_address($_POST[_gateway]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["tengb_title"],$words["gateway_error"]);
        }        

        if((check_dhcp_range($_POST[_ip],$_POST[_netmask],$_POST[_startip],$_POST[_endip])==-2) && ($_POST['_dhcp']==1))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["tengb_title"],$words["ip_segment_error"],'ERROR');
	      }
*/                                           
        //==========  data check -- end  ==========         
        //$db->setvar($prefix,$_POST['_mac']);
        //$NIC=new SetNIC($_POST['prefix'],$_POST);
        $update=1;
    }
    //==========dhcpd config==========
    $dhcp_post_enable=$_POST['_dhcp'];
    $dhcp_db_enable=$db->getvar($prefix.'_dhcp','0');

    if ($dhcp_post_enable == '1'){
	//post data
	    $dhcp_post_key=array( '_dhcp', '_startip', '_endip');
	    $dhcp_post_array=array();
	    foreach ($dhcp_post_key as $k) 
		    $dhcp_post_array[]=$_POST[$k];
	      //db data
	    $dhcp_db_key=array($prefix."_dhcp"=>"0",
	    			             $prefix."_startip"=>$_POST['_default_sdbcp'],
	    			             $prefix."_endip"=>$_POST['_default_edbcp']
	    			       );
	    			
	    $dhcp_db_array=array();
	    
	    foreach ($dhcp_db_key as $k=>$v) 
	    	$dhcp_db_array[]=$db->getvar($k,$v);
      
      if (serialize($dhcp_post_array)!=serialize($dhcp_db_array)){
          //==========  data check -- begin  ==========
          if ($ch->check_empty($_POST[_startip]) || !$ch->ip_address($_POST[_startip]))
          {
              unset($ch);
              unset($db);
              return MessageBox(true,$words["tengb_title"],$words["startip_error"],'ERROR');
          }        
              
          if ($ch->check_empty($_POST[_endip]) || !$ch->ip_address($_POST[_endip]))
          {
              unset($ch);
              unset($db);
              return MessageBox(true,$words["tengb_title"],$words["endip_error"],'ERROR');
          }        
          
          if(check_dhcp_range($_POST[_ip],$_POST[_netmask],$_POST[_startip],$_POST[_endip])==-1)
          {
              unset($ch);
              unset($db);
              return MessageBox(true,$words["tengb_title"],$words["range_error"],'ERROR');
          } 
          
          if(check_dhcp_range($_POST[_ip],$_POST[_netmask],$_POST[_startip],$_POST[_endip])==-2)
          {
              unset($ch);
              unset($db);
              return MessageBox(true,$words["tengb_title"],$words["ip_segment_error"],'ERROR');
          }
                                                                             
          //==========  data check -- end  ========== 
    
          $idx=0;
	  	    foreach ($dhcp_db_key as $k=>$v){
	  		      $db->setvar($k,$dhcp_post_array[$idx]);
	  		      $idx++;
	  	    }
    
	  	    if ($update == 0)
	  		    shell_exec($rc_path."rc.tengb dhcp_start ".$prefix." ".$_POST['_ip']." ".$_POST['_netmask']." ".$_POST['_startip']." ".$_POST['_endip']." > /tmp/udhcpd".$prefix.".tmp 2>&1 &");
    
	  	    $update=2;
	    }
  }else{
	  if ($dhcp_post_enable != $dhcp_db_enable){
		  $db->setvar($prefix.'_dhcp',$dhcp_post_enable);
		  if ($update == '0')
			  shell_exec($rc_path."rc.tengb dhcp_stop ".$prefix." > /tmp/udhcpd".$prefix.".tmp 2>&1 &");
		    $update=2;
	  }
  }

  if (serialize($tengb_post_array)!=serialize($tengb_db_array) ){
    $idx=0;
    foreach ($tengb_db_key as $k=>$v){
      $db->setvar($k,$tengb_post_array[$idx]);
      $idx++;
    }
  }
}else{
  if($NIC->theSameIPError){
    $errmsg = sprintf($words['10gbe_ipExist'],$num);
    if($NIC->internalError)
      $errmsg = sprintf($words['10gbe_internalError'],$num);

    $update=-1; 
  }
  if($NIC->theSameSegmentError){
    $errmsg = $words['theSameSegment'];
    $update=-1; 
  }
}

unset($ch);
unset($db);

$is_exist=trim(shell_exec("/sbin/ifconfig | awk '/^".$prefix."/{print $1}'"));
//return MessageBox(true,$dhcp_post_enable,$dhcp_db_enable);
if ($update<0){
  return MessageBox(true,$title,$errmsg,'ERROR');
}else if ($update>0 || $is_exist==""){ 
	//return MessageBox(true,$gwords['lan'],$words["lan_staticSuccess"]);
	$ary = array('ok'=>'redirect_reboot()');
	$card_name=$gwords['10gbe'].$num;
	if (serialize($tengb_post_array)!=serialize($tengb_db_array) ){
		$strExec="/img/bin/logevent/event 997 423 info \"\" \"".$card_name."\" \"".$_POST['_ip']."\" \"".$_POST['_netmask']."\"";
		shell_exec($strExec);
	}
	
	if($dhcp_post_enable=="1"){
	  if (serialize($dhcp_post_array)!=serialize($dhcp_db_array)){
      $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='nic1_dns'\"";
      $dns=shell_exec($strExec);
			$strExec="/img/bin/logevent/event 997 424 info \"\" \"".$card_name."\" \"ON\" \", Start IP = ".$_POST[_startip]."\" \", End IP = ".$_POST[_endip]."\" \", DNS = ".$dns."\"";
			shell_exec($strExec);
  	}
  }else{
    if ($dhcp_post_enable != $dhcp_db_enable){
			$strExec="/img/bin/logevent/event 997 424 info \"\" \"".$card_name."\" \"OFF\"";
			shell_exec($strExec);
		}
	}	  
	return  MessageBox(true,$title,sprintf($words["10gbe_staticSuccess"],$num),'INFO','OK',$ary);
}else
  return MessageBox(true,$title,$gwords["setting_confirm"]);
?>

