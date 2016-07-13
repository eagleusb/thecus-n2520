<?
  require_once(INCLUDE_ROOT.'sqlitedb.class.php');
  require_once(INCLUDE_ROOT.'function.php');
  require_once(INCLUDE_ROOT.'validate.class.php');
  
  if (NAS_DB_KEY == '1')
  {
    $database="/etc/cfg/isomount.db";
    $db=new sqlitedb($database,"isomount");
    $mountTable = "isomount";
  }
  elseif (NAS_DB_KEY == '2')
  {
    $db=new sqlitedb();
    $mountTable = "mount";
  }

  $words = $session->PageCode("isomount");
  get_sysconf();
  $folder=stripcslashes(trim($_POST['iso_path']));
  $point=stripcslashes(trim($_POST['mount_path']));
  $isomount_folder=stripcslashes(trim($_POST['root_folder']));  

//  $tmpfolder=explode('/',$folder);

  if (NAS_DB_KEY == '1'){
    $isomount_root=escapeshellstring("awk",$isomount_folder);
    $strExec="cat /tmp/smb.conf | awk -F'/' '/\/${isomount_root}$/&&/path = /{print $2}'";
  }elseif (NAS_DB_KEY == '2'){
    $isomount_root=addcslashes($isomount_folder,"($+{}'^)");
    $strExec="cat /etc/samba/smb.conf | awk -F'/' '/\/${isomount_root}$/&&/path = /{print $2}'";
  }
//  echo $isomount_root;
  $raidno=trim(shell_exec($strExec));
  $iso_add_result=array();
  $fn=array();
  $iso_add_result['show']=true;
  $iso_add_result['topic']=$words['isomount_title'];
  $iso_add_result['button']='OK';
  $iso_add_result['prompt']='';
  $iso_add_result['fn']=$fn;
  
