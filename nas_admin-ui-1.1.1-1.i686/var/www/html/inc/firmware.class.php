<?php
require_once(INCLUDE_ROOT.'function.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');
require_once(INCLUDE_ROOT.'commander.class.php');

get_sysconf();
global $sysconf;
define('TarKey', (NAS_DB_KEY == 1) ? '2006N5200' : $sysconf['key'] );

final class FirmwareHandle {
    const Extracting        = 'status_extracting';
    const ExtractSuccess    = 'status_extractsuccess';
    const ExtractError      = 'status_extracterror';
    const SpaceNotEnough    = 'status_spacenotenough';
    const NoProcedure       = 'status_noprocedure';
}

abstract class Firmware extends Commander {
    
    /**
     *  All firmware requirement shell commands.
     */
    const CmdMemoryUsage    = "free | grep Mem | awk '{print $2; print $3; print $4}'";
    const CmdDiskSpace      = "df %s | tail -n 1 | awk '{print $4}'";
    const CmdFactoryMode    = "cat /proc/thecus_io | grep FAC_MODE | cut -d ':' -f2";
    const CmdPicFac         = "cat /proc/thecus_io | grep PIC_FAC | cut -d ':' -f2";
    const CmdIsZipFile      = "unzip -t '%s' 2>&1 | grep 'End-of-central-directory'";
    const CmdZipHasFile     = "unzip -Z -1 '%s' '%s' 2>/dev/null";
    const CmdZipHasPassword = "unzip -Z -z '%s' \"`unzip -Z -1 '%s' | head -n 1`\" | awk '{print $5}' | cut -c 1";
    const CmdZipExtractRom  = "unzip -P '%s' -p '%s' 'upgrade.rom' | des -k '%s' -D | tar zxvf - -C '/tmp' 2>&1 | grep 'tar: Error' > /tmp/extract.log &";
    const CmdZipExtractFile = "echo 'n' | unzip -P '%s' -o '%s' -x 'upgrade.rom' -d '%s' 2>&1 | grep '(disk full?)' > /tmp/extract.log &";
    const CmdUntarFile      = "des -k '%s' -D '%s' | tar zxvf - -C '/tmp' 2>&1 | grep 'tar: Error' > /tmp/extract.log &";
    const CmdIsExtracting   = "ps | grep upgrade.rom | grep -v grep";
    const CmdRemoveFolder   = "rm -Rf '%s'";
    
    /**
     *  Firmware common define.
     */
    const ZipKey            = '4cc7@firmware';
    const TarKey            = TarKey;
    const SizeLimit         = 10485760;
    const LFirmwareFile     = '/raid/data/tmp/upgrade.rom';
    const SFirmwareFile     = '/tmp/upgrade.rom';
    const ExtractFolder     = '/tmp';
    const ExtractResult     = '/tmp/extract.log';
    const UpgradeFolder     = '/tmp/upgrade';
    const UpgradeStepFile   = '/tmp/upgrade_step.log';
    const UpgradeStepResult = '/tmp/upgrade_result.log';
    
    static private function getVersion($file = '/etc/version') {
        $fp = fopen($file, 'r');
        $ver = trim(fgets($fp));
        fclose($fp);
        preg_match('/([0-9]+)\.([0-9]+)\.([0-9]+)/', $ver, $vers);
        $vers[0] = $ver;
        return $vers;
    }
    
    static private function getMemoryUsage() {
        return self::frontground('a', Firmware::CmdMemoryUsage);
    }
    
    static private function getFactoryMode() {
        return (self::frontground('s', Firmware::CmdFactoryMode) == 'ON');
    }
    
    static function getPicFac() {
        return (self::frontground('s', Firmware::CmdPicFac) == 'ON');
    }
    
    static private function getDiskSpace($disk) {
        return self::frontground('i', Firmware::CmdDiskSpace, $disk) * 1024;
    }
    
    static private function isZipFile($zip) {
        return (self::frontground('s', Firmware::CmdIsZipFile, $zip) == '');
    }
    
    static function zipHasFile($zip, $file) {
        return self::frontground('s', Firmware::CmdZipHasFile, $zip, $file);
    }
    
    static private function zipHasPassword($zip) {
        $type = self::frontground('s', Firmware::CmdZipHasPassword, $zip, $zip);
        return ($type == 'T' || $type == 'B');
    }
    
    static private function zipExtractRom($zip) {
        self::background(Firmware::CmdZipExtractRom, Firmware::ZipKey, $zip, Firmware::TarKey);
    }
    
    static private function zipExtractFile($zip) {
        self::background(Firmware::CmdZipExtractFile, Firmware::ZipKey, $zip, Firmware::UpgradeFolder);
    }
    
    static private function unTarFile($tar) {
        self::background(Firmware::CmdUntarFile, Firmware::TarKey, $tar);
    }
    
    static function removeUpgradeFolder($folder) {
        self::frontground(NULL, Firmware::CmdRemoveFolder, Firmware::UpgradeFolder);
    }
    
