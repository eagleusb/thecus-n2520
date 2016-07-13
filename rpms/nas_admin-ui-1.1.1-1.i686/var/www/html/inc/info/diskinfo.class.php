<?
//"provide disk information"
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
include_once("INFO.base.php");
require_once(INCLUDE_ROOT.'Vendor/vendor.class.php');
class DISKINFO extends INFO{
  var $Enclosure=array();
  var $disk_list=array();
  var $modelname="";
  var $sysConfig;
  var $vio;
  
  function DISKINFO(){
    $this->sysConfig = new VendorConfig();
    $this->vio = new VendorIO();
  }
  
  function SMARTDevice() {
    $strDevice=$this->sysConfig->data["smart_device"];
    //printf("strExec=%s \n",$strExec);
    return $strDevice;
  }
  
  function getMdArray(){
    $strExec="/bin/cat /proc/mdstat | grep md | awk -F \" \" '/md/{printf(\"%s\\n\",$1)}' | sort -u";
    $md_list=shell_exec($strExec);
    $md_array_tmp=explode("\n",$md_list);
    foreach($md_array_tmp as $md_name){
      if($md_name!="" && (int)trim(substr($md_name,2,strlen($md_name)-2)) < 20){
        $md_array[]=trim(substr($md_name,2,strlen($md_name)-2));
      }
    }
    return $md_array;
  }
  
  function getNestMdArray(){
    $strExec="/bin/cat /proc/mdstat | grep \"md[3-4][0-9] \" | awk -F \" \" '/md/{printf(\"%s\\n\",$1)}' | sort -u";
    $nestmd_list=shell_exec($strExec);
    $nestmd_array_tmp=explode("\n",$nestmd_list);
    foreach($nestmd_array_tmp as $md_name){
      $nestmd_array[]=trim(substr($md_name,2,strlen($md_name)-2));
    }
    return $nestmd_array;
  }

  function getDiskType($traynum){
    $strExec="cat /proc/scsi/scsi | awk '/Tray:".$traynum." /{print $0}' | awk -F: '{print $7}'";
    $disk_type_tmp=trim(shell_exec($strExec));
    $disk_type=explode(" ",$disk_type_tmp);
    $disk_type[1]=$disk_type[0];

    if(trim($disk_type[1])=="SAS"){
      return 1;
    }else
      return 0;
  }
  
