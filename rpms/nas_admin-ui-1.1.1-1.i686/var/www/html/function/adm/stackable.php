<?php
require_once(WEBCONFIG);
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
//require_once(INCLUDE_ROOT.'db.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'validate.class.php');

$words = $session->PageCode("stackable");
$awords = $session->PageCode("acl");
$nwords = $session->PageCode("nsync");
$gwords = $session->PageCode("global");


$target_port="3260";
                          
/**************** request parameter *********************/
$tree = initWebVar('tree');  
$store=$_REQUEST["store"]; 
$sharename=$_REQUEST["share"]; 
$md_num=$_REQUEST["md"];  
$winad=$sysconf["winad"] | $sysconf["ldap"];
  
$share = $_POST['share'];
$target_ip = $_POST['_target_ip'];
//$target_port = $_POST['_target_port'];
$pattern_ip = '/[\/\ :;<=>?\[\]\\\\*\+\,]/';

$database=SYSTEM_DB_ROOT.'stackable.db';
$db = new sqlitedb($database,"stackable");   
$db_all=$db->db_getall();
$folder_info=$db->db_get_folder_info("stackable","*","where share='$share'");
$unique_info=$db->db_get_folder_info("stackable","ip,port,iqn","where share!='$share'");
unset($db);
  
if (NAS_DB_KEY == 1){
  $folder_path="/raid/stackable/";
}else{
  $folder_path="/raid/data/stackable/";
}
/*****************************************
    load stackable
******************************************/
if($tree=='1'){ 
  require_once(INCLUDE_ROOT."stackable.class.php");
  $stack=new stackable();
  $stackable_count=count($db_all);
  $stackable_ary=array();
  if($stackable_count >= "1"){
    $c="0";
    foreach($db_all as $k=>$data){
      //echo "<pre>";
      //print_r($data);
      $stack->set_default_value($data);
      //########################################################
      //#       Check capacity
      //########################################################
      $capacity=$stack->check_ui_capacity();
      //########################################################
      //#       Check enabled
      //########################################################
      if($data["enabled"]=="1"){
        $status=$gwords["enable"];
        //########################################################
        //#     Check connection (check session)
        //########################################################
        $record=$stack->stack_check_session();
        //echo "rec=$record";
        if($record!=1){
          $status=$gwords["disable"];
        }elseif($record==1){
          //########################################################
          //#   Check mount
          //########################################################
          $mount_ret=$stack->check_mount();
          //echo $mount_ret;
          if(!$mount_ret){
            $status=$words["unknow"];
          }
        }
        //########################################################
      }else{
        $status=$gwords["disable"];
      }
      //########################################################
      //#       Check button
      //########################################################
      if($status!=$gwords["disable"]){
        $reconnect_disabled="off";
      }else{
        $reconnect_disabled="";
      }
      if($status==$words["unknow"]){
        $format_disabled="";
      }else{
        $format_disabled="off";
      }  
      if($data["guest_only"]=="yes" || $status!=$gwords["enable"]){
        $acl_disabled="off";
      }else{
        $acl_disabled="";
      }
      //########################################################
      $color=$c % 2;
      $c++;
      if($color=="0"){
        $bgcolor="style=\"background:#FFFACD;height:30;\"";
      }else{
        $bgcolor="style=\"height:30;\"";
      }
      
      //$test = mb_abbreviation($data["share"],15,1).",".mb_abbreviation($data["comment"],15,1).",".$data["ip"].",$capacity,$status,".$data["iqn"];
      //echo $test;

      // Parser iqn data (iqn + ip) to array
      $iqn_array=explode(" ", $data['iqn']);

      array_push($stackable_ary,array('share'=>$data["share"],
                                      'comment'=>mb_abbreviation($data["comment"],15,1),
                                      'ip'=>$data['ip'],
                                      'capacity'=>$capacity,
                                      'reconnect'=>$reconnect_disabled,
                                      'format'=>$format_disabled,
                                      'acl'=>$acl_disabled, 
                                      'rootfolder'=>'1',
                                      'status'=>$status,
                                      'iqn'=>$iqn_array[0],
                                      'path'=>$folder_path.$data["share"].'/data',
                                      'uiProvider'=>'col')); 
    } 
    
  } 
  die(json_encode($stackable_ary)); 
} 


