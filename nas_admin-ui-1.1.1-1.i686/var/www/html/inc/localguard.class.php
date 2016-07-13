<?php
require_once(INCLUDE_ROOT.'dataguard.class.php');
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'rsync.class.php');
require_once(INCLUDE_ROOT.'sharefolder.class.php');

class LocalDataGuard extends DataGuard {
    const  CMD_PATH="/img/bin/dataguard/";
    const  RAID_LOCK_PATH="/tmp";
    const  RAID_PATH="/raid/data/ftproot";
    const  RC_CMD="/img/bin/rc/rc.lbackup";
    const  MOUNT_FILE="/etc/mtab";
    var $texternal_mount="";
    var $sexternal_mount="";
    var $sfull_path="";
    var $tfull_path="";

    function __construct($config) {
        // TODO: override constructor method and check $config to throw execption when any error
        $ret=true;
        if($config["tid"]==0){
            $ret=$this->checkTaskStatus(&$config);
        }

        if($ret){
            if ($config["tid"] == 0){
                $config["opts"]["force"]="1";
                parent::__construct($config);
                self::closeDb();
                $config=self::$config;
                $this->executeCreate($config);
            } else {
                self::$config = $config;
            }
        } else {
            throw new Exception("create error", self::$err);
        }
    }

    private function getRaidFolder($path){
        $real_path="";
        $raid_folder="";
        $root_folder=explode("/",$path);
        $real_path=readlink(self::RAID_PATH."/".$root_folder[1]);

        if ($real_path){
            if(!preg_match("/^\/raid\/data\/stackable\/*/",$real_path)){
                $folder_list=explode("/",$real_path);
                $raid_folder=$folder_list[1];
            }else{
                $raid_folder=$this->getMasterRaid();
            }
        }
        return $raid_folder;
    }

    private function getMountPath($dev,$path,$folder){
        if($dev=="" && $path==""){
            $dev_nic=explode(":",$folder);
        }else{
            $dev_nic[0]=$dev;
        }
        $search=array("\\040","\\134","\\011");
        $replace=array(" ","\\","\t");
        $mount_list=str_replace($search,$replace,file(self::MOUNT_FILE));

        if (substr($dev_nic[0],0,3)=="emd"){
            $dev_nic[0]="loop".(50+substr($dev_nic[0],3));
        }

        if(substr($dev_nic[0],0,5)=="stack"){
            $dev_nic[0]=substr($dev_nic[0],6);
        }

        for($i=0;$i<count($mount_list);$i++){
            if($mount_list[$i] != ""){
                preg_match('/^\/dev\/'.$dev_nic[0].' (.*) (.*) r[wo].*$/',$mount_list[$i],$matches);
                if($matches){
                    break;
                }
            }
        }

        return $matches[1];
    }

    private function getMasterRaid(){
        $master_path=readlink("/raid");
        $folder_list=explode("/",$master_path);

        return $folder_list[1];
    }

    private function checkTargetRaidStatus($config){
        $ret=true;
        $raid_folder="";
        $target=explode("//",$config["opts"]["target"]);

        for($i=0;$i<count($target);$i++){
            switch($config["opts"]["device_type"]){
                case '0' :
                case '2' :
                    if($config["back_type"] == "import" || $config["back_type"] == "import_iscsi"){
                        $raid_folder=substr(trim($target[$i]),1);
                    } else {
                        $raid_folder=$this->getRaidFolder(trim($target[$i]));
                    }
                    break;
                case '1' :
                    $raid_folder=$this->getMasterRaid();
                    break;
                default :
                    break;
            }

            if ($raid_folder!="") {
                $raid_status=file("/var/tmp/".$raid_folder."/rss");

                if (trim($raid_status[0]) != "Healthy" && trim($raid_status[0]) != "Degraded" ){
                    $ret=false;
                }
            } else {
                $ret=false;
            }

            if(!$ret){
                self::$err=self::ERR_TARGET_RAID;   //Raid Status Error;
                break;
            }
        }

        return $ret;
    }

    private function getTaskCount($type) {
        self::openDb();
        $cmd = sprintf("SELECT * FROM task WHERE back_type='%s' and act_type='local';", $type);
        $st = self::$db->query($cmd);
        $result = $st->fetchAll(PDO::FETCH_ASSOC);
        $count = count($result);
        self::closeDb();
        return $count;
    }

