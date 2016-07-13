<?php  
require_once(INCLUDE_ROOT.'info/smbacl.class.php');
//require_once(INCLUDE_ROOT.'db.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'info/acl.class.php'); 
require_once(WEBCONFIG);

 
              
$words = $session->PageCode("acl");
$gwords = $session->PageCode("global");


$_REQUEST["share"]=str_replace("\\\\","\t",$_REQUEST["share"]);
$_REQUEST["share"]=str_replace("\\","",$_REQUEST["share"]);
$_REQUEST["share"]=str_replace("\t","\\",$_REQUEST["share"]);
$share=$_REQUEST["share"];
$path=$_REQUEST["path"];
$md_num=$_REQUEST["md"]; 

$action=$_REQUEST["action"];
$search_type=$_REQUEST["search_type"];
$access=$_REQUEST["access"];
$search_name=$_REQUEST["search_name"];
$checkvalue=$_REQUEST["checkvalue"]; 
//$target_path=escapeshellarg(getSharePath($share,$path,1)); // do check
$target_path="'".getSharePath($share,$path,1)."'"; // do check
$setfacl='/usr/bin/setfacl';
$ad_db="/raid/sys/ad_account.db";
$limit="1000";
//$limit_msg=sprintf($words["display_limit"],$limit);
 
$result = array(); 
 
      
if($md_num!='undefined'){
    if (NAS_DB_KEY == '1')
        $database="/raid".($md_num-1)."/sys/raid.db";
    elseif (NAS_DB_KEY == '2')
        $database="/raid".($md_num)."/sys/smb.db";
    $db = new sqlitedb($database);  
    $fsmode=$db->db_get_single_value('conf',"v","where k='filesystem'"); 
    unset($db);
}else{
    $database=SYSTEM_DB_ROOT.'stackable.db'; 
}
 

//###########################################
//#  get recursive status:
//#  subfolder recurstion's status is following Rootfolder's.
//###########################################
if($path!=''){
	$fary = explode('/',$path);
	$dbname = $fary[1];
	$rootfolder = sqlite_escape_string($fary[3]);
	if (NAS_DB_KEY == '1'){
	  $db = new sqlitedb('/'.$dbname.'/sys/raid.db');
	  $recursive_value=$db->db_get_single_value('folder',"recursive","where share='$rootfolder'");
	}elseif (NAS_DB_KEY == '2'){
	  $db = new sqlitedb('/'.$dbname.'/sys/smb.db');
	  $recursive_value=$db->db_get_single_value('smb_specfd',"recursive","where share='$rootfolder'"); 
	  if ($recursive_value=='')
	    $recursive_value=$db->db_get_single_value('smb_userfd',"recursive","where share='$rootfolder'"); 
	  
	  if (($recursive_value=='') && ($rootfolder=='stackable')){
	    unset($db);
	  $rootfolder=sqlite_escape_string($fary[4]);
	  $db = new sqlitedb('/etc/cfg/stackable.db');
	  $recursive_value=$db->db_get_single_value('stackable',"recursive","where share='$rootfolder'");
	}

    if (($recursive_value == 'no') || ($recursive_value == '0'))
        $recursive_value = 0;
    else
        $recursive_value = 1;
    }
    unset($db);
}

$acl=getACL($share,$path); 
 
    
switch($action){ 
    case 'search':
        $data = acl_search($search_name,$search_type);
        $result = array('data'=>$data);    
        die(json_encode($result));   
    case 'getacl':   
        $access_array = array();    
        if($access!='')        
             $access_array = getAccessGroup($share,$path,$acl);
        $data = init_acl($access_array['in_access'],$limit);
        $result = array('data'=>$data,'access'=>$access_array,'recursive'=>$recursive_value);    
        die(json_encode($result));
    case 'setacl': 
        setACL($checkvalue,$search_type,$setfacl,$target_path,$md_num,$share); 
    case 'sync':
        setSync(); 
        $access_array = array();    
        if($access!='')        
             $access_array = getAccessGroup($share,$path,$acl);
        $data = init_acl($access_array['in_access'],$limit);
        $result = array('data'=>$data,'access'=>$access_array);    
        die(json_encode($result));
    break; 
} 






