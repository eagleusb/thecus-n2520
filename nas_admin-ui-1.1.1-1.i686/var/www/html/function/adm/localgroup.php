<?php 
require_once(INCLUDE_ROOT.'info/smbacl.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("localgroup");
$gwords = $session->PageCode("global");
$tpl->assign('words',$words);  
$tpl->assign('gwords',$gwords);  

 
$get_groupid = $_REQUEST['get_groupid'];  
$start = $_POST['start'];
$limit = $_POST['limit'];  
$store = $_REQUEST['store'];  
$groupname = $_REQUEST['groupname'];  

$cmd_getusers = "cut -d \":\" /etc/passwd -f1,3 2>&1";


/*****************************************
         load group data
******************************************/
if(isset($start)){ 
 $totalcount =0;
 $data = array();
 
 $smbacl=new SMBACL();
 $groups=$smbacl->getLocalGroups(1);
 foreach ($groups as $group_name => $group_info){
          array_push($data,array('groupname'=>$group_name,'groupid'=>$group_info[id]));
          $totalcount++;
 }
 
 $data=array_slice($data,$start,$limit);
 die(json_encode(array('totalcount'=>"$totalcount",'data'=>$data)));
}





/*****************************************
             load new groupid 
******************************************/
if(isset($get_groupid)){ 
   require_once(WEBCONFIG);
   $smbacl=new SMBACL();
   $groups=$smbacl->getLocalGroups(1);
   if($groupname==""){
         for($i=$webconfig["group_id_limit_begin"];$i<$webconfig["group_id_limit_end"];$i++){
            $strExec="cat /etc/group | grep \":$i:\"";
            $group_id_exist=shell_exec($strExec);
            if($group_id_exist==""){
                  $group_id=$i;
                  break;
            }
         }
         die(json_encode(array('get_groupid'=>$group_id)));
   }else{
         $username=''; 
         $userlist = array();
         $users = shell_exec($cmd_getusers);
         $users = explode("\n",$users);
         foreach ($users as $user){
              $user_info = explode(":",$user);
              if($user_info[0] != "" && $user_info[1] >= $webconfig["user_id_limit_begin"] && in_array($user_info[0],$groups[$groupname]['users']) ){
                       $username.=$user_info[0].' ';
                       array_push($userlist,array('userid'=>$user_info[1],'username'=>$user_info[0]));
              }
         } 
         $username=substr($username,0,-1);         
         
         if (NAS_DB_KEY==1)
            $strExec="cat /etc/group | grep \"^smb".$groupname.":\" | awk -F':' '{print $3}'";
         else
            $strExec="cat /etc/group | grep \"^".$groupname.":\" | awk -F':' '{print $3}'";
         
         $group_id=trim(shell_exec($strExec));
         die(json_encode(array('get_groupid'=>$group_id,'username'=>$username,'data'=>$userlist)));
   }
}


/******************************************
    load userlist
******************************************/
$userlist = '[ ';
$users = shell_exec("cut -d \":\" /etc/passwd -f1,3 2>&1");
$users = explode("\n",$users);
foreach ($users as $user){
        $user_info = explode(":",$user);
        if($user_info[0] != "" && $user_info[1] >= $webconfig["user_id_limit_begin"]){
              $userlist .= "['".$user_info[1]."','".$user_info[0]."'],";
        }
}
$userlist = substr($userlist,0,-1).']';
$tpl->assign('Data_userlist',$userlist);
                        
$tpl->assign('limit','10');
$tpl->assign('get_url','getmain.php?fun=localgroup'); 
$tpl->assign('set_url','setmain.php?fun=setlocalgroup'); 
$tpl->assign('lang',$session->lang);
?>