/*****************************************
    load share foloder
******************************************/
if($tree=='subfolder'){ 
  $dir = '';
  $node = $_REQUEST['path'];
  $aclshow = $_REQUEST['aclshow'];
  $d = dir($dir.$node);
  $nodes = array();
  if($d){
    while($f = $d->read()){
      if($f == '.' || $f == '..' || substr($f, 0, 1) == '.')continue;
      if(is_dir($dir.$node.'/'.$f)){    
           $nodes[] = array('share'=>$f, 
                            'id'=>$node.'/'.$f, 
                            'path'=>$node.'/'.$f, 
                            'desc'=>'', 
                            'acl'=>$aclshow, 
                            'status'=>'-', 
                            'uiProvider'=>'col',
                            'rootfolder'=>'0');
      } 
    }
    $d->close();
  }
  
  die(json_encode($nodes));
} 
 
/*****************************************
    load iqn
******************************************/
if($store=='iqn_discovery'){   
   die(json_encode(get_iqn($target_ip,$target_port)));
}
  

if($store=='edit'){
  $act="edit"; 
  
  //#######################################################
  //#	Setting value
  //####################################################### 
  $enabled=$folder_info[0]["enabled"];
  $target_ip= $folder_info[0]["ip"];
  $iqn=$folder_info[0]["iqn"];
  $username=$folder_info[0]["user"];
  $password=$folder_info[0]["pass"];
  $share_name=$folder_info[0]["share"];
  $o_share_name=$folder_info[0]["share"];
  $comment=$folder_info[0]["comment"];
  $browseable=$folder_info[0]["browseable"];
  $guest_only=$folder_info[0]["guest_only"];
  $quota_limit=$folder_info[0]["quota_limit"];
  
  $result = get_iqn($target_ip,$target_port,$share_name); 
  $result['data']=array('enabled'=>$enabled,
                           'target_ip'=>$target_ip,
                           'target_port'=>$target_port,
                           'iqn'=>$iqn,
                           'username'=>$username,
                           'password'=>$password,
                           'share_name'=>$share_name,
                           'o_share_name'=>$o_share_name,
                           'comment'=>$comment,
                           'browseable'=>$browseable,
                           'guest_only'=>$guest_only,
                           'quota_limit'=>$quota_limit
                           );
   die(json_encode($result));
}

function check_ip($ip){
    global  $gwords,$words,$validate;
    if(!$validate->ip_address($ip)){   
        if(!$validate->ipv6_address($ip)){
            preg_match($pattern_ip, $ip, $matches);
            if($matches[0]){
                return array('success'=>false,'msg'=>MessageBox(true,$gwords['error'],$words["target_ip_err"],'ERROR')); 
            }else{
                $ip_type=1;
            }
        }else{
            $ip_type=2;
        }
    }else{
        $ip_type=3;
    }
    return $ip_type;
}

