<?php 
//**************************  restore shortcut.db  ***********************
//check shortcut.db , if it's damaged then restore db to default
$dbpath = "/etc/cfg/shortcut.db"; 
$chktable = shell_exec("/usr/bin/sqlite $dbpath .table");  // check table 
if(!$chktable){ 
    if (NAS_DB_KEY == '1'){
      //copy default shortcut.db
      $shellcmd = "tar zxvf /etc/default.tar.gz -C /tmp;";   // extract default.tar.gz
      $shellcmd .= "cp /tmp/$dbpath $dbpath;";               // copy shortcut.db to path:/etc/cfg/
      $shellcmd .= "rm /tmp/app -rf;";                       // remove tmp/app that extract from default.tar.gz
    }else{
      $shellcmd = "cp /img/bin/default_cfg/default/etc/cfg/shortcut.db /etc/cfg/;";                       // remove tmp/app that extract from /img/bin/default_cfg
    }
    shell_exec($shellcmd);
    shell_exec("rm ".LANG_DB);
    shell_exec("/img/bin/rc/rc.treemenu init");
}
//*************************************************************************

require_once(INCLUDE_ROOT.'shortcut.class.php');
require_once(INCLUDE_ROOT.'treemenu.class.php');
$ac = $_POST['ac']; 
$treeid=$_POST['treeid'];

$sc = new ShortCut();
$tree = new Treemenu();

$words = array(
    "add_shortcut" => $gwords["add_shortcut"],
    "del_shortcut" => $gwords["rm_shortcut"]
);
  
switch($ac){
	/**
	* find shortcut
	*/
	case 'find':
		$shortcut_find = $sc->find($treeid);
		$ary = array('find'=>$shortcut_find); 
		die(json_encode($ary));
		break;
	
	/**
	* get shortcut list
	*/
	default: 
		$list = $sc->getlist();  
		$tpl->assign('sclist',$list);
		$tpl->assign('words', json_encode($words));
		$tpl->assign('sclists',json_encode($list));
		$tpl->assign('group',json_encode($tree->getTreeMenuList()));
} 
 
?>
