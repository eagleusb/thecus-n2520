<?php
require_once("smbconf.class.php");
require_once("function.php");
require_once("../../function/conf/localconfig.php");
get_sysconf();

//==========================================
//
//	create a new instance:
//	(string) $nic
//	(array) $_POST
//	$n=new SetNIC($nic,$_POST);
//	$n->Batch();//do set
//
//	Prefix:
//	_cmd_:execute shell command
//	_rc_:edit /etc/cfg/rc config file
//	_conf_:edit config file except rc
//
//==========================================
class SetNIC {

	//==========================================
	//	Below are vars pass by POST
	//==========================================
	var $ip;
	var $netmask;
	var $gateway;
	var $dns;
	var $wins;
	var $jumbo;
	var $domainname;

	//==========================================
	//	Below are vars defining system file path
	//==========================================
    //this $dhclient is for 5200. if NAS_DB_KEY='2', $dhclient is changed for 3800 when _rc_SetBoot
    var $dhclient="/sbin/udhcpc -s /img/bin/udhcpc_script.sh -b -h `hostname` ";
    
    var $ifconfig="/sbin/ifconfig";
	var $route="/sbin/route";
	var $resolv="/etc/resolv.conf";
	var $rc="/etc/cfg/cfg_nic";
	var $pppoe="/usr/sbin/pppoe-start";

	//==========================================
	//	Below define NIC
	//==========================================
	var $nic;
	var $cmd=array("sleep 5");

	//==========================================
	//	Constructor
	//==========================================
	function __construct($nic,$array) {
		if($array['interface']=='1'){ // eth1 only support static ip
			$array['_dhcp'] = 0;
		}
		$this->_SortOut($array);
		$this->nic="eth".$this->eth;
		if($this->dhcp) {
		    $this->_cmd_SetDhcp();
		    return;
		} else {
			//if($this->eth=='0')
		    	//shell_exec("killall udhcpc");
		    $this->_cmd_SetDisable();
		    $this->_cmd_SetStatic();
		}
		return;
	}

