<?
//###############################################################
//#	Destribution : 
//#	Input : No
//#	Output : firmware version
//###############################################################
function getFWVersion() {
	$fileName="/etc/version";
	$version="";
	if (file_exists($fileName)) {
		$aryFile=file($fileName);
		$version=trim($aryFile[0]);
	}
	return $version;
}

//###############################################################
//#	Destribution : Get firmware type and producer from /etc/manifest.txt
//#	Input : No
//#	Output : manifest array
//###############################################################
function getManifest() {
	$fileName="/etc/manifest.txt";
	$aryManifest="";
	if (file_exists($fileName)) {
		$aryFile=file($fileName);
		$FWTYPE=trim($aryFile[0]);
		$FWPRODUCER=trim($aryFile[1]);
		$aryData=explode("type",$FWTYPE);
		$FWTYPE=trim($aryData[1]);
		$aryData=explode("producer",$FWPRODUCER);
		$FWPRODUCER=trim($aryData[1]);
		
		$aryManifest=array("FWTYPE" => $FWTYPE, "FWPRODUCER" => $FWPRODUCER);
	}
	return $aryManifest;
}

//###############################################################
//#	Destribution : Get sysconf from /img/bin/sysconf0.txt
//#	               or /img/bin/sysconf1.txt
//#	Input : No
//#	Output : sysconf array
//###############################################################
function get_sysconf(){
  global $thecus_io,$sysconf;
  $thecus_io_array=file("/proc/thecus_io");
  $thecus_io=array();
  foreach($thecus_io_array as $line){
    if($line!=""){
      $line_array=explode(":",$line);
      $thecus_io[trim($line_array[0])]=trim($line_array[1]);
    }
  }
  if (NAS_DB_KEY == '1'){
  	$sysconf_array=file("/img/bin/conf/sysconf".$thecus_io["MBTYPE"].".txt");
  }else{
  	$sysconf_array=file("/img/bin/conf/sysconf.".$thecus_io["MODELNAME"].".txt");
  }
  $sysconf=array();
  foreach($sysconf_array as $line){
    if($line!=""){
      $line_array=explode("=",$line);
      $sysconf[trim($line_array[0])]=trim($line_array[1]);
    }
  }
}

//###############################################################
//# Destribution : Get hwinfo from /tmp/hwinfo
//# Input : No
//# Output : hwinfo array
//###############################################################
function get_hwinfo() {
  global $hwinfo;

  $hwinfo = array();
  $hwinfo = file("/tmp/hwinfo");
  for($i = 0; $i < count($hwinfo); $i++) {
    $hwinfo[$i] = trim(ereg_replace("\(.*.\)", "", $hwinfo[$i]));
  }
}

//###############################################################
//#	Destribution : Check sysconf service
//#	               if service = 0, then exit
//#	               else service != 0, then contiune
//#	Input : $value => 0 = service disable
//#	                  >= 1 service enable
//#	        $msg => Show this message on the UI
//#	        $gopage => Press "OK", then go to which page
//#         $in_type=>enter type,0:admin 1:xplorer 2:photo server
//#	Output : Show messages
//###############################################################
function check_system($value,$msg,$gopage,$in_type=0){
  global $session;
  $words = $session->PageCode('global');
  $message=$words[$msg];    
  if($value=="0" || $value==""){
    if($in_type==0){
      $fn=array('ok'=>'setCurrentPage("'.$gopage.'");processUpdater("getmain.php","fun='.$gopage.'");');
      $ary = json_encode( array("show"=>true,    
                       "topic"=>$words["warning"], 
                       "message"=>$message,                
                       "icon"=>'WARNING',                  
                       "button"=>'OK',                     
                       "fn"=>$fn,                                                    
                       "prompt"=>''));                     
      die($ary);
    }else if($in_type==1){
    }else{
      $url=$gopage;
      $a=new msgBox("$message","OKOnly",$words["warning"]);
      $a->makeLinks(array($url));
      echo "
      <html><head>
      </head><body>";
      $a->showMsg();
      flush();
      exit;
    } 
  }
}