function setSync(){ 
    global $words;
    $strExec="/bin/ps | grep /img/bin/create_acl_db.sh | grep -v \"grep\""; 
    $ps=shell_exec($strExec);
    if($ps==""){
       shell_exec("/img/bin/create_acl_db.sh"); 
    } 
}
/****************************************************************
  setACL
  @param  string checkvalue  : checkbox value ,like =>106|write^107|write^105|write^108|deny^102|read^
  @param  string search_type 
  @param  string setfacl     : script path
  @param  string target_path : share folder real path
  @return json array
****************************************************************/
function setACL($checkvalue,$search_type,$setfacl,$target_path,$md_num,$share){ 
    global $words,$limit,$webconfig,$fsmode,$database,$ad_db;
    
    $w_ary=array();
    $r_ary=array();
    $d_ary=array();
    $checkvalue_ary = explode("^",$checkvalue);
    
    //deny:
    if($checkvalue_ary[0]){
        $valueid = explode("|",$checkvalue_ary[0]); 
        foreach($valueid as $v){
            if ($v=="")
              continue;

            $values = explode("~",$v); 
            $id = $values[0];
            $mode = $values[1]; 
            array_push($d_ary,$id."\t".$mode);  
        }       
    }
    //readonly:
    if($checkvalue_ary[1]){
        $valueid = explode("|",$checkvalue_ary[1]); 
        foreach($valueid as $v){ 
            if ($v=="")
              continue;

            $values = explode("~",$v); 
            $id = $values[0];
            $mode = $values[1]; 
            array_push($r_ary,$id."\t".$mode);  
        }       
    }
    
    //writable:
    if($checkvalue_ary[2]){
        $valueid = explode("|",$checkvalue_ary[2]); 
        foreach($valueid as $v){
            if ($v=="")
              continue;

            $values = explode("~",$v); 
            $id = $values[0];
            $mode = $values[1]; 
            array_push($w_ary,$id."\t".$mode);   
        }       
    } 
    if(  (count($d_ary)+count($w_ary)+count($r_ary)) > intval($webconfig["acl_limit"]) )
         die(json_encode(MessageBox(true,$words["settingTitle"],$words["aclMaxLimit"],'ERROR'))); 
    
    $deny=addPrefix($d_ary);
    $writable=addPrefix($w_ary);
    $readonly=addPrefix($r_ary); 
    
    /* readonly is r-x, for both file and directory */ 
    $entries=array_merge(getACLEntries($deny,'---'),getACLEntries($writable,'rwx'),getACLEntries($readonly,'r-x'),array(0=>"u::rwx",1=>"g::---",2=>"o::---"));
    /* issue command */
    $param=join($entries,"\n");
    $recursive='';
    
    
    /*****************************************
    **             Recursive                **
    ******************************************/
    if (isset($_REQUEST['recursive']) && $_REQUEST['recursive']!='') {
      $recursive=' -R ';
      $recursizeSQL='1'; 
    }else{
      $recursizeSQL='0'; 
    }  
    $db = new sqlitedb($database);  
    if($fsmode==''){ 
        $db->db_update('stackable',"recursive='$recursizeSQL'","where share='${share}'");
    }else{
        if (NAS_DB_KEY == '1')
            $db->db_update('folder',"recursive='$recursizeSQL'","where share='${share}'");
        else if (NAS_DB_KEY == '2')
        {
            if ($recursizeSQL=='1'){
                $db->db_update('smb_specfd',"recursive='yes'","where share='${share}'");
                $db->db_update('smb_userfd',"recursive='yes'","where share='${share}'");
            }
            else{
                $db->db_update('smb_specfd',"recursive='no'","where share='${share}'");
                $db->db_update('smb_userfd',"recursive='no'","where share='${share}'");
            }
        }
    }
    unset($db);         

    /********************************************
    **       [ZFS] setting ACL command         **
    *********************************************/ 
    if($fsmode=="zfs"){
        $deny_count=count($deny);
        $readonly_count=count($readonly);
        $writable_count=count($writable);
        $deny_member=array();
        $deny_id=array();
        $readonly_member=array();
        $readonly_id=array();
        $writable_member=array();
        $writable_id=array();
        $valid_member=array();
        $valid_id=array(); 
         
        $db = new sqlitedb();  
        $domain=$db->getvar('winad_domain','');  
        unset($db);
        /**********************************************
        **    Get ACL values for Database format     **
        ***********************************************/     
        if($deny_count!="0"){ 
          foreach($deny as $v){
            if($v!=""){ 
              $deny_info=explode("\t",$v);
              $deny_uid=trim($deny_info[0]);
              $deny_mode=trim($deny_info[1]);
              if($deny_mode=="local_user"){
                $strExec="cat /etc/passwd | awk -F':' '/:$deny_uid:/{print $1}'";
                $deny_user=trim(shell_exec($strExec));
                $deny_member[]=trim($deny_user);
                $deny_id[]="LU_".$deny_uid;
                continue;
              }elseif($deny_mode=="local_group"){
                $strExec="cat /etc/group | awk -F':' '/:$deny_uid:/{print $1}'";
                $deny_group=trim(shell_exec($strExec));
                $deny_member[]="@".trim($deny_group);
                $deny_id[]="LG_".$deny_uid;
                continue;
              }elseif(preg_match("/ad_/",$deny_mode)){ 
                $db = new sqlitedb($ad_db);  
                $deny_ad_user=$db->db_get_single_value('acl',"user","where id='$deny_uid'");
                unset($db);
                if($deny_mode=="ad_user"){
                  $deny_member[]="\"${domain}+".trim($deny_ad_user)."\"";
                  $deny_id[]="AU_".$deny_uid;
                }else{
                  $deny_member[]="@\"${domain}+".trim($deny_ad_user)."\"";
                  $deny_id[]="AG_".$deny_uid;
                }
                continue;
              }
            }
          }
          $deny_member=implode(",",$deny_member);
          $deny_id=implode(",",$deny_id);  
        }else{ 
          $deny_member='';
          $deny_id='';   
        } 
        
        if($readonly_count!="0"){
          foreach($readonly as $v){
            if($v!=""){
              $readonly_info=explode("\t",$v);
              $readonly_uid=trim($readonly_info[0]);
              $readonly_mode=trim($readonly_info[1]);
              if($readonly_mode=="local_user"){
                $strExec="cat /etc/passwd | awk -F':' '/:$readonly_uid:/{print $1}'";
                $readonly_user=trim(shell_exec($strExec));
                $readonly_member[]=trim($readonly_user);
                $readonly_id[]="LU_".$readonly_uid;
                $valid_member[]=trim($readonly_user);
                $valid_id[]="LU_".$readonly_uid;
                continue;
              }elseif($readonly_mode=="local_group"){
                $strExec="cat /etc/group | awk -F':' '/:$readonly_uid:/{print $1}'";
                $readonly_group=trim(shell_exec($strExec));
                $readonly_member[]="@".trim($readonly_group);
                $readonly_id[]="LG_".$readonly_uid;
                $valid_member[]="@".trim($readonly_group);
                $valid_id[]="LG_".$readonly_uid;
                continue;
              }elseif(preg_match("/ad_/",$readonly_mode)){ 
                $db = new sqlitedb($ad_db);  
                $readonly_ad_user=$db->db_get_single_value('acl',"user","where id='$readonly_uid'");
                unset($db);
                if($readonly_mode=="ad_user"){
                  $readonly_member[]="\"${domain}+".trim($readonly_ad_user)."\"";
                  $readonly_id[]="AU_".$readonly_uid;
                  $valid_member[]="\"${domain}+".trim($readonly_ad_user)."\"";
                  $valid_id[]="AU_".$readonly_uid;
                }else{
                  $readonly_member[]="@\"${domain}+".trim($readonly_ad_user)."\"";
                  $readonly_id[]="AG_".$readonly_uid;
                  $valid_member[]="@\"${domain}+".trim($readonly_ad_user)."\"";
                  $valid_id[]="AG_".$readonly_uid;
                }
                continue;
              }
            }
          }
          $readonly_member=implode(",",$readonly_member);
          $readonly_id=implode(",",$readonly_id); 
        }else{   
          $readonly_member='';
          $readonly_id=''; 
        }
        
        if($writable_count!="0"){
          foreach($writable as $v){
            if($v!=""){
              $writable_info=explode("\t",$v);
              $writable_uid=trim($writable_info[0]);
              $writable_mode=trim($writable_info[1]);
              if($writable_mode=="local_user"){
                $strExec="cat /etc/passwd | awk -F':' '/:$writable_uid:/{print $1}'";
                $writable_user=trim(shell_exec($strExec));
                $writable_member[]=trim($writable_user);
                $writable_id[]="LU_".$writable_uid;
                $valid_member[]=trim($writable_user);
                $valid_id[]="LU_".$writable_uid;
                continue;
              }elseif($writable_mode=="local_group"){
                $strExec="cat /etc/group | awk -F':' '/:$writable_uid:/{print $1}'";
                $writable_group=trim(shell_exec($strExec));
                $writable_member[]="@".trim($writable_group);
                $writable_id[]="LG_".$writable_uid;
                $valid_member[]="@".trim($writable_group);
                $valid_id[]="LG_".$writable_uid;
                continue;
              }elseif(preg_match("/ad_/",$writable_mode)){
                
                $db = new sqlitedb($ad_db);  
                $writable_ad_user=$db->db_get_single_value('acl',"user","where id='$writable_uid'");
                unset($db);
                if($writable_mode=="ad_user"){
                  $writable_member[]="\"${domain}+".trim($writable_ad_user)."\"";
                  $writable_id[]="AU_".$writable_uid;
                  $valid_member[]="\"${domain}+".trim($writable_ad_user)."\"";
                  $valid_id[]="AU_".$writable_uid;
                }else{
                  $writable_member[]="@\"${domain}+".trim($writable_ad_user)."\"";
                  $writable_id[]="AG_".$writable_uid;
                  $valid_member[]="@\"${domain}+".trim($writable_ad_user)."\"";
                  $valid_id[]="AG_".$writable_uid;
                }
                continue;
              }
            }
          }
          $writable_member=implode(",",$writable_member);
          $writable_id=implode(",",$writable_id); 
        }else{
          $writable_member='';
          $writable_id=''; 
        } 
        
        
        /*************************************************
        **               Update DataBase                **
        **************************************************/      
        $valid_count=count($valid_member);
        $valid_member=implode(",",$valid_member);
        $valid_id=implode(",",$valid_id);
        $db = new sqlitedb($database);   
        if($valid_count=="0"){
          $db->db_update('folder',"valid_users='root'","where share='${share}'"); 
        }else{
          $db->db_update('folder',"valid_users='${valid_member}',valid_id='${valid_id}'","where share='${share}'");  
        }  
        $db->db_update('folder',"invalid_users='${deny_member}',invalid_id='${deny_id}'","where share='${share}'");
        $db->db_update('folder',"read_list='${readonly_member}',read_list_id='${readonly_id}'","where share='${share}'");
        $db->db_update('folder',"write_list='${writable_member}',write_list_id='${writable_id}'","where share='${share}'"); 
        unset($db);
        
        shell_exec("/img/bin/rc/rc.samba assemble > /dev/null 2>&1");
        
        
    /********************************************
    **       [EXT3/XFS/EXT4] setting ACL command         **
    *********************************************/ 
    }else{    
      $cmd1="$setfacl $recursive -P -b $target_path";   //remove all 
      $cmd2="$setfacl $recursive -P -M- $target_path";  //set new
      $cmd= "$cmd1 ; $cmd2";
      require_once(INCLUDE_ROOT.'proc.class.php');
      proc_run($cmd,$param);

      // change folder's owner, to fix bug 5822
      $cmd= "chown nobody:users $target_path";
      proc_run($cmd,$param);

      $param = str_replace("o::r--","o::rw-",$param);
      $cmd3="$setfacl $recursive -P -k $target_path";
      $cmd4="$setfacl $recursive -P -d -M- $target_path";	
      $cmd= "$cmd3 ; $cmd4"; 
      proc_run($cmd,$param); 
      /*Leon 2005/01/18 fixed bug 1066 START*/
      $req = shell_exec("$setfacl -d -R -P -m other::rw- $target_path");   
      /*END */ 
    }  

    // Reload WebDAV Service if is enabled
    webdav_reload();

    /* output result dialog */
    $result=0; // pretend to success
    if ($result==0){ 
      shell_exec("/img/bin/logevent/event 109 $share &");
      $ary = array('ok'=>'onLoad_acl_apply()');
      $result=MessageBox(true,$words["settingTitle"],$words["aclSuccess"],'INFO','OK',$ary); 
    }else{
      $result=MessageBox(true,$words["settingTitle"],$words["aclError"],'ERROR'); 
    }  
    die(json_encode($result)); 
}


