<?php  
require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'inittemplate.php');
require_once(INCLUDE_ROOT.'session.php');
require_once(INCLUDE_ROOT.'publicfun.php');
if(!$session->admin_auth && !check_fsck_flag())
    die('logout');
if(!$session->logged_in && !check_fsck_flag())
   die('logout');
   
$request = initWebVar('fun');
if(!empty($request)){
  $tpl->assign('gwords',$session->PageCode("global"));
  $_POST['checksys_id'] = ($request!='checksys')?str_replace('set','',$request):$_POST['checksys_id'];
  if( !($_REQUEST['fun'] == 'setquota' && $_REQUEST['action'] == 'cancel') ) {
      require_once('../../function/adm/checksys.php');
  }
  die(json_encode(require(FUNCTION_ADM_ROOT.$request.'.php')));  
}  
?>
