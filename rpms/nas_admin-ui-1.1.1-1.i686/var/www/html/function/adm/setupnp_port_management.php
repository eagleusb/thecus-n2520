<?php
$action = $_REQUEST['action'];

switch( $action ) {
case 'save':
    $data = json_decode(stripcslashes($_REQUEST['params']), true);
    //for( $c = 0; $c <= count($data); $c++){
       $old_ports=$data[0][0];
       $ports=$data[0][1];
       $protocol=$data[0][2];
       $des=$data[0][3];       
       if ($ports==""){
          break;
       }
      
       if ($data[0][2]=="1"){
           $protocol="TCP";            
       }else if ($data[0][2]=="2"){
           $protocol="UDP";         
       }else if ($data[0][2]=="3"){
           $protocol="TCP/UDP";                
       }

       ereg("([0-9]{1,})-([0-9]{1,})",$ports,$regs); 
       if ($regs!=""){           
           $range=($regs[2]-$regs[1])+1;
           for($ran=0;$ran<$range;$ran++){
               $rn_port=$regs[1]+$ran;
               if($protocol=="TCP/UDP"){                  
                  $total.="$rn_port TCP $rn_port UDP ";
               }else{
                  $total.="$rn_port $protocol ";
               }
           }
           $ports=$regs[1];
           ereg("([0-9]{1,})-([0-9]{1,})",$old_ports,$old_regs);
           $old_ports=$old_regs[1]; 
           
       }else{
           if($protocol=="TCP/UDP"){
                $total.="$ports TCP $ports UDP ";
           }else{
                $total.="$ports $protocol ";
           } 
       }
       
       $change=shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"select port from router where port='$old_ports'\"");
       if($change!=""){
        $old_protocol=trim(shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"select protocol from router where port='$old_ports'\""));
          if ($old_regs!=""){               
               $old_range=($old_regs[2]-$old_regs[1])+1;
               for($rans=0;$rans<$old_range;$rans++){
                   $old_rn_port=$old_regs[1]+$rans;                 
                   if($old_protocol=="TCP/UDP"){                  
                      $del_old.="$old_rn_port TCP $old_rn_port UDP ";
                   }else{
                      $del_old.="$old_rn_port $old_protocol ";
                   }
               }
          }else{
               $del_old.="$old_ports $old_protocol ";
          }
       }   
       shell_exec("/img/bin/rc/rc.router setup \"$total\" \"$del_old\"");
       $status=trim(shell_exec("cat /tmp/setport_msg2"));
       if($status!="3"){
         if ($change!=""){         
            shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"delete from router where port='$old_ports'\"");   
         }
         if ($regs!=""){
               shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"insert into router(port,range_port,protocol,des) values('$regs[1]','$regs[2]','$protocol','$des')\"");
            }else{
               shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"insert into router(port,protocol,des) values('$ports','$protocol','$des')\"");
         }
       }else{
            shell_exec("/img/bin/rc/rc.router delete \"$total\"");
       }
       //$regs="";
    //}   
    
    //echo "123";
    die(json_encode(array(
        'code'=> 'save',
        'status'=> $status
    )));
case 'remove':
    $data = json_decode(stripcslashes($_REQUEST['params']), true);
    //for( $c = 0; $c <= count($data); $c++){
       $ports=$data[0][1];    
       
       if ($data[0][2]=="1"){
           $protocol="TCP";            
       }else if ($data[0][2]=="2"){
           $protocol="UDP";         
       }else if ($data[0][2]=="3"){
           $protocol="TCP/UDP";                
       }
       
       ereg("([0-9]{1,})-([0-9]{1,})",$ports,$regs); 
       if ($regs!=""){
           $range=($regs[2]-$regs[1])+1;           
           for($ran=0;$ran<$range;$ran++){
               $rn_port=$regs[1]+$ran;
               if($protocol=="TCP/UDP"){                  
                  $total.="$rn_port TCP $rn_port UDP ";
               }else{
                  $total.="$rn_port $protocol ";
               }
           }
           $ports=$regs[1];
       }else{
           if($protocol=="TCP/UDP"){
                $total.="$ports TCP $ports UDP ";
           }else{
                $total.="$ports $protocol ";
           }
       }
               
       shell_exec("/usr/bin/sqlite /etc/cfg/conf.db \"delete from router where port='$ports'\"");
       //$regs="";
    //}
    //echo "$total";
    shell_exec("/img/bin/rc/rc.router delete \"$total\"");
    $status=trim(shell_exec("cat /tmp/setport_msg2"));
    die(json_encode(array(
        'code'=> 'remove',
        'status'=> $status
    )));
}

?>