    private function checkTaskCount($config){
        if ( $config["tid"] == "0" ) {
            get_sysconf();
            global $sysconf;
            $type_list=array("copy","import", "import_iscsi");
            //$task_type=$config["back_type"]."_task_limit";
            if(in_array($config["back_type"], $type_list)){
                $task_count = $this->getTaskCount($config["back_type"]);
                $max_count = 1;
            }else{
                $task_count = self::taskCount();
                $max_count = $sysconf["rsync_task_limit"];
            }
            if($task_count >= $max_count){
                self::$err=self::ERR_TASK_LIMIT;  // task Count limit
                return false;
            }
        }

        return true;
    }

    private function checkTaskNameEmpty($name){
        if( $name == "" ){
            self::$err=self::ERR_TASKNAME_EMPTY;  // Name Empty
            return false;
        }

        return true;
    }

    private function checkTaskNameType($name){       
        if(!preg_match("/^([a-zA-Z0-9_-])*$/",$name)){
            self::$err=self::ERR_TASKNAME_FORMAT; // Name Type
            return false;
        }

        return true;
    }

    private function checkDupTaskName($tid,$name){
        $id = self::getTaskId($name);
        if( $id == $tid ) {
            return true;
        } else {
            self::$err=self::ERR_TASKNAME_DUP; // Name Duplicate 
            return false;
        }

        return true;
    }

    private function checkTaskName($config){
        $ret=true;
/*        $type_list=array("copy","import", "iscsi");
        $is_one_task=in_array($config["back_type"], $type_list);

        if($is_one_task){
            if ( $config["task_name"] != $type ) {
                self::$err=0x08002008;
                $ret=false;
            }
        } else {*/
            $ret=$this->checkTaskNameEmpty($config["task_name"]);
            if($ret){
                $ret=$this->checkTaskNameType($config["task_name"]);
                if($ret){
                    $ret=$this->checkDupTaskName($config["tid"],$config["task_name"]);
                }
            }
//        }

        return $ret;
    }

    private function checkAction($config){
        $type_list=array("copy","import","import_iscsi");
        if($config["tid"] != 0 && in_array($config["back_type"], $type_list)){
            self::$err=self::ERR_ACTION; // illegal action
            return false;
        }
        return true;
    }

    private function checkFlagNoExist($task_name){
        $status_file = sprintf(RSYNC_STATUS_FILE, $task_name);
        if (file_exists($status_file)){
            return false;
        }

        return true;
    }

    private function checkNoProcess($config){
        $ret=$this->checkFlagNoExist($config["task_name"]);
        if (!$ret) {
            self::$err=self::ERR_TASKNAME_RUN; // Task already Process
        }
        
        return $ret;
    }

    private function checkSourceCount($config){
        $ret=true;
        $type_list=array("realtime", "iscsi","import_iscsi");
        if(in_array($config["back_type"], $type_list)){
            $source_list=explode("/",$config["opts"]["folder"]);
            if(count($source_list)!=1){
                self::$err=self::ERR_SOURCE_COUNT; // Check Source Count
                $ret=false;
            }
        }

        return $ret;
    }

    private function checkTargetReadonly($config){
        $ret=true;

        if($config["opts"]["device_type"]=="1"){
            $target=explode("//",$config["opts"]["target"]);
            $target_list=explode("//",$this->texternal_mount);
            for($i=0;$i<count($target);$i++){
                $file_name=".".date("U");
                if($target_list[$i]==""){
                    $target_mount=$target_list[0];
                }else{
                    $target_mount=$target_list[$i];
                }

                if($target_mount != ""){
                    $tmp_file=$target_mount.$target[$i]."/".$file_name;
                    if(touch($tmp_file)){
                        unlink($tmp_file);
                    }else{
                        $ret=false;
                        break;
                    }
                }else{
                    $ret=false;
                    break;
                }
            }

            if (!$ret) {
                self::$err=self::ERR_TARGET_READONLY; // Target Readonly
            }
            
        }

        return $ret;
    }

    private function parseDevList($dev,$path,$folder){
        $folder_list=explode("/",$folder);
        for( $i = 0 ; $i < count($folder_list) ; ++$i) {
            if($folder_list[$i] != ""){
                preg_match("/^([^:]*):?(.*)$/", $folder_list[$i], $dev_list[$i]);
                if($dev == "" && $path == ""){
                    $dev_list[$i][3] = "0";
                }else{
                    $dev_list[$i][3] = "1";
                }

                if(substr($dev_list[$i][1],0,5)=="iscsi"){
                    $dev_list[$i][1]="iscsi";
                }
            }
        }
        return $dev_list;
    }


    private function getDevType($dev){
        $type="raid";
        if (substr($dev,0,2) != "md" && substr($dev,0,3) != "emd" && substr($dev,0,5) != "iscsi" && substr($dev,0,5) != "stack"){
            $type="external";
        }

        return $type;
    }

