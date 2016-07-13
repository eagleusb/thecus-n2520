<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');

define('DVD_GENISOIMAGE','/tmp/genisoimage.txt');
define('DVD_ERR_NUM','102'); 

$ac = $_REQUEST['ac'];
$isForMainPanel = $_POST['isForMainPanel'];

$drive = $_POST['drive'];
$speed = $_POST['speed'];
$label = $_POST['label'];   //check   *_:\;'/

$data = $_POST['data'];     //check   /\
$iso = $_POST['iso'];
$verify = $_POST['verify'];
$path = $_REQUEST['path'];
$onlydir = $_REQUEST['onlydir'];
$extension = $_REQUEST['extension'];
$totalsize = $_POST['totalsize'];

$pattern = '/^\/raid.{0,2}\/data\//';

/**
* get convert size
* @param {Number} size
* @return {String} size+type(KB/MB/GB....)
*/ 
function convert($size=0){
    $size = (int)$size;
    if($size<1024){
        $type = 'KB';
        $csize = $size;
    }elseif($size < 1048567){
        $type = 'MB';
        $csize = round(($size/1024),2);
    }elseif($size < 1073741824){
        $type = 'GB';
        $csize = round(($size/pow(1024, 2)),2);
    }else{
        $type = 'TB';
        $csize = round(($size/pow(1024, 3)),2);
    }
    return $csize.' '.$type;
}

/**
* get disc information and speed
* @param {String} drive name
* @return {Array} info and speed
*/ 
function getInfo($drive){
    if(!empty($drive)){
        $p = popen(IMG_BIN."/burn_cd.sh info '$drive'", 'r');
        $line = trim(fread($p, 4096));
        pclose($p);

        list($type , $status, $size, $speed) = explode("|", $line);
        if($size != ''){
            $size = convert($size/1024);
        }
        $info_ary = array('type'=> $type, 'status'=>$status, 'size'=>$size);
        $speed_ary = array();
        if($speed != ''){
            $sary = explode(",", $speed);
            foreach($sary as $v){
                $v = trim($v);
                if(!empty($v)){
                    array_push($speed_ary, array("value"=>$v, "display"=>$v.'x'));
                }
            }
        }
        return array("info"=>$info_ary, "speed"=>$speed_ary);
    }else{
        return array("info"=>'', "speed"=>'');
    }
}

 
/**
* get root folder
* @param {Bool} 1 is onlydir , otherwise 0
* @return {Array} root node
*/                                                                      
function getRootFolder($onlydir='0'){
     global $validate;
     $raid_class=new RAIDINFO();
     $md_array=$raid_class->getMdArray();
     $folder_list = array();
     foreach($md_array as $num){
        if (NAS_DB_KEY == '1'){
          $database="/raid".($num-1)."/sys/raid.db";
          $strExec="/bin/mount | grep '/raid".($num-1)."/data'";
          $raid_data_result=shell_exec($strExec);
        }else{
          $database="/raid".($num)."/sys/smb.db";
          $strExec="/bin/mount | grep '/raid".$num."'";
          $raid_data_result=shell_exec($strExec);
        }
        if($raid_data_result!=""){
          $db = new sqlitedb($database,'conf');
          if (NAS_DB_KEY == '1'){
            $db_list=$db->db_getall("folder");
          }else
          {
             $strExec="/usr/bin/sqlite /raid".$num."/sys/smb.db \"select v from conf where k='raid_master'\"";
             $master=trim(shell_exec($strExec)); 
             $db_lista=$db->db_getall("smb_specfd");
             $db_listb=$db->db_getall("smb_userfd");
             if($master=="1"){
                if($db_listb != 0){
                    $db_list=array_merge($db_lista,$db_listb);
                }else{
                    $db_list=$db_lista;
                }
             }else{
                   $db_list=$db_listb;  
             }
          }   
          foreach($db_list as $k=>$list){
            if($list!=""){
               // hide special system folder
               if($validate->hide_system_folder($list["share"])){
                   continue;
               }
               if (NAS_DB_KEY == '1'){
                 $url = "/raid".($num-1).'/data/'.$list["share"];
               }else{
                 $url = "/raid".($num).'/data/'.$list["share"];
               }
               if($onlydir == '1' && !is_dir($url)){
                   continue;
               }
               
               if(is_dir($url)){
                    $tag['mainCls'] = 'folder-icon';
                    $tag['isFolder'] = true;
               }else{
                    $tag['mainCls'] = 'file-icon';
                    $tag['isFolder'] = false;
                    
               }
               $tag['url'] = $url;
               $tag['id'] = $url;
               $tag['text']=addslashes($list["share"]);               
               array_push($folder_list, $tag);
            }
          }
          foreach($folder_list as $key=>$value){
            $name[$key] = $value['text'];
          }
          array_multisort($name, SORT_ASC, $folder_list);
        }
     }
     return $folder_list;
}

