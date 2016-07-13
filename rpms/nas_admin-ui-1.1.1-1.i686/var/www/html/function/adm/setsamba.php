<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php'); 
 
$words = $session->PageCode("httpd");
$twords = $session->PageCode("index");
$gwords = $session->PageCode("global"); 
$cifs_enable=$_POST['_nic1_cifs'];
$nhttpd_nic1_filecache=($_POST['_nic1_filecache']=="" ? "0" : $_POST['_nic1_filecache']);
$nsmb_recycle=($_POST['advance_smb_recycle']=="" ? "0" : $_POST['advance_smb_recycle']);
$nsmb_restrict_anonymous=($_POST['advance_smb_restrict_anonymous']=="" ? "0" : $_POST['advance_smb_restrict_anonymous']);  
$smb_localmaster=($_POST['smb_localmaster']=="" ? "0" : $_POST['smb_localmaster']);  
$smb_unix=($_POST['smb_unix']=="" ? "0" : $_POST['smb_unix']);  
$smb_roundup=($_POST['smb_roundup']=="" ? "1" : $_POST['smb_roundup']);
$smb_signing=($_POST['smb_signing']=="" ? "0" : $_POST['smb_signing']);  
$smb_receivefile_size=($_POST['smb_receivefile_size']=="" ? "1" : $_POST['smb_receivefile_size']);
$smb_blocksize=($_POST['smb_blocksize']=="" ? "1" : $_POST['smb_blocksize']);
$smb_veto=($_POST['smb_veto']=="" ? "1" : $_POST['smb_veto']);
$smb_trusted=($_POST['smb_trusted']=="" ? "0" : $_POST['smb_trusted']);
$o_cifs_enable=$_POST['o_nic1_cifs'];
$o_nhttpd_nic1_filecache=$_POST['o_nic1_filecache'];
$o_nsmb_recycle=$_POST['o_advance_smb_recycle'];
$o_nsmb_restrict_anonymous=$_POST['o_advance_smb_restrict_anonymous']; 
$o_smb_localmaster=$_POST['o_smb_localmaster']; 
$o_smb_unix=$_POST['o_smb_unix'];
$o_smb_roundup=$_POST['o_smb_roundup'];
$o_smb_signing=$_POST['o_smb_signing'];
$o_smb_receivefile_size=$_POST['o_smb_receivefile_size'];
$o_smb_blocksize=$_POST['o_smb_blocksize'];
$o_smb_veto=$_POST['o_smb_veto'];
$o_smb_trusted=$_POST['o_smb_trusted'];
$o_daysago=$_POST['o_smb_dataago'];
$o_maxsize=$_POST['o_smb_maxsize'];
$daysago=$_POST['_daysago'];
$maxsize=$_POST['_maxsize'];
if(!$validate->numeric(5,'max',$daysago)){
return MessageBox(true,$gwords['info'],$words["field_format_error"],'INFO');
}
if(!$validate->numeric(5,'max',$maxsize)){
return MessageBox(true,$gwords['info'],$words["field_format_error"],'INFO');
}
$o_recycle_display=$_POST['o_recycle_display'];
$recycle_display=($_POST['recycle_display']=="" ? "0" : $_POST['recycle_display']);
if($daysago==""){
   $daysago="0";
   }
if($maxsize==""){
   $maxsize="0";
   } 
$db=new sqlitedb(); 
$if_no_change=true; 
$smb_stop="/img/bin/rc/rc.samba stop 2>&1 > /dev/null";
$smb_boot="/img/bin/rc/rc.samba boot 2>&1 > /dev/null";
$smb_reload="/img/bin/rc/rc.samba reload 2>&1 > /dev/null";
$bonjour_boot="/img/bin/rc/rc.bonjour boot > /dev/null 2>&1";

/*******************************************************
                 Samba cache
*******************************************************/
if($nhttpd_nic1_filecache != $o_nhttpd_nic1_filecache){ 
     $if_no_change=false;  
     $db->setvar("httpd_nic1_filecache",$nhttpd_nic1_filecache);
}
/*******************************************************
                 Samba Recycle
*******************************************************/
if($nsmb_recycle != $o_nsmb_recycle){ 
     $if_no_change=false;  
     $db->setvar("advance_smb_recycle",$nsmb_recycle); 
}
/*******************************************************
                  Samba Recycle delete days
*******************************************************/
if($daysago != $o_daysago){
     $if_no_change=false;
     $db->setvar("smb_dataago",$daysago);
}
/*******************************************************
                  Samba file maxsize
*******************************************************/
if($maxsize != $o_maxsize){
      $if_no_change=false;
      $db->setvar("smb_maxsize",$maxsize);
}
            
/*******************************************************
                  Samba Recycle Display
*******************************************************/
if($recycle_display != $o_recycle_display){
     $if_no_change=false;
     $db->setvar("recycle_display",$recycle_display);
}
/*******************************************************
                 Samba Anonymous Login Authentication
*******************************************************/ 
if($nsmb_restrict_anonymous != $o_nsmb_restrict_anonymous){ 
     $if_no_change=false;   
     $db->setvar("advance_smb_restrict_anonymous",$nsmb_restrict_anonymous);   
}

if($smb_localmaster != $o_smb_localmaster){ 
     $if_no_change=false;
     $db->setvar("advance_smb_localmaster",$smb_localmaster);   
}

if($smb_unix != $o_smb_unix){ 
     $if_no_change=false;
     $db->setvar("advance_smb_unix_exten",$smb_unix);   
} 

if(NAS_DB_KEY==1){
  if($smb_signing != $o_smb_signing){
   $if_no_change=false;
   $db->setvar("advance_smb_signing",$smb_signing);
  }
}

if($smb_receivefile_size != $o_smb_receivefile_size){ 
    $if_no_change=false;
    $db->setvar("advance_receivefile_size",$smb_receivefile_size);   
}

if($smb_blocksize != $o_smb_blocksize){
    $if_no_change=false;
    $db->setvar("advance_smb_blocksize",$smb_blocksize);
}

if($smb_roundup != $o_smb_roundup){ 
    $if_no_change=false;
    $db->setvar("smb_buffering_size",$smb_roundup);   
}

if($smb_veto != $o_smb_veto){
    $if_no_change=false;
    $db->setvar("advance_smb_veto",$smb_veto);
}

if($smb_trusted != $o_smb_trusted){
   $if_no_change=false;
   $db->setvar("advance_smb_trusted",$smb_trusted);
}

if(!$if_no_change && $cifs_enable==1){
    shell_exec($smb_reload); 
}

/*******************************************************
                 Samba  enable/disable
*******************************************************/
if($cifs_enable != $o_cifs_enable){ 
      $if_no_change=false;  
      require_once(INCLUDE_ROOT.'smbconf.class.php');
      $SmbConf=new SmbConf();
      $SmbConf->setShare("global");
      if($cifs_enable==1) {
             $SmbConf->setValue("interfaces","eth*,wlan*,lo");
             $SmbConf->restart(); 
             shell_exec($smb_boot);
      } elseif($cifs_enable==0) {
             $SmbConf->setValue("interfaces","lo");
             $SmbConf->restart();
             shell_exec($smb_stop);
      }   
     $db->setvar("httpd_nic1_cifs",$cifs_enable);
     shell_exec($bonjour_boot);
}

 //if not do any change,redirect to setting page
if($if_no_change){
    return  MessageBox(true,$gwords['info'],$words["notchange"],'INFO');  
}
 
return  MessageBox(true,$twords['tree_samba'],$gwords["setting_success"],'INFO'); 
?> 
