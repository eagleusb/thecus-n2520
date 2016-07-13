<?php
require_once(INCLUDE_ROOT.'dataguard.class.php');
require_once(INCLUDE_ROOT.'rsync.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

class RemoteDataGuard extends DataGuard {
    function __construct($config) {
        //var_dump($config);
        // TODO: override constructor method and check $config to throw execption when any error
        //check task name format
        preg_match("/[^a-zA-Z0-9_-]/",$config["task_name"],$match);
        if( $match[0] != ""){
            throw new Exception("Task name format is not correct.", self::ERR_TASKNAME_FORMAT);
        }
        
        $validate = new validate();
        // check passwrod, single byte only
        if(!$validate->limitstrlen(4,16,$config["opts"]["passwd"]) || !$validate->check_userpwd($config["opts"]["passwd"])) {
            unset($validate);
            throw new Exception("Password format is not correct.", self::ERR_PASSWD_FORMAT);
        }
        if ($config["tid"]==0){
            //check task name is duplicate
            $task_dup = self::getTaskId($config["task_name"]);
           if ($task_dup!=0) {
                unset($validate);
//               throw new Exception("Task name is duplicate.", self::ERR_TASKNAME_DUP);
break;
//It has to break because RPC and remoteDataguard working at the same time. Hwoever, RPCis the default way which cannot be delete.
//So If there is any duplicate task, remoteDataguard class will be break without any alert.
            }
        
            get_sysconf();
            global $sysconf;
            //check now task_count > task limit
            $task_count = self::taskCount();
            if($task_count >= $sysconf["rsync_task_limit"]){
                unset($validate);
                throw new Exception("task_count > task limit", self::ERR_TASK_LIMIT);
            }
        }
        
        unset($validate);
        if (($config["back_type"]=="realtime") && ($config["tid"]==0)){
            $config['status']="1";
        }

        if (! is_numeric($config["timeout"])){
            $config["timeout"]="600";
        }
        
        if (! is_numeric($config["speed_limit"])){
            $config["speed_limit"]="0";
        }

        if ($config["tid"]==0) {
            if ($config["opts"]["remote_back_type"]=="iscsi"){
                $tmp=explode(":", $config["opts"]["src_folder"]);
                $iscsi_full_path=trim(shell_exec("readlink /raid/data/ftproot/".$tmp[1]));
                $config["opts"]["iscsi_full_path"]=$iscsi_full_path;
            }
            
            if($config["back_type"]=="realtime" && $config["act_type"]=="remote"){
                $config["opts"]["sys_status"]='1';
            }

            parent::__construct($config);
            shell_exec(REMOTE_BACKUP_SH_PATH." add_cron \"". self::$config["tid"] . "\" > /dev/null 2>&1");
        } else {
            self::$config = $config;
        }
        
        if (($config["back_type"]=="realtime") && ($config["tid"]==0)){
            shell_exec(REMOTE_BACKUP_SH_PATH." Backup \"". self::$config["tid"] . "\" > /dev/null 2>&1 &");
        }
    }
    
    function modify($config) {
        // TODO: check $config or something
        $tmp=$this->status;
        if ($tmp=="1"){
            self::$err=self::ERR_TASKNAME_RUN;
            return false;
        }
        
        $validate = new validate();
        // check passwrod, single byte only
        if(!$validate->limitstrlen(4,16,$config["opts"]["passwd"]) || !$validate->check_userpwd($config["opts"]["passwd"])) {
            unset($validate);
            self::$err=self::ERR_PASSWD_FORMAT;
            return false;
        }
        
        unset($validate);
        self::$config=$config;
        if (self::$config["back_type"]=="realtime"){
            self::$config['status']="1";
        }

        if (self::$config["opts"]["remote_back_type"]=="iscsi"){
            $tmp=explode(":", self::$config["opts"]["src_folder"]);
            $iscsi_full_path=trim(shell_exec("readlink /raid/data/ftproot/".$tmp[1]));
            self::$config["opts"]["iscsi_full_path"]=$iscsi_full_path;
        }
        
        self::save();
        shell_exec(REMOTE_BACKUP_SH_PATH." del_cron \"".self::$config["tid"]."\" > /dev/null 2>&1");
        shell_exec(REMOTE_BACKUP_SH_PATH." add_cron \"".self::$config["tid"]."\" > /dev/null 2>&1");
        
        if (self::$config["back_type"]=="realtime"){
            shell_exec(REMOTE_BACKUP_SH_PATH." Backup \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
        }
        
        return true;
    }
    
    function start() {
        $tmp=$this->status();
        
        if ($tmp=="1"){
            self::$err=self::ERR_TASKNAME_RUN;
            return false;
        }
        
        if ( ! self::check_task(self::$config["tid"],self::$config["task_name"]))
          return false;
        
        if(self::$config["back_type"]=="realtime" && self::$config["act_type"]=="remote"){
            self::$config["opts"]["sys_status"]='1';
        }
        
        self::$config['status']="1";
        self::save();
        shell_exec(REMOTE_BACKUP_SH_PATH." Backup \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
        return true;
    }
    
    function stop() {
        if ( ! self::check_task(self::$config["tid"],self::$config["task_name"]))
          return false;
          
        if (self::$config['status']!="1"){
          return true;
        }

        if(self::$config["back_type"]=="realtime" && self::$config["act_type"]=="remote"){
            self::$config["opts"]["sys_status"]='0';
        }
        
        self::$config['status']="2";
        self::save();
        shell_exec(REMOTE_BACKUP_SH_PATH." stop \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
        return true;
    }
    
    function listLog() {
        $logfolder="/raid/data/ftproot/".self::$config["opts"]["log_folder"]."/LOG_Data_Guard/";
        $loglist=self::fg("a","ls -u '" . $logfolder . "' | grep ^" . self::$config["task_name"] . "_");
        array_pop($loglist);
        return $loglist;
    }
    
    function restore() {
        $tmp=$this->status();
        if ($tmp=="1"){
            self::$err=self::ERR_TASKNAME_RUN;
            return false;
        }
        
        if ( ! self::check_task(self::$config["tid"],self::$config["task_name"]))
          return false;
          
        self::$config['status']="1";
        self::save();
        shell_exec(REMOTE_BACKUP_SH_PATH." Restore \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
        return true;
    }
    
    static function listNasConfig($config) {
        $ret=self::testConnection($config["opts"]["ip"], $config["opts"]["port"], 'raidroot/_SYS_TMP', $config["opts"]["username"], $config["opts"]["passwd"], "", "remote_conf");
        if (!$ret){
          return;
        }
        
        $passwd_file = "/tmp/rsync_" . $config["opts"]["ip"] . "_passwd";
        self::bg("echo '" . $config["opts"]["passwd"]. "' > " . $passwd_file);
        self::bg("chmod 600 " . $passwd_file);
        $filelist=self::fg("a","/usr/bin/rsync --list-only --port=".$config['opts']['port'] ." \"". $config['opts']['username'] . "@" . $config['opts']['ip'] ."::raidroot/_SYS_TMP/remote_conf/\" --password-file=" . ${passwd_file} );
        self::bg("rm " . $passwd_file);
        
        $configlist=array();
        
        foreach($filelist as $file){
            if( $file == "" ) break;
            $filedate=self::fg("s","echo \"". $file . "\" | awk '{print \$3\" \"\$4}'");
            $filename=self::fg("s","echo \"". $file . "\" | awk '{print \$5}'");
            if (($filename!=".") && ($filename!=".."))
                array_push($configlist,array($filename, $filedate));
        }
        
        return $configlist;
    }
    
    static function getNasConfig($config, $fielname) {
        $tarfolder="/raid/data/tmp/mgmt_nasconfig";
        $ret=self::testConnection($config["opts"]["ip"], $config["opts"]["port"], 'raidroot/_SYS_TMP', $config["opts"]["username"], $config["opts"]["passwd"], "", "remote_conf");
        if (!$ret){
          return;
        }

        self::fg("s", "/img/bin/dataguard/mgmt_nasconfig.sh getconf '" . $fielname . "' '" . $config["opts"]["username"] . "' '" . $config["opts"]["passwd"] . "' '". $config["opts"]["ip"] . "' '". $config["opts"]["port"] . "'");
        if (file_exists($tarfolder."/conf.bin") && file_exists($tarfolder."/raidsys")){
            $enckey="conf_".trim(shell_exec('/img/bin/check_service.sh key'));
            shell_exec('/usr/bin/des -k ' . $enckey . ' -D ' .$tarfolder. '/conf.bin /tmp/conf.tar.gz 2>&1');
            exec('mkdir -p /tmp/conf;tar zxf /tmp/conf.tar.gz -C /tmp/conf',$stdout,$result);
            if($result){
                self::$err=self::ERR_CONFIG_FILE;
                return;
            }
            
            return true;
        }else{
            self::$err=self::ERR_CONFIG_FILE;
            return;
        }
    }
    
    static function checkNasConfig() {
        $tarfolder="/raid/data/tmp/mgmt_nasconfig";
        $remoteraid_arr=self::fg("a", "/img/bin/dataguard/mgmt_nasconfig.sh raidnum_id '". $tarfolder."/raidsys" . "'");
        for( $i = 0 ; $i < count($remoteraid_arr) ; ++$i ) {
            if( $remoteraid_arr[$i] == "" ) {
                unset($remoteraid_arr[$i]);
                break;
            }
            $remoteraid_arr[$i] = explode("|", $remoteraid_arr[$i]);
        }
        // [[raidnum, raid id], [raidnum, raid id], [raidnum, raid id]]
        return $remoteraid_arr;
    }

    static function restoreNasConfig($raidmap) {
        $tarfolder="/raid/data/tmp/mgmt_nasconfig";
        for ($i=0; $i<count($raidmap);$i++){
            self::fg("a", "/img/bin/dataguard/mgmt_nasconfig.sh raid '" . $raidmap[$i][0] . "' '" . $tarfolder . "/raidsys/" . $raidmap[$i][1] . "'");
        }
        
        shell_exec("rm -rf ".$tarfolder);
        shell_exec("mv /tmp/conf.tar.gz /etc");
        return true;
    }
    
    function remove() {
        // TODO: override this method and check everything before remove
        $tmp=$this->status();
        if ($tmp=="1"){
            self::$err=self::ERR_TASKNAME_RUN;
            return false;
        }
        
        shell_exec(REMOTE_BACKUP_SH_PATH." del_cron \"".self::$config["tid"]."\" > /dev/null 2>&1");
        $logfolder="/raid/data/ftproot/".self::$config["opts"]["log_folder"]."/LOG_Data_Guard/";
        self::fg("a","rm '" . $logfolder . self::$config["task_name"] . "_'*");
        parent::remove();
        return true;
    }
    
    static function check_task($taskid,$taskname) {
        if ($taskid=="0"){
            self::$err=self::ERR_TASK_NOT_EXISTS;
            return false;
        }else{
            $task_exist = self::getTaskId($taskname);
            if ($task_exist==0) {
                self::$err=self::ERR_TASK_NOT_EXISTS;
                return false;
            }
        }
        return true;
    }

    function status() {
        $status_file = sprintf(RSYNC_STATUS_FILE, self::$config["task_name"]);
        if (file_exists($status_file) && (self::$config["status"]=="1")) {
            $progress_file="/tmp/rsync_" . self::$config["task_name"] . "_progress";
            $count_file = sprintf(RSYNC_SRC_COUNT_FILE, self::$config["task_name"]);
            $all_count = file($count_file);
            if (empty($all_count)) {
                $all_count = 0;
            } else {
                $all_count = trim($all_count[0]);
            }
            
            if (file_exists($progress_file)){
                $trans=self::fg("s","sed -nr 's/.*to-check=(.*)\\/(.*)\\)/\\1 \\2/p' " . $progress_file . " | tail -n 1");
                $trans=explode(" ", $trans);
                $num1=$trans[1]-$trans[0]+1;
                $num2=$all_count+$trans[1];
                if ($num2==0){
                    $task_progress = "";
                }else{
                    $task_progress = "$num1/$num2";
                }
            }else{
                $task_progress="";
            }

            $proceed =trim(shell_exec("/img/bin/dataguard/fun.sh get_progress $progress_file"));
    
            return array(
                1,
                $proceed,
                $task_progress
            );        
        }
        
        return array(
            self::$config["status"],
            '',
            ''
        );        
    }

    static function testConnection($host, $port, $dest_folder, $id, $password, $path, $folder, $encrypt = 0) {
        $folderlist="";
        $path=trim(shell_exec("echo \"". $path . "\"  | sed 's/^\/raid[0-9]\/data//g'"));
        $path=trim(shell_exec("echo \"". $path . "\"  | sed 's/^\/raid6[0-9]\/data//g'"));
        
        //if it is iscsi backup, modify the folder content, for example: '/iscsi_test:iSCSI_test'
        if (strpos($folder, ":")){
            $tmp=explode(":", $folder);
            $folder=$tmp[1];
        }
        
        $folderlist=str_replace("/","::",$folder);
        
        if ($path==""){
            $testfolder=$folderlist;
        }else {
            $tmp=explode("/", $path);
            $testfolder=$tmp[1];
        }
        
        if ($testfolder=="")
          $testfolder="raidroot";
        
        $paras=array(
            'taskname'=>$host,
            'ip'=>$host,
            'port'=>$port,
            'dest_folder'=>$dest_folder,
            'username'=>$id,
            'passwd'=>$password,
            'encrypt_on'=>$encrypt,
            'folder'=>$testfolder);

        $rsync = new Rsync();
        $ret = $rsync->connTest($paras);
        unset($rsync);

        if ($ret=='707'){
            //var_dump($ret);
            return true;
        }else{
            self::$err=self::ERR_BASE_CODE + hexdec($ret);
            return false;
        }
    }
}
?>
