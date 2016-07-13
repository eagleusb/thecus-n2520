<?php
require_once(WEBCONFIG);
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');

$words = $session->PageCode("share");
$rwords = $session->PageCode("raid");
$aswords = $session->PageCode("addshare");
$mswords = $session->PageCode("modshare");
$dwords = $session->PageCode("schedule");
$awords = $session->PageCode("acl");
$swords = $session->PageCode("snapshot");
$nwords = $session->PageCode("nsync");
$gwords = $session->PageCode("global");

$words['nfs_norootsquash'] = str_replace("<br>",' ',$words['nfs_norootsquash']);
$words['nfs_rootsquash'] = str_replace("<br>",' ',$words['nfs_rootsquash']);
$words['nfs_allsquash'] = str_replace("<br>",' ',$words['nfs_allsquash']); 
                          
/**************** request parameter *********************/
$tree = initWebVar('tree');  
$store=$_REQUEST["store"]; 
$sharename=$_REQUEST["share"]; 
$md_num=$_REQUEST["md"]; 
$model_name=trim(shell_exec("awk '/^MODELNAME/{print $2}' /proc/thecus_io"));  
get_sysconf();
$winad=$sysconf["winad"] | $sysconf["ldap"];

/*****************************************
    load root folder
******************************************/
function getRootFolder(){
  require_once(INCLUDE_ROOT.'nsync.class.php');
  global $md_num;
  global $validate;
  
    $nsync_task=new nsync();
    $nsync_data=$nsync_task->GetNsyncList();
    $i=0;
    foreach($nsync_data as $k=>$v){
      if(isset($nsync_data[$k]['folder']))
        $all_nsync_task =$all_nsync_task ."all_nsync_task[$i]=\"".urlencode($nsync_data[$k]['folder'])."\";\n";
      $i++;
    } 
     
    $quota_count=0;
    $nasmusic="_NAS_Media";
    $raid_class=new RAIDINFO();
    $md_array=$raid_class->getMdArray(); 
    $folder_list = array();
    $acl_md_lock = trim(shell_exec("/img/bin/acl_backup.sh 'get_lock_md_info'"));
    foreach($md_array as $num){
      if($num==$acl_md_lock)
          continue;
      if (NAS_DB_KEY == '1'){          
        $database="/raid".($num-1)."/sys/raid.db";
        $strExec="/bin/mount | grep '/raid".($num-1)."/data'";
        $raid_data_result=shell_exec($strExec);
      }else{
        $database="/raid".($num)."/sys/smb.db"; 
        $strExec="/bin/mount | grep '/raid".$num."'";
        $raid_data_result=shell_exec($strExec);
      }
      if($raid_data_result!=""){   
        $db = new sqlitedb($database,'conf'); 
        $raid_id=$db->getvar("raid_name");
        $ismaster=$db->getvar("raid_master");
        $file_system=$db->getvar("filesystem");
        if(!$file_system)
            $file_system='ext3';
        if (NAS_DB_KEY == '1'){
          $db_list=$db->db_getall("folder");
        }else
        {
          $db_lista=$db->db_getall("smb_specfd");
          $db_listb=$db->db_getall("smb_userfd");
          if($db_listb != 0){
            $db_list=array_merge($db_lista,$db_listb);
          }else{
            $db_list=$db_lista;
          }
        }
        foreach($db_list as $k=>$list){
          if($list!=""){
            
            // hide special system folder
            if($validate->hide_system_folder($list["share"])){
            continue; 
            }
            $tag['share']=addslashes($list["share"]);
            
            /**
            * Modify by Heidi
            * Desc: 
            * If share folder is not master RAID folder, then skip system folder display in UI 
            */
            //check master RAID folder
            if($ismaster!=1)  
            { 
              //check system folder
              if($validate->in_system_folder(trim($list['share'])))
              {
                continue;
              }
            }
            
            if (NAS_DB_KEY == '1'){
                $readonly=$list["v1"];
            }else{
                $readonly=$list["readonly"];
            }
            
            $speclevel=$list["speclevel"];
            
            $tag['md_num']=$num;
            if (NAS_DB_KEY == '1'){
              $tag['path']="/raid".($num-1).'/data/'.$list["share"];
            }else{
              $tag['path']="/raid".($num).'/data/'.$list["share"];
            }
            $tag['raidid']=trim($raid_id);
            $tag['share_title']=mb_abbreviation(str_replace(" ","&nbsp;",$list["share"]),50,1);
            $tag['share_tip']=$list["share"];
            $tag['enc_share']=urlencode($list["share"]);
            $tag['comment_tip']=$list["comment"];
            $comment=stripslashes($list["comment"]);
            $tag['comment_all']=$comment; 
            $tag['comment']=mb_abbreviation($comment,15,1); 
            $tag['file_system']=trim($file_system);
            $tag['readonly']=trim($readonly);
            $tag['speclevel']=trim($speclevel);
            $quota_percent='';

            if($file_system == "zfs"){
              $tag['nfs_disable']="0";
              $tag['zfs_disable']="1";
              $tag['snapshot_disable']="1";
                $strExec = "/usr/bin/zfs list|grep \"/raid".($num-1)."/data/".$list['share']."\" |awk '{print $1}'";
              $zfspoolname=trim(shell_exec($strExec));
              if ($list['quota_limit']>0) {
                $strExec="/usr/bin/zfs get -Hp used,available -o value \"$zfspoolname\"";
                $getusage=trim(shell_exec($strExec));
                list($quota_usage,$zfs_avariable)=explode("\n",$getusage);
                $quota_usage=round($quota_usage/1024/1024/1024,1);
                $quota_percent=$quota_usage . " GB/ " . number_format($list['quota_limit']) . " GB (" . number_format($quota_usage * 100 / $list['quota_limit']) . "%)";
              }
            }elseif($file_system =="btrfs"){
              $tag['nfs_disable']="1";
              $tag['zfs_disable']="0";
              $no_snapshot_folder=array('esatahdd','_nas_module_source_','_p2p_download_','sys','tmp','lost+found','ftproot','dlnamedia','module','_sys_tmp','nsync','usbhdd','usbcopy','snapshot');
              $result = array_search(strtolower($list['share']),$no_snapshot_folder);
              if($result!=NULL && $result!==false)
                $tag['snapshot_disable']="0";
              else
                $tag['snapshot_disable']="1";
  
              $strExec = "/usr/bin/zfs list|grep \"/raid".($num-1)."/data/".$list['share']."\" |awk '{print $1}'";
              $zfspoolname=trim(shell_exec($strExec));
              if ($list['quota_limit']>0) {
                $strExec="/usr/bin/zfs get -Hp used,available -o value \"$zfspoolname\"";
                $getusage=trim(shell_exec($strExec));
                list($quota_usage,$zfs_avariable)=explode("\n",$getusage);
                $quota_usage=round($quota_usage/1024/1024/1024,1);
                $quota_percent=$quota_usage . " GB/ " . number_format($list['quota_limit']) . " GB (" . number_format($quota_usage * 100 / $list['quota_limit']) . "%)";
              }
            }else{
                 $tag['nfs_disable']="1";
                 $tag['zfs_disable']="0"; 
                 $tag['snapshot_disable']="0";
                 $raid_num=$num-1;  
                 $aryin=file("/tmp/qtamgn");  
                 foreach ($aryin as $line) {  
                    $strfolder=trim(strstr($line,"/raid"));  
                    $aryqt=preg_split("/[ \t]+/",$line);  
                    $chkfolder=trim("/raid" . $raid_num . "/data/" .$list["share"]);   
                    if (strcmp($strfolder,$chkfolder)==0) {   
                      $quota_limit=$aryqt[1];  
                      $quota_usage=$aryqt[2];  
                      $quota_limit=$quota_limit/1024; 
                      $quota_usage=round($quota_usage/1024,1);  
                      if ($quota_limit>0)   
                        $quota_percent=$quota_usage." GB/ ".number_format($quota_limit)." GB (".number_format($quota_usage * 100 / $quota_limit)."%)";   
                    }  
                  }  
            }
            
            
            /**
            * Modify by Heidi
            * Desc: 
            * Check share folder attribute, if is system folder then disable to edit and delete. 
            */
            if($validate->in_system_folder(trim($list['share'])))
            {
              $tag['share_delete']="0";
            }
            else
            {
              $tag['share_delete']="1";
            }
            
            $tag['quota_usage']=$quota_usage; 
            $tag['quota_percent']=$quota_percent;
            $tag['quota_limit']=$list['quota_limit'];
            
            // set quota
            if($tag['quota_limit']>0){
              $quota_count++;
              $quota_limit_gb="<span style=\"color:green\">".$list['quota_limit']." GB</span>";
            }else{
              $quota_limit_gb="---";
            }
            
            $tag['quota_limit_gb']=$quota_limit_gb;
            $tag['browseable']=$list['browseable'];
            if (NAS_DB_KEY == '1')
              $tag['guest_only']=$list['guest_only'];
            elseif (NAS_DB_KEY == '2')
              $tag['guest_only']=$list['guest only'];
              
            $tag['uiProvider']='col';
            $tag['rootfolder']='1';
            $tag['desc']=$tag['comment']; 
            $tag['desc_all']=$tag['comment_all']; 
            $tag['usb']=($list['share']=='usbhdd')?'1':'0'; 
            
            array_push($folder_list,$tag); 
          }
        }
      }
    }
    unset($db);
    $total = count($folder_list);
    for($i=0;$i<$total;$i++){
      $folder_list[$i]["quota_count"]=$quota_count;
    }
    return $folder_list;
}


