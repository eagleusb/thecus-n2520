<?
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(WEBCONFIG);
include_once(INCLUDE_ROOT.'/info/sysinfo.class.php');
$words = $session->PageCode("disk");
$sysinfo_class = new SYSINFO();
$sysinfo=$sysinfo_class->getINFO();
$disk_class=new DISKINFO();
$disk_no=trim($_GET["diskno"]);
$tray_no=trim($_GET["trayno"]);
$disk_type=$disk_class->getDiskType($tray_no);
if ($disk_no=="") $disk_no="a";

if ($disk_type==0){
  $smartdev=$disk_class->SMARTDevice();
  $strExec="/usr/sbin/smartctl -i -d $smartdev /dev/sd" . $disk_no . "|awk '/SMART support is: Enabled/{cval=cval+1;}END{printf(\"%d\",cval);}'";

  $smart_enable = shell_exec($strExec);
  //echo "smart_enable=$smart_enable<br>";
  if ($smart_enable=="0") {
    $strExec="/usr/sbin/smartctl -s on -d $smartdev /dev/sd" . $disk_no;
    $ret = shell_exec($strExec);
  //echo "ret=$ret <br>";
  }
  
  $strExec="/usr/sbin/smartctl -A -d $smartdev /dev/sd" . $disk_no . "|awk -F\  '/  5 /||/  9 /||/197 /||/  1 /||/  7 /||/194 /||/195 /||/184 /{printf(\"ATTR:%d VALUE:%d \\n \",$1,$10)}'";
  $smartinfo = shell_exec($strExec);
  preg_match_all("/ATTR:(\w+)\s* VALUE:(\w+)\s*/",$smartinfo,$smart_info);

  for($i=0;$i<count($smart_info[1]);$i++){
    ${"ATTR" . $smart_info[1][$i]}=$smart_info[2][$i];
  }
  
  if(file_exists("/syslog/smartdump.sd" . $disk_no)){
    $strExec="cat /syslog/smartdump.sd" . $disk_no . "|awk -F\  '/  5 /||/  9 /||/197 /||/  1 /||/  7 /||/194 /||/195 /||/184 /{printf(\"ATTR:%d_old VALUE:%d \\n \",$1,$10)}'";
    $smartinfo_old = shell_exec($strExec);
    preg_match_all("/ATTR:(\w+)\s* VALUE:(\w+)\s*/",$smartinfo_old,$smart_info_old);

    for($i=0;$i<count($smart_info_old[1]);$i++){
      ${"ATTR" . $smart_info_old[1][$i]}=$smart_info_old[2][$i];
    }
  }
  
  $strExec="/usr/sbin/smartctl -A -d $smartdev /dev/sd" . $disk_no . " > /syslog/smartdump.sd" . $disk_no;
  shell_exec($strExec);

  $strExec="/usr/sbin/smartctl -l error -d $smartdev /dev/sd" . $disk_no . "|awk  '/Error: /{i=i+1;FS=\"Error: \";print $2}'";
  $smartinfo = shell_exec($strExec);
  $smartlog=explode("\n",$smartinfo);
  $ologcount=count($smartlog);
  $logcount=0;
  
  for($i=0;$i<$ologcount;$i++){
    if ($smartlog[$i]!="") {
    //echo "smartlog[" . $i . "]=" . $smartlog[$i] . "<br>";
      $logcount++;
    }
  }
}else{
  $strExec="/usr/sbin/smartctl -A -d scsi /dev/sd". $disk_no ."|awk -F '=' '/  number of hours powered up/{print $2}'";
  $ATTR9=trim(shell_exec($strExec)); 

  $strExec="/usr/sbin/smartctl -A -d scsi /dev/sd". $disk_no ."|awk -F ':' '/Current Drive Temperature/{print $2}'";
  $ATTR194=trim(shell_exec($strExec)); 
}  
//##############################################
//#  Get Disk Information
//##############################################
$disk_info=$disk_class->getINFO();
$model='N/A';
foreach($disk_info as $disk_list){
  foreach($disk_list as $info){
    if($info[4]==$disk_no){
      $model=$info[1];
    }
  }
}
//##############################################

$smart_action=trim($_POST["smart_status"]);
if (NAS_DB_KEY == '1'){
	$total_tray=trim(shell_exec("/img/bin/check_service.sh total_tray"));
}else{
	$total_tray=trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
}
$strExec="/usr/sbin/smartctl -i -d $smartdev /dev/sd" . $disk_no . "|awk -F':' '/Serial Number/{print substr($2,5,length($2))}'";
$HD_serial=trim(shell_exec($strExec));

if($HD_serial == "[No Information Found]" || $HD_serial == ""){
      $test_button=$words["test_status"];
      $smart_status=0;
      $smart_result="N/A";
      $smart_test_time="--";
      $test_type="short";
}else{  
  $smart_list=file("/var/tmp/HD/smart_".$HD_serial);

  for($t=0;$t<sizeof($smart_list);$t++)
    $smart_test[$t]=explode("=",trim($smart_list[$t]));
    
  if(trim($smart_test[0][1]) == "1"){
    $smart_result=sprintf($words["progress"],$smart_test[2][1],"%");
    $test_button=$words["stop_test_status"];
    $smart_test_time=$smart_test[4][1];
    $smart_status=1;
    $test_type=$smart_test[1][1];  
  }else{
    $test_button=$words["test_status"];
    $smart_status=0;
    
    if(trim($smart_test[0][1]) == ""){ //status
      $smart_result=$words["disk_no_scan"];
      $smart_test_time="--";     
      $test_type="short";   
    }else{
      $smart_test_time=$smart_test[4][1];
      $test_type=$smart_test[1][1]; 
      if(trim($smart_test[0][1]) == "0"){
        if(trim($smart_test[3][1]) == "PASSED"){ //result
          $smart_result = sprintf($words["result_normal"],$smart_test[1][1]);
        }else{
          $smart_result = sprintf($words["result_fail"],$smart_test[1][1]);
        }
      }else{
        $smart_result=$words["abort_test"];       
      }
    } 
  }
}

die(json_encode(array('tray_no'=>$tray_no,
                      'model'=>$model,
                      'ATTR9'=>($ATTR9=="")?"N/A":$ATTR9." ".$gwords['hours'],
                      'ATTR194'=>($ATTR194=="")?"N/A":$ATTR194,
                      'ATTR5'=>($ATTR5=="")?"N/A":$ATTR5,
                      'ATTR197'=>($ATTR197=="")?"N/A":$ATTR197,
                      'ATTR184'=>($ATTR184=="")?"N/A":$ATTR184,
                      'ATTR9_old'=>($ATTR9_old=="")?"N/A":$ATTR9_old." Hours",
                      'ATTR194_old'=>($ATTR194_old=="")?"N/A":$ATTR194_old,
                      'ATTR5_old'=>($ATTR5_old=="")?"N/A":$ATTR5_old,
                      'ATTR197_old'=>($ATTR197_old=="")?"N/A":$ATTR197_old,
                      'ATTR184_old'=>($ATTR184_old=="")?"N/A":$ATTR184_old,
                      'smart_result'=>$smart_result,
                      'smart_test_time'=>$smart_test_time,
                      'smart_status'=>$smart_status,
                      'test_button'=>$test_button,
                      'test_type'=>$test_type,
                      'diskno'=>$disk_no,
                      'disk_type'=>$disk_type)));



?>
