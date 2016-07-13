<?php 


function initWebVar($varname) {
    if (isset($_REQUEST[$varname])) {
         return($_REQUEST[$varname]);
     } else {
         return('');
     }
}

/*
* return current page name , example: snmp/ups/....
* @return string
*/
function getCurrentPage(){
	$page = explode("/",$_SERVER['PHP_SELF']);
	$currentpage = substr(array_pop($page), 0, -4); 
	return $currentpage;
}
/*
* MessageBox function  for generating different styles of message boxes.  
* @param bool $show - true/false
* @param string $topic - title
* @param string $message - message
* @param string $icon - INFO/ERROR/QUESTION/WARNING  default:INFO
* @param string $button - OK/CANCEL/OKCANCEL/YESNO/YESNOCANCEL  default:OK 
* @param array $fn - array of function name 
* @param bool $prompt - true/false default:false
* @return array
*/
function MessageBox($show,$topic,$message,$icon='INFO',$button='OK',$fn,$prompt=false){
  if(is_array($fn))$fn = array_change_key_case($fn,CASE_LOWER);
  if(!$button)$button = 'OK';
  if(!$icon)$icon = 'INFO';
  $button = strtoupper($button);
  $icon = strtoupper($icon);
  
  return array('show'=>$show,
               'topic'=>$topic,
               'message'=>$message,
               'icon'=>$icon,
               'button'=>$button,
               'fn'=>$fn,
               'prompt'=>$prompt);
}

/*
* Progress Bar function  for generating different styles of message boxes.  
* @param bool $show - true/false
* @param string $topic - title
* @param string $message - message
* @param string $interval -   default:1
* @param string $duration -   default:60
* @param string $ifshutdown -   default:0
* @param string $button - OK/CANCEL/OKCANCEL/YESNO/YESNOCANCEL  default:OK 
* @param array $fn - array of function name 
* @return array
*/
function ProgressBar($show,$topic,$message,$icon='ProgressBar',$interval=1,$duration=60,$button='OK',$fn, $ifshutdown=0){
  if(is_array($fn))$fn = array_change_key_case($fn,CASE_LOWER);
  if(!$interval)$interval = 1;
  if(!$duration)$duration = 60;
  if(!$button)$button = 'OK';
  if(!$ifshutdown)$ifshutdown = 0;
  $icon='ProgressBar';
  $button = strtoupper($button);
  
  return array('show'=>$show,
               'topic'=>$topic,
               'message'=>$message,
               'icon'=>$icon,
               'interval'=>$interval,
               'duration'=>$duration,
               'button'=>$button,
               'fn'=>$fn,
               'ifshutdown'=>$ifshutdown);
}

/*
* smbUserModify   
* @param string $username 
* @param string $action - delete | new | modify 
* @param string $pwd   
*/
function smbUserModify($username,$action,$pwd=""){
        $cmd = "/usr/bin/smbpasswd";
        if($action == "delete"){
                $cmd .= " -x $username";
        }
        elseif($action == "new"){
                $cmd .= " -s -a $username <<END\n$pwd\n$pwd\nEND";
        }
        elseif($action == "modify"){
                $cmd .= " -s $username <<END\n$pwd\n$pwd\nEND";
        }
        else{
                return false;
        }
        shell_exec($cmd);
}

/*
* joinMember   
* @param string $groupname 
* @param string $members_list 
* @param string batch|group
*/
function joinMember($group_name,$member_list,$type='batch'){
   if (NAS_DB_KEY == 1){
      $global_groupname="smb$group_name";
   }else{
      $global_groupname=$group_name; 
   } 
   
  $group_exist=posix_getgrnam($global_groupname); 
  if($group_exist!=false || $type!='batch'){
  
  //$group_exist=shell_exec("/bin/cat /etc/group | grep $global_groupname"); 
  //if($group_exist!="" || $type!='batch'){
    $source_group=file("/etc/group");
    $group_info = array();
    for($i=0;$i<count($source_group);$i++){
      $tmp_group=explode(":",trim($source_group[$i]));
      if(count($tmp_group)==3){
        $tmp_group[]="";
      }
      $group_info[]=$tmp_group;
    }   
    for($i=0;$i<count($group_info);$i++){   
    	 if($global_groupname==$group_info[$i][0]){
    	    if($type=='batch'){
              $tmp_new_member=explode(",",$member_list);
              if($group_info[$i][3]!=""){
                $tmp_source_member=explode(",",$group_info[$i][3]);
                $tmp_member_list=array_merge($tmp_source_member,$tmp_new_member);
              }else{
                $tmp_member_list=$tmp_new_member;
              }
              $tmp_member_list=array_unique($tmp_member_list);
              $tmp_member_list=implode(",",$tmp_member_list);
              $group_info[$i][3]=$tmp_member_list;
            }else{
              $member_list = str_replace(" ",",",$member_list);
              $member_list = substr($member_list,0,-1);
              $group_info[$i][3]=$member_list;
            }
            break;
        }  
    }
    for($i=0;$i<count($group_info);$i++){
      $group_info[$i]=str_replace("\n","",implode(":",$group_info[$i]))."\n";
    }
    $group_info=implode("",$group_info);
    $fd=fopen("/etc/group","wb");
    fwrite($fd,$group_info);
    fclose($fd);
  }else{
    if (NAS_DB_KEY == 1){
        shell_exec("/usr/sbin/addgroup $global_groupname $member_list");
    }else{
        $tmp_member_list=explode(",",$member_list);
        for($i=0;$i<count($tmp_member_list);$i++){
                shell_exec("/usr/sbin/addgroup $global_groupname");
                shell_exec("/usr/sbin/usermod -a -G $global_groupname $tmp_member_list[$i]");
        }
    }
  }
} 

