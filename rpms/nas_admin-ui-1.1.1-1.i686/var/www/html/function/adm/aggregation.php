<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

$Cmd=IMG_BIN."/rc/rc.net get_network_info";
$AllInfo=shell_exec($Cmd);
$InfoArray=explode("\n",$AllInfo);
$FieldArray=Array('gateway|','bond|','option|','eth','geth');
$links=array();

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
    global $links;
    $fieldcount=19;

    list($tag, $id, $mode ,$v4["enable"], $v4["setup"],$v4["ip"], $v4["mask"], 
         $v4["gateway"], $v6["enable"], $v6["setup"],$v6["prefix"],
         $v6["length"],$v6["gateway"],$jumbo['selected'], $desp, $min_jumbo, 
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
    
    array_push($links,array(
        'bonding'    => &$bonding,
        'hearetbeat' => &$hearetbeat,
        'v4'         => &$v4,
        'v6'         => &$v6,
        'jumbo'      => &$jumbo,
        'mode'       => &$mode,
        'vip'        => &$vip,
        'note'       => &$desp
    ));
}

function parse_interface($InfoData){
    global $interfaces;

    list($interface, $name, $mac, $connected, $speed, $min_jumbo, $max_jumbo, $desp, $vip, $heartbeat,
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

    $v4["enable"]=change_value($v4["enable"],true,false);
    $v6["enable"]=change_value($v6["enable"],true,false);
    $v4["setup"]=change_value($v4["setup"],"auto","manual");
    $v6["setup"]=change_value($v6["setup"],"auto","manual");

    $v4["ip"]=$v4[$v4["setup"]]["ip"];
    $v4["mask"]=$v4[$v4["setup"]]["mask"];
    $v4["gateway"]=$v4[$v4["setup"]]["gateway"];
    $v6["prefix"]=$v6[$v6["setup"]]["prefix"];
    $v6["length"]=$v6[$v6["setup"]]["length"];
    $v6["gateway"]=$v6[$v6["setup"]]["gateway"];
    if($linking!="")
        $linking=substr($linking,0,4).(substr($linking,4)+1);
    $interfaces[$interface]=array(
        'name'      => &$name,
        'jumbo'     => &$jumbo,
        'linking'   => &$linking,
        'heartbeat' => &$heartbeat,
        'speed'     => &$speed,
        'v4'        => &$v4,
        'v6'        => &$v6,
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
                $gateway=parse_gateway($InfoData);
                break;
            case 1:
                parse_bond($InfoData);
                break;
            case 2:
                list($tag,$flags["ha"],$flags["reboot"])=explode("|", $InfoData);
                break;
            case 3:
            case 4:
                parse_interface($InfoData);
                break;
            default:
                break;
        }
    }
}

$words = $session->PageCode("aggregation");

$tpl->assign('interfaces', json_encode($interfaces));
$tpl->assign('links', json_encode($links));
$tpl->assign('flags', json_encode($flags));
$tpl->assign('gateway', $gateway);
$tpl->assign('words', json_encode($words));
?>
