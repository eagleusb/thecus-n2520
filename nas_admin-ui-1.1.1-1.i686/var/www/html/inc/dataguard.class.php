<?php
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'commander.class.php');

abstract class DataGuard extends Commander {
    const DB_FILE = "/etc/cfg/backup.db";
    const LOG_FILE = "/raid/data/ftproot/%s/LOG_Data_Guard/%s";
    const SQL_INIT_TASK = "CREATE TABLE task (tid INTEGER PRIMARY KEY, task_name, back_type, act_type, last_time, status);";
    const SQL_INIT_OPTS = "CREATE TABLE opts (tid, key, value);";
    const SQL_INSERT_TASK = "INSERT INTO task (task_name, back_type, act_type, last_time, status) VALUES('%s', '%s', '%s', '%s', '%s');";
    const SQL_INSERT_OPTS = "INSERT INTO opts VALUES(%d, '%s', '%s');";
    const SQL_DELETE_TASK = "DELETE FROM task WHERE tid = %d;";
    const SQL_DELETE_OPTS = "DELETE FROM opts WHERE tid = %d;";
    const SQL_UPDATE_TASK = "UPDATE task SET task_name='%s', back_type='%s', act_type='%s', last_time='%s', status='%s' WHERE tid = %d;";
    const SQL_UPDATE_OPTS = "UPDATE opts SET value='%s' WHERE key='%s';";
    const SQL_QUERY_TASK = "SELECT * FROM task WHERE tid = %d;";
    const SQL_QUERY_TASKS = "SELECT * FROM task;";
    const SQL_QUERY_OPTS = "SELECT key, value FROM opts WHERE tid = %d;";
    const SQL_QUERY_ALL = "SELECT task.*, opts.key, opts.value FROM task LEFT JOIN opts ON task.tid = opts.tid";
    
    const ERR_LOG_NOT_EXISTS        = 0x08000001;
    const ERR_CFG_ILLEGAL           = 0x08000002;
    const ERR_BASE_CODE             = 0x08001000;
    const ERR_TASKNAME_FORMAT       = 0x08001001;    //Taskname 格式錯誤
    const ERR_PASSWD_FORMAT         = 0x08001002;    //密碼格式錯誤
    const ERR_TASKNAME_DUP          = 0x08001003;    //Taskname 重複
    const ERR_TASK_LIMIT            = 0x08001004;    //Task數量超過限制
    const ERR_TASK_NOT_EXISTS       = 0x08001005;    //Task不存在
    const ERR_TASK_DUP              = 0x08001006;    //Task重複
    const ERR_TASKNAME_RUN          = 0x08001007;    //Task正在執行
    const ERR_CONFIG_FILE           = 0x08001008;    //Restore NAS Config but file error
    const ERR_VERSION_MODEL         = 0x08001009;    //The fw version or model name is different between local nas and remote conf.bin
    const ERR_SOURCE_NOT_EXIST      = 0x08001010;    //Source folder is not existed when restore
    const ERR_TASKNAME_EMPTY        = 0x08001011;    //Taskname is empty        

    const ERR_TARGET_CONN_FAIL      = 0x08001700;    //Target server connection failed.
    const ERR_AUTH                  = 0x08001701;    //User authentication failed.
    const ERR_TARGET_TIMEOUT        = 0x08001702;    //Target Server Connection timeout.
    const ERR_FOLDER_NOT_EXISTS     = 0x08001703;    //Target folder [ %s ] is not exist.
    const ERR_PERMISSION_DENY       = 0x08001704;    //Permission deny.
    const ERR_CREATE_TARGET_FOLDER  = 0x08001705;    //Test create target directory error.
    const ERR_TRANSFER              = 0x08001706;    //Test transfer file error.
    const ERR_OUT_SPACE             = 0x08001708;    //Out of space.
    const ERR_MAX_CONNECTIONS       = 0x08001709;    //Max connections of target are reached.
    const ERR_UNKNOWN               = 0x08001710;    //Unknown failed.
    const ERR_ENCRYPT_FAIL          = 0x08001711;    //Encryption connection failed.
    const ERR_ENCRYPT_REFUSE        = 0x08001712;    //Encryption Connection refused.
    const ERR_REMOTE_CLOSE          = 0x08001713;    //Connection closed by remote host.
    const ERR_TIME_LARGE            = 0x08001714;    //The time difference between local and S3 host is too large.

