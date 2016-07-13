<?php


//========== Wording ==========
$words = $session->PageCode("webdav");
$gwords = $session->PageCode("global");

//========== Get date from webdav.tpl ==========
$webdav_enable=$_POST['webdav_enable'];
$webdav_port=$_POST['webdav_port'];
$webdav_ssl_enable=$_POST['webdav_ssl_enable'];
$webdav_ssl_port=$_POST['webdav_ssl_port'];
$webdav_browser_view=$_POST['webdav_browser_view'];

//========== Define ==========
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
$ch=new validate;
$check_port_cmd="/img/bin/check_port.sh";

//========== Data Check (Part 1)==========
  // Check port value is empty

if (($webdav_enable=='1') && $ch->check_empty($webdav_port)){
    unset($ch);
    return MessageBox(true,$words["alert_title"],$words["webdav_port_empty"],'ERROR');
}

if (($webdav_ssl_enable=='1') && $ch->check_empty($webdav_ssl_port)){
    unset($ch);
    return MessageBox(true,$words["alert_title"],$words["webdav_port_empty"],'ERROR');
}

unset($ch);

  // Check WebDAV and SSL port is eqal
if ( ($webdav_enable=='1') && ($webdav_ssl_enable=='1') ){
    if ($webdav_port==$webdav_ssl_port){
        return MessageBox(true,$words["alert_title"],$words["webdav_eq_ssl"],'ERROR');
    }
}

//========== Get previous DB setting ==========
$db=new sqlitedb();
$o_webdav_enable=$db->getvar("webdav_enable","1");
$o_webdav_port=$db->getvar("webdav_port","9800");
$o_webdav_ssl_enable=$db->getvar("webdav_ssl_enable","1");
$o_webdav_ssl_port=$db->getvar("webdav_ssl_port","9802");
$o_webdav_browser_view=$db->getvar("webdav_browser_view","1");

//========== Data Check (Part 2)==========

  // Check Port is used for other server
if ( ($webdav_enable=='1') && (($o_webdav_enable=='0')||($webdav_port!=$o_webdav_port)) ){
     $shellcmd=sprintf("%s %s t all webdav > /dev/null 2>&1; echo $?",$check_port_cmd,$webdav_port);
     $execRes=shell_exec($shellcmd);
     $execRes=trim($execRes,"\n");
     switch ($execRes){
          case 1:
               $error_msg=$words["webdav_port_conflict"];
               break;
          case 2:
               $error_msg=$words["webdav_port_type_error"];
               break;
          case 3:
               $error_msg=$words["webdav_port_out_range"];
               break;
          case 4:
               $error_msg=$words["webdav_port_out_range"];
               break;
          case 5:
               $error_msg=$words["webdav_port_reserved"];
               break;
     }
     if($execRes!=0){
          return MessageBox(true,$words["alert_title"],$error_msg,'ERROR');
     }
}

if ( ($webdav_ssl_enable=='1') && (($o_webdav_ssl_enable=='0')||($webdav_ssl_port!=$o_webdav_ssl_port)) ){
     $shellcmd=sprintf("%s %s t all webdavssl > /dev/null 2>&1; echo $?",$check_port_cmd,$webdav_ssl_port);
     $execRes=shell_exec($shellcmd);
     $execRes=trim($execRes,"\n");
     switch ($execRes){
          case 1:
               $error_msg=$words["webdav_port_conflict"];
               break;
          case 2:
               $error_msg=$words["webdav_port_type_error"];
               break;
          case 3:
               $error_msg=$words["webdav_port_out_range"];
               break;
          case 4:
               $error_msg=$words["webdav_port_out_range"];
               break;
          case 5:
               $error_msg=$words["webdav_port_reserved"];
               break;
     }
     if($execRes!=0){
          return MessageBox(true,$words["alert_title"],$error_msg,'ERROR');
     }
}

  // Check all new setting is equal DB setting
if ( ($webdav_enable==$o_webdav_enable) && ($webdav_port==$o_webdav_port) && ($webdav_ssl_enable==$o_webdav_ssl_enable) && ($webdav_ssl_port==$o_webdav_ssl_port) && ($webdav_browser_view==$o_webdav_browser_view) ){
     unset($db);
     return MessageBox(true,$words["alert_title"],$gwords["setting_confirm"],'WARNING');
}

