<?php    
require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
require_once(INCLUDE_ROOT.'function.php'); 

$gModName = array("Piczza","WebDisk"); 
$gModTmpCmd = "echo ' %s ' >> /var/tmp/tmp_module/module_item"; 
$gModEnabledCmd ="/img/bin/rc/rc.module 'enable' "; 
$gAutoModBin = "/img/bin/rc/rc.automodule";
$gAutoModDownloadCmd = $gAutoModBin." online '%s' '%s' '%s';";
$gAutoModBackgroundCmd = "(%s) > /dev/null 2>&1 &";
$gAutoModListCmd = $gAutoModBin." list | tr -d \' "; 
$gModDBPath= MODULE_ROOT.'cfg/module.db'; 

$ac = $_GET["ac"];
$modname = $_GET["modname"];

switch($ac){ 
	case "install":   
	    if(file_exists($gModDBPath)){
	  		$db = new sqlitedb($gModDBPath, 'module');   
			$index = array();
                        $cmd = "";
			foreach($modname as $v){   
				list($name,$displayname,$url) =  explode(",",$v); 
				$cmd .= sprintf($gAutoModDownloadCmd,$name,$url,$displayname); 
	    		
	    		$total = $db->db_get_count("module");   
	    		if($total){
	    			array_push($index,$total[0]);  
	    		}  
			}    
                        shell_exec(sprintf($gAutoModBackgroundCmd, $cmd));
	    	unset($db);   
			$_SESSION["modIndex"]=$index;   
	    }
		break; 
	case "enable": 
		if(isset($_SESSION["modIndex"])){
			$modAry = $_SESSION["modIndex"];
			foreach($modAry as $v){ 
				$cmd = sprintf($gModTmpCmd,$v);
	    		shell_exec($cmd);
			}
			shell_exec($gModEnabledCmd);
		} 
		unset($_SESSION["modIndex"]); 
		$_SESSION["mod_upgrade"]=1;
		break;
				
	case "no_remind":
		$db=new sqlitedb();  
		$db->setvar("modupgrade_enabled", "0"); 
		$db->db_close();
		$_SESSION["modupgrade_enabled"]= "";
		break; 
		
	case "detect": 
		die(json_encode(getOnlineModule()));  
		break;
		
	default: 
		$mod_upgrade = "0";
		$mod_form = ""; 
		if (isset($_SESSION["modupgrade_enabled"]) && $_SESSION["modupgrade_enabled"] == "1") { 
			$mod_upgrade = check_module_upgrade(); 
			if($_SESSION["new_module_install"]=="1"){
				$mod_form = "cd";
			}else{  
				$data = getOnlineModule();
				$mod_data = $data["mod_data"];
				switch($data["success"])
				{
					case -1:
						$mod_upgrade = "1";
						break;
					case 0:
						$mod_form = "fail";
						break;
					case 1:
						$mod_form = "install";
						break;
				}
			} 
		}    
		return array(
				"mod_form" =>$mod_form, 
				"modupgrade_enabled" =>$_SESSION["modupgrade_enabled"],
				"mod_upgrade" =>$mod_upgrade,
				"mod_data" =>$mod_data);
} 

/**
 * get online module list
 * @return array{ success=1, data=online module list}
 */
function getOnlineModule()
{ 
	global $gAutoModListCmd,$gModName,$gModDBPath; 
	$req = 0; 
	$mod_data = ""; 
	if(check_raid_exist()){
		$moduleData = shell_exec($gAutoModListCmd);
		$moduleData=trim($moduleData); 
		$ary = explode(",",$moduleData); 
		if(count($ary)>1){  
			$r = 8;
			$total = count($ary)/$r;
			$j=0;
			for($i=0;$i<$total;$i++){
				$name = $ary[$i*$r+1];
				$displayname = $ary[$i*$r+2];
				$version = $ary[$i*$r+3];
				$url_ary = $ary[$i*$r+7]; 
				$fwversion_ary = $ary[$i*$r+6]; 
				if($url_ary){
					$url = explode("|",$url_ary);
					$url = $url[1];
				}
				if($fwversion_ary){
					$nas_check = explode("|",$fwversion_ary);
					$nas_check = $nas_check[2];
				}
				if(in_array($name,$gModName) && $nas_check=="1"){ 
					$exists = shell_exec("/usr/bin/sqlite \"".$gModDBPath."\" 'select name from module where name=\"".$name."\"' ");
					if(empty($exists)){ 
						$mod_data .= "$name,$displayname,$version,$url|";
						$j++;
					}
				}
			} 
			$req=1; 
		}
	}else{
		$req = -1; 
	} 
	return array(
				"success"=>$req, 
				"mod_data"=>$mod_data);   
}



 
/**
 * check module upgrade
 * if upgrade then return 1, otherwise return 0
 */
function check_module_upgrade(){
	global $gModDBPath;
	$raidexist = check_raid_exist(); 
	$upgrade = 0; 
	if($raidexist!==0 && file_exists($gModDBPath) ){  
		$db = new sqlitedb(MODULE_ROOT . "cfg/module.db"); 
		$db->runPrepare("SELECT * FROM module WHERE name in ('Piczza','WebDisk') AND enable='Yes'");  
		if ($mod_info = $db->runNext()){
			$upgrade = 1;
		}  
		unset($db);
	}
	$upgrade=0;
	return $upgrade;
}

?> 
