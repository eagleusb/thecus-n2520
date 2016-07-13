<?php 

function check_ups(){  
	require_once(INCLUDE_ROOT.'sqlitedb.class.php'); 
	require_once(INCLUDE_ROOT.'function.php');
	get_sysconf();   
	$sys_ups_rs232=$sysconf["ups_rs232"]; 
	if($sys_ups_rs232=="1" && $sys_ups_rs232!=""){  
	      $strExec="/img/bin/check_service.sh ups_rs232";
	      $ups_rs232=trim(shell_exec($strExec)); 
	      $upscpath="/usr/bin/upsc"; 
	      $db=new sqlitedb();  
	      $ups_use=$db->getvar("ups_use","0"); 
	      $ups_brand=$db->getvar("ups_brand","Powercom");
	      $ups_model=$db->getvar("ups_model","BNT-1000AP");
	      $ups_finaldelay=$db->getvar("ups_finaldelay","5");
	      $ups_usems=$db->getvar("ups_usems","0");
	      $ups_ip=$db->getvar("ups_ip","");
	      $db->db_close(); 
	      
	      if($ups_rs232 != "1"){  
	        //List USB UPS Only
	        $lines=explode("\n",shell_exec("cat /usr/share/driver.list|grep -v ^\"#\"| awk -F '\"' '{if ($2!=\"\") print $2\"|\"$4\"|\"$6\"|\"$8}' | awk '/usbhid-ups/ || /megatec_usb/ || /energizerups/ || /bcmxcp_usb/ || /tripplite_usb/'"));
	      }else{
	        //List USB and RS232 UPS
	        $lines=explode("\n",shell_exec("cat /usr/share/driver.list|grep -v ^\"#\"| awk -F '\"' '{if ($2!=\"\") print $2\"|\"$4\"|\"$6\"|\"$8}'"));
	      }
	      
	      //replace byte-order mark (BOM) (0xEF 0xBB 0xBF)
	      $replace=chr(239).chr(187).chr(191);
	      $lines[0]=str_replace($replace,"",$lines[0]); 
	       
	      $currkey="";   
	      $ups_driver=""; 
	      foreach ($lines as $line) {
	        $aryline=explode("|",$line);
	        if (trim($aryline[0])!="") {
	          $currkey=trim($aryline[0]); 
	          $modelvalue=trim(trim($aryline[1]) . " " . trim($aryline[2]));  
	          if (($ups_brand==$currkey) && ($modelvalue==$ups_model)) {
	            $ups_option=trim($aryline[3]);
	            $ary_upsoption=explode(" ",$ups_option);
	            $ups_driver=trim($ary_upsoption[0]);
	          }
	        }
	      } 
	      $battery_use=-1;
	      if ($ups_use=="1") { 
	        if ($ups_driver!="") { 
	          $battery_use=0;
	          if ($ups_usems == "1")
	           $strExec=$upscpath . " " . $ups_driver . "@" . $ups_ip;
	          else
	           $strExec=$upscpath . " " . $ups_driver . "@localhost";
                 
	          $exeResult=shell_exec($strExec);
	          $ary_result=explode("\n",$exeResult);
	          foreach ($ary_result as $item) {
	            $ary_item=explode(":",$item);
	            $varkey=trim($ary_item[0]);
	            if ($varkey=="battery.charge") {
	              $battery_use=$ary_item[1];
	            }  
	          }
	        } 
	        if($battery_use <0 || $battery_use < ($ups_finaldelay+5)){
	          $ups='off'; 
	        }else{
	          $ups='on'; 
	        }
	      }else{
	        $ups='none';
	      }
	}else{
	  $ups='none'; 
	} 
	return $ups;
}



/****************************************************************
  get icon
  @param string $status,  -1:unavailable | 0:fail | 1:success
  @return string
*****************************************************************/
function getStatus($status=-1){ 
  switch($status){
    case '0':
      $flag = 'off'; break;
    case '1':
      $flag = 'on'; break;
    default:
      $flag = 'none';
  }
  return $flag;
}

/********************************************************
  check_raid_rss
  @Return: RAID Healthy  on success return 1, 
           and 0 if RAID is Damaged/Degraded.  
*********************************************************/
function check_raid_rss(){
    exec("cat /var/tmp/raid*/rss ",$result,$req);  
    if($req=="0"){ 
	    foreach($result as $v){
	      if($v=='Damaged' || $v=='Degraded'){
	         return 0; 
	      }
	    }
	    return 1;
    }else{
    	return -1;
    }
    
}

/********************************************************
  check_disk
  @Return: check /tmp/TRAY* on fail if has 'Error' string, return 0,
           otherwise return 1 on success.
*********************************************************/
function check_disk(){
    $result = shell_exec("cat /tmp/TRAY* 2>/dev/null |awk '{if($2==\"Error\"){print 0}}'");
    $row = explode("\n",$result);
    foreach($row as $v){
      if($v=='0')
         return '0';
      }
    return '1';
}

/******************************************
          open file
  @param string $file
  @param string $type 
  @return numeric , then call getStatus()
******************************************/
function openfile($file,$type=''){
  $filename = '/var/tmp/'.$file; 
  $handle = fopen($filename, "r");
  if($handle){
     if($type=='raid'){
        $flag = check_raid_rss();
     }else if($type=='disk'){
        $flag = check_disk();
     }else{
        $flag = fread($handle, filesize($filename));
     }
  }else{
     $flag=-1;
  }
  fclose($handle);
  return trim($flag);
}
?>