  function parse(){
    $sata = shell_exec("cat /proc/scsi/scsi");
    $partition = shell_exec("cat /proc/partitions")." ";
    $mount_list=shell_exec("mount");

    $total_tray=$this->vio->data["MAX_TRAY"];//trim(shell_exec('cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2'));
    $esata_tray=$this->sysConfig->data["esata"];// trim(shell_exec('/img/bin/check_service.sh esata'));
    $esata_count=$this->sysConfig->data["esata_count"];//trim(shell_exec('/img/bin/check_service.sh esata_count'));

    $md_array=$this->getMdArray();
    $nestmd_array=$this->getNestMdArray();
    
    //echo "sata=$sata <br>";
    if (NAS_DB_KEY == '1'){
      preg_match_all("/Tray:(\d{1,2})\s*Disk:sd(\w*)\s*Model:(.+)Rev:(.+)Removable:([^\n]+)/",$sata,$hdd_info);
    }else{
      preg_match_all("/Tray:(\d{1,3})\s*Disk:sd(\w+)\s*Model:(.+)Rev:(.+)Intf:(.+)LinkRate:(.+)Loc:(.+)Pos:([^\n]+)/",$sata,$hdd_info);
    }
    //echo "count(hdd_info[1])=" . count($hdd_info[1]) . "<br>";
    
    $ary_indexmap=array();
    $max_index=0;
    for($i=0;$i<count($hdd_info[1]);$i++){
      preg_match("/(\d+)\s+sd".$hdd_info[2][$i]."[^\d] /",$partition,$dev_size);
      
      $map_index = $hdd_info[1][$i];
      $ary_indexmap[]=$map_index;
      $disk_list[$map_index][0] = $dev_size[1]/1024/1024;//size
      $disk_list[$map_index][1] = trim($hdd_info[3][$i]);//model
      $disk_list[$map_index][2] = trim($hdd_info[4][$i]);//firmware
      if(file_exists("/var/tmp/HD/badblock_".$map_index)) {
        $result = Commander::fg("a", "sed -nr 's/(.*)=(.*)/\"\\1\":\"\\2\"/p' /var/tmp/HD/badblock_$map_index");
        array_pop($result);
        $result = sprintf("{%s}", join(",", $result));
        $result = json_decode($result, true);
      }
      $disk_list[$map_index][3] = array(
        "state" => $result["State"] + 0,
        "progress" => $result["Progress"] + 0,
        "bad" => $result["Badblock"] + 0
      );
      unset($result);
      $disk_list[$map_index][4] = $hdd_info[2][$i];//partition
      $disk_list[$map_index][9] = $hdd_info[5][$i].trim($hdd_info[6][$i])." Gb/s";//link rate
      $disk_list[$map_index][10] = (int)$hdd_info[7][$i];//Location
      $disk_list[$map_index][11] = (int)$hdd_info[8][$i];//Position
      $disk_map = $this->trayMap();
      $disk_list[$map_index][12] = $disk_map[$map_index];

      if (NAS_DB_KEY == '2'){
        $hdd_info[6][$i]=trim($hdd_info[5][$i]);
        if ($hdd_info[6][$i]=='USB') {
          $hdd_info[5][$i]='1';
        }else{
          $hdd_info[5][$i]='0';
        }
      }
      //echo "$hdd_info[5][" . $i . "]=" . $hdd_info[5][$i] . "<br>";
      if ($hdd_info[5][$i]=='0') {
        $disk_list[$map_index][5] = "0";//not removeable ?
        $dev_name="\/dev\/sd".$hdd_info[2][$i]."2";
        $disk_list[$map_index][6]="0";
        $disk_list[$map_index][7]="0";
        foreach($md_array as $v){
          if($v!=""){
            $strExec="mdadm -D /dev/md${v} | awk '/${dev_name}/{print $5}'";
            $ret=shell_exec($strExec);
            if(trim($ret)=="active"){
              $disk_list[$map_index][6]="1"; //used in raid
              break;
            }elseif(trim($ret)=="spare"){
              $disk_list[$map_index][7]="1";  //used in spare
              break;
            }
          }
        }
        foreach($nestmd_array as $v){
          if($v!=""){
            $strExec="mdadm -D /dev/md${v} | awk '/${dev_name}/{print $5}'";
            $ret=shell_exec($strExec);
            if(trim($ret)=="active"){
              $disk_list[$map_index][6]="1"; //used in raid
              break;
            }elseif(trim($ret)=="spare"){
              $disk_list[$map_index][7]="1";  //used in spare
              break;
            }
          }
        }
      }else{
        $disk_list[$map_index][5] = "1";//removeable
        $usbbus=preg_split('/[ :]/',$hdd_info[5][$i]);
        $disk_list[$map_index][6]=$usbbus[2];
        $disk_list[$map_index][7]=$usbbus[4];
        //echo "/dev/sd" . $disk_list[$map_index][4] . "<br>";
        if(preg_match("/\/dev\/sd" . trim($disk_list[$map_index][4]) . "/",$mount_list))
          $disk_list[$map_index][8]=1;
        else
          $disk_list[$map_index][8]=0;
      }

      if ($max_index < $map_index) {
        $max_index=$map_index;
      }
    }
    //$strtest="1 Bus:3 Port:1";
    //$usbbus=preg_split('/[ :]/',$strtest);
    //echo "busnum=" . $usbbus[2] . "  portnum=" . $usbbus[4] . "<br>";

    //echo "max_index=" . $max_index . "<br>";
    $max_index=$max_index+1;
    $exist_disk_count=0;
    $used_disk_count=0;
    for($i=1;$i <= $max_index;$i++){
    //for($i=1;$i <= $total_tray;$i++){
      if(!isset($disk_list[$i]) || ($disk_list[$i][1]=="")){
        $disk_list[$i][0] = "N/A";//size
        $disk_list[$i][1] = "N/A";//model
        $disk_list[$i][2] = "N/A";//firmware
        $disk_list[$i][3] = "N/A";//status
        $disk_list[$i][4] = "N/A";//partition
        $disk_list[$i][5] = "0";//removeable
        $disk_list[$i][6] = "0";//used in raid
        $disk_list[$i][7] = "0";//used in spare
        $disk_list[$i][9] = "N/A";//link rate
        $disk_list[$i][10] = 0;//Location
        $disk_list[$i][11] = 0;//Position
        $disk_list[$i][12] = "";//Disk raid name
      }else{
        $exist_disk_count++;
        if($disk_list[$i][6] == "1" || $disk_list[$i][7] == "1")
          $used_disk_count++;
      }
    }
    //echo "count(hdd_info[1])=" . count($disk_list[1]) . "<br>";
    $this->content["DiskInfo"]=$disk_list;
    $this->content["max_index"]=$max_index;
    $this->content["exist_disk_count"]=$exist_disk_count;
    $this->content["unused_disk_count"]=$exist_disk_count-$used_disk_count;
  }

