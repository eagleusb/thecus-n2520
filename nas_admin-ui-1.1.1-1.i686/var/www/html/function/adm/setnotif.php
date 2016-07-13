<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("notif");
$gwords = $session->PageCode("global");
$db=new sqlitedb();
$ch= new validate;

$update=0;

//==========notif config==========
//post data
$action=$_POST["action"]; // for init wizard
$notif_post_key=array( '_beep', '_led', '_mail', '_smtp', '_smtport', '_auth_selected', '_account', '_password', '_level_selected', '_from', '_domain', '_ssl_selected', '_addr1', '_addr2', '_addr3', '_addr4');
$notif_post_array=array();
foreach ($notif_post_key as $k)
	$notif_post_array[]=stripslashes($_POST[$k]);

//db data
$notif_db_key=array("notif_beep"=>"0",
			"notif_led"=>"1",
			"notif_mail"=>"0",
			"notif_smtp"=>"",
			"notif_smtport"=>"",
			"notif_auth"=>"off",
			"notif_account"=>"",
			"notif_password"=>"",
			"notif_level"=>"all",
			"notif_from"=>"",
			"notif_domain"=>"",
			"notif_ssl"=>"off",
			"notif_addr1"=>"",
			"notif_addr2"=>"",
			"notif_addr3"=>"",
			"notif_addr4"=>"");
$notif_db_array=array();
foreach ($notif_db_key as $k=>$v)
	$notif_db_array[]=$db->getvar($k,$v);

if (serialize($notif_post_array)!=serialize($notif_db_array) ){
    $idx=0;
    $db->setvar("notif_beep",$_POST[_beep]);
    //$db->setvar("notif_led",0);
    $db->setvar("notif_led",$_POST['_led']);
	
    if($_POST[_mail]){
        //==========  data check -- begin  ==========
        if (($ch->check_empty($_POST[_addr1])) && ($ch->check_empty($_POST[_addr2])) && ($ch->check_empty($_POST[_addr3])) && ($ch->check_empty($_POST[_addr4])))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words['notif_title'],$words["email_prompt"]);
        }

        if ($_POST[_auth_selected] != 'off')
        {
            if (!$ch->singlebyte($_POST[_password]))
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["notif_title"],$words["pwd_error"]);
            }

            if ($ch->check_empty($_POST[_account]))
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["notif_title"],$words["user_error"]);
            }
        }

        $from=$_POST[_from];
        $domain=$_POST[_domain];
        $ssl=$_POST[_ssl_selected];
        $addr1=$_POST[_addr1];
        $addr2=$_POST[_addr2];
        $addr3=$_POST[_addr3];
        $addr4=$_POST[_addr4];
        
        if ((!$ch->check_email($from) && !$ch->check_empty($from)) || (!$ch->check_email($addr1) && !$ch->check_empty($addr1)) || (!$ch->check_email($addr2) && !$ch->check_empty($addr2)) || (!$ch->check_email($addr3) && !$ch->check_empty($addr3))  || (!$ch->check_email($addr4) && !$ch->check_empty($addr4)))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["notif_title"], $words["email_error"]);
        }
    
        if (!$ch->check_port($_POST[_smtport]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["notif_title"], $words["smtp_port_error"]);
        }

        $_smtp = trim($_POST[_smtp]);
        for ($j=0;$j<strlen($_smtp);$j++)
        {
            if (ord(substr($_smtp, $j)) == 32)
            {
                unset($ch);
                unset($db);
                return MessageBox(true,$words["notif_title"], $words["smtp_server_error"]);
            }
        }

        if (!$ch->is_simple_url($_POST[_smtp]) || $ch->check_empty($_POST[_smtp]))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["notif_title"], $words["smtp_server_error"]);
        }  
        
        if (!$ch->check_domainname($domain))
        {
            unset($ch);
            unset($db);
            return MessageBox(true,$words["notif_title"], $words["domain_error"]);
        }
        //==========  data check -- end  ==========
          
        foreach ($notif_db_key as $k=>$v){
	  	    $db->setvar($k,$notif_post_array[$idx]);
	  	    $idx++;
	    }
  }else{
	  	$db->setvar("notif_mail",$_POST[_mail]);
  }
	  
  //$NIC=new SetNIC($_POST['prefix'],$_POST);
  $update=1;
}

$string="0 0 SLED 1\n";
$filename="/var/tmp/oled/pipecmd";
if ($update==1){
  if (NAS_DB_KEY == '1'){
     if($_POST[_beep]==0){
        $cmd="/img/bin/buzzer.sh 1";
        shell_exec($cmd);
        $cmd="/img/bin/buzzer.sh 0";
        shell_exec($cmd);
        $cmd="echo 0 > /tmp/beep_enable";
        shell_exec($cmd);
     }else{
        $cmd="/img/bin/buzzer.sh 1";
        shell_exec($cmd);
        $cmd="echo 1 > /tmp/beep_enable";
        shell_exec($cmd);
     }
	 if(($_POST[_led]==0)){
		file_put_contents($filename, $string);
	 }
  }elseif (NAS_DB_KEY == '2'){
    if($_POST[_beep]==0){
       shell_exec("echo \"Buzzer 0\" > /proc/thecus_io");
       $cmd="echo 0 > /tmp/beep_enable";
       shell_exec($cmd);
    }else{
        $cmd="echo 1 > /tmp/beep_enable";
        shell_exec($cmd);
     }
	 if(($_POST[_led]==0)){
		file_put_contents($filename, $string);
	 }
  }

	if ($action == "init") {
		return MessageBox(false,"","");
	} else {
		return MessageBox(true,$words['notif_title'],$words["successMsg"]);
	}
}

?>
