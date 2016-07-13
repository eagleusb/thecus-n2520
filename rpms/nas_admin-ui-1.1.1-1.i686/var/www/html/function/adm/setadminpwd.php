<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("adminpwd");
$gwords = $session->PageCode("global");

$dataCheck= new validate;
$db=new sqlitedb();

if ($_REQUEST['prefix'] == 'adminpwd')
{
    $passwd1=$_REQUEST['_passwd1'];
    $passwd2=$_REQUEST['_passwd2'];

    // Check password
    if($passwd1=='' || $passwd2=='')
        return  MessageBox(true,$gwords['error'],$words['pwd_empty'],'ERROR');
    if($passwd1 != $passwd2)
        return  MessageBox(true,$gwords['error'],$words['pwd_diff'],'ERROR');

    $passwd1_db = stripslashes($passwd1);
    if (!$dataCheck->limitstrlen(4,16, $passwd1_db))
    {
        unset($dataCheck);
        unset($db);
        return MessageBox(true,$gwords['error'],$words['pwd_too_short'],'ERROR');
    }

    if (!$dataCheck->singlebyte($passwd1_db))
    {
        unset($dataCheck);
        unset($db);
        return  MessageBox(true,$gwords['error'],$words['pwd_worng_rule'],'ERROR');
    }

    //############################################
    //#  Escape special character to Linux Shell
    //############################################
    $passwd1 = str_replace("\\\\","\t",$passwd1);
    $passwd1 = str_replace("\\","",$passwd1);
    $passwd1 = str_replace("\t","\\",$passwd1);
    $passwd1 = preg_replace("/\"/","\\\\$0",$passwd1);
    $passwd1 = stripslashes($passwd1);
    $passwd_len=strlen($passwd1);
    $pwd="";

    for($i=0;$i<$passwd_len;$i++){
        $char=substr($passwd1,$i,1);
        if($char==chr(39)){
            $pwd.="'\"'\"'";
        }else{
            $pwd.=$char;
        }
    }

    $passwd1=$pwd;
	

    unset($dataCheck);
    unset($db);

    if (NAS_DB_KEY == 1){
        $chgpasswd=sprintf("/usr/bin/makepasswd -e shmd5 -p %s|awk '{print \"%s:\"$2}'|/usr/bin/chpasswd -e",escapeshellarg($passwd1_db),"admin");
        shell_exec($chgpasswd);
}
    else{
        $chgpasswd=sprintf("/usr/bin/passwd %s %s","admin",escapeshellarg($passwd1_db));
        shell_exec($chgpasswd);
        $chgpasswd=sprintf("/usr/bin/passwd %s %s","root",escapeshellarg($passwd1_db));
        shell_exec($chgpasswd);
    }
    
    shell_exec("/img/bin/logevent/event 108 admin &");

    //samba password
    smbUserModify("admin","modify",$passwd1);

    return  MessageBox(true,$words['adminpwd_title'],$words['chpwSuccess']); 
}
elseif ($_REQUEST['prefix'] == 'lcdpwd')
{
    $passwd1=$_REQUEST['_lcdpasswd1'];
    $passwd2=$_REQUEST['_lcdpasswd2'];

    // Check password
    if($passwd1=='' || $passwd2=='')
        return  MessageBox(true,$gwords['error'],$words['lcd_pwd_empty'],'ERROR');
    if($passwd1 != $passwd2)
        return  MessageBox(true,$gwords['error'],$words['lcd_pwd_diff'],'ERROR');

    if ((iconv_strlen($passwd1, 'utf-8')<4) || (iconv_strlen($passwd1, 'utf-8')>4))
    {
        unset($dataCheck);
        unset($db);
        return MessageBox(true,$gwords['error'],$words['lcd_pwd_too_short'],'ERROR');
    }
    
    if (!$dataCheck->numeric(4, "exactly", $passwd1))
    {
        unset($dataCheck);
        unset($db);
        return MessageBox(true,$gwords['error'],$words['lcd_pwd_worng_rule'],'ERROR');
    }
/*
    if (!$dataCheck->singlebyte($passwd1))
    {
        unset($dataCheck);
        unset($db);
        return  MessageBox(true,$gwords['error'],$words['lcd_pwd_worng_rule'],'ERROR');
    }
*/
    //############################################
    //#  Escape special character to Linux Shell
    //############################################
    $passwd1 = str_replace("\\\\","\t",$passwd1);
    $passwd1 = str_replace("\\","",$passwd1);
    $passwd1 = str_replace("\t","\\",$passwd1);
    $passwd1 = preg_replace("/\"/","\\\\$0",$passwd1);
    $passwd1 = stripslashes($passwd1);
    $passwd_len=strlen($passwd1);
    $pwd="";

    for($i=0;$i<$passwd_len;$i++){
        $char=substr($passwd1,$i,1);
        if($char==chr(39)){
            $pwd.="'\"'\"'";
        }else{
            $pwd.=$char;
        }
    }

    $passwd1=$pwd;
	
    $db->setvar("lcmcfg_pwd",$passwd1);

    unset($dataCheck);
    unset($db);
    
    shell_exec("/img/bin/logevent/event 129 &");

    return  MessageBox(true,$words['adminpwd_title2'],$words['lcd_chpwSuccess']); 
}

?> 
