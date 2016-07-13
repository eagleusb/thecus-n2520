<?php
require_once(INCLUDE_ROOT.'dataguard.class.php');
require_once(INCLUDE_ROOT.'validate.class.php');

class S3DataGuard extends DataGuard {
    function __construct($config) {
        //var_dump($config);
        // TODO: override constructor method and check $config to throw execption when any error
        //check task name format
        preg_match("/[^a-zA-Z0-9_-]/",$config["task_name"],$match);
        if( $match[0] != ""){
            throw new Exception("Task name format is not correct.", self::ERR_TASKNAME_FORMAT);
        }
        
        if ($config["tid"]==0){
            //check task name is duplicate
            $task_dup = self::getTaskId($config["task_name"]);
            if ($task_dup!=0) {
                throw new Exception("Task name is duplicate.", self::ERR_TASKNAME_DUP);
            }
        
            get_sysconf();
            global $sysconf;
            //check now task_count > task limit
            $task_count = self::taskCount('remote');
            if($task_count >= $sysconf["rsync_task_limit"]){
                throw new Exception("task_count > task limit", self::ERR_TASK_LIMIT);
            }
        }
        
        parent::__construct($config);

        if ($config["tid"]==0) {
            shell_exec("/img/bin/dataguard/s3_backup.sh add_cron \"" . self::$config["tid"] ."\" > /dev/null 2>&1");
        }
    }
    
    function modify($config) {
        // TODO: check $config or something
        $tmp=$this->status;
        if ($tmp=="1"){
            self::$err=self::ERR_TASKNAME_RUN;
            return false;
        }
        
        self::$config=$config;
        self::save();
        self::closeDb();
        shell_exec("/img/bin/dataguard/s3_backup.sh del_cron \"".self::$config["tid"]."\" > /dev/null 2>&1");
        shell_exec("/img/bin/dataguard/s3_backup.sh add_cron \"".self::$config["tid"]."\" > /dev/null 2>&1");
        
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

        self::$config['status']="1";
        self::save();
        self::closeDb();
        shell_exec("/img/bin/dataguard/s3_backup.sh Backup \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
        return true;
    }
    
    function stop() {
        if ( ! self::check_task(self::$config["tid"],self::$config["task_name"]))
          return false;

        self::$config['status']="2";
        self::save();
        self::closeDb();
        shell_exec("/img/bin/dataguard/s3_backup.sh stop \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
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
        self::closeDb();
        shell_exec("/img/bin/dataguard/s3_backup.sh Restore \"".self::$config["tid"]."\" > /dev/null 2>&1 &");
        return true;
    }
    
    function remove() {
        // TODO: override this method and check everything before remove
        $tmp=$this->status();
        if ($tmp=="1"){
            self::$err=self::ERR_TASKNAME_RUN;
            return false;
        }

        shell_exec("/img/bin/dataguard/s3_backup.sh del_cron \"".self::$config["tid"]."\" > /dev/null 2>&1");
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
        $status_file = sprintf("/tmp/s3_backup_%s.status", self::$config["task_name"]);
        if (file_exists($status_file)) {
            $log_file="/raid/data/tmp/s3_backup." . self::$config["task_name"];
            $progress_file="/raid/data/tmp/s3_" . self::$config["task_name"] . "_progress";

            if (file_exists($log_file)){
                $task_progress = self::fg("s","tail -n 1 " . $log_file);
            }

            if (file_exists($progress_file)){
                $proceed = "<br>".self::fg("s","tail -n 1 " . $progress_file);
            }
    
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

    static function testConnection($dest_folder, $id, $password) {
        if ($dest_folder==""){
            self::$err=0x08001703;
            return false;
        }
        
        $cmd = '/img/bin/dataguard/s3_test.sh "'.$id. '" "'.$id. '" "'.$password. '" "'.$dest_folder. '"';
        $output = shell_exec($cmd);
        $ret = trim(substr( strrchr( $output, " " ), 1 ));

        if ($ret=='707'){
            return true;
        }else{
            self::$err=self::ERR_BASE_CODE + hexdec($ret);
            return false;
        }
    }
}
?>
