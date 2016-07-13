<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');
//require_once("/etc/www/htdocs/setlang/lang.html");

$strExec="/img/bin/check_service.sh ups_rs232";
$ups_rs232=trim(shell_exec($strExec));

$words= $session->PageCode("ups");
$gwords= $session->PageCode("global");
// Kevin 2006/09/26 Ups Config
$upscpath="/usr/bin/upsc";

$db=new sqlitedb();

//load UPS default value
$ups_use=$db->getvar("ups_use","0");
$ups_usems=$db->getvar("ups_usems","0");
$ups_ip=$db->getvar("ups_ip","");
$ups_brand=$db->getvar("ups_brand","Powercom");
$ups_model=$db->getvar("ups_model","BNT-1000AP");
$ups_pollfreq=$db->getvar("ups_pollfreq","5");
$ups_pollfreqalert=$db->getvar("ups_pollfreqalert","20");
$ups_finaldelay=$db->getvar("ups_finaldelay","5");
unset($db);

if(!$validate->ip_address($ups_ip)){
   if($validate->ipv6_address($ups_ip)){
       $ups_ip="[$ups_ip]";
       $ip_type="1"; //ipv6
   }
}else{
   $ip_type="2";
}

//$driver_map="/etc/ups/driver.map";  
//$lines=file($driver_map);
if($ups_rs232 != "1"){  
  //List USB UPS Only
    $lines=explode("\n",shell_exec("cat /usr/share/nut/driver.list|grep -vE '^(#|.IPMI.)'| awk -F '\"' '{if ($2!=\"\") print $2\"|\"$8\"|\"$10\"|\"$12}' | awk '/usbhid-ups/ || /megatec_usb/ || /energizerups/ || /bcmxcp_usb/ || /tripplite_usb/'"));
}else{
  //List USB and RS232 UPS
    $lines=explode("\n",shell_exec("cat /usr/share/nut/driver.list|grep -vE '^(#|.IPMI.)'| awk -F '\"' '{if ($2!=\"\") print $2\"|\"$8\"|\"$10\"|\"$12}'"));
}

//replace byte-order mark (BOM) (0xEF 0xBB 0xBF)
$replace=chr(239).chr(187).chr(191);
$lines[0]=str_replace($replace,"",$lines[0]);

//  $ary_model=array();
//  $ary_mfc=array();
$lastkey="";
$currkey="";
$i=0;
$j=0;
$k=0;
$ups_brand_index=0;
$ups_model_index=0;
$ups_driver="";
$count=0;
$mdata=array();
$model_data=array();
$ups_brand_index=0;
$ups_real_model="";
$ups_real_brand="";

foreach ($lines as $line) {
  $aryline=explode("|",$line);
  if (trim($aryline[0])!="") {
    $currkey=trim($aryline[0]);
    if ($currkey!=$lastkey) {
      $lastkey=$currkey;
      $count++;
      array_push($mdata,array('id'=>$count,'info'=>$currkey));
    }
    $modelvalue=trim(trim($aryline[1]) . " " . trim($aryline[2]));
    $model_data[$count][]=array('info'=>$modelvalue,'driver'=> trim($aryline[3]));

    if ($currkey==$ups_brand) {
      $ups_brand_index=$count;
    }

    if (($ups_brand==$currkey) && ($modelvalue==$ups_model)) {
      $ups_real_model=$modelvalue;
      $ups_option=trim($aryline[3]);
      $ary_upsoption=explode(" ",$ups_option);
      $ups_driver=trim($ary_upsoption[0]);
    }
  }
}

if($ups_brand_index!=0){
  $ups_real_brand=$mdata[$ups_brand_index-1]["info"];
}else{
  $ups_real_brand=$mdata[$ups_brand_index]["info"];
} 
 
if(trim($ups_real_model) == ""){
  $ups_real_model=$model_data[$ups_brand_index][0]["info"];
}

