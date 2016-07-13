<?php 
error_reporting(E_ERROR | E_PARSE);
ini_set('display_errors', 'On');

require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'ha.class.php');
require_once(INCLUDE_ROOT.'info/raidinfo.class.php');
$action = $_POST['action'];


if( method_exists('HighAvailabilityRPC', $action) ) {
    $params = json_decode(stripslashes($_POST['params']), true);

    $result = call_user_func_array(array('HighAvailabilityRPC', $action), $params);
    array_unshift($result, $action);
    die(json_encode($result));
}


/**
 * Query all public methods in HugeVolumeRPC class.
 * 
 * @return String[]
 */
function proceduresEnum() {
    $refl = new ReflectionClass('HighAvailabilityRPC');
    $public = $refl->getMethods(ReflectionMethod::IS_PUBLIC);
    $methods = array();
    for( $i = 0 ; $i < count($public) ; $i++ ) {
        if( $public[$i]->name != "background" && $public[$i]->name != "frontground" ) {
            array_push($methods, $public[$i]->name);
        }
    }
    return $methods;
}


switch($_REQUEST['ac']){
    case 'getLog':
        $start = ($_POST['start'] == '')? 0: $_POST['start'];	// start record
        $limit = ($_POST['limit'] =='')? 10: $_POST['limit'];	// page limit 
        $priority = ($_POST['priority'] == '')? 'all': $_POST['priority'];	// ha log priority: all/info/warn/error
        $init = $_POST['init'];		// init ha log data 
    
        // initialization ha log data to SESSION variable
        if($init == '1'){
            $logstore = array("totalCount"=>0, "logs"=>array());
            $fp = fopen(HA_LOG_PATH, 'rb');
            while ( $cline = fgets($fp) )
            {
                list($prior, $datetime, $desc) = explode('|',$cline);
                if($prior == $priority || $priority == 'all'){
                    array_push($logstore['logs'], array('priority'=>$prior, 
                                                'datetime'=>$datetime,
                                                'desc'=>$desc));
                    $logstore['totalCount']++;
                }
            }
            fclose($fp);
            
            //sorting 
            $logstore_sort = array('logs'=>array(), 'totalCount'=>$logstore['totalCount']);
            $total = count($logstore['logs'])-1;
            $k=0;
            for($i=$total ;$i>=0; $i--){
                $logstore_sort['logs'][$k] = $logstore['logs'][$i];
                $k++;
            } 
            $_SESSION['ha_log'] = $logstore_sort;
        }
        
        // general page 
        $count = $_SESSION['ha_log']['totalCount'];
        $log = array();
        
        if( ($limit + $start)  > $count){
            $current_count = $count;
        }else{
            $current_count = $limit + $start;
        } 		
        
        for($i = $start; $i < $current_count; $i++){
            $log[]= $_SESSION['ha_log']['logs'][$i];
        }
        die(json_encode(
                array('totalCount'=>$count,'logs'=>$log)
                ));
        break;
    case 'getRaidStatus':
        $store = array();
        $fp = fopen(HA_STATUS_PATH, 'rb');
        while ( $cline = fgets($fp) )
        {
            list($raidid, $type, $recovery, $finish, $speed, $capacity, $status, $active_md, $standby_md) = explode('|',$cline);
            array_push($store, array('raidid'=>$raidid, 
                                    'type'=>$type,
                                    'recovery'=>$recovery,
                                    'finish'=>$finish,
                                    'speed'=>$speed,
                                    'capacity'=>$capacity,
                                    'status'=>$status,
                                    'md'=>array($active_md,$standby_md)
                                    ));
        }
        fclose($fp);
        die(json_encode($store));
        break;
}


$words = $session->pageCode("ha");
    
$db = new sqlitedb();
$data = array();
$hostname = $db->getvar("nic1_hostname","");
$ip1 = $db->getvar("nic1_ip","192.168.1.100");
$ip2 = $db->getvar("nic1_ipv6_addr","fec0::1");

$db_HA_field = array("ha_enable"=>0, "ha_role"=>"0", "ha_virtual_name"=>"HA", "ha_virtual_ip"=>"",
        "ha_primary_name"=>$hostname,"ha_primary_ip1"=>$ip1.",".$ip2,
        "ha_standy_name"=>"", "ha_standy_ip1"=>"",
        "ha_keepalive"=>HA_KEEPALIVE, "ha_deadtime"=>HA_DEADTIME, "ha_warntime"=>HA_WARNTIME, "ha_initdead"=>HA_INITDEAD,
        "ha_udpport"=>HA_UDPPORT,
        "ha_heartbeat"=>HA_HEARTBEAT,
        "ha_auto_failback"=>"0",
        "ha_primary_ip3"=>HA_HEARTBEAT_ACTIVE, "ha_standy_ip3"=>HA_HEARTBEAT_STANDBY, "ha_indicator_ip"=>"" );
foreach($db_HA_field as $k=>$v){
    $data[$k] = $db->getvar($k, $v);
}


