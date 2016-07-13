<?php
require_once(WEBCONFIG);  
require_once(INCLUDE_ROOT.'nasstatus.class.php');
require_once(INCLUDE_ROOT.'indexnews.class.php'); 
require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'treemenu.class.php'); 
require_once(INCLUDE_ROOT.'ha.class.php'); 
require_once(INCLUDE_ROOT.'function.php');

$indexnews = new IndexNews();
$tree = new Treemenu();

//check status
$raid = openfile('rss','raid');   		//check_raid
$disk = openfile('rss','disk');         //check_disk
$fan = openfile('fan');          		//check_fan
$ups = check_ups();           			//check_ups
$temp = openfile('temperature');  		//check_temperature
$log = $indexnews->getCount('log');		//check log count
//$news = $indexnews->getCount('news');	//check news count

//check treemenu 
$treeupdate = $tree->detectTreeMenu()?$tree->getTreeMenuList():false;	 

// detect new module upgrade window 
$modup = require_once(FUNCTION_ADM_ROOT.'modupgrade.php');

// monitor ha
//$ha = require_once(FUNCTION_ADM_ROOT.'setha.php');
$ha = HighAvailabilityRPC::getMonitor();

// dvd burning
if(file_exists(DVD_LOG)){
    $dvd = require_once(FUNCTION_ADM_ROOT.'setdvd.php'); 
}

$req = array('raid'=>getStatus($raid),
             'disk'=>getStatus($disk),
             'fan'=>getStatus($fan),
             'ups'=>$ups,
             'temp'=>getStatus($temp),
			 'log'=>$log,
			 //'news'=>$news,
			 'tree'=>$treeupdate,
             'modup'=>$modup,
	     'ha'=>$ha,
             'dvd'=>$dvd
             );
die(json_encode($req));
?>