/****************************************************************
  getAccessGroup
  @param  string share : share name
  @param  string path  : path
  @param  string acl   : acl 
  @return json array
****************************************************************/
function getAccessGroup($share,$path,$acl){ 
    $ary_deny = array();
    $ary_writable = array();
    $ary_readonly = array();
    $value_deny='';
    $value_writable='';
    $value_readonly='';
    $in_access=array();
    foreach (array('deny','writable','readonly') as $s){  
        foreach($acl[$s] as $item){
          $item=addslashes($item);
          $item=explode("\t",$item);
          if ($item[0]=='') continue;	
          $localname = str_replace('@smb','',$item[0]);
          $localname = str_replace('@','',$localname); 
          if($localname=='')continue; 
          $localid = $item[1];
          $mode = $item[2];  
          $ary_list = array('id'=>$localid,'name'=>$localname,'type'=>$s,'mode'=>$mode);
          $in_access[$mode][] = $localid;
          switch($s){
             case 'deny':
                 $value_deny.=$localid.'~'.$mode.'|';
                 array_push($ary_deny,$ary_list);
             break; 
             case 'writable':
                 $value_writable.=$localid.'~'.$mode.'|';
                 array_push($ary_writable,$ary_list);    
             break; 
             case 'readonly':
                 $value_readonly.=$localid.'~'.$mode.'|';
                 array_push($ary_readonly,$ary_list);  
             break; 
          }
       }
    } 

    return  array('deny'=>$ary_deny,'writable'=>$ary_writable,'readonly'=>$ary_readonly,
                  'value_deny'=>$value_deny,'value_writable'=>$value_writable,'value_readonly'=>$value_readonly,
                  'in_access'=>$in_access); 
}


