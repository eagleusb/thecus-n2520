<?php
require_once(INCLUDE_ROOT.'commander.class.php');
require_once(INCLUDE_ROOT.'rpc.class.php');

class AccessLog extends Commander {
    const SYSTEM_CONF_DB = "/etc/cfg/conf.db";
    const DEFAUL_FILE = "/raid/data/tmp/access.csv";
    
    static function changeRole(&$params) {
        $conn = new PDO("sqlite:".AccessLog::SYSTEM_CONF_DB);
        $sql = "INSERT OR REPLACE INTO conf VALUES(:key, :value)";
        $stmt = $conn->prepare($sql);
        $conn->beginTransaction();
        foreach( $params as $key => &$value ) {
            $stmt->bindParam(':key', $key);
            $stmt->bindParam(':value', $value);
            $stmt->execute();
        }
        $result = $conn->commit();
        self::fg(NULL, "/img/bin/rc/rc.syslogd restart");
        return $result;
    }
    
    static function getRole() {
        $conn = new PDO("sqlite:".AccessLog::SYSTEM_CONF_DB);
        $sql = "SELECT v FROM conf WHERE k ='size_items' or k ='role' ORDER BY v ASC";
        $st = $conn->query($sql);
        return $st->fetchAll(PDO::FETCH_COLUMN);
    }
    
    static function generateCSV($db, $sql, $head, $file = AccessLog::DEFAUL_FILE) {
        unlink($file);
        file_put_contents($file, $head);
        shell_exec("/usr/bin/sqlite -csv $db \"$sql\" >> $file");
    }
    
    static function export($file = AccessLog::DEFAUL_FILE) {
        $date = date("Ymds");
        header("Content-Type: application/octet-stream");
        header("Pragma:");
        header("Cache-Control:");
        header("Content-Disposition: attachment; filename=$date.log.csv");
        header("Content-length: " . filesize($file));
        readfile($file);
    }
    
    static function query($db, $filter, $total) {
        $result = array();
        if( filesize($db) == 0 ) {
            return;
        }
        $conn = new PDO("sqlite:$db");
        
        $stmt = $conn->prepare($filter[0]);
        $stmt->execute($filter[1]);
        $result []= $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $stmt = $conn->prepare($total[0]);
        $stmt->execute($total[1]);
        $result []= $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        unset($stmt);
        unset($conn);
        
        return $result;
    }
    
    static function remove($db, $filter) {
        $conn = new PDO("sqlite:$db");
        $conn->beginTransaction();
        $stmt = $conn->prepare($filter[0]);
        $result = $stmt->execute($filter[1]);
        $conn->commit();
        return $result;
    }
}

class SystemLog extends AccessLog {
    const SYSTEM_DB = "/syslog/sys_log.db";
    const SYSTEM_DB_HEAD = "Date_time, level, Details";
    const SYSTEM_CSV = "/raid/data/tmp/syslog.csv";
    const SYSTEM_CSV_HEAD = "\xEF\xBB\xBFDate, Level, Event\n";
    
    static function export($level) {
        if( $level === "all" ) {
            $level = "%";
        }
        $sql = sprintf(
            "
                SELECT %s
                FROM sysinfo
                WHERE
                    level LIKE '%s'
                ORDER BY Date_time DESC, ROWID DESC
            ",
            SystemLog::SYSTEM_DB_HEAD,
            $level
        );
        parent::generateCSV(
            SystemLog::SYSTEM_DB,
            $sql,
            SystemLog::SYSTEM_CSV_HEAD,
            SystemLog::SYSTEM_CSV
        );
        
        parent::export(SystemLog::SYSTEM_CSV);
    }
    
    static function query($params) {
        if( $params["level"] === "all" ) {
            $params["level"] = "%";
        }
        $result = parent::query(
            SystemLog::SYSTEM_DB,
            array(
                "
                    SELECT
                        Date_time as time,
                        Details as event,
                        lower(level) as level
                    FROM sysinfo
                    WHERE
                        level LIKE :level
                    ORDER BY time DESC, ROWID DESC
                    LIMIT :start, :limit
                ",
                array(
                    ":level" => $params["level"],
                    ":start" => $params["start"],
                    ":limit" => $params["limit"]
                )
            ),
            array(
                "
                    SELECT
                        count(*) as total
                    FROM sysinfo
                    WHERE
                        level LIKE :level
                ",
                array(
                    ":level" => $params["level"]
                )
            )
        );
        
        if( $result == null ) {
            return array("data" => array(), "total" => 0);
        }
        return array(
            "data" => &$result[0],
            "total" => $result[1][0]["total"] + 0
        );
    }
    
    static function remove($level) {
        if( $level === "all" ) {
            $level = "%";
        }
        return parent::remove(
            SystemLog::SYSTEM_DB,
            array(
                "
                    DELETE FROM sysinfo
                    WHERE
                        lower(level) LIKE :level
                ",
                array(
                    ":level" => $level
                )
            )
        );
    }
}

