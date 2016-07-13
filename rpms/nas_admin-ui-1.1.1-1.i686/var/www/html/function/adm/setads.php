<?
/*
session_start();
require_once("/var/www/html/inc/security_check.php");
check_admin($_SESSION);

//#######################################################
//#     Check security
//#######################################################
$is_function=function_exists("check_system");
if($is_function){
	check_raid();
	$samba_enabled=check_samba();
	check_system($samba_enabled,"samba_warning","httpd");
}else{
	require_once("/var/www/html/inc/function.php");
	check_system("0","access_warning","about");
}
//#######################################################
*/
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$db_tool=new sqlitedb();
//####################################
//#count local user and add 200 user
//####################################
$local=trim(shell_exec("/bin/cat /etc/passwd | wc -l"));
$total_count=$local+200;
//$wins_limit="2";

global $ads_enable,$topic;
$topic="";
require_once(INCLUDE_ROOT.'smbconf.class.php');

$gwords = $session->PageCode("global");
$words = $session->PageCode("ads");

$security = "user";

$debug_testjoin="/tmp/step1_ad_testjoin.txt";
$debug_net_ads_leave="/tmp/step2_ad_net_ads_leave.txt";
$debug_nslookup="/tmp/step3_ad_nslookup.txt";
$debug_net_join="/tmp/step4_ad_net_join.txt";
$debug_net_ads_info="/tmp/step5_ad_net_ads_info.txt";
$debug_net_join_d="/tmp/step6_ad_net_join_d.txt";
$debug_hostname="/tmp/step7_ad_hostname.txt";
$debug_getent="/tmp/step8_ad_getent.txt";

//##########################################
//#  setting wins server,replace CLRF char
//##########################################
//$_POST['_wins']=urldecode($_POST['_wins']);
//$_POST['_wins']=str_replace(chr(10)," ",$_POST['_wins']);
/*
	Not used
	$wins = str_replace("\r\n","\t",$_POST['_wins']);
	$wins = str_replace("\n","\t",$wins);
	$wins = str_replace("\r","\t",$wins);
	$wins = str_replace("\t"," ",$wins);
	$_POST['_wins'] = str_replace("\t","\n",$wins);
*/
//$wins_array=explode(" ",trim($_POST['_wins']));
//$wins_count=count($wins_array);

if($_POST["_domain"]=="" || !$validate->check_domainname($_POST["_domain"]) || !$validate->singlebyte($_POST["_domain"]))
	return  MessageBox(true,$words['ads_title'],$words["domain_error"],'ERROR');
if($_POST['_enable']=='1'){
	if($_POST["_ip"]=="" || !$validate->is_simple_url($_POST["_ip"]) || !$validate->singlebyte($_POST["_ip"]))
		return  MessageBox(true,$words['ads_title'],$words["server_name_error"],'ERROR');
	if($_POST["_realm"]=="" || !$validate->check_realm($_POST["_realm"]) || !$validate->singlebyte($_POST["_realm"]))
		return  MessageBox(true,$words['ads_title'],$words["realm_error"],'ERROR');
	if($_POST["_admid"]=="" || !$validate->check_username($_POST["_admid"]) || !$validate->singlebyte($_POST["_admid"]))
		return  MessageBox(true,$words['ads_title'],$words["admin_error"],'ERROR');
	//if($_POST["_admpwd"]=="" || !$validate->singlebyte($_POST["_admpwd"]) || $_POST["_admpwd"]!=$_POST["_admpwd_confirm"])
	if($_POST["_admpwd"]=="" || !$validate->singlebyte($_POST["_admpwd"]))
		return  MessageBox(true,$words['ads_title'],$words["pwd_error"],'ERROR');
	/*
	foreach($wins_array as $s){
		if(!$validate->is_simple_url($s) && $s!="")
			return  MessageBox(true,$words['ads_title'],$words["wins_error"],'ERROR');
	}
	if($wins_count>$wins_limit)
		return  MessageBox(true,$words['ads_title'],$words["wins_limit"],'ERROR');
	*/
	$security = $_POST['_AuthType']=='nt' ? "domain" : "ads";
}
$auth_methods = "guest sam_ignoredomain".($_POST['_enable']=='1' ? " winbind" : "");
$domain = $_POST['_domain'];
$result = 0;
$authType=$_POST['_AuthType'];

$basepath = '/usr/bin/';

//##########################################
//#  leave local machine from realm (ad)
//##########################################
$command = $basepath."net ads testjoin";
system($command. ' > /dev/null 2>&1', $msg);
cmdlog($command);
if ($msg == 0) {
	$command = $basepath."net ads leave > $debug_net_ads_leave 2>&1";
	shell_exec($command);
	cmdlog($command);
}

$SmbConf=new SmbConf();
$SmbConf->setShare("global");

//$SmbConf->setValue("wins server",$wins);
//$db_tool->setvar("winad_wins",$wins);

//##########################################
//#	setting workgroup
//##########################################
//$db = sqlite_open("/etc/cfg/conf.db");
//$rs = sqlite_query($db,"select v from conf where k='winad_enable'");
//$query="select v from conf where k='winad_enable'";
$ads_enable=$db_tool->getvar("winad_enable",$_POST["_enable"]);
$_enable=trim($_POST["_enable"]);
	//$topic.="aaa".$ads_enable."<br>";
//$ads_enable = sqlite_fetch_single($rs);
if($ads_enable!="0" && $SmbConf->getSetting("workgroup")!=$domain && $security!="user"){
	$result = 1;
	$icon="ERROR";
	//$topic .= $words["error"]." : ".$words["changeDomainError"]."</br>";
	$topic .= $words["changeDomainError"]."</br>";
}else{
	$SmbConf->setValue("workgroup",$domain);
}

if($security != 'user'){
	$server_name = $_POST['_ip'];
	$realm = $_POST['_realm']; 
	$admin_id = $_POST['_admid'];
	$admin_pwd = $_POST['_admpwd'];

	//############################################
	//#  Escape special character to Linux Shell
	//############################################
	$admin_pwd = str_replace("\\\\","\t",$admin_pwd);
	$admin_pwd = str_replace("\\","",$admin_pwd);
	$admin_pwd = str_replace("\t","\\",$admin_pwd);
	$admin_pwd = preg_replace("/\"/","\\\\$0",$admin_pwd);
	$admin_pwd = stripslashes($admin_pwd);
	$passwd_len=strlen($admin_pwd);
	$pwd="";
	for($i=0;$i<$passwd_len;$i++){
		$char=substr($admin_pwd,$i,1);
		if($char==chr(39)){
			$pwd.="'\"'\"'";
		}else{
			$pwd.=$char;
		}
	}
	$admin_pwd=$pwd;
	$_POST["_admpwd"]=$admin_pwd;
	$_POST["_admpwd_confirm"]=$admin_pwd;

	//############################################
	//#	Modify smb.conf
	//############################################
	$SmbConf->setValue("security",$security);
	$SmbConf->setValue("auth methods",$auth_methods);
	$SmbConf->setValue("password server",'*');
	$SmbConf->setValue("realm",strtoupper($realm));
	$SmbConf->setValue("idmap backend","rid:$domain=20000-60000000");
	if($security == "ads"){
		$SmbConf->setValue("client ntlmv2 auth","yes");
	}else{
		$SmbConf->setValue("client ntlmv2 auth","no");
	}
  	
	$SmbConf->commit();
  	
	//############################################
	//#Modify krb5.conf
	//############################################
	$krb = "[libdefaults]\n";
	$krb .= "default_realm = ".strtoupper($realm)."\n";
	$krb .= "kdc_timesync = 1\n";
	$krb .= "dns_lookup_realm = false\n";
	$krb .= "dns_lookup_kdc = true\n";
	$krb .= "[realms]\n";
	$krb .= strtoupper($realm)." = {\n";
	$krb .= "admin_server = ".strtoupper($server_name).".".strtoupper($realm)."\n";
	$krb .= "kdc = ".strtoupper($server_name).".".strtoupper($realm)."\n";
	$krb .= "default_domain = ".strtoupper($realm)."\n";
	$krb .= "}\n";
	$krb .= "[domain_realm]\n";
	$domain_name = explode("/\./",$realm);
	$krb .= ".".strtoupper($domain_name[count($domain_name)-1])." = ".strtoupper($realm)."\n";
	
	$krb_file = fopen("/etc/krb5.conf","wb");
	fwrite($krb_file,$krb);
	fclose($krb_file);
			
	if (NAS_DB_KEY == '2')
		$db_tool->setvar("winad_enable","1");
	$SmbConf->restart("1");
		
	//#############################################
	//#	Check /etc/resolv.conf
	//#############################################
	$strExec="/bin/cat /etc/resolv.conf | grep \"nameserver\"";
	$nameserver=shell_exec($strExec);
	if($nameserver==""){
		$icon="ERROR";
		//$topic .= $words["error"]." : ".$words["dns_error"]."</br>";
		$topic .= $words["dns_error"]."</br>";
		$result="1";
	}
  
	//#############################################
	//#	Check Server Name and Realm
	//#############################################
	$strExec="/usr/bin/nslookup ".$server_name.".".$realm." > $debug_nslookup 2>&1";
	cmdlog($strExec);
	system($strExec,$msg);
	if($msg!='0'){
		$icon="ERROR";
		//$topic .= $words["error"]." : ".$words["serverOrDNSOrRealmError"]."</br>";
		$topic .= $words["serverOrDNSOrRealmError"]."</br>";
		$result = 1;
	}
  	
	if($security=='ads'){
		//#############################################
		//#		Clock skew too great
		//#############################################
		$strExec=$basepath."net ads info -S ".$server_name.".".$realm." | grep 'time offset'|cut -d ':' -f2 2>&1";
		cmdlog($strExec);
		$msg = trim(shell_exec($strExec));
		if(abs($msg) >= 300){
			$icon="ERROR";
			//$topic .= $words["error"]." : ".$words["ClockError"]."....$msg ".$words["seconds"]."</br>";
			$topic .= $words["ClockError"]."....$msg ".$words["seconds"]."</br>";
			$result = 1;
		}
		file_put_contents($debug_net_ads_info,$msg);
	}
  
	if($result != 1 && $security!='user'){
		//#############################################
		//#join message paser	
		//#############################################
		if ($authType=="nt") {
			$strExec=$basepath."net join -d 10 -S ".$server_name." -U '".$admin_id."%".$admin_pwd."' 2>&1";
		} else {
			$strExec=$basepath."net join -d 10 -S ".$server_name.".".$realm." -U '".$admin_id."%".$admin_pwd."' 2>&1";
		}
		cmdlog($strExec);
		$msg = shell_exec($strExec);
		file_put_contents($debug_net_join_d,$msg);
    
		//#############################################
		//#administrator username and password incorrect 
		//#############################################
		if(preg_match("/(The username or password was not correct|Could not connect to server|Preauthentication failed|Unable to find a suitable server|Client not found)/",$msg)){
			$icon="ERROR";
			//$topic .= $words["error"]." : ".$words["AdminOrPwdError"]."</br>";
			$topic .= $words["AdminOrPwdError"]."</br>";
			$result = 1;
		}
			
		//#############################################
		//unauthorize
		//#############################################
		if(preg_match("/(Insufficient access|error setting trust account password: NT_STATUS_ACCESS_DENIED)/",$msg)){
			$icon="ERROR";
			//$topic .= $words["error"]." : ".$words["AdminInsufficientError"]."</br>";
			$topic .= $words["AdminInsufficientError"]."</br>";
			$result = 1;
		}
			
		//#############################################
		//Domain/Workgroup Name Error
		//#############################################
		if(preg_match("/The workgroup in smb.conf does not match the short/",$msg)){
			$message = preg_match("/You should set \"workgroup = ([^\"]+)\" in smb.conf/",$msg,$matches);
			$icon="ERROR";
			//$topic .= $words["error"]." : ".$words["DomainError"]."</br>";
			$topic .= $words["DomainError"]."</br>";
			$result = 1;
		}
		
		if(trim(file_get_contents("/var/tmp/ha_role"))){
			$hostname=$db_tool->getvar("ha_virtual_name","");
		}else{
			$hostname = shell_exec("/bin/hostname");
		}
		$hostname = str_replace("\n","",$hostname);
			
		file_put_contents($debug_hostname,$hostname);
		$msg_tmp=strtoupper($msg);
		if($result!=1 && (preg_match("/Joined '".strtoupper($hostname)."' to realm '".strtoupper($realm)."'/",$msg)||preg_match("/Joined domain/",$msg)||preg_match("/Joined '".strtoupper($hostname)."' to realm '".$realm."'/",$msg))){
			$topic .=$words["joinSuccess"]."</br>";
			$SmbConf->restart("1");
		}elseif($result!=1 && (preg_match("/JOINED '".strtoupper($hostname)."' TO REALM '".strtoupper($realm)."'/",$msg_tmp)||preg_match("/JOINED DOMAIN/",$msg_tmp))){
			$topic .=$words["joinSuccess"]."</br>";
			$SmbConf->restart("1");
		}else{
			$icon="ERROR";
			$topic .= $words["noJoin"]."</br>";
			//$topic .= $msg."</br>";
			$result=1;
		}
	}else{
		$icon="ERROR";
		//$topic .= $words["error"]." : ".$words["noJoin"]."</br>";
		$topic .= $words["noJoin"]."</br>";
		$result = 1;
	}
}

$db_tool->setvar("winad_domain",$domain);
if($result==1 || $security == 'user'){
	$SmbConf->setValue("security","user");
	$SmbConf->setValue("auth methods","guest sam_ignoredomain");
	if($security=="ads"){
		$SmbConf->setValue("client ntlmv2 auth","yes");
	}else{
		$SmbConf->setValue("client ntlmv2 auth","no");
	}
	$SmbConf->commit();
	$db_tool->setvar("winad_enable","0");
	//sqlite_query($db,"update conf set v='0' where k='winad_enable'");
	$SmbConf->restart("1");
}else{
	$db_tool->setvar("winad_enable",$_enable);
	$db_tool->setvar("winad_admid",$admin_id);
	$db_tool->setvar("winad_admpwd",$admin_pwd);
	//$db_tool->setvar("winad_admpwd_confirm",$admin_pwd);
	$db_tool->setvar("winad_ip",$server_name);
	$db_tool->setvar("winad_realm",$realm);
	$db_tool->setvar("winad_AuthType",$authType);
	if(trim(file_get_contents("/var/tmp/ha_role"))){
		shell_exec("/img/bin/rc/rc.samba stop >/dev/null 2>&1 ;/img/bin/rc/rc.samba boot >/dev/null 2>&1");
	}
}

if ($security == 'user') {
	$topic .= $words['joinDisable'];//"ADS/NT Support disabled";
}
	
//$rs = sqlite_query($db,"select v from conf where k='winad_enable'");
//$ads_enable = sqlite_fetch_single($rs);
$ads_enable=$db_tool->getvar("winad_enable","0");
shell_exec("/img/bin/rc/rc.atalk restart > /dev/null 2>&1 &");

unset($db_tool);

require_once(INCLUDE_ROOT.'conf.class.php');
//require_once("../../inc/conf.class.php");
$conf=new Configure();
global $prefix;
$prefix=$_POST['prefix'];
    
return  MessageBox(true,$words['ads_title'],$topic,$icon);
//exit;
//return $result;
 
function cmdlog($msg) {
	$strLog="/img/bin/logevent/information 999 \"[ADS Test] Run Command : %s\"";
	$strExec=sprintf($strLog,$msg);
	//echo "strExec=$strExec <br>";
	//shell_exec($strExec);
}

function msglog($msg) {
	$strLog="/img/bin/logevent/information 999 \"[ADS Test] Message : %s\"";
	$strExec=sprintf($strLog,$msg);
	shell_exec($strExec);
}
?>
