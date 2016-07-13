<?php
require_once("inifile.class.php");
require_once("foo.class.php");
require_once("smbconf.class.php");
//===============================================================
//
//	By "kevincheng@thecus.com" on May,3th,2006
//	
//	/* New an instance */
//	$AfpConf=new AfpConf();
//
//
//===============================================================

class SnapshotConf extends foo {
	public static $keys=array();
	private static $mapping=array("_path","_comment","_browseable","_guest_only");
	private static $ini=FALSE;
	private static $SmbConf=False;
	private static $share;
	const conf="/etc/samba/smb.conf";
	const raidpath="/raid/snapshot";
	const lvpath="/dev/vg0";

	//===============================================================
	//	Use to set share name
	//===============================================================
	public function setShare($val) {
		return self::$share=$val;
	}

	//===============================================================
	//	To retrieve share path
	//===============================================================
	public function getPath() {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$v=self::$ini->get_key(self::$share,"path");
		return $v;
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function deleteShare($sharename) {
		/*if(!self::$SmbConf){ self::$SmbConf=new SmbConf();}
		self::$SmbConf->deleteShare($sharename);
		*/
		$use_qt=shell_exec("cat /tmp/use_qtman");
		
		$sharepath=self::raidpath . "/" . $sharename;
		$strExec="";
		//if (is_dir($sharepath)) {
			if ($use_qt=="1") {
				$strExec=$strExec . "cat /proc/qtamgn > /raid/sys/quota.conf;sync;rmmod qtamgn;";
			}
			$strExec=$strExec . "umount " . $sharepath . " > /dev/null 2>&1 ;";
			$devpath=self::lvpath . "/" . $sharename;
			$strExec=$strExec . "lvchange -an " . $devpath . " > /dev/null 2>&1 ;";
			$strExec=$strExec . "lvremove -f " . $devpath . " > /dev/null 2>&1 ;";
			if ($use_qt=="1") {
				$strExec=$strExec . "modprobe qtamgn;";
				$strExec=$strExec . "/img/bin/update_quota.sh;";
			}
			//echo "strExec=$strExec <br>";
			self::execute($strExec);
			
			if (!rmdir($sharepath)) {
				return 1;
			}
		//} 

		return 0;
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function addShare() {
		$db = sqlite_open('/etc/cfg/conf.db');
		$rs = sqlite_query($db,"select v from conf where k='snapshot_autodel'");
		$snapshot_autodel = sqlite_fetch_single($rs);
		sqlite_close($db);
		//echo "snapshot_autodel=" . $snapshot_autodel . "<br>";
		if ($snapshot_autodel=="1") {
			$strExec="/img/bin/create_snaplv.sh \"autodel\"";
		} else {
			$strExec="/img/bin/create_snaplv.sh";
		}
		$snapfolder=exec($strExec);
		
		$pattern = '/Fail/';
		//echo "snapfolder=$snapfolder <br>";
		preg_match($pattern, $snapfolder,$match);
		if ($match[0]) {
			//echo "Fail ...";
			return 1;
		} else {
				/*if(!self::$SmbConf){ self::$SmbConf=new SmbConf(); }
				self::$SmbConf->setShare($snapfolder);
				self::$SmbConf->setShareDefaultParameters();
				self::$SmbConf->modifyArgv("comment","snapshot folder");
				self::$SmbConf->modifyArgv("browseable","no");
				self::$SmbConf->modifyArgv("guest only","no");
				self::$SmbConf->modifyArgv("read only","yes");
				self::$SmbConf->modifyArgv("path",self::raidpath . "/" . $snapfolder);
				self::$SmbConf->modifyArgv("map hidden","yes");
				
				$strExec="setfacl -P -d -m admin::rx ". (self::raidpath . "/" . $snapfolder);
				echo "strExec=$strExec <br>";
				shell_exec($strExec);
      	
				self::$SmbConf->commit();
				self::$SmbConf->hup();
				*/
				return 0;
		}
	}

	//===============================================================
	//	this method could do reload config
	//===============================================================
	public function hup() {
		$cmd="/img/bin/rc/rc.samba restart > /dev/null 2>&1 &";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do restart samba process
	//===============================================================
	public function restart() {
		$cmd="/img/bin/rc/rc.samba restart >> /tmp/samba.err 2>&1";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do stop samba process
	//===============================================================
	public function stop() {
		$cmd="/img/bin/rc/rc.samba stop > /dev/null 2>&1";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do start samba process
	//===============================================================
	public function start() {
		$cmd="/img/bin/rc/rc.samba start > /dev/null 2>&1";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method to reload config
	//===============================================================
	public function reload() {
		$cmd="/usr/bin/smbcontrol smbd reload-config &&";
		$cmd.="/usr/bin/smbcontrol nmbd reload-config";
		return self::execute($cmd);
	}
}
?>