    const ERR_TARGET_RAID           = 0x08002001;    //Target Raid is not healthy or degrade.
    const ERR_ACTION                = 0x08002002;    //This task does not execute action
    const ERR_SOURCE_COUNT          = 0x08002003;    //This task only select one source folder
    const ERR_TARGET_READONLY       = 0x08002004;    //Target is readonly
    const ERR_CONFIG                = 0x08002005;    //Conifg of task is error
    const ERR_TARGET_PATH           = 0x08002006;    //Path of target has error
    const ERR_SOURCE_PATH           = 0x08002007;    //Path of source has error
    const ERR_TARGET_INC_SOURCE     = 0x08002008;    //Target include Source
    const ERR_TARGET_EXIST          = 0x08002009;    //Target does not exist
    const ERR_IMPORT_LIMIT          = 0x08002010;    //Total Folder is over limitation
    const ERR_IMPORT_FOLDER         = 0x08002011;    //Name format of source folder is not correct (name do not include "module","tmp","ftproot","_SYS_TMP","lost+found","sys","data","stackable", name does not has []!`'"/*:<>?\|# , name has continue space)
    const ERR_BACKUP_TYPE           = 0x08002012;    //No this Backup Type
    const ERR_TASK_STOP             = 0x08002013;    //Task have no any backup/restore
    
    static protected $err = 0;
    static protected $db = null;
    static protected $config = array();
    
    function __construct($config) {
        self::$config = $config;
        
        self::save();
    }
    
    function __destruct() {
        if( isset(self::$db) ) {
            self::$db = null;
        }
    }
    
    protected function openDb() {
        if( isset(self::$db) ) {
            return;
        }
        if( !file_exists(self::DB_FILE) ) {
            (self::$db = new PDO("sqlite:".self::DB_FILE)) || (self::$db = new PDO("sqlite2:".self::DB_FILE));
            self::$db->beginTransaction();
            self::$db->exec(self::SQL_INIT_TASK);
            self::$db->exec(self::SQL_INIT_OPTS);
            self::$db->commit();
        } else {
            (self::$db = new PDO("sqlite:".self::DB_FILE)) || (self::$db = new PDO("sqlite2:".self::DB_FILE));
        }
    }
    
    protected function closeDb() {
        self::$db = null;
    }
    
    
    protected static function save() {
        self::openDb();
        
        if( self::$config["tid"] != 0 ) {
            self::$db->beginTransaction();
            $task = sprintf(
                self::SQL_UPDATE_TASK,
                self::$config["task_name"],
                self::$config["back_type"],
                self::$config["act_type"],
                self::$config["last_time"],
                self::$config["status"],
                self::$config["tid"]
            );
            self::$db->exec($task);
            $del = sprintf(
                self::SQL_DELETE_OPTS,
                self::$config["tid"]
            );
            self::$db->exec($del);
            foreach( self::$config["opts"] as $key => $value ) {
                $value=str_replace("'","''",$value);
                $opts .= sprintf(
                    self::SQL_INSERT_OPTS,
                    self::$config["tid"],
                    $key,
                    $value
                );
            }
            self::$db->exec($opts);
            self::$db->commit();
        } else {
            self::$db->beginTransaction();
            $task = sprintf(
                self::SQL_INSERT_TASK,
                self::$config["task_name"],
                self::$config["back_type"],
                self::$config["act_type"],
                self::$config["last_time"],
                self::$config["status"]
            );
            self::$db->exec($task);
            self::$config["tid"] = self::$db->lastInsertId();
            foreach( self::$config["opts"] as $key => $value ) {
                $value=str_replace("'","''",$value);
                $opts .= sprintf(
                    self::SQL_INSERT_OPTS,
                    self::$config["tid"],
                    $key,
                    $value
                );
            }
            self::$db->exec($opts);
            self::$db->commit();
        }
        
        self::closeDb();
    }
    
