<?php
//$execut_log="/var/log/execute_log.".date("d_H_i_s"); 

class foo {
	const awk="/usr/bin/awk";
	const debug=false;
	public static $execut_log=FALSE; 

	//===========================================================
	//	constructor
	//===========================================================
	function __construct() {
		return;
	}

	//===========================================================
	//	method to do execute command
	//	IF success will print on console, $output=1
	//	IF fail will print on console, $output=0
	//===========================================================
	public function execute($cmd,$output=1,$syslog_str="",$syslog_prog="") {
		if(!foo::$execut_log) foo::$execut_log="/var/log/execute_log.".date("d_H_i_s");
		$buf=shell_exec($cmd);
		if(self::debug) {
			$wcmd=preg_replace('@"@',"\\\'",$cmd);
			shell_exec("echo '===================' >> ".foo::$execut_log." && echo \"Command:( ".$wcmd." ):\" >> ".foo::$execut_log." && echo 'OUTPUT: ".$buf."' >> ".foo::$execut_log."");
		}
		//echo "buf=$buf <br>";
		if($output > 0){
			$res=($buf!="")?${buf}:0;//0=>success
		}else{
			$res=($buf=="")?0:$buf;
		}
		//echo "foo sys log = ${syslog_str}<br>";
		//echo "foo sys error code = ".$this->error_code."<br>";
		if($syslog_str!="") {
			if($res=="0") {
				self::syslog($syslog_prog,$syslog_str,"info");
			} //else {
				//self::syslog($syslog_prog,$syslog_str,"error");
			//}
		}
		//echo "foo res = ${res}<br>";
		return $res;
	}

	//===========================================================
	//	Like UNIX shell and C language
	//	0 => Succes
	//	others => Fail
	//===========================================================
	public function errorer($error_code=1,$error_msg="",$error_prog="") {
		if($error_msg!="") {
			self::syslog($error_prog,$error_msg,"error");
		}
		$error_code=($error_code==0)?1:$error_code;
		return $error_code;
	}

	//===========================================================
	//	Call to print javascript alert
	//===========================================================
	public function js_alert($msg,$direct="") {
		$tpl="<script language='javascript'>alert(\"%s\");%s</script>\n";
		$direct=($direct=="")?"history.back();":"location.href='".$direct."';";
		return sprintf($tpl,$msg,$direct);
	}

	//===========================================================
	//	foo::syslog($PROGRAM,$STRING_TO_LOG)
	//===========================================================
	public function syslog($program,$string,$switch="error") {
		switch ($switch) {
		case "error":
			$level=LOG_ERR;
			break;
		case "info":
			$level=LOG_INFO;
			break;
		case "warning":
			$level=LOG_WARNING;
			break;
		}
		$string=($string!="")?"{".$string."}":"";
		$program=($program=="")?"System":$program;
		define_syslog_variables();
		@openlog($program,LOG_ODELAY,LOG_USER);//LOG_USER);
		@syslog($level,$string);
		return @closelog();
	}

	//===========================================================
	//	Load a html template
	//===========================================================
	public function miniTemplate($file_string, $vars=array()) {
		return str_replace(array_keys($vars), array_values($vars), $file_string);
	}

	//===========================================================
	//	This func will delete all
	//===========================================================
	public function DelRecords($file,$pattern,$comment=FALSE) {
		$larr=file($file);
		foreach($larr as $k=>$v) {
			if(preg_match($pattern,$v)) {
				if($comment) $larr[$k]="###".trim($v)."\n";
				else unset($larr[$k]);
			}
		}
		return $larr;
	}

	//===========================================================
	//	This func write config value back    
	//===========================================================
	public function WriteBack($file,$lines_arr,$type="write") {
		$type=($type=="w" || $type=="write")?"w+":"a+";
		$fh=fopen($file,$type);
		if(!$fh) return FALSE;
		flock($fh,LOCK_EX);
		foreach($lines_arr as $s) {
			fputs($fh,$s,strlen($s));
		}
		fflush($fh);
		flock($fh,LOCK_UN);
		@fclose($fh);
		return TRUE;
	}

	//===========================================================
	//	End of class
	//===========================================================
}

define(SUCCESS_WILL_PRINT_ON_CONSOLE,		1);
define(FAIL_WILL_PRINT_ON_CONSOLE,		0);
define(PROGRESS_BAR_NEEDED,			1);
define(PROGRESS_BAR_NOT_NEEDED,			0);

define(SATA_LED_OFF,				0);
define(SATA_LED_ON,				1);
define(SATA_LED_BLINK,				2);

define(RAID_CREATE_ERROR,			501);
define(RAID_CREATE_ABORTED,			502);
define(RAID_REBUILD_ERROR,			503);
define(RAID_REBUILD_ABORTED,			504);
define(RAID_ADD_SPARE_ERROR,			505);
define(RAID_ADD_SPARE_ABORTED,			506);
define(RAID_ONE_PLUS_ZERO_CREATE_ERROR,		507);
define(RAID_NO_MORE_DISK_AVAILABLE,		508);
define(RAID_ADD_SPARE_SIZE_ERROR,		509);