    static function isExtracting() {
        return self::frontground('b', Firmware::CmdIsExtracting);
    }
    
    static function getAbleFile($bytes) {
        $size = (int)$bytes;
        $memory = self::getMemoryUsage();
        
        if( defined(UPDFW_MEM_LIMIT) && $memory[0] /* Total Memory */ < UPDFW_MEM_LIMIT && $size > Firmware::SizeLimit ) {
            if( $size > self::getDiskSpace('/raid/data') ) {
                return FirmwareHandle::SpaceNotEnough;
            }
            return Firmware::LFirmwareFile;
        }
        
        if( $size > self::getDiskSpace('/tmp') ) {
            return FirmwareHandle::SpaceNotEnough;
        }
        
        return Firmware::SFirmwareFile;
    }
    
    static private function initFirmwareInfo() {
        return array(
            'error'     => FirmwareHandle::ExtractSuccess,
            'new'       => FALSE,
            'script'    => FALSE,
            'upgradable'=> FALSE,
            'conf'      => array(),
            'firmware'  => array(
                'system'    => '',
                'source'    => '',
                'md5'       => '',
                'readme'    => ''
            )
        );
    }
    
    static function extract($firmware, $extractFolder = Firmware::ExtractFolder) {
        $info = self::initFirmwareInfo();
        
        unlink(Firmware::ExtractResult);
        self::removeUpgradeFolder();
        
        // test is zip file not not
        if( self::isZipFile($firmware) ) {
            if( !self::zipHasPassword($firmware) ) {
                $info['error'] = FirmwareHandle::ExtractError;
                return $info;
            }
            
            if( self::zipHasFile($firmware, 'upgrade.rom') ) {
                $info['error'] = FirmwareHandle::Extracting;
                self::zipExtractRom($firmware);
                return $info;
            }
            
            $info['error'] = FirmwareHandle::Extracting;
            self::zipExtractFile($firmware);
            return $info;
        } else {
            $info['error'] = FirmwareHandle::Extracting;
            self::unTarFile($firmware);
            return $info;
        }
    }
    
    static function getFirmwareInfo($firmware, $extractFolder = Firmware::ExtractFolder) {
        $info = self::initFirmwareInfo();
        
        if( self::isExtracting() ) {
            $info['error'] = FirmwareHandle::Extracting;
            return $info;
        }
        
        if( filesize(Firmware::ExtractResult) > 0 || !is_dir(Firmware::UpgradeFolder) ) {
            $info['error'] = FirmwareHandle::ExtractError;
            return $info;
        }
        
        $procedure = file_exists('/tmp/upgrade/upgrade.sh') || file_exists('/tmp/upgrade/postup.sh') || file_exists('/tmp/upgrade/up.sh');
        if( !$procedure ) {
            $info['error'] = FirmwareHandle::NoProcedure;
            return $info;
        } 
        
        $info['firmware']['md5'] = strtoupper(md5_file($firmware));
        
        $info['error'] = FirmwareHandle::ExtractSuccess;
        
        $srcVerFile = sprintf('%s/upgrade/version', $extractFolder);
        if( file_exists($srcVerFile) ) {
            $sysVer = self::getVersion();
            $info['firmware']['system'] = $sysVer[0];
            
            $srcVer = self::getVersion($srcVerFile);
            $info['firmware']['source'] = $srcVer[0];
            
            array_push($sysVer, (int)$sysVer[1] * 1000000 + (int)$sysVer[2] * 1000 + (int)$sysVer[3]);
            array_push($srcVer, (int)$srcVer[1] * 1000000 + (int)$srcVer[2] * 1000 + (int)$srcVer[3]);
            
            $facMode    = self::getFactoryMode();
            $picFac     = self::getPicFac();
            $facMode    = $facMode | $picFac;
            $info['upgradable'] = $facMode || ($srcVer[4] >= $sysVer[4]);
        }
        
        if( file_exists('/tmp/upgrade/upgrade.sh') ) {
            $info['new'] = TRUE;
            $info['upgradable'] = TRUE;
        }
        
        if( file_exists('/tmp/downgrade') ) {
            $info['upgradable'] = TRUE;
        }

        if( $info['upgradable'] === FALSE ) {
            return $info;
        }
        
        if( file_exists('/tmp/upgrade/readme') ) {
            $fp = fopen('/tmp/upgrade/readme', 'r');
            $info['firmware']['readme'] = fread($fp, filesize('/tmp/upgrade/readme'));
            fclose($fp);
        }
        
        if( file_exists('/tmp/upgrade/upgrade.conf') ) {
            $info['new'] = TRUE;
            $lines = file('/tmp/upgrade/upgrade.conf');
            foreach ($lines as $line_num => $line) {
                $setting = explode('[:]', trim($line));
                if( count($setting) == 2 ) {
                    $info['conf'][$setting[0]] = $setting[1];
                }
            }
        }
        
        return $info;
    }
}

?>
