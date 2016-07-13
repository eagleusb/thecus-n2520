<?php   
require_once(INCLUDE_ROOT.'db.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'foo.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(WEBCONFIG);

$words = $session->PageCode("share");
$gwords = $session->PageCode("global"); 
$mswords = $session->PageCode("modshare");

$action_snapshot = $_POST['action_snapshot'];
$action_share = $_POST['action_share'];
$action_smb = $_POST['action_smb'];
$nfs_action_share = $_POST['nfs_action_share'];
$quota_usage_value= $_POST['quota_usage_value'];


if($action_share!=''){
  $aswords = $session->PageCode("addshare");
  $md_num = $_POST['md_num'];
  if(!empty($md_num)){
    $n_ary = explode(',',$_POST['md_num']);
    if(is_array($n_ary)){
       $md_num = $n_ary[0]; 
    }else{
       $md_num = $_POST['md_num'];
    }
  }
  $share_name = $_POST['_share'];
  $comment=stripslashes($_POST["_comment"]);
  $comment=check_char($comment);
  $sysfolder = $_POST['sysfolder'];
  
  if(empty($share_name) && $sysfolder=='1'){
    return MessageBox(true,$gwords['error'],$aswords['ERROR_SHARENAME_BLANK'],'ERROR');
  }
  if(!$validate->check_sharefolder($share_name) && $action_share != "remove"){
    return MessageBox(true,$gwords['error'],$validate->errmsg,'ERROR');
  }
  if(!$validate->check_sharefolder_desc($comment) && $comment!='' && $action_share != "remove"){
    return MessageBox(true,$gwords['error'],$words['share_desc_limit'],'ERROR');
  }
  
  $browseable = $_POST['_browseable'];
  $guest_only = $_POST['_guest_only'];
  $quota_limit = $_POST['_quota_limit'];
  $_POST["o_share"]=str_replace("\\\\","\t",$_POST["o_share"]);
  $_POST["o_share"]=str_replace("\\","",$_POST["o_share"]);
  $o_share_name=str_replace("\t","\\",$_POST["o_share"]);
  if(empty($share_name))$share_name = $o_share_name;
  $_POST['_share']=$share_name;
  
  if(!$validate->check_quota_limit($quota_limit)){
    return MessageBox(true,$gwords['error'],$validate->errmsg,'ERROR');
  }
  if($quota_usage_value>$quota_limit && $quota_limit>0){
    return MessageBox(true,$gwords['error'],$words['quota_presetup'],'ERROR');
  }
  
  $share_path = $_POST['path'];
  $old_share = $_POST['old_share'];
  
  if (NAS_DB_KEY == '1')
    $path="/raid".($md_num-1).'/data'.$share_path.$share_name;
  elseif (NAS_DB_KEY == '2')
    $path="/raid".($md_num).'/data'.$share_path.$share_name;
      
}else if($nfs_action_share !=''){
  $md_num=$_POST["nfs_md_num"];
  $_POST["nfs_sharename"]=str_replace("\\\\","\t",$_POST["nfs_sharename"]);
  $_POST["nfs_sharename"]=str_replace("\\","",$_POST["nfs_sharename"]);
  $_POST["nfs_sharename"]=str_replace("\t","\\",$_POST["nfs_sharename"]);
  $share_name=$_POST["nfs_sharename"];
  $hostname=$_POST["_hostname"];
  if(!$validate->ip_address_nfs($hostname)){
     $twords = $session->PageCode("network");
     return MessageBox(true,$gwords['error'],$twords['hostname_error'],'ERROR');        
   }
  $privilege=$_POST["_privilege"];
  $rootaccess=$_POST["_rootaccess"];
  $os_support=$_POST["_os_support"];
  $sync=$_POST["_sync_support"];  
}else if($action_snapshot!=''){
  $words = $session->PageCode("snapshot");
  $md_num=$_POST["md_num"];
  $share=$_POST["share"];
  $zfs_pool=$_POST["zfs_pool"];
  $zfs_share=$_POST["zfs_share"];
  $share_date=$_POST["share_date"];  
}else if($action_smb!=''){

  //get post
  $comment=$_POST["_comment"];
  $browseable=$_POST["_browseable"];
  $smbreadonly=$_POST["_smbreadonly"];
  $readonly_visible=$_POST["readonly_visible"];
  $o_browseable=$_POST["o_browseable"];
  $share=$_POST["share"];
  $md=$_POST["md"];


  //check input description
  if(!$validate->check_sharefolder_desc($comment) && $comment!=''){
       return MessageBox(true,$gwords['error'],$words['share_desc_limit'],'ERROR');        
  }

  
  $set = "comment='$comment', browseable='$browseable' ";
  $where=" where share='".$share."'";  
 
  if (NAS_DB_KEY == '1'){
    // update read only  
    if($readonly_visible=='true' && $smbreadonly=='1'){
       $set.=" ,v1='1'";
    }else{
       $set.=" ,v1='0'";
    }
    $raid_db = "/raid".($md-1)."/sys/raid.db";
    $sqlite_cmd="/usr/bin/sqlite";
    $db = new sqlitedb($raid_db);   
    $db_return = $db->db_update("folder",$set,$where); 
  
  }elseif (NAS_DB_KEY == '2'){
    $raid_db = "/raid".$md."/sys/smb.db";
    $sqlite_cmd="sqlite";
    $db = new sqlitedb($raid_db);  
    $folder_exist=$db->db_get_folder_info("smb_specfd","share",$where); 
    $folder_exist=$folder_exist[0][0];

    if($readonly_visible=='true' && $smbreadonly=='1'){
       $set.=" ,readonly='1'";
    }else{
       $set.=" ,readonly='0'";
    }

    if ($folder_exist == ''){
        $db_return = $db->db_update("smb_userfd",$set,$where);   
    }else{
        $db_return = $db->db_update("smb_specfd",$set,$where);   
    }
  } 

  // update log 
  if($browseable != $o_browseable){
    $strExec="$sqlite_cmd $raid_db \"select v from conf where k='raid_name'\"";
    $raid_id=trim(shell_exec($strExec));
    $strExec="/img/bin/logevent/event 997 409 info \"\" '".$share."' \"".$raid_id."\" \"[ Browseable = ".$browseable." ]\"";
    shell_exec($strExec);
  }
  unset($db);

  if(!$db_return){
    return MessageBox(true,$gwords['error'],$mswords['modshareError'],'ERROR');  
  }else{
    shell_exec("/img/bin/rc/rc.samba restart");
    return MessageBox(true,$gwords['success'],$words['smb_success']);  
  } 
}

$sqlite_cmd="/usr/bin/sqlite";
$stack_db="/etc/cfg/stackable.db";
$share_name = uniDecode($share_name, 'utf8');
$share_path = uniDecode($share_path, 'utf8');

if (NAS_DB_KEY == '1'){
  $raid_name="raid".($md_num-1);
  $raid_database="/$raid_name/sys/raid.db";
  $db = new sqlitedb($raid_database);  
  $fsmode=$db->db_get_single_value("conf","v","where k='filesystem'");  
  $zfsname=$db->db_get_single_value("folder","zfsname","where share='$share_name'");
  $o_zfsname=$db->db_get_single_value("folder","zfsname","where share='$o_share_name'"); 
  $nfs_count=$db->runSQL("select count(*) from nfs where share='$share_name' and hostname='$hostname'");
  $nfs_count=$nfs_count[0];
  $nfs_db_list=$db->db_getall("nfs");
  unset($db);
}  
elseif (NAS_DB_KEY == '2'){
  $raid_name="raid".($md_num);  
  $raid_database="/$raid_name/sys/smb.db";
  $db = new sqlitedb($raid_database);  
  $fsmode=$db->getvar('filesystem','');
  unset($db);
  
  $db = new sqlitedb();  
  $nfs_count=$db->runSQL("select count(*) from nfs where share='$share_name' and hostname='$hostname'");
  $nfs_count=$nfs_count[0];
  $nfs_db_list=$db->db_getall("nfs");
  unset($db);
}

        
        
$mkzpool="/usr/bin/zpool";
$mkzfs="/usr/bin/zfs"; 



//###############################################
//#	Share Folder 
//###############################################
switch($action_share){
  case 'add':
    $share_length = shell_exec('sed -nr "/\[[^\n]*\]/p" /etc/samba/smb.conf|wc -l') -1;
    if($share_length >= $webconfig["share_limit"]){
      return MessageBox(true,$gwords['error'],$aswords["addshareLimit"],'ERROR');
    }

    //==========================================
    //	isDuplicate
    //==========================================
    require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
    $raid_class=new RAIDINFO();
    $md_array=$raid_class->getMdArray();
    foreach($md_array as $num){
      if (NAS_DB_KEY == '1')
        $database="/raid".($num-1)."/sys/raid.db";
      elseif (NAS_DB_KEY == '2')
        $database="/raid".($num)."/sys/smb.db";

      $dbs = new sqlitedb($database,'conf');

      if (NAS_DB_KEY == '1'){
        $db_list=$dbs->db_getall("folder");
      }elseif (NAS_DB_KEY == '2'){
        $db_lista=$dbs->db_getall("smb_specfd");
        $db_listb=$dbs->db_getall("smb_userfd");
        if($db_listb != 0){
          $db_list=array_merge($db_lista,$db_listb);
        }else{
          $db_list=$db_lista;
        }
      }
      unset($dbs);

      //get stack folder name
      $conf_db=new sqlitedb();
      $iscsi_is_enabled=$conf_db->db_get_single_value("conf","v","where k='iscsi'");
      unset($conf_db);
      if($iscsi_is_enabled !== NULL){
        $stackdb = new sqlitedb($stack_db);
        $all_stack_share_name=$stackdb->db_get_folder_info("stackable","share","");
        unset($stackdb);
      }

      foreach($db_list as $k=>$list){
        if(strtolower($share_name)==strtolower($list['share'])){
          return MessageBox(true,$gwords['error'],$aswords['ERROR_SHARENAME_DUPLICATE'],'ERROR');
        }
      }
      foreach($all_stack_share_name as $data){
        if($data!=""){
          if(strtolower($share_name)==strtolower($data["share"])){
            return MessageBox(true,$gwords['error'],$aswords['ERROR_SHARENAME_DUPLICATE'],'ERROR');
          }
        }
      }      
    }

    //==========================================
    //	Insert info to db
    //==========================================
    if (NAS_DB_KEY == '1'){
      $columns="share,browseable,guest_only,quota_limit";
      $values="'".$share_name."','yes','".$guest_only."','".$quota_limit."'";
      $dbs = new sqlitedb($raid_database);
      $db_ret=$dbs->db_insert("folder",$columns,$values);
    }elseif (NAS_DB_KEY == '2'){
      $columns="share,browseable,'guest only',path, 'map hidden', recursive";
      $values="'".$share_name."','yes','".$guest_only."','".$share_name."','no','yes'";
      $dbs = new sqlitedb($raid_database);
      $db_ret=$dbs->db_insert("smb_userfd",$columns,$values);
    }


    unset($dbs);
    if(!$db_ret){
      $msg = $aswords["addshareError"]." - [{$share_name}]";
      return MessageBox(true,$gwords['error'],$msg,'ERROR');
    }
    //==========================================
    //	Create folder
    //==========================================
    switch ($fsmode) {
      case "zfs":
        $zfspoolname=sprintf("zfspool%d",$md_num-1);
        $mountpoint=sprintf("/raid%d/data%s",$md_num-1,$share_path.$share_name);
        $strExec="/bin/mkdir \"$mountpoint\"";
        shell_exec($strExec);
        $strExec="/img/bin/zfs_getfreename.sh ${md_num}";
        $freeshare=trim(shell_exec($strExec));
        $zfsitem=sprintf("%s/%s",$zfspoolname,$freeshare);
        if(($quota_limit!="0") && ($quota_limit!="")){
          $strExec=sprintf("$mkzfs create -o mountpoint='%s' -o quota=%sg '%s' > /tmp/zfslog.log 2>&1",$mountpoint,$quota_limit,$zfsitem);
        } else {
          $strExec=sprintf("$mkzfs create -o mountpoint='%s' '%s' > /tmp/zfslog.log 2>&1",$mountpoint,$zfsitem);
        }
        shell_exec($strExec);
        //update zfsname
        $table="folder";
        $set="zfsname='$freeshare'";
        if($guest_only=="no"){
          $set.=",valid_users='root'";
        }
        $where="where share='$share_name'";

        $db = new sqlitedb($raid_database);
        $db->db_update("folder",$set,$where);
        unset($db);

        $strExec="chmod 777 \"$path\" &&";
        $strExec.="chown nobody:smbusers \"$path\"";
        shell_exec($strExec);
        break;
      case "btrfs":
        $strExec="/sbin/btrfsctl -S $share_name /raid".($md_num)."/data/";
        shell_exec($strExec);
        if($quota_limit!="0" && $quota_limit!=""){
          $quota_limit=$quota_limit*1024;
          $strExec="sh -x /img/bin/managefolder.sh -m '".$path."' ".$quota_limit." >/tmp/managefolder.log 2>&1 &";
          shell_exec($strExec);
        }
        $strExec="chmod 774 '$path' &&";

        if (NAS_DB_KEY == '1')
          $strExec.="chown nobody:smbusers '$path'";
        elseif (NAS_DB_KEY == '2')
          $strExec.="chown nobody:users '$path'";

        shell_exec($strExec);
        //##########################################
        //  Set ACL
        //##########################################
        if($guest_only=='yes'){
          $strExec="setfacl -P -m other::rwx ".escapeshellarg($path);
          shell_exec($strExec);
        }else{
          $strExec="chmod 700 ".escapeshellarg($path);
          shell_exec($strExec);
        }
        $strExec="setfacl -P -d -m other::rwx ".escapeshellarg($path);
        shell_exec($strExec);
        //##########################################
        break;
      case "ext4":
      case "ext3":
      case "xfs":
      default:
        $strExec="/bin/mkdir '$path'";
        shell_exec($strExec);
        if($quota_limit!="0" && $quota_limit!=""){
          $quota_limit=$quota_limit*1024;
          $strExec="sh -x /img/bin/managefolder.sh -m '".$path."' ".$quota_limit." >/tmp/managefolder.log 2>&1 &";
          shell_exec($strExec);
        }
        $strExec="chmod 774 '$path' &&";

        if (NAS_DB_KEY == '1')
          $strExec.="chown nobody:smbusers '$path'";
        elseif (NAS_DB_KEY == '2')
          $strExec.="chown nobody:users '$path'";

        shell_exec($strExec);
        //##########################################
        //	Set ACL
        //##########################################
        if($guest_only=='yes'){
          $strExec="setfacl -P -m other::rwx ".escapeshellarg($path);
          shell_exec($strExec);
        }else{
          $strExec="chmod 700 ".escapeshellarg($path);
          shell_exec($strExec);
        }
        $strExec="setfacl -P -d -m other::rwx ".escapeshellarg($path);
        shell_exec($strExec);
        //##########################################
        break;
    }


    //==========================================
    //	Start Service(samba,ftp,afp,nfs)
    //==========================================
    if (NAS_DB_KEY == '1'){
      shell_exec("/img/bin/rc/rc.samba assemble > /dev/null 2>&1");
    }elseif (NAS_DB_KEY == '2'){
      shell_exec("/img/bin/rc/rc.samba reload > /dev/null 2>&1");
      shell_exec('/img/bin/rc/rc.atalk reload > /dev/null 2>&1 &');
    }

    shell_exec("/img/bin/rc/rc.rsyncd rebuildconf");
    webdav_reload();

    $ary = array('ok'=>'onLoad_share_apply()');
    $msg = $aswords["addshareSuccess"]." - [{$share_name}]";
    foo::syslog("",sprintf(LOG_MSG_ADD_SHARE_SUCCESS,$share_name),"info");
    //==========================================
    //      Check folder exist
    //==========================================
    if(file_exists($share_path) && $db_ret=="1"){
      $strExec="/img/bin/logevent/event 997 407 info \"\" '".$share_name."'";
      shell_exec($strExec);
    }

    return MessageBox(true,$gwords['success'],$msg,'INFO','OK',$ary);
    break;
  case 'update':	 
    require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
    $class=new RAIDINFO();
    $modify=FALSE;
    $result=FALSE;
    $smb_restart=FALSE;
    $md_num = $_POST['o_md_num'];
    //===========================================
    //	First, Don't forget to prepare SmbConf
    //===========================================
    if($md_num=='')
      $md_num=$_POST["md_num"];
    if (NAS_DB_KEY == '1')
      $raid_name="raid".($md_num-1);
    elseif (NAS_DB_KEY == '2')
      $raid_name="raid".($md_num);

    $strExec="$sqlite_cmd $raid_database \"select v from conf where k='raid_name'\"";
    $raid_id=trim(shell_exec($strExec));

    $_POST["_share"]=str_replace("\\\\","\t",$_POST["_share"]);
    $_POST["_share"]=str_replace("\\","",$_POST["_share"]);
    $share_name=str_replace("\t","\\",$_POST["_share"]);
    $guest_only=trim($_POST["_guest_only"]);
    $quota_limit=trim($_POST["_quota_limit"]);

    if (NAS_DB_KEY == '1'){
      $o_path="/raid".($md_num-1)."/data/".$o_share_name;
      $path="/raid".($md_num-1)."/data/".$share_name;
    }elseif (NAS_DB_KEY == '2'){
      $o_path="/raid".($md_num)."/data/".$o_share_name;
      $path="/raid".($md_num)."/data/".$share_name;
    }
    //###########################################################
    //#     Get total folder name
    //###########################################################
    $total_folder=get_total_folder();
    
    
    //###########################################################
    //#     Get all stack folder name
    //##########################################################
    $conf_db=new sqlitedb();
    $iscsi_is_enabled=$conf_db->db_get_single_value("conf","v","where k='iscsi'");
    unset($conf_db);
    if($iscsi_is_enabled !== NULL){
      $db = new sqlitedb($stack_db);
      $all_stack_share_name=$db->db_get_folder_info("stackable","share",""); //#	Get stack folder name
      unset($db);
    }

    //###########################################################
    //#     Check folder (duplicate)
    //###########################################################
    foreach($total_folder as $folder){
        if($folder!="" && strtolower($folder)!=strtolower($o_share_name)){
            if(strtolower($folder)==strtolower($share_name)){
                foreach($all_stack_share_name as $data){
                    if($data!=""){
                        if(strtolower($share_name)==strtolower($data["share"])){
                            return MessageBox(true,$gwords['error'],$aswords['ERROR_SHARENAME_DUPLICATE'],'ERROR');
                        }
                    }
                }
                return MessageBox(true,$gwords['error'],$aswords['ERROR_SHARENAME_DUPLICATE'],'ERROR');
            }
        }
    }
    

    //=====================================================
    //	Update db
    //=====================================================
    $compare = array("_quota_limit","_share","_guest_only");
    foreach($compare as $c) {
      if($_POST[$c]!=$_POST["o".$c]) {
        $modify=TRUE;
        break;
      }
    }

    if(!$modify){
      if($_POST["_quota_limit"]!=$_POST["o"."_quota_limit"]) {
        $quota_limit=$_POST["_quota_limit"];
        modify_folder_quota($share_name,$quota_limit,$md_num);
      }
      $ary = array('ok'=>'onLoad_share_apply()');
      return MessageBox(true,$gwords['success'],$mswords['modshareSuccess'],'INFO','OK',$ary);
    }

    if($modify){
      if(file_exists($o_path)){
        if (NAS_DB_KEY == '1')
          $db = new sqlitedb($raid_database);
        elseif (NAS_DB_KEY == '2')
          $db = new sqlitedb();


        if($share_name!=$o_share_name){
          if (NAS_DB_KEY == '1'){
            shell_exec("/img/bin/rc/rc.isomount modify '".$o_share_name."' ".($md_num-1)." '".$share_name."' updatedb");
            $req=modify_folder_name($o_share_name,$share_name,$md_num);
            if(!$req){
              shell_exec("/img/bin/rc/rc.isomount modify '".$share_name."' ".($md_num-1)." '".$o_share_name."' recover");
              shell_exec("/img/bin/rc/rc.isomount modify '".$share_name."' ".($md_num-1)." '".$o_share_name."' mount");
              $mountpoint=sprintf("/raid%d/data/%s",$md_num-1,$share_name);
              if($mountpoint != "")
                shell_exec("/bin/rmdir '$mountpoint'");
              return MessageBox(true,$gwords['error'],$mswords['modshare_in_use'],'ERROR');
            }
            shell_exec("/img/bin/rc/rc.isomount modify '".$o_share_name."' ".($md_num-1)." '".$share_name."' mount");
          }elseif (NAS_DB_KEY == '2'){
            shell_exec("/img/bin/rc/rc.isomount modify '".$o_share_name."' ".($md_num)." '".$share_name."' updatedb");
            $req=modify_folder_name($o_share_name,$share_name,$md_num);
            if(!$req){
              shell_exec("/img/bin/rc/rc.isomount modify '".$share_name."' ".($md_num)." '".$o_share_name."' recover");
              shell_exec("/img/bin/rc/rc.isomount modify '".$share_name."' ".($md_num)." '".$o_share_name."' mount");
              $mountpoint=sprintf("/raid%d/data/%s",$md_num,$share_name);
              if($mountpoint != "")
                shell_exec("/bin/rmdir '$mountpoint'");
              return MessageBox(true,$gwords['error'],$mswords['modshare_in_use'],'ERROR');
            }
            shell_exec("/img/bin/rc/rc.isomount modify '".$o_share_name."' ".($md_num)." '".$share_name."' mount");
          }
        }
        //#############################################
        //#	Update nfs database
        //#############################################
        $set="share='".$share_name."'";
        $where="where share='".$o_share_name."'";
        $db->db_update("nfs",$set,$where);

        //#############################################
        //#	Update raid folder database
        //#############################################
        if (NAS_DB_KEY == '1'){
          $set="share='".$share_name."',guest_only='".$guest_only."',quota_limit='".$quota_limit."'";
          $where="where share='".$o_share_name."'";
          $db_return = $db->db_update("folder",$set,$where);
        }elseif (NAS_DB_KEY == '2'){
          unset($db);
          $db = new sqlitedb($raid_database);
          $maphidden="no";

          $set="share='".$share_name."','guest only'='".$guest_only."','map hidden'='".$maphidden."','path'='".$share_name."'";
          $where="where share='".$o_share_name."'";

          $folder_exist=$db->db_get_folder_info("smb_specfd","share",$where);
          $folder_exist=$folder_exist[0][0];
          if ($folder_exist == '')
            $db_return = $db->db_update("smb_userfd",$set,$where);
          else
            $db_return = $db->db_update("smb_specfd",$set,$where);
        }

        //#############################################
        unset($db);
        if(!$db_return){
          return MessageBox(true,$gwords['error'],$mswords['modshareError'],'ERROR');
        }
      }

      //===========================================
      //	Delete Quota
      //===========================================
      if(($share_name!=$o_share_name && $_POST["o_quota_limit"]>"0") || ($_POST["_quota_limit"]!=$_POST["o_quota_limit"] && $_POST["o_quota_limit"]>"0")){
        if ($fsmode!="zfs") {
          $strExec="/img/bin/managefolder.sh -d '" . $o_path . "' >/dev/null 2>&1";
          shell_exec($strExec);
        }
      }

      //===========================================
      //	Write log
      //===========================================
      $change_log="";
      if($share_name!=$o_share_name){
        $change_log.="[ Share Folder = ".$share_name." ]";
      }

      if($_POST["_guest_only"] != $_POST["o_guest_only"]){
        if($_POST['_guest_only']=='yes'){
          if($fsmode=="zfs"){
            $set.=",valid_users='',invalid_users='',read_list='',write_list='',valid_id='',invalid_id='',read_list_id='',write_list_id=''";
            $where="where share='".$share_name."'";
            $db = new sqlitedb($raid_database);
            $db_return=$db->db_update("folder",$set,$where);
            unset($db);
            if(!$db_return){
            return MessageBox(true,$gwords['error'],$mswords['modshareError'],'ERROR');
            }
          }else{
            $strExec="setfacl -R -P -b ".escapeshellarg($path);
            shell_exec($strExec);
            $strExec="setfacl -R -P -m other::rwx ".escapeshellarg($path);
            shell_exec($strExec);
          }
          shell_exec("chmod -R 777 ".escapeshellarg($path));
        }else{
          if($_POST["o_guest_only"]=="yes"){
            if($fsmode=="zfs"){
              $set.=",valid_users='root',invalid_users='',read_list='',write_list=''";
              $where="where share='".$share_name."'";
              $db = new sqlitedb($raid_database);
              $db_return=$db->db_update("folder",$set,$where);
              unset($db);
              if(!$db_return){
                return MessageBox(true,$gwords['error'],$mswords['modshareError'],'ERROR');
              }
              shell_exec("chmod -R 777 ".escapeshellarg($path));
            }else{
              $strExec="setfacl -R -P -m other::--- ".escapeshellarg($path);
              shell_exec($strExec);
              $strExec="chmod -R 700 ".escapeshellarg($path);
              shell_exec($strExec);
            }
          }
        }
        if($fsmode!="zfs"){
          $strExec="setfacl -R -P -d -m other::rwx ".escapeshellarg($path);
          shell_exec($strExec);
        }
        $change_log.="[ Public = ".$guest_only." ]";
      }

      if($_POST["_quota_limit"] != $_POST["o_quota_limit"]){
        $change_log.="[ Share Folder Limit = ".$quota_limit." GB ]";
      }
      $strExec="/img/bin/logevent/event 997 409 info \"\" '".$o_share_name."' \"".$raid_id."\" \"".$change_log."\"";
      shell_exec($strExec);
      //===========================================
      //	Modify Quota
      //===========================================
      if(($share_name!=$o_share_name && $_POST["_quota_limit"]>"0") || ($_POST["_quota_limit"]!=$_POST["o_quota_limit"] && $_POST["_quota_limit"]>"0")){
        $quota_limit=$_POST["_quota_limit"];
        modify_folder_quota($share_name,$quota_limit,$md_num);
      }
      //===========================================
      //	Restart smbd
      //===========================================
      flush();
      if (NAS_DB_KEY == '1'){
        shell_exec("/img/bin/rc/rc.samba assemble > /dev/null 2>&1");
        shell_exec('/img/bin/rc/nfs reload');
      }elseif (NAS_DB_KEY == '2'){
        shell_exec('/img/bin/rc/rc.nfsd reload');
        shell_exec("/img/bin/rc/rc.samba reload > /dev/null 2>&1");
        shell_exec('/img/bin/rc/rc.atalk reload > /dev/null 2>&1 &');
      }
    }

    shell_exec("/img/bin/rc/rc.rsyncd rebuildconf");
    webdav_reload();

    $ary = array('ok'=>'onLoad_share_apply()');
    return MessageBox(true,$mswords["settingTitle"],$mswords["modshareSuccess"],'INFO','OK',$ary);
    break;
  case 'remove':   
  	if(empty($share_name)){
      $db = new sqlitedb($raid_database);
	    if (NAS_DB_KEY == '1')
        $db->db_delete("folder","where share='$share_name'");
      elseif (NAS_DB_KEY == '2')
        $db->db_delete("smb_userfd","where share='$share_name'");
      unset($db); 
      $Mesg=sprintf($mswords["del_success"],$share_name); 
      $ary = array('ok'=>'onLoad_share_apply()'); 
      foo::syslog("",sprintf(LOG_MSG_DELETE_SHARE_SUCCESS,$share_name),"info");
      return MessageBox(true,$gwords['success'],$Mesg,'INFO','OK',$ary);  
    }
    if (NAS_DB_KEY == '1')
      $path="/raid".($md_num-1).'/data'.$share_path;
    elseif (NAS_DB_KEY == '2')  
      $path="/raid".($md_num).'/data'.$share_path;

    $error="0";
        
    //===============================================================
    //	DELETE Folder DB & Remove Quota & Remove folder
    //===============================================================  
   
    if (NAS_DB_KEY == '1'){
      $strExec="$sqlite_cmd $raid_database \"select quota_limit from folder where share='$share_name'\""; 
      $quota_limit=trim(shell_exec($strExec));

      $db_res=remove_folder($share_name,$md_num,$quota_limit,$share_path);
    }
    elseif (NAS_DB_KEY == '2'){
      $db_res=remove_folder($share_name,$md_num,"",$share_path);
    }

    if($db_res=="2"){
      $error="3";
    }elseif($db_res!="0"){
      $error="1";
    }else{
      if ($share_name != "" && is_dir($path)){
        $cmd="/bin/rm -rf '$path' >> /tmp/del.log 2>&1";
        exec($cmd,$out,$rm_res);
      }else
        $rm_res="0";
      if($rm_res!="0"){
        $error="2";
      }
    }
    //===============================================================
    //      Check folder exist
    //===============================================================
    if(!file_exists($share_path)){
      $strExec="/img/bin/logevent/event 997 408 info email '".$share_name."'";
      shell_exec($strExec);
    }
            
        
    //===============================================================
    //	Restart Service
    //===============================================================
    if($db_res=="0" && $rm_res=="0"){
      if (NAS_DB_KEY == '1'){
        shell_exec("/img/bin/rc/rc.samba assemble > /dev/null 2>&1 &");
        shell_exec('/img/bin/rc/rc.nfsd reload > /dev/null 2>&1 &');
      }elseif (NAS_DB_KEY == '2'){
        shell_exec('/img/bin/rc/rc.nfsd reload');
        shell_exec("/img/bin/rc/rc.samba reload > /dev/null 2>&1");
        shell_exec('/img/bin/rc/rc.atalk reload > /dev/null 2>&1 &');
      }
    }
    
    shell_exec("/img/bin/rc/rc.rsyncd rebuildconf");
    webdav_reload();
    
    //===============================================================
    //	Redirect to the POST page
    //===============================================================
   
    if($error){
      foo::syslog("",sprintf(LOG_MSG_DELETE_SHARE_FAILED,$share_name),"info"); 
      if($error=="3")
        $Mesg=sprintf($mswords["umount_failed"],$share_name); 
      else
        $Mesg=sprintf($mswords["del_failed"],$share_name); 
      return MessageBox(true,$gwords['error'],$Mesg,'ERROR'); 
    }else{  
      $Mesg=sprintf($mswords["del_success"],$share_name); 
      $ary = array('ok'=>'onLoad_share_apply()'); 
      foo::syslog("",sprintf(LOG_MSG_DELETE_SHARE_SUCCESS,$share_name),"info");
      return MessageBox(true,$gwords['success'],$Mesg,'INFO','OK',$ary);  
    }  
    break;
  
}

//###############################################
//#	NFS
//###############################################
switch($nfs_action_share){
   case 'nfs_add':   
      //###############################################
      //#	Check database and column
      //###############################################  
      if (NAS_DB_KEY == '1'){
        $db = new sqlitedb($raid_database);
        if($nfs_db_list[0]['share']==""){
            $db->db_alter("nfs","os_support","0");
          }else{
            foreach($nfs_db_list as $info){
              if($info != ""){
                if($info["os_support"]==""){
                  $db->db_alter("nfs","os_support","0");
                  break;
                }
              }
            }
          }
      }
      elseif (NAS_DB_KEY == '2')
        $db = new sqlitedb();
      
      //===========================================
      //	Check share name
      //=========================================== 
      if($nfs_count!=0){
        return MessageBox(true,$gwords['error'],$mswords['nfs_createfail']." - [$hostname]",'ERROR'); 
      }
      //==============================================
      // Write Share Folder permission to DB
      //==============================================
      if (NAS_DB_KEY == '1')
          $insert_ret=$db->db_insert("nfs","share,hostname,privilege,rootaccess,os_support","'$share_name','$hostname','$privilege','$rootaccess','$os_support'");
      elseif (NAS_DB_KEY == '2')
          $insert_ret=$db->db_insert("nfs","share,hostname,privilege,rootaccess,os_support,sync","'$share_name','$hostname','$privilege','$rootaccess','$os_support','$sync'");

      if(!$insert_ret){
        return MessageBox(true,$gwords['error'],$mswords['nfs_createfail']." - [$hostname]",'ERROR'); 
      }
      unset($db);

      if (NAS_DB_KEY == '1')
          shell_exec("/img/bin/rc/nfs reload");
      elseif (NAS_DB_KEY == '2')
          shell_exec('/img/bin/rc/rc.nfsd reload');
 
      return MessageBox(true,$gwords['success'],$mswords["nfs_createsuccess"]." - [$hostname]"); 
   break; 
   case 'nfs_update': 
      if (NAS_DB_KEY == '1'){
          $db = new sqlitedb($raid_database);
          //==============================================
          // Update Share Folder permission to db
          //==============================================
          //###############################################
          //#     Check database and column
          //###############################################  
          if($nfs_db_list[0]['share']==""){
            $db->db_alter("nfs","os_support","0");
          }else{
            foreach($nfs_db_list as $info){
              if($info != ""){
                if($info["os_support"]==""){
                  $db->db_alter("nfs","os_support","0");
                  break;
                }
              }
            }
        }

        $update_ret=$db->db_update("nfs","privilege='$privilege',rootaccess='$rootaccess',os_support='$os_support'","where share='$share_name' and hostname='$hostname'");
      }elseif (NAS_DB_KEY == '2'){
        $db = new sqlitedb();
        $update_ret=$db->db_update("nfs","privilege='$privilege',rootaccess='$rootaccess',os_support='$os_support',sync='$sync'","where share='$share_name' and hostname='$hostname'");
      }
      if(!$update_ret){
        return MessageBox(true,$gwords['error'],$mswords['modshareError']." - [$hostname]",'ERROR'); 
      }
      unset($db);
      //###############################################
      //===========================================
      //	Restart smbd
      //===========================================
      if($errcode==0) {
        if (NAS_DB_KEY == '1')
          shell_exec("/img/bin/rc/nfs reload");
        elseif (NAS_DB_KEY == '2')
          shell_exec('/img/bin/rc/rc.nfsd reload');
      }
      
      //===========================================
      //	Redirect
      //===========================================
      return MessageBox(true,$gwords['success'],$mswords['modshareSuccess']); 
   break;
   
   case 'nfs_remove':  
      //===============================================================
      //	First, we could get the share name .Then, we could delete nfs share in db
      //===============================================================
      if (NAS_DB_KEY == '1'){
        $db = new sqlitedb($raid_database);
        $update_ret=$db->db_delete("nfs","where share='$share_name' and hostname='$hostname'");
      }elseif (NAS_DB_KEY == '2'){
        $db = new sqlitedb();
        $update_ret=$db->db_delete("nfs","where share='$share_name' and hostname='$hostname'");
      }
      unset($db);
 
        if (NAS_DB_KEY == '1')
          shell_exec("/img/bin/rc/nfs reload");
        elseif (NAS_DB_KEY == '2')
          shell_exec('/img/bin/rc/rc.nfsd reload');

      //===============================================================
      //	Redirect to the POST page
      //===============================================================
      
      $ary = array('ok'=>'onLoad_nfs_remove()');
      return MessageBox(true,$gwords['success'],$gwords['success'],'INFO','OK',$ary); 
   break;
}
 

//###############################################
//#	SnapShot
//###############################################
switch($action_snapshot){
   case 'take_shot':
       $strExec="/img/bin/rc/rc.snapshot check_root_folder";
       $ret=trim(shell_exec($strExec));
       if (NAS_DB_KEY == '1')
        $strExec="/img/bin/rc/rc.snapshot check_share_folder \"".($md_num-1)."\" \"${share}\"";
       elseif(NAS_DB_KEY == '2')
        $strExec="/img/bin/rc/rc.snapshot check_share_folder \"".$md_num."\" \"${share}\"";
       $ret=trim(shell_exec($strExec));
       
       if (NAS_DB_KEY == '1')
        $strExec="/img/bin/rc/rc.snapshot start \"".($md_num-1)."\" \"${share}\" \"${action_snapshot}\"";
       elseif(NAS_DB_KEY == '2')
        $strExec="/img/bin/rc/rc.snapshot start \"".$md_num."\" \"${share}\" \"${action_snapshot}\"";
       $ret=trim(shell_exec($strExec));
       
       if($ret==0){
         $ary = array('ok'=>'onLoad_snapshot()');
         return MessageBox(true,$gwords['success'],$words['take_shot_success'],'INFO','OK',$ary);
       }elseif($ret=="-1"){  // Create snpashot fail
         $Mesg=$words["create_snapshot_fail"];  
       }elseif($ret=="-2"){ // Create clone fail
         $Mesg=$words["create_clone_fail"]; 
       }elseif($ret=="-3"){  //   Unmount fail
         $Mesg=$words["umount_fail"]; 
       }elseif($ret=="-4"){  // Set mount point
         $Mesg=$words["set_mount_point_fail"]; 
       }elseif($ret=="-5"){ //    Mount fail
         $Mesg=$words["mount_fail"]; 
       }elseif($ret=="-6"){  //   Other fail in take snapshot
         $Mesg=$words["unknow_fail"];
       }elseif($ret=="-9"){ //   Over snapshot count
         get_sysconf();
         if (NAS_DB_KEY == '1')
          $Mesg=sprintf($words["snap_limit"],$sysconf["zfs_snapshot"]);
         else
          $Mesg=sprintf($words["snap_limit"],$sysconf["snapshot"]); 
       }else{  //   Unknow fail
         $Mesg=$words["unknow_fail"];
       }
       return MessageBox(true,$gwords['error'],$Mesg,'ERROR'); 
   break;
   case 'del_shot':
       $zfs_path="${zfs_pool}/${zfs_share}";
       if (NAS_DB_KEY == '1')
        $strExec="/img/bin/rc/rc.snapshot delete \"".(${md_num}-1)."\" \"${share}\" \"${action_snapshot}\" \"${zfs_path}\" \"${share_date}\"";
       elseif(NAS_DB_KEY == '2')
        $strExec="/img/bin/rc/rc.snapshot delete \"".$md_num."\" \"${share}\" \"${action_snapshot}\" \"${zfs_path}\" \"${share_date}\"";
       $ret=trim(shell_exec($strExec));
       if($ret==1){
         $ary = array('ok'=>'onLoad_snapshot()');
         return MessageBox(true,$gwords['success'],$words['del_snapshot_success'],'INFO','OK',$ary);
       }elseif($ret=="-7"){ //   Delete clone fail
         $Mesg=$words["del_clone_fail"]; 
       }elseif($ret=="-8"){ //   Delete snapshot fail
         $Mesg=$words["del_snapshot_fail"];  
       }else{
         $ary = array('ok'=>'onLoad_snapshot()');
         return MessageBox(true,$gwords['success'],$words['del_snapshot_success'],'INFO','OK',$ary);
       }
       return MessageBox(true,$gwords['error'],$Mesg,'ERROR');
   break;
   case 'set_schedule': 
      if (NAS_DB_KEY == '1'){
        $strExec="/usr/bin/zfs list | grep '/${raid_name}/data/${share}$' | awk '{print $1}'";
  		  $snapshot_info=explode("/",trim(shell_exec($strExec)));
  		  $zfs_pool=trim($snapshot_info["0"]);
  		  $zfs_share=trim($snapshot_info["1"]);
  		}
      elseif(NAS_DB_KEY == '2'){
  		  $zfs_share=$share;
      }
		  $autodel=($_POST["_enable_autodel"]!="")?trim($_POST["_enable_autodel"]):0;
		  $enabled=($_POST["_enable_schedule"]!="")?trim($_POST["_enable_schedule"]):0;
		  $rule=($_POST["_schedule_rule"]!="")?trim($_POST["_schedule_rule"]):m;
		  $month_day=($_POST["_month_day"]!="")?trim($_POST["_month_day"]):0;
		  $month_hours=($_POST["_month_hours"]!="")?trim($_POST["_month_hours"]):0;
		   
		  
			$week_day_list=array("0"=>$gwords['sunday'],"1"=>$gwords['monday'],"2"=>$gwords['tuesday'],"3"=>$gwords['wednesday'],"4"=>$gwords['thursday'],"5"=>$gwords['friday'],"6"=>$gwords['saturday']);
			foreach($week_day_list as $k=>$v) {
			  if ($_POST["_week_day"]==$v) {
					  $_POST["_week_day"]=$k;
			  } 
			} 
			
		  $week_day=($_POST["_week_day"]!="")?trim($_POST["_week_day"]):0;
		  $week_hours=($_POST["_week_hours"]!="")?trim($_POST["_week_hours"]):0;
		  $day_hours=($_POST["_day_hours"]!="")?trim($_POST["_day_hours"]):0;
		  
		  
		   
		  //#######################################################
		  if($rule=="m"){
		    $insert_col=",day";
		    $insert_val=",'${month_day}'";
		    $update_val=",day='${month_day}'";
		    $hour=$month_hours;
		    $cron_time="00 ${hour} ${month_day} * *";
		  }elseif($rule=="w"){
		    $insert_col=",week";
		    $insert_val=",'${week_day}'";
		    $update_val=",week='${week_day}'";
		    $hour=$week_hours;
		    $cron_time="00 ${hour} * * ${week_day}";
		  }else{
		    $insert_col="";
		    $insert_val="";
		    $update_val="";
		    $hour=$day_hours;
		    $cron_time="00 ${hour} * * *";
		  }
		  
		  
		  //#######################################################
		  //#	Check database
		  //#######################################################
		  $database="/${raid_name}/sys/snapshot.db"; 
		  $db = new sqlitedb($database); 
      $table_exist=$db->db_get_folder_info("sqlite_master","count(*)","where type='table' and name='snapshot'");  

		  $table_exist=$table_exist[0][0]; 
		  if($table_exist=="0"){
		    $strExec="touch ${database}";
		    shell_exec($strExec); 
		    $db->db_runSQL("create table snapshot(zfs_share,enabled,autodel,schedule_rule,day,week,hour,p1,p2,p3,p4)");
		    
		  }
      $table_exist=$db->db_get_folder_info("sqlite_master","count(*)","where type='table' and name='snapshot'");  

		  $table_exist=$table_exist[0][0];       
		  if($table_exist=="0"){ 
		    return MessageBox(true,$gwords['error'],$words['create_snapshot_db_fail'],'ERROR'); 
		  }
		  $strExec="/img/bin/rc/rc.snapshot check_root_folder";
		  $ret=trim(shell_exec($strExec));
		  if (NAS_DB_KEY == '1')
        $strExec="/img/bin/rc/rc.snapshot check_share_folder \"".($md_num-1)."\" \"${share}\"";
		  elseif (NAS_DB_KEY == '2')
        $strExec="/img/bin/rc/rc.snapshot check_share_folder \"".$md_num."\" \"${share}\"";
		  $ret=trim(shell_exec($strExec));
      $record_exist=$db->db_get_single_value("snapshot","zfs_share","where zfs_share='${zfs_share}'");
		  //#######################################################
		  //#	Insert/Update info to database
		  //####################################################### 
		  if($record_exist==""){
		    $columns="zfs_share,enabled,autodel,schedule_rule".$insert_col.",hour";
		    $values="'${zfs_share}','${enabled}','${autodel}','${rule}'".${insert_val}.",'${hour}'"; 
		    $insert_ret=$db->db_insert("snapshot",$columns,$values); 
		    if(!$insert_ret){
		      return MessageBox(true,$gwords['error'],$words['add_schedule_fail'],'ERROR');  
		    }
		  }else{
		    if($enabled=="1"){
		      $set="enabled='${enabled}',autodel='${autodel}',schedule_rule='${rule}'".$update_val.",hour='${hour}'";
		    }else{
		      $set="enabled='${enabled}'";
		    }
		    $where="where zfs_share='${zfs_share}'"; 
		    $update_ret=$db->db_update("snapshot",$set,$where); 
		    if(!$update_ret){
		      return MessageBox(true,$gwords['error'],$words['modify_schedule_fail'],'ERROR');   
		    }
		  }
		  unset($db);
		  if($enabled=="1"){
		    $source=shell_exec("cat /etc/cfg/crond.conf | grep -v '#snapshot ${share}$'");
		    if (NAS_DB_KEY == '1')
          $crond_msg="${cron_time} /img/bin/rc/rc.snapshot start \"".(${md_num}-1)."\" \"${share}\" \"${action_snapshot}\" > /dev/null 2>&1 #snapshot ${share}";
		    elseif (NAS_DB_KEY == '2')
          $crond_msg="${cron_time} /img/bin/rc/rc.snapshot start \"".$md_num."\" \"${share}\" \"${action_snapshot}\" > /dev/null 2>&1 #snapshot ${share}";
		    $fp=fopen("/etc/cfg/crond.conf","wb");
		    fwrite($fp,$source);
		    fwrite($fp,$crond_msg."\n");
		    fclose($fp);
		    shell_exec("cat /etc/cfg/crond.conf | crontab - -u root");
		  }else{
		    $source=shell_exec("cat /etc/cfg/crond.conf | grep -v '#snapshot ${share}'");
		    $fp=fopen("/etc/cfg/crond.conf","wb");
		    fwrite($fp,$source."\n");
		    fclose($fp);
		    shell_exec("cat /etc/cfg/crond.conf | crontab - -u root");
		  } 
		  return MessageBox(true,$gwords['success'],$words['set_schedule_success']);  
		  
		  
   break;
}
  
	 
function remove_folder($sharename,$md_num,$quota_limit,$share_path) {
  global $fsmode,$mkzpool,$mkzfs,$zfsname,$raid_database;
  $db = new sqlitedb($raid_database);
  if (NAS_DB_KEY == '1')
    $folder_exist=$db->db_get_single_value("folder","share","where share='$sharename'");
  elseif (NAS_DB_KEY == '2')
    $folder_exist=$db->db_get_single_value("smb_userfd","share","where share='$sharename'");
  unset($db);
  if ($folder_exist==""){
    return 1;
  }
	$umount_result=shell_exec("/img/bin/rc/rc.isomount delete '".$sharename."' ".($md_num-1));
	if(trim($umount_result)=="1"){
		return 2;
	}
	switch ($fsmode) {
		case "zfs":  
			$zfspoolname=sprintf("zfspool%d",$md_num-1);
			$zfsitem=sprintf("%s/%s",$zfspoolname,$zfsname);
			$strExec="${mkzfs} list | grep \"$zfsitem\"";
			$zfsitem_exist=shell_exec($strExec);
			if($zfsitem_exist=="" || $zfsname==""){
				return 1;
			}
			$strExec="umount \"${zfsitem}\"";
			exec($strExec,$out,$req); 
			if($req!='0') return 1;
			$strExec="/img/bin/rc/rc.snapshot delete \"".($md_num-1)."\" \"${sharename}\" \"all_snapshot\" \"${zfsitem}\"";
			exec($strExec,$out,$req); 
			if($req!='0') return 1;
			$strExec="${mkzfs} destroy \"${zfsitem}\"";
			exec($strExec,$out,$req); 
			if($req!='0') return 1;
			break;
    case "btrfs":
      if (NAS_DB_KEY == '1')
        $strExec="/img/bin/rc/rc.snapshot delete \"".($md_num-1)."\" \"${sharename}\" \"all_snapshot\"";
      elseif (NAS_DB_KEY == '2')
        $strExec="/img/bin/rc/rc.snapshot delete \"".($md_num)."\" \"${sharename}\" \"all_snapshot\"";

      exec($strExec,$out,$req);
      if($req!='0') return 1;
      if (NAS_DB_KEY == '1')
        $strExec="/sbin/btrfsctl -D $sharename /raid".($md_num-1)."/data/";
      elseif (NAS_DB_KEY == '2')
        $strExec="/sbin/btrfsctl -D $sharename /raid".($md_num)."/data/";
      exec($strExec,$out,$req);
      //if($req!='0') return 1;
      
      if (NAS_DB_KEY == '1')
        $path="/raid".($md_num-1)."/data".$share_path;
      elseif (NAS_DB_KEY == '2')
        $path="/raid".($md_num)."/data".$share_path;

      if($quota_limit!="0" && $quota_limit!=""){
        $strExec="(/img/bin/managefolder.sh -d '".$path."' > /dev/null 2>&1) &";
        shell_exec($strExec);
      }

      break;
		case "ext4":
		case "ext3":
		case "xfs":
		default:
			if (NAS_DB_KEY == '1')
        $path="/raid".($md_num-1)."/data".$share_path;
      elseif (NAS_DB_KEY == '2')
        $path="/raid".($md_num)."/data".$share_path;
                
			if(!file_exists($path) && $sharename==""){
				return 1;
			}
		  if($quota_limit!="0" && $quota_limit!=""){
		    $strExec="(/img/bin/managefolder.sh -d '".$path."' > /dev/null 2>&1) &";
		    shell_exec($strExec);
		  }
			break;
	}
  $db = new sqlitedb($raid_database);
	
	if (NAS_DB_KEY == '1')
    $db->db_delete("folder","where share='$sharename'");
  elseif (NAS_DB_KEY == '2')
    $db->db_delete("smb_userfd","where share='$sharename'");

  unset($db);
	return 0;  
}



function check_char($string){
  $str_len=strlen($string);
  $new_string="";
  for($c=0;$c<$str_len;$c++){
    $char=substr($string,$c,1);
    $tmp_string="";
    if($char==chr(39)){
      $tmp_string=chr(39).$char;
    }elseif($char==chr(124) || $char==chr(92) || $char==chr(34)){
      $tmp_string=chr(92).$char;
    }else{
      $tmp_string=$char;
    }
    $new_string.=$tmp_string;
  }
  return $new_string;
}



//#################################################################
//#	Modify snapshot mount point
//#################################################################
function modify_snapshot_item($o_sharename,$sharename,$md_num,$zfsitem,$type=''){
	global $fsmode,$mkzpool,$mkzfs; 
	$strExec="df | grep \"${zfsitem}/\" | awk '{printf(\"%s\\t%s\\n\",$1,$6)}'"; 
	$snapshot_list=trim(shell_exec($strExec));
	$snapshot_list=explode("\n",$snapshot_list);
	foreach($snapshot_list as $snapshot_item){	
		if($snapshot_item != ""){
			$strExec="echo \"${snapshot_item}\" | awk -F'/' '{print $3}'";
			$snap_date=trim(shell_exec($strExec));
			$snap_item="${zfsitem}/${snap_date}";
			$old_snap_path="/raid/snapshot/${o_sharename}";
			$new_snap_path="/raid/snapshot/${sharename}";
			$snap_point="${new_snap_path}/${snap_date}"; 
			$o_snap_point="${old_snap_path}/${snap_date}"; 
                        if($type=='remove'){
				$strExec=sprintf("$mkzfs set mountpoint=\"%s\" \"%s\" >> /tmp/snapshot.log 2>&1",$o_snap_point,$snap_item); 
				shell_exec($strExec);
				$strExec=sprintf("$mkzfs mount \"%s\" >> /tmp/snapshot.log 2>&1",$snap_item);
				shell_exec($strExec);
			}elseif(file_exists($old_snap_path)){ 
				$strExec="/bin/mkdir \"${new_snap_path}\"";
				shell_exec($strExec);
				shell_exec("umount \"$snap_item\" ");
				$strExec=sprintf("$mkzfs set mountpoint=\"%s\" \"%s\" >> /tmp/snapshot.log 2>&1",$snap_point,$snap_item);
				system($strExec,$req);  
				if($req!='0'){
				     $strExec=sprintf("$mkzfs set mountpoint=\"%s\" \"%s\" >> /tmp/snapshot.log 2>&1",$o_snap_point,$snap_item);
				     shell_exec($strExec);
				     $strExec=sprintf("$mkzfs mount \"%s\" >> /tmp/snapshot.log 2>&1",$snap_item);
				     shell_exec($strExec);
                                     modify_snapshot_item($o_sharename,$sharename,$md_num,$zfsitem,'remove');
				     return -1;
				}  
				$strExec=sprintf("$mkzfs mount \"%s\" >> /tmp/snapshot.log 2>&1",$snap_item);
				system($strExec,$req);
				if($req!='0'){
				     $strExec=sprintf("$mkzfs set mountpoint=\"%s\" \"%s\" >> /tmp/snapshot.log 2>&1",$o_snap_point,$snap_item);
				     shell_exec($strExec);
				     $strExec=sprintf("$mkzfs mount \"%s\" >> /tmp/snapshot.log 2>&1",$snap_item);
				     shell_exec($strExec);
                                     modify_snapshot_item($o_sharename,$sharename,$md_num,$zfsitem,'remove');
				     return -1;
				}
			}
		}
	} 
}

function modify_folder_name($o_sharename,$sharename,$md_num) {
	global $fsmode,$mkzpool,$mkzfs,$zfsname,$o_zfsname;  
	
	switch ($fsmode) {
		case "zfs": 
			$zfspoolname=sprintf("zfspool%d",$md_num-1);
			$mountpoint=sprintf("/raid%d/data/%s",$md_num-1,$sharename);
			$o_mountpoint=sprintf("/raid%d/data/%s",$md_num-1,$o_sharename); 
			$zfsitem=sprintf("%s/%s",$zfspoolname,$o_zfsname);
			shell_exec("umount '$zfsitem' ");
			$strExec="/bin/mkdir '$mountpoint'";
			shell_exec($strExec);
			$strExec=sprintf("$mkzfs set mountpoint='%s' '%s' >> /tmp/zfslog.log 2>&1",$mountpoint,$zfsitem);
			system($strExec,$req);
			if($req!='0') {  
			    return false; 
			}

			$strExec=sprintf("$mkzfs mount '%s' >> /tmp/zfslog.log 2>&1",$zfsitem);
			system($strExec,$req);
			if($req!='0')  {  
			    return false; 
			}
 
			//#################################################################
			//#	Modify snapshot mount point
			//#################################################################
			$req=modify_snapshot_item($o_sharename,$sharename,$md_num,$zfsitem);
                        if($req==-1){ 
				$strExec=sprintf("$mkzfs set mountpoint='%s' '%s' >> /tmp/zfslog.log 2>&1",$o_mountpoint,$zfsitem);
				shell_exec($strExec);
				$strExec=sprintf("$mkzfs mount '%s' >> /tmp/zfslog.log 2>&1",$zfsitem);
				shell_exec($strExec);

			        $old_snap_path="/raid/snapshot/${o_sharename}";
        if($o_sharename != "" && is_dir($old_snap_path)){
				  $strExec="/bin/rm -rf '$old_snap_path'";
				shell_exec($strExec);
        }
			        return false;  
                        }else{
        if($o_sharename != "" && is_dir($o_mountpoint)){
				  $strExec="/bin/rm '$o_mountpoint' -rf";
				shell_exec($strExec);
        }
                        } 
			break;
		case "ext4":
		case "ext3":
		case "xfs":
		default:
			if (NAS_DB_KEY == '1'){
               			$o_path="/raid".($md_num-1)."/data/".$o_sharename;
                		$path="/raid".($md_num-1)."/data/".$sharename;
            		}elseif (NAS_DB_KEY == '2'){
                		$o_path="/raid".($md_num)."/data/".$o_sharename;
			    	$path="/raid".($md_num)."/data/".$sharename;
			}
	    	
            		$strExec="/bin/mv '$o_path' '$path'";
  	  		shell_exec($strExec);
			break;
	}
        return true;
}

function modify_folder_quota($sharename,$quota_limit,$md_num) {  
	global $fsmode,$mkzpool,$mkzfs,$zfsname;
	switch ($fsmode) {
		case "zfs":
			$zfspoolname=sprintf("zfspool%d",$md_num-1);
			$zfsitem=sprintf("%s/%s",$zfspoolname,$zfsname);
			if($quota_limit=="0"){
				$strExec=sprintf("$mkzfs set quota=none '%s' > /tmp/zfslog.log 2>&1",$zfsitem);
			}else{
				$strExec=sprintf("$mkzfs set quota=%sg '%s' > /tmp/zfslog.log 2>&1",$quota_limit,$zfsitem);
			} 
			shell_exec($strExec);
			break;
		case "ext4":
		case "ext3":
		case "xfs":
		default:
			if (NAS_DB_KEY == '1')
                $path="/raid".($md_num-1)."/data/".$sharename;
            elseif (NAS_DB_KEY == '2')
                $path="/raid".($md_num)."/data/".$sharename;
            
	    		$quota_limit=$quota_limit * 1024;
	    		$strExec="(/img/bin/managefolder.sh -m '" . $path . "' " . $quota_limit . " >/dev/null 2>&1) &";
	    		shell_exec($strExec);
			break;
	}
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