define(LVM_PVSCAN_ERROR,			601);
define(LVM_VGSCAN_ERROR,			602);
define(LVM_PV_CREATE_ERROR,			603);
define(LVM_VG_CREATE_ERROR,			604);
define(LVM_LV_CREATE_ERROR,			605);
define(LVM_LV_RESIZE_ERROR,			606);
define(LVM_LV_SHRINK_ERROR,			607);
define(LVM_LV_EXTEND_ERROR,			608);
define(LVM_LV_EXCEED_LIMIT,			609);
define(LVM_MKE2FS_ERROR,			610);
define(LVM_CREATE_MOUNTPOINT_ERROR,		611);
define(LVM_MOUNT_MOUNTPOINT_ERROR,		612);
define(LVM_SET_DEFAULT_ACL_ERROR,		613);
define(LVM_WRITE_FSTAB_ERROR,			614);
define(LVM_THIEF_LV_CREATE_ERROR,		615);
define(LVM_THIEF_MKE2FS_ERROR,			616);
define(LVM_THIEF_CREATE_MOUNTPOINT_ERROR,	617);
define(LVM_THIEF_MOUNT_MOUNTPOINT_ERROR,	618);
define(LVM_THIEF_SET_DEFAULT_ACL_ERROR,		619);
define(LVM_REMOVE_LOST_AND_FOUND_ERROR,		620);
define(PV_CREATE_FAIL,				621);
define(VG_EXTEND_FAIL,				622);

define(USER_PUSH_STOP_BUTTON,			701);
define(SAMBA_RESTART_ERROR,			702);

define(LOG_MSG_RAID_CREATE_ABORTED_USER,		"User aborted raw raid creation process");
define(LOG_MSG_RAID_CREATE_ABORTED,			"Raw raid creation process stop");
define(LOG_MSG_RAID_CREATE_ERROR,			"Raw raid creation failed");
define(LOG_MSG_RAID_CREATE_SUCCESS,			"Raw raid creation success");
define(LOG_MSG_RAID_CREATE_START,			"Raw raid creation start");

define(LOG_MSG_RAID_ADD_SPARE_ABORTED_USER,		"User aborted raid add spare process");
define(LOG_MSG_RAID_ADD_SPARE_ABORTED,			"Raid add spare process stop");
define(LOG_MSG_RAID_ADD_SPARE_ERROR,			"Raid add spare failed");
define(LOG_MSG_RAID_ADD_SPARE_SUCCESS,			"Raid add spare success");
define(LOG_MSG_RAID_ADD_SPARE_START,			"Raid add spare start");
define(LOG_MSG_RAID_ADD_SPARE_SIZE_ERROR,		"Not large enough size to join RAID");

define(LOG_MSG_RAID_REBUILD_ABORTED_USER,		"User aborted raid rebuild process");
define(LOG_MSG_RAID_REBUILD_ABORTED,			"Raid rebuild process stop");
define(LOG_MSG_RAID_REBUILD_ERROR,			"Raid rebuild failed");
define(LOG_MSG_RAID_REBUILD_SUCCESS,			"Raid rebuild success");
define(LOG_MSG_RAID_REBUILD_START,			"Raid rebuild start");

define(LOG_MSG_RAID_MONITOR_ENABLE,			"Enable raid monitor");
define(LOG_MSG_RAID_MONITOR_DISABLE,			"Disable raid monitor");
define(LOG_MSG_RAID_ASSEMBLER_ENABLE,			"Enable raid assembler");
define(LOG_MSG_RAID_ASSEMBLER_DISABLE,			"Disable raid assembler");

define(LOG_MSG_LVM_PVSCAN_ERROR,			"pvscan failed");
define(LOG_MSG_LVM_PV_CREATE_ERROR,			"pv creation failed");
define(LOG_MSG_LVM_VGSCAN_ERROR,			"vgscan failed");
define(LOG_MSG_LVM_VG_CREATE_ERROR,			"vg creation failed");

define(LOG_MSG_LVM_LV_CREATE_ERROR,			"logical volume %s creation failed");
define(LOG_MSG_LVM_MKE2FS_ERROR,			"%s mke2fs error");
define(LOG_MSG_LVM_CREATE_MOUNTPOINT_ERROR,		"mount point %s mkdir error");
define(LOG_MSG_LVM_MOUNT_MOUNTPOINT_ERROR,		"mount %s error");
define(LOG_MSG_LVM_SET_DEFAULT_ACL_ERROR,		"%s set default acl error");
define(LOG_MSG_LVM_WRITE_FSTAB_ERROR,			"%s writing to fstab failed");
define(LOG_MSG_ADD_SHARE_SUCCESS,			"add share %s success");
define(LOG_MSG_DELETE_SHARE_SUCCESS,			"delete share %s success");
define(LOG_MSG_ADD_NFSSHARE_SUCCESS,			"add nfs share %s success");
define(LOG_MSG_DELETE_NFSSHARE_SUCCESS,			"delete nfs share %s success");
define(LOG_MSG_LVM_LV_SHRINK_ERROR,			"Shrink share \"%s\" failed");
define(LOG_MSG_LVM_LV_EXTEND_ERROR,			"Extend share \"%s\" failed");
define(LOG_MSG_LVM_LV_SHRINK_SUCCESS,			"Shrink share \"%s\" success");
define(LOG_MSG_LVM_LV_EXTEND_SUCCESS,			"Extend share \"%s\" success");
define(LOG_MSG_ADD_SNAPSHARE_SUCCESS,			"add snapshot share %s success");
define(LOG_MSG_DELETE_SNAPSHARE_SUCCESS,			"delete snapshot share %s success");
?>