    private function checkDevMatchType($dev,$type){
        $ret=true;
        $real_type=$this->getDevType($dev);
        if($type != $real_type)
            $ret=false;
/*        if($type=="raid"){
            if (substr($dev,0,2)!="md" && substr($dev,0,3)!="emd" && substr($dev,0,5)!="iscsi"){
                $ret=false;
            }
        }else{
            if (substr($dev,0,2)=="md" || substr($dev,0,3)=="emd" || substr($dev,0,5)=="iscsi"){
                $ret=false;
            }
        }*/
        return $ret;
    }

    private function checkConfig($config){
        $ret=true;
/*        $task_id = self::getTaskId($config["task_name"]);
        if ( $config["tid"] != $task_id){
                self::$err=0x08002009; // Configure Error
                return false; 
        }*/
        $dev=array($config["opts"]["dest_dev"],
                   $config["opts"]["src_dev"]);
        $dev_list[0]=$this->parseDevList($config["opts"]["dest_dev"],$config["opts"]["dest_path"],$config["opts"]["dest_folder"]);
        $dev_list[1]=$this->parseDevList($config["opts"]["src_dev"],$config["opts"]["src_path"],$config["opts"]["src_folder"]);
        switch($config["opts"]["device_type"]){
            case "0" :
                $type=array("raid","raid");
                 break;
            case "1" :
                $type=array("external","raid");
                break;
            case "2" :
                $type=array("raid","external");
                break;
            default :
                $ret=false;
                break;
        }

        for($i=0;$i<count($dev_list);$i++){
            if($dev[$i] != ""){
                $ret=$this->checkDevMatchType($dev[$i],$type[$i]);
            }else{
                for($j=0;$j<count($dev_list[$i]);$j++){
                    $ret=$this->checkDevMatchType($dev_list[$i][$j][1],$type[$i]);
                    if(!$ret){
                        break;
                    }
                }
            }

            if(!$ret){
                break;
            }
        }

        if(!$ret){
            self::$err=self::ERR_CONFIG; // Configure Error
        }

        return $ret;
    }

    private function get_extern_mount_len($mount_path){
        $mount_len=0;
        $mount_len=strlen(strstr($mount_path,"/eSATAHDD/"));

        if($mount_len == 0){
            $mount_len=strlen(strstr($mount_path,"/USBHDD/"));
        }
        return $mount_len;
    }

    private function parseStack($path){
        $path_list=explode("/",$path);
        if($path_list[1]=="stackable"){
            $new_list[]="/".$path_list[2];
            for($i=4;$i<count($path_list);$i++){
                $new_list[]=$path_list[$i];
            }
            $after_path=implode("/", $new_list);
            
        }else{
            $after_path=$path;
        }
        return $after_path;
    }

    private function parseTargetPath($config){
        $ret=true;
        $dev_list=$this->parseDevList($config["opts"]["dest_dev"],$config["opts"]["dest_path"],$config["opts"]["dest_folder"]);
        if($config["back_type"] == "import" || $config["back_type"] == "import_iscsi"){
            for($i=0;$i<count($dev_list);$i++){
                if($dev_list[$i][3] == "0" && (substr($dev_list[$i][1],0,2) == "md" || substr($dev_list[$i][1],0,3) == "emd")){
                    if(substr($dev_list[$i][1],0,2) == "md"){
                        $mdnum=substr($dev_list[$i][1],2);
                    }else{
                        $mdnum=substr($dev_list[$i][1],3);
                    }
                    if($config["opts"]["target"] == ""){
                        $config["opts"]["target"]="/raid".$mdnum;
                    }else{
                        $config["opts"]["target"].="///raid".$mdnum;
                    }
                    $this->tfull_path=$config["opts"]["target"];
                }else{
                    $ret=false;
                    break;
                }
            }
        }else{
            for($i=0;$i<count($dev_list);$i++){
                $mount_path=$this->getMountPath($config["opts"]["dest_dev"],$config["opts"]["dest_path"],$dev_list[$i][0]);
                $type_list=array("0","1","2");
                if(in_array($config["opts"]["device_type"], $type_list)){
                    switch($config["opts"]["device_type"]){
                        case "1" :
                            if ($dev_list[$i][3] == "1"){
                                $this->texternal_mount=$mount_path;
                            }else{
                                if($this->texternal_mount == ""){
                                    $this->texternal_mount=$mount_path;
                                }else{
                                    $this->texternal_mount.="//".$mount_path;
                                }
                            }
                            $mount_len=$this->get_extern_mount_len($mount_path);
                            break;
                        default:
                            $mount_len=strlen($mount_path)+5;
                            break;
                    }

                    if($dev_list[$i][3] == "1"){
                        $tmp_dev=substr($config["opts"]["dest_dev"],0,5);
                    }else{
                        $tmp_dev=substr($dev_list[$i][0],0,5);
                    }

                    if ($dev_list[$i][3] == "1"){
                        if($tmp_dev!="stack")
                            $app_target=substr($config["opts"]["dest_path"]."/".$dev_list[$i][1],$mount_len);
                        else
                            $app_target=$this->parseStack($config["opts"]["dest_path"]."/".$dev_list[$i][1]);
                        $full_path=$mount_path.$config["opts"]["dest_path"]."/".$dev_list[$i][1];
                    }else{
                        if($tmp_dev!="stack"){
                            $app_target="";
                        } else {
                            $app_target=$dev_list[$i][2];
                        }
                        $full_path=$mount_path;
                    }

                    if($config["opts"]["target"] == ""){
                        $config["opts"]["target"]=$app_target;
                    }else{
                        $config["opts"]["target"].="//".$app_target;
                    }

                    if($i == 0){
                        $this->tfull_path=$full_path;
                    }else{
                        $this->tfull_path.="//".$full_path;
                    }

                }else{
                     $ret=false;
                     break;
                }
            }
        }

/*        echo '<br>config["opts"]["target"]==='.$config["opts"]["target"]."<br>";
        echo '<br>$this->tfull_path==='.$this->tfull_path."<br>";
        echo 'texternal_mount==='.$this->texternal_mount."<br>";*/
        if(!$ret){
            self::$err=self::ERR_TARGET_PATH; // Target Type Error
        }

        return $ret;
    }