	function addCommand($addcmd){
	    $this->cmd[]=$addcmd;
	}

/*	function canChange(){
                system('/sbin/ifconfig eth'.($this->eth==0 ? '1':'0').' > /dev/null 2>&1',$other_ethernet_exist);
                system('/sbin/ifconfig wlan0 > /dev/null 2>&1',$wireless_exist);
		require_once("sqlitedb.class.php");
		$conf=new sqlitedb();
		$other_ethernet_ip=$conf->getvar('nic'.($this->eth==0 ?'2':'1').'_ip');
		$other_ethernet_netmask=$conf->getvar('nic'.($this->eth==0 ?'2':'1').'_netmask');
		$wireless_ip=$conf->getvar('wireless_ip');
		$wireless_netmask=$conf->getvar('wireless_netmask');
		unset($conf);

                if($other_ethernet_exist==0){
                        if($other_ethernet_ip==$this->ip){
                                $this->theSameIPError = 1;
                                return 1;
                        }
                        $ip1 = explode('.',$this->ip);
                        $ip2 = explode('.',$other_ethernet_ip);
                        $netmask1 = explode('.',$this->netmask);
                        $netmask2 = explode('.',$other_ethernet_netmask);
                        $network_id1 = array();
                        $network_id2 = array();
                        for($i=0;$i<4;$i++){
                                $network_id1[] = (int)$ip1[$i] & (int)$netmask1[$i];
                                $network_id2[] = (int)$ip2[$i] & (int)$netmask2[$i];
                        }
                        $network_id1 = implode('.',$network_id1);
                        $network_id2 = implode('.',$network_id2);
                        if($network_id1==$network_id2){
                                $this->theSameSegmentError = 1;
                                return 1;
                        }
                }
                if($wireless_exist==0){
                        if($wireless_ip==$this->ip){
                                $this->theSameIPError = 1;
                                return 1;
                        }
                        $ip1 = explode('.',$this->ip);
                        $ip2 = explode('.',$wireless_ip);
                        $netmask1 = explode('.',$this->netmask);
                        $netmask2 = explode('.',$wireless_netmask);
                        $network_id1 = array();
                        $network_id2 = array();
                        for($i=0;$i<4;$i++){
                                $network_id1[] = (int)$ip1[$i] & (int)$netmask1[$i];
                                $network_id2[] = (int)$ip2[$i] & (int)$netmask2[$i];
                        }
                        $network_id1 = implode('.',$network_id1);
                        $network_id2 = implode('.',$network_id2);
                        if($network_id1==$network_id2){
                                $this->theSameSegmentError = 1;
                                return 1;
                        }
                }

                preg_match('/addr:([^ ]+)/',shell_exec('/sbin/ifconfig eth'.$this->eth),$matches);
                $command=implode(' && ',$this->cmd);
                $command=preg_replace('/(eth\d)/',"\$1:1",$command);
                system('/usr/bin/arping -f -c 1 -w 1 -I eth'.$this->eth." ".$this->ip.' > /dev/null 2>&1',$ip_alive);
                if($ip_alive!=0 || $_SERVER['SERVER_ADDR'] == $this->ip || $this->ip == $matches[1]){
                        $result=shell_exec($command);
                        $this->internalError = ($result == '') ? 0 : 1;
                        preg_match('/eth\d:\d/',$command,$matches);
                        shell_exec($this->ifconfig.' '.$matches[0].' down');
                        return $this->internalError;
                }
                $this->theSameIPError = 1;
                return 1;
        }
*/

function canChange(){
		require_once("sqlitedb.class.php");
		require_once("function.php");
		$conf=new sqlitedb();
		$nic_data=array();
//Wan and Lan
		for($i=0;$i<2;$i++){
				$nic_data[$i]['type']="nic".($i+1);
				system('/sbin/ifconfig eth'.$i.' > /dev/null 2>&1',$nic_data[$i]['exist']);
				$nic_data[$i]['ip']=$conf->getvar('nic'.($i+1).'_ip');
				$nic_data[$i]['mask']=$conf->getvar('nic'.($i+1).'_netmask');
		}
//for Wan default IP
/*		$nic_data[$i]['type']="nic1";
		$nic_data[$i]['exist']=0;
		$nic_data[$i]['ip']="192.168.1.100";
		$nic_data[$i]['mask']="255.255.255.0";		     
		$i++;   */
//for Wan DHCP
		$nic1_dhcp=$conf->getvar('nic1_dhcp');
		if ($nic1_dhcp== "1"){
			$ph = popen("/sbin/ifconfig eth0", "r");
			while (!feof($ph)){
				if (preg_match("/inet addr:([0-9\.]*)  Bcast:([0-9\.]*)  Mask:([0-9\.]*)/i", fgets($ph, 4096), $match)){
					$nic_data[$i]['type']="nic1";
					system('/sbin/ifconfig eth0 > /dev/null 2>&1',$nic_data[$i]['exist']);
					$nic_data[$i]['ip']=$match[1];
					$nic_data[$i]['mask']=$match[3];		     
					$i++;
				}
			}
		}
//Wireless
		$nic_data[$i]['type']="wlan0";
		system('/sbin/ifconfig wlan0 > /dev/null 2>&1',$nic_data[$i]['exist']);
		$nic_data[$i]['ip']=$conf->getvar('wireless_ip');
		$nic_data[$i]['mask']=$conf->getvar('wireless_netmask');
//Ten gb		
		$nickname="geth";
		$tengb_list=get_tengb($nickname);    

		foreach($tengb_list as $key=>$value){
			if($value != ""){
				$i++;
				$nic_data[$i]['type']=$value;
				//system('/sbin/ifconfig '.$value.' > /dev/null 2>&1',$nic_data[$i]['exist']);
				$nic_data[$i]['exist']=0;
				$tmp_ip=$conf->runSQL("select v from conf where k='".$value."_ip'");
				$nic_data[$i]['ip']=$tmp_ip[0];
				$tmp_mask=$conf->runSQL("select v from conf where k='".$value."_netmask'");
				$nic_data[$i]['mask']=$tmp_mask[0];
			}
		}
	
		unset($conf);

		for($j=0; $j<count($nic_data); $j++){
			if(trim($nic_data[$j]['type'])==trim($this->interface) || ( $nic1_dhcp== "1" && $j == 0))
				continue;
			else{ 
				if($nic_data[$j]['exist']==0){
					if(trim($nic_data[$j]['ip'])==trim($this->ip)){
						$this->theSameIPError = 1;
						return 1;
					}
					$ip1 = explode('.',trim($this->ip));
					$ip2 = explode('.',trim($nic_data[$j]['ip']));
					$netmask1 = explode('.',trim($this->netmask));
					$netmask2 = explode('.',trim($nic_data[$j]['mask']));
					$network_id1 = array();
					$network_id2 = array();
					for($i=0;$i<4;$i++){
						$network_id1[] = (int)$ip1[$i] & (int)$netmask1[$i];
						$network_id2[] = (int)$ip2[$i] & (int)$netmask2[$i];
					}
					$network_id1 = implode('.',$network_id1);
					$network_id2 = implode('.',$network_id2);
					if($network_id1==$network_id2){
						$this->theSameSegmentError = 1;
						return 1;
					}
				}
			}
		}

		preg_match('/addr:([^ ]+)/',shell_exec('/sbin/ifconfig '.trim($this->interface)),$matches);
		$command=implode(' && ',$this->cmd);
		$command=preg_replace('/(eth\d)/',"\$1:1",$command);
		system('/usr/bin/arping -f -c 1 -w 1 -I eth'.$this->eth." ".$this->ip.' > /dev/null 2>&1',$ip_alive);
		if($ip_alive!=0 || $_SERVER['SERVER_ADDR'] == $this->ip || $this->ip == $matches[1]){
			$result=shell_exec($command);
			$this->internalError = ($result == '') ? 0 : 1;
			preg_match('/eth\d:\d/',$command,$matches);
			shell_exec($this->ifconfig.' '.$matches[0].' down');
			return $this->internalError;
		}
		$this->theSameIPError = 1;
		return 1;
}


