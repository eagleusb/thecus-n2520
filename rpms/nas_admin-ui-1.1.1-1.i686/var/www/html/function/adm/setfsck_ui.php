<?
//require_once("../setlang/lang.html");
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

$gwords = $session->PageCode("global");
$words = $session->PageCode("fsck");

$action=trim($_POST['action']);


$fsck_flag=trim(shell_exec('cat /etc/fsck_flag'));
$tmp_fsck_dev="/tmp/fsck_dev";
//echo "<pre>";
//print_r($_POST);
//echo $action;
//shell_exec("echo ${action} > /tmp/test");exit;

if($action!="" && is_file("/etc/fsck_flag") && $fsck_flag=="1"){
	if($action=="start"){
		shell_exec("echo ${action} > /tmp/test");
		shell_exec('/img/bin/fsck.sh');
		exit;
	}elseif($action=="next"){
		$strExec="rm -f ${tmp_fsck_dev}";
		shell_exec($strExec);
		$md_array=explode(",",trim($_POST["md_num"]));
		foreach($md_array as $md_num){
			if($md_num!=""){
				if (NAS_DB_KEY == 1)
                  $vg_num=$md_num-1;
                elseif (NAS_DB_KEY == 2)
                  $vg_num=$md_num;
                  
				$strExec="echo \"${vg_num}\" >> ${tmp_fsck_dev}";
				shell_exec($strExec);
			}
		}
		exit;
	}elseif($action=="stop"){
		$cmd="killall e2fsck";
		shell_exec($cmd);
		$strExec="/bin/touch /tmp/fsck_stop";
		shell_exec($strExec);
		sleep(2);
		shell_exec('rm -f /tmp/lns.lock');
		return  MessageBox(true,$words['fsck_title'],$gwords['stop']);
		exit;
	}elseif($action=="reboot"){
		//reboot_func($words);
		flush();
		shell_exec('rm -f /etc/fsck_flag');
		shell_exec('rm -f /tmp/lns*');
		if (NAS_DB_KEY == '1'){
		  shell_exec('/img/bin/model/sysdown.sh reboot > /dev/null 2>&1 &');
		}else{
		  shell_exec('/img/bin/sys_reboot > /dev/null 2>&1 &');
		}
		return  ProgressBar(true,$words['fsck_title'],$gwords["reboot"],"ProgressBar",1,intval($sysconf["boot_time"]));
		exit;
	}elseif($action=="syslv"){
		shell_exec('/img/bin/lns5200 -c "/sbin/e2fsck -fy /dev/vg0/syslv -C 1" -o "/tmp/lns_sys.log" > /dev/null 2>&1 &');
		//header('Location: /adm/getform.html?name=fsck_ui');
		exit;
	}
}

function reboot_func($words){
  global $words,$url,$html;
  require_once("../../inc/db.class.php");
  require_once("/var/www/html/function/conf/webconfig");
  include_once("../../inc/msgbox.inc.php");
  $command = "/img/bin/model/sysdown.sh reboot";
  $db = sqlite_open("/etc/cfg/conf.db");
  $rs = sqlite_query($db,"select v from conf where k='nic1_ipv4_dhcp_client'");
  $lan1 = sqlite_fetch_single($rs);
  $rs = sqlite_query($db,"select v from conf where k='nic1_ip'");
  $lan1_ip = sqlite_fetch_single($rs);
  $rs = sqlite_query($db,"select v from conf where k='nic2_ip'");
  $lan2_ip = sqlite_fetch_single($rs);
  $rs = sqlite_query($db,"select v from conf where k='httpd_nic1_httpd'");
  $httpd = sqlite_fetch_single($rs);
  $rs = sqlite_query($db,"select v from conf where k='httpd_port'");
  $httpd_port = sqlite_fetch_single($rs);
  $rs = sqlite_query($db,"select v from conf where k='httpd_ssl'");
  $httpd_ssl = sqlite_fetch_single($rs);
  
  sqlite_close($db);
  $url = $httpd=='1' ? "http://" : "https://";
  $url .= $webconfig['default_interface']=="lan1"? $lan1_ip : $lan2_ip;
  $url .= ":";
  $url .= $httpd=='1' ? $httpd_port : $httpd_ssl;
  $url .= "/";
  $a=new msgBox("<center>".$words["rebootSuccess"]."</br><font color='#ff0000'><span id='reboot'>60</span>&nbsp;<span id='seconds'>".$words["seconds"]."</span></font></center>",null,$words["rebootTitle"]);
  $a->makeLinks(array($url));
  echo "<html><head></head><body>";
  $a->showMsg();
  echo "<script language='javascript'>";
  echo "function go(){";
  echo "location.href='$url'";
  echo "}";
  echo "function reboot(){";
  echo "var msg=document.getElementById('reboot');";
  echo "msg.innerHTML=String(parseInt(msg.innerHTML)-1);";
  echo "if(msg.innerHTML!='0'){";
  echo "setTimeout('reboot()',1000);";
  echo "}else{";
  echo "var seconds=document.getElementById('seconds');";
  echo "seconds.innerHTML = '';";
  echo "if('1'=='$lan1'){";
  echo "msg.innerHTML='".$words['rebootComplete']."';";
  echo "}else{";
  echo "msg.innerHTML='<a href=$url>".$words['rebootComplete']."</a>';";
  echo "}";
  echo "}";
  echo "}";
  echo "reboot();";
  echo "</script>";
  echo "</body></html>";
}
?>
