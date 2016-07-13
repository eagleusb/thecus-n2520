<?
    /*iap, 2005.1.7 */
    /* parse the result of getacl */
	$shareroot=$share_root;
    $getfacl='/usr/bin/getfacl';
    $delimeter='+' ; // separater of ads server and user in smb.conf
    function getACL($share,$rpath){
//        $path=escapeshellarg(getSharePath($share,$rpath,1)); // do check
        $path="'".getSharePath($share,$rpath,1)."'"; // do check
        //echo "share = $share<br>";
        //echo "path = $path<br>";
        global $getfacl;
        $cmd="$getfacl -p --numeric $path|grep -v '^default:'";
        $lines=explode("\n",trim(shell_exec($cmd)));
        $acl=parseACL($lines);
        //echo "<pre>";
        //print_r($acl);
        return $acl;
    }
    function char2ord($s){
    }

	function Oct2Char($s){
  		return chr(octdec($s[0]));
	}
	
	function parseACL($lines){
        	global $fsmode;
        	switch ($fsmode){
        		case "zfs":
        			return parseZFS_acl();
        			break;
        		case "ext3":
        		default:
        			return parseEXT3_ACL($lines);
        			break;	
        	}
        	exit;
	}
	
	function getACLNAME($role,$guid){
		if($role=='local_user'){
			  $strExec="/bin/cat /etc/passwd | grep ':{$guid}' | cut -d ':' -f1";
		}elseif($role=='ad_user'){
			  $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user from acl where id='$guid' and role='ad_user'\"";
		}elseif($role=='local_group'){
			  $strExec="/bin/cat /etc/group | grep ':{$guid}' | cut -d ':' -f1";
		}elseif($role=='ad_group'){
			  $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user from acl where id='$guid' and role='ad_group'\"";
		}
		return trim(shell_exec($strExec));;
	}
	
	function parseZFS_ACL(){
		global $md_num,$share;
		include_once("/var/www/html/inc/db.class.php");
		$db_tool=new db_tool2();
		$database="/raid".($md_num-1)."/sys/raid.db";
        	//echo "md = $md_num<br>";
        	//echo "share = $share<br>";
		$entries=array();
		$entries['deny']=array();
		$entries['readonly']=array();
		$entries['writable']=array();
		$db_tool->db_connect($database);
		$db_info=$db_tool->db_get_folder_info("folder","invalid_id,read_list_id,write_list_id","where share='${share}'");
		$db_tool->db_close();
		$deny_list=explode(",",$db_info[0]["invalid_id"]);
		$readonly_list=explode(",",$db_info[0]["read_list_id"]);
		$writable_list=explode(",",$db_info[0]["write_list_id"]);
		//echo "<pre>";
		//print_r($deny_list);
		//print_r($readonly_list);
		//print_r($writable_list);
		$permission=array("deny","readonly","writable");
		foreach($permission as $p){
		  foreach(${$p."_list"} as $v){
	     	    if(preg_match("/LU_/",$v)){
		      $role="local_user";
		      $uid=substr($v,3,strlen($v)-3);
		      $strExec="cat /etc/passwd | awk -F':' '/:${uid}:/{print $1}'";
		      $name=trim(shell_exec($strExec));
		      $entries[$p][]="$name\t$uid\t$role";
		    }elseif(preg_match("/LG_/",$v)){
		      $role="local_group";
		      $gid=substr($v,3,strlen($v)-3);
		      $strExec="cat /etc/group | awk -F':' '/:${gid}:/{print $1}'";
		      $group=trim(shell_exec($strExec));
		      $entries[$p][]="@${group}\t${gid}\t${role}";
		    }elseif(preg_match("/AU_/",$v)){
		      $role="ad_user";
		      $uid=substr($v,3,strlen($v)-3);
		      $db_tool->db_connect("/raid/sys/ad_account.db");
		      $name=$db_tool->db_get_single_value("acl","user","where id='${uid}'");
		      $db_tool->db_close();
		      $entries[$p][]="${name}\t${uid}\t${role}";
		    }elseif(preg_match("/AG_/",$v)){
		      $role="ad_group";
		      $gid=substr($v,3,strlen($v)-3);
		      $db_tool->db_connect("/raid/sys/ad_account.db");
		      $group=$db_tool->db_get_single_value("acl","user","where id='${gid}'");
		      $db_tool->db_close();
		      $entries[$p][]="${group}\t${gid}\t${role}";
		    }
		  }
		}
		return $entries;
	}
	
	function parseEXT3_ACL($lines){
		$winad_enable=trim(shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='winad_enable'\""));
		$ldap_enable=trim(shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='ldap_enabled'\""));
		$entries=array();
		$entries['deny']=array();
		$entries['writable']=array();
		$entries['readonly']=array();
		/* skip first line */
		$line=array_shift($lines);
		$line=array_shift($lines);
		$owner=trim(substr($line,9));
		$line=array_shift($lines);
		$group=trim(substr($line,9));
		foreach ($lines as $line){
			$line=trim($line);
			if (!$line) continue;
			$line=preg_replace_callback("/\\\\0(\d\d)/",Oct2Char,$line);
			$line=preg_replace_callback("/\\\\(\d\d\d)/",Oct2Char,$line);
			$p=strpos($line,'#effective:'); // length=11
			if ($p !== false){
				$effective=substr($line,$p+11,3);
				$line=trim(substr($line,0,$p));
			}
			$default=false;
			$fields=explode(':',$line);
			list($role,$guid,$perm)=$fields;
			$ldap_user=0;
			$ldap_group=0;
			if($role=='user'){
				if($guid>=20000 && ($winad_enable=="1" || $ldap_enable=="1")){
				  $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user from acl where id='$guid' and role='ad_user'\"";
				}else{
				  if ($ldap_enable=="1"){
				      $strExec="/bin/cat /etc/passwd | awk -F':' '/:{$guid}/&&!/^{$guid}:/{print \$1}'";
				      $name=trim(shell_exec($strExec));
				      if ($name==''){
				          $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user from acl where id='$guid' and role='ad_user'\"";
				          $ldap_user=1;
				      }else{
				          $ldap_user=0;
				      }
				  }else{
  				      $strExec="/bin/cat /etc/passwd | awk -F':' '/:{$guid}/&&!/^{$guid}:/{print \$1}'";
  				  }
				}
				$name=trim(shell_exec($strExec));
				//$name = trim(shell_exec("/usr/bin/getent passwd|cut -d ':' -f1,3|grep ':{$guid}'|cut -d ':' -f1"));
				//echo $name."<br>";
			}elseif($role=='group'){
				if($guid>=20000 && ($winad_enable=="1" || $ldap_enable=="1")){
				  $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user from acl where id='$guid' and role='ad_group'\"";
				}else{
				  if ($ldap_enable=="1"){
				      $strExec="/bin/cat /etc/group | grep ':{$guid}:' | cut -d ':' -f1";
				      $name=trim(shell_exec($strExec));
				      if ($name==''){
				          $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user from acl where id='$guid' and role='ad_group'\"";
				          $ldap_group=1;
 				      }else{
				          $ldap_group=0;
				      }
				  }else{
 				      $strExec="/bin/cat /etc/group | grep ':{$guid}:' | cut -d ':' -f1";
 				  }
				}
				$name=trim(shell_exec($strExec));
				//$name = trim(shell_exec("/usr/bin/getent group|cut -d ':' -f1,3|grep ':{$guid}'|cut -d ':' -f1"));
			}
			$acl='';
			if ($role=='user' && $guid==''){
				$entries['owner']=array($owner,$perm);
				continue;
			}
			elseif ($role=='group' && $guid==''){
				$entries['group']=array($group,$perm);
				continue;
			}
			elseif ($role=='mask'){
				$entries['mask']=$perm;
				continue;
			}
			elseif ($role=='other'){
				$entries['other']=$perm;
				continue;
			}
			$acl=$perm;
			if ($perm=='---') $acl='deny';
			elseif (strpos($perm,'w')!== false) $acl='writable';
			elseif (strpos($perm,'r')!== false) $acl='readonly';
			if ($role=='group') {
				$name='@'.$name;
			}
			//Leon 2005/10/18 fixed user/group name UpperCase issue
			$is_local_user = trim(shell_exec("grep \"^{$name}:\" /etc/passwd")); 
			$is_local_group = trim(shell_exec("grep \"^{$name}:\" /etc/group"));
			//if($guid >= 20000) 
		  		//$name = strtolower($name);
			$name = $name."\t".$guid."\t";

			if($role=='user'){
				$name .= ($guid >= 20000 || $ldap_user=="1") ? 'ad_user' : 'local_user';
			}
			elseif($role=='group'){
				$name .= ($guid >= 20000 || $ldap_group=="1") ? 'ad_group' : 'local_group';
			}
			if (!isset($entries[$acl])) $entries[$acl]=array();
			//echo "$name<BR>";
			array_push($entries[$acl],$name);
		}
		//echo "<pre>";
		//print_r($entries);
		return $entries;
	}
	function getSharePath($share,$path='/',$check=1){
		global $shareroot;
		if (!$path) $path='/';
		/*if (!$share || !$path ){
			echo "<center><FONT COLOR=#FF0000>Given Parameters are not defined <BR> Please click on the Link</FONT></center>";
		}
		*/
		//$shareroot="/raid/stackable/";
		//$share="polson";
		$path_parts = pathinfo(__FILE__);
		$mypath=$path_parts['dirname'];
	//	require_once(realpath("$mypath/../smbconf.class.php"));
	//	$SmbConf=new SmbConf();
	//	$SmbConf->setShare($share);
//		$target_path=realpath($SmbConf->getPath().'/'.$path);
//		$target_path=realpath("$path/$share");
		$target_path=realpath("$path");
		//echo "target=$target_path<br>";
		if (!$check) return $target_path;
		//echo $target_path."_".$shareroot;
		if (substr($target_path,0,strlen($shareroot))!=$shareroot){
			/* user trying to access path which is out of shareroot */
			echo "<center><FONT COLOR=#FF0000>Given Parameters are not defined <BR> Please click on the Link</FONT></center>";
			exit;
		}
		if (!file_exists($target_path)){
			echo "<center><FONT COLOR=#FF0000>$target_path,Given Parameters are not defined <BR> Please click on the Link</FONT></center>";
			exit;
		}
		return $target_path;
	}
?>
