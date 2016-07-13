<?
global $etcgroup; 
$etcgroup='/etc/group';
$mypath=dirname(__FILE__);
/* Run samba "weinfo" and parsing it's resulte*/
require_once(realpath("$mypath/../sqlitedb.class.php")); 
require_once(WEBCONFIG);
$db=new sqlitedb();
$winad=$db->getvar('winad_enable','0');
$ldap=$db->getvar("ldap_enabled","0");
$username=$db->getvar('winad_admid','');
$password=$db->getvar('winad_admpwd','');
$authoption=" -U\"{$username}%{$password}\" ";

$cmd='/usr/bin/getent';
$min_localuser_id = $webconfig['user_id_limit_begin'];
$min_localgroup_id = $webconfig['group_id_limit_begin'];

unset($db);
unset($authoption);
unset($mypath);
class SMBACL{
  function getLocalGroups($limit=""){
    global $min_localgroup_id;
    //$strExec="/usr/bin/sqlite /raid/sys/acl_account.db \"select user,id from acl where role='local_group' limit 0,$limit\"";
    $strExec="/bin/cat /etc/group | sort | awk -F':' '/$search/{if($3>=$min_localgroup_id){printf(\"%s:%s:%s\\n\",$1,$3,$4)}}'";
    //echo $strExec."<br>";
    $group=shell_exec($strExec);
    if($group!=""){
      $group=explode("\n",$group);
    }
    //echo $count1."_".$limit1;
    $groups=array();
    foreach($group as $line){
      if($line!=""){
        $group=explode(":",$line);
        $group_tmp=array();
        $group_tmp["id"]=$group[1];
        $group_member=explode(",",$group[2]);
        $group_tmp["users"]=$group_member;
        
        if(substr($group[0],0,3)=="smb")
            $group_name=substr($group[0],3);
        else
            $group_name=$group[0];
        
        $groups[$group_name]=$group_tmp;
      }
    }
    return $groups;
  }
  
  function getLocalUsers($limit1=""){
    global $min_localuser_id;
    //$strExec="/usr/bin/sqlite /raid/sys/acl_account.db \"select user,id from acl where role='local_user' limit 0,$limit1\"";
    $strExec="/bin/cat /etc/passwd | sort | awk -F':' '//{if($3>=$min_localuser_id){printf(\"%s,%s\\n\",$1,$3)}}'";
    //echo $strExec."<br>";
    $user=shell_exec($strExec);
    $user=explode("\n",$user);
    $users=array();
    foreach($user as $line){
      if($line!=""){
        $user=explode(",",$line);
        $user_tmp=array();
        $user_tmp["name"]=$user[0];
        $user_tmp["id"]=$user[1];
        $users[]=$user_tmp;
      }
    }
    return $users;
  }
	
  function getADGroups($limit2=""){
    global $winad;
    global $ldap;
    if($winad=="1" || $ldap=="1"){
      $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user,id from acl where role='ad_group' limit 0,$limit2\"";
      //echo $strExec."<br>";
      $ad_group=shell_exec($strExec);
      $ad_group=explode("\n",$ad_group);
      $ad_groups=array();
      foreach($ad_group as $line){
        if($line!=""){
          $ad_group=explode("|",$line);
          $ad_group_tmp=array();
          $ad_group_tmp["name"]=$ad_group[0];
          $ad_group_tmp["id"]=$ad_group[1];
          $ad_groups[]=$ad_group_tmp;
        }
      }
    }else{
      unset($ad_groups);
    }
    return $ad_groups;
  }
	
  function getADUsers($limit3=""){
    global $winad;
    global $ldap;
    if($winad=="1" || $ldap=="1"){
      $strExec="/usr/bin/sqlite /raid/sys/ad_account.db \"select user,id from acl where role='ad_user' limit 0,$limit3\"";
      //echo $strExec."<br>";
      $ad_user=shell_exec($strExec);
      $ad_user=explode("\n",$ad_user);
      $ad_users=array();
      foreach($ad_user as $line){
        if($line!=""){
          $ad_user=explode("|",$line);
          $ad_user_tmp=array();
          $ad_user_tmp["name"]=$ad_user[0];
          $ad_user_tmp["id"]=$ad_user[1];
          $ad_users[]=$ad_user_tmp;
        }
      }
    }else{
      unset($ad_users);
    }
    return $ad_users;
  }

  function updateLocalGroups($data,$dels,$news){
    global $etcgroup;
    $f=fopen($etcgroup,'rb');
    $groups=array();
    $newitems=array();
    while ($f && !feof($f)){
      $line=fgets($f);
      $newline=$line;
      $line=trim($line);
      if (!$line){
        array_push($newitems,$newline); //restore
        continue;
      }
      list($group,$x,$gid,$ulist)=explode(':',$line);
      if (substr($group,0,3)!=='smb'){
        array_push($newitems,$newline); //restore
        continue;
      }
      $group=substr($group,3);
      if (isset($dels[$group])){
        /* group deleted */
        continue;
      }
      if (!isset($data[$group])){
        array_push($newitems,$newline); //restore
        continue;
      }
      $newitem="smb$group:$x:$gid:".$data[$group]."\n";
      array_push($newitems,$newitem);
    }
    if ($f) fclose($f);
    global $debug;
    if ($debug) file_put_contents("$etcgroup.new",join($newitems));
    else {file_put_contents($etcgroup,join($newitems));}
    return $newitems;
  }
} 
?>