if ($ups_use=="1") {
  if ($ups_driver!="") {
    $battery_use="";
     if ($ups_usems=="1") {
       $strExec=$upscpath . " " . $ups_driver . "@" . $ups_ip;
     }else{
       $strExec=$upscpath . " " . $ups_driver . "@localhost";
     }
      
    $conn_flag="fail";
    $conn_try_times_max=3;
    $conn_try_times=0;
    while($conn_flag=="fail"){
      $exeResult=shell_exec($strExec);
      if(  (preg_match("/ups.status: WAIT/",$exeResult) == 0)
        && (preg_match("/Error: Driver not connected/",$exeResult) == 0)
        && (preg_match("/Error: Data stale/",$exeResult) == 0) 
        && (preg_match("/Error: Connection failure: Connection refused/",$exeResult) == 0)
        && (preg_match("/^$/",$exeResult) == 0)
        ){
        $conn_flag="true";
      }
      if( ($conn_flag=="true") || ($conn_try_times++ >= $conn_try_times_max) ){
        break;
      }
      shell_exec("sleep 1");
    }

    
    $ary_result=explode("\n",$exeResult);
    foreach ($ary_result as $item) {
      $ary_item=explode(":",$item);
      $varkey=trim($ary_item[0]);
      if ($varkey=="battery.charge") {
        $battery_use=sprintf("%.1f",$ary_item[1]) . "%";
      }
      if ($varkey=="ups.status") {
        $aryupsstat=explode(" ",trim($ary_item[1]));
        foreach ($aryupsstat as $upsstat) {
          $conn_stat=trim($upsstat);
          if ($conn_stat=="OB") {
            $power_stat=$words["ups_batt_stat_batt"]; 
            break;
          }
          if ($conn_stat=="OL") {
            $power_stat=$words["ups_batt_stat_ac"];
            break;
          }
        }
      }
      
    }
  }
  if ($battery_use=="") $battery_use=$gwords['na'];
  if ($power_stat=="") $power_stat=$gwords['na'];
} else {
  $battery_use=$gwords['na'];
  $power_stat=$gwords['na'];
}

if($_GET['update']=="1"){
die(json_encode(array('battery_use'=>$battery_use,
                      'power_stat'=>$power_stat)
               )
   );
exit;  
}

if($ip_type=="1"){
   $db=new sqlitedb();
   $ups_ip=$db->getvar("ups_ip","");
   unset($db);
}

/*$lastkey="";
$currkey="";
$nowpt=0;
$mlength=0;
$i=0;
$mdata=array();
$model_data=array();
$ups_brand_index=0;
foreach ($ary_model as $model) {
  $currkey=$model["mfcname"];
    
  if ($currkey!=$lastkey) {  
    $i++;
    array_push($mdata,array('id'=>$i,'info'=>$model["mfcname"]));
    $lastkey=$currkey;    
  } 
  $model_data[$i][]=array('info'=>$model["model"]." ".$model["extra_model"],'driver'=> trim($model["driver"]));
  
  if($currkey==$ups_brand) $ups_brand_index=$i;  
}
*/

//$tpl->assign('ary_model',json_encode($ary_model));
$tpl->assign('mdata',json_encode($mdata));
$tpl->assign('model_data',json_encode($model_data));
$tpl->assign('model_first_data',json_encode($model_data[$ups_brand_index]));
$tpl->assign('words',$words);
$tpl->assign('battery_use',$battery_use);
$tpl->assign('power_stat',$power_stat);
//$tpl->assign('ary_mfc',$ary_mfc);
$tpl->assign('ups_brand',$ups_real_brand);
$tpl->assign('ups_model',$ups_real_model);
$tpl->assign('ups_pollfreq',$ups_pollfreq);
$tpl->assign('ups_pollfreqalert',$ups_pollfreqalert);
$tpl->assign('ups_finaldelay',$ups_finaldelay);
$tpl->assign('form_action','setmain.php?fun=setups');
$tpl->assign('mfactory_option',$mfactory_option);
$tpl->assign('ups_use',$ups_use);
$tpl->assign('ups_usems',$ups_usems);
$tpl->assign('ups_ip',$ups_ip);
$tpl->assign('ups_option',$ups_option);
?>
