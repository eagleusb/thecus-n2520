<?php
include_once(INCLUDE_ROOT.'commander.class.php');

class VendorBase extends Commander {
    public $data;
    
    function grep($pattern) {
        $keys = preg_grep($pattern, array_keys( $this->data ) );
        if( !isset($this->data) || count($keys) == 0 ) {
            return;
        }
        $match = array();
        foreach ( $keys as $key ) {
            $match[$key] = $this->data[$key];
        }
        return $match;
    }
}

class VendorIO extends VendorBase {
    function __construct() {
        $io = self::fg("a", "sed -nr 's/(.*): (.*)/\"\\1\":\"\\2\"/p' /proc/thecus_io | grep -v 'Copy button'");
        array_pop($io);
        $model = self::fg("s", "sed -nr 's/type\\t*([^ ]*)/\\1/p' /etc/manifest.txt");
        $this->data = json_decode(sprintf("{%s}", join(",", $io)), true);
        $this->data["MODELNAME"] = $model;
    }
}

class VendorConfig extends VendorBase {
    function __construct() {
        $config = self::fg("a", "sed -nr 's/(.*)=(.*)/\"\\1\":\"\\2\"/p' /img/bin/conf/sysconf.`cat /var/run/model`.txt");
        array_pop($config);
        $this->data = json_decode(sprintf("{%s}", join(",", $config)), true);
    }
}

class VendorHWM extends VendorBase {
    function __construct() {
        $hwm = self::fg("a", "sed -nr 's/(.*) *: *(.*) */\"\\1\":\"\\2\"/p' /proc/*hwm");
        array_pop($hwm);
        $this->data = json_decode(sprintf("{%s}", join(",", $hwm)), true);
    }
}

class VendorMemory extends VendorBase {
    function __construct() {
        $memory = self::fg("a", "sed -nr 's/(.*)*: *(.*) kB/\"\\1\":\"\\2\"/p' /proc/meminfo");
        array_pop($memory);
        $this->data = json_decode(sprintf("{%s}", join(",", $memory)), true);
    }
}

class VendorSCSIx2 extends VendorBase {
    function __construct() {
        $scsix2 = self::fg("a", "sed -r '1,1d;s/(^  (Thecus: )?)|( *Model:.*Rev: .*)$|( *ANSI  SCSI)//g;s/: */:/g' /proc/scsi/scsi | sed 'N;N;N;s/\\n/ /g'");
        array_pop($scsix2);
        $this->data = array();
        for( $i = 0 ; $i < count($scsix2) ; ++$i ) {
            $scsi = &$scsix2[$i];
            preg_match("/(Host):(.*) (Channel):(.*) (Id):(.*) (Lun):(.*) (Vendor):(.*) (Type):(.*) (revision):(.*) (Tray):(.*) (Disk):(.*) ?(Model):(.*) *(Rev):(.*) (Intf):(.*) +(LinkRate):(.*) +(Loc):(.*) *(Pos):(.*)/", $scsi, $pat);
            $scsi = array();
            for( $p = 1 ; $p < count($pat) ; $p += 2 ) {
                $key = &$pat[$p];
                $val = &$pat[$p + 1];
                if( preg_match("/Channel|Id|Lun|revision|Tray|LinkRate|Loc|Pos/", $key) ) {
                    $val += 0;
                }
                $scsi[$key] = $val;
            }
            $this->data []= $scsi;
        }
    }
    
    function grep($pattern, $k = null) {
        if( !isset($this->data) || count($this->data) == 0 ) {
            return;
        }
        $result = array();
        for( $i = 0 ; $i < count($this->data) ; ++$i ) {
            $scsi = &$this->data[$i];
            foreach( $scsi as $key => &$val ) {
                $match = preg_match($pattern, $val);
                if( $k != null ) {
                    if( $match && $k === $key ) {
                        $result []= $scsi;
                        break;
                    }
                } else {
                    if( $match ) {
                        $result []= $scsi;
                        break;
                    }
                }
                
            }
        }
        if( count($result) == 0 ) {
            return;
        }
        return $result;
    }
}
?>