    private function parseSourcePath($config){
        $ret=true;
        $dev_list=$this->parseDevList($config["opts"]["src_dev"],$config["opts"]["src_path"],$config["opts"]["src_folder"]);
        if($config["back_type"] == "iscsi"){
            for($i=0;$i<count($dev_list);$i++){
                if($dev_list[$i][3] == "0" && substr($dev_list[$i][1],0,5) == "iscsi"){
                    $config["opts"]["path"]="";
                    if($config["opts"]["folder"] == ""){
                        $config["opts"]["folder"]=$dev_list[$i][2];
                        $this->sfull_path=readlink(self::RAID_PATH."/".$config["opts"]["folder"]);
                    }else{
                        $config["opts"]["folder"].="/".$dev_list[$i][2];
                        $this->sfull_path.="/".readlink(self::RAID_PATH."/".$config["opts"]["folder"]);
                    }
                }else{
                    $ret=false;
                }
            }
        }else{
            $type_list=array("0","1","2");
            if(in_array($config["opts"]["device_type"], $type_list)){
                for($i=0;$i<count($dev_list);$i++){
                    $mount_path=$this->getMountPath($config["opts"]["src_dev"],$config["opts"]["src_path"],$dev_list[$i][0]);
                    $folder="";
                    switch($config["opts"]["device_type"]){
                        case "2" :
                            if($config["opts"]["src_dev"] == "" && $config["opts"]["src_path"] == ""){
                                $config["opts"]["entire_external_copy"]="1";
                                $folder=$dev_list[$i][2]."_".$dev_list[$i][1];
                                if($this->sexternal_mount == ""){
                                    $this->sexternal_mount=$mount_path;
                                }else{
                                    $this->sexternal_mount.="//".$mount_path;
                                }
                            }else{
                                $config["opts"]["entire_external_copy"]="0";
                                $folder=$dev_list[$i][1];
                                $this->sexternal_mount=$mount_path;
                            }

                            $mount_len=$this->get_extern_mount_len($mount_path);
                            break;

                        default:
                            $mount_len=strlen($mount_path)+5;
                            if($config["opts"]["src_dev"] == "" && $config["opts"]["src_path"] == ""){
                                $folder=$dev_list[$i][2];
                            }else{
                                $folder=$dev_list[$i][1];
                            }
                            break;
                    }

                    if($dev_list[$i][3] == "1"){
                        $tmp_dev=substr($config["opts"]["src_dev"],0,5);
                    }else{
                        $tmp_dev=substr($dev_list[$i][0],0,5);
                    }

                    if ($dev_list[$i][3] == "1"){
                        if($tmp_dev!="stack"){
                            $app_source=substr($config["opts"]["src_path"],$mount_len);
                        }else{
                            $app_source=$this->parseStack($config["opts"]["src_path"]);
                        }
                        $full_source=$mount_path.$config["opts"]["src_path"]."/".$folder;
                    }else{
                        $app_source="";
                        $full_source=$mount_path."/".$folder;
                    }

                    if($i == 0){
                        $config["opts"]["folder"]=$folder;
                        $this->sfull_path=$full_source;
                    }else{
                        $config["opts"]["folder"].="/".$folder;
                        $this->sfull_path.="//".$full_source;
                    }
                }
            }else{
                $ret=false;
                break;
            }
        }

        if (!$ret){
            self::$err=self::ERR_SOURCE_PATH; // Source Type Error
        }else{
            $config["opts"]["path"]=$app_source;
        }

/*        echo '<br>config["opts"]["path"]==='.$config["opts"]["path"]."<br>";
        echo '<br>config["opts"]["folder"]==='.$config["opts"]["folder"]."<br>";
        echo '<br>$this->sfull_path==='.$this->sfull_path."<br>";
        echo 'sexternal_mount==='.$this->sexternal_mount."<br>";
        echo $config["opts"]["entire_external_copy"];*/
        return $ret;
    }

