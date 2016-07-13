<?php
$Cmd=IMG_BIN."/rc/rc.net set_network_info";
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

if( isset($params['host']) ) {
    $str="%shost|%s|%s|%s|%s\n";
    $InfoStr = sprintf($str,$InfoStr,$params['host']['name'],$params['host']['domain'],$params['host']['wins'][0],$params['host']['wins'][1]);
}

if( isset($params['dns']) ) {
    $str="%sdns|%s|%s|%s|%s\n";
    $params['dns']['setup']=change_value($params['dns']['setup'],"auto","1","0");
    $InfoStr = sprintf($str,$InfoStr,$params['dns']['setup'],$params['dns']['manual'][0],$params['dns']['manual'][1],$params['dns']['manual'][2]);
}

if( isset($params['gateway']) ) {
    $str="%sgateway|%s\n";
    $InfoStr = sprintf($str,$InfoStr,$params['gateway']);
}

if( isset($params['ethernets']) ) {
    $str="%s%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n";
    foreach($params['ethernets'] as $k => $v) {
        $v['v4']['setup']=change_value($v['v4']['setup'],"auto","1","0");
        $v['v6']['setup']=change_value($v['v6']['setup'],"auto","1","0");
        $v['v4']['enable']=change_value($v['v4']['enable'],true,"1","0");
        $v['v6']['enable']=change_value($v['v6']['enable'],true,"1","0");

        $InfoStr = sprintf($str,$InfoStr,$k,$v['v4']['enable'],$v['v4']['setup'],
                           $v['v4']['manual']['ip'],$v['v4']['manual']['mask'],
                           $v['v4']['manual']['gateway'],$v['v6']['enable'],$v['v6']['setup'],
                           $v['v6']['manual']['prefix'],$v['v6']['manual']['length'],
                           $v['v6']['manual']['gateway'],$v['jumbo']['selected'],$v['note']);
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
