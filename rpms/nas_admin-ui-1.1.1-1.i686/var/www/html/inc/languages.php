<?php
/**
 * This page is for set language mode
 */
require_once(INCLUDE_ROOT.'session.php');
//grab language
require_once(DOC_ROOT.'language/'.$session->lang.'/index.php'); 
//send all language variables to template; 

//deal with exception of language
$looplang='';
foreach(get_defined_vars() as $key => $value) {
	preg_match('/^(str.*)/',$key,$matches);
	if(isset($matches[1]) && $matches[1]!='' ){ 
		$tpl->assign($matches[1],$value);
		$looplang.="var $matches[1]='$value';"; 
	} 
} 
$tpl->assign('looplang',$looplang);
?>