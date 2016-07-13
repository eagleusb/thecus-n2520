<?php
require_once(INCLUDE_ROOT."function.php");
$checksys_id=$_POST['fun'];  
get_sysconf();
$md=trim($_POST['md_num']);
check_upgrade();
switch($checksys_id)
{
  case 'ads':
    check_raid(0);
    $samba_enabled=check_samba();
    check_system($samba_enabled,"samba_warning","samba",0);
    $samba_service=check_samba_service();
    check_system($samba_service,"samba_service_warning","samba",0);
    $ldap_enabled=check_ldap();
    if($ldap_enabled=='0'){
       $ldap_enabled='1'; 
    }else{
       $ldap_enabled='0';
    }
    check_system($ldap_enabled,"ad_error","ldap",0);
    break;
  case 'ldap':
    check_raid(0);
    $ads_enabled=check_ads();
    if($ads_enabled=='0'){
       $ads_enabled='1';
    }else{
       $ads_enabled='0';
    }
    check_system($ads_enabled,"ads_error","ads",0);
    break;
  case 'nfs':
    check_raid(0);
    break;
  case 'share':
    check_raid(0);
    break;
  case 'ha':
    check_ha_raid(0);
    break;
  case 'dvd':
  case 'nsync':
  case 'rsync':
  case 'rsync_target':
  case 'access_log':
    check_raid(0);
    break;
  case 'afp':
    check_raid(0);
    break;
  case 'DLNA':
    check_raid(0);
    break;
  case 'fsck':
    check_raid(0);
    break;
  case 'http':
    check_raid(0);
    break;
  case 'iscsi':
  case 'module':
  case 'auto_module':
    check_raid(0);
    break;
  case 'quota':
    check_raid(0);
    break;
  case 'printer':
    check_raid(0);
    break;
  case 'tftp':
    check_raid(0);
    break;
  case 'localuser':
  case 'localgroup':
  case 'batch':
    check_raid(0);
    $samba_enabled=check_samba();
    check_system($samba_enabled,"samba_warning","samba",0);
    $samba_service=check_samba_service();
    check_system($samba_service,"samba_service_warning","samba",0);
    break;
  case 'ftp':
    check_raid(0);
    $samba_enabled=check_samba();
    check_system($samba_enabled,"samba_warning","samba",0);
    $samba_service=check_samba_service();
    check_system($samba_service,"samba_service_warning","samba",0);
    break;
  case 'space_allocate_advance':  
    if($sysconf["iscsi_limit"]<="0"){
      check_system("0","no_support","raid",0);
    }
  case 'space_allocate_data':
  case 'space_allocate':
    check_raid(0);
    $md_info=$_POST["md"];
    if($md_info!=''){
      $open_encrypt=trim(shell_exec("/img/bin/check_service.sh encrypt_raid"));
      if($open_encrypt==1){
        check_encrypt($md_info,1);
        check_usbkey_exist($md_info,1);
      }
    }
    if($sysconf["target_usb"]!="1" && $sysconf["iscsi_limit"]<="0"){
      check_system("0","no_support","raid",0);
    }
    break; 
  case 'unmountiso':
  case 'addisomount':
  case 'isomount':
    check_system($sysconf["isomount"],"permission_warning","about",0);
    check_raid(0);
    $samba_enabled=check_samba();
    check_system($samba_enabled,"samba_warning","samba",0);
    $samba_service=check_samba_service();
    check_system($samba_service,"samba_service_warning","samba",0);
    break;   
  case 'iTune':
    check_raid(0);
    $samba_enabled=check_samba();
    check_system($samba_enabled,"samba_warning","samba",0);
    $samba_service=check_samba_service();
    check_system($samba_service,"samba_service_warning","samba",0);
    break;
  case 'stackable':
    check_raid(0);
    check_system($sysconf["stackable"],"permission_warning","about");
    break;
  case 'expand':
  case 'migrate':
  case 'raid':
    if($md!=''){
      $open_encrypt=trim(shell_exec("/img/bin/check_service.sh encrypt_raid"));
      if($open_encrypt==1){
        check_encrypt($md,1);
        check_usbkey_exist($md,1);
      }
      check_raid(0);
    }      
    break;
  case 'ddombackup':
    check_raid(0);
    break;
  case 'online':
    check_raid(0);
    break;
  case 'aclbackup':
    check_raid(0);
    break;
  case 'dataguard':
  case 'amazon_s3':
    check_raid(0);
    break;
  case 'webdav':
    check_raid(0);
    break;
  default:
    break;
}
?>
