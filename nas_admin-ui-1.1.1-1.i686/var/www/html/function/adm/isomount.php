<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'function.php');
$words = $session->PageCode("isomount");

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

require_once(INCLUDE_ROOT."function.php");
get_sysconf();
//#######################################################
//#  Create share folder item
//#######################################################
$start=$_POST['start'];
$limit=$_POST['limit'];
$sort=$_POST['sort'];
$sort_style=$_POST['dir'];
$root=$_POST['roots'];
/*$fp=fopen('/raid0/data/enian1/post1','a');
foreach($_POST as $key=> $row){
  fwrite($fp,$key."=".$row);
}  
fclose($fp);

$fp=fopen('/raid0/data/enian1/get1','a');
foreach($_Get as $key=> $row){
  fwrite($fp,$key."=".$row);
}  
fclose($fp);

$fp=fopen('/raid0/data/enian1/request1','a');
foreach($_REQUEST as $key=> $row){
  fwrite($fp,$key."=".$row);
}  
fclose($fp);
*/

function sort_iso_data($sort,$sort_type){
  global $isomount_data;
  $sort_order = SORT_DESC;
  if($sort_type=='ASC')
    $sort_order = SORT_ASC;

  foreach($isomount_data as $key=> $row){
    $poit[$key]=$row['point'];
    $iso[$key]=$row['iso'];
    $size[$key]=$row['size'];
  }  
  if ($sort=='iso') 
    list($iso,$poit)=array($poit,$iso); 
  if ($sort=='size')
    list($size,$poit)=array($poit,$iso);
   
  array_multisort($poit,$sort_order,$iso,SORT_DESC,$size,SORT_DESC,$isomount_data);
}


if(!isset($root)){
  $share_list=array();
/*  if (NAS_DB_KEY == '1')
    $share_list = trim(shell_exec("awk -F'[][]' '/^\\[/{if(\$2!=\"global\" && \$2!=\"snapshot\"){print \$2}}' /tmp/smb.conf"));
  elseif (NAS_DB_KEY == '2')
    $share_list = trim(shell_exec("awk -F'[][]' '/^\\[/{if(\$2!=\"global\"){print \$2}}' /etc/samba/smb.conf"));
  
  $share_list = explode("\n",$share_list);
  $except_list = array("");
  $share_list = array_diff($share_list, $except_list);
  $share_folder=array();
  $ismount_data=array();*/
  $share_list=get_total_folder(1);
  foreach($share_list as $v){
    if($v!="snapshot")
      $share_folder[]=array("value"=>$v,"display"=>$v);
  }

//#######################################################
  if (count($share_list) == 0){
    $rs=$db->db_delete("isomount","");
  }
}

//#######################################################
//#     Get folder realy path in raid
//#######################################################
/*require_once(INCLUDE_ROOT."info/raidinfo.class.php");
$raidinfo=new RAIDINFO();
$md_count=$raidinfo->getMdarray();*/
//#######################################################
/*function mb_str_split($str, $length = 1) {
  if ($length < 1) return FALSE;

  $result = array();
  $rs = array();
  $mb_string = preg_split('//u', $str);

  $p=0;
  $xlen=0;
  foreach ($mb_string as $q){
    $rs[$p][]=$q;
    if (strlen($q) > 1){
      $xlen=$xlen+2;
    }else{
      $xlen++;
    }
    if ($xlen >= $length){
      $xlen=0;
      $p++;
    }
  }
  foreach($rs as $im){
    $k='';
    for ($i=0;$i<count($im);$i=$i+1){
      $k.=$im[$i];
    }
    $result[]=$k;
  }

  return $result;
}

function filename_format($filename,$len=24){
  if (strlen($filename) > $len){
    $tmp_str=mb_str_split($filename,$len);
    $rs=array_shift($tmp_str).'<br>';
    foreach($tmp_str as $ln){
      $rs.='&nbsp;'.$ln.'<br>';
    }
  }else{
    $rs=$filename;
  }
  return $rs;
}
*/

if (NAS_DB_KEY == '1')
{
  $strExec="/img/bin/rc/rc.isomount check_db";
  shell_exec($strExec);
}

if(!isset($root)){
  $isomount_list=$db->db_get_folder_info($mountTable,"iso,point,size","order by point");
}else{
  $isomount_list=$db->db_get_folder_info($mountTable,"iso,point,size","where label='".$root."' order by point");
}

/*$str="/enian1/CLI_XP_3_0_20060803,/enian1/Fedora-10-i386-DVD";
$tmp=explode(',',$str);
 echo sizeof($tmp);

$strExec="mount | grep '/dev/loop/loop' | cut -d ' ' -f 3- | sed -n 's/ type iso9660 (ro,nosuid,nodev,noexec)//gp'";
$mount_list=shell_exec($strExec);
  
$isomount_list_tmp=$db->db_get_folder_info("isomount","point","");

  foreach($isomount_list_tmp as $k=>$v){
    $isomount_list11[$k]=$v["point"];
  }
    
  foreach ($isomount_list11 as $isomount){
    echo $isomount."<br>";
    $iso_array=explode("/",$isomount);
    $share_name=$iso_array[1];
    
    foreach($md_count as $v){
      if($v!=""){
        $v=trim($v);
        $raidno="raid".($v-1);
        $strExec="/usr/bin/sqlite /${raidno}/sys/raid.db \"select share from folder where share='${share_name}'\"";
        $folder_exist=shell_exec($strExec);
        if($folder_exist!=""){
          break;
        }
      }
    }

    $strExec="df | grep \"${isomount}$\" | awk '{print $1}'";
    $loop_device=shell_exec($strExec);
    $pos = strpos($mount_list, $isomount);
    echo "------".$mount_list." ----- ".$isomount."<br>";
}

*/

foreach ($isomount_list as $isomount){
//$isomount["point"] = str_replace('+','%2B',$isomount[point]);
//$isomount["iso"] = str_replace('+','%2B',$isomount[iso]);
$isomount_data[]=array('size'=>$isomount["size"],'point'=>$isomount["point"],'iso'=>$isomount["iso"]);
}

$tpl->assign('words',$words);
$tpl->assign('isomout_data',json_encode($isomount_data));
$tpl->assign('share_folder',json_encode($share_folder));
$tpl->assign('f_folder_name',$share_folder[0]["value"]);
$tpl->assign('url','/adm/getmain.php?fun=isomount');
$tpl->assign('limit',13);
$tpl->assign('limit1',12);
$tpl->assign('url_iso_add','/adm/getmain.php?fun=isomount_table&iso_filter=');
$tpl->assign('isomount',$sysconf["isomount"]);
$tpl->assign('isomount_desp',sprintf($words["isomount_desp"],$sysconf["isomount"]));
$tpl->assign('lang',$session->lang);
sort_iso_data($sort,$sort_style);

unset($db);

$count=sizeof($isomount_data);
$isomount=array();
$tpl->assign('isomount_count',$count);
if(($limit+$start) > $count)
  $current_count=$count;
else
  $current_count=$limit+$start;
  
if($start!=''){
  for($i=$start;$i<$current_count;$i++){
   $isomount[]= $isomount_data[$i];   
  }
  $ary = array('totalcount'=>$count,'topics'=>$isomount);
  die(json_encode($ary));
}


?>
