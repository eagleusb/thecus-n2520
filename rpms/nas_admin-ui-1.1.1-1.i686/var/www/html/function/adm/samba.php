<?php 
$words = $session->PageCode("httpd");
$twords = $session->PageCode("index");
$awords = $session->PageCode("advance");
$afpwords = $session->PageCode("afp");
$wan_ipv6=str_replace("\n", "", shell_exec("/img/bin/function/get_interface_info.sh get_ipv6 eth0"));
$wan_ipv6_literal=str_replace(":", "-", $wan_ipv6);
$soc=str_replace("\n", "", shell_exec("/img/bin/check_service.sh soc"));
 
$db = new sqlitedb('/etc/cfg/conf.db'); 
$cifs=$db->getvar("httpd_nic1_cifs","0"); 
$httpd_nic1_filecache=$db->getvar("httpd_nic1_filecache","0"); 
$smb_recycle=$db->getvar("advance_smb_recycle","0"); 
$smb_restrict_anonymous=$db->getvar("advance_smb_restrict_anonymous","0");
$smb_dataago=$db->getvar("smb_dataago","0");
$smb_maxsize=$db->getvar("smb_maxsize","0");
$recycle_display=$db->getvar("recycle_display","0");

if(NAS_DB_KEY==1){
 $smb_localmaster=$db->getvar("advance_smb_localmaster","1");
 $smb_unix=$db->getvar("advance_smb_unix_exten","1");
 $smb_signing=$db->getvar("advance_smb_signing","0");
 $tpl->assign('smb_signing',$smb_signing);
}else{
 $smb_localmaster=$db->getvar("advance_smb_localmaster","1");
 $smb_unix=$db->getvar("advance_smb_unix_exten","0");
 $smb_trusted=$db->getvar("advance_smb_trusted","0");
}
$smb_receivefile_size=$db->getvar("advance_receivefile_size","1");
$smb_blocksize=$db->getvar("advance_smb_blocksize","1");

//Fix the file bigger in issue 4256
$strExec="/img/bin/check_service.sh smb_buffering_size";
$default_roundup=trim(shell_exec($strExec));
$smb_roundup=$db->getvar("smb_buffering_size","$default_roundup");
$smb_veto=$db->getvar("advance_smb_veto","1");

unset($db);

$hide_receivefile_size=0;
if ($soc == "ppc"){
    $hide_receivefile_size=1;
}
 
$tpl->assign('cifs',$cifs);
$tpl->assign('httpd_nic1_filecache',$httpd_nic1_filecache);
$tpl->assign('smb_recycle',$smb_recycle);
$tpl->assign('smb_dataago',$smb_dataago);
$tpl->assign('smb_maxsize',$smb_maxsize);
$tpl->assign('smb_restrict_anonymous',$smb_restrict_anonymous); 
$tpl->assign('smb_roundup',$smb_roundup);
$tpl->assign('recycle_display',$recycle_display);
$tpl->assign('awords',$awords);
$tpl->assign('twords',$twords);
$tpl->assign('words',$words);
$tpl->assign('NAS_DB_KEY',NAS_DB_KEY);
$tpl->assign('set_url','setmain.php?fun=setsamba');
$tpl->assign('smb_localmaster',$smb_localmaster);
$tpl->assign('smb_unix',$smb_unix);
$tpl->assign('wan_ipv6',$wan_ipv6);
$tpl->assign('wan_ipv6_literal',$wan_ipv6_literal);
$tpl->assign('smb_trusted',$smb_trusted);
$tpl->assign('smb_receivefile_size',$smb_receivefile_size);
$tpl->assign('smb_blocksize',$smb_blocksize);
$tpl->assign('smb_veto',$smb_veto);
$tpl->assign('hide_receivefile_size',$hide_receivefile_size);
?>
