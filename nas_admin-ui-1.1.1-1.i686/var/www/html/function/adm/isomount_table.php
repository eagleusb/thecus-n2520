<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
// from php manual page
$max_folder_count=50;
$max_file_count=50;
$folder_count=0;
$file_count=0;
$iso_filter=$_REQUEST['iso_filter'];

if (NAS_DB_KEY == '1')
{
  $database="/etc/cfg/isomount.db";
  $db=new sqlitedb($database,"isomount");
}
elseif (NAS_DB_KEY == '2')
  $db=new sqlitedb();
  
/*function formatBytes($val, $digits = 3, $mode = "SI", $bB = "B"){ //$mode == "SI"|"IEC", $bB == "b"|"B"
   $si = array("", "K", "M", "G", "T", "P", "E", "Z", "Y");
   $iec = array("", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi", "Yi");
   switch(strtoupper($mode)) {
       case "SI" : $factor = 1000; $symbols = $si; break;
       case "IEC" : $factor = 1024; $symbols = $iec; break;
       default : $factor = 1000; $symbols = $si; break;
   }
   switch($bB) {
       case "b" : $val *= 8; break;
       default : $bB = "B"; break;
   }
   for($i=0;$i<count($symbols)-1 && $val>=$factor;$i++)
       $val /= $factor;
   $p = strpos($val, ".");
   if($p !== false && $p > $digits) $val = round($val);
   elseif($p !== false) $val = round($val, $digits-$p);
   return round($val, $digits) . " " . $symbols[$i] . $bB;
}*/
/*
$fp=fopen('/raid0/data/enian1/post','a');
fwrite($fp,sizeof($_POST)."\n");
foreach($_POST as $key=> $row){
  fwrite($fp,$key."=".$row);
}  

fclose($fp);

$fp=fopen('/raid0/data/enian1/get','a');
foreach($_Get as $key=> $row){
  fwrite($fp,$key."=".$row);
}  
fclose($fp);

$fp=fopen('/raid0/data/enian1/request','a');
foreach($_REQUEST as $key=> $row){
  fwrite($fp,$key."=".$row);
}  
fclose($fp);
*/

$node = isset($_REQUEST['node'])?$_REQUEST['node']:"";
$root= explode('/',$node);

if (NAS_DB_KEY == '1')
{
  $root[0]=escapeshellstring("awk",$root[0]);
  $strExec="cat /tmp/smb.conf | awk -F'/' '/\/".$root[0]."$/&&/path = /{print $2}'";
  $raidno=trim(shell_exec($strExec));
}
elseif (NAS_DB_KEY == '2')
{
  //$strExec="cat /etc/samba/smb.conf | awk -F'/' '/".$root[0]."$/&&/path = /printf(\"%s,%s;\",$2,$4)}'";
  $root[0]=addcslashes($root[0],"($+{}'^)");
  $strExec="cat /etc/samba/smb.conf | awk -F'/' '/\/".$root[0]."$/&&/path = /{print $2}'";
  $raidno=trim(shell_exec($strExec));
}

if(strpos($node, '..') !== false){
    die('Nice try buddy.');
}
$nodes = array();
$node=stripcslashes($node);
$path='/'.$raidno.'/data/'.$node;
//shell_exec(sprintf("echo '=====%s----%s==%s=%s=' >> /raid0/data/enian1/value",$raidno,$node,$path,$iso_filter));
if(!is_dir($path))
  die(json_encode($nodes));

$d = dir($path);

while($f = $d->read()){
    if($f == '.' || $f == '..' || substr($f, 0, 1) == '.')continue;
    if (!$validate->check_ignore_file($f)) continue;

    if(($folder_count > $max_folder_count-1) && ($file_count > $max_file_count-1))
     break;
//    $lastmod = date('M j, Y, g:i a',filemtime($dir.$node.'/'.$f));
    if(is_dir($path.'/'.$f)){
//        $qtip = 'Type: Folder<br />Last Modified: '.$lastmod;
      if ($folder_count > ($max_folder_count-1)) continue;
      
      $nodes[] = array('text'=>$f, 'id'=>$node.'/'.$f/*, 'qtip'=>$qtip*/, 'cls'=>'folder');
      //shell_exec(sprintf("echo '=====%s----%s==%s==' >> /raid0/data/enian1/value1",$raidno,$node,$f));
      $folder_count++;
    }else{
//        $size = formatBytes(filesize($path.'/'.$f), 2);
//        $qtip = 'Type: JavaScript File<br />Last Modified: '.$lastmod.'<br />Size: '.$size;
        if ($file_count > ($max_file_count-1)) continue;
        $path_parts = pathinfo($f);
        if ((strtolower($path_parts["extension"]) != 'iso') && ($iso_filter=='true')){
        //   shell_exec(sprintf("echo '=====%s----%s==%s=%s=' >> /raid0/data/enian1/test1",$raidno,$node,$f,$iso_filter));
            continue;
          }
        
        if (NAS_DB_KEY == '1')
          $cmd="select count (*) from isomount where iso=\"/".$node."/".$f."\"";
        elseif (NAS_DB_KEY == '2')
          $cmd="select count (*) from mount where iso=\"/".$node."/".$f."\"";
          
//        $rs=$db->db_get_folder_info('isomount','iso',"where iso='/".$node."/".$f."'");
        $rs=$db->runSQL($cmd);
 //       shell_exec(sprintf("echo '=====%s----%s==%s=%s=' >> /raid0/data/enian1/test1",$raidno,$node,$f,$rs[0]));
        if($rs[0]==0){
          $nodes[] = array('text'=>$f, 'id'=>$node.'/'.$f, 'leaf'=>true/*, 'qtip'=>$qtip, 'qtipTitle'=>$f */, 'cls'=>'file');
          $file_count++;
        }
    }
}
unset($db);
$d->close();
die(json_encode($nodes));
?>