/**
* get sub-folder 
* @param {String} sub folder path
* @param {Bool} 1 is onlydir , otherwise 0
* @return {Array} node
*/ 
function getSubFolder($path='/raid/data', $onlydir='0', $extension=""){
    if(!is_dir($path)){
        return false;
    }
    $d = dir($path);
    $nodes = array();
    $typeary = explode(",",$extension);
    while($f = $d->read()){
      if($f == '.' || $f == '..' || substr($f, 0, 1) == '.')continue;
      $url = $path.'/'.$f;

      if(is_dir($url)){
        $is_leaf=false;
        $iconCls = 'folder-icon';
      }else{
        if($onlydir == '1'){
            continue;
        }
        if($extension!=''){
            $info = pathinfo($url);
            if(!in_array($info['extension'], $typeary, true)){
                continue;
            }
        }
        $is_leaf=true;
        $iconCls = 'file-icon';
        $size = ((int)filesize($url))/1024;
        $sizename = convert($size);
      }
      $nodes[] = array('url'=>$url,
                       'id'=>$url,
                       'text'=>$f,
                       'isFolder'=>!$is_leaf,
                       'leaf'=>$is_leaf,
                       'mainCls'=>$iconCls
                        );
    }
    
    foreach($nodes as $key=>$value){
      $name[$key] = $value['text'];
    }
    array_multisort($name, SORT_ASC, $nodes);
    
    $d->close();
    return $nodes;
}


/**
* get folder from file manager
* @param {String} path
* @param {Bool} 1 is for main panel, otherwise 0
* @return {Array} node
*/ 
function getFiles($path, $isForMainPanel){ 
    if($isForMainPanel){
        if($path=='/'){
            $ary = getRootFolder();
        }else{
            $ary = getSubFolder($path);
        }
        return array("files"=>$ary);
        
    }else{
        //left tree
        if($path=='/'){
            $ary = getRootFolder('1');
        }else{
            $ary = getSubFolder($path,'1');
        }
        return $ary;
    }
}


