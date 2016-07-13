<?
require_once(INCLUDE_ROOT.'function.php');
get_sysconf();

if (NAS_DB_KEY==1)
{
  $strExec="ls -l /raid/sys | awk '{print $11}' | awk -F'/' '{print $2}'";
  $master_raid=trim(shell_exec($strExec));
  $vg_name="vg".trim(substr($master_raid,4,1));
  $strExec="mount | grep \"/dev/${vg_name}/syslv\" | grep rw | wc -l";
}
elseif (NAS_DB_KEY==2)
  $strExec="/bin/mount | /bin/grep md0 | /bin/grep rw | /usr/bin/wc -l";

$logpath=(shell_exec($strExec)==0)?"/var/log":"/raid/sys";

if (NAS_DB_KEY==2)
{
  if (shell_exec("/bin/mount | /bin/grep -c ' /syslog '")==1)
    $logpath="/syslog";
  
  if ($logpath=="/raid/sys")
    if( (!file_exists("/raid/sys/error")) || (!file_exists("/raid/sys/warning")) || (!file_exists("/raid/sys/information")) )
      shell_exec("/img/bin/logevent/sysinfo  > /dev/null 2>&1;");
}

$info_type=$_GET['info_type'];
$log_file=$_GET['log_file'];
$download_flag=$_GET['download_flag'];

if($download_flag=='1'){
  $loger = "error";
  $logwn = "warning";
  $logif = "information";
  header("Content-Type: application/octet-stream");
  header("Content-Disposition: attachment; filename=".$info_type.".tar.gz;");
  header("Pragma: ");
  header("Cache-Control: ");
  header("Content-length: " . filesize($dfile));

  if($logpath=="/raid/sys")
    if( (!file_exists("/raid/sys/error")) || (!file_exists("/raid/sys/warning")) || (!file_exists("/raid/sys/information")) )
      shell_exec("/img/bin/logevent/sysinfo  > /dev/null 2>&1;");

  if($info_type=='all'){
  //   echo "cd $logpath;tar zcf $logpath/logal.tar.gz $loger $logwn $logif";
    shell_exec("cd $logpath;tar zcf $logpath/logal.tar.gz $loger $logwn $logif");
    readfile("$logpath/logal.tar.gz");
    shell_exec("rm -rf $logpath/logal.tar.gz");
  }else{ 
    shell_exec("cd $logpath;tar zcf $logpath/".$log_file.".tar.gz ".$log_file);
    readfile("$logpath/".$log_file.".tar.gz");
    shell_exec("rm -rf $logpath/".$log_file.".tar.gz");
//    readfile($$_GET['logtype']);
  }
  exit;
}
?>
