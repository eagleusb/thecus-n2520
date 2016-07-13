<?php
require_once("inifile.class.php");
require_once("foo.class.php");
require_once("sqlitedb.class.php");
//===============================================================
//
//	By "hubert_huang@thecus.com" on January,5th,2005
//	
//	/* New an instance */
//	$SmbConf=new SmbConf();
//
//	/* To add new share, MUST need commit() */
//	$SmbConf->setShare("SHARE_NAME");
//	$SmbConf->comb($_POST);
//	$SmbConf->setShareDefaultParameters();
//	$SmbConf->commit();
//
//	/* Set [global] workgroup */
//	$SmbConf->setWorkGroup("WORKGROUP");
//
//	/* Retrieve share path */
//	$SmbConf->getPath();
//
//===============================================================

class SmbConf extends foo {

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
	public static $share;
	const conf="/etc/samba/smb.conf";
	const fake="FAKE_ACCOUNT";

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
        //      Modify argv
        //===============================================================
        public function modifyArgv($k,$v) {
                self::$keys["{$k}"]="{$v}";
                return ;
        }

	//===============================================================
	//	To retrieve share path's mapping /dev/rootvg/lv-num
	//===============================================================
	public function getDevicePath() {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$v=self::$ini->get_key(self::$share,"path");
		$v="/dev/rootvg/".basename($v);
		return $v;
	}

	//===============================================================
	//	To retrieve specified KEY
	//===============================================================
	public function getSetting($key) {
		if (NAS_DB_KEY == '1'){
			if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
			$v=self::$ini->get_key(self::$share,$key);
		}else if (NAS_DB_KEY == '2'){
			$smbdb=new sqlitedb('/raid/sys/smb.db','smb_global');
			//$v=$smbdb->db_runSQL("select v from smb_global where k='$key'");
			$rs=$smbdb->getvar("$key","");
			unset($smbdb);
		}
		return $v;
	}

	//===============================================================
	//	To retrieve specified KEY
	//===============================================================
	public function setValue($key,$val) {
		if (NAS_DB_KEY == '1'){
			if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
			return self::$ini->set_key(self::$share,$key,$val);
		}else if (NAS_DB_KEY == '2'){
			if (file_exists('/raid/sys/smb.db')){
				$smbdb=new sqlitedb('/raid/sys/smb.db','smb_global');
				//$rs=$smbdb->db_runSQL("update smb_global set v='$val',m='0' where k='$key'");
				$rs=$smbdb->setvar("$key", "$val");
				unset($smbdb);
			}
			return $rs;
		}
	}

	//===============================================================
	//	To arrange $_POST like comb hairs
	//===============================================================
	public function comb($arr) {
		foreach($arr as $k=>$v) {
			if(in_array($k,self::$mapping)) { 
				$k=substr($k,1);
				$k=str_replace("_"," ",$k);
				self::$keys[$k]=$v;
			}
		}
		return;
	}

	//===============================================================
	//	As this function's name
	//===============================================================
	public function setShareDefaultParameters() {
		self::$keys["map acl inherit"]="yes";
		self::$keys["inherit acls"]="yes";
		//self::$keys["profile acls"]="yes";
		self::$keys["read only"]="no";
		self::$keys["create mask"]="0777";
		self::$keys["force create mode"]="0000";
		self::$keys["inherit permissions"]="Yes";
		//self::$keys["map system"]="yes";
		self::$keys["map archive"]="yes";
		self::$keys["map hidden"]="yes";
		self::$keys["#recursive"]="yes";
		return;
	}

	//===============================================================
	//	Write back to real smb.conf
	//===============================================================
	public function commit() {
		//echo "self::conf=" . self::conf . "<br>";
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		
		foreach(self::$keys as $k => $v) {
			self::$ini->set_key(self::$share,$k,$v);
			//print "sharename=>(".self::$share."),key=>(".$k."),nalue=>(".$v.")";print "\n<hr>\n";
		}
		self::$keys=array();
	}