switch($tree){
  /*****************************************
      load root share foloder
  ******************************************/
  case "rootfolder":
    $ary = getRootFolder();
    die(json_encode($ary));
    break;
    
  /*****************************************
      get current share folder that has setted quota
  ******************************************/
  case "quota":
    $folder = getRootFolder();
    $quota_count = $folder[1]["quota_count"];
    $ary = array("quota_count"=>$quota_count);
    die(json_encode($ary));
    break;
    
  /*****************************************
      load sub share foloder
  ******************************************/
  case "subfolder":
    $dir = ''; 
    $node = $_REQUEST['path']; 
    $d = dir($dir.$node);
    $is_usb=0;
    $sf_len=0;
    if($node!=''){
      $sf_name=explode('/',$node);
      $sf_len=count($sf_name);
      if($sf_name[3]=='usbhdd')
        $is_usb=1;
    }
    while($f = $d->read()){
      if($f == '.' || $f == '..' || substr($f, 0, 1) == '.')continue;
      $lastmod = date('M j, Y, g:i a',filemtime($dir.$node.'/'.$f));  
      if(is_dir($dir.$node.'/'.$f)){  
        $is_leaf=false;
      }else{
        $is_leaf=true;
      }

         $nodes[] = array('share'=>$f, 
                            'share_title'=>$f,
                            'id'=>$node.'/'.$f, 
                            'usb'=>$is_usb, 
                            'len'=>$sf_len, 
  
                            'path'=>$node.'/'.$f, 
                            'zfs'=>$_REQUEST['zfs'],                             
                            'guest_only'=>$_REQUEST['guest_only'],                             
                            'speclevel'=>$_REQUEST['speclevel'],
                            'desc'=>'', 
                            'status'=>'-', 
                            'uiProvider'=>'col',
                        'leaf'=>$is_leaf,
                            'rootfolder'=>'0');
            } 
   
    $nodes=array_sort($nodes,'share','SORT_ASC');
       $d->close();
       die(json_encode($nodes));
    break;
}

 
 
/*****************************************
    load nfs store
******************************************/
if($store=='nfs_store'){
    $nfs_list_ary = array();
    
    //check zfs
    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select v from conf where k='filesystem'\"";
    }else{
      $strExec="/usr/bin/sqlite /raid".($md_num)."/sys/smb.db \"select v from conf where k='filesystem'\"";
  }
    $filesystem=trim(shell_exec($strExec));
    if($filesystem=="zfs"){
       die("ok");  
    } 

    if (NAS_DB_KEY == '1'){
      $strExec="/usr/bin/sqlite /raid".($md_num-1)."/sys/raid.db \"select * from nfs where share='\"".addcslashes($sharename, '$')."\"'\"";
    }else{
      $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select * from nfs where share='\"".addcslashes($sharename, '$')."\"'\"";
  }
    
    $nfs_list=shell_exec($strExec);
    $nfs_list_array=explode("\n",$nfs_list);
    foreach($nfs_list_array as $list){
          if($list!=""){
                $nfs_info=explode("|",trim($list));
                $map_value = $nfs_info[3];
      if (NAS_DB_KEY == '1'){
                ($nfs_info[4]=="0" || $nfs_info[4]=="")?$os_value="0":$os_value=$nfs_info[4];
                ($nfs_info[4]=="0" || $nfs_info[4]=="")?$nfs_info[4]=$words["nfs_linux"]:$nfs_info[4]=$words["nfs_aix"];
      }else{
        ($nfs_info[4]=="secure" || $nfs_info[4]=="")?$os_value="secure":$os_value=$nfs_info[4];
        ($nfs_info[4]=="secure" || $nfs_info[4]=="")?$nfs_info[4]=$words["nfs_linux"]:$nfs_info[4]=$words["nfs_aix"];
        ($nfs_info[5]=="sync" || $nfs_info[5]=="")?$sync_value="sync":$sync_value=$nfs_info[5];
      }
    if($nfs_info[3]=="root_squash"){
                        $nfs_info[3]=$words["nfs_rootsquash"];
                }elseif($nfs_info[3]=="no_root_squash"){
                        $nfs_info[3]=$words["nfs_norootsquash"];
                }else{
                        $nfs_info[3]=$words["nfs_allsquash"];
                }
                $priv = ($nfs_info[2]=="ro")?$gwords["readonly"]:$gwords["writable"];
                $nfs_list_ary[]=array('hostname'=>$nfs_info[1],
                                  'privilege_words'=>$priv,
                                  'privilege'=>$nfs_info[2],
                                  'os'=>$nfs_info[4], 
                                  'map'=>$nfs_info[3],
                                  'os_value'=>$os_value, 
                        'map_value'=>$map_value, 
                        'sync_value'=>$sync_value);
                
         }
    }

    require_once(INCLUDE_ROOT.'raid.class.php'); 
    $masterRaid = raid::getMasterRaid(); 
    $nfs_mount_point = sprintf('NFS3 %s: /%s/data/_NAS_NFS_Exports_/%s<br>NFS4 %s: /%s', 
        $words['nfs_point'], 
        $masterRaid, 
        $sharename, 
        $words['nfs_point'], 
        $sharename);
    
    $nfs_list_ary[] = array("nfs_mount_point"=>$nfs_mount_point);
    die(json_encode($nfs_list_ary));   
}

/*****************************************
    load snapshot store
******************************************/
if($store=='snapshot_store'){
   $snapshot_list = array();
   if (NAS_DB_KEY == '1'){
     $raid="raid".($md_num-1);
   $strExec="/usr/bin/zfs list | grep \"/raid/snapshot/${sharename}/\" | awk -F '/' '{printf(\"%s|%s|%s|%s|%s|%s\\n\",$1,$2,$4,$5,$6,$7)}'";
   $sntable=shell_exec($strExec);
   $arysntabl=explode("\n",$sntable);
   $arysn=array();
   foreach ($arysntabl as $line) {
      if($line != ""){
         $aryline=explode("|",$line);
         $date=explode("-",trim($aryline[5]));
         $year=substr($date[0],0,4);
         $month=substr($date[0],4,2);
         $day=substr($date[0],6,2);
         $hour=substr($date[1],0,2);
         $min=substr($date[1],2,2);
         $sec=substr($date[1],4,2);
         $snap_date="${year}/${month}/${day} ${hour}:${min}:${sec}";
         array_push($snapshot_list,array('snap_date'=>$snap_date,
                                         'share_date'=>trim($aryline[5]),
                                         'zfs_pool'=>$aryline[0],
                                         'zfs_share'=>$aryline[1]
                                         ));
      }
   }
  }else{
    $raid="raid".($md_num);
    $strExec="ls /raid/data/snapshot/${sharename}/";
    $sntable=shell_exec($strExec);
    $arysntabl=explode("\n",$sntable);
    $arysn=array();
    foreach ($arysntabl as $line) {
      if($line != ""){
         $aryline=$line;
         $date=explode("-",trim($aryline));
         $year=substr($date[0],0,4);
         $month=substr($date[0],4,2);
         $day=substr($date[0],6,2);
         $hour=substr($date[1],0,2);
         $min=substr($date[1],2,2);
         $sec=substr($date[1],4,2);
         $snap_date="${year}/${month}/${day} ${hour}:${min}:${sec}";
         array_push($snapshot_list,array('snap_date'=>$snap_date,
                                         'share_date'=>trim($aryline),
                                         'zfs_pool'=>"",
                                         'zfs_share'=>${sharename}
                                         ));
      }
    }
  }
   die(json_encode($snapshot_list));
   
}



/*****************************************
    load schedule store 
******************************************/
if($store=='schedule_store'){ 
  if (NAS_DB_KEY == '1'){
    $raid="raid".($md_num-1);
   $snapshot_list = array();
   $strExec="/usr/bin/zfs list | grep \"/raid/snapshot/${sharename}/\" | awk -F '/' '{printf(\"%s|%s|%s|%s|%s|%s\\n\",$1,$2,$4,$5,$6,$7)}'";
   $sntable=shell_exec($strExec);
   $arysntabl=explode("\n",$sntable);
   $arysn=array();
   foreach ($arysntabl as $line) {
      if($line != ""){
         $aryline=explode("|",$line);
         $date=explode("-",trim($aryline[5]));
         $year=substr($date[0],0,4);
         $month=substr($date[0],4,2);
         $day=substr($date[0],6,2);
         $hour=substr($date[1],0,2);
         $min=substr($date[1],2,2);
         $sec=substr($date[1],4,2);
         $snap_date="${year}/${month}/${day} ${hour}:${min}:${sec}";
         array_push($snapshot_list,array('snap_date'=>$snap_date,
                                         'share_date'=>trim($aryline[5]),
                                         'zfs_pool'=>$aryline[0],
                                         'zfs_share'=>$aryline[1]
                                         ));
      }
   }
  }else{
    $raid="raid".($md_num);
    $strExec="ls \"/raid/data/snapshot/${sharename}/\"";
    $snapshot_list = array();
    $sntable=shell_exec($strExec);
    $arysntabl=explode("\n",$sntable);
    $arysn=array();
    foreach ($arysntabl as $line) {
      if($line != ""){
        $aryline=$line;
        $date=explode("-",trim($aryline));
        $year=substr($date[0],0,4);
        $month=substr($date[0],4,2);
        $day=substr($date[0],6,2);
        $hour=substr($date[1],0,2);
        $min=substr($date[1],2,2);
        $sec=substr($date[1],4,2);
        $snap_date="${year}/${month}/${day} ${hour}:${min}:${sec}";
        array_push($snapshot_list,array('snap_date'=>$snap_date,
                                       'share_date'=>trim($aryline),
                                       'zfs_pool'=>"",
                                       'zfs_share'=>${sharename}
                                       ));
      }
    }
  }
   
   
  if (NAS_DB_KEY == '1'){
    $strExec="/usr/bin/zfs list | grep '/${raid}/data/${sharename}$' | awk '{print $1}'";
    $snapshot_info=explode("/",trim(shell_exec($strExec)));
    $zfs_pool=trim($snapshot_info["0"]);
    $zfs_share=trim($snapshot_info["1"]);
  }else{
    $strExec="ls -al '/${raid}/data/${sharename}$' | awk '{print $1}'";
    $zfs_share=$sharename;
  }
    
  $database="/$raid/sys/snapshot.db";
  $db = new sqlitedb($database);   
   
  $autodel=$db->db_get_single_value('snapshot',"autodel","where zfs_share='${zfs_share}'");
  if(!$autodel){
    $autodel="0";
  }
  $enabled=$db->db_get_single_value('snapshot',"enabled","where zfs_share='${zfs_share}'"); 
  if(!$enabled){
    $enabled="0";
  }
  $rule=$db->db_get_single_value('snapshot',"schedule_rule","where zfs_share='${zfs_share}'");
  if(!$rule){
    $rule="m";
  }
  $day=$db->db_get_single_value('snapshot',"day","where zfs_share='${zfs_share}'");
  $week=$db->db_get_single_value('snapshot',"week","where zfs_share='${zfs_share}'");
  $hour=$db->db_get_single_value('snapshot',"hour","where zfs_share='${zfs_share}'");
  unset($db);
    $ary = array('autodel'=>$autodel,
                 'enabled'=>$enabled,
                 'rule'=>$rule,
                 'rulevalue'=>$rulevalue,
                 'day'=>$day,
                 'week'=>$week,
                 'hour'=>$hour 
                 );
    die(json_encode(array('snapshot'=>$snapshot_list,'schedule'=>$ary)));
}



