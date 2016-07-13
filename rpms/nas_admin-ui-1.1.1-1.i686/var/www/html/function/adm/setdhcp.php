<?php
$Cmd=IMG_BIN."/rc/rc.net set_dhcp_server";
$params = json_decode(stripslashes($_REQUEST['params']), TRUE);
//var_dump($params);

function change_value($val,$def,$ok,$fail){
    if($val==$def){
        $val=$ok;
    }else{
        $val=$fail;
    }
    return $val;
}

$InfoStr="";
$str="%s%s|%s|%s|%s|%s|%s|%s|%s";
$dnstr="%s|v4d_%s";
foreach($params as $k => $v) {
    $v['v4']['dhcp']['enable']=change_value($v['v4']['dhcp']['enable'],true,"1","0");
    $v['v6']['radvd']['enable']=change_value($v['v6']['radvd']['enable'],true,"1","0");
    $InfoStr = sprintf($str,$InfoStr,$k,$v['v4']['dhcp']['enable'],$v['v4']['dhcp']['low'],
                       $v['v4']['dhcp']['high'],$v['v4']['dhcp']['gateway'],
                       $v['v6']['radvd']['enable'],$v['v6']['radvd']['prefix'],
                       $v['v6']['radvd']['length']);

    for($i=1;$i<=3;$i++){
       if($v['v4']['dhcp']['dns'.$i] != ""){
           $InfoStr = sprintf($dnstr,$InfoStr,$v['v4']['dhcp']['dns'.$i]);
       }
    }
    $InfoStr = sprintf("%s\n",$InfoStr);
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
