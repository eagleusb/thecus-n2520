<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$Cmd=IMG_BIN."/rc/rc.net get_network_info";
$AllInfo=shell_exec($Cmd);
$InfoArray=explode("\n",$AllInfo);
$FieldArray=Array('host|' , 'dns|', 'default_gateway|global|' , 'bond|','option|');

function parse_host($InfoData){
    list($tag, $name, $domain, $wins1, $wins2) = explode("|", $InfoData);
    $wins=array();
    if ($wins1!=""){
        $wins[]=$wins1;
    }
    if ($wins2!=""){
        $wins[]=$wins2;
    }

    return array(
               'name' => &$name,
               'domain' => &$domain,
               'wins' => &$wins
           );
}

function parse_dns($InfoData){
    global $dns;

    list($tag, $type) = explode("|", $InfoData);
    switch($type){
        case 'global' :
            list($tag, $type, $val) = explode("|", $InfoData);

            if($val==1){
                $dns["setup"]="auto";
            }else{
                $dns["setup"]="manual";
            }
            break;
        default:
            if($type=="static"){
                $Name="manual";
            }else{
                $Name="auto";
            }

            $InfoList=explode("|", $InfoData);
            for($i=0;$i<2;$i++){
                array_shift($InfoList);
            }
            $dns[$Name]=$InfoList;
            break;
    }
}

function parse_gateway($InfoData){
    list($tag, $type, $val) = explode("|", $InfoData);
    switch($type){
        case 'global' :
            return $val;
            break;
        default:
            break;
    }
}

function change_value($val,$ok,$fail){
    if($val==1){
        $val=$ok;
    }else{
        $val=$fail;
    }
    return $val;
}

function parse_bond($InfoData){
    global $ethernets;
    $fieldcount=19;

    list($tag, $id, $mode ,$v4["enable"], $v4["setup"],$v4["manual"]["ip"], $v4["manual"]["mask"], 
         $v4["manual"]["gateway"], $v6["enable"], $v6["setup"],$v6["manual"]["prefix"],
         $v6["manual"]["length"],$v6["manual"]["gateway"],$jumbo['selected'], $desp, $min_jumbo, 
         $mac,$vip,$hearetbeat) = explode("|", $InfoData);

    $v4["setup"]=change_value($v4["setup"],"auto","manual");
    $v6["setup"]=change_value($v6["setup"],"auto","manual");
    $v4["enable"]=change_value($v4["enable"],true,false);
    $v6["enable"]=change_value($v6["enable"],true,false);

    $JumboArray[]=$min_jumbo;
    $jumbo["allow"]=$JumboArray;
    if( $jumbo['selected'] == "" ){
        $jumbo['selected']=$min_jumbo;
    }

    $infolist=explode("|", $InfoData);
    
    for($i=$fieldcount;$i<count($infolist);$i++){
        if($infolist[$i] != ""){
          $bonding[]=$infolist[$i];
        }
    }

    $ethernets["bond".$id]=array(
        'bonding'  => &$bonding,
        'v4'       => &$v4,
        'v6'       => &$v6,
        'jumbo'    => &$jumbo,
        'mac'      => &$mac,
        'name'     => "LINK".($id+1),
        'mode'     => &$mode,
        'vip'      => &$vip,
        'note'     => &$desp
    );
}

function parse_interface($InfoData){
    global $ethernets;

    list($interface, $name, $mac, $connected, $speed, $min_jumbo, $max_jumbo, $desp, $vip ,$heartbeat,
         $linking, $jumbo['selected'], $v4["enable"], $v4["setup"], $v4["manual"]["ip"], 
         $v4["manual"]["mask"], $v4["manual"]["gateway"],$v4["auto"]["ip"],$v4["auto"]["mask"],
         $v4["auto"]["gateway"], $v6["enable"], $v6["setup"], $v6["manual"]["prefix"], 
         $v6["manual"]["length"], $v6["manual"]["gateway"], $v6["auto"]["prefix"], 
         $v6["auto"]["length"], $v6["auto"]["gateway"]) = explode("|", $InfoData);
    
    $JumboArray[]=$min_jumbo;
    for ($jumbo_idx=2000;$jumbo_idx<=$max_jumbo;$jumbo_idx+=1000){
        $JumboArray[]=$jumbo_idx;
    }

    if(($max_jumbo % 1000) !=0){
        $JumboArray[]=$max_jumbo;
    }
    
    $jumbo["allow"]=$JumboArray;
    
    if( $connected == "yes"){
        $connected=true;
    }else{
        $connected=false;
    }

    if( $jumbo['selected'] == "" ){
        $jumbo['selected']=$min_jumbo;
    }
    
/*    if($linking != ""){
         $v4["setup"]="";
         $v4["manual"]["ip"]=""; 
         $v4["manual"]["mask"]="";
         $v4["manual"]["gateway"]="";
         $v4["auto"]["ip"]="";
         $v4["auto"]["mask"]="";
         $v4["auto"]["gateway"]="";
         $v6["enable"]="";
         $v6["setup"]="";
         $v6["manual"]["prefix"]="";
         $v6["manual"]["length"]="";
         $v6["manual"]["gateway"]="";
         $v6["auto"]["prefix"]=""; 
         $v6["auto"]["length"]="";
         $v6["auto"]["gateway"]="";
    }
*/
    $v4["enable"]=change_value($v4["enable"],true,false);
    $v6["enable"]=change_value($v6["enable"],true,false);
    $v4["setup"]=change_value($v4["setup"],"auto","manual");
    $v6["setup"]=change_value($v6["setup"],"auto","manual");
    if($linking!="")
        $linking=substr($linking,0,4).(substr($linking,4)+1);
    
    $ethernets[$interface]=array(
        'name'      => &$name,
        'mac'       => &$mac,
        'jumbo'     => &$jumbo,
        'linking'   => &$linking,
        'heartbeat' => &$heartbeat,
        'connected' => &$connected,
        'speed'     => &$speed,
        'v4'        => &$v4,
        'v6'        => &$v6,
        'bonding'   => false,
        'vip'       => &$vip,
        'note'      => &$desp
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
                $host=parse_host($InfoData);
                break;
            case 1:
                parse_dns($InfoData);
                break;
            case 2:
                $gateway=parse_gateway($InfoData);
                break;
            case 3:
                parse_bond($InfoData);
                break;
            case 4:
                list($tag,$flags["ha"],$flags["reboot"])=explode("|", $InfoData);
                break;
            default:
                parse_interface($InfoData);
                break;
        }
    }
}

$words = $session->PageCode("network");

$tpl->assign('host', json_encode($host));
$tpl->assign('dns', json_encode($dns));
$tpl->assign('ethernets', json_encode($ethernets));
$tpl->assign('gateway', $gateway);
$tpl->assign('flags', json_encode($flags));
$tpl->assign('words', json_encode($words));
?>