	//==========================================
	//	Final batch execution
	//==========================================
	function Batch() {
		$this->_rc_SetBoot();

/*
		//UNFINISHED
		if($result=="") {
			return true;
		}
		else{
			return false;
		}
*/

	}

	//==========================================
	//	This func picks out the $_POST we need
	//==========================================
	function _SortOut($array) {
		$this->interface=$array['prefix'];
		$this->eth=$array['interface'];
		$this->dhcp=$array['_dhcp'];
		$this->ip=$array['_ip'];
		$this->netmask=$array['_netmask'];
		$this->gateway=$array['_gateway'];
		$this->dns=$array['_dns'];
		$this->wins=$array['_wins'];
		$this->jumbo=$array['_jumbo'];
		$this->domainname=$array['_domainname'];
	}

	//==========================================
	//	This func set NIC disable
	//==========================================
	function _cmd_SetDisable() {
		//$this->cmd[]=$this->ifconfig." ".$this->nic." down";
	}

	//==========================================
	//	This func sets DHCP
	//==========================================
	function _cmd_SetDhcp() {
		//$this->cmd[]=$this->_SetDisable();
		//shell_exec("killall udhcpc");
		unlink("$resolv");
		//$this->cmd[]=$this->dhclient."-i ".$this->nic." > /dev/null 2>&1";
	}

	//==========================================
	//	This func does all static settings needed
	//==========================================
	function _cmd_SetStatic() {
		$this->_cmd_Ifconfig();
		if($this->eth=='0'){
			$this->_cmd_SetDNS();
			$this->_cmd_SetGW();
		}
	}
	
	//==========================================
	//	This func will exec ifconfig
	//==========================================
	function _cmd_Ifconfig() {
		$buf=$this->ifconfig." ".$this->nic." ";
		$buf.=$this->ip." netmask ".$this->netmask." ";
		$buf.="broadcast + ";
		$buf.="mtu ".$this->jumbo;
		//$this->cmd[]=$buf;
	}

	//==========================================
	//	This func sets Gateway
	//==========================================
	function _cmd_SetGW() {
		//$this->cmd[]=$this->route." del default";
		//shell_exec($this->route." del default");
		//$this->cmd[]=$this->route." add default gw ".$this->gateway;
	}

	//==========================================
	//	This func will set DNS resolv
	//==========================================
	function _cmd_SetDNS() {
		$d=trim($this->dns);
		$flag = false;
		$arr=explode("\n",$d);
		//$this->cmd[]="cat /dev/null > ".$this->resolv;
		shell_exec("cat /dev/null > ".$this->resolv);
		foreach($arr as $a) {
			$a=trim($a);
			if($a!="") {
				$str="nameserver ".$a;
				//$this->cmd[]="echo '".$str."' >> ".$this->resolv;
				shell_exec("echo '".$str."' >> ".$this->resolv);
				$flag = true;
			}
		}
		$d=trim($this->domainname);
		if ($d!=""){
			$str="search ".$d;
			shell_exec("echo '".$str."' >> ".$this->resolv);
			$flag = true;
		}
		if(!$flag)
			unlink("$resolv");
	}

	//==========================================
	//	This func will set WINS in smb.conf
	//==========================================
	function _conf_SetWINS() {
		$w=trim($this->wins);
		$val=implode(" ",explode("\n",$w));
		$SmbConf=new SmbConf();
		$SmbConf->setShare("global");
		$SmbConf->setValue("wins server",$val);
		unset($SmbConf);
	}

	//==========================================
	//	This func write config value back
	//==========================================
	function _rc_RollBack($lines_arr) {
		$fh=fopen($this->rc.$this->eth, "w");
		if(!$fh) return FALSE;
		flock($fh,LOCK_EX);
		fwrite($fh,$lines_arr);
		fflush($fh);
		flock($fh,LOCK_UN);
		@fclose($fh);
		return TRUE;
	}

	//==========================================
	//	This func will set nic down on boot
	//==========================================
	function _rc_SetBoot() {
	    global $thecus_io;
    	if (NAS_DB_KEY=='2')
            $this->dhclient="/sbin/udhcpc -t 5 -n -h `hostname` ";
        
	    $value="#!/bin/sh\n";
		if($this->jumbo=="") $this->jumbo=1500;
		if($this->eth=='1') { // eth1 only support static ip
			if ($sysconf["arch"] != 'oxnas')
				$value.=$this->ifconfig." ".$this->nic." ".$this->ip." netmask ".$this->netmask." broadcast +\n";
			$value.=$this->ifconfig." ".$this->nic." up\n";
			$value.=$this->ifconfig." ".$this->nic." mtu ". $this->jumbo."\n";
			if ($sysconf["arch"] == 'oxnas'){
				$value.=$this->ifconfig." ".$this->nic." down\n";
				$value.="sleep 2\n";
 				$value.=$this->ifconfig." ".$this->nic." ".$this->ip." netmask ".$this->netmask." broadcast +\n";
   				$value.=$this->ifconfig." ".$this->nic." up\n";
	    		}
			$value.= trim($this->gateway)=='' ? '' : $this->route." add default gw ".$this->gateway." dev eth1\n";
		} else if($this->dhcp == '1') {
			$value.=$this->ifconfig." ".$this->nic." up\n";
			$value.=$this->ifconfig." ".$this->nic." mtu ".$this->jumbo."\n";
			if ($sysconf["arch"] != 'oxnas')
				$value.=$this->dhclient."-i ".$this->nic." > /dev/null 2>&1\n";
			if ($sysconf["arch"] == 'oxnas'){
				$value.=$this->ifconfig." ".$this->nic." down\n";
				$value.="sleep 2\n";
 				$value.=$this->dhclient."-i ".$this->nic." > /dev/null 2>&1\n";
				$value.=$this->ifconfig." ".$this->nic." up\n";
	    		}
		} else if($this->dhcp == '2') {
			$value.=$this->ifconfig." ".$this->nic." up\n";
			$value.=$this->pppoe." > /dev/null 2>&1\n";
		}
		else {
			if ($sysconf["arch"] != 'oxnas')
    				$value.=$this->ifconfig." ".$this->nic." ".$this->ip." netmask ".$this->netmask." broadcast +\n";
			$value.=$this->ifconfig." ".$this->nic." up\n";
			$value.=$this->ifconfig." ".$this->nic." mtu ". $this->jumbo."\n";
			if ($sysconf["arch"] == 'oxnas'){
    				$value.=$this->ifconfig." ".$this->nic." down\n";
				$value.="sleep 2\n";
	    			$value.=$this->ifconfig." ".$this->nic." ".$this->ip." netmask ".$this->netmask." broadcast +\n";
    				$value.=$this->ifconfig." ".$this->nic." up\n";
	    	        }
			if($this->eth=='0')
				$value.= trim($this->gateway)=='' ? '' : $this->route." add default gw ".$this->gateway."\n";
		}
		/* THEN WRITE BACK */
		return $this->_rc_RollBack($value);
	}


	//==========================================
	//	End of class
	//==========================================
}

?>