//========== Save DB ==========
if ($webdav_enable!=$o_webdav_enable){
     $db->setvar("webdav_enable",$webdav_enable);
}

if ($webdav_ssl_enable!=$o_webdav_ssl_enable){
     $db->setvar("webdav_ssl_enable",$webdav_ssl_enable);
}

if ( ($webdav_enable=='1') && ($webdav_port!=$o_webdav_port)){
     $db->setvar("webdav_port",$webdav_port);
}

if ( ($webdav_ssl_enable=='1') && ($webdav_ssl_port!=$o_webdav_ssl_port)){
     $db->setvar("webdav_ssl_port",$webdav_ssl_port);
}

if ( (($webdav_enable=='1')||($webdav_ssl_enable=='1')) && ($webdav_browser_view!=$o_webdav_browser_view) ){
     $db->setvar("webdav_browser_view",$webdav_browser_view);
}

//========== Execute rc.webdav ==========
  //Stop WebDAV
if( ($webdav_enable=='0')&&($webdav_ssl_enable=='0') ){
     $shellcmd="/img/bin/rc/rc.webdav stop > /dev/null 2>&1; echo $?";
     $execRes=shell_exec($shellcmd);
     $execRes=trim($execRes,"\n");
     if ($execRes!='0'){
          // Restore original DB setting
          $db->setvar("webdav_enable",$o_webdav_enable);
          $db->setvar("webdav_port",$o_webdav_port);
          $db->setvar("webdav_ssl_enable",$o_webdav_ssl_enable);
          $db->setvar("webdav_ssl_port",$o_webdav_ssl_port);
          $db->setvar("webdav_browser_view",$o_webdav_browser_view);
          
          unset($db);
          return  MessageBox(true,$words['http_title'],$words["webdav_stop_fail"],'ERROR');
     }else{
          unset($db);
          return  MessageBox(true,$words['http_title'],$words["webdav_stop"],'INFO','OK');
     }
     
  //Start WebDAV (original is stop)
}elseif( (($o_webdav_enable=='0')&&($o_webdav_ssl_enable=='0')) && (($webdav_enable=='1')||($webdav_ssl_enable=='1')) ){
     $shellcmd="/img/bin/rc/rc.webdav start > /dev/null 2>&1; echo $?";
     $execRes=shell_exec($shellcmd);
     $execRes=trim($execRes,"\n");
     if ($execRes!='0'){
          // Restore original DB setting
          $db->setvar("webdav_enable",$o_webdav_enable);
          $db->setvar("webdav_port",$o_webdav_port);
          $db->setvar("webdav_ssl_enable",$o_webdav_ssl_enable);
          $db->setvar("webdav_ssl_port",$o_webdav_ssl_port);
          $db->setvar("webdav_browser_view",$o_webdav_browser_view);
          
          unset($db);
          return  MessageBox(true,$words['http_title'],$words["webdav_start_fail"],'ERROR');
     }else{
          unset($db);
          return  MessageBox(true,$words['http_title'],$words["webdav_start"],'INFO','OK');
     }
     
  //Reload WebDAV configure (original is running)
}else{
     $shellcmd="/img/bin/rc/rc.webdav reload > /dev/null 2>&1; echo $?";
     $execRes=shell_exec($shellcmd);
     $execRes=trim($execRes,"\n");
     if ($execRes!='0'){
          // Restore original DB setting
          $db->setvar("webdav_enable",$o_webdav_enable);
          $db->setvar("webdav_port",$o_webdav_port);
          $db->setvar("webdav_ssl_enable",$o_webdav_ssl_enable);
          $db->setvar("webdav_ssl_port",$o_webdav_ssl_port);
          $db->setvar("webdav_browser_view",$o_webdav_browser_view);
          
          unset($db);
          return  MessageBox(true,$words['http_title'],$words["webdav_start_fail"],'ERROR');
     }else{
          unset($db);
          return  MessageBox(true,$words['http_title'],$words["webdav_start"],'INFO','OK');
     }
}

?>