  function diskMap(){
    $total_tray=$this->vio->data["MAX_TRAY"];
    $sata = shell_exec("cat /proc/scsi/scsi");
    //echo "sata=$sata <br>";
    if (NAS_DB_KEY == '1'){
      preg_match_all("/Tray:(\d{1,2})\s*Disk:sd(\w)\s*Model:(.+)Rev:(.+)Removable:([^\n]+)/",$sata,$hdd_info);
    }else{
      preg_match_all("/Tray:(\d{1,3})\s*Disk:sd(\w+)\s*Model:(.+)Rev:(.+)Intf:(.+)LinkRate:(.+)Loc:(.+)Pos:([^\n]+)/",$sata,$hdd_info);
    
      $hdd_info[6][$i]=trim($hdd_info[5][$i]);
      if ($hdd_info[6][$i]=='USB') {
        $hdd_info[5][$i]='1';
      }else{
        $hdd_info[5][$i]='0';
      }
    }

    //echo "count(hdd_info[1])=" . count($hdd_info[1]) . "<br>";
    $max_index=0;
    $diskMap=array();
    for($i=0;$i<count($hdd_info[1]);$i++){
      if ($hdd_info[5][$i]=='0') {
        $map_index = $hdd_info[1][$i]-1;
        $diskMap[$hdd_info[2][$i]]=$map_index;
      }
    }
    return $diskMap;
  }
  
  function getspintime() {
    $db = new sqlitedb();
    if (NAS_DB_KEY == '1'){
      $spintime=$db->getvar("disk_spintime");
    }else{
      $spintime=$db->getvar("disks_spin_down");
    }
    $db->db_close();
    return $spintime;
  }
  
  function setspintime($spintime) {
    $db = new sqlitedb();
    if (NAS_DB_KEY == '1'){
      $db->setvar("disk_spintime", $spintime);
    }else{
      $db->setvar("disks_spin_down", $spintime);
    }
    $db->db_close();
    shell_exec("/img/bin/hdspin.sh >/dev/null 2>&1"); 
    return $spintime;
  }
  
  function ejectusb($usbdisk) {
    $usbdisk="sd" . $usbdisk;
    $strexec="/img/bin/eject_usb.sh $usbdisk >/dev/null 2>&1;sleep 2";
    //echo "strexec=" . $strexec . "<br>";
    shell_exec($strexec); 
  }
  
