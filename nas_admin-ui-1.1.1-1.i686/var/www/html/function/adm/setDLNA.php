<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once('../../function/conf/localconfig.php');

$words = $session->PageCode("DLNA");

$folderAction=$_REQUEST['folderAction'];
$folder=$_REQUEST['folder'];
$sharedID=$_REQUEST['sharedID'];

$ms_enable=$_REQUEST['ms_enable'];
$_server=$_REQUEST['_server'];
$returnmsg="";
if ($ms_enable=='1')
{
    $db=new sqlitedb();
    if ($_server=='1')
    {
        shell_exec('/img/bin/rc/rc.DLNA restart > /dev/null 2>&1 &');
        
        $DLNA_Status = $db->setvar("DLNA_server", 1);
        $returnmsg = $words['DLNA_Enable'];
        unset($db);
        
    }
    
    if ($_server=='0')
    {
        shell_exec('/img/bin/rc/rc.DLNA stop > /dev/null 2>&1 &');
        
        $DLNA_Status = $db->setvar("DLNA_server", 0);
        $returnmsg = $words['DLNA_Disable'];
        unset($db);
        //return  MessageBox(true,$words['DLNA_title'],$words['DLNA_Disable']); 
    }
}
else
{
    if ($folderAction == '0')
    {
        Sync_Remove($sharedID, $folder);
        $returnmsg = $words['share_remove'];
        //return  MessageBox(true,$words['share_me'],$words['share_remove']); 
    }

    if ($folderAction == '1')
    {
        Sync_Add($folder);
        $returnmsg = $words['share_add'];
        //return  MessageBox(true,$words['share_me'],$words['share_add']); 
    }

    if ($folderAction == '2')
    {
        Sync_Rescan($sharedID, $folder);
        $returnmsg = $words['share_rescan'];
        //return  MessageBox(true,$folder,$sharedID);
        //return  MessageBox(true,$words['share_me'],$words['share_rescan']); 
    }
}

    sleep(2);
    //*********************************************************************
    //refresh the data store of the media server's shared folder
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

    $folderStore="";

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

        if($share_folder==$m_folder_st)
            $folderStore .= "true,$foldername,$share_folder,$media_st_1,";
        else
            $folderStore .= "false,$foldername,$share_folder,-1,";
    }

    $folderStore = substr($folderStore, 0, strlen($folderStore)-1);
    
    die(json_encode(array('folderData'=>$folderStore,
                          'msgStr'=>$returnmsg
    )));

function Sync_Add($share_folder){
    global $words;
    
    $share_folder=urldecode($share_folder);
    $share_folder1=str_replace('%2B','+',$share_folder);
    $cmd_add = 'mkdir /tmp/dlna;cd /tmp/dlna;';
    $cmd_add .= '/usr/bin/wget "http://127.0.0.1:8080/mdiag/sysobjs?';
    $cmd_add .= 'sysname=IMSyncManager&idx=0&oper=Add+URL:&arg='.urlencode($share_folder1);
    $cmd_add .= '" > /dev/null 2>&1;rm -rf /tmp/dlna';

    shell_exec($cmd_add);

    sleep(1);
    $share_folder_tmp=explode("/",$share_folder);
    $share_folder=$share_folder_tmp[3];
    $share_folder=str_replace('%2B','\+',$share_folder);
    $IMSyncManager=file_get_contents('http://127.0.0.1:8080/mdiag/sysobjs?sysname=IMSyncManager');

    if (preg_match('/<th>Operations<\/th><\/tr><tr><td>(\d+)+<\/td><td align=center>'.$share_folder.'\/<\/td>/',$IMSyncManager,$matches)){
        $share_id=$matches[1]-1;
    }

    
    $cmd_rescan = 'mkdir /tmp/dlna;cd /tmp/dlna;';
    $cmd_rescan .= '/usr/bin/wget "http://127.0.0.1:8080/mdiag/sysobjs?';
    $cmd_rescan .= 'sysname=IMSyncManager&idx=0&oper=Update:&arg=compare&subidx='.$share_id;
    $cmd_rescan .= '" > /dev/null 2>&1;rm -rf /tmp/dlna';
    shell_exec($cmd_rescan);

    return $share_id;
}


function Sync_Remove($share_id,$share_folder){
    global $words;

    $cmd_remove = 'mkdir /tmp/dlna;cd /tmp/dlna;';
    $cmd_remove .= '/usr/bin/wget "http://127.0.0.1:8080/mdiag/sysobjs?';
    $cmd_remove .= 'sysname=IMSyncManager&idx=0&oper=Remove&arg=1&subidx='.$share_id;
    $cmd_remove .= '" > /dev/null 2>&1;rm -rf /tmp/dlna';
    shell_exec($cmd_remove);
    sleep(1);
}

function Sync_Rescan($share_id,$share_folder){
    global $words;
    
    $cmd_rescan = 'mkdir /tmp/dlna;cd /tmp/dlna;';
    $cmd_rescan .= '/usr/bin/wget "http://127.0.0.1:8080/mdiag/sysobjs?';
    $cmd_rescan .= 'sysname=IMSyncManager&idx=0&oper=Update:&arg=compare&subidx='.$share_id;
    $cmd_rescan .= '" > /dev/null 2>&1;rm -rf /tmp/dlna';
    shell_exec($cmd_rescan);
}

?> 