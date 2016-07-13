<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("thumbnail");
$gwords = $session->PageCode("global");

$thumbnail=$_POST['_enable'];

$db=new sqlitedb();

$o_thumbnail=$db->getvar("thumbnail","1");

if($thumbnail == $o_thumbnail){
    unset($db);
    return MessageBox(true,$words['thumbnail_title'],$gwords["setting_confirm"]);
}else{
    $db->setvar("thumbnail",$thumbnail);
    unset($db);

    if ($thumbnail == 1){
        return MessageBox(true,$words['thumbnail_title'],$words["thumbnail_enable"]);
    }else if ($thumbnail == 0){
        shell_exec("/img/bin/thumbnail.sh clean > /dev/null 2>&1");
        return MessageBox(true,$words['thumbnail_title'],$words["thumbnail_disable"]);
    }
}