  function get_all_disk_data(){
    global $Enclosure,$disk_list,$total_size,$gwords,$total_tray;
    $total_size=0;
    $total_tray=$this->vio->data["MAX_TRAY"];
    $product_no=$this->vio->data["MODELNAME"];//trim(shell_exec('cat /proc/thecus_io | grep "MODELNAME:" | cut -d" " -f2'));
    $Enclosure []= array(
        "product_no" => 0,
        "product_name" => $product_no,
        "total_tray" => $total_tray,
        "column" => $this->sysConfig->data["column"],
        "rotation" => $this->sysConfig->data["rotation"],
        "ignore" => $this->sysConfig->data["ignore"] + 0,
        "disks" => array()
    );

    $arr = array(52, 78, 104, 130);
    foreach ($arr as &$enc_tray) {
      $temp=trim(shell_exec("sg_ses -p 0x1 /dev/sg$enc_tray | grep 'enclosure vendor'"));
      if ($temp == "") continue;
      preg_match_all("/enclosure vendor:(.+)product:(.+)rev:([^\n]+)/",$temp,$enclosure_info);

      $Enclosure []= array(
          "product_no" => $enc_tray/26-1,
          "product_name" => trim($enclosure_info[2][0]),
          "total_tray" => 16,
          "column" => 4,
          "rotation" => "H",
          "disks" => array()
      );
    }

    $disk_map = $this->trayMap();
    for($index=0;$index<count($disk_list);$index++){
      if($disk_list[$index][0] != "N/A" && $disk_list[$index][5] == '0' && ($disk_list[$index][10] >= 1 || $disk_list[$index][11] <= (int)$total_tray)) {
        $enc_id=$disk_list[$index][10];
        $temp = $disk_list[$index][0];
        $capacity =number_format($temp, 0);
        if ($capacity == 0) continue;
        $total_size+=round($temp);

        $disk_no = $disk_list[$index][11];
        $diskno=$disk_list[$index][4];

        $model=$disk_list[$index][1];
        $fireware=$disk_list[$index][2];
        $s_status=$disk_list[$index][3];
        $linkrate=$disk_list[$index][9];

        if($s_status=="OK")
          $s_status=$gwords['detect'];

        for($Eindex=0;$Eindex<count($Enclosure);$Eindex++){
          if($Enclosure[$Eindex]["product_no"] == $enc_id)
            $Enclosure[$Eindex]['disks'] []= array(
              "disk_no" => $disk_no,
              "tray_no" => $index,
              "disk_name" => $model,
              "size" => $capacity." Gb",
              "link" => $linkrate,
              "fw" => $fireware,
              "status" => $s_status,
              "partition_no" => $diskno,
              "Serial" => "",
              "used" => $disk_list[$index][6],
              "spare" => $disk_list[$index][7],
              "raid_id" => $disk_map[$index]
            );
        }
      }
    }
    return $Enclosure;
  }
  
  function get_spare_disk_data(){
    global $Enclosure;
    $dbpath = "/etc/cfg/conf.db";
    $chktable = shell_exec("/usr/bin/sqlite $dbpath .table | grep hot_spare");  // check table
    if(!$chktable){
      shell_exec("/usr/bin/sqlite $dbpath 'CREATE TABLE hot_spare(spare varchar);'");
    }
    $Serial_List = explode("\n",trim(shell_exec("/usr/bin/sqlite $dbpath 'select spare from hot_spare'")));
    foreach($Enclosure as $k=>$item){
      foreach($item['disks'] as $j=>$disk){
        $Enclosure[$k]['disks'][$j]["hot_spare"]="0";
        $Enclosure[$k]['disks'][$j]["Serial"]=trim(shell_exec('/usr/sbin/smartctl -i /dev/sd'.$Enclosure[$k]['disks'][$j]['partition_no']." | grep 'Serial [Nn]umber' | awk '{print $3}'"));
        foreach($Serial_List as $Serial){
          if($Serial != "" && $Serial == $Enclosure[$k]['disks'][$j]["Serial"])
            $Enclosure[$k]['disks'][$j]['hot_spare']="1";
        }
        if($Enclosure[$k]['disks'][$j]['hot_spare']=="0")
          shell_exec("/usr/bin/sqlite $dbpath \"delete from hot_spare where spare='".$Enclosure[$k]['disks'][$j]['Serial']."'\"");
      }
    }
    return $Enclosure;
  }
  
    function trayMap() {
        $md_list = trim(shell_exec("sed -nr 's/^md([0-9]) :(.*)/md\\1/p' /proc/mdstat | sort -u"));
        $md_array_tmp = explode("\n",$md_list);
        foreach ( $md_array_tmp as $md_name ) {
            if ( $md_name != "" ) {
                $md_array[] = trim(substr($md_name,2,strlen($md_name)-2));
            }
        }
        
        $tray_map[] = array();
        foreach ( $md_array as $md_name ) {
            $raid_id = trim(shell_exec("sed -nr 's/(.*)/\\1/p' /var/tmp/raid".$md_name."/raid_id"));
            $disk_tray = explode("\n",trim(shell_exec("sed -nr 's/\"(.*)\"/\\1/p' /var/tmp/raid".$md_name."/disk_tray")));
            
            for ( $i=0 ; $i<count($disk_tray) ; $i++ ) {
                if ( $disk_tray[$i] != "" ) {
                    $tray_map[$disk_tray[$i]] = $raid_id;
                }
            }
        }
        return $tray_map;
    }
  
}
?>