    static function listTask() {
        self::openDb();
        $tasks = array();
        
        if( ( $st1 = self::$db->query(self::SQL_QUERY_TASKS)) == false ) {
            return $tasks;
        }
        
        $result1 = $st1->fetchAll(PDO::FETCH_ASSOC);
        for( $i = 0 ; $i < count($result1) ; ++$i ) {
            $row1 = &$result1[$i];
            $task = array(
                "tid"       => $row1["tid"] + 0,
                "task_name" => $row1["task_name"],
                "back_type" => $row1["back_type"],
                "act_type"  => $row1["act_type"],
                "last_time" => $row1["last_time"],
                "status"    => $row1["status"],
                "opts"      => array()
            );
            $opts = &$task["opts"];
            
            $cmd = sprintf(self::SQL_QUERY_OPTS, $task["tid"]);
            $st2 = self::$db->query($cmd);
            $result2 = $st2->fetchAll(PDO::FETCH_ASSOC);
            for( $j = 0 ; $j < count($result2) ; ++$j ) {
                $row2 = &$result2[$j];
                $opts[$row2["key"]] = $row2["value"];
            }
            unset($result2);
            unset($st2);
            array_push($tasks, $task);
        }
        
        self::closeDb();
        return $tasks;
    }
    
    static function getTaskId($name = "") {
        self::openDb();
        $cmd = sprintf("SELECT tid FROM task WHERE task_name='%s';", $name);
        $st = self::$db->query($cmd);
        $result = $st->fetchAll(PDO::FETCH_ASSOC);
        if( $result ) {
            $tid = $result[0]["tid"] + 0;
        } else {
            $tid = 0;
        }
        self::closeDb();
        return $tid;
    }
    
//    static function taskCount($type = "local") {
    static function taskCount() {
        self::openDb();
//        $cmd = sprintf("SELECT * FROM task WHERE act_type='%s';", $type);
        $cmd = "SELECT * FROM task;";
        $st = self::$db->query($cmd);
        $result = $st->fetchAll(PDO::FETCH_ASSOC);
        $count = count($result);
        self::closeDb();
        return $count;
    }
    
    static function getLastError() {
        return self::$err;
    }
    
    static private function makeObject(&$config) {
        try {
            switch( $config["act_type"] ) {
            case "local":
                require_once(INCLUDE_ROOT.'localguard.class.php');
                return new LocalDataGuard($config);
            case "remote":
                require_once(INCLUDE_ROOT.'remoteguard.class.php');
                return new RemoteDataGuard($config);
            case "s3":
                require_once(INCLUDE_ROOT.'S3.class.php');
                return new S3DataGuard($config);
            }
        } catch(Exception $e) {
            self::$err = $e->getCode();
        }
    }
    
    static function create($config) {
        return self::makeObject($config);
    }
    
    static function load($tid) {
        self::openDb();
        
        $cmd = sprintf(self::SQL_QUERY_TASK, $tid);
        $task = self::$db->query($cmd);
        $rs = $task->fetchAll(PDO::FETCH_ASSOC);
        if( count($rs) != 1 ) {
            self::$err = self::ERR_TASK_NOT_EXISTS;
            return;
        }
        
        $config = $rs[0];
        $config["opts"] = array();
        
        $cmd = sprintf(self::SQL_QUERY_OPTS, $tid);
        $opts = self::$db->query($cmd);
        $rs = $opts->fetchAll(PDO::FETCH_ASSOC);
        
        for( $i = 0 ; $i < count($rs) ; ++$i ) {
            $key = &$rs[$i]["key"];
            $value = &$rs[$i]["value"];
            $config["opts"][$key] = $value;
        }
        
        return self::makeObject($config);
    }
    
    function remove() {
        if( !isset(self::$config["tid"]) ) {
            return false;
        }
        $tid = self::$config["tid"];
        self::openDb();
        
        $task = sprintf(self::SQL_DELETE_TASK, $tid);
        $opts = sprintf(self::SQL_DELETE_OPTS, $tid);
        
        self::$db->beginTransaction();
        self::$db->exec($task);
        self::$db->exec($opts);
        self::$db->commit();
        
        self::closeDb();
        
        self::$config = array();
        return true;
    }
    
    function getLog($file) {
        if( self::$config["tid"] == 0 ) {
            self::$err = self::ERR_CFG_ILLEGAL;
            return null;
        }
        if( self::$config["opts"]["log_folder"] ) {
            $file = sprintf(self::LOG_FILE, self::$config["opts"]["log_folder"], $file);
            if( file_exists($file) ) {
                return file_get_contents($file);
            } else {
                self::$err = self::ERR_LOG_NOT_EXISTS;
            }
        } 
    }
    
    function getTid() {
        return self::$config["tid"] + 0;
    }
    
    abstract function modify($config);
    abstract function start();
    abstract function stop();
    abstract function listLog();
    abstract function restore();
    abstract function status();
}
?>
