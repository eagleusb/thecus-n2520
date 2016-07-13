<?php
if(!$_POST){
   define( '_EXT_PATH', dirname(__FILE__) );
   define( '_VALID_MOS', 1 );
   define( '_VALID_EXT', 1 );
   require_once('application.php');
   $default_lang = !empty( $GLOBALS['mosConfig_lang'] ) ? $GLOBALS['mosConfig_lang'] : ext_Lang::detect_lang();
   require_once("languages/$default_lang.php");
   $msg = $GLOBALS["error_msg"]['uploadfile'];
   die(json_encode(array('success'=>false,'errormsg'=>$msg)));
}else{
   require_once('index.php');
}
?>