class ServiceLog extends AccessLog {
    const SERVICE_DB = "/raid/data/tmp/access.db";
    const SERVICE_DB_HEAD = "Date_time, level, Users, Source_ip, Computer_name, size, Event, filetype, action";
    const SERVICE_CSV = "/raid/data/tmp/servicelog.csv";
    const SERVICE_CSV_HEAD = "\xEF\xBB\xBFDate, Level, User Name, Source IP, Computer Name, Size, Event, File Type, Action\n";
    
    static function export($level, $catagory) {
        if( $level === "all" ) {
            $level = "%";
        }
        $sql = sprintf(
            "
                SELECT %s
                FROM access_info
                WHERE
                    Connection_type LIKE '%s'
                    AND
                    level LIKE '%s'
                ORDER BY Date_time DESC, ROWID DESC
            ",
            ServiceLog::SERVICE_DB_HEAD,
            $catagory,
            $level
        );
        parent::generateCSV(
            ServiceLog::SERVICE_DB,
            $sql,
            ServiceLog::SERVICE_CSV_HEAD,
            ServiceLog::SERVICE_CSV
        );
        
        parent::export(ServiceLog::SERVICE_CSV);
    }
    
    static private function assambleCondition(&$params, $limit = true) {
        $conditions = array();
        foreach( $params as $key => $value ) {
            $value = ($value === "all") ? "%" : $value;
            if( $key == "start" || $key == "limit" ) {
                if( $limit ) {
                    $conditions[":$key"] = $value;
                }
            } else {
                $conditions[":$key"] = $value;
            }
        }
        
        if( !isset($conditions[":user"]) )
            $conditions[":user"] = "%";
        
        if( !isset($conditions[":ip"]) )
            $conditions[":ip"] = "%";
        
        if( !isset($conditions[":computer"]) )
            $conditions[":computer"] = "%";
        
        if( !isset($conditions[":filetype"]) )
            $conditions[":filetype"] = "%";
            
        if( !isset($conditions[":action"]) )
            $conditions[":action"] = "%";
        
        return $conditions;
    }
    
    static function query(&$params) {
        $result = parent::query(
            ServiceLog::SERVICE_DB,
            array(
                "
                    SELECT
                        lower(Connection_type) as catagory,
                        Date_time as time,
                        Users as user,
                        Source_ip as ip,
                        Computer_name as computer,
                        size,
                        Event as event,
                        lower(level) as level,
                        filetype,
                        action
                    FROM access_info
                    WHERE
                        catagory LIKE :catagory
                        AND
                        user LIKE :user
                        AND
                        ip LIKE :ip
                        AND
                        computer LIKE :computer
                        AND
                        filetype LIKE :filetype
                        AND
                        action LIKE :action
                        AND
                        level LIKE :level
                    ORDER BY time DESC, ROWID DESC
                    LIMIT :start, :limit
                ",
                self::assambleCondition($params)
            ),
            array(
                "
                    SELECT
                        count(*) as total
                    FROM access_info
                    WHERE
                        Connection_type LIKE :catagory
                        AND
                        Users LIKE :user
                        AND
                        Source_ip LIKE :ip
                        AND
                        Computer_name LIKE :computer
                        AND
                        filetype LIKE :filetype
                        AND
                        action LIKE :action
                        AND
                        level LIKE :level
                ",
                self::assambleCondition($params, false)
            )
        );
        
        if( $result == null ) {
            return array("data" => array(), "total" => 0);
        }
        return array(
            "data" => &$result[0],
            "total" => $result[1][0]["total"] + 0
        );
    }
    
    static function remove($level, $catagory) {
        if( $level === "all" ) {
            $level = "%";
        }
        return parent::remove(
            ServiceLog::SERVICE_DB,
            array(
                "
                    DELETE FROM access_info
                    WHERE
                        lower(Connection_type) LIKE :catagory
                        AND
                        lower(level) LIKE :level
                ",
                array(
                    ":catagory" => $catagory,
                    ":level" => $level
                )
            )
        );
    }
}

class AccessLogRPC extends RPC {
    function query($params) {
        if( $params["catagory"] == "sys" ) {
            return self::fireEvent(SystemLog::query($params));
        } else {
            return self::fireEvent(ServiceLog::query($params));
        }
    }
    
    function remove($params) {
        if( $params["catagory"] == "sys" ) {
            return self::fireEvent(SystemLog::remove($params["level"]));
        } else {
            return self::fireEvent(ServiceLog::remove($params["level"], $params["catagory"]));
        }
    }
    
    function changeRole($params) {
        return self::fireEvent(AccessLog::changeRole($params));
    }
    
    function download($params) {
        if( $params["catagory"] == "sys" ) {
            SystemLog::export($params["level"]);
        } else {
            ServiceLog::export($params["level"], $params["catagory"]);
        }
    }
}
?>