/****************************************************************
  acl_search   
  @param string $search      : search name
  @param string $search_mode : [local_group | local_user | ad_group | ad_user]
  @return json array
****************************************************************/ 
function acl_search($search,$search_mode){ 
  global $acl,$limit,$words,$winad,$ad_db,$webconfig; 
  

  $no_access_tmp = explode("|",$_POST['checkvalue']); 
  $no_access = array();
  foreach($no_access_tmp as $v){
  		$no_access_v = explode("~",$v); 
  	  array_push($no_access,$no_access_v[0]);
  }
  
  
  shell_exec("/img/bin/create_acl_db.sh check_db"); 
  $search=str_replace("*","",$search);  
  if(preg_match("/local/",$search_mode)){   //local_group, local_user
    $user_id_limit_begin = $webconfig["user_id_limit_begin"];
    $group_id_limit_begin = $webconfig["group_id_limit_begin"];
    
    if($search_mode=="local_group"){
      $strExec="/bin/cat /etc/group | sort | awk -F':' '/^$search/{if($3>=$group_id_limit_begin){printf(\"%s,%s\\n\",$1,$3)}}'";
    }else{
      $strExec="/bin/cat /etc/passwd | sort | awk -F':' '/^$search/{if($3>=$user_id_limit_begin){printf(\"%s,%s\\n\",$1,$3)}}'";
    }
    $account=shell_exec($strExec);
    $account=explode("\n",$account); 
  }else{ 
    if($winad["winad_enable"]=="1"){
      $strExec="/usr/bin/sqlite $ad_db \"select user,id from acl where role='$search_mode' and user like '$search%' limit 0,$limit\""; 
      $account=shell_exec($strExec); 
      if($account!=""){
        $account=explode("\n",$account);
      }    
    }else{
      $account="";
    }  
    if(count($account)=="0"){
      if($search_mode=="ad_user"){
        $strExec="/usr/bin/wbinfo --user-info=\"".$search."\" | awk -F':' '{printf(\"%s|%s\",$1,$3)}'";
        $account[]=trim(shell_exec($strExec));
      }else{
        $strExec="/usr/bin/wbinfo --group-info=\"".$search."\" | awk -F':' '{printf(\"%s|%s\",$1,$3)}'";
        $account[]=trim(shell_exec($strExec));
      }
    }
  } 
  $member=array();
  $member_tmp=array(); 
  foreach($account as $v){
    if($v!=""){
      if(preg_match("/local/",$search_mode)){
        $account_arr=explode(",",$v);
      }else{
        $account_arr=explode("|",$v);
      }
      if($search_mode=="local_group"){
        $length=strlen($account_arr[0]);
        $member_tmp["name"]=$account_arr[0];
      }else{
        $member_tmp["name"]=$account_arr[0];
      }
      $member_tmp["id"]=$account_arr[1];
      $member[]=$member_tmp;
      
      $db = new sqlitedb($ad_db,'acl');  
      $db_ret=$db->db_get_folder_info('acl',"*","where user='".$member_tmp["name"]."' and id='".$member_tmp["id"]."'");
      unset($db);
      if($db_ret==0){
          $db = new sqlitedb($ad_db,'acl');  
          $db->db_set("user,id,role","'".$member_tmp["name"]."','".$member_tmp["id"]."','$search_mode'");
          unset($db);
      } 
    }
  }
 
  if(count($member)=="0"){
    if($search_mode=="local_user" || $search_mode=="ad_user"){  
      die(json_encode(array('error'=>1,'errormsg'=>$words["user_not_find"])));
    }else{ 
      die(json_encode(array('error'=>1,'errormsg'=>$words["group_not_find"]))); 
    }
  } 
  if(count($member)>$limit){
      $alert_msg=sprintf($words["overflow"],$limit); 
      die(json_encode(array('error'=>1,'errormsg'=>$words["alert_msg"])));  
  }
  $result = array();
  for($i=0;$i<count($member);$i++){
    if(in_array($member[$i]["id"],$no_access))continue;  
    array_push($result,array('id'=>$member[$i]["id"],'name'=>$member[$i]["name"],'mode'=>$search_mode)); 
  }
  return $result; 
}


