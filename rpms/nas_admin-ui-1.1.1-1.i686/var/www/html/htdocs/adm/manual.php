<?php
require_once('../../function/conf/localconfig.php');
require_once(INCLUDE_ROOT.'inittemplate.php');
require_once(INCLUDE_ROOT.'session.php'); 
require_once(INCLUDE_ROOT.'manual.class.php'); 
 

$searchmsg = $_GET['searchmsg']; 
$id = $_GET['id']; 
$cid = $_GET['cid']; 
 
$man = new Manual();

if($id!='' && $cid!=""){
//show special function manual
	$man_ary = $man->ManualContent($cid,$id);  
	$tpl->assign('title',$man_ary["title"]); 
	$tpl->assign('manual_content',$man_ary["content"]);   
			
}else if($searchmsg!=""){
//search text of manual list
	$manual_list = $man->ManualList($searchmsg); 
	$tpl->assign('manual_list',$manual_list);   
	 
}else{
//show all of manual list
	$manual_list = $man->ManualList(); 
	$eventlog_list = $man->ManualList_Eventlog();  
	$tpl->assign('manual_list',$manual_list);    
	$tpl->assign('eventlog_list',$eventlog_list);    

}
 
$tpl->assign('id',$id); 
$tpl->assign('cid',$cid); 
$tpl->display('/adm/manual.tpl'); 
?>  