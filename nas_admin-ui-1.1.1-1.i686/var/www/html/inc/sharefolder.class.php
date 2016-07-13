<?php
require_once(INCLUDE_ROOT.'commander.class.php');

class ShareFolder extends Commander {
    const  FOLDER_PATH="/raid/data/ftproot/";
    const  STACK_DB="/etc/cfg/stackable.db";

    static function getFolders(&$stack = false) {
        $folder_list=array();
        $all_folder_list=scandir(self::FOLDER_PATH);

        $folder_count=0;
        for($i=0;$i<count($all_folder_list);$i++){
            if ($all_folder_list[$i]!="." && $all_folder_list[$i]!=".."){
                if(!preg_match('/^\/raid\/data\/stackable\//', readlink(self::FOLDER_PATH.$all_folder_list[$i]))){
                    $folder_list[]=$all_folder_list[$i];
                }
            }
        }

        if($stack){
            $has_stack=Commander::fg("s", "sqlite ".self::STACK_DB." .tables | grep stackable");
            if($has_stack!=""){
                $stack_folder=Commander::fg("a", "sqlite ".self::STACK_DB." \"select share from stackable\"");
                array_pop($stack_folder);
                $folder_list=array_merge($folder_list, $stack_folder);
            }
        }
        return $folder_list;
    }
    
    static function getFolderCount(&$stack = false) {
        return count(self::getFolders($stack));
    }
}

?>