//###############################################################
//#	Destribution : Check migrate RAID whether exist --> enian
//#	Input : No
//#	Output : if Migrate RAID exist then return 0
//#	         else Migrate RAID not exist then return 1
//###############################################################
function check_migrate_exist()
{
  require_once("/var/www/html/inc/info/raidinfo.class.php");
	$migrate_raid = new RAIDINFO();
	$migrate_raid->setmdselect(0);
  $migrate_md_array = $migrate_raid->getMdArray();   
  
  foreach($migrate_md_array as $md_num)
  {
  	$md_num = $md_num - 1;   	
		$strExec = "cat /raid" . (string)$md_num . "/sys/migrate/lock";		
		$md_migrate_lock_check = shell_exec($strExec);  
		if($md_migrate_lock_check == 1)
    	return 0;		
  }

/*  $strExec = "cat /var/tmp/raidlock";
  $md_migrate_lock_check = shell_exec($strExec);  
	if($md_migrate_lock_check == 1)
  	return 0;
*/	
	return 1;
}
//###############################################################
//#	Destribution : Check migrate RAID whether exist  ---> enian
//#	Input : No
//#	Output : if Migrate RAID exist then return 0
//#	         else Migrate RAID not exist then return 1
//###############################################################
function check_migrate()
{
	$check_migrate_exist=check_migrate_exist();
  check_system($check_migrate_exist,"raid_migrate_exist_warning","raid");
}

//###############################################################
//#	Destribution : Check user sysconf service            ---->enian
//#	               if service = 0, then exit
//#	               else service != 0, then contiune
//#	Input : $value => 0 = service disable
//#	                  >= 1 service enable
//#	        $msg => Show this message on the UI
//#	        $gopage => Press "OK", then go to which page
//#	Output : Show messages
//###############################################################
function check_system_user($value,$msg,$gopage){
    check_system($value,$msg,$gopage,2);
/*  if($value=="0" || $value==""){
    require_once("/var/www/html/htdocs/setlang/lang.html");
    require_once("/var/www/html/inc/msgbox.inc.php");
    $words = PageCode('function');
    $topic=$words[$msg];
    $url=$gopage;
    $a=new msgBox("$topic","OKOnly",$words["warning"]);
    $a->makeLinks(array($url));
    echo "
    <html><head>
    </head><body>";
    $a->showMsg();
    flush();
    exit;
  }*/
}

//###############################################################
//#	Destribution : Check migrate RAID whether exist  ---> enian
//#	Input : No
//#	Output : if Migrate RAID exist then return 0
//#	         else Migrate RAID not exist then return 1
//###############################################################
function check_system_usermode($con_url)
{
   $check_raid_exist=check_raid_exist();
   check_system_user($check_raid_exist,"raid_exist_warning",$con_url);
   $check_raid_lock=check_raid_lock();
   check_system_user($check_raid_lock,"raid_lock_warning",$con_url);
}

//###############################################################
//# Destribution : Check RAID Encrypt
//# Input : No
//# Output : if RAID Encrypted,show need usb key plug in
//#
//###############################################################
function check_useencrypt($md_num){
  $raid_num = $md_num - 1;
  $sys_path="/raid$raid_num/sys";
  $strExec="/bin/mount | grep $sys_path";
  $mount_sys=shell_exec($strExec);
  if($mount_sys!=""){
    $strExec="/usr/bin/sqlite $sys_path/raid.db \"select v from conf where k='encrypt'\"";
    $use_encrypt=shell_exec($strExec);
  }

  if($use_encrypt){
    return 1;
  }else{
    return 0;
  }
}

function check_mountencrypt($md_num){
  $raid_num = $md_num - 1 ;
  $data_path="/raid$raid_num/data";
  $strExec="/bin/mount | grep $data_path";
  $mount_data=shell_exec($strExec);
  if($mount_data==""){
    return 0;
  }
  return 1;
}

function check_encrypt($md_num,$msgbox){
  $check_useencrypt=check_useencrypt($md_num);
  if($check_useencrypt){
    $check_mountencrypt=check_mountencrypt($md_num);
    if($check_mountencrypt!=1){
      if($msgbox ==1)
        check_system($check_mountencrypt,"encrypt_start","raid",0);
      else
        return $check_mountencrypt;
    }else
      return $check_mountencrypt;
  }else
   return 1;
}

function check_usbkey_exist($md_num,$msgbox){
  $raid_num = $md_num - 1;
  $sys_path="/raid$raid_num/sys";
  $strExec="/bin/mount | grep $sys_path";
  $mount_sys=shell_exec($strExec);
  if($mount_sys!=""){
    $strExec="/usr/bin/sqlite $sys_path/raid.db \"select v from conf where k='encrypt'\"";
    $use_encrypt=shell_exec($strExec);
    if($use_encrypt){
      $strExec="/usr/bin/sqlite $sys_path/raid.db \"select v from conf where k='keyname'\"";
      $key_filename=shell_exec($strExec);
      $strExec="find /raid[0-9]/data/usbhdd/ | grep $key_filename";
      $mount_key=shell_exec($strExec);
      if($mount_key){
          $got_key = 1;
      }else{
      	  $strExec="find /mnt/usb/ | grep $key_filename";
          $mount_key=shell_exec($strExec);
          if($mount_key){
          	$got_key = 1;
          }else{
            $got_key = 0;
          }
      }
      if($msgbox==1)
        check_system($got_key,"encrypt_keyplug","raid",0);
      else
        return $got_key;
    }else
      return 1;
  }
  return 0;
}

function check_usbrw(){
  $ret=shell_exec("/img/bin/check_usbrw.sh");
  if($ret){
    $usb_rw=1;
  }else{
    $usb_rw=0;
  }
  check_system($usb_rw,"usbkey_ro","raid",0);
}
  
//###############################################################
//#	Destribution : Check RAID whether exist
//#	Input :in_type:enter type :0:admin 1:xplorer  2:poto server 
//#	Output : if RAID exist then return 1
//#	         else RAID not exist then return 0
//###############################################################
function check_raid($in_type){
  $check_raid_exist=check_raid_exist();
  check_system($check_raid_exist,"raid_exist_warning","raid",$in_type);
  $check_raid_lock=check_raid_lock();
  check_system($check_raid_lock,"raid_lock_warning","raid",$in_type);
}

//###############################################################
//#	Destribution : Check RAID Lock
//#	Input : No
//#	Output : if RAID Lock = 1 return 1
//#	         else RAID Lock = 0 then return 0
//###############################################################
function check_raid_lock(){
  $raid_lock=trim(file_get_contents("/var/tmp/raidlock"));
  if($raid_lock!="0"){
    return 0;
  }
  return 1;
}

//###############################################################
//#	Destribution : Check RAID whether exist
//#	Input : No
//#	Output : if RAID exist then return 1
//#	         else RAID not exist then return 0
//###############################################################
function check_raid_exist(){
  $strExec="/bin/ls -l /raid/sys | awk -F' ' '{printf $11}'";
  $sys_path=shell_exec($strExec);
  $strExec="/bin/ls -l /raid/data | awk -F' ' '{printf $11}'";
  $data_path=shell_exec($strExec);
  if($sys_path=="" || $data_path==""){
    return 0;
  }
  $strExec="/bin/mount | grep $sys_path";
  $mount_sys=shell_exec($strExec);
  $strExec="/bin/mount | grep $data_path";
  $mount_data=shell_exec($strExec);
  if (NAS_DB_KEY == '1'){
	  if($mount_sys=="" || $mount_data==""){
	    return 0;
	  }
  }else{
    return 1;
	  if($mount_data==""){
	    return 0;
	  }
  }
  return 1;
}

//###############################################################
//#	Destribution : check HA RAID whether exist
//#	Input : No
//#	Output : if RAID exist then return 1
//#	         else RAID not exist then return 0
//###############################################################
function check_ha_raid_exists(){	
	$handle = popen("find /raidsys/ -name ha_raid | wc -l",'r');
	$ha_raid = trim(fread($handle, 4096));
	pclose($handle);		
	if(is_dir('/raid/data') || ($ha_raid != "0")){
		return 1;
	}else{
		return 0;
	}
}	
//###############################################################
//#	Destribution : Check HA RAID whether exist
//#	Input :in_type:enter type :0:admin 1:xplorer  2:poto server 
//#	Output : if RAID exist then return 1
//#	         else RAID not exist then return 0
//###############################################################
function check_ha_raid($in_type){                 
    $db = new sqlitedb();                     
    $enable = $db->getvar('ha_enable',0);   
	unset($db);     
    if($enable == '0'){	
    	 $check_ha_raid_exist=check_ha_raid_exists();          
    	 if ($check_ha_raid_exist == 0){
             check_system(0,"raid_exist_warning","raid",$in_type);
         }else{
  	     $handle = popen("cat /proc/mdstat | grep -c '^md[0-9] : '",'r');
	     $raid_count = trim(fread($handle, 4096));
	     pclose($handle);
	     if ($raid_count == 0){
	         check_system(0,"raid_exist_warning","raid",$in_type);
	     }else if ($raid_count == 1){
	         check_system(1,"raid_exist_warning","raid",$in_type);
	     }else{
	         check_system(0,"error_multi_ha","raid",$in_type);
	     }
         }
    }
} 
//###############################################################
//
//###############################################################
function check_ha_wan($in_type){                 
    $db = new sqlitedb();                     
    $dhcp = $db->getvar('nic1_ipv4_dhcp_client');  
    $dns_dhcp =  $db->getvar('nic1_dns_type');
     
    unset($db); 
    if($dns_dhcp == '1'){           
         check_system(0,"ha_dhcp_warning","wan",$in_type);
    }else{
        $is_bond=trim(shell_exec("/img/bin/function/get_interface_info.sh 'check_eth_bond' 'eth0'"));
        if( $is_bond == "" ){
            if($dhcp == '1'){           
                 check_system(0,"ha_dhcp_warning","wan",$in_type);
            }
        }
    }
} 



//###############################################################
//# Destribution : Check upgrade is running or not
//# Input :in_type:enter type :0:admin 1:xplorer  2:poto server 
//# Output : if RAID exist then return 1
//#          else RAID not exist then return 0
//###############################################################
function check_upgrade(){
    require_once(INCLUDE_ROOT.'upgrade.class.php');
    $upgrade = new Upgrade();
    if( isset($_SESSION['PageCode']) && $upgrade->isUpgrading() && ( $_SESSION['PageCode'] != 'updfw' )) {
        $lang = $_SESSION["lang"];
        
        $db = new sqlitedb();
        $db->db_open(LANG_DB);
        $sql =  'SELECT A.treeid cateid, B.treeid treeid, D.msg catename, A.value tree, B.value value, B.fun fun, C.msg treename '.
                'FROM treemenu A, '.$lang.' D '.
                'INNER JOIN treemenu B ON A.treeid = B.cateid '.
                'INNER JOIN '.$lang.' C ON B.value = C.value '.
                'WHERE A.value = D.value AND B.fun = "updfw" '.
                'ORDER BY A.treeid, B.treeid';

        $data = $db->runSQL($sql);
        $db->db_close();

        $js = sprintf('TreeMenu.setCurrentPage("false","%s", "%s", "%s", "%s", "%s")',$data['fun'], $data['treeid'], $data['treename'],$data['cateid'], $data['catename']);
        die($js);
    }
}

//###############################################################
//#	Destribution : Check URL format must have getform.html
//#	Input : No
//#	Output : if URL match, then contiune
//#	         else show warning message
//###############################################################
function check_url(){
  $url=$_SERVER["SCRIPT_URI"];
  if(!preg_match("/getform.html/",$url)){
    check_system("0","access_warning","about");
  }
}

//###############################################################
//#	Destribution : Get total folder 
//#	               (smb.conf and stackable.db)
//#	Input : $flag => decide get total_folder 
//#                  or raid folder (not contain stackable)
//#	Output : folder array
//############################################################### 
function get_total_folder($flag=0){
  require_once(INCLUDE_ROOT.'validate.class.php'); 
  $validate=new validate();
  //#######################################################
  //#     Get smb.conf folder list
  //#######################################################
  $smb_file="/etc/samba/smb.conf";
  $smb_list_array=file($smb_file);
  $validate = new validate();
  foreach($smb_list_array as $k=>$data){
    if($data!="" && preg_match("/^\[/",$data) && !preg_match("/global/",$data)){
      $data=trim($data);
      $smb_folder_name=substr($data,1,(strlen($data)-2));
      
      // hide special system folder
      if($validate->hide_system_folder($smb_folder_name)){
         continue; 
      }    
      $total_folder[]=$smb_folder_name;
    }
  }
  //#######################################################
  //#     Get stackable folder which is disable
  //####################################################### 
  $stack=array();
  $is_stackable=shell_exec("/usr/bin/sqlite ".SYSTEM_DB_ROOT."stackable.db .tables | grep stackable"); 
  if($is_stackable!=""){
    $database = SYSTEM_DB_ROOT."stackable.db";
    $db = new sqlitedb($database);  
    $db_disable=$db->db_get_folder_info("stackable","*","");
    $db->db_close($database);

    foreach($db_disable as $k=>$data){
      if($data!=""){
        $stack[]=trim($data["share"]);
      }
    }
  }
  //#######################################################
  switch($flag){
    case 1:
      $total_folder=array_diff($total_folder, $stack);
      break;
    default:
      $total_folder=array_merge($total_folder, $stack);
      break;
  }
  
  $total_folder=array_unique($total_folder);
  return $total_folder;
}


//###############################################################
//#	Destribution : Check samba enable/disable
//#	Input : No
//#	Output : 0 => samba disable
//#	         1 => samba enable
//###############################################################
function check_samba(){
  $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='httpd_nic1_cifs'\"";
  $samba_enabled=trim(shell_exec($strExec));
  return $samba_enabled;
}

//###############################################################
//#     Destribution : Check LDAP service
//#     Input : No
//#     Output : 0 => LDAP not been start
//#              1 => LDAP is start
//###############################################################
function check_ldap(){
  $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='ldap_enabled'\"";
  $ldap_service=trim(shell_exec($strExec));
  if($ldap_service=="" || $ldap_service=="0" ){
     return 0;
  }else{
     return 1;
  }
}

//###############################################################
//#     Destribution : Check ADS service
//#     Input : No
//#     Output : 0 => ADS not been start
//#              1 => ADS is start
//###############################################################
function check_ads(){
  $strExec="/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='winad_enable'\"";
  $ads_service=trim(shell_exec($strExec));
  if($ads_service=="" || $ads_service=="0" ){
     return 0;
  }else{
     return 1;
  }
}

//###############################################################
//#	Destribution : Check samba service
//#	Input : No
//#	Output : 0 => samba not been start
//#	         1 => samba is start
//###############################################################
function check_samba_service(){
  $strExec="/bin/ps aux | grep \"/usr/sbin/smbd\" | grep -v grep";
  $samba_service=trim(shell_exec($strExec));
  if($samba_service==""){
    return 0;
  }else{
    return 1;
  }
}

//###############################################################
//#	Destribution : String abbreviation
//#	Input : $string = string
//#	        $limit = limit string length
//#		$havedot = add ... in string
//#	Output : abbreviation string
//###############################################################
function mb_abbreviation($string, $limit, $havedot=0, $last_limit=0) {
  //check len
  $string = html_entity_decode($string, ENT_QUOTES, 'UTF-8');
  $len = strlen($string);
  if(strlen($string) <= ($limit+$last_limit)) {
    return $string;
  }
  $wordscut = '';
  //if(strtolower($charset) == 'utf-8') {
    //utf8 encode
    $n = 0;
    $tn = 0;
    $noc = 0;
    while ($n < strlen($string)) {
      $t = ord($string[$n]);
      //echo "t = $t<br>";
      if($t == 9 || $t == 10 || ($t >= 32 && $t <= 126)) {
        $tn = 1;
        $n++;
        $noc++;
      } elseif(194 <= $t && $t <= 223) {
        $tn = 2;
        $n += 2;
        $noc += 2;
      } elseif(224 <= $t && $t < 239) {
        $tn = 3;
        $n += 3;
        $noc += 2;
      } elseif(240 <= $t && $t <= 247) {
        $tn = 4;
        $n += 4;
        $noc += 2;
      } elseif(248 <= $t && $t <= 251) {
        $tn = 5;
        $n += 5;
        $noc += 2;
      } elseif($t == 252 || $t == 253) {
        $tn = 6;
        $n += 6;
        $noc += 2;
      } else {
        $n++;
      }
      //echo "tn = $tn<br>";
      if ($noc >= $limit) {
        break;
      }
    }
    //echo "$len ==== $noc ==== $limit ==== $string<br>";
    if ($noc > $limit) {
      $n -= $tn;
    }
    $wordscut = substr($string, 0, $n);
    //echo "str = $wordscut<br>";
  /*
  } else {
    for($i = 0; $i < $limit - 3; $i++) {
      if(ord($string[$i]) > 127) {
        $wordscut .= $string[$i].$string[$i + 1];
        $i++;
      } else {
        $wordscut .= $string[$i];
      }
    }
  }
  */
  //...
  //echo "==========================================<br>";
  if($last_limit!="0"){
    $laststr=substr($string,-${last_limit});
  }else{
    $laststr="";
  }
  if($havedot && $string!=$wordscut) {
  //if($havedot) {
    return $wordscut.'...'.$laststr;
  } else {
    return $wordscut;
  }
}
 
//###############################################################
//#	Destribution : Check critical process
//#	Input : Formatting,Migrating,Expand
//#	Output : 0 => Contiune
//#	         1 => Show warning message
//###############################################################
function check_process($string){
  $deny_status=explode(",",$string);
  $strExec="ls /var/tmp | grep -v raidlock | awk -F '/' '/raid/{printf(\"%s,\",$1)}'";
  $raid_list=shell_exec($strExec);
  $raid_list=explode(",",$raid_list);
  foreach($raid_list as $raid){
    if($raid!=""){
      foreach($deny_status as $v){
        $strExec="grep \"$v\" /var/tmp/${raid}/rss";
        $ret=shell_exec($strExec);
        if($ret){
          return 1;
        }
      }
    }
  }
  return 0;
}

//###############################################################
//#	Destribution : Check user folder
//#	Input : No
//#	Output : 0 => None of user folder
//#	         1 => one or more user folder
//###############################################################
function check_user_folder(){
  //#######################################################
  //#     Get smb.conf folder list
  //#######################################################
  $smb_file="/etc/samba/smb.conf";
  $smb_list_array=file($smb_file);
  $isUserFolder=0;
  foreach($smb_list_array as $k=>$data){
    if($data!="" && preg_match("/\[/",$data) 
    							&& !preg_match("/global/",$data) 
    							&& !preg_match("/nsync/",$data)
    							&& !preg_match("/usbhdd/",$data)
    							&& !preg_match("/usbcopy/",$data)
    							&& !preg_match("/naswebsite/",$data)
    							&& !preg_match("/snapshot/",$data)
    							){
      $data=trim($data);
      $smb_folder_name=substr($data,1,(strlen($data)-2));
      $total_folder[]=$smb_folder_name;
      $isUserFolder=1;
    }
  }
  return $isUserFolder;
}

//###############################################################
//#	Destribution : Check ZFS RAID count is 3
//#	Input : 
//#	Output : 0 => Contiune
//#	         1 => Show warning message
//###############################################################
function check_zfs_count(){
  global $zfs_limit;
  $zfs_limit=1;
  $strExec="ls /var/tmp | grep -v raidlock | awk -F '/' '/raid/{printf(\"%s,\",$1)}'";
  $raid_list=shell_exec($strExec);
  $raid_list=explode(",",$raid_list);
  $zfs_count=0;
  foreach($raid_list as $raid){
    if($raid!=""){
      $strExec="/usr/bin/sqlite /${raid}/sys/raid.db \"select v from conf where k='filesystem'\"";
      $fsmode=trim(shell_exec($strExec));
      if($fsmode=="zfs"){
        $zfs_count=$zfs_count+1;
      }
    }
  }
  if($zfs_count<$zfs_limit){
    return 0;
  }else{
    return 1;
  }
}


//###############################################################
//#	Destribution : Decode string from javascript escape
//#	@param: $str        
//#	@param: charactor code (utf8)
//###############################################################
function uniDecode($str,$charcode){                               
  $text = preg_replace_callback("/%u[0-9A-Za-z]{4}/",toUtf8,$str);                 
  return mb_convert_encoding($text, $charcode, 'utf-8');
}        
            
//###############################################################
//#	Destribution : Change to UTF-8 format
//#	@param: $str         
//###############################################################             
function toUtf8($ar){                                                    
   foreach($ar as $val){              
       $val = intval(substr($val,2),16);   
       if($val < 0x7F){        // 0000-007F                     
             $c .= chr($val);                          
       }elseif($val < 0x800) { // 0080-0800
             $c .= chr(0xC0 | ($val / 64));
             $c .= chr(0x80 | ($val % 64));
       }else{                // 0800-FFFF       
             $c .= chr(0xE0 | (($val / 64) / 64));
             $c .= chr(0x80 | (($val / 64) % 64));        
             $c .= chr(0x80 | ($val % 64));                
       }                                                 
   }                                                  
   return $c;                         
}

//###############################################################
//#	Destribution : Check DHCP Range 
//#	@param: $str         
//############################################################### 
function check_dhcp_range($ip,$netmask,$startip,$endip){
	if($startip==$endip){
		return -1;
	}
	$mask_item=explode(".",$netmask);
	$ip_item=explode(".",$ip);
	for($c=0;$c<count($mask_item);$c++){
		if(intval($mask_item[$c])!=255){
			$subnet=$c;
			break;
		}
	}
	$range=intval($mask_item[$subnet]) ^ 255;
	$startip_item=explode(".",$startip);
	$endip_item=explode(".",$endip);
	
	for($c=0;$c<$subnet;$c++){
		if(intval($startip_item[$c])!=intval($ip_item[$c]) || intval($endip_item[$c])!=intval($ip_item[$c])){
			//return "RANGE ERROR";
			return -2;
		}
	}
	for($c=$subnet;$c<4;$c++){
		$sip_item=intval($startip_item[$c]);
		$eip_item=intval($endip_item[$c]);
		if($sip_item==$eip_item){
			$subnet++;
			$range=255;
		}
		if(($sip_item > $eip_item) || ($sip_item > $range) || ($eip_item > $range)){
			//return "ERROR RANGE".$sip_item." == ".$eip_item." == ".$range;
			return -1;
		}
		
	}
	return 0;
}

//###############################################################
//#	Destribution : Get Ten GB info in ifconfig
//#	@param: $str         
//############################################################### 
function get_tengb($nickname){  
  if (($nickname=="eth") || ($nickname=="geth")){
    $tengb_data=shell_exec("/sbin/ifconfig -a | awk '/^eth[0-9]/||/^geth[0-9]/{if($1!=\"eth0\" && $1!=\"eth1\" && $1!=\"eth2\") print $1}'");
  }else{
    $tengb_data=shell_exec("/sbin/ifconfig -a | awk '/^".$nickname."/{print $1}'");
  }
  
  $tengb_list=explode("\n",$tengb_data);  
  return $tengb_list; 
}


//###############################################################
//#	Destribution : get ODM value from webconfig
//#	@param: array webconfig        
//#	@param: array gwords
//############################################################### 
function getWebConfigODM($webconfig,$gwords)
{
	$item = array();
	$dbODM = new sqlitedb(); 
	$i=0;
	foreach($webconfig['odm'] as $k => $v){
		 if($v=='1'){
		 	 $item[$i]['id']=$i;
		 	 $item[$i]['name']=substr($k,0,strlen($k)-4);
		 	 $item[$i]['val']=$dbODM->getvar($item[$i]['name'],"1");
		 	 
		 	 switch($item[$i]['name'])
		 	 {
			 	 case "webdisk": 
		 	  		 $item[$i]['lang']=$gwords['web_disk'];
			 		 break;
			 	 case "photoserver": 
		 	 		 $item[$i]['lang']=$gwords['photo_server'];
			 		 break;
			 	 default: 
					$item[$i]['lang']=$gwords[$item[$i]['name']]; 
		 	 } 
		 	 
		 	 $redirect_original = $webconfig[$item[$i]['name']]['successurl'];
		 	 $redirect_update = $webconfig[$item[$i]['name']]['successurl_2']; 
		 	 
		 	 if(($webconfig[$item[$i]['name']]['enable'] != "Yes")) {
		 	 	$item[$i]['redirection']="";
		 	 }else{ 
			 	$item[$i]['redirection']= (!empty($redirect_update)) ? $redirect_update : $redirect_original;
		 	 	$item[$i]['redirection'] = "http://".$_SERVER["SERVER_NAME"]."/".$item[$i]['redirection'];
		 	 }
		 	 $i++;
		 }
	}  
	unset($dbODM); 
	return $item;
} 

//#################################################
//#	Destribution : Get day store data
//# @Output: day array
//#################################################
function getDayStore() {
	$day_fields = "['display', 'value']";
	$day_data = "[";
	for($i=1; $i <= 31; $i++){
		$_day=$i;
		$day_data .= "['$_day','$_day']";
		if ($i<31) {
			$day_data .= ",";
		}
	}
	$day_data .= "]";

	return array(
		"day_fields"=>$day_fields,
		"day_data"=>$day_data
	);
}

//#################################################
//#	Destribution : Get week store data
//# @Output: week array
//#################################################
function getWeekStore($gwords) {
	$week_fields="['display', 'value']";
	$week_day_list=array(
		"0"=>$gwords['sunday'],
		"1"=>$gwords['monday'],
		"2"=>$gwords['tuesday'],
		"3"=>$gwords['wednesday'],
		"4"=>$gwords['thursday'],
		"5"=>$gwords['friday'],
		"6"=>$gwords['saturday']
	);
	$week_data="[";
	foreach($week_day_list as $value=>$display) {
		if($display!="") {
			if($default_week == "") {
				$default_week = $display;
			}
			$week_data .= "['$display','$value'],";
		}
	}
	$week_data = substr($week_data,0,strlen($week_data)-1);
	$week_data .= "]";
	
	return array(
		"week_fields"=>$week_fields,
		"week_data"=>$week_data
	);
}

//#################################################
//#	Destribution : Get time store data
//# @Output: time array
//#################################################
function getTimeStore() {
	// hour
	$hour_fields="['display', 'value']";
	$hour_data="[";
	for($i=0;$i < 24;$i++){
		$_hour=$i;
		$hour_data .= "['$_hour','$_hour']";
		if ($i<23) {
			$hour_data .= ",";
		}
	}
	$hour_data .= "]";
	
	// minute
	$min_fields="['display', 'value']";
	$min_data="[";
	for($i=0;$i < 60;$i++){
		$_min=$i;
		$min_data .= "['$_min','$_min']";
		if ($i<59) {
			$min_data .= ",";
		}
	}
	$min_data .= "]";

	return array(
		"hour_fields"=>$hour_fields,
		"hour_data"=>$hour_data,
		"min_fields"=>$min_fields,
		"min_data"=>$min_data
	);
}

//#################################################
//#	Destribution : Add a new crond job into /etc/cfg/crond.conf
//# @return: true or false
//#################################################
function addCrondJob($crond_job, $schedule) {
	if (empty($crond_job) || empty($schedule)) {
		return false;
	}

	exec("cat ".CROND_CONF_PATH." | grep ".$crond_job, $out, $ret);
	if ($ret == 0) {
		// crond job has been existed
		return false;
	}
	
	exec("echo '$schedule $crond_job' >> ".CROND_CONF_PATH, $out, $ret);
	
	return true;
}

//#################################################
//#	Destribution : Update crond job from /etc/cfg/crond.conf
//# @return: true or false
//#################################################
function modifyCrondSchedule($crond_job, $schedule_new) {
	if (empty($crond_job) || empty($schedule_new)) {
		return false;
	}
	
	delCrondJob($crond_job);
	addCrondJob($crond_job, $schedule_new);
	
	return true;
}

//#################################################
//#	Destribution : Delete crond job from /etc/cfg/crond.conf
//# @return: true or false
//#################################################
function delCrondJob($crond_job) {
	if (empty($crond_job)) {
		return false;
	}
	
	$crond_tmp = CROND_CONF_PATH.".".date("U");
	$cmd = "cat ".CROND_CONF_PATH." |grep -v '".$crond_job."' > ".$crond_tmp;
	exec($cmd, $out, $ret);
	if ($ret != 0 && !empty($out)) {
		return false;
	}
	chmod($crond_tmp, 644);
	rename($crond_tmp, CROND_CONF_PATH);
	
	return true;
}

//#################################################
//#	Destribution : Replace crontab from stdin after
//# calling addCrondJob(), modifyCrondJob() or 
//# delCrondJob().
//#################################################
function resetCrond() {
	shell_exec("cat ".CROND_CONF_PATH." | /usr/bin/crontab - -u root");
}

/**
 * This function will query all public methods in given class.
 *
 * @param {String} $class
 */
function EnumRPC($class) {
    $refl = new ReflectionClass($class);
    $public = $refl->getMethods(ReflectionMethod::IS_PUBLIC);
    $methods = array();
    for( $i = 0 ; $i < count($public) ; $i++ ) {
        if( $public[$i]->name != "__constructor" && $public[$i]->name != "fireEvnet" ) {
          array_push($methods, $public[$i]->name);
        }
    }
    return $methods;
}

/**
 * This function will try to invoke method in given class.
 * 
 * @param {String} $class
 **/
function InvokeRPC($class) {
  $action = $_POST['action'];
  if( method_exists($class, $action) ) {
      $params = json_decode(stripslashes($_POST['params']), true);
      
      $result = call_user_func_array(array($class, $action), $params);
      array_unshift($result, $action);
      die(json_encode($result));
  }
}

//#################################################
//# Destribution : Change RAID Status Language
//# @return: Other Language
//#################################################
function changeLanguage($raid_status) {
    global $session;
    $gwords = $session->PageCode('global');
    
    if (preg_match("/^Healthy/",$raid_status)) {
        $raid_status=str_ireplace('Healthy',$gwords["healthy"],$raid_status);
    }else if (preg_match("/^Degraded/",$raid_status)) {
        $raid_status=str_ireplace('Degraded',$gwords["degraded"],$raid_status);
    }else if (preg_match("/^Damaged/",$raid_status)) {
        $raid_status=str_ireplace('Damaged',$gwords["damaged"],$raid_status);
    }else if (preg_match("/formatting/",$raid_status)) {
        $raid_status=$gwords["format"];
    }else if (preg_match("/^Migrating/",$raid_status)) {
        $raid_status=str_ireplace('Migrating RAID',$gwords["migrate_raid"],$raid_status);
    }else if (preg_match("/^Constructing/",$raid_status)) {
        $raid_status=str_ireplace('Constructing',$gwords["construct"],$raid_status);
    }else if (preg_match("/^Recovering/",$raid_status)) {
        $raid_status=str_ireplace('Recovering',$gwords["recover"],$raid_status);
    }else if (preg_match("/^Build/",$raid_status) || preg_match("/^Building/",$raid_status)) {
        $raid_status=str_ireplace('Build',$gwords["build"],$raid_status);
    }else if (preg_match("/^Expand/",$raid_status)) {
        $raid_status=str_ireplace('Expand',$gwords["expand"],$raid_status);
    }

    return $raid_status;
}

//#################################################
//# Destribution : get OEM website link
//# @return: link
//#################################################
function getLogoLink(){
	$strExec = "cat /etc/manifest.txt|awk '/producer/{print \$2}'";
	$manifest = trim(shell_exec($strExec));
	$logoLink="";
	switch($manifest){
		case "THECUS":
			$logoLink = "http://tc.thecus.com/";
			break;
	 
		case "YANO":
			$logoLink = "http://www.yano-sl.co.jp";
			break;
	}
	return $logoLink;
}







?>