    private function checkNoMatch($target,$source){
        $ret=true;
        $preg_s=preg_quote($source,"/");
        $preg_t=preg_quote($target,"/");
        if(preg_match("/^".$preg_t."($|\/)/",$source)||
           preg_match("/^".$preg_s."($|\/)/",$target)){
               $ret=false;
        }
/*        $s_list=explode("/",$source);
        $t_list=explode("/",$target);
        for($i=0;$i<count($s_list);$i++){
            if($s_list[$i] != $t_list[$i]){
                $ret=true;
                break;
            }
        }*/

        return $ret;
    }

    private function checkTargetIncludeSource($config){
        $ret=true;
        if($config["back_type"] != "import" && $config["back_type"] !="import_iscsi"){
            $source_list=explode("//",$this->sfull_path);
            for($i=0;$i<count($source_list);$i++){
                $target_list=explode("//",$this->tfull_path);
                for($j=0;$j<count($target_list);$j++){
                    $ret=$this->checkNoMatch($target_list[$j],$source_list[$i]);
                    if(!$ret){
                        break;
                    }
                }
                if(!$ret){
                       break;
                }
            }
        }

        if (!$ret) {
           self::$err=self::ERR_TARGET_INC_SOURCE; // Path Error
        }

        return $ret;
    }


    private function checkTargetExist($config){
        $ret=true;
        $type_list=array("copy", "schedule", "realtime", "iscsi");
        $target=explode("//",$config["opts"]["target"]);
        $target_list=explode("//",$this->texternal_mount);

        for($i=0;$i<count($target);$i++){
            if(in_array($config["back_type"], $type_list)){
                switch($config["opts"]["device_type"]){
                    case "0":
                    case "2":
                        if(!file_exists(self::RAID_PATH.$target[$i]) || !is_dir(self::RAID_PATH.$target[$i])){
                            $ret=false;
                        }
                        break;
                    case "1":
                        if($target_list[$i] == ""){
                            $target_mount=$target_list[0];
                        }else{
                            $target_mount=$target_list[$i];
                        }

                        if(!file_exists($target_mount.$target[$i]) || !is_dir($target_mount.$target[$i])){
                            $ret=false;
                        }
                        break;
                    default:
                        $ret=false;
                        break;
                }
            }else{
                if(!file_exists(trim($target[$i]))){
                    $ret=false;
                }
            }

            if(!$ret){
                self::$err=self::ERR_TARGET_EXIST;   //target does not exist
                break;
            }
        }

        return $ret;
    }

/*    private function checkTargetDupFolder($config){   //for iscsi backup/schedule
        $ret=true;
        if($config["back_type"] == "iscsi" && $config["back_type"]== "0"){
        }
        if($config["back_type"] == "schdule" && $config["create_sfolder"]=="1"){
            
        }
        if($ret){
            self::$err=0x08002018;   //Target has duplicate folder
        }
        return $ret;
    }
*/
    private function generateTargetTag($config){  //for iscsi backup/schedule
        if($config["back_type"] == "realtime" || $config["back_type"] == "schedule" || $config["back_type"] == "iscsi"){
            $config["opts"]["target_tag"]=".".$config["task_name"]."_".date("U");
        }
        return true;
    }

    private function checkFolderCount($config){
        require_once(WEBCONFIG);

        $ret=true;
        $folder_count=ShareFolder::getFolderCount();
        $src_count=0;
        $share=explode("/",$config["opts"]["folder"]);

        for($i=0;$i<count($share);$i++){
            if(!file_exists(self::RAID_PATH."/".$share[$i])){
                $src_count++;
            }
        }

        $folder_count+=$src_count;

        if( $folder_count >= $webconfig["share_limit"]){
            self::$err=self::ERR_IMPORT_LIMIT;   //Import Source folder count limitation
            $ret=false;
        }

        return $ret;
    }

    private function limitBlank($str,$middle=false){
      $len = strlen($str);
      $result = true;
      $middle_blank=0;
      for($i=0;$i<$len;$i++){
          if(ord($str[$i])==32){
              if($i==0){
                  $result = false;
                  break;
              }else if($i==($len-1)){
                  $result = false;
                  break;
              }else if($middle && $middle_blank>0){
                  $result = false;
                  break;
              }
              $middle_blank++;   
          }else
              $middle_blank=0;
         }
         return $result;
      }

    private function limitstrlen($min,$max,$str){
            $len = iconv_strlen($str, 'utf-8');
            if($len<$min) return false;
            if($len>$max) return false;
            return true;
    }

    private function checkImportTask($config){
        $ret=true;
        if( $config["back_type"] == "import" ){
            $ret=$this->checkFolderCount($config);
            if($ret){
                $exclude_name=array("module","tmp","ftproot","_SYS_TMP","lost+found","sys","data","stackable");
                $exclude_pattern='/[\[\]\!\`\'\"\/\*:<>?\\\|#]/';
                $folder_list=explode("/",$config["opts"]["folder"]);
                for($i=0;$i<count($folder_list);$i++){
                    preg_match($exclude_pattern, $folder_list[$i], $matches);
                    $space_ret=$this->limitBlank($folder_list[$i],true);
                    $len_ret=$this->limitstrlen(0,60,$folder_list[$i]);
                    if(in_array(strtolower($folder_list[$i]),$exclude_name) || $matches || !$space_ret || !$len_ret){
                        $ret=false;
                        self::$err=self::ERR_IMPORT_FOLDER;   //Import Source format has error
                    }
                }
            }
        }
        return $ret;
    }

    private function assembleFileType($type,$config){
        $field_name=$type."_type";
        $type_list= json_decode(file_get_contents(self::CMD_PATH."/type.list"),true);
        $other_search=array("[","]","`");
        $other_replace=array("\[","\]","\`");

        for($i=ord('A');$i<=ord('Z');$i++){
              $c=$i+32;
              $search[]=chr($i);
              $replace[]="[".chr($i).chr($c)."]";
          }
         
        $search=array_merge($other_search,$search);
        $replace=array_merge($other_replace,$replace);

        foreach ($type_list as $field=>$value){
            if($config["opts"][$type."_".$field] == "1"){
                if($config["opts"][$field_name] == ""){
                    $config["opts"][$field_name].=implode(',',str_ireplace($search,$replace,$value));
                }else{
                    $config["opts"][$field_name].=",".implode(',',str_ireplace($search,$replace,$value));
                }
            }
        }

        if($config["opts"][$type."_other"] == "1"){
            if($config["opts"][$field_name] == ""){
                $config["opts"][$field_name].=str_ireplace($search,$replace,$config["opts"][$type."_other_txt"]);
            }else{
                $config["opts"][$field_name].=",".str_ireplace($search,$replace,$config["opts"][$type."_other_txt"]);
            }
        }
    }

    private function parseRealTimeFileType(&$config){
        if($config["back_type"] == "realtime"){
            $this->assembleFileType("include",&$config);
            $this->assembleFileType("exclude",&$config);
/*            echo "<br>include:  ".$config["opts"]["include_type"]."<br>";
            echo "<br>exclude:  ".$config["opts"]["exclude_type"]."<br>";*/
        }

        return true;
    }

    private function changeStatus(&$config){
        if($config["back_type"] == "copy" || $config["back_type"] == "import" || $config["back_type"] == "import_iscsi")
            $config['status']="1";
        return true;
    }

    private function parseImportISCSI(&$config){
        if($config["back_type"]=="import_iscsi"){
            if($config["opts"]["src_dev"] != ""){
                $dev=$config["opts"]["src_dev"];
            }else{
                $dev_list=$this->parseDevList($config["opts"]["src_dev"],$config["opts"]["src_path"],$config["opts"]["src_folder"]);
                $dev=$dev_list[0][1];
            }
            $type=$this->getDevType($dev);
            if($type == "raid"){
                $config["opts"]["device_type"]="0";
            }else{
                $config["opts"]["device_type"]="2";
            }
        }
        return true;
    }

