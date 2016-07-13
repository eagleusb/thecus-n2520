<?php
require_once(WEBCONFIG);  
require_once(INCLUDE_ROOT.'indexnews.class.php');
 
//show log or news list
$name = $_POST['name'];
$indexnews = new IndexNews();
switch($name){ 
	case "cleanlog": 
		$indexnews->setCountZero('log');
		die;
	break;
	case "popuplog": 
		die(json_encode($indexnews->PopupLog()));
	break;
	case "log": 
		die(json_encode($indexnews->showRecord('log',8)));
	break;
	case "news":
		die(json_encode($indexnews->showRecord('news',8)));
	break;
} 
 
?>
