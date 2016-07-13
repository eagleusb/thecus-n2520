<?php  
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');


$words = $session->PageCode("snmp");
$gwords = $session->PageCode("global");


$snmp_enabled=$_POST['_snmp_enabled'];
$snmp_read_comm=$_POST['_snmp_read_comm'];
$snmp_sys_contact=$_POST['_snmp_sys_contact'];
$snmp_sys_locate=$_POST['_snmp_sys_locate'];
$count=3;
for($i=1;$i<=$count;$i++){
    $snmp_trap_target_ip[$i]=$_POST['_snmp_trap_target_ip'.$i];
}

//if enable then check field
if($snmp_enabled=='1'){ 
  if(empty($snmp_read_comm))
    return  MessageBox(true,$gwords['error'],$words['empty_read_comm'],'ERROR'); 
  if(!$validate->general($snmp_read_comm))
    return  MessageBox(true,$gwords['error'],$words['alert_comm_limit'],'ERROR'); 

  for($i=1;$i<=$count;$i++){
    if(!$validate->ip_address($snmp_trap_target_ip[$i]) && !$validate->ipv6_address($snmp_trap_target_ip[$i]) && $snmp_trap_target_ip[$i]!='')
        return  MessageBox(true,$gwords['error'],$gwords['ip_error'],'ERROR'); 
  }
}

//read cifs and upnp original setting
$db=new sqlitedb();
$db->setvar('snmp_enabled',$snmp_enabled);

//if snmpd disabled dont change the setting
if($snmp_enabled){
  $db->setvar("snmp_read_comm",$snmp_read_comm);
  $db->setvar("snmp_sys_contact",$snmp_sys_contact);
  $db->setvar("snmp_sys_locate",$snmp_sys_locate);
  for($i=1;$i<=$count;$i++){
      if($snmp_trap_target_ip[$i]==""){
         for($j=$i+1;$j<=$count;$j++){
             if($snmp_trap_target_ip[$j]!=""){
                 $snmp_trap_target_ip[$i]=$snmp_trap_target_ip[$j];
                 $snmp_trap_target_ip[$j]="";
                 break;
             }
         }
      }
  }
  for($i=1;$i<=$count;$i++){
      if($i==1)
          $field="snmp_trap_target_ip";
      else
          $field="snmp_trap_target_ip".$i;
                              
      $db->setvar($field,$snmp_trap_target_ip[$i]);
  }

  $conf=fopen("/etc/snmpd.conf","w");
  if($conf){
    flock($conf,2);
    fwrite($conf,"syslocation $snmp_sys_locate\n");
    fwrite($conf,"syscontact $snmp_sys_contact\n");
    fwrite($conf,"rocommunity $snmp_read_comm");
    flock($conf,3);
    fclose($conf);
  }
}
unset($db);


if($snmp_enabled){
  shell_exec("/img/bin/rc/rc.snmpd restart > /dev/null 2>&1");
}else{
  shell_exec("/img/bin/rc/rc.snmpd stop > /dev/null 2>&1");
}
return  MessageBox(true,$gwords['success'],$words['serviceSuccess']); 
?> 
