<?
class WIRELESS{
	var $wireless_content = array();
	var $info_content = array();
	var $conf_content = array();
	var $dev="eth2";
	var $global_dev="eth0";
	var $iwlist="/sbin/iwlist";
	var $iwconfig="/sbin/iwconfig";
	var $ifconfig="/sbin/ifconfig";
	var $wireless_list="/tmp/wireless_list.log";
	var $wireless_info="/tmp/wireless_info.log";
	var $database="/etc/cfg/wireless.db";
	var $scanlist="";
	function GetList($rescan="0"){
		if (NAS_DB_KEY == 2)
		    $this->dev = "wth0";
        
        $strExec="ifconfig | grep ".$this->dev;
		$dev_exist=trim(shell_exec($strExec));
		if($dev_exist==""){
			$strExec="ifconfig ".$this->dev." up";
			shell_exec($strExec);
		}
		if($rescan=="1" || !file_exists($this->wireless_list)){
			$strExec="rm -f ".$this->wireless_list;
			shell_exec($strExec);
			$strExec=$this->iwlist." ".$this->dev." scanning > ".$this->wireless_list;
			shell_exec($strExec);
		}
		$this->scanlist=file($this->wireless_list);
		//echo "<pre>";
		//print_r($this->scanlist);
		$count=count($this->scanlist);
		$index="0";
		for($c=0;$c<=$count;$c++){
			if($this->scanlist[$c]!=""){
				if(preg_match("/Address:/",$this->scanlist[$c])){
					$index++;
					$tmp=explode(" ",$this->scanlist[$c]);
					$wireless_content[$index][Address]=trim($tmp[14]);
				}elseif(preg_match("/ESSID:/",$this->scanlist[$c])){
					$essid=trim($this->scanlist[$c]);
					$essid=substr($essid,7,strlen($essid)-8);
					if($essid=="<hidden>"){
						$essid="";
					}
					$wireless_content[$index][ESSID]=$essid;
				}elseif(preg_match("/Protocol:/",$this->scanlist[$c])){
					$protocol=trim($this->scanlist[$c]);
					$protocol=substr($protocol,9,strlen($protocol)-9);
					$protocol_array=explode(" ",$protocol);
					$protocol=trim($protocol_array[1]);
					$wireless_content[$index][Protocol]=$protocol;
				}elseif(preg_match("/Mode:/",$this->scanlist[$c])){
					$mode=trim($this->scanlist[$c]);
					$mode=substr($mode,5,strlen($mode)-5);
					$wireless_content[$index][Mode]=$mode;
				}elseif(preg_match("/Mode:/",$this->scanlist[$c])){
					$mode=trim($this->scanlist[$c]);
					$mode=substr($mode,5,strlen($mode)-5);
					$wireless_content[$index][Mode]=$mode;
				}elseif(preg_match("/Frequency:/",$this->scanlist[$c])){
					$tmp=explode(" ",$this->scanlist[$c]);
					$freq=trim($tmp[20]);
					$freq=substr($freq,10,strlen($freq)-10);
					$channel=trim($tmp[23]);
					$channel=substr($channel,0,strlen($channel)-1);
					$wireless_content[$index][Freq]=$freq;
					$wireless_content[$index][Channel]=$channel;
				}elseif(preg_match("/Encryption key:/",$this->scanlist[$c])){
					$enc=trim($this->scanlist[$c]);
					$enc=substr($enc,15,strlen($enc)-15);
					$wireless_content[$index][ENC]=$enc;
				}elseif(preg_match("/Mb\/s;/",$this->scanlist[$c])){
					if(preg_match("/Bit Rates:/",$this->scanlist[$c])){
						$rate="";
						$rate=trim($this->scanlist[$c]);
						$rate=substr($rate,10,strlen($rate)-10);
					}else{
						$rate.="; ".trim($this->scanlist[$c]);
					}
				}elseif(preg_match("/Quality/",$this->scanlist[$c])){
					$rate=explode("; ",$rate);
					$rate[]=usort($rate);
					foreach($rate as $value){
						if($value!=""){
							$wireless_content[$index][Rate][].=substr($value,0,strlen($value)-5);
						}
					}
					$tmp=explode(" ",$this->scanlist[$c]);
					$quality=trim($tmp[20]);
					$quality=substr($quality,8,strlen($quality)-8);
					$signal=trim($tmp[23]);
					$signal=substr($signal,6,strlen($signal)-6);
					$wireless_content[$index][Quality]=$quality;
					$wireless_content[$index][Signal]=$signal;
				}elseif(preg_match("/IE: /",$this->scanlist[$c])){
					if(preg_match("/WPA /",$this->scanlist[$c])){
						$ie_title="WPA";
					}elseif(preg_match("/WPA2 /",$this->scanlist[$c])){
						$ie_title="WPA2";
					}
				}elseif(preg_match("/Group Cipher :/",$this->scanlist[$c])){
					$group=trim($this->scanlist[$c]);
					$group=substr($group,15,strlen($group)-15);
					$wireless_content[$index][$ie_title][Group]=$group;
				}elseif(preg_match("/Pairwise Ciphers /",$this->scanlist[$c])){
					$pairwise=trim($this->scanlist[$c]);
					$pairwise_array=explode(":",$pairwise);
					$pairwise=trim($pairwise_array[1]);
					$wireless_content[$index][$ie_title][Pairwise]=$pairwise;
				}elseif(preg_match("/Authentication Suites /",$this->scanlist[$c])){
					$auth=trim($this->scanlist[$c]);
					$auth_array=explode(":",$auth);
					$auth=trim($auth_array[1]);
					$wireless_content[$index][$ie_title][Auth_Suite]=$auth;
				}
			}
		}
		return $wireless_content;
	}
	
	function GetInfo(){
		if (NAS_DB_KEY == 2)
		    $this->dev = "wth0";

		require_once(INCLUDE_ROOT."sqlitedb.class.php");
		//$database="/etc/cfg/wireless.db";
    $db_tool=new sqlitedb($this->database,"cwireless");
		//$db_tool=new db_tool2();
		$strExec="rm -f ".$this->wireless_info;
		shell_exec($strExec);
		$strExec=$this->iwconfig." ".$this->dev." > ".$this->wireless_info;
		shell_exec($strExec);
	
		$strExec=$this->ifconfig." ".$this->global_dev." | awk '/HWaddr/{print \$5}'";
		$eth0_mac=trim(shell_exec($strExec));
		$info_content["info_eth0_mac"]=$eth0_mac;
		$strExec=$this->ifconfig." ".$this->dev." | awk '/HWaddr/{print \$5}'";
		$eth2_mac=trim(shell_exec($strExec));
		$info_content["info_eth2_mac"]=$eth2_mac;
		
		if($eth0_mac!=$eth2_mac){
			$essid_info="N/A";
			$info_content["info_ssid"]=$essid_info;
			return $info_content;
		}
		//$strExec=$this->iwconfig." ".$this->dev." | awk '/ESSID:/{if(NR==1){print substr(\$4,8,length(\$4)-8)}else{print \"N/A\"}}'";
		//$info_content["info_ssid"]=trim(shell_exec($strExec));
		$strExec="cat ".$this->wireless_info." | awk '{if(NR==1){print \$3}}'";
		$info_content["info_protocol"]=trim(shell_exec($strExec));
		
		$strExec="cat ".$this->wireless_info." | awk -F':' '/ESSID:/{if(NR==1){print \$2}else{print \"N/A\"}}'";
		$essid_info=trim(shell_exec($strExec));
		if(preg_match("/off\/any/",$essid_info)){
			$essid_info="N/A";
		}elseif($essid_info==""){
			$essid_info="N/A";
		}else{
			$strExec="cat ".$this->wireless_info." | awk -F'\"' '/ESSID:/{if(NR==1){print \$2}}'";
			$essid_info=trim(shell_exec($strExec));
		}
		$info_content["info_ssid"]=$essid_info;
		
		$strExec=$this->iwlist." ".$this->dev." channel | awk '/Current /{print substr(\$5,0,length(\$5)-1)}'";
		$strExec=$this->iwlist." ".$this->dev." channel | awk '/Current /{printf(\"%s,%s\",substr(\$2,11,length(\$2)-10),substr(\$5,0,length(\$5)-1))}'";
		$channel_info=explode(",",shell_exec($strExec));
		$info_content["info_freq"]=trim($channel_info[0]);
		$info_content["info_channel"]=trim($channel_info[1]);
		
		$strExec=$this->iwconfig." ".$this->dev." | awk '/Access Point:/{if(NR==2){print \$6}else{print \"N/A\"}}'";
		$bssid_info=trim(shell_exec($strExec));
		if(preg_match("/Invalid/",$bssid_info)){
			$bssid_info="N/A";
		}
		$info_content["info_bssid"]=$bssid_info;
		
		$strExec=$this->iwconfig." ".$this->dev." | awk '/Bit Rate/{if(NR==3){print substr(\$2,6,length(\$2)-5)}else{print \"N/A\"}}'";
		$speed_info=trim(shell_exec($strExec));
		$info_content["info_speed"]=$speed_info;
		
		//$strExec=$this->iwconfig." ".$this->dev." | awk -F':' '/Encryption key:/{if(NR==4){print \$2}else{print \"N/A\"}}'";
		//$info_content["info_enc"]=trim(shell_exec($strExec));
		//$db_tool->db_connect($this->database);
		//$auth_info=$db_tool->db_get_single_value("cwireless","v","where k='auth'");
		$auth_info1=$db_tool->runSQL("select v from cwireless where k='auth'");
		$db_tool->db_close();
    $auth_info=$auth_info1[0];
		if($auth_info=="open_system"){
			$info_content["info_enc"]="";
		}elseif($auth_info=="share_key"){
			$info_content["info_enc"]="WEP";
		}else{
			$auth_info=strtoupper(substr($auth_info,0,strlen($auth_info)-4));
			$info_content["info_enc"]=$auth_info;
		}
		
		$strExec=$this->ifconfig." ".$this->global_dev." | awk '/inet addr:/&&/Mask:/{if(NR==2){printf(\"%s,%s\",substr(\$2,6,length(\$2)-5),substr(\$4,6,length(\$4)-5))}else{print \"N/A\"}}'";
		//$strExec=$this->ifconfig." eth1 | awk '/inet addr:/&&/Mask:/{if(NR==2){printf(\"%s,%s\",substr(\$2,6,length(\$2)-5),substr(\$4,6,length(\$4)-5))}else{print \"N/A\"}}'";
		$ip_mask=explode(",",trim(shell_exec($strExec)));
		$info_content["info_ip"]=trim($ip_mask[0]);
		$info_content["info_netmask"]=trim($ip_mask[1]);
		
		//$strExec=$this->iwconfig." ".$this->dev." | awk '/Link Quality/&&/Signal level/{if(NR==5){printf(\"%s,%s\",substr(\$2,9,length(\$2)-8),substr(\$4,7,length(\$4)-6))}else{print \"0,0\"}}'";
        
        //cancel the limit NR=5, because NR=6 is in N0503  
        $strExec=$this->iwconfig." ".$this->dev." | awk '/Link Quality/&&/Signal level/{printf(\"%s,%s\",substr(\$2,9,length(\$2)-8),substr(\$4,7,length(\$4)-6))}'";
        if (trim(shell_exec($strExec)) == "")
            $signal_quality=explode(",","0,0");
        else
            $signal_quality=explode(",",trim(shell_exec($strExec)));
		
		$signal_info=explode("/",$signal_quality[1]);
		if($signal_info[0]==""){
			$signal_info[0]="0";
		}
		$info_content["info_signal"]=$signal_info[0]." %";
		
		$quality_info=explode("/",$signal_quality[0]);
		if($quality_info[0]==""){
			$quality_info[0]="0";
		}
		$info_content["info_quality"]=$quality_info[0]." %";
		
		if($info_content["info_ip"]!=""){
			$strExec="route -n | awk '/^0.0.0.0/&&/".$this->global_dev."/{print \$2}'";
			$gateway_info=trim(shell_exec($strExec));
			$gateway_info=explode("\n",$gateway_info);
			$info_content["info_gateway"]=$gateway_info;
		}
		//echo "<pre>";
		//print_r($info_content);
		return $info_content;
	}
	
	function GetConf(){
	  require_once(INCLUDE_ROOT."sqlitedb.class.php");
		//require_once("/img/inc/db.class.php");
		//$db_tool=new db_tool2();
		//$db_tool->db_connect($this->database);
		//$database="/etc/cfg/wireless.db";
    $db_tool=new sqlitedb($this->database,"cwireless");
		$conf_array=$db_tool->runSQLAry("select * from cwireless");
		$db_tool->db_close();
		foreach($conf_array as $v){
			if($v!=""){
				$conf_content["conf_".$v[k]]=$v[v];
			}
		}
		return $conf_content;
	}
}
?>
