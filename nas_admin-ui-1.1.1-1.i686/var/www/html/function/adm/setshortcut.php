<?php 
require_once(INCLUDE_ROOT.'shortcut.class.php');  

$ac = $_POST['ac'];
$treeid = $_POST['treeid'];
$target_treeid = $_POST['target_treeid'];
$source_treeid = $_POST['source_treeid'];
 

if($_SERVER['REQUEST_METHOD']=='POST' && $ac!=''){  
   $sc = new ShortCut();  
   switch($ac){  
	/**
	* add shortcut
	*/
   	case 'add':  
 		$sc->add($treeid);		// add to shortcut db
   		break; 

	/**
	* remove shortcut
	*/
   	case 'remove':
		$sc->remove($treeid);
   		break;

	/**
	* sorting shortcut
	*/
   	case 'sort':
		$sc->sort($source_treeid,$target_treeid);
   		break;
   } 
}

if(!$sc->result){
	return MessageBox(true,'Error',$sc->message);
}

?>