$snap_title=sprintf($swords["snap_title"],$sharename);
$snap_description=sprintf($swords["snap_description"],$_SERVER[SERVER_ADDR]);  
$raid_class=new RAIDINFO();
$md_array=$raid_class->getMdArray(); 
 
$open_mraid=trim(shell_exec("/img/bin/check_service.sh m_raid"));
/*************************************
      combobox RAID value
**************************************/
$combo_value = ' [ ';
if($open_mraid=='1'){
  $i=0;
  foreach($md_array as $num){
    if (NAS_DB_KEY == '1'){
      $strExec="/bin/mount | grep '/raid".($num-1)."/data'";
    }else{
      $strExec="/bin/mount | grep '/raid".($num)."'";
    }
    $raid_data_result=shell_exec($strExec);
    if($raid_data_result=='')continue;

    if (NAS_DB_KEY == '1'){
      $database="/raid".($num-1)."/sys/raid.db";
    }else{
      $database="/raid".($num)."/sys/smb.db";
    }
    $db = new sqlitedb($database,'conf');  
    $raid_id=$db->getvar("raid_name");
    $file_system=$db->getvar("filesystem");
    if(!$file_system)
      $file_system='ext3';
    unset($db); 
    $combo_value .=" ['$num,$file_system','$raid_id'],";
    if($i==0){
      $md_num_default = $num;
      $file_system_default = $file_system;
      $i++;
    }
  }
  $combo_value = substr($combo_value,0,-1);
}else{
  if (NAS_DB_KEY == '1'){
    $database="/raid0/sys/raid.db";
  }else{
    $database="/raid0/sys/smb.db";
  }
  $db = new sqlitedb($database,'conf');
  $raid_id=$db->getvar("raid_name");
  $file_system=$db->getvar("filesystem");
  if(!$file_system)
     $file_system='ext3';
  unset($db); 
  $file_system_default = $file_system;
}
$combo_value .= ' ] ';


/*************************************
      combobox RAID value
**************************************/
$combo_fields="['value','display']";

/*************************************
      combobox ACL mode
**************************************/                                 
$acl_combo_value = " [['local_group','".$awords["localGroup"]."'],
                      ['local_user','".$awords["localUser"]."']";

if ($winad == '0'){
    $acl_combo_value .= "]";
}else{
    $acl_combo_value .= ",
                      ['ad_group','".$awords["adGroup"]."'],
                      ['ad_user','".$awords["adUser"]."']]";
}
                      
/*************************************
      combobox date
**************************************/  
$combo_date = '[';
for($d=1;$d<=31;$d++){
  $combo_date.="['$d','$d'],";
}
$combo_date = substr($combo_date,0,-1).']'; 

/*************************************
      combobox time
**************************************/  
$combo_time = '[';
for($t=0;$t<=23;$t++){
  $combo_time.="['$t','$t'],";
}
$combo_time = substr($combo_time,0,-1).']'; 

/*************************************
      combobox week
**************************************/  
$combo_week="[";
$week_day_list=array("0"=>$gwords['sunday'],"1"=>$gwords['monday'],"2"=>$gwords['tuesday'],"3"=>$gwords['wednesday'],"4"=>$gwords['thursday'],"5"=>$gwords['friday'],"6"=>$gwords['saturday']);
foreach($week_day_list as $k=>$v) {
  if ($week==$k) {
    $tpl->assign('combo_week_select',$k);
  }
   $combo_week.="['$k','$v'],"; 
}
$combo_week = substr($combo_week,0,-1).']';  

/*************************************
      check snapshot
************************************/
$show_snapshot='0';
if($sysconf["zfs_snapshot"]>0 || $sysconf["btrfs_snapshot"]>0){
     $show_snapshot='1'; 
}

if (NAS_DB_KEY=="1"){
    $share_limit_hidden='false';
}else if (NAS_DB_KEY=="2"){
    $share_limit_hidden='true';
}

function array_sort($array, $on, $order='SORT_DESC'){ 
  $new_array = array(); 
  $sortable_array = array(); 
  
  if (count($array) > 0) { 
    foreach ($array as $k => $v) { 
      if (is_array($v)) { 
        foreach ($v as $k2 => $v2) { 
          if ($k2 == $on) { 
            $sortable_array[$k] = $v2; 
          } 
        } 
      } else { 
        $sortable_array[$k] = $v; 
      } 
    } 
  
    switch($order) 
    { 
      case 'SORT_ASC':    
        asort($sortable_array); 
        break; 
      case 'SORT_DESC': 
        arsort($sortable_array); 
        break; 
    } 
  
    foreach($sortable_array as $k => $v) { 
      $new_array[] = $array[$k]; 
    } 
  } 
  
  return $new_array; 
} 
$smbservice = check_samba_service();
$show_nfs = trim(shell_exec("/img/bin/check_service.sh 'nfs'"));

$tpl->assign('smbservice',$smbservice);

$tpl->assign('show_nfs',$show_nfs);
$tpl->assign('show_snapshot',$show_snapshot);

$tpl->assign('combo_date',$combo_date);
$tpl->assign('combo_time',$combo_time);
$tpl->assign('combo_week',$combo_week);

$tpl->assign('words',$words);
$tpl->assign('rwords',$rwords);
$tpl->assign('aswords',$aswords);
$tpl->assign('dwords',$dwords);
$tpl->assign('swords',$swords);
$tpl->assign('gwords',$gwords);
$tpl->assign('nwords',$nwords);
$tpl->assign('awords',$awords);
$tpl->assign('mswords',$mswords);

$tpl->assign('expand',$_REQUEST['expand']);
$tpl->assign('open_mraid',$open_mraid);
$tpl->assign('acl_combo','local_group');
$tpl->assign('combo_fields',$combo_fields);
$tpl->assign('md_num_default',$md_num_default);
$tpl->assign('file_system_default',$file_system_default);
$tpl->assign('combo_value',$combo_value);
$tpl->assign('zfs_snapshot',$sysconf["zfs_snapshot"]);
$tpl->assign('acl_combo_value',$acl_combo_value);
$tpl->assign('snap_title',$snap_title);
$tpl->assign('snap_description',$snap_description);
$tpl->assign('acl_url','getmain.php?fun=acl');
$tpl->assign('get_url','getmain.php?fun=share');
$tpl->assign('set_url','setmain.php?fun=setshare');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY);
$tpl->assign('model_name',$model_name);
$tpl->assign('share_limit_hidden',$share_limit_hidden);
$tpl->assign('lang',$session->lang);
$tpl->assign('quota_folder_limit',$webconfig['quota_folder_limit']); 
$tpl->assign('winad',$winad);
?>