    private function checkTaskStatus($config){
//            echo "checkTaskStatus";
        $type_list=array("copy","import", "iscsi", "realtime", "schedule", "import_iscsi");
        $ret=true;
        
        $ret=in_array($config["back_type"], $type_list);
        if ($ret) {
            $fun_ary=array(
  //              "checkConfig",
                "checkAction",
                "checkNoProcess",
                "checkTaskName",
                "checkTaskCount",
//                "parseImportISCSI",
                "checkConfig",
                "parseTargetPath",
                "parseSourcePath",
                "parseRealTimeFileType",
                "checkSourceCount",
                "checkTargetIncludeSource",
                "checkTargetRaidStatus",
                "checkImportTask",
                "checkTargetExist",
                "checkTargetReadonly",
                "generateTargetTag",
                "changeStatus"
            );

            for($i=0;$i<count($fun_ary);$i++){
                $ret = call_user_func_array(array($this, $fun_ary[$i]), array(&$config));
                if(!$ret){
                    break;
                }
            }
        } else {
            self::$err=self::ERR_BACKUP_TYPE;   //backup type error;
            $ret=false;
        }
     //   var_dump(printf("%x %s",self::$err,$config["opts"]["path"]));
        return $ret;
    }

    private function checkTaskExist($taskid,$taskname){
        $ret=true;
        if ($taskid == "0"){
            self::$err=self::ERR_TASK_NOT_EXISTS;
            $ret=false;
        }else{
            $task_exist = self::getTaskId($taskname);
            if ($task_exist == 0) {
                self::$err=self::ERR_TASK_NOT_EXISTS;
                $ret=false;
            }
        }

        return $ret;
    }

    private function createProcessFlag($task_name){
        $status_file = sprintf(RSYNC_STATUS_FILE, $task_name);
        $fh = fopen($status_file, 'w');
        if($fh != null){
            fwrite($fh, '1');
            fclose($fh);
        }
    }

    private function executeCreate($config){
        switch($config["back_type"]){
            case "copy":
            case "import":
                $this->createProcessFlag($config["task_name"]);
                shell_exec(self::RC_CMD." 'start' ".$config["tid"]." '".$this->texternal_mount."' '".$this->sexternal_mount."' > /dev/null 2>&1 &");
                break;
            case "import_iscsi":
                $this->createProcessFlag($config["task_name"]);
                shell_exec(self::RC_CMD." 'import_iscsi' ".$config["tid"]." '".$this->texternal_mount."' '".$this->sexternal_mount."' > /dev/null 2>&1 &");
                break;
            case "realtime":
                shell_exec(self::RC_CMD." 'create' ".$config["tid"]." '".$this->texternal_mount."' '".$this->sexternal_mount."' > /dev/null 2>&1");
                $this->start();
                break;
            case "schedule":
            case "iscsi":
//                var_dump(self::RC_CMD." 'create' ".$config["tid"]." '".$this->texternal_mount."' '".$this->sexternal_mount."' > /dev/null 2>&1");
                shell_exec(self::RC_CMD." 'create' ".$config["tid"]." '".$this->texternal_mount."' '".$this->sexternal_mount."' > /dev/null 2>&1");
                break;
            default:
                break;
        }
    }

    private function executeModify($config){
        switch($config["back_type"]){
            case "realtime":
            case "schedule":
            case "iscsi":
                shell_exec(self::RC_CMD." 'modify' ".$config["tid"]." '".$this->texternal_mount."' '".$this->sexternal_mount."'");
                break;
            default;
                break;
        }
    }

    function modify($config) {
        // TODO: check $config or something
        $ret=true;
        //var_dump($config["opts"]["dest_folder"]);
        $this->texternal_mount="";
        $thsi->sexternal_mount="";
        $config["opts"]["target"]="";
        $config["opts"]["folder"]="";
        $config["opts"]["path"]="";
        $config["opts"]["include_type"]="";
        $config["opts"]["exclude_type"]="";
//        echo "modify";

        $ret=$this->checkTaskStatus(&$config);
        if($ret){
            $config["opts"]["force"]="1";
            //$config["opts"]["sys_status"]='0';
            self::$config=$config;
            self::save();
            self::closeDb();
            $this->executeModify($config);
        }
        return $ret;
    }

    function start() {
        $ret=true;
        $type_list=array("realtime", "schedule","iscsi");
        if (in_array(self::$config["back_type"], $type_list)){
            $ret=$this->checkTaskExist(self::$config["tid"],self::$config["task_name"]);
            if($ret){
                $ret=$this->checkNoProcess(self::$config);
                if ($ret){
                    if(self::$config["back_type"]=="realtime" && self::$config["act_type"]=="local"){
                        self::$config["opts"]["sys_status"]='1';
                    }
                }
            }
        }else{
            self::$err=self::ERR_ACTION;   //Start action backup type error
            $ret=false;
        }

        if ($ret){
            self::$config['status']="1";
            self::save();
            self::closeDb();
            $this->createProcessFlag(self::$config["task_name"]);

            shell_exec(self::RC_CMD." 'start' ".self::$config["tid"]." > /dev/null 2>&1 &");
        }

        return $ret;
    }

