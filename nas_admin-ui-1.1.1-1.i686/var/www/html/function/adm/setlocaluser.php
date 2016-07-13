<?php  
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(WEBCONFIG);

$words = $session->PageCode("localuser");
$gwords = $session->PageCode("global");

$action = $_POST['action'];
$username = $_POST['username'];
$userid = $_POST['userid'];
$groupname = $_POST['groupname'];
$pwd = $_POST['pwd']; 
$pwd_lock = $_POST['pwd_lock']; 
$sqlite="/usr/bin/sqlite";
$conf_db="/etc/cfg/conf.db";
$ldap_enable=shell_exec("$sqlite $conf_db \"select v from conf where k='ldap_enabled'\"");


/******************************************
      validate password is't lock
******************************************/
if(isset($pwd_lock) && $pwd_lock=='0'){
  if(!$validate->limitstrlen(4,99,$pwd))
       return  MessageBox(true,$gwords['error'],$words['pwd_too_short'],'ERROR');
  if(!$validate->check_userpwd($pwd))
       return  MessageBox(true,$gwords['error'],$words['pwd_multi_bytes'],'ERROR');
}

/******************************************
      validate password
******************************************/
if(isset($pwd) && $pwd!=""){
  $pwd=stripslashes($pwd);
  for($i=0;$i<strlen($pwd);$i++){
    $char=substr($pwd,$i,1);
    if(ord($char)=="34" || ord($char)=="36"){
      $char=chr(92).$char;
    }elseif(ord($char)=="92"){
      $char=chr(92).chr(92).chr(92).$char;
    }
    $tmp_pwd.=$char;
  }
  $pwd=$tmp_pwd;
}


switch($action){
   /******************************************
        add localuser 
   ******************************************/
   case 'add': 
        //check field
        if(!$validate->check_username($username))
              return  MessageBox(true,$gwords['error'],$words['user_error'],'ERROR');
        if($userid < $webconfig["user_id_limit_begin"] || $userid >$webconfig["user_id_limit_end"] || (!$validate->numeric(5,'max',$userid))){
              $msg=sprintf($words["user_id_error"],$webconfig["user_id_limit_begin"]);
              return  MessageBox(true,$gwords['error'],$msg,'ERROR');
        }
              
        //check user exist
        if($ldap_enable=="0"){
            $userlist = shell_exec("cut -d \":\" /etc/passwd -f1,3 2>&1");
        }else{
            shell_exec("getent passwd > /tmp/passwd_adduser");
            $userlist = shell_exec("cut -d \":\" /tmp/passwd_adduser -f1,3 2>&1");
        }
        $userlist = explode("\n",$userlist);
        foreach ($userlist as $user){
              $user_info = explode(":",$user);
              if(strtolower($user_info[0])==strtolower($username)){
                 $msg=sprintf($words['user_exist'],$username);
                 return  MessageBox(true,$gwords['error'],$msg,'ERROR');
              }else if($user_info[1]==$userid){                 
                 $ldap_user=shell_exec("cat /raid/sys/ldap.txt | grep \":$user_info[1]:\"");
                 if($ldap_user!="")
                     return  MessageBox(true,$gwords['error'],$words['ldap_userid_dup'],'ERROR');
                 else             
                     return  MessageBox(true,$gwords['error'],$words['userid_dup'],'ERROR');
              } 
        }
        
        //check limit
        $members_list = $groupname;
        $strExec="cat /etc/passwd | awk -F':' '{if($3>=" . $webconfig["user_id_limit_begin"] . "){print $3}}' | wc -l";
        $now_user_count=trim(shell_exec($strExec));
        if($now_user_count >= $webconfig["user_limit"]){
           return MessageBox(true,$gwords['error'],$words['user_limit'],'ERROR');
        }
        
        //add
        if (NAS_DB_KEY == 1)
            $strExec="/usr/sbin/adduser -D -u {$userid} -G smbusers -s /dev/null -h /dev/null {$username}";
        else
            $strExec="/usr/sbin/adduser -D -u {$userid} -G users -s /dev/null -h /dev/null -H -g {$username} {$username}";
        
        exec($strExec,$adduser_out,$adduser_ret);

        if($adduser_ret=="0"){
          if (NAS_DB_KEY == 1)
            $chgpasswd=sprintf("/usr/bin/makepasswd -e shmd5 -p \"%s\"|awk '{print \"%s:\"$2}'|/usr/bin/chpasswd -e",$pwd,$username);
          else
            $chgpasswd=sprintf("/usr/bin/passwd %s %s",$username, $pwd);
            
          shell_exec($chgpasswd);
          joinGroup($username,$members_list);
          smbUserModify($username,"new",$pwd);
          shell_exec("/img/bin/logevent/event 997 104 info \"\" \"{$username}\" &");
          $ary = array('ok'=>'onLoadStore()');
          return MessageBox(true,$words['user_setting'],$words['user_add_success'],'INFO','OK',$ary);  
        }else{
          //error
          smbUserModify($username,"delete");
          $strExec="/usr/sbin/userdel {$username}";
          shell_exec($strExec);
          shell_exec("rm -rf /var/mail/$username");
          $msg=sprintf($words["adduser_failed"],$username);
          return MessageBox(true,$gwords['error'],$msg,'ERROR');
        }
     break;
   /******************************************
        update localuser 
   ******************************************/
   case 'update': 
        $members_list = $groupname;
        joinGroup($username,$members_list);
        if($pwd_lock==0){
            //change password
            smbUserModify($username,"modify",$pwd);

            if (NAS_DB_KEY == 1)
                $chgpasswd=sprintf("/usr/bin/makepasswd -e shmd5 -p \"%s\"|awk '{print \"%s:\"$2}'|/usr/bin/chpasswd -e",$pwd,$username);
            else
                $chgpasswd=sprintf("/usr/bin/passwd %s %s",$username, $pwd);
                        
            shell_exec($chgpasswd); 
        } 
      	shell_exec("/img/bin/logevent/event 997 108 info \"\" \"{$username}\" &");
        return MessageBox(true,$words['user_setting'],$words['user_update_success']);  
     break;
   /******************************************
        delete localuser 
   ******************************************/
   case 'delete': 
          smbUserModify($username,"delete");
          shell_exec("/usr/sbin/userdel $username");
          shell_exec("rm -rf /var/mail/$username");
          joinGroup($username,array());
          shell_exec("/img/bin/logevent/event 997 105 info \"\" \"$username\" &");
          $ary = array('ok'=>'onLoadStore()');
          return MessageBox(true,$words['user_setting'],$words['user_remove_success'],'INFO','OK',$ary);  
     break;
}    




?> 