/****************************************************************
  init_acl  
  @param array $in_access ,not in array
  @return json array
****************************************************************/ 
function init_acl($in_access,$limit){   
    $data=array();
    $smbacl=new SMBACL();       
    
    // 	local group 
    $groups=$smbacl->getLocalGroups($limit);
    $count1=count($groups);
    $limit1=$limit-$count1; 
         
    // 	local user 
    if($count1>="0"){
    	$users=$smbacl->getLocalUsers();
    	$count2=count($users);
    	$limit2=$limit-$count1-$count2;
    } 
     
    // AD groups 
    if($count2>="0"){
      $ad_groups = $smbacl->getADGroups($limit2);
      $count3=count($ad_groups);
      $limit3=$limit-$count1-$count2-$count3;
    } 
     
    // AD users 
    if($count3>="0"){
    	$ad_users=$smbacl->getADUsers($limit3);
    }

    //write local group to javascript variable
    foreach ($groups as $group_name => $group_info){
      if(in_array($group_info["id"],$in_access['local_group'])) continue;
      if ($group_name=='admingroup') continue;
      if (substr($group_name,0,3)=='smb') $group_name=substr($group_name,3);
      $group=addslashes($group_name);
      array_push($data,array('id'=>$group_info["id"],'name'=>$group_name,'mode'=>'local_group'));  
    }
     
    //write local user to javascript variable
    foreach ($users as $s){
      if(in_array($s['id'],$in_access['local_user'])) continue;
      if ($s['name']=='admin') continue;
      $s['name']=addslashes($s['name']);
      array_push($data,array('id'=>$s['id'],'name'=>$s['name'],'mode'=>'local_user'));  
    }
    
    //write ad group to javascript variable
    foreach ($ad_groups as $s){
      if(in_array($s['id'],$in_access['ad_group'])) continue;
      if ($s['name']=='admingroup') continue;
      $s['name']=addslashes($s['name']);
      array_push($data,array('id'=>$s['id'],'name'=>$s['name'],'mode'=>'ad_group'));   
    }
    
    //write ad user to javascript variable
    foreach ($ad_users as $s){
      if(in_array($s['id'],$in_access['ad_user'])) continue;
      if ($s['name']=='admin') continue;
      $s['name']=addslashes($s['name']);
      array_push($data,array('id'=>$s['id'],'name'=>$s['name'],'mode'=>'ad_user'));   
    } 
   return $data;
}


