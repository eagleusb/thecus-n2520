<?php
require_once("inifile.class.php");
require_once("foo.class.php");
require_once("db.class.php");
//===============================================================
//
//	By "kevincheng@thecus.com" on May,3th,2006
//	
//	/* New an instance */
//	$AfpConf=new AfpConf();
//
//
//===============================================================

class AfpConf extends foo {

	//===============================================================
	//
	//	[DEFAULT]:
	//		guest ok=no
	//		read only=yes
	//	[POLICY]:
	//		read only=yes
	//		valid users=FAKE_ACCOUNT
	//	[IMPORTANT]:
	//		valid users=##empty
	//			if "valid users" is empty, then any users can login.
	//		guest ok=yes
	//			if "guest ok" is yes, then no password is required to connect to.
	//	[SYNONYM]:
	//		"public" == "guest ok"
	//		"writeable" == "read only" (inverted)
	//	[PRIORITY]:
	//		"write list" > "read list"
	//		"write list" > "read only=yes"
	//		"read list" > "read only=no"
	//		"guest ok" > "invalid users" > "valid users"
	//	[SUMMARY]:
	//		whole share is full access => writeable="yes"
	//		whole share is read only => writeable="no"
	//		users have full access => write list
	//		users no login => invalid users
	//		users can login => valid users
	//		no matter share is full access or read only still can => valid users
	//		deny individual => invalid users
	//		don't wanna password => guest ok="yes" (but need a guest account)
	//	[SCENARIO]:
	//		share read only, some users can write:
	//			writeable=no
	//			write list=user1, user2
	//			valid users=
	//		share read only, no users can write:
	//			writeable=no
	//			valid users=
	//		share writeable, some users cannot write:
	//			writeable=yes
	//			read list=user1, user2
	//			valid users=
	//		share writeable, everyone could write
	//			writeable=yes
	//			valid users=
	//		share deny everyone, only some can read, some can write
	//			valid users=user1, user2, user3
	//			write list=user1
	//			read list=user2, user3
	//			
	//===============================================================
	public static $keys=array();
	private static $mapping=array("_path","_comment","_browseable","_guest_only");
	private static $ini=FALSE;
	private static $share;
	const conf="/etc/netatalk/AppleVolumes.default";
	const raidpath="/raid/data";

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
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		//$FOLDER = self::raidpath . "/" . $sharename . " " . $sharename . " option:upriv";
		$FOLDER = self::raidpath . "/" . $sharename . " " . $sharename;
		//echo "FOLDER=$FOLDER <br>";
		self::$ini->del_keyline($FOLDER);
		return ;
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function addShare($sharename) {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		//$write_data = self::raidpath . "/" . $sharename . " " . $sharename . " option:upriv";
  	$dbtool=new dbtool();
  	$dbtool->connect();
		$afpd_charset=$dbtool->db_getvar("httpd_charset","0");
		$dbtool->db_close();
		
		$write_data = "\"" . self::raidpath . "/" . $sharename . "\" \"" . $sharename . "\" options:usedots maccharset:" . $afpd_charset . " volcharset:UTF8";
		self::$ini->add_keyline($write_data);
		return ;
	}

	//===============================================================
	//	to list ALL sections except [global]
	//===============================================================
	public function toListAllShares() {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$secs=self::$ini->enum_sections();
		$re=array();
		foreach($secs as $s) {
			if($s!="global") {
				$re[]=$s;
			}
		}
		return $re;
	}

	//===============================================================
	//	this method could do reload config
	//===============================================================
	public function hup() {
		//$cmd="/img/bin/samba_check;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/nmbd.pid`;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/smbd.pid`;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/winbindd.pid`";
		$cmd="/img/bin/rc/rc.atalk restart > /dev/null 2>&1 &";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do restart samba process
	//===============================================================
	public function restart() {
		//$cmd="/img/bin/rc/rc.samba restart > /dev/null 2>&1";
		$cmd="/img/bin/rc/rc.atalk restart >> /tmp/afpd.err 2>&1";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do stop samba process
	//===============================================================
	public function stop() {
		$cmd="/img/bin/rc/rc.atalk stop > /dev/null 2>&1";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do start samba process
	//===============================================================
	public function start() {
		$cmd="/img/bin/rc/rc.atalk start > /dev/null 2>&1";
		return self::execute($cmd);
	}
}
?>
