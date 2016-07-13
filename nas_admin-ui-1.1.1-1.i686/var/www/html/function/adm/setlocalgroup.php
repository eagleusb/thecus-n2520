<?php  
require_once(INCLUDE_ROOT.'info/smbacl.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(WEBCONFIG);

$words = $session->PageCode("localgroup");
$gwords = $session->PageCode("global");

$action = $_POST['action'];
$groupname = $_POST['groupname'];
$groupid = $_POST['groupid'];
$username = $_POST['username'];

// if success then click [ok] doing...
$return_ary = array('ok'=>'onLoadStore()');


switch($action){
   /***********************************************************
                           add localgroup 
   ************************************************************/
   case 'add': 
        // check field 
        if(!$validate->check_groupname($groupname))
              return  MessageBox(true,$gwords['error'],$words['group_error'],'ERROR');
        if($groupid < $webconfig["group_id_limit_begin"] || $groupid >$webconfig["group_id_limit_end"] || (!$validate->numeric(5,'max',$groupid)))
              return  MessageBox(true,$gwords['error'],$words['group_id_error'],'ERROR');
	
        // check group exists 
    	$smbacl=new SMBACL();
    	$groups=$smbacl->getLocalGroups(1);
    	foreach ($groups as $group_name => $group_info){
    	    if($group_name==$grouname)
    	        return  MessageBox(true,$gwords['error'],$words['group_exist'],'ERROR'); 
	    }  
	    
	    
        // check limit
      	if (NAS_DB_KEY==1)
          $strExec="cat /etc/group | awk -F':' '{if($3>=102){print $3}}' | wc -l";
        elseif (NAS_DB_KEY==2)
          $strExec="cat /etc/group | awk -F':' '{if($3>=100){print $3}}' | wc -l";
        
      	$now_group_count=trim(shell_exec($strExec));
      	if($now_group_count >= $webconfig["group_limit"]){ 
      	   return MessageBox(true,$gwords['error'],$words['group_limit'],'ERROR');
      	}
      	
        //add
        if (NAS_DB_KEY==1)
            $strExec="/usr/sbin/addgroup -g {$groupid} smb{$groupname}";
      	else
            $strExec="/usr/sbin/addgroup -g {$groupid} {$groupname}";
      	
      	exec($strExec,$out,$ret);
      	if($ret=="0"){
      	  joinMember($groupname,$username,'group');
      	  shell_exec("/img/bin/logevent/event 997 106 info \"\" \"{$groupname}\" &");
      	  return MessageBox(true,$words['group_setting'],$words['group_add_success'],'INFO','OK',$return_ary);  
      	}else{
      	  $msg=sprintf($words["addgroup_failed"],$groupname);
      	  return MessageBox(true,$gwords['error'],$msg,'ERROR');
      	}   
     break;
   case 'update': 
        //return MessageBox(true,$groupname,$username,'ERROR');
        joinMember($groupname,$username,'group');
        return MessageBox(true,$words['group_setting'],$words['group_update_success'],'INFO','OK',$return_ary);  
     break;
   case 'delete': 
          //check special group,like users
          if($groupname=='users')
       	         return MessageBox(true,$gwords['error'],$words['special_group_msg'],'ERROR');
          
          if (NAS_DB_KEY==1)
            shell_exec("/bin/delgroup smb{$groupname}");
          else
            shell_exec("/usr/sbin/groupdel {$groupname}");
          
          shell_exec("/img/bin/logevent/event 997 107 info \"\" \"{$groupname}\" &");
          return MessageBox(true,$words['group_setting'],$words['group_remove_success'],'INFO','OK',$return_ary);  
     break;
}    


?> 
