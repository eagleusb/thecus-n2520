<?php
$prefix=aclbackup;
$backupcmd=IMG_BIN."/acl_backup.sh";
$words = $session->PageCode($prefix);
$act=$_REQUEST['do_act'];
$cmd=sprintf("%s 'check_lock'",$backupcmd);
$lock=trim(shell_exec($cmd));

if( $act == "check_lock"){
    if ($lock != "1") {
        $cmd=sprintf("%s 'get_result'",$backupcmd);
        $final_result=trim(shell_exec($cmd));
        list($result, $action, $icon, $word_key, $raid_name, $para1) = explode("|", $final_result);
        $msg=sprintf($words[$word_key],$raid_name,$para1);
        if ($word_key == "acl_restore_finish") {
            $msg=$msg."<br>".$words['acl_restore_desc'];
        }
        die(json_encode(array('lock'=>$lock,'result'=>$result,'icon'=>strtoupper($icon),'msg'=>$msg,'mdnum'=>$mdnum)));
    }else{
        die(json_encode(array('lock'=>$lock)));
    }
}else{
    $raid_fields="['value','display']";
    $cmd=sprintf("%s get_all_raid",$backupcmd);
    $raid_info=trim(shell_exec($cmd));
    if ($raid_info != ""){
        $raid_list=explode("|",$raid_info);
        $raid_store_data="[";
        $raid_fs="[";
        foreach($raid_list as $raid_data){
            $raid_ary=explode(",",$raid_data);
            $raid_store_data.="['".$raid_ary[0]."','".$raid_ary[1]."'],";
            $raid_fs.="'".trim($raid_ary[2])."',";
            if($raid_first == "")
                $raid_first=$raid_ary[0];
        }
        $raid_store_data = rtrim($raid_store_data,",");
        $raid_store_data.="]";
        $raid_fs = rtrim($raid_fs,",");
        $raid_fs.="]";
    }else{
        $raid_fs="[]";
        $raid_store_data="[]";
    }
    $aclbackup_folder_fields="['id','share_name']";
}
$tpl->assign('words',$words);
$tpl->assign($prefix.'_raid_fields',$raid_fields);
$tpl->assign($prefix.'_raid_data',$raid_store_data);
$tpl->assign($prefix.'_zone',$zone);
$tpl->assign($prefix.'_tmenabled',$tmenabled);
$tpl->assign($prefix.'_raid_fs',$raid_fs);
$tpl->assign('raid_first',$raid_first);
$tpl->assign('lock',$lock);
$tpl->assign('aclbackup_folder_fields',$aclbackup_folder_fields);
$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
$tpl->assign('getform_action','getmain.php?fun='.$prefix);
$tpl->assign('nas_key',NAS_DB_KEY);
?>
