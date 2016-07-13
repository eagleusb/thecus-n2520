<?php

$words = $session->PageCode("wireless");

require_once(INCLUDE_ROOT."info/wireless.class.php");
$wireless=new WIRELESS();
$wireless_list=$wireless->GetList();
$wpa_mode="1";

$bssid=trim($_REQUEST["bssid"]);
//$act=trim($_POST["act"]);
$act=trim($_REQUEST["act"]);



$protocol='';
$freq='';
$channel='';
if($bssid!=""){
  foreach($wireless_list as $key=>$value){
    if($value!=""){
      if(trim($value["Address"])==$bssid){
        $index=$key;
        break;
      }
    }
  }

  $ssid=trim($wireless_list[$index]["ESSID"]);
  $protocol=trim($wireless_list[$index]["Protocol"]);
  $freq=trim($wireless_list[$index]["Freq"]);
  $channel=trim($wireless_list[$index]["Channel"]);
}else{
  $ssid=trim($_POST["ssid"]);
}


if($act=="edit" && ($bssid!="" || $ssid!="")){
  $wireless_conf=$wireless->GetConf();
  $speed=$wireless_conf["conf_speed"];
  $auth=$wireless_conf["conf_auth"];
  $enc=$wireless_conf["conf_enc"];
  $wpa_key=$wireless_conf["conf_wpa_key"];
  $default_key=$wireless_conf["conf_default_key"];
  $wep_key1=$wireless_conf["conf_wep_key1"];
  $wep_key2=$wireless_conf["conf_wep_key2"];
  $wep_key3=$wireless_conf["conf_wep_key3"];
  $wep_key4=$wireless_conf["conf_wep_key4"];
}

$speed_list=array();
$speed_list[]=array('value'=>'auto','display'=>$words["auto"]);
foreach($wireless_list[$index]["Rate"] as $speed){
    if($speed!=""){
      $speed_list[]=array('value'=>$speed,'display'=>$speed);
  }
}
$speed_index='auto';
$auth_list="[['open_system','".$words['open_system']."'],['share_key','".$words['share_key']."']";

if($wpa_mode=="1"){
  $auth_list=$auth_list.",['wpa_psk','".$words['wpa_psk']."'],['wpa2_psk','".$words['wpa2_psk']."']";
}

$auth_list.="]";

$auth_index="share_key";

$open_system_enc="[['none','".$words["none"]."']]";
$share_key_enc="[[64,'".$words["wep_64"]."'],[128,'".$words["wep_128"]."']]";
$wpa_mode_enc="[['TKIP','".$words["tkip"]."'],['AES','".$words["aes"]."']]";
$default_key_data="[[1,'".$words["wepkey1"]."'],[2,'".$words["wepkey2"]."'],[3,'".$words["wepkey3"]."'],[4,'".$words["wepkey4"]."']]";


die(json_encode(array("wireless_conf"=>$wireless_conf,
                      "ssid"=>$ssid,
                      "protocol"=>$protocol,
                      "freq"=>$freq,
                      "channel"=>$channel,
                      "open_system_enc"=>$open_system_enc,
                      "share_key_enc"=>$share_key_enc,
                      "wpa_mode_enc"=>$wpa_mode_enc,
                      "default_key_data"=>$default_key_data,
                      "auth_list"=>$auth_list,
                      "speed_list"=>$speed_list,
                      "wpa_mode"=>$wpa_mode,
                      "auth_index"=>$auth_index,
                      "speed_index"=>$speed_index                    
)));
?>
