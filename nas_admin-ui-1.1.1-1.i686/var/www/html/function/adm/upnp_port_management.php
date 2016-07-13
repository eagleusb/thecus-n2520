<?php

$action = $_REQUEST['action'];
$words = $session->PageCode("upnp_port_management");

function show_port(){ 
  $mapping = array(); 
  $change=1;
  $p=trim(shell_exec("cat /tmp/p"));
  if($p!=""){
      for( $ps=1; $ps<=$p; $ps++ ){
          $in_port=trim(shell_exec("cat /tmp/router_ports2|awk -F' ' 'NR==$ps{print $3}'|awk -F'->' '{print $2}'|awk -F':' '{print $2}'"));
          $protocol=trim(shell_exec("cat /tmp/router_ports2|awk -F' ' 'NR==$ps{print $2}'"));
          switch($protocol){
            case 'TCP':
              $protocols=1;
              break;
            case 'UDP':
              $protocols=2;
              break;
            case 'TCP/UDP':
              $protocols=3;
              break;  
          }
          array_push($mapping, array(
                '0',
                $in_port,
                $protocols,
                ''
          ));
      } 
  }
  
  while(1){
     $in_port=trim(shell_exec("cat /tmp/copy_port2|awk -F'|' 'NR==$change{print $1}'"));
     $protocol=trim(shell_exec("cat /tmp/copy_port2|awk -F'|' 'NR==$change{print $3}'"));
     $des=trim(shell_exec("cat /tmp/copy_port2|awk -F'|' 'NR==$change{print $4}'"));
     $status=trim(shell_exec("cat /tmp/copy_port2|awk -F'|' 'NR==$change{print $5}'"));
     if($in_port!=""){
        $range_port=trim(shell_exec("cat /tmp/copy_port2|awk -F'|' 'NR==$change{print $2}'"));
        if($range_port!=""){
             $in_port="$in_port-$range_port";
        }
        
        switch($protocol){
            case 'TCP':
              $protocols=1;
              break;
            case 'UDP':
              $protocols=2;
              break;
            case 'TCP/UDP':
              $protocols=3;
              break;  
        }
        array_push($mapping, array(
                '1',
                $in_port,
                $protocols,
                $des,
                $status
        ));
     }else{
        break;
     }
     $change++;
  }
  shell_exec("rm -rf /tmp/p");
return $mapping;
}

function information(){
shell_exec("/img/bin/rc/rc.router scan");

$link =trim(shell_exec("cat /tmp/link_url"));
$curl = curl_init($link);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
$f = curl_exec($curl);
curl_close($curl);

preg_match("/<friendlyName[^>]*>(.*?)<\/friendlyName>/si", $f, $match1);
preg_match("/<manufacturerURL[^>]*>(.*?)<\/manufacturerURL>/si", $f, $match2);
preg_match("/<modelNumber[^>]*>(.*?)<\/modelNumber>/si", $f, $match3);
preg_match("/<modelURL[^>]*>(.*?)<\/modelURL>/si", $f, $match4);
preg_match("/<modelDescription[^>]*>(.*?)<\/modelDescription>/si", $f, $match5);
preg_match("/<UDN[^>]*>(.*?)<\/UDN>/si", $f, $match6);          
    $info = array(
            $match1[1],
            $match2[1],
            $match3[1],
            $match4[1],
            $match5[1],
            $match6[1]
    );
    
return $info;
}

if( $action == 'refresh' ) {
    $result = array(
        'code' => 'refresh',
        'info' => information(),
        'data' => show_port(),
        'status' => trim(shell_exec("cat /tmp/setport_msg2"))
    );
    die(json_encode($result));
}else{
    if ( $action == 'reset' ) {
        shell_exec("/img/bin/rc/rc.router start");
        $result = array(
        'code' => 'refresh',
        'info' => information(),
        'data' => show_port(),
        'status' => trim(shell_exec("cat /tmp/setport_msg2"))
        );
        die(json_encode($result));
    }
    
    
    $tpl->assign('words', json_encode($words));
    $tpl->assign('information', json_encode(information()));
    $tpl->assign('mapping', json_encode(show_port()));
    $tpl->assign('status', json_encode(trim(shell_exec("cat /tmp/setport_msg2")))); 
}       
?>
