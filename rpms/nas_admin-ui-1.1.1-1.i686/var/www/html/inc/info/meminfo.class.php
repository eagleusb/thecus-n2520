<?php
//'provide memory information'

include_once("INFO.base.php");
class MEMINFO extends INFO{
  var $condition = array('MemTotal','MemFree');
    
	function parse(){
	  //$this->content["MemorySize"]=515136;
	  $f = file("/proc/meminfo");
	  foreach ($f as $key => $value) {	
		  $date=explode(":",$f[intval($key)]);
		  foreach($this->condition as $k=>$v){
			  if ($this->filter($date[0]) == $v ){
			    $this->content[$v]=intval($this->filter($date[1]));
			  }
			  $mem_usage=$this->content["MemTotal"] - $this->content["MemFree"];
		    $this->content["MemoryUsage"]=$mem_usage;
		    $this->content["MemorySize"]=$this->content["MemTotal"];
		  }
	  }
	}
	
	function parse_cpuinfo(){
	  $f = file("/proc/cpuinfo");
	  $arythecus=array();
	  foreach ($f as $key => $value) {	
		  $date=explode(":",$f[intval($key)]);
		  $arythecus[trim($date[0])]=$date[1];
		  //echo $date[0] . "=" . $date[1] . "<br>";
	  }
	  return $arythecus;
	}
	
	function parse_thecusio(){
	  //$this->content["MemorySize"]=515136;
	  $f = file("/proc/thecus_io");
	  $arythecus=array();
	  foreach ($f as $key => $value) {	
		  $date=explode(":",$f[intval($key)]);
		  $arythecus[$date[0]]=$date[1];
		  //echo $date[0] . "=" . $date[1] . "<br>";
	  }
	  
	  //for get fan information of n4100pro from /proc/hwm.(fan 1)
	  //for get fan information of n7700 from /proc/thecus_hwm.(fan 1,2,3)
	  $modelname=trim(shell_exec("awk '/^MODELNAME/{print $2}' /proc/thecus_io"));
		switch ($modelname) {
		case N0503 :
            $rpm=trim(shell_exec("cat /proc/thecus_hwm | grep 'FAN 2 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
            $arythecus["FAN 2 RPM"]=$rpm;
            break;
		case N4100PRO :
			$rpm=trim(shell_exec("cat /proc/hwm | grep 'FAN 1 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
    	$arythecus["FAN 2 RPM"]=$rpm;
    	break;
    case N7700 :
	$rpm=trim(shell_exec("cat /proc/thecus_hwm | grep 'FAN 1 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
    	$arythecus["FAN 1 RPM"]=$rpm;
    	if ($mbtype == 504 || $mbtype == 505){
	    $rpm=trim(shell_exec("cat /proc/hwm | grep 'FAN 1 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
       	    $arythecus["FAN 2 RPM"]=$rpm;
	    $rpm=trim(shell_exec("cat /proc/hwm | grep 'FAN 2 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
    	    $arythecus["FAN 3 RPM"]=$rpm;
	    $rpm=trim(shell_exec("cat /proc/hwm | grep 'FAN 3 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
       	    $arythecus["FAN 4 RPM"]=$rpm;
	    $rpm=trim(shell_exec("cat /proc/hwm | grep 'FAN 4 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
    	    $arythecus["FAN 5 RPM"]=$rpm;
    	}else{
	    $rpm=trim(shell_exec("cat /proc/thecus_hwm | grep 'FAN 2 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
       	    $arythecus["FAN 2 RPM"]=$rpm;
	    $rpm=trim(shell_exec("cat /proc/thecus_hwm | grep 'FAN 3 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
    	    $arythecus["FAN 3 RPM"]=$rpm;
    	}
    	break;    	    	
		default:
                $arch=trim(shell_exec("/img/bin/check_service.sh arch"));
      switch ($arch) {
	case oxnas :
          $rpm=trim(shell_exec("cat /proc/hwm | grep 'FAN 1 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
          $arythecus["FAN 2 RPM"]=$rpm;
          break;
        default :
          $rpm=trim(shell_exec("cat /proc/hwm | grep 'CPU_FAN RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
          $arythecus["FAN 1 RPM"]=$rpm;
          $rpm=trim(shell_exec("cat /proc/hwm | grep 'HDD_FAN1 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
          $arythecus["FAN 2 RPM"]=$rpm;
          $rpm=trim(shell_exec("cat /proc/hwm | grep 'HDD_FAN2 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
          $arythecus["FAN 3 RPM"]=$rpm;
          $rpm=trim(shell_exec("cat /proc/hwm | grep 'HDD_FAN3 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
          $arythecus["FAN 4 RPM"]=$rpm;
          $rpm=trim(shell_exec("cat /proc/hwm | grep 'HDD_FAN4 RPM:' | sed -e 's/^.*RPM: //' | cut -d' ' -f1"));
          $arythecus["FAN 5 RPM"]=$rpm;

          $temp=trim(shell_exec("cat /proc/hwm | grep 'CPU_TEMP:' | sed -e 's/^.*: //' | cut -d' ' -f1"));
          $arythecus["CPU TEMP 1"]=$temp;
          $temp=trim(shell_exec("cat /proc/hwm | grep 'SAS_TEMP:' | sed -e 's/^.*: //' | cut -d' ' -f1"));
          $arythecus["TEMP 1"]=$temp;
          $temp=trim(shell_exec("cat /proc/hwm | grep 'SYS_TEMP:' | sed -e 's/^.*: //' | cut -d' ' -f1"));
          $arythecus["TEMP 2"]=$temp;
          $temp=trim(shell_exec("cat /proc/hwm | grep 'HDD_TEMP1:' | sed -e 's/^.*: //' | cut -d' ' -f1"));
          $arythecus["TEMP 3"]=$temp;
          $temp=trim(shell_exec("cat /proc/hwm | grep 'HDD_TEMP2:' | sed -e 's/^.*: //' | cut -d' ' -f1"));
          $arythecus["TEMP 4"]=$temp;
          break;
      }
    	break;
		}

	  return $arythecus;
	}
	
	function service_status(){
		$chkservice=array("afpd" => "httpd_nic1_afpd","nfsd" => "httpd_nic1_nfs", "smbd" => "httpd_nic1_cifs","pure-ftpd" => "ftp_ftpd","opentftpd" => "tftpd_enabled","nsync" => "nsync_target_enable","upnpd" => "httpd_nic1_upnp","snmpd" => "snmp_enabled","ncpserv" => "netware_enabled","mediaserver" => "DLNA_server","rsync"=>"nsync_target_rsync_enable");
		$allservice=shell_exec("ps");
		$db=new sqlitedb();
	  $aryservice=array();
	  
	  foreach ($chkservice as $key => $value) {	
			if(preg_match("/" . $key . "/",$allservice)){
				$service_work="1";
			} else {
				$service_work="0";
			}
            
			$service_value = $db->getvar("$value","0");
			
			$aryservice[$key]=array("now_status"=>$service_work,"db_status"=>$service_value);
		}
		if (!(shell_exec("pidof pure-ftpd|wc -w"))){
			$aryservice["pure-ftpd"]["now_status"]="0";
		}
      unset($db);
	  return $aryservice;
	}

}
/* test main 
$x = new MEMINFO();
print_r($x->getINFO());
*/
?>
