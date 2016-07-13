<?php  
require_once(WEBCONFIG);  
require_once(INCLUDE_ROOT.'treemenu.class.php');

$ac= $_POST['ac']; 
$searchmsg = $_POST['searchmsg']; 
$tree = new Treemenu();  


switch($ac){
	case "search":
		//get treemenu after search.
		$content=$tree->Search($searchmsg);
		die(json_encode($content));
		break;	
	case "searchbyfun":  
		$content=$tree->SearchByFun($searchmsg);
		die(json_encode($content));
		break;	 
	default:
		return $tree->getTreeMenuList();
} 
 
?>



