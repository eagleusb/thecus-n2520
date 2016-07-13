<?
include_once("/home/polson/www/transferDB.class.php");
$trans=new transDB();
//$trans->trans_bat("snmp","new_snmp");
$trans->trans_once("snmp","apply","new_snmp","apply");
?>