    function stop() {
        $ret=$this->checkTaskExist(self::$config["tid"],self::$config["task_name"]);
        if($ret){
            $status_list=array("1","2","400","401");
            if(!in_array(self::$config["status"],$status_list)){
                self::$err=self::ERR_TASK_STOP;   //Task no action
                $ret=false;
            }
        }

        if ($ret){
            if(self::$config["back_type"]=="realtime" && self::$config["act_type"]=="local"){
                self::$config["opts"]["sys_status"]='0';
            }
            self::$config['status']="2";
            self::save();
            self::closeDb();
            sleep(1);
            shell_exec(self::RC_CMD." 'stop' ".self::$config["tid"]." > /dev/null 2>&1");
        }

        return $ret;
    }

    function listLog() {
        $logfolder="/raid/data/ftproot/".self::$config["opts"]["log_folder"]."/LOG_Data_Guard/";
        $loglist=self::fg("a","ls -u '" . $logfolder . "' | grep ^" . self::$config["task_name"] . "_");
        array_pop($loglist);
        return $loglist;
    }

    function restore() {
        $ret=true;
        if(self::$config["back_type"]=="schedule" || self::$config["back_type"]=="iscsi"){
            $ret=$this->checkTaskExist(self::$config["tid"],self::$config["task_name"]);
            if($ret){
                $ret=$this->checkNoProcess(self::$config);
            }
            if($ret){
                self::$config['status']="1";
                self::save();
                self::closeDb();
                $this->createProcessFlag(self::$config["task_name"]);
                shell_exec(self::RC_CMD." 'restore' ".self::$config["tid"]." > /dev/null 2>&1 &");
            }
        }else{
            $ret=false;
            self::$err=ERR_ACTION; //no restore action
        }
        return false;
    }

    function remove() {
        // TODO: override this method and check everything before remove
        $ret=$this->checkTaskExist(self::$config["tid"],self::$config["task_name"]);
        if($ret){
            $ret=$this->checkNoProcess(self::$config);
        }

        if($ret){
            $logfolder="/raid/data/ftproot/".self::$config["opts"]["log_folder"]."/LOG_Data_Guard/";
            self::fg("a","rm '" . $logfolder . self::$config["task_name"] . "_'*");
            shell_exec(self::RC_CMD." 'remove' ".self::$config["tid"]." > /dev/null 2>&1");
            parent::remove();
        }

        return $ret;
    }

    function status() {
        $status_file = sprintf(RSYNC_STATUS_FILE, self::$config["task_name"]);
        $progress_file="/tmp/rsync_backup_" . self::$config["task_name"] . ".count";
        $count_file = "";
        if(file_exists($status_file)) {
            if(self::$config["status"] == "2"){
                return array(
                    2,
                    '',
                    ''
                );
            }else{
                $backup="start";
                $restore=trim(self::fg("s","ps | grep \" ".self::RC_CMD." 'restore' ".self::$config["tid"]." \" | grep -v grep"));
    
                if($restore != ""){
                    $backup="restore";
                }
    
                $acl_file="/tmp/rsync_".self::$config["task_name"]."_".$backup.".acl";
                if(file_exists($acl_file)){
                    if($backup == "start"){
                        return array(
                           400,
                           '',
                           '',
                        );
                    }else{
                        return array(
                           401,
                           '',
                           ''
                        );
                    }
                }elseif(file_exists($count_file)){
                    $all_count = file($count_file);
                    if(empty($all_count)) {
                        $all_count = 0;
                    } else {
                        $all_count = trim($all_count[0]);
                    }
                    $trans=self::fg("s","sed -nr 's/.*to-check=(.*)\\/(.*)\\)/\\1 \\2/p' " . $progress_file . " | tail -n 1");
                    $trans=explode(" ", $trans);
                    $num1=$trans[1]-$trans[0]+1;
                    $num2=$all_count+$trans[1];
                    if($num2==0){
                        $task_progress = "";
                    }else{
                        $task_progress = "$num1/$num2";
                    }
                }else{
                    $task_progress="";
                }

                $proceed =trim(shell_exec("/img/bin/dataguard/fun.sh get_local_progress $progress_file"));
                return array(
                    1,
                    $proceed,
                    $task_progress
                );
            }
        }

        return array(
            self::$config["status"],
            '',
            ''
        );   
    }
}

?>
