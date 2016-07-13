<?
require_once(INCLUDE_ROOT.'validate.class.php');
$ch= new validate;

$words = $session->PageCode("notif");

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
        //==========  data check -- end  ==========

if (NAS_DB_KEY == '1'){
	$test_cmd="/img/bin/logevent/email EmailTest \"$_POST[_smtp]\" \"$_POST[_smtport]\" \"$_POST[_auth_selected]\" \"$_POST[_account]\" \"$_POST[_password]\" \"$_POST[_addr1] $_POST[_addr2] $_POST[_addr3] $_POST[_addr4]\" \"$_POST[_from]\"";
}

if (NAS_DB_KEY == '2'){
	$test_cmd="/img/bin/logevent/email EmailTest \"$_POST[_smtp]\" \"$_POST[_smtport]\" \"$_POST[_auth_selected]\" \"$_POST[_account]\" \"$_POST[_password]\" \"$_POST[_from]\" \"$_POST[_addr1] $_POST[_addr2] $_POST[_addr3] $_POST[_addr4]\"";
}
shell_exec($test_cmd);

$mail_test_res = '/tmp/mail_test_res';
if (file_exists($mail_test_res)){
    $result = file_get_contents($mail_test_res);
    unlink($mail_test_res);
}else{
    $result = 1;
}

if ($result != 0){
    return MessageBox(true,$words['notif_title'],$words["email_sent_fail"]);
}else{
    return MessageBox(true,$words['notif_title'],$words["email_sent"]);
}

?>
