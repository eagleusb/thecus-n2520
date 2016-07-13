<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words = $session->PageCode("snmp");

$count=3;
$db = new sqlitedb();
//load UPS default value
$snmp_enabled=$db->getvar("snmp_enabled","0");
$snmp_read_comm=$db->getvar("snmp_read_comm","");
$snmp_sys_contact=$db->getvar("snmp_sys_contact","");
$snmp_sys_locate=$db->getvar("snmp_sys_locate","");
for($i=1;$i<=$count;$i++){
    if($i==1)
        $field="snmp_trap_target_ip";
    else
        $field="snmp_trap_target_ip".$i;

    $snmp_trap_target_ip[$i]=$db->getvar($field,"");
}
unset($db);
        
$tpl->assign('words',$words);
$tpl->assign('form_action','setmain.php?fun=setsnmp');
$tpl->assign('form_onload','onLoadForm');
$tpl->assign('snmp_enabled',$snmp_enabled);
$tpl->assign('snmp_read_comm',$snmp_read_comm);
$tpl->assign('snmp_sys_contact',$snmp_sys_contact);
$tpl->assign('snmp_sys_locate',$snmp_sys_locate);
$tpl->assign('snmp_trap_target_ip',$snmp_trap_target_ip);
?>