//  shell_exec(sprintf("echo '=====%s----%s------%s---------%s-------------' >> /raid0/data/enian1/value1",$folder,$point,$raidno,$isomount_folder));

  function file_basename($file= null) {
    $files = explode('/',$file);
    return $files[count($files)-1];
  }

  	
  function vfilesize($path){
    if (NAS_DB_KEY == '1'){
      $path=escapeshellstring("common",$path);
    }elseif (NAS_DB_KEY == '2'){      
      $path=addcslashes($path,"`$");
    }
    $command = "/usr/bin/du -h \"$path\" | awk '{print $1}'";
    $sizeInBytes = trim(shell_exec($command));       
    return $sizeInBytes.'B';
  }

  if (file_exists("/${raidno}/data".$folder)) {
    $rpath="/${raidno}/data".$folder;
  } else {
    $rpath=false;
  }
  $arpath=explode('/',$rpath,5);
  $rs=$db->runSQL("select count(*) from ". $mountTable);
  
  $isomount_limit=sprintf($words['isomount_limit'],$sysconf["isomount"]);
 
  if(strlen($folder)==0){
    $iso_add_result['message']=$words['isomount_empty'];
    $iso_add_result['icon']='ERROR';
    $iso_add_result['result']=0;       
    return $iso_add_result;
  }else if(!$validate->check_isomountfolder($point)){
    unset($db);
    $iso_add_result['message']=$validate->errmsg;
    $iso_add_result['icon']='ERROR';
    $iso_add_result['result']=0;       
    return $iso_add_result;
  }else if ($rs[0] >= $sysconf["isomount"]){
    unset($db);
    $iso_add_result['message']=$isomount_limit;
    $iso_add_result['icon']='ERROR';
    $iso_add_result['result']=0;
    return $iso_add_result;
 //   return array(true,$words['isomount_title'],$isomount_limit."123213",'ERROR');
  }else if ($arpath[3] != $isomount_folder){
    unset($db);
    $iso_add_result['message']=$words['invalid_path']." : '".$folder."' !!";
    $iso_add_result['icon']='ERROR';
    $iso_add_result['result']=0;
    return $iso_add_result;
 //   return MessageBox(true,$words['isomount_title'],$words['invalid_path']." : '".$folder."' !!",'ERROR');
  }else if  (!file_exists("/${raidno}/data/".$folder)){
    unset($db);
    $iso_add_result['message']=$folder." : ".$words['file_not_exist'];
    $iso_add_result['icon']='ERROR';
    $iso_add_result['result']=0;
    return $iso_add_result;
  //  return MessageBox(true,$words['isomount_title'],$folder." : ".$words['file_not_exist'],'ERROR');
  }else{
    $arpath=explode('/',$rpath,4);
    $folder = '/'.$arpath[3];
    $folder_info=pathinfo($folder);
    if ($point != ''){
      $point=$folder_info["dirname"].'/'.$point;
    }else{
      if (strlen($folder_info["extension"]) != 0){
        $point=$folder_info["dirname"].'/'.substr(file_basename($folder),0,-strlen($folder_info["extension"])-1);
      }else{
        $point=$folder;
      }
    }
    //if (file_exists('/raid/data/ftproot/'.$point)) {
    if (file_exists("/${raidno}/data/".$point)) {
      unset($db);
      $iso_add_result['message']=$point." : ".$words['file_exist'];
      $iso_add_result['icon']='ERROR';
      $iso_add_result['result']=0;
      return $iso_add_result;
      //return MessageBox(true,$words['isomount_title'],$point." : ".$words['file_exist']."exsit",'ERROR') ;
    }
    //########################################################
    //#	Check loop number
    //########################################################
    
    if (NAS_DB_KEY == '1'){
      $loopPath = "/dev/loop/loop";
      $strExec="df | grep \"$loopPath\" | awk '{printf(\"%s,\",substr(\$1,15))}'";
    }elseif (NAS_DB_KEY == '2'){
      $loopPath = "/dev/loop";
      $strExec="df | grep \"$loopPath\" | awk '{printf(\"%s,\",substr(\$1,10))}'";
    }
    
    $device_list=shell_exec($strExec);
    $in_mount_tmp=explode(",",$device_list);
    $in_mount=array();
 
    foreach($in_mount_tmp as $v){
      if($v!=""){
        $in_mount[]=trim($v);
      }
    }
    
    for($i=20;$i<$sysconf["isomount"]+20;$i++){
      $exist="";
      foreach($in_mount as $num){
        if($i==$num){
          $exist="1";
          break;
        }
      }
      if($exist!="1"){
        if(!file_exists($loopPath."${i}")){
          $strExec="mknod $loopPath" . "${i} b 7 ${i}";
          shell_exec($strExec);
          $loop="loop".$i;
          break;
        }else{
          $loop="loop".$i;
          break;
        }
      }
    }
    //########################################################
    //mkdir("/raid/data/ftproot".$point);
    mkdir("/${raidno}/data".$point);
    //$cmd='/bin/mount -t iso9660 -o loop=/dev/loop/'.${loop}.',user "/raid/data/ftproot'.$folder.'" "/raid/data/ftproot'.$point.'"';
    if (NAS_DB_KEY == '1'){
      $mount_folder=escapeshellstring("common",$folder);
      $mount_point=escapeshellstring("common",$point);
      $cmd="/bin/mount -t udf,iso9660 -o loop=/dev/loop/".${loop}.",user,iocharset=utf8 \"/${raidno}/data".$mount_folder."\" \"/${raidno}/data".$mount_point."\"";
    }elseif (NAS_DB_KEY == '2')
      $cmd="/bin/mount -t udf,iso9660 -o loop=/dev/".${loop}.",user \"/${raidno}/data".addcslashes($folder,"`$")."\" \"/${raidno}/data".addcslashes($point,"`$")."\" >/dev/null 2>&1";
//    shell_exec(sprintf("echo '=====%s----%s------%s------%s-----------' >> /raid0/data/enian1/value",$raidno,$loop,$folder,$point));
    system($cmd,$result);   
    
    if ($result == 0){
      $rs=$db->runSQL("insert into ". $mountTable ." (label,iso,point,size) values (\"".$isomount_folder."\",\"".$folder."\",\"".$point."\",\"".vfilesize("/${raidno}/data/".$folder)."\")");        
      unset($db);
     // $folder = str_replace('+','%2B',$folder);
     // $point = str_replace('+','%2B',$point);
      $iso_add_result['message']=$folder." ".$words['mount_success'];
      $iso_add_result['icon']='INFO';
      $iso_add_result['result']=1;
      $fn['ok']='update_grid_data(1)';
      $iso_add_result['fn']=$fn;
      return $iso_add_result;
   //   return MessageBox(true,$words['isomount_title'],$folder." ".$words['mount_success']);
    }else{
      //rmdir("/raid/data/ftproot".$point);
      unset($db);
      rmdir("/${raidno}/data".$point);
      //$folder = str_replace('+','%2B',$folder);
      $iso_add_result['message']=$folder." ".$words['mount_error'];
      $iso_add_result['icon']='ERROR';
      $iso_add_result['result']=0;
      return $iso_add_result;
     // return MessageBox(true,$words['isomount_title'],$folder." ".$words['mount_error']."end",'ERROR');
    }
  }
?>
