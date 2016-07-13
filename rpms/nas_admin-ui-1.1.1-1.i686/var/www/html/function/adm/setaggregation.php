<?php
$action = $_REQUEST['action'];
$Cmd=IMG_BIN."/rc/rc.net set_link";
$params = json_decode(stripslashes($_REQUEST['params']), TRUE);

function change_value($val,$def,$ok,$fail){
    if($val==$def){
        $val=$ok;
    }else{
        $val=$fail;
    }
    return $val;
}

$InfoStr="";

if( isset($params['gateway']) ) {
    $str="%sgateway|%s\n";
    $InfoStr = sprintf($str,$InfoStr,$params['gateway']);
}

if( isset($params['bonds']) ) {
    $str="%s%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s";
    $ethstr="%s|%s";
    $i=0;
    foreach($params['bonds'] as $v) {
        $v['v4']['enable']=change_value($v['v4']['enable'],true,"1","0");
        $v['v6']['enable']=change_value($v['v6']['enable'],true,"1","0");
    
        $InfoStr = sprintf($str,$InfoStr,$i,$v['mode'],$v['v4']['enable'],"0",
                           $v['v4']['ip'],$v['v4']['mask'],$v['v4']['gateway'],
                           $v['v6']['enable'],"0",$v['v6']['prefix'],$v['v6']['length'],
                           $v['v6']['gateway'],$v['jumbo']['selected'],$v['note']);
    
        foreach($v['bonding'] as $eth){
            $InfoStr = sprintf($ethstr,$InfoStr,$eth);
        }
        $InfoStr = sprintf("%s\n",$InfoStr);
        $i++;
    }
}

if ($InfoStr != "")
    $result_list=trim(shell_exec($Cmd." '".$InfoStr."'"));

$result=explode("|",$result_list);

for($i=1;$i<count($result);$i++){
    $data[]=explode(",",$result[$i]);
}
    
die(json_encode(array(code=> $result[0],
                           data=> $data
                     )));
                                               
?>

