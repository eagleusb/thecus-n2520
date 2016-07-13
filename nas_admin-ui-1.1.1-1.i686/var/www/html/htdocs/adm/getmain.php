<?php
require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'inittemplate.php');
require_once(INCLUDE_ROOT.'session.php');
require_once(INCLUDE_ROOT.'publicfun.php'); 
require_once(INCLUDE_ROOT.'treemenu.class.php'); 

if(!$session->admin_auth && !check_fsck_flag())
    die('<script>location.href="/adm/logout.php"</script>');
    
if(!$session->logged_in && !check_fsck_flag()){
   die('<script>location.href="/index.php"</script>');
}
$request = initWebVar('fun'); 
$module = initWebVar('module'); 
if(!empty($module)){
  if (is_file(MODULE_ROOT.$module.'/www/index.htm')){
    include_once(MODULE_ROOT.$module.'/www/index.htm'); 
  }else if (is_file(MODULE_ROOT.$module.'/www/index.php')){
    include_once(MODULE_ROOT.$module.'/www/index.php');
  }else if (is_file(PKG_ROOT.$module.'/www/index.htm')){
    //for old module which is use getform generate index.htm
    $ishtml=shell_exec( 'grep "[<]html[>]" '.PKG_ROOT.$module.'/www/index.htm');
    $with_header_img=shell_exec( 'grep "theme/images/index/header.jpg" '.PKG_ROOT.$module.'/www/index.htm');
    if (empty($ishtml) && empty($with_header_img)){
        header("Location: getform.html?Module=".$module);
    }else{
        include_once(PKG_ROOT.$module.'/www/index.htm');
    }
  }else {
    include_once(PKG_ROOT.$module.'/www/index.php');
  }
  exit;
}
if(!empty($request)){
  $gwords = $session->PageCode("global");
  $tpl->assign('gwords',$gwords);
  if( $request != 'nasstatus' ) {
    $_SESSION['PageCode'] = $request;
  }
  include_once(FUNCTION_ADM_ROOT.'checksys.php');  
  include_once(FUNCTION_ADM_ROOT.$request.'.php');  
  
/******************************************************
        check currentpage 
        if currentpage not exist in treemenu
*******************************************************/ 
$nolimitpage = array("shortcut","fsck_ui","indexnews"); 
if (!in_array($request, $nolimitpage)) {  
	$tree = new Treemenu();  
	$treeview = $tree->getTreeMenuList(); 
	$current_check =findTreeTxt($request, $treeview);
	if($current_check==''){   
		die("<script>function gotoshortcut(){location.href='/adm/index.php';} Ext.onReady(function(){Ext.Msg.alert('','".$gwords['notavailable']."',gotoshortcut);});</script>"); 
	} 
} 

  require_once(INCLUDE_ROOT.'sqlitedb.class.php');
  
  $tpl->assign('form_html',"adm/$request.tpl");
  $tpl->display("adm/content.tpl");
}
?>
 
