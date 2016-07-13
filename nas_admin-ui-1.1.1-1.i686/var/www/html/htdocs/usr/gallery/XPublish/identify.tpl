<?	session_start();
	function eecho($str){
		//shell_exec('echo "'.$str.'" >> /tmp/pu.log');
	}
                
	//variables define
  require_once('../../../../function/conf/localconfig.php');
	require_once(INCLUDE_ROOT.'session.php');
  require_once(WEBCONFIG);
  require_once(INCLUDE_ROOT.'sqlitedb.class.php');
	$db=new sqlitedb();
	$_SESSION['lang'] = $db->getvar("admin_lang","en");;
	$db->db_close();
	unset($db);

	$getent = "/usr/bin/getent";
	$smbclient = "/usr/bin/smbclient";

	if(isset($_POST['username'])){
		$username = $_POST['username'];
		$pwd = $_POST['pwd'];
	}
	else{
		$username = $_SESSION['username'];
		$pwd = $_SESSION['pwd'];
	}
	$username = rmPostslash($username);
	$pwd = rmPostslash($pwd);

	$user_info = posix_getpwnam($username);
	$_SESSION['uid'] = $user_info['uid'];

	//if user is admin ,redirect to admin page
	if($username=="admin"){
		$ret=trim(shell_exec('/opt/bin/auth root "'.$pwd.'"'));
		if($ret == 'AUTH: OK'){
                
			setAuthsession('username','pwd');
			$_SESSION['admin_auth'] = 1;
			header("Location: /usr/gallery/XPublish/?cmd=publish");
			exit;
		}
		else{
			header("Location: /usr/gallery/XPublish/?cmd=publish");
			exit;
		}
	}
	
	//filter special account
	$user_exist = trim(shell_exec("$getent passwd|grep '^{$username}:'|wc -l"));
	if($pwd == "" || $username == "root" || $username == "sshd" || $username == "nobody" || $username == "ftp" ||
	   !$user_exist){
		header("Location: /usr/gallery/XPublish/?cmd=publish");
		exit;
	}

	if(!isset($_SESSION['username'])){
		if(!doAuthentication($username,$pwd)){
			header("Location: /usr/gallery/XPublish/?cmd=publish");
			exit;
		}
	}

	//Authentication
	function doAuthentication($username,$pwd){
		global $smbclient;
		$authent = !trim(shell_exec("$smbclient -L 127.0.0.1 -U \"{$username}%".str_replace("\"","\\\"",$pwd).
				   "\" > /dev/null 2>&1;echo $?"));
		if($authent){
			setAuthsession('username','pwd');
		}
		
		return $authent;
	}
	//set variables to $_SESSION
	function setAuthsession(){
		$arg_list = func_get_args();
		foreach ($arg_list as $varname){
			global $$varname;
			$_SESSION[$varname] = $$varname;			
						
			if($varname=='username')
			  $_SESSION['loginid']= $$varname;
		}
	}
	//remove POST method auto append slash
	function rmPostslash($query){
		$query = str_replace("\\\\","\t",$query);
		$query = str_replace("\\","",$query);
		$query = str_replace("\t","\\",$query);
		return $query;
	}
	$url = "/usr/gallery/XPublish/?cmd=publish";
	header("Location: {$url}");
?>