switch($ac){
    /**
    * get from file manager 
    */ 
    case 'getfiles':
        if($isForMainPanel){
             if($path=='/'){
                 $ary = getRootFolder($onlydir);
             }else{
                 $ary = getSubFolder($path, $onlydir, $extension);
             }
             $res = array("files"=>$ary);
             
         }else{
             //left tree
             if($path=='/'){
                 $res= getRootFolder('1');
             }else{
                 $res= getSubFolder($path,'1');
             }
         }
        break;
    
    /**
    * get iso folder or files...
    */    
    case 'getfolder':
        if($path == '/'){
            $res = getRootFolder($onlydir);
        }else{
            $res = getSubFolder($path, $onlydir, $extension);
        }
        break;
        
        
    /**
    * get disc information and speed
    */    
    case 'getinfo':
        $res = getInfo($_POST['drive']);
        break;
        
    /**
    * cancel burning task
    */    
    case 'cancel':
        $cmd = IMG_BIN."/cancel_burn.sh";
        pclose(popen($cmd , "r"));
        unlink(DVD_LOG);
        $res = array("result"=>1);
        break;
        
    /**
    * data burn to ISO file
    */  
    case 'data2iso':
        // check correct iso directory 
        $diriso = dirname($iso);
        if(!is_dir($diriso) || !preg_match($pattern,$diriso) ){
            $words = $session->PageCode("dvd");
            $res = array("result"=>0, "msg"=>$words['faildir']);
            break;
        }
        if(strlen($label)>16){
            $res = array("result"=>0, "msg"=>$words['faillabellen']);
            break;
        }
        $data = str_replace('\"','"',$data);
        $data = str_replace("\'","'",$data);
        
        //create data for burn
        $fp = fopen(DVD_GENISOIMAGE, 'w');
        fwrite($fp, $data);
        fclose($fp);

        //go to burn...
        touch(DVD_LOG);
        $cmd = IMG_BIN."/burn_cd.sh burn_iso '$label' '$iso' '$totalsize' > /dev/null 2>&1 &";
        pclose(popen($cmd , "r"));
        $res = array("result"=>1);
        break;
    
    /**
    * data burn to disc
    */    
    case 'data2disc':
        if(strlen($label)>16){
            $res = array("result"=>0, "msg"=>$words['faillabellen']);
            break;
        }
        $data = str_replace('\"','"',$data);
        $data = str_replace("\'","'",$data);
        //create data for burn
        $fp = fopen(DVD_GENISOIMAGE, 'w');
        fwrite($fp, $data);
        fclose($fp);
        
        //go to burn...
        touch(DVD_LOG);
        $cmd = IMG_BIN."/burn_cd.sh burn_cd '$drive' '$label' '$verify' '$speed' '$totalsize' > /dev/null 2>&1 &";
        pclose(popen($cmd , "r"));
        $res = array("result"=>1);
        break;
    
    /**
    * ISO file burn to disc
    */    
    case 'iso2disc':
        // check correct iso file
        $iso_is_file = (bool)shell_exec("test -f ".$iso." && echo -n 1 || echo -n 0") ;
        if(!$iso_is_file || !preg_match($pattern,$iso)){
            $words = $session->PageCode("dvd");
            $res = array("result"=>0, "msg"=>$words['failiso']);
            break;
        }
        //go to burn...
        touch(DVD_LOG);
        $cmd = IMG_BIN."/burn_cd.sh iso_disc '$drive' '$iso' '$verify' '$speed' > /dev/null 2>&1 &";
        pclose(popen($cmd , "r"));
        $res = array("result"=>1);
        break;

    /**
    * disc burn to ISO file
    */ 
    case 'disc2iso':
        // check correct iso directory 
        $diriso = dirname($iso);
        if(!is_dir($diriso) || !preg_match($pattern,$diriso)){
            $words = $session->PageCode("dvd");
            $res = array("result"=>0, "msg"=>$words['faildir']);
            break;
        }
        
        //go to burn...
        touch(DVD_LOG);
        $cmd = IMG_BIN."/burn_cd.sh desc_to_iso '$drive' '$iso' > /dev/null 2>&1 &";
        pclose(popen($cmd , "r"));
        $res = array("result"=>1);
        break;
        
    case 'makesize':
        $total = 0;
        $ary = explode("|", $data);
        foreach($ary as $v){
            if(!empty($v)){
                $size = trim(shell_exec("/usr/bin/du \"".$v."\" -s |awk -F\" \" '{print $1}'"));
                $total += (int)$size;
            }
        }
        $res = $total;
        break;
    
    /**
    * monitor...
    */     
    default:
        //get wording
        $words = $session->PageCode("dvd");
        $wording = array($words['burningtitle'], $words['burningload'], $words['burn'], $words['success']);
        
        //get flag value
        $content = str_replace("\n","",trim(file_get_contents(DVD_LOG))); 
        list($res, $resmsg, $progress, $step) = explode("|", $content);
        
	    //doing...
        if($res != DVD_ERR_NUM){
            $msg = ($step=='')?'':$words[trim($step)];
        }else{
        //error
            $msg = ($resmsg=='')?'':$words[trim($resmsg)];
        }
        $dvd = array( "res"=>$res, "msg"=>$msg,  "progress"=>$progress ,  "wording"=>$wording);
        return $dvd;
        die;
}

die(json_encode($res));
?>