/****************************************************************
  getACLEntries 
  @param  string names 
  @param  string perm 
  @return array
****************************************************************/
function getACLEntries($names,$perm){
  $entries=array();
  if (!$names) return $entries;
  foreach($names as $d){
    $role='u';
    $tmp = explode("\t",$d); 
    if ($tmp[1]=='local_group' || $tmp[1]=='ad_group'){
      $role='g';
    }
    array_push($entries,"$role:$tmp[0]:$perm");
  } 
  return $entries;
}

/****************************************************************
  addPrefix 
  @param  array a 
  @return array
****************************************************************/
function addPrefix($a){
    $c=array();
    foreach($a as $b){
      $tmp = explode("\t",$b); 
      array_push($c,$tmp[0]."\t".$tmp[1]); 
    }
    return $c;
}

/****************************************************************
  encode_name 
  @param  string $v 
  @return string
****************************************************************/
function encode_name($v){
  $v=str_replace("!","!!excl!!",$v);
  $v=str_replace("+","!!plus!!",$v);
  $v=str_replace("\\","!!backslash!!",$v);
  $v=str_replace("|","!!pipe!!",$v);
  $v=str_replace("~","!!tilde!!",$v);
  $v=str_replace("#","!!hash!!",$v);
  $v=str_replace("&","!!amp!!",$v);
  return $v;
}

function webdav_reload(){
  //========== Get WebDAV DB setting ==========
  $db=new sqlitedb();
  $webdav_enable=$db->getvar("webdav_enable","1");
  $webdav_ssl_enable=$db->getvar("webdav_ssl_enable","1");
  //========== Judge WebDAV Server is enable ? ==========
  if ( ($webdav_enable=='1') || ($webdav_ssl_enable=='1') ){
    shell_exec("/img/bin/rc/rc.webdav reload > /dev/null 2>&1 &");
  }
}

?>


