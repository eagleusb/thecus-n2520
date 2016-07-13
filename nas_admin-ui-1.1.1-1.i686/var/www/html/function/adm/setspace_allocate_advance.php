<?
include_once(INCLUDE_ROOT.'sqlitedb.class.php');
$words=$session->PageCode('raid');
$gwords=$session->PageCode('global');
$niscsi_block_size=$_POST['advance_iscsi_block_size'];
$niscsi_crc=$_POST['advance_iscsi_crc'];
$db=new sqlitedb();
$oiscsi_block_size=$db->getvar("advance_iscsi_block_size","9");
$oiscsi_crc=$db->getvar("advance_iscsi_crc","0");

if(($niscsi_block_size != $oiscsi_block_size) || ($niscsi_crc != $oiscsi_crc)){
  //echo "change iscsi_block_size<br>";
  $if_no_change="0";
  $db->setvar("advance_iscsi_block_size",$niscsi_block_size);		
  $db->setvar("advance_iscsi_crc",$niscsi_crc);
  unset($db);
  $fn=array('ok'=>'setCurrentPage("reboot");processUpdater("getmain.php","fun=reboot");');
  return MessageBox(true,$gwords['space_allocate'],$words['iSCSI_block_size_ready'],'INFO','OK',$fn);
}else{
  unset($db);
  return MessageBox(true,$gwords['space_allocate'],$gwords['setting_confirm']);
}











?>
