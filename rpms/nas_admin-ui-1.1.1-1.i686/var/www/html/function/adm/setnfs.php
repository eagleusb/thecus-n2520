<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("nfs");
$gwords = $session->PageCode("global");

$nfsd=$_POST['_nfsd'];
$db=new sqlitedb();

if (NAS_DB_KEY==1)
    $o_nfsd=$db->getvar("httpd_nic1_nfs","0");
else
    $o_nfsd=$db->getvar("nfsd_nfsd","0");

if($nfsd == $o_nfsd){
    unset($db);
    return MessageBox(true,$gwords['nfs'],$gwords["setting_confirm"]);
}else{
    if (NAS_DB_KEY==1)
        $db->setvar("httpd_nic1_nfs",$nfsd);
    else
        $db->setvar("nfsd_nfsd",$nfsd);

    unset($db);
    $rc_path="/img/bin/rc/";
    if ($nfsd == 1){
        if (NAS_DB_KEY==1)
            shell_exec("/img/bin/rc/portmap restart > /dev/null 2>&1;/img/bin/rc/nfs restart > /dev/null 2>&1");
        else
        {
            shell_exec($rc_path."rc.nfsd restart > /dev/null 2>&1");
            shell_exec("/img/bin/logevent/event 146 &");
        }
        return MessageBox(true,$gwords['nfs'],$words["nfsdEnable"]);

    }else if ($nfsd == 0){
        if (NAS_DB_KEY==1)
            shell_exec("/img/bin/rc/portmap stop > /dev/null 2>&1;/img/bin/rc/nfs stop > /dev/null 2>&1");
        else
        {
            shell_exec($rc_path."rc.nfsd stop > /dev/null 2>&1");
            shell_exec("/img/bin/logevent/event 147 &");
        }
    
        return MessageBox(true,$gwords['nfs'],$words["nfsdDisable"]);
    }
}
