<?php 
require_once(INCLUDE_ROOT.'info/smbacl.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(WEBCONFIG);

$words = $session->PageCode("localuser");
$gwords = $session->PageCode("global");
$tpl->assign('words',$words);  
$tpl->assign('gwords',$gwords);  

$store = escapeshellcmd($_REQUEST['store']);
$username = escapeshellcmd($_REQUEST['username']);

//$get_userid = $_POST['get_userid'];  
$get_userid = $_REQUEST['get_userid'];  
$start = $_POST['start'];
$limit = $_POST['limit'];  


/*****************************************
         load user data
******************************************/
if(isset($start)){ 
    $totalcount =0;
    $data = array();
 
    $userlist = shell_exec("cut -d \":\" /etc/passwd -f1,3 2>&1");
 
    $userlist = explode("\n",$userlist);
    foreach ($userlist as $user){
        $user_info = explode(":",$user);
        if(($user_info[0] != "" && $user_info[0] != "admin") && ($user_info[1] >= $webconfig["user_id_limit_begin"] || +$user_info[1] == 97)){
            array_push($data,array('username'=>$user_info[0],'userid'=>$user_info[1]));
            $totalcount++;
        }
    }
    $data=array_slice($data,$start,$limit);
 
    die(json_encode(array('totalcount'=>"$totalcount",'data'=>$data)));
}




/*****************************************
             load new userid 
******************************************/
if(isset($get_userid)){ 
   $smbacl=new SMBACL();
   $grouplist = array();
   $groups=$smbacl->getLocalGroups(1);
   if($username==""){
         for($i=$webconfig["user_id_limit_begin"];$i<$webconfig["user_id_limit_end"];$i++){
            $strExec="getent passwd | awk -F ':' '{print $3}' | grep \"$i\"";
            $user_id_exist=shell_exec($strExec);
            if($user_id_exist==""){
                  $user_id=$i;
                  break;
            }
         }
         array_push($grouplist,array('groupname'=>'users','groupid'=>$webconfig['group_id_limit_begin']));
         die(json_encode(array('get_userid'=>$user_id,'groupname'=>'users','data'=>$grouplist)));
   }else{
         $groupname='';
         foreach ($groups as $group_name=>$group_info){
	      if(in_array($username,$group_info["users"])){
	             $groupname.=$group_name.' ';
                     array_push($grouplist,array('groupname'=>$group_name,'groupid'=>$group_info['id']));
	      }
         }
         $groupname=substr($groupname,0,strlen($groupname)-1);
         $strExec="cat /etc/passwd | grep \"^".$username.":\" | awk -F':' '{print $3}'";
         $user_id=trim(shell_exec($strExec));
         die(json_encode(array('get_userid'=>$user_id,'groupname'=>$groupname,'data'=>$grouplist)));
   }
}


/*******************************************
  init grouplist
*******************************************/
$smbacl=new SMBACL();
$groups=$smbacl->getLocalGroups(1);
$Data_grouplist='[ ';
foreach ($groups as $group_name=>$group_info){
      if($group_name != "users"){
   	    $Data_grouplist .= "['".$group_info['id']."','$group_name'],";
      }
}
$Data_grouplist = substr($Data_grouplist,0,-1).']';
$tpl->assign('Data_grouplist',$Data_grouplist);
                        
$tpl->assign('limit','10');
$tpl->assign('get_url','getmain.php?fun=localuser'); 
$tpl->assign('set_url','setmain.php?fun=setlocaluser'); 
$tpl->assign('lang',$session->lang);
?>
