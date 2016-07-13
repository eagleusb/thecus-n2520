<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$Cmd=IMG_BIN."/rc/rc.net get_dhcp_server_info";
$AllInfo=shell_exec($Cmd);
$InfoArray=explode("\n",$AllInfo);
$FieldArray=Array('option|');


function change_value($val,$ok,$fail){
    if($val==1){
        $val=$ok;
    }else{
        $val=$fail;
    }
    return $val;
}

function parse_interface($InfoData){
    global $configure;

    list($interface, $name, $note, $vip, $heartbeat, $linking, $v4["enable"], $v4["setup"], $v4["ip"], 
         $v4["mask"], $v4["dhcp"]["enable"], $v4["dhcp"]["low"],$v4["dhcp"]["high"],
         $v4["dhcp"]["gateway"], $v4_dns_list, $v6["enable"], $v6["setup"], 
         $v6["ip"],$v6["len"], $v6["radvd"]["enable"], $v6["radvd"]["prefix"], 
         $v6["radvd"]["length"])= explode("|", $InfoData);

    $v4["enable"]=change_value($v4["enable"],true,false);
    $v6["enable"]=change_value($v6["enable"],true,false);
    $v4["setup"]=change_value($v4["setup"],"auto","manual");
    $v6["setup"]=change_value($v6["setup"],"auto","manual");
    $v4["dhcp"]["enable"]=change_value($v4["dhcp"]["enable"],true,false);
    $v6["radvd"]["enable"]=change_value($v6["radvd"]["enable"],true,false);
    $i=1;
    $v4_dns_ary=explode(" ",$v4_dns_list);
    foreach ($v4_dns_ary as $dns){
        if( $dns != ""){
            $v4["dhcp"]["dns".$i]=$dns;
            $i++;
        }
    }
    if($linking!="")
            $linking=substr($linking,0,4).(substr($linking,4)+1);
            
    $configure[$interface]=array(
        'name'      => $name,
        'linking'   => $linking,
        'heartbeat' => $heartbeat,
        'v4'        => $v4,
        'v6'        => $v6,
        'vip'       => $vip,
        'note'      => $note
    );
}

foreach ($InfoArray as $InfoData){
    if($InfoData != ""){
        for($i=0;$i<count($FieldArray);$i++){
            $Ret=strstr($InfoData,$FieldArray[$i]);
            if ($Ret!= ""){
                break;
            }
        }
    
        switch($i){
            case 0:
                list($tag,$options["ha"],$options["reboot"])=explode("|", $InfoData);
                break;
            default:
                parse_interface($InfoData);
                break;
        }
    }
}

$words = $session->PageCode("dhcp");

$tpl->assign('configure', json_encode($configure));
$tpl->assign('flags', json_encode($options));
$tpl->assign('words', json_encode($words));
?>
