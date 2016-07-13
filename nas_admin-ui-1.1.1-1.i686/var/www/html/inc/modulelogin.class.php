<?php
require_once(INCLUDE_ROOT.'commander.class.php');
require_once(INCLUDE_ROOT.'rpc.class.php');
require_once(WEBCONFIG);

class ModuleLogin extends Commander {
    static private $SQL_STATEMENT = "INSERT OR REPLACE INTO conf VALUES(:pkg, :status);";
    
    static function getModuleStatus() {
        $pkgs = self::fg("a", "ls -1 /opt");
        $pkgs = preg_grep("/WebDisk|Piczza/", $pkgs);
        $loadWebconfig = require '/var/www/html/webinfo/webconfig';
        
        
        $conn = new PDO("sqlite:/etc/cfg/conf.db");

        $result = array();
        $status = array();
        
        foreach ($pkgs as $k => $v){
            if ($v === "") {
                continue;
            }
            $status[$v] = false;
            $result []= array("module" => $v, "status" => &$status[$v]);
        }

        if ($webconfig['odm']['module_odm']=="1"){
            $stmt = $conn->query("SELECT k AS `module`, v AS `status` FROM conf WHERE k='module'");
            $records = $stmt->fetchAll(PDO::FETCH_BOTH);
            if ($records[0]["status"]=="1"){
                $result []= array("module" => "Module", "status" => true);
            }else{
                $result []= array("module" => "Module", "status" => false);
            }
        }
        
        $stmt = $conn->query("SELECT k AS `module`, v AS `status` FROM conf WHERE k LIKE 'mod_%_login'");
        $records = $stmt->fetchAll(PDO::FETCH_BOTH);
        
        for ($i = 0 ; $i < count($records) ; ++$i) {
            preg_match("/mod_([^_]*)_login/", $records[$i]["module"], $module);
            $module = $module[1];
            
            $status[$module] = (!!+$records[$i]["status"]);
        }
        
        return $result;
    }
    
    static function setModuleStatus($modules) {
        $conn = new PDO("sqlite:/etc/cfg/conf.db");
        $statement = $conn->prepare(self::$SQL_STATEMENT);
        $conn->beginTransaction();
        foreach ($modules as $pkg => $status) {
            $status = +$status;
            if($pkg=="Module"){
                $pkg="module";
                $statement->bindParam(":pkg", $pkg);
                $statement->bindParam(":status", $status);
                $statement->execute();
            }else{
                $statement->bindParam(":pkg", sprintf("mod_%s_login", $pkg));
                $statement->bindParam(":status", $status);
                $statement->execute();
            }
        }
        return $conn->commit();
    }
}

class ModuleLoginRPC extends RPC {
    function getModuleStatus() {
        return self::fireEvent(ModuleLogin::getModuleStatus());
    }
    
    function setModuleStatus($modules) {
        return self::fireEvent(ModuleLogin::setModuleStatus($modules));
    }
}

?>