	//===============================================================
	//	Used to build "write list"
	//===============================================================
	private static function buildWriteList($arr) {
		if(!is_array($arr) || count($arr)<1) return;
		$write_list="";
		foreach($arr as $s) {
			$write_list.=",".(string)$s;
		}
		$write_list=ltrim($write_list,",");
		return self::$keys["write list"]=$write_list;
	}

	//===============================================================
	//	Used to build "read list"
	//===============================================================
	private static function buildReadList($arr) {
		if(!is_array($arr) || count($arr)<1) return;
		$read_list="";
		foreach($arr as $s) {
			$read_list.=",".(string)$s;
		}
		$read_list=ltrim($read_list,",");
		return self::$keys["read list"]=$read_list;
	}

	//===============================================================
	//	Used to build "valid users" list, special : accept 2 arrays
	//===============================================================
	private static function buildValidUsers($arr1,$arr2="") {
		if(!is_array($arr1) || count($arr)<1) return;
		$valid_users=self::fake;
		foreach($arr1 as $s) {
			$valid_users.=",".(string)$s;
		}
		if(is_array($arr2)) {
			foreach($arr2 as $t) {
				$valid_users.=",".(string)$t;
			}
		}
		$valid_users=ltrim($valid_users,",");
		return self::$keys["valid users"]=$valid_users;
	}

	//===============================================================
	//	Used to build "invalid users" list,
	//===============================================================
	private static function buildInvalidUsers($arr) {
		if(!is_array($arr) || count($arr)<1) return;
		$invalid_users="";
		foreach($arr as $s) {
			$invalid_users.=",".(string)$s;
		}
		$invalid_users=ltrim($invalid_users,",");
		return self::$keys["invalid users"]=$invalid_users;
	}

	//===============================================================
	//	residual
	//===============================================================
	private static function setLogic() {
		return;
	}

	//===============================================================
	//	To delete whole SHARE section
	//===============================================================
	public function deleteShare($sharename) {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$keysarr=self::$ini->enum_keys($sharename);
		foreach($keysarr as $k) {
			if(self::$ini->del_key($sharename,$k)) {
				//echo "sharename=$sharename   k=$k  <br>";
				continue;
			}
			return FALSE;
		}
		return self::$ini->del_sec($sharename);
	}

	//===============================================================
	//	for AD use, to set ALL section "admin users"
	//===============================================================
	public function setAllAdmins($userList) {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$secs=self::$ini->enum_sections();
		foreach($secs as $s) {
			if($s!="global") {
				self::$ini->set_key($s,"admin users",$userList);
			}
		}
		return;
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
	//	Setting ONE section "admin users"
	//===============================================================
	public function setAdminUsers($userList) {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		$val="";
		foreach($userList as $u) {
			$val.=", ".$u;
		}
		$val=ltrim($val,",");
		$val=trim($val);
		return self::$ini->set_key(self::$share,"admin users",$val);
	}

	//===============================================================
	//	for AD use, to set "global" section "workgroup"
	//===============================================================
	public function setWorkGroup($val) {
		if(!self::$ini){ self::$ini=new inifile(self::conf,FALSE); }
		return self::$ini->set_key("global","workgroup",$val);
	}

	//===============================================================
	//	this method could do reload config
	//===============================================================
	public function hup() {
		//$cmd="/img/bin/samba_check;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/nmbd.pid`;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/smbd.pid`;";
		//$cmd.="/bin/kill -HUP `cat /var/locks/winbindd.pid`";
		$cmd="/img/bin/rc/rc.samba restart > /dev/null 2>&1 &";
		return self::execute($cmd);
	}

	//===============================================================
	//	this method could do restart samba process
	//===============================================================
	public function restart($winad_enable) {
		//$cmd="/img/bin/rc/rc.samba restart > /dev/null 2>&1";
		if (NAS_DB_KEY == '1'){
			if($winad_enable){
			  $cmd="/img/bin/rc/rc.samba restart ".$winad_enable." >> /tmp/samba.err 2>&1";
			}else{
			  $cmd="/img/bin/rc/rc.samba restart >> /tmp/samba.err 2>&1";
			}
		}else if (NAS_DB_KEY == '2'){
			$cmd="/img/bin/rc/rc.samba restart testad > /dev/null 2>&1";
		}
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
