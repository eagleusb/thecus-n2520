<?php 
require_once(TEMPLATE_LITE_SRC_ROOT . 'class.template.php');
$tpl = new Template_Lite;
$tpl->compile_dir= TEMPLATE_LITE_COMPILE_ROOT;
$tpl->template_dir= TEMPLATE_LITE_TPL_ROOT;
$tpl->right_delimiter = '}>';
$tpl->left_delimiter = '<{';
$tpl->cache= true;
$tpl->assign('BETA_VERSION',BETA_VERSION);	
$tpl->assign('FW_VERSION',FW_VERSION);	
$tpl->assign('FWTYPE',FWTYPE);	
$tpl->assign('FWPRODUCER',FWPRODUCER);	
$tpl->assign('urljs',URL_ROOT_JS);	
$tpl->assign('urlextjs',URL_ROOT_EXTJS);	
$tpl->assign('urlcss',URL_ROOT_CSS);	
$tpl->assign('urlimg',URL_ROOT_IMG);	

?>
