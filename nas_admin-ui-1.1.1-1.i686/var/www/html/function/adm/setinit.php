<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(WEBCONFIG);

$init_words = $session->PageCode("init");
$user_words = $session->PageCode("localuser");
$gwords = $session->PageCode("global");

$action = $_POST["action"];
$msg = "";
$db=new sqlitedb();
if ($action == "chkinit") {
	$initlock = shell_exec("cat /var/tmp/initwizard_lock");
	if ($initlock == "1" || $db->getvar("run_init") == "1") {
		$msg = $init_words["init_repeat"];
	} else {
		shell_exec("echo 1 > /var/tmp/initwizard_lock");
	}
} elseif ($action == "setdb") {
	$db->setvar("run_init","1");
	unlink("/var/tmp/initwizard_lock");
} else if ($action == "adduser") {
	$username = $_POST['username'];
	$pwd = $_POST['user_pwd'];
	//validate password
	if (isset($pwd) && $pwd != "") {
		$pwd = stripslashes($pwd);
		for($i = 0; $i < strlen($pwd); $i++){
			$char = substr($pwd,$i,1);
			if (ord($char) == "39"){
				$char = chr(92).$char;
			}
			$tmp_pwd .= $char;
		}
		$pwd = $tmp_pwd;
	}
	
	$fp = fopen(INIT_INFO, "w");
	fwrite($fp, "user_name='".$username."'\n");
	fwrite($fp, "user_pwd='".$pwd."'\n");
	fclose($fp);

	$db->setvar("run_init","1");
	unlink("/var/tmp/initwizard_lock");
}
unset($db);

return MessageBox(false,"",$msg);
?>