if(strstr($data['ha_virtual_ip'], ",")){
    list($data['ha_virtual_ip_iface'], $data['ha_virtual_ip_ipv4'], $data['ha_virtual_ip_ipv6']) = explode(',',$data['ha_virtual_ip']);
    list($data['ha_virtual_ip_iface'], $data['ha_primary_ip_ipv4'], $data['ha_primary_ip_ipv6']) = explode(',',$data['ha_primary_ip1']);
    list($data['ha_virtual_ip_iface'], $data['ha_standby_ip_ipv4'], $data['ha_standby_ip_ipv6']) = explode(',',$data['ha_standy_ip1']);
    list($data['ha_virtual_ip_iface'], $data['ha_indicator_ip_ipv4'], $data['ha_indicator_ip_ipv6']) = explode(',',$data['ha_indicator_ip']);
}else{
    $data['ha_virtual_ip_iface']='eth0';
    list($data['ha_virtual_ip_ipv4'], $data['ha_virtual_ip_ipv6']) = explode(',',$data['ha_virtual_ip']);
    list($data['ha_primary_ip_ipv4'], $data['ha_primary_ip_ipv6']) = explode(',',$data['ha_primary_ip1']);
    list($data['ha_standby_ip_ipv4'], $data['ha_standby_ip_ipv6']) = explode(',',$data['ha_standy_ip1']);
    $data['ha_indicator_ip_ipv4'] = $db->getvar("nic1_gateway");
}

$hostname = $db->getvar("nic1_hostname","");
$primary_name = $db->getvar("ha_primary_name",$hostname);
if($primary_name ==''){
    $db->setvar("ha_primary_name",$hostname);
}

if (($data['ha_enable']=='0') && ($data['ha_primary_ip_ipv4'] != $ip1)){
  $data['ha_primary_ip_ipv4'] = $ip1;
}

/**
 * Virtual Interface array
 */
$virtual_interfaces = array();
$Cmd=IMG_BIN."/rc/rc.net get_network_info";
$AllInfo=shell_exec($Cmd);
$InfoArray=explode("\n",$AllInfo);
$data['ha_virtual_ip_iface_name'] = '';
$data['ha_virtual_ip_iface_index'] = '0';
$index = 0;
$hearetbeatable = false;
foreach($InfoArray as $InfoData){
    if($InfoData != ''){
        $linking = "";
        if(preg_match("/^g?eth[0-9]+/", $InfoData)){
            list($iface, $name, $mac, $connected, $speed, $min_jumbo, $max_jumbo, $desp, $vip ,$heartbeat,
                $linking, $jumbo['selected'], $v4["enable"], $v4["setup"], $v4["manual"]["ip"], 
                $v4["manual"]["mask"], $v4["manual"]["gateway"],$v4["auto"]["ip"],$v4["auto"]["mask"],
                $v4["auto"]["gateway"], $v6["enable"], $v6["setup"], $v6["manual"]["prefix"], 
                $v6["manual"]["length"], $v6["manual"]["gateway"], $v6["auto"]["prefix"], 
                $v6["auto"]["length"], $v6["auto"]["gateway"]) = explode("|", $InfoData);
            
            if( $linking != "" || $v4["setup"] == "1" || $v6["setup"] == "1" ) {
                continue;
            }
            if($data['ha_virtual_ip_iface']==trim($iface)){
                $data['ha_virtual_ip_iface_name'] = trim($name);
                $data['ha_virtual_ip_iface_index'] = $index;
            }
        } else if( preg_match("/^bond\|/", $InfoData) ) {
            $bondAry = explode("|", $InfoData);
            list($tag, $id, $mode ,$v4["enable"], $v4["setup"],$v4["manual"]["ip"], $v4["manual"]["mask"], 
                $v4["manual"]["gateway"], $v6["enable"], $v6["setup"],$v6["manual"]["prefix"],
                $v6["manual"]["length"],$v6["manual"]["gateway"],$jumbo['selected'], $desp, $min_jumbo, 
                $mac,$vip,$hearetbeat, $other) = explode("|", $InfoData);

            $iface = trim($tag.$id);
            $name = "LINK".($id+1);
            $data['ha_virtual_ip_iface_name'] = trim($name);
            $data['ha_virtual_ip_iface_index'] = $index;
        } else {
            continue;
        }
        
        if( $name == "" || $linking != "" || $v4["setup"] == "1" || $v6["setup"] == "1" ) {
            continue;
        }
        
        if( preg_match("/^eth(1[0-9]+|[2-9][0-9]?)|^(geth|bond)[0-9]+/", $iface) ) {
            $hearetbeatable = true;
        }
        
        array_push($virtual_interfaces,array(
            'index'=>$index,
            'id'=>trim($iface),
            'name'=>trim($name),
            'ipv4_setup'=>$v4['setup'],
            'ipv6_setup'=>$v6['setup'],
            'ipv6_enable'=>$v6['enable'],
            'ipv4'=>$v4["manual"]["ip"],
            'ipv6'=>$v6["manual"]["prefix"]
        ));
        
        if(trim($iface) == $data['ha_virtual_ip_iface']) {
            $iface_match = true;
        }
        $index++;
    }
}
if( $iface_match != true ) {
    $data['ha_virtual_ip_iface'] = "";
}
$data["hearetbeatable"] = $hearetbeatable;

