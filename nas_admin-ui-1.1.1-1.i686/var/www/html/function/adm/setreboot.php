<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');

if($_REQUEST['action'] == 'cancel'){  
    $db = new sqlitedb();                                                                                                                                                                                                        
    $db->setvar('ha_enable','0');                                                                                                                                                                                                
    unset($db); 
    pclose(popen(HA_SCRIPT.' cancel', "r"));                                                                                                                                                                                             
    shell_exec("rm ".HA_FLAG);
    shell_exec("rm /var/tmp/www/ha_conf_hw_result");                                                                                                                                                                                     
    die;
}
if($_REQUEST['action'] == 'cancelboot'){  
    shell_exec("rm ".HA_FLAG);
    die;
}

$gwords = $session->PageCode("global");
$words = $session->PageCode("sdrb");
get_sysconf();
$raid_deny=trim(shell_exec("/img/bin/raid_deny.sh"));
$deny_msg=$words["current_raid"].' ['.$raid_deny.'], '.$words["try_later"];
if ($raid_deny != ''){
    echo json_encode(MessageBox(true,$gwords['reboot'],$deny_msg));
    exit;
}

if (NAS_DB_KEY == '1'){
  $command="/img/bin/model/sysdown.sh check 2>&1";
  $check=shell_exec($command);
  if(trim($check) != "1"){
    return MessageBox(true,$words['shutdownTitle'],$words['shutdown_fail'],'ERROR');
    exit;
  }
}

if($_REQUEST['action'] == 'reboot'){
        if (NAS_DB_KEY == '1'){
                $command = "/img/bin/model/sysdown.sh reboot > /dev/null 2>&1 &";
        }else{
                $command = "/img/bin/sys_reboot > /dev/null 2>&1 &";
        }

	$msg=sprintf($words["rebootSuccess"], $sysconf["boot_time"]);
	echo json_encode(ProgressBar(true,$words['rebootTitle'],$msg,"ProgressBar",1,intval($sysconf["boot_time"])));
	flush();
	if($_REQUEST['noaction']!='1'){
	    shell_exec("$command");
	}
	exit;
}
elseif($_REQUEST['action']=='shutdown'){
        if (NAS_DB_KEY == '1'){
                $command = "/img/bin/model/sysdown.sh poweroff > /dev/null 2>&1 &";
        }else{
                $command = "/img/bin/sys_halt > /dev/null 2>&1 &";
        }
	flush();
	if($_REQUEST['noaction']!='1'){
	    shell_exec("$command");
	}
	return ProgressBar(true,$words['shutdownTitle'],$words["shutdownSuccess"],"ProgressBar", 1, 30, "OK", "", $words["shutdownOver"]);
	exit;
}
elseif($_REQUEST['action'] == 'ha_reboot'){
    if($_REQUEST['type']=='shutdown') $_REQUEST['type']  = "halt";
    shell_exec(HA_POWER." init ".$_REQUEST['type']." > /dev/null 2>&1 &");
    sleep(2);
    die('0');
}



?>
