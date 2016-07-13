<?php
require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'inittemplate.php');
require_once(INCLUDE_ROOT.'session.php');
require_once(INCLUDE_ROOT.'publicfun.php'); 
require_once(INCLUDE_ROOT.'function.php'); 

if(!$session->admin_auth)
    die('1');
    
if(!$session->logged_in){
   die('2');
}
   
$module = initWebVar('Module'); 
if($module==''){
   $module=$_SESSION['module'];
}

if(!empty($module)){
  $_SESSION['module']=$module; 
  $style_dir=MODULE_ROOT.$module.'/www/style.css';
  $header_dir=MODULE_ROOT.$module.'/www/header.php';
  $footer_dir=MODULE_ROOT.$module.'/www/footer.php';
  
  $homepage='/www/index.htm';
  $module_db_path= MODULE_ROOT . "cfg/module.db";  
  $db = new sqlitedb($module_db_path, 'module');
  $mod_rs = "select homepage from module where name='$module' and homepage like 'www%' ";
  $db->runPrepare($mod_rs);
  if($mod_info = $db->runNext()){ 
      $homepage=$mod_info['homepage'];
  }
  
  echo "<html><head>";
  $s = is_file($style_dir); 
  if($s){
     echo "<link rel='stylesheet' type='text/css' href='/modules/$module/www/style.css' />";
  }else{
     echo "<link rel='stylesheet' type='text/css' href='/theme/css/mstyle.css' />";
     echo "<link rel='stylesheet' type='text/css' href='/theme/css/css2.css' />";
  }
  echo "</head><body>";
  
  
  $h = is_file($header_dir); 
  if($h){
     require_once($header_dir); 
  }else{
    echo "<div align='center'><table width='1004' cellpadding='0' cellspacing='0' border=0>";
    echo "<tr><td><img src='/theme/images/index/header.jpg' /></td></tr>";
    echo "<tr><td>";
  }
  
//  include_once(MODULE_ROOT.$module.$homepage'/www/index.htm'); 
  include_once(MODULE_ROOT.$module.'/'.$homepage); 
  $f = is_file($footer_dir); 
  if($f){
     require_once($footer_dir); 
  }else{
    echo "</td></tr>";
    echo "<tr><td><img src='/theme/images/index/footer.jpg' /></td></tr>";
    echo "</table></div>";
  }
  
  echo "</body></html>";
  exit;
}
?>
 