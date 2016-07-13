<?php
require_once("inifile.class.php");
require_once("foo.class.php");
//===============================================================
//
//	By "kevincheng@thecus.com" on May,3th,2006
//	
//	/* New an instance */
//	$AfpConf=new AfpConf();
//
//
//===============================================================

class NfsConf extends foo {

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
	const conf="/etc/exports";
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
	//	to list ALL sections except [global]
	//===============================================================
	public function toListAllExport($sharename="",$avilableip="") {
    $retlist = array();
    if ($ifile = @file(self::conf))
      {
      foreach ($ifile as $vValue)
        {
        	$aryshare=array();
        	list($leftdata,$rightdata)=explode(' ', trim($vValue));
        	list($aryshare["none"],$aryshare["none1"],$aryshare["path"],$aryshare["path2"],$aryshare["sharename"])=preg_split('/["/]/', $leftdata);
        	if ($aryshare["none1"]!="") {
	        	list($aryshare["none"],$aryshare["path"],$aryshare["path2"],$aryshare["sharename"])=explode('/', $leftdata);
        	}
        	list($aryshare["avilableip"],$aryshare["writed"],$aryshare["rooted"],$aryshare["synced"])=preg_split('/[(),]/', $rightdata);
        	/*
        	echo "none=" . $aryshare["none"] . "<br>";
        	echo "path=" . $aryshare["path"] . "<br>";
        	echo "path2=" . $aryshare["path2"] . "<br>";
        	echo "sharename=" . $aryshare["sharename"] . "<br>";
        	echo "avilableip=" . $aryshare["avilableip"] . "<br>";
        	echo "writed=" . $aryshare["writed"] . "<br>";
        	echo "rooted=" . $aryshare["rooted"] . "<br>";
        	echo "synced=" . $aryshare["synced"] . "<br>";*/
        	if (($sharename!="")&& ($avilableip!=="")) {
        		if (($sharename==$aryshare["sharename"]) && ($avilableip==$aryshare["avilableip"])) {
        			$retlist[]=$aryshare;
        		}
        	} elseif ($sharename!="") {
        		if ($sharename==$aryshare["sharename"]) {
        			$retlist[]=$aryshare;
        		}
        	} elseif ($avilableip!="") {
        		if ($avilableip==$aryshare["avilableip"]) {
        			$retlist[]=$aryshare;
        		}
        	} else {
        		$retlist[]=$aryshare;
        	}
        	
        }
      }
    return $retlist;

	}

	//===============================================================
	//	merge parameter to exportfs format
	//===============================================================
	public function mergeShare($sharename,$avilableip="*",$writed="rw",$rooted="no_root_squash") {
		if ($sharename) {
			$retstr=sprintf("\"%s/%s\" %s(%s,%s,sync,anonuid=99,anongid=99)",self::raidpath,$sharename,$avilableip,$writed,$rooted);
		} else {
			$retstr="";
		}
		//echo "retstr=" . $retstr . "<br>";
		return $retstr;
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function deleteShare($sharename,$avilableip) {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		
		$arymatch=self::toListAllExport($sharename,$avilableip);
		foreach ($arymatch as $deldata) {
			$delkey = self::mergeShare($deldata["sharename"],$deldata["avilableip"],$deldata["writed"],$deldata["rooted"]);
			self::$ini->del_keyline($delkey);
		}
		return ;
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function addShare($sharename,$avilableip="*",$writed="rw",$rooted="no_root_squash") {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$arymatch=self::toListAllExport($sharename,$avilableip);
		$isexist=0;
		foreach ($arymatch as $chkdata) {
			if (($sharename==$chkdata["sharename"]) && ($avilableip==$chkdata["avilableip"])) {
				$isexist=1;
				break;
			}
		}
		
		//echo "isexist=" . $isexist . "  sharename='" . $sharename . "'<br>";
		if ($isexist==0) {
			$write_data = self::mergeShare($sharename,$avilableip,$writed,$rooted);
			//echo "write_data=$write_data <br>";
			//echo "self::conf=" . self::conf . "<br>write_data=$write_data <br>";
			self::$ini->add_keyline($write_data);
			return 0;
		} else {
			return 1;
		}
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function modShare($sharename,$avilableip="*",$writed="rw",$rooted="no_root_squash") {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		
		//echo "sharename=$sharename <br>avilableip=$avilableip <br>";
		$arymatch=self::toListAllExport($sharename,$avilableip);
		foreach ($arymatch as $moddata) {
			$oldkey = self::mergeShare($moddata["sharename"],$moddata["avilableip"],$moddata["writed"],$moddata["rooted"]);
			$newkey = self::mergeShare($moddata["sharename"],$moddata["avilableip"],$writed,$rooted);
			//echo "oldkey=$oldkey <br>";
			//echo "newkey=$newkey <br>";
			self::$ini->mod_keyline($oldkey,$newkey);
		}
		return 0;
	}

	//===============================================================
	//	this method could do reload config
	//===============================================================
	public function hup() {
		//$cmd="/img/bin/samba_check;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/nmbd.pid`;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/smbd.pid`;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/winbindd.pid`";
		if (NAS_DB_KEY == 1){
			//$cmd="/img/bin/rc/portmap reload > /dev/null 2>&1 &";
			$cmd="/img/bin/rc/nfsd reload > /dev/null 2>&1";
		}else{
			//$cmd="/img/bin/rc/rc.portmap reload > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/rc.nfsd reload > /dev/null 2>&1";
		}
		//echo "cmd=$cmd <br>";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do restart samba process
	//===============================================================
	public function restart() {
		//$cmd="/img/bin/rc/rc.samba restart > /dev/null 2>&1";
		if (NAS_DB_KEY == 1){
			$cmd="/img/bin/rc/portmap restart > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/nfs restart > /dev/null 2>&1 &";
		}else{
			$cmd="/img/bin/rc/rc.portmap restart > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/rc.nfs restart > /dev/null 2>&1 &";
		}
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do stop samba process
	//===============================================================
	public function stop() {
		if (NAS_DB_KEY == 1){
			$cmd="/img/bin/rc/portmap stop > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/nfs stop > /dev/null 2>&1 &";
		}else{
			$cmd="/img/bin/rc/rc.portmap stop > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/rc.nfs stop > /dev/null 2>&1 &";
		}
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do start samba process
	//===============================================================
	public function start() {
		if (NAS_DB_KEY == 1){
			$cmd="/img/bin/rc/portmap start > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/nfs start > /dev/null 2>&1 &";
		}else{
			$cmd="/img/bin/rc/rc.portmap start > /dev/null 2>&1 &";
			$cmd.="/img/bin/rc/rc.nfs start > /dev/null 2>&1 &";
		}
		return self::execute($cmd);
	}
}
?>
