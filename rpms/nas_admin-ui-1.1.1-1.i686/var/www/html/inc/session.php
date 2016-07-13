<?php 
require_once("smbwebclient.class.php");
require_once("sqlitedb.class.php");
require_once("db.class.php");
include_once("form.php");

define("USERCHECK_LOGIN", -2);
define("USERCHECK_PASSWORD", -1);
class Session extends smbwebclient{
	var $time;			//Time user was last active (page loaded)
	var $logged_in;			//True if user is logged in, false otherwise
	var $url;			//The page url current being viewed
	var $lang;			//user's language  
	var $loginid;	
  var $admin_pwd;		
  var $admin_auth;					 

	/* Class constructor */
	function Session() {
		$this->time = time();
		$this->startSession(); 
	}

	/**
	 * startSession - Performs all the actions necessary to
	 * initialize this session object. Tries to determine if the
	 * the user has logged in already, and sets the variables
	 * accordingly. Also takes advantage of this page load to
	 * update the active visitors tables.
	 */
	function startSession() {
		session_start();   //Tell PHP to start the session
		$this->logged_in = $this->checkLogin();		// Determine if user is logged in
		$this->admin_auth=false;
		//printf("1 logged_in=%s admin_auth=%s<br>",$this->logged_in,$this->admin_auth);
		if ($this->logged_in) {
			if ($_SESSION['loginid']=="admin") {
				$this->admin_auth=true;
			}
		}
		//printf("2 logged_in=%s admin_auth=%s<br>",$this->logged_in,$this->admin_auth);
  
		/* Set current url */
		$this->url = $_SESSION['url'] = $_SERVER['PHP_SELF'];
		 /*	Get language	*/
		$this->lang = $this->getLanguage(); 
	}


	function unsetLogin() {
		unset($_SESSION['loginid']);
		//unset($_SESSION['lang']); 
		unset($_SESSION['admin_auth']);
		unset($_SESSION['username']);
		unset($_SESSION['pwd']);
		unset($_SESSION['url']);
		unset($_SESSION['admin_pwd']);
	}
	function getLogin() {
		$this->loginid= $_SESSION['loginid'];  
		//$this->lang	= $_SESSION['lang'];
	}
	function setLogin() {
		$_SESSION['loginid']= $this->loginid;
		$_SESSION['lang']= $this->lang;  
	}
	 
	/**
	 * getLanguage - When the users exchange language, setting  session.
	 * Default value will cache the user's browser language.
	 */
    function getLanguage(){
        if (isset($_REQUEST["lang"]) && !empty($_REQUEST["lang"])) {
            $lang=$_REQUEST["lang"];
            $db=new sqlitedb("/var/www/html/language/language.db");
	    $sql="SELECT name FROM sqlite_master WHERE name='$lang'";
	    $tbname=$db->runSQL($sql);
	    $tbname=$tbname[0];
            unset($db);
	    if($tbname!='' && $this->admin_auth){
               $_SESSION['lang']=$_REQUEST['lang'];
               $db=new sqlitedb();
               shell_exec("echo ".$_SESSION['lang']." > /tmp/lang");
               $db->setvar('admin_lang',$_SESSION['lang']);
               unset($db);
            }
        }
        if ((!isset($_SESSION['lang'])) || ($_SESSION['lang']=='')) {
            $db=new sqlitedb();
            shell_exec("echo ".$_SESSION['lang']." > /tmp/lang");
            $_SESSION['lang'] = $db->getvar('admin_lang','en');
            unset($db);
        }
        return $_SESSION["lang"];
    }
	
	/**
	 * checkLogin - Checks if the user has already previously
	 * logged in, and a session with the user has already been
	 * established. Also checks to see if user has been remembered.
	 * Returns true if the user has logged in.
	 */
	function checkLogin() {
		if (isset($_SESSION['loginid']) && !empty($_SESSION["loginid"])) { 
			$this->getLogin();			
			return true;
		} else {
		/* User not logged in */
			$this->unsetLogin();
			return false;
		}
	}

 
	function login() {
		     if($_REQUEST['login_type']=='photo'){
		        if(!file_exists("/raid/data/_NAS_Picture_/")){  
		             $gwords= $this->PageCode('global');
		             $ary = array('title'=>$gwords['error'],'msg'=>$gwords['dir_exist']);
                                die(json_encode(array('success'=>false,'errormsg'=>$ary)));		            
		        }
		     }
 		$swc = new smbwebclient(); 
	  $swc->Run(); 
		return TRUE;
	}
	
	function singleLogin($user,$pass) {
		// $_POST['pwd'] from flash is empty, so need to assign value to it.
		// But $_POST['pwd'] has been encoded with backslash if it is from html, need to handle the special character backslash(\) for flash password
		$pass_len = strlen($pass);
		for($i = 0; $i < $pass_len; $i++){
			$char=substr($pass,$i,1);
			if(ord($char)==92){
				$char=chr(92).$char;
			}
			$tmp_pwd.=$char;
		}
		
		$_POST['username']=$user;
		$_POST['pwd']=$tmp_pwd;
		$_SESSION['username'] = $user;
		$_SESSION['pwd'] = $pass;
		$nodie=1;
 		$swc = new smbwebclient($nodie); 
		return $swc->Run();
	}

	/**
	 * validateLoginUserInputField - Gets called to check user submitted info.
	 * returns.
	 */
	function validateLoginUserInputField($fieldId, $fieldName, $fieldValue) {
		global $form;
		/* Check if username is not alphanumeric */
		if (!eregi("^([0-9a-z])*$", $fieldValue)) {
				$form->setError($fieldName, "* Username not alphanumeric");
		}
		return true;
	}
	
	
	 

	/**
	 * logout - Gets called when the user wants to be logged out of the
	 * website. It deletes any cookies that were stored on the users
	 * computer as a result of him wanting to be remembered, and also
	 * unsets session variables and demotes his user level to guest.
	 */
	function logout() {
		/**
		 * Delete cookies - the time must be in the past,
		 * so just negate what you added when creating the
		 * cookie.
		 */
		/* === modified use of these cookies to become family login flag === */
		/*
		if (isset($_COOKIE['cookname']) && isset($_COOKIE['cookmid'])) {
			setcookie("cookname", "", time()-COOKIE_EXPIRE, COOKIE_PATH);
			setcookie("cookmid",  "", time()-COOKIE_EXPIRE, COOKIE_PATH);
		}
		*/
		/* Unset PHP session variables */
		$this->unsetLogin();
		
		shell_exec("rm -rf /tmp/admin");
		

		/* Reflect fact that user has logged out */
		$this->logged_in = false;  
		session_destroy();
	}
	
	 
  function PageCode($board){
		if(!$this->lang){
			$db=new sqlitedb();
		        $this->lang = $db->getvar('admin_lang','en');
			unset($db);
		}
		$lang=$this->lang;
		$ROOT="/var/www/html/language/";
		$lang_db="${ROOT}language.db";
		$RAID_ROOT="/raid/sys/language/";
		$raid_lang_db="${RAID_ROOT}language.db";
		
		$ldb=new sqlitedb($lang_db,$lang);
		//$lrs="select value,msg from ${lang} where function='${board}'";
		//$lang_array=$ldb->runSQLAry($lrs);
		$lrs="SELECT name FROM sqlite_master WHERE type='table'";
		$lang_array=$ldb->runSQLAry($lrs);
		unset($ldb);
		$default_lang = array();
		foreach($lang_array as $lang){
			if($lang!=""){
				$default_lang[]=$lang["name"];
			}
		}
		//$default_lang = array("en","tw","zh","ja","fr","de","it","ko","es","ru");
		$lang=$this->lang;
		
		$words=$this->GetWording($lang_db,$lang,$board);
		//$SLang="{$ROOT}en/{$board}";
		//require($SLang);
		if(in_array($lang,$default_lang)){
			//$DLang="{$ROOT}{$lang}/{$board}";
			$lang=$lang;
		}else{
			//English	en	n4100	1.0.16.3
			$version=trim(shell_exec('cut -d "-" /etc/version -f1'));
			$product=trim(shell_exec("grep '^type' /etc/manifest.txt|awk '{print \$2}'"));
			$lang_info=trim(shell_exec('grep "	'.$lang.'	" /raid/sys/language/lang.list'));
			$lang_info=explode("\t",$lang_info);
			if($lang_info[2] == $product && $lang_info[3] == $version){
				//$DLang="{$RAID_ROOT}{$lang}/{$board}";
				$lang_db=$raid_lang_db;
			}else{
				//$DLang = $this->LangMapError($lang,$board,$ROOT,1);
		                $lang=$this->LangMapError($lang,$board,$ROOT,1);
			}
		}
		//if(!file_exists($DLang) || (!preg_match("/Healthy/i",shell_exec("cat /var/tmp/rss")) && 
		if(!file_exists($lang_db) || (!preg_match("/Healthy/i",shell_exec("cat /var/tmp/rss")) && 
									!in_array($lang,$default_lang))){
			$this->LangMapError($lang,$board,$ROOT,0);
			return $words;
		}else{
			$words_tmp = $words;
			//require($DLang);
			$words=$this->GetWording($lang_db,$lang,$board);
			$words = array_merge($words_tmp,$words);
			return $words;
		}
	}

	function GetWording($db,$lang,$board){
		$words=array();
		$ldb=new sqlitedb($db,$lang);
		$word_array=$ldb->runSQLAry("select value,msg from ${lang} where function='${board}'");
		unset($ldb);
//		echo $db.$lang.$board;print_r($item);die();
		foreach($word_array as $item){
		/*
		        if($board!='index')
  			    $words[trim($item["value"])]=$item["msg"];
  			else
			    $words[trim($item["value"])]=addslashes($item["msg"]);
  			*/
  			    $words[trim($item["value"])]=$item["msg"];
		}
//		echo "2";print_r($words);die();
		return $words;
	}

	function LangMapError($lang,$board,$ROOT,$kill_lang){
		$db=new sqlitedb();
		$db->setvar('admin_lang','en');
		unset($db);
		$this->lang = 'en'; 

		if($kill_lang){
			shell_exec('grep -v "\\:'.$lang.'\\:" /raid/sys/language/lang.list > /tmp/lang');
			shell_exec('mv /tmp/lang /raid/sys/language/lang.list');
			//return "{$ROOT}en/{$board}";
			return $this->lang;
		}
	}
 
	//Get user uid
	function getUID($username) {
		$uid="";
		//Check local user first
		$strExec=sprintf("awk -F: '{if ($1==\"%s\") print $3}' /etc/passwd",$username); 
		
		//printf("strExec=[%s]\n",$strExec);
		$uid=shell_exec($strExec);
		//printf("username=%s uid=%s \n",$username,$uid);
		if (($uid!="0")&&($uid!="")) {
			return $uid;
		}
		
		$db = new sqlitedb();
		$ad_enabled = $db->getvar('winad_enable','0');
		$ldap_enabled = $db->getvar('ldap_enabled','0');
		if($ad_enabled=='1' || $ldap_enabled=='1'){
		    if(file_exists("/raid/sys/ad_account.db")){
			$strSQL=sprintf("select id from acl where role='ad_user' and user='%s'",$username);
			$ldb=new sqlitedb("/raid/sys/ad_account.db","acl");
			$table_exist=$ldb->table_exists("acl");
			if($table_exist){
				$word_array=$ldb->runSQL($strSQL);
				$uid=$word_array['id'];
				unset($ldb);
			}
		    }else{
			if ($ad_enabled=='1'){
				$strExec="/usr/bin/wbinfo -u|awk -F':' '/$username/{print $2}'";
				$uid = trim(shell_exec($strExec));
			}

			if ($ldap_enabled=='1'){
				$strExec="/usr/bin/getent passwd | awk -F':' '/$username:/{print $3}'";
				$uid = trim(shell_exec($strExec));
			}

		    }
		}
		return $uid;
	}
 
	//Get user uid
	function chkLocalUser($uid) {
		$localUser=0;
		if ($uid!="")
			if ($uid < 20000) $localUser=1;
		return $localUser;
	}


	//Change user password
	function chgLocalPasswd($username,$userpwd) {
		$this->smbUserModify($username,"modify",$userpwd);
  	
        if (NAS_DB_KEY == 1)
            $chgpasswd=sprintf("/usr/bin/makepasswd -e shmd5 -p \"%s\"|awk '{print \"%s:\"$2}'|/usr/bin/chpasswd -e",$userpwd,$username);
        else
            $chgpasswd=sprintf("/usr/bin/passwd %s %s",$username,$userpwd);
  	
        shell_exec($chgpasswd);
        shell_exec("/img/bin/logevent/event 997 108 info \"\" \"$username\" &");
        return 1;
	}
	
	function smbUserModify($username,$action,$pwd=""){
		//$cmd = "/usr/bin/smbpasswd";
		$cmd = "echo -e \"$pwd\\n$pwd\" | /usr/bin/smbpasswd";
		if($action == "delete"){
		        $cmd .= " -x $username";
		}
		elseif($action == "new"){
		        //$cmd .= " -s -a $username <<END\n$pwd\n$pwd\nEND";
		        $cmd .= " -s -a $username";
		}
		elseif($action == "modify"){
		        //$cmd .= " -s $username <<END\n$pwd\n$pwd\nEND";
		        $cmd .= " -s $username";
		}
		else{
		        return false;
		}
		shell_exec($cmd);
	}
 
}
/**
 * Initialize session object - This must be initialized before
 * the form object because the form uses session variables,
 * which cannot be accessed unless the session has started.
 */ 
$session = new Session;  
?>
