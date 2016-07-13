<?php
require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("DLNA");
$gwords = $session->PageCode("global");

//in 3800, the path of shared folder is only two levels; in 5200, it is three levels
    $strExec="ls -l /raid/|awk -F\/ '/data/&&/raid/{print substr($2,5)+1}'|head -1";
    $mmdnum=trim(shell_exec($strExec));
    $mraidnum=$mmdnum-1;

if (NAS_DB_KEY==1){
    $srv_lists = trim(shell_exec("awk -F'://' '/sync.folder/{print substr(\$2,0,length(\$2)-1)}' /raid/data/dlnamedia/etc/mediaserver.conf"));
}
else{
    $srv_lists = trim(shell_exec("awk -F'://' '/sync.folder/{print substr(\$2,0,length(\$2)-1)}' /etc/mediaserver.conf"));
}
    

if (strlen($srv_lists) > 0){
    $srv_lists = explode("\n",$srv_lists);
}else{
    $srv_lists = array();
}


$srv_list = array();
$IMSyncManager=file_get_contents('http://127.0.0.1:8080/mdiag/sysobjs?sysname=IMSyncManager');
if (preg_match_all('/<th>Operations<\/th><\/tr><tr><td>(\d+)<\/td><td align=center>(.*?)\/<\/td>/',$IMSyncManager,$matches)){
    $srv_id_list=$matches[2];
    $srv_lista=array();
    foreach($srv_id_list as $id=>$v){
        foreach($srv_lists as $path){
            $path_array=explode("/",$path);
            $path_tmp=trim($path_array[3]);
            if($path!="" && $v==$path_tmp){
                $srv_list[$id]=$path;
                break;
            }
        }
    }
}


if (NAS_DB_KEY==1)
{
    $share_list = trim(shell_exec("awk -F[\=][\ ] '/^path/&&!(/^path = \/raid\/stackable\//){printf(\"%s\\n\",$2)}' /tmp/smb.conf"));
    $except_list = array("/raid" . $mraidnum . "/data/usbhdd","/raid" . $mraidnum . "/data/nsync","/raid/snapshot");
}
else
{
    $share_list = trim(shell_exec("awk -F[\=][\ ] '/^path/{printf(\"%s\\n\",$2)}' /etc/samba/smb.conf"));
    $except_list = array("/raid" . $mraidnum . "/data/USBHDD","/raid" . $mraidnum . "/data/nsync","/raid" . $mraidnum . "/data/usbhdd");
}
    
$share_list = explode("\n",$share_list);
$share_list = array_diff($share_list, $except_list);

$ar_share = array();
$ar_share = array_intersect($share_list,$srv_list);

$folderStore="[";

foreach ($share_list as $share_folder){
    $media_st_1="";
    unset($m_folder_st);
    foreach($ar_share as $m_folder){
        if($share_folder==$m_folder)
        {
            $m_folder_st = $m_folder;
            break;
        }
    }
    
    //$media_st_1=array_search($share_folder,$srv_list);

    $share_folder1=str_replace("+","%2B",$share_folder);
    foreach($srv_list as $k=>$v){
        if($v == $share_folder){
            $media_st_1=$k;
            break;
        }
    }

    $foldername=explode("/",$share_folder);
    $foldername=$foldername[3];
    
   
   
    // hide special system folder
    if($validate->hide_system_folder($foldername)){
        continue;
    }

    if($share_folder==$m_folder_st)
    {
        $folderStore .= "['true','$foldername','$share_folder','$media_st_1'],";
    }
    else
    {
        $folderStore .= "['false','$foldername','$share_folder','-1'],";
    }
}

$folderStore = substr($folderStore, 0, strlen($folderStore)-1);
$folderStore .= "]";

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$db=new sqlitedb();
$DLNA_Status = $db->getvar("DLNA_server","0");
unset($db);

$tpl->assign('words',$words);
$tpl->assign('DLNA_Status',$DLNA_Status);  
$tpl->assign('share_list',$share_list);  
$tpl->assign('ar_share',$ar_share);  
$tpl->assign('folderStore',$folderStore);  
$tpl->assign('form_action','setmain.php?fun=setDLNA');

?>

