<?php
$words = $session->PageCode("sshd");
$gwords = $session->PageCode("global");
$SshCmd="/rc/rc.sshd";

$sshd=$_POST['_sshd'];
$port=$_POST['_port'];
$sftp=$_POST['_sftp'];
$Str=IMG_BIN."%s '%s' '%s' '%s' '%s'";
$Cmd=sprintf($Str,$SshCmd,'set',$sshd,$port,$sftp);
shell_exec($Cmd);
$Str=IMG_BIN."%s '%s'";
$Cmd=sprintf($Str,$SshCmd,'get_result');
list($msg,$icon)=explode("|",trim(shell_exec($Cmd)));
$msg_array=explode(",",trim($msg));
foreach ($msg_array as $value)
{
     $words_msg=$words_msg.$words[$value]."<br>";
}
if($icon==info){
    $fun=array('ok'=>'change_old("'.$sshd.'","'.$port.'","'.$sftp.'")');
    return MessageBox(true,$words['title'],$words_msg,strtoupper($icon),'OK',$fun);
}else{
    return MessageBox(true,$words['title'],$words_msg,strtoupper($icon),'OK');
}
?>
