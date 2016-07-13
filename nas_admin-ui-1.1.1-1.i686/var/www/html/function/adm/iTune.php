<?
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(WEBCONFIG);
$words = $session->PageCode("iTune");
$tpl->assign('words',$words);
$prefix=iTune;

$rescan_interval_fields="['value','display']";
$rescan_interval_data="[['60','1 minute'],['600','10 minutes'],['1800','30 minutes'],['3600','60 minutes'],['86400','1 day']]";

$encode_fields="['value','display']";

if (NAS_DB_KEY == '1')
    $encode_data="[['BIG5','BIG5'],['GBK','GBK'],['GB2312','GB2312'],['GB18030','GB18030'],['ISO_8859-1','ISO'],['EUC-JP','EUC-JP'],['SHIFT-JIS','SHIFT-JIS'],['EUC-KR','EUC-KR'],['UTF-8','UTF-8']]";
else
    $encode_data="[['BIG5','BIG5'],['GBK','GBK'],['GB2312','GB2312'],['GB18030','GB18030'],['ISO_8859-1','ISO'],['EUC-JP','EUC-JP'],['SHIFT-JIS','SHIFT-JIS'],['EUC-KR','EUC-KR'],['CP1251','CP1251'],['KOI8-R','KOI8-R'],['UTF-8','UTF-8']]";

$db=new sqlitedb();
$iTune=$db->getvar("iTune_iTune","0");
$nc1name=$db->getvar("nic1_hostname",$webconfig['product_no']);
$servername=$db->getvar("iTune_servername",$nc1name);

if(trim($servername) == ""){
  if(trim($nc1name) == ""){
    $servername=trim($webconfig['product_no']);    
  }else{
    $servername=trim($nc1name);    
  }   
}

$passwd=$db->getvar("iTune_passwd","");
$rescan_interval=$db->getvar("iTune_rescan_interval","1800");
$encode=$db->getvar("iTune_encode","ISO_8859-1");
$ha_enable=$db->getvar("ha_enable","0");

$tpl->assign($prefix.'_iTune',$iTune);
$tpl->assign($prefix.'_servername',$servername);
$tpl->assign($prefix.'_passwd',$passwd);
$tpl->assign($prefix.'_rescan_interval',$rescan_interval);
$tpl->assign($prefix.'_rescan_interval_fields',$rescan_interval_fields);
$tpl->assign($prefix.'_rescan_interval_data',$rescan_interval_data);
$tpl->assign($prefix.'_encode',$encode);
$tpl->assign($prefix.'_encode_fields',$encode_fields);
$tpl->assign($prefix.'_encode_data',$encode_data);
$tpl->assign('ha_enable',$ha_enable);

$tpl->assign('form_action','setmain.php?fun=set'.$prefix);
?>