function get_iqn($target_ip,$target_port,$share=''){
    global  $gwords,$words,$validate,$unique_info;
    $iscsiadm="/sbin/iscsiadm";
     
          if($target_ip=="")   
               return array('success'=>false,'msg'=>MessageBox(true,$gwords['error'],$words["target_ip_empty"],'ERROR')); 
               
          //ip_type 1=domain 2=ipv6 3=ipv4
          $ip_type = check_ip($target_ip);
          
          $ip_port_iqn=array();
          foreach($unique_info as $k=>$data){
            if($data!=""){
              $datas=explode(" ",$data["iqn"]);
              $data["iqn"]=$datas[0];
              $db_ip_type = check_ip($data["ip"]);
              if($db_ip_type=="1"){                 
                 $ip_port_iqn[]=trim($datas[1]).",".trim($data["port"]).",".trim($data["iqn"]);  
              }elseif ($db_ip_type=="2"){
                 $data["ip"]="[".trim($data["ip"])."]";
              }              
              $ip_port_iqn[]=trim($data["ip"]).",".trim($data["port"]).",".trim($data["iqn"]);
            }
          }
          
          $strExec="/img/bin/clearnode.sh \"$target_ip:$target_port\" 2> /dev/null";
          $discovery_res=shell_exec($strExec);
          if($ip_type=="1"){
              $strExec="$iscsiadm -m discovery -tst --portal $target_ip:$target_port";
          }elseif ($ip_type=="2"){
              $strExec="$iscsiadm -m discovery -tst --portal [$target_ip]:$target_port | grep '\[$target_ip\]':$target_port,";
              $target_ip="[$target_ip]";
          }else{
              $strExec="$iscsiadm -m discovery -tst --portal $target_ip:$target_port | grep $target_ip:$target_port,";
          }
          $discovery_res=shell_exec($strExec);
          $discovery_array=explode("\n",$discovery_res);
          $iqn_flag="";
          $iqn_combo=array();
          foreach($discovery_array as $line){ 
            if($line!=""){
              $paser_line=explode(" ",$line);
              $ip_len=strlen($paser_line[0]);
              $ip=substr($paser_line[0],-$ip_len,-7);
              $iqn=$paser_line[1]; 
              if($iqn!=""){
                $compare_item=$target_ip.",".$target_port.",".$iqn;
                $unique_flag="1"; 
                foreach($ip_port_iqn as $item){ 
                  if($item!="" && $item==$compare_item){
                    $unique_flag="0";
                    break;
                  }else{
                    $iqn_item=trim(shell_exec("echo $item | awk -F',' '{print $3}'"));
                    if($iqn==$iqn_item){
                       $unique_flag="0";
                       break;
                    }else{
                       $unique_flag="1";
                    }
                  }
                } 
                if($unique_flag){
                  $iqn_flag="1";
                  if($ip_type=="1"){
                     $iqn_d="$iqn($ip)";
                     $iqn="$iqn $ip";
                  }else{
                     $iqn_d="$iqn";
                     $iqn="$iqn $ip";
                  }
                  array_push($iqn_combo,array('value'=>$iqn, 'display'=>$iqn_d));
                }
              }
            }
          }
          
          if($iqn_flag==""){ 
            $result=array('success'=>false,'msg'=>MessageBox(true,$gwords['warning'],$words["discovery_empty"],'WARNING')); 
          }else{
            $result = array('success'=>true,'iqn_combo'=>json_encode($iqn_combo));
          }
          return $result;
}

$combo_fields="['value','display']"; 
$iqn_combo="[]";                

        
$acl_combo_value = " [['local_group','".$awords["localGroup"]."'],
                      ['local_user','".$awords["localUser"]."'],
                      ['ad_group','".$awords["adGroup"]."'],
                      ['ad_user','".$awords["adUser"]."']]";
                      
$initiator_iqn=trim(shell_exec("/img/bin/rc/rc.initiator initiator_iqn"));

$tpl->assign('open_mraid',$open_mraid);
$tpl->assign('iqn_combo',$iqn_combo);

$tpl->assign('acl_combo','local_group');
$tpl->assign('target_port',$target_port);

$tpl->assign('combo_fields',$combo_fields); 
$tpl->assign('acl_combo_value',$acl_combo_value);
$tpl->assign('words',$words);
$tpl->assign('gwords',$gwords);
$tpl->assign('nwords',$nwords);
$tpl->assign('awords',$awords);
$tpl->assign('acl_url','getmain.php?fun=acl');
$tpl->assign('get_url','getmain.php?fun=stackable');
$tpl->assign('set_url','setmain.php?fun=setstackable');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('lang',$session->lang);
$tpl->assign('initiator_iqn',strtolower($initiator_iqn));
$tpl->assign('winad',$winad);
?>