/**
 * Heartbeat Interface array
 */
$ha_heartbeat = $db->getvar("ha_heartbeat");
//$ha_heartbeat_txt = "LAN3"; 
//$interface_num = 3;
$data["ha_heartbeat"] = "";
$hb_interfaces = array();
/*$check_bond_cmd="/img/bin/function/get_interface_info.sh 'check_eth_bond' ";
$ret=trim(shell_exec($check_bond_cmd."'".HA_HEARTBEAT."'"));
if( $ret == ""){
    array_push($hb_interfaces,array('id'=>HA_HEARTBEAT,'name'=>'LAN3'));
}*/
$ph = popen("ifconfig", "r");
while (!feof($ph)){
    $line = fgets($ph, 4096);
    if (preg_match("/Link encap/i", $line, $match)){
        list($eth) = explode(" ",$line);
/*        if (preg_match("/^eth[4-99]/i", $eth, $match2)){
            $tengTxt=trim(shell_exec("/img/bin/function/get_interface_info.sh get_nic_name ".$eth));
            
            
            //$interface_num++;	
        }*/
    
        if (preg_match("/^geth|^eth[2-99]/i", $eth, $match3)){
            $ret=trim(shell_exec($check_bond_cmd."'".$eth."'"));
            if( $ret == ""){
                $ethlist=file("/tmp/all_interface");
                foreach($ethlist as $v){
                    $ethinfo=explode("|",$v);
                    if( $ethinfo[0] == $eth){
                        $tengTxt=trim(shell_exec("/img/bin/function/get_interface_info.sh get_nic_name ".$eth));
           //             $interface_num=$ethinfo[1];
                        break;
                    }
                }

//                $tengTxt = $gwords['10gbe'].$interface_num;
                array_push($hb_interfaces, array('id'=>$eth, 'name'=>$tengTxt));
                if($ha_heartbeat == $eth){
                    $data['ha_heartbeat']=$eth;
                    $ha_heartbeat_txt = $tengTxt;
                }
           }
        }
    }
}
pclose($ph);
$data['Iface'] = $virtual_interfaces;
$data['hb_Iface'] = $hb_interfaces;
$data['ha_heartbeat_txt'] = $ha_heartbeat_txt;

//read ha role file
$current_role = trim(file_get_contents("/var/tmp/ha_role"));
$current_role_value = (trim($current_role) == "active")? '0': '1';
$current_role_txt = ($current_role_value== '0')? $words['active']: $words['standby'];
$data['current_role_value'] = $current_role_value;
$data['current_role'] = $current_role;


/**
* check current RAID isn't HA RAID
*/
$exists_ha_raid = 0;
if($data['ha_enable']=='0'){
    $raid = new RAIDINFO();
    $md_array = $raid->getMdArray();
    foreach($md_array as $k=>$md_num){
        if($md_num <200 ){
            if (file_exists("/raidsys/$k/ha_raid")){
                 $exists_ha_raid = 1;
                break;
            }
        }
    }
}
$data['exists_ha_raid'] = $exists_ha_raid;
$data['ha_tab'] = ($data['ha_enable'] == '0')?'1':'0';

$hv_client_on_off=0;
$strExec="/bin/cat /proc/mdstat | awk -F: '/^md1[1-9] :/{printf(\"%s\\n\",  substr(\$1,3))}' | sort -u";
$md_list=trim(shell_exec($strExec));
if ($md_list!="")
    $hv_client_on_off=1;
    
$hv_enable=$db->getvar("hv_enable","0");

if ($hv_client_on_off==1)
  $hv_enable="1";

$words['all'] = $gwords['all'];
$words['truncate_all'] = $gwords['truncate_all'];
$words['ip_error'] = $gwords['ip_error'];
$words['wait_sys'] = $gwords['wait_sys'];
$words['info'] = $gwords['info'];
$words['warn'] = $gwords['warn'];
$words['error'] = $gwords['error'];
$words['page1'] = $gwords['page1'];
$words['page2'] = $gwords['page2'];
$words['page3'] = $gwords['page3'];
$words['ip'] = $gwords['ip'];
$words['enable'] = $gwords['enable'];
$words['disable'] = $gwords['disable'];
$words['status'] = $gwords['status'];
$words['ha_dhcp_warning'] = $gwords['ha_dhcp_warning'];

$tpl->assign('words',json_encode($words));
$tpl->assign('data',json_encode($data));
$tpl->assign('hv_enable',$hv_enable);
$tpl->assign('procedures', json_encode(proceduresEnum()));

?>