function joinGroup($username,$members_list){
	//�Ngroup�H\n�����j�A���@�Ӱ}�C
    $source_groups = file("/etc/group");
	
	$group_info = array();

	//�H:�����j�A�Ngroup�ݩʭȤ��}�A���@�Ӱ}�C
	for ($i=0;$i<count($source_groups);$i++){
		$tmp_group = explode(":",trim($source_groups[$i]));
		if(count($tmp_group)==3)//�ª���/etc/group���Asmbusers�������H:�����A�G�[�J���P�_
			$tmp_group[] = '';
		$group_info[] = $tmp_group;
	}
	

	//�H,�����j�A�Nmember user�ݩʭȤ��}�A���@�Ӱ}�C
	for ($i=0;$i<count($group_info);$i++){
		if(trim($group_info[$i][3])!=''){
			$group_info[$i][3] = explode(",",$group_info[$i][3]);
			for ($j=0;$j<count($group_info[$i][3]);$j++){
				if($group_info[$i][3][$j]==$username){
					unset($group_info[$i][3][$j]);
				}
			}
		}
		else{
			$group_info[$i][3] = array();
		}
	} 
	//�N�ҳ]�wusername������member������
	for ($i=0;$i<count($group_info);$i++){
		//�Ǧ^�}�C���A�W�٬ۦP��index�A���ϥ�array_search�O�]���Aarray_search�|�L�k����Oindex = 0��false
		//�]��0 == false
		$is_member = -1;
		for ($j=0;$j<count($group_info[$i][3]);$j++){
			if($username==$group_info[$i][3][$j]){
				$is_member = $j;
				break;
			}
		}
		if($is_member != -1)
			unset($group_info[$i][3][$is_member]);
	}

	//�Nusername�[�J�ҳ]�w��group��
	$members_list = explode(" ",$members_list);
	for ($i=0;$i<count($members_list);$i++){
		for ($j=0;$j<count($group_info);$j++){
		    if (NAS_DB_KEY == 1)
		    {
    			if("smb".$members_list[$i]==$group_info[$j][0]){
                    $group_info[$j][3][] = $username;
                }
            }
            else
		    {
    			if($members_list[$i]==$group_info[$j][0]){
                    $group_info[$j][3][] = $username;
                }
            }
		}
	}

	//�X�ְ}�C�A�Ngroup file�٭�A�C����ݥ����]�tnewline�r��
	for ($i=0;$i<count($group_info);$i++){
		$group_info[$i][3] = str_replace("\n","",implode(",",$group_info[$i][3]));
		$group_info[$i] = str_replace("\n","",implode(":",$group_info[$i]))."\n";
	}
	$group_info = implode("",$group_info);

	//�g�^group file
    $fd = fopen("/etc/group","wb");
	
	fwrite($fd,$group_info);
	fclose($fd);
}
/*
* Check fsck_flag (/etc/fsck_flag)   
* @return true:have fsck_flag , false:none
*/
function check_fsck_flag(){
	$fsck_flag=(file_exists("/etc/fsck_flag"))?trim(shell_exec('cat /etc/fsck_flag')):"0";
	if($fsck_flag=="1" && is_file("/etc/fsck_flag")){
		return true;
	}else{
		return false;
	}
}

/*
* Check status_flag (/var/tmp/raidlock /var/tmp/raidmd_num/rss)   
* @return true:have lock_falg , false:none
*/
function check_status_flag(){
	require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
	$raid=new RAIDINFO();
	$raid->setmdselect(0);
	$md_array=$raid->getMdArray();
	$now_status=0;
	$locks=file("/var/tmp/raidlock");

	foreach($md_array as $num){
		if(NAS_DB_KEY==1)
			$status=file("/var/tmp/raid".($num-1)."/rss");
		else
			$status=file("/var/tmp/raid".($num)."/rss");
		if(!preg_match("/Healthy|Degraded/",$status[0])){
			$now_status=1;
			break;
		}
	}  
	return trim($locks[0])|$now_status;
}

function check_raid_status($md){
	if(NAS_DB_KEY==1)
		$status=file("/var/tmp/raid".($md-1)."/rss");
	else
		$status=file("/var/tmp/raid".($md)."/rss");

	if(preg_match("/Healthy/",$status[0])){
		$now_status=0;
	}else{
		$now_status=1;
	}

	return $now_status;
}


/**
* getTreeValue
* @param string $treeword: tree wording
* @return tree value if found
*/
function getTreeValue($treeword){
	global $session;
	$lang_db= "/img/language/language.db";
	$db = new sqlitedb($lang_db);  
	$row = $db->db_get_folder_info($session->lang,'value','where value like "tree_%" and msg="'.$treeword.'"'); 
	if($row[0]['value']!=''){
		$tree_value=$row[0]['value'];
	}else{
		$tree_value='';
	}  
   	$db->db_close();
	return $tree_value;

}

/**
* findTreeTxt
* @param string $needle
* @param string $haystack
* @param string $txt
* @return wording if find.
*/
function findTreeTxt($needle, $haystack,$txt=''){
	$path=array();  
	global $treetxt; 
	foreach($haystack as $id => $val){ 
		if(strstr($val,'tengb')){
			$val='tengb';
			$txt = substr($txt,0,-1);
		}
		if($val === $needle) {
			$path[]=$id;  
			$treetxt=$txt;
			break;
			//this breaks out of loop when it finds needle 
		} else if(is_array($val)){ 
			$found=findTreeTxt($needle, $val,$val['treename']); 
			if(count($found)>0){
				$path[$id]=$found; 
				break;
				// this breaks out of loop when recursive call found needle
			}
		}
	}
	return $treetxt;
}
 

/**
* getModuleInfo
* @param string type : shortcut/treemenu
* @param string $name: shortcut name
* @return tree value if found
*/
function getModuleInfo($type,$name=''){
	require_once(INCLUDE_ROOT.'sqlitedb.class.php');
	$module_db= MODULE_ROOT."cfg/module.db";
	if(file_exists($module_db)){
    	$db = new sqlitedb($module_db,'module'); 
	$tree_module_sys_items = array();
	$tree_module_user_items = array();

	$mod_rs = "select * from module";
	if($name!='')
		$mod_rs.="  where name='$name'";
	$db->runPrepare($mod_rs); 
	$i = 0;   
	while ($mod_info = $db->runNext()){
		list($mod_name,$mod_version,$mod_description,$mod_enable,$mod_updateurl,$mod_icon,$mod_mode,$mod_homepage,$mod_ui) = $mod_info;  
		if ($mod_enable=='Yes') { 
			$moduletype = 'user';
			if($mod_mode=='System')
				$moduletype = 'sys';  

			$in_menu='0';
			$menu_footer=array("Status","Storage","Network","Accounts","System","Nomenu");
			foreach($menu_footer as $v){
				if($v!=""){
					if($v==$mod_homepage){
						$in_menu='1';
						break;
					}
				} 
			}
			if($mod_ui=='Thecus' || $in_menu=='1'){
				$modulelink = ''; 
				$shortcutlink= 'getform.html?Module='.$name; 
			}else{
				$modulelink = $mod_homepage; 
				$shortcutlink="/modules/$name/$mod_homepage"; 
			}
			$id=$mod_name.'|'.$modulelink;
			if ($moduletype=='sys'){ //thecus 
				array_push($tree_module_sys_items,array('txt'=>$mod_name,'id'=>$id,'moduletype'=>$moduletype));
			}else{
				array_push($tree_module_user_items,array('txt'=>$mod_name,'id'=>$id,'moduletype'=>$moduletype));
			} 
			$shortcut_ary = array(	'mode'=>$mod_mode,
						'modulelink'=>$shortcutlink);
		}
		$i++;
	}
	}
	switch($type){
		case 'shortcut':
   			return $shortcut_ary;
		break;
		case 'treemenu': 
   			return array('modsys'=>$tree_module_sys_items,'moduser'=>$tree_module_user_items);
		break;
	} 
}

 
?>
