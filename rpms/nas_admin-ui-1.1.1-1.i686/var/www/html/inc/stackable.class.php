<?
require_once(INCLUDE_ROOT."db.class.php");
require_once(INCLUDE_ROOT."commander.class.php");
require_once(INCLUDE_ROOT.'validate.class.php');
class stackable extends db_tool2{
  public static $mkreiserfs="/sbin/mkreiserfs";
  const mount="/bin/mount";
  const umount="/bin/umount";
  const sqlite="/usr/bin/sqlite";
  const db="/etc/cfg/stackable.db";
  const iscsiadm="/sbin/iscsiadm";
  public static $stackable_root="/raid/stackable";
  public static $file_system="reiserfs";
  const mount_option="acl,rw,noatime";
  const mount_ro_option="acl,ro,noatime";
  const TIMEOUT="20";
  public static $share;
  public static $ip_port;
  public static $iqn;
  public static $username;
  public static $password;
  public static $guest_only;
  public static $o_guest_only;
  const to_dev_null=" 2>/dev/null ";
  //const to_dev_null="";

  function stackable(){
    if (NAS_DB_KEY == '2'){
      self::$mkreiserfs="/sbin/mke2fs";
      self::$stackable_root="/raid/data/stackable";
      self::$file_system="ext4";
    }
  } 
   
  function set_default_value($data){
    self::$ip_port=$data["ip"].":".$data["port"];
    self::$iqn=$data["iqn"];
    self::$username=$data["user"];
    self::$password=$data["pass"];
    self::$share=$data["share"];
    self::$guest_only=$data["guest_only"];
    self::$o_guest_only=$data["o_guest_only"];
    //echo "<pre>";
    //print_r($data);
  }
  
  function check_ui_capacity(){
    if($this->check_device()!=""){
      $device="/dev/".$this->check_device();
      $strExec="cat /proc/partitions | grep \"${device}1\"";
      $device_exist=shell_exec($strExec);
      if($device_exist!=""){
        $device="${device}1";
      }else{
        $device=$device;
      }
      //$strExec="/bin/df | grep \"".self::$stackable_root."/".self::$share."\"";
      $strExec="/bin/df | grep \"".$device." \"";
      $df_array=explode(" ",shell_exec($strExec));
      $df_info=array();
      foreach($df_array as $data){
        if($data!=""){
          $df_info[]=$data;
        }
      }
      $count=count($df_info);
      if($count!="0"){
        $used=round($df_info[2]/1024/1024,1);
        $total_tmp=($df_info[2]+$df_info[3]);
        $total=round(($df_info[2]+$df_info[3])/1024/1024,1);
        $capacity=$used." GB / ".$total." GB";
      }else{
        $capacity="N/A";
      }
    }else{
      $capacity="N/A";
    }
    return $capacity;
  }
  
  function check_mount(){
    $device="/dev/".$this->check_device();
    $strExec="cat /proc/partitions | grep \"${device}1\"";
    $device_exist=shell_exec($strExec);
    if($device_exist!=""){
      $device="${device}1";
    }else{
      $device=$device;
    }
    $strExec="/bin/df | grep \"".$device." \"";
    $mount_ret=shell_exec($strExec);
    if($mount_ret==""){
      return 0;//no mount point
    }
    return 1;//have mount point
  }
  
  function stack_connect(){
    $validate=new validate();
    $ip_len=strlen(self::$ip_port);
    $ip_self=substr(self::$ip_port,-$ip_len,-5);
    $ip_self_len=strlen($ip_self);
    $port_self=substr(self::$ip_port,$ip_self_len);
    
    $iqn=self::$iqn;
    $iscsiadm_iqn_string=explode(" ",$iqn);
    $iqn=$iscsiadm_iqn_string[0];
    
    if($validate->ipv6_address($ip_self)){
       $grep_ip_port="\[$ip_self\]$port_self";
       $ip_port="[$ip_self]$port_self";
    }else{
       $ip_port="$iscsiadm_iqn_string[1]$port_self";   
       $grep_ip_port="$ip_self$port_self";
    }
    $strExec=self::iscsiadm." -m discovery -tst -p $ip_port";
    shell_exec($strExec);
    $strExec=self::iscsiadm." -m node";
    $iscsiadm_info=shell_exec($strExec);
    $iscsiadm_array=explode("\n",$iscsiadm_info);
    $record="0";
    foreach($iscsiadm_array as $line){
      if($line!=""){
        if(preg_match("/$grep_ip_port/",$line) && preg_match("/$iqn/",$line)){
          //$line_info=explode(" ",$line);
          $record="1";
          //echo "record=$record <br>";
          break;
        }
      }
    }
    if($record=="0"){
      return 1;
    }
    
    if(self::$username!=""){
      $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.session.auth.authmethod -v CHAP";
      //echo "strExec=$strExec <br>";
      shell_exec($strExec);
      $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.session.auth.username -v ".self::$username;
      //echo "strExec=$strExec <br>";
      shell_exec($strExec);
      $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.session.auth.password -v ".self::$password;
      //echo "strExec=$strExec <br>";
      shell_exec($strExec);
    }else{
      $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.session.auth.authmethod -v None";
      //echo "strExec=$strExec";
      shell_exec($strExec);
      $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.session.auth.username -v \"\"";
      //echo "strExec=$strExec";
      shell_exec($strExec);
      $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.session.auth.password -v \"\"";
      //echo "strExec=$strExec";
      shell_exec($strExec);
    }
    $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.conn[0].tcp.window_size -v \"65535\"";
    //echo "strExec=$strExec <br>";
    shell_exec($strExec);
    $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.conn[0].iscsi.HeaderDigest -v \"None\"";
    //echo "strExec=$strExec <br>";
    shell_exec($strExec);
    $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -o update -n node.conn[0].iscsi.DataDigest -v \"None\"";
    //echo "strExec=$strExec <br>";
    shell_exec($strExec);
    $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port -l";
    //echo "strExec=$strExec <br>";
    exec($strExec,$out,$ret);
    return $ret;
  }
  
  function stack_mount(){
    $device=$this->check_device();
    $strExec="cat /proc/partitions | grep \"${device}1\"";
    $device_exist=shell_exec($strExec);
    if($device_exist!=""){
      $device="${device}1";
    }else{
      $device=$device;
    }
    if($device!="" && self::$share!=""){
      $strExec="echo 2048 > /sys/block/".$device."/queue/read_ahead_kb";
      shell_exec($strExec);
      $this->stack_mkdir();
      $cmd = "/usr/bin/sqlite /etc/cfg/conf.db \"select v from conf where k='quota'\"";
      $quota_enable = Commander::frontground('s', $cmd) == '1';
      if (NAS_DB_KEY == '1'){
        $strExec=self::mount." -t ".self::$file_system." -o ".self::mount_option." /dev/$device \"".self::$stackable_root."/".self::$share."\"";
      }else{
        $strExec="/usr/bin/sg_modes /dex/\"${device}\" | grep WP=1";
        if ($out[0] != "")
          $strExec=self::mount." -t ".self::$file_system." -o ".self::mount_ro_option." /dev/$device \"".self::$stackable_root."/".self::$share."\"".self::to_dev_null;
        else
          $strExec=self::mount." -t ".self::$file_system." -o ".self::mount_option." /dev/$device \"".self::$stackable_root."/".self::$share."\"".self::to_dev_null;
      }
      if( $quota_enable ){
        shell_exec($strExec);
        $strExec="/img/bin/rc/rc.user_quota mount_quota stack";
      }
      exec($strExec,$out,$ret);
      if($ret=="0"){
        $this->stack_make_data_folder();
        return 0;//true
      }else{
        for($i=0;$i<self::TIMEOUT;$i++){
          sleep(1);
          if (NAS_DB_KEY == '1'){
            $strExec=self::mount." -t ".self::$file_system." -o ".self::mount_option." /dev/$device \"".self::$stackable_root."/".self::$share."\"";
          }else{
            $strExec="/usr/bin/sg_modes /dex/\"${device}\" | grep WP=1";
            if ($out[0] != "")
              $strExec=self::mount." -t ".self::$file_system." -o ".self::mount_ro_option." /dev/$device \"".self::$stackable_root."/".self::$share."\"".self::to_dev_null;
            else
              $strExec=self::mount." -t ".self::$file_system." -o ".self::mount_option." /dev/$device \"".self::$stackable_root."/".self::$share."\"".self::to_dev_null;
          }
          
          exec($strExec,$out,$ret);
          if($ret=="0"){
            $this->stack_make_data_folder();
            return 0;//true
          }
        }
        $strExec="/bin/rm -rf \"".self::$stackable_root."/".self::$share."\"";
        shell_exec($strExec);
        return 1;//false
      }
    }
    return 1;
  }
  
  function check_device(){
    $validate=new validate();
    $strExec=self::iscsiadm." -m session".self::to_dev_null;
    $iscsiadm_info=shell_exec($strExec);
    $iscsiadm_array=explode("\n",$iscsiadm_info);
    foreach($iscsiadm_array as $line){
      if($line!=""){
        $iqn=self::$iqn;
        $iscsiadm_iqn_string=explode(" ",$iqn);
        $iqn=$iscsiadm_iqn_string[0];
        $ip=$iscsiadm_iqn_string[1];
        if($ip==""){
             $ip_port=self::$ip_port;
        }else{
             $str="echo ${ip} | sed 's/\]//g' | sed 's/\[//g'";
             $ip=trim(shell_exec($str));
             if($validate->ipv6_address($ip)){
                 $ip_port="\[$ip\]:3260";
             }else{
                 $ip_port="$ip:3260";
             }
        }
        if(preg_match("/$ip_port/",$line) && preg_match("/$iqn/",$line)){
          $line_info=explode(" ",$line);
          $key=trim($line_info[1]);
          $arykey=preg_split("/[[]|[]]/",$key);
          $key=$arykey[1];
          if($key[0]=="0"){
            $key=$key[1];
          }
        }
      }
    }
    
    shell_exec("sleep 1");
    $strExec="/bin/ls -laR /sys/class/iscsi_session/session".$key."/device/".self::to_dev_null."|awk -F\/ '/block\/sd.*:$/&&!/block\/sd.*\//{print substr(\$10,0,length(\$10)-1)}'";
    $device=explode("\n",shell_exec($strExec));
    //echo "strExec=$strExec <br>";
    //echo "device=$device <br>";
    return $device[0];//sda
  }
  
  function stack_mkdir(){
    $is_folder=file_exists(self::$stackable_root."/".self::$share);
    if(!$is_folder){
      $strExec="/bin/mkdir -p \"".self::$stackable_root."/".self::$share."\"";
      shell_exec($strExec);
    }
  }
  
  function stack_umount(){
    $device=$this->check_device();
    if(strlen($device)=="3" || strlen($device)=="4"){
      $strExec="/bin/mount | grep \"$device \" | awk -F ' ' '{printf $3}'";
      $stack_folder=trim(shell_exec($strExec));
      if($stack_folder!=""){
        exec("sync",$out,$ret);
        exec("sync",$out,$ret);
        exec("sync",$out,$ret);
        $strExec=self::umount." -f \"$stack_folder\"";
        exec($strExec,$out,$ret);
        if($ret!="0"){
          $strExec="/sbin/fuser -m \"$stack_folder\"";
          $hold_pid=explode(" ",shell_exec($strExec));
          foreach($hold_pid as $pid){
            $pid=trim($pid);
            if($pid!=""){
              $strExec="kill -9 $pid";
              shell_exec($strExec);
            }
          }
          $strExec=self::umount." -f \"$stack_folder\"";
          shell_exec($strExec);
        }
        $strExec="/bin/rm -rf \"$stack_folder\"";
        shell_exec($strExec);
      }
    }
  }
  
  function stack_check_session(){
    $validate=new validate();
    $strExec=self::iscsiadm." -m session".self::to_dev_null;
    $iscsiadm_info=shell_exec($strExec);
    $iscsiadm_array=explode("\n",$iscsiadm_info);
    $record=0;
    foreach($iscsiadm_array as $line){
      if($line!=""){
        $iqn=self::$iqn;
        $iscsiadm_iqn_string=explode(" ",$iqn);
        $iqn=$iscsiadm_iqn_string[0];
        $ip=$iscsiadm_iqn_string[1];
        if($ip==""){
          $ip_port=self::$ip_port;
        }else{
          $str="echo ${ip} | sed 's/\]//g' | sed 's/\[//g'";
          $ip=trim(shell_exec($str));
        
          if($validate->ipv6_address($ip)){
             $ip_port="\[$ip\]:3260";
          }else{
             $ip_port="$ip:3260";
          }
        }
        if(preg_match("/${ip_port}/",$line) && preg_match("/$iqn/",$line)){
          $record=1;
          break;
        }
      }
    }
    return $record;//0:fail,1:sucess
  }
  
  function stack_logout($record){
    $ip_port=self::$ip_port;
    $iqn=self::$iqn;
    $iscsiadm_iqn_string=explode(" ",$iqn);
    $iqn=$iscsiadm_iqn_string[0];
    $ip=$iscsiadm_iqn_string[1];
    
    $ip_port="$ip:3260";
    $strExec=self::iscsiadm." -m node -T $iqn -p $ip_port --logout";
    //echo "strExec=$strExec <br>";
    shell_exec($strExec);
  }
  
  function stack_format(){
    $device=$this->check_device();
    if(strlen($device)=="3" || strlen($device)=="4"){
      $strExec="/usr/sbin/sgdisk -oZ /dev/$device";
      exec($strExec,$sgdisk_del_out,$sgdisk_del_ret);
      $strExec=self::$mkreiserfs." -t ext4 -m 0 -b 4096 -i 4096 -F /dev/${device} > /dev/null 2>&1 && echo -e \"$?\"";
      exec($strExec,$mkfs_ret,$mkfs_tmp);
      if($sgdisk_del_ret=="0" && $mkfs_ret[0]=="0"){
        $this->stack_make_data_folder();
        return 0;//format success
      }else{
        return 1;
      }
    }else{
      return 1;
    }
  }
  
  function stack_make_data_folder(){
    $path=self::$stackable_root."/".self::$share."/data";
    if(!file_exists($path)){
      $strExec="/bin/mkdir -p \"$path\"";
      shell_exec($strExec);
      if (NAS_DB_KEY == '1'){
        $strExec="/bin/chown nobody:smbusers \"$path\"";
      }else{
        $strExec="/bin/chown nobody:users \"$path\"";
      }
      shell_exec($strExec);
      if(self::$guest_only=="yes"){
        $strExec="/bin/chmod 777 \"$path\"";
        shell_exec($strExec);
      }else{
        $strExec="/bin/chmod 700 \"$path\"";
        shell_exec($strExec);
        //echo "$strExec<br>";
      }
    }
  }
  
  function set_default_acl(){
    $path=self::$stackable_root."/".self::$share."/data";
    if(self::$guest_only=="yes"){
      $strExec="setfacl -P -m other::rwx \"".$path."\"";
      shell_exec($strExec);
      //echo "$strExec<br>";
    }else{
      $strExec="getfacl -p \"$path\" | awk -F':' '/^user:/||/^group:/{print \$2}'";
      $acl_info=shell_exec($strExec);
      $acl_info_array=explode("\n",$acl_info);
      $acl_count=count($acl_info_array);
      for($c=0;$c<$acl_count;$c++){
        if($acl_info_array[$c]!=""){
          $acl_member="1";
          break;
        }
      }
      if($acl_member=="1"){
        $strExec="/bin/chmod 770 \"$path\"";
      }else{
        $strExec="/bin/chmod 700 \"$path\"";
      }
      shell_exec($strExec);
      //echo "$strExec<br>";
    }
    $strExec="setfacl -P -d -m other::rwx \"".$path."\"";
    //echo "$strExec<br>";
    shell_exec($strExec);
  }
  
  function set_acl(){
    $path=self::$stackable_root."/".self::$share."/data";
    if(self::$guest_only=="yes"){
      $strExec="setfacl -R -P -b \"".$path."\"";
      shell_exec($strExec);
      //echo "$strExec<br>";
      $strExec="setfacl -R -P -m other::rwx \"".$path."\"";
      shell_exec($strExec);
      //echo "$strExec<br>";
      $strExec="chmod -R 777 \"".$path."\"";
      shell_exec($strExec);
      //echo "$strExec<br>";
    }else{
      if(self::$o_guest_only=="yes"){
        $strExec="setfacl -R -P -m other::--- \"".$path."\"";
        shell_exec($strExec);
        //echo "$strExec<br>";
      }
      $strExec="chmod -R 700 \"".$path."\"";
      shell_exec($strExec);
      //echo "$strExec<br>";
    }
    $strExec="setfacl -R -P -d -m other::rwx \"".$path."\"";
    shell_exec($strExec);
    //echo "$strExec<br>";
  }
}
?>
