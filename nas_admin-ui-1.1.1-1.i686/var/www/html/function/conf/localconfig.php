<?php 
define('DOC_ROOT','/var/www/html/'); 

define('INCLUDE_ROOT',DOC_ROOT.'inc/');
define('FUNCTION_ROOT',DOC_ROOT.'function/'); 
define('FUNCTION_ADM_ROOT',FUNCTION_ROOT.'adm/'); 
define('FUNCTION_USR_ROOT',FUNCTION_ROOT.'usr/'); 
define('FUNCTION_CONF_ROOT',FUNCTION_ROOT.'conf/'); 
 
 
//web root (extjs/css/images)
define('URL_ROOT', '/adm/');  
define('URL_ROOT_THEME', '/theme/');    
define('URL_ROOT_JS', '/javascript/');
define('URL_ROOT_EXTJS', '/extjs/'); 
define('URL_ROOT_CSS', URL_ROOT_THEME.'css/'); 
define('URL_ROOT_IMG', URL_ROOT_THEME.'images/'); 


//template root
define('TEMPLATE_LITE_SRC_ROOT', DOC_ROOT."template_lite/");
define('TEMPLATE_LITE_COMPILE_ROOT', '/tmp/compiled/');
define('TEMPLATE_LITE_TPL_ROOT', DOC_ROOT.'templates/'); 


//others
define('WEBCONFIG', FUNCTION_CONF_ROOT.'webconfig');  
define('APP_ROOT', '/var/www/html/');
define('APP_INC_ROOT', APP_ROOT.'inc/'); 
define('APP_INFO_ROOT', APP_INC_ROOT.'info/'); 
define('LANG_ROOT', APP_ROOT.'htdocs/setlang/');    
define('SYSTEM_DB_ROOT', '/etc/cfg/');    
define('CROND_CONF_PATH', SYSTEM_DB_ROOT.'crond.conf');
define('MODULE_ROOT', '/raid/data/module/');    
define('MODULE_TMP', '/raid/data/tmp/');
define('MODULE_WWW', APP_ROOT.'htdocs/modules/'); 
define('PKG_ROOT', '/opt/');

//user
define('USER_ROOT', APP_ROOT.'htdocs/usr/');

//define value
define('SQLITE_VERSION','3');
define('NAS_DB_KEY','2');
define('MDADM_PATH','/sbin/mdadm');
define('SAVE_LOG','/usr/bin/savelog  /etc/cfg/logfile ');

//development version
define('BETA_VERSION','v0.5');

// TFTP
define('TFTP_WAN', 1);
define('TFTP_LAN', 2);
define('TFTP_READ', 1);
define('TFTP_WRITE', 2);

define('TMP_PATH', '/var/tmp/www');
define('INIT_INFO', TMP_PATH.'/init_info');
define('LANG_DB',TMP_PATH.'/language.db');
define('CHANGE_TREE',TMP_PATH.'/change_tree');

// /img/bin
define('IMG_BIN', '/img/bin');
define('LOGEVENT', IMG_BIN.'/LOGEVENT');
define('EVENT_SH', LOGEVENT.'/event');
require_once("eventno.php");


// HA script path
define('HA_STATUS_PATH',TMP_PATH.'/ha_status');
define('HA_LOG_PATH',TMP_PATH.'/ha_log');
define('HA_NETWORK_PATH',TMP_PATH.'/ha_network');
define('HA_FLAG',TMP_PATH.'/ha_flag');
define('HA_HW_CONF',TMP_PATH.'/ha_conf_hw_result');
define('HA_ROLE','/tmp/ha_role');

define('HA_SCRIPT',IMG_BIN.'/ha/script/rc.ha');
define('HA_POWER',IMG_BIN.'/ha/script/ha_power.sh');



// HA thresholds values
define('HA_KEEPALIVE','2');
define('HA_DEADTIME','30');
define('HA_WARNTIME','10');
define('HA_INITDEAD','120');
define('HA_UDPPORT','3694');
define('HA_HEARTBEAT','eth2');
define('HA_HEARTBEAT_ACTIVE','192.168.3.200');
define('HA_HEARTBEAT_STANDBY','192.168.3.201');
//IPV6
define('IPV6_STATIC', '0');
define('IPV6_AUTO', '1');

//DVD
define('DVD_LOG',TMP_PATH.'/burn_log'); 
?>
