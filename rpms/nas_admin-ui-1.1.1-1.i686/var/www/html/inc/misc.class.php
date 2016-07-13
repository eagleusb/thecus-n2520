<?php
require_once("info/lvminfo.class.php");
require_once("foo.class.php");
class misc {
	//================================================
	//	!!!! FOR N4500 !!!!
	//	$arr=misc::du_mapper()
	//	$arr is a two-dimension array
	//================================================
	public static function du_mapper() {
		$x=new LVMINFO();
		$arr=$x->getINFO();
		$lvsize=$arr["LVList"];
		unset($x);
		//$cmd="df -h | awk 'BEGIN{OFS=\",\"}{print $1,$4,$5}'";
		$cmd="df -h | /usr/bin/awk 'BEGIN{OFS=\",\"}\$1~/mapper\/rootvg\-lv/{device=\$1;counter=NR+1;} (NR==counter){size=\$1;percentage=\$4;print device,size,percentage}'";
		$output=shell_exec($cmd);
		$output=explode("\n",trim($output));
		$arr=array();
		foreach($output as $o) {
			list($fs,$size,$usage)=explode(",",$o);
			list($a,$lv)=explode("-",basename($fs));
			$arr[$fs]=array();
			$arr[$fs]['size']=$lvsize[$lv];
			$arr[$fs]['usage']=$usage;
		}
		return $arr;
	}

	//================================================
	//	!!!! FOR N4100 !!!!
	//	$arr=misc::du()
	//	$arr is a two-dimension array
	//================================================
	public static function du() {
		$x=new LVMINFO();
		$arr=$x->getINFO();
		$lvsize=$arr["LVList"];
		unset($x);
		$cmd="df -h | awk 'BEGIN{OFS=\",\"}NR>1{print $1,$4,$5}'";
		//print $cmd;print "<hr>";
		$output=shell_exec($cmd);
		//print $output;print "<hr>";
		$output=explode("\n",trim($output));
		$arr=array();
		foreach($output as $o) {
			list($fs,$size,$usage)=explode(",",$o);
			$lv=basename($fs);
			$arr[$fs]=array();
			//$arr[$fs]['size']=$size;
			$arr[$fs]['size']=$lvsize[$lv];
			$arr[$fs]['usage']=$usage;
		}
		return $arr;
	}

	//================================================
	//	misc::syslog($PROGRAM,$STRING_TO_LOG)
	//================================================
	public static function syslog($program,$string,$switch="e") {
		switch ($switch) {
		case "e":
			$level=LOG_ERR;
			break;
		case "i":
			$level=LOG_INFO;
			break;
		case "w":
			$level=LOG_WARNING;
			break;
		}
		$string="{".$string."}";
		define_syslog_variables();
		@openlog($program,LOG_ODELAY,LOG_USER);//LOG_USER);
		@syslog($level,$string);
		return @closelog();
	}

	//================================================
	//	Load a html template
	//================================================
	public static function Template($file_string, $vars=array()) {
		return str_replace(array_keys($vars), array_values($vars), $file_string);
	}
}
?>
