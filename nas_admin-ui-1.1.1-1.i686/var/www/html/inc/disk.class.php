<?php
require_once(INCLUDE_ROOT.'rpc.class.php');
require_once(INCLUDE_ROOT.'info/diskinfo.class.php');
require_once(INCLUDE_ROOT.'Vendor/vendor.class.php');

class DiskRPC extends RPC {
    function listAll() {
        global $Enclosure, $disk_list, $total_size, $gwords, $total_tray;
        
        $info = new DISKINFO();
        $disk_info = $info->getINFO();
        $disk_list = $disk_info["DiskInfo"];
        $max_index = $disk_info["max_index"];

        $disk = $info->get_all_disk_data();
        $all = $info->get_spare_disk_data();
        return self::fireEvent($all);
    }
}


?>