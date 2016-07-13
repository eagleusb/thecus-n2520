<?php
/**
 * @file This Upgrade class will handle all upgrade follow between client and server.
 * @author kenny_wu@thecus.com
 */

/**
 * Include base class and firmware util.
 */
require_once(INCLUDE_ROOT.'commander.class.php');
require_once(INCLUDE_ROOT.'firmware.class.php');

/**
 * The UpgradeStep class use to map client side step.
 */
final class UpgradeStep {
    const Browse    = 'UpgradeBrowse';
    const Upload    = 'UpgradeUpload';
    const Download  = 'UpgradeDownload';
    const Disclaim  = 'UpgradeDisclaim';
    const Confirim  = 'UpgradeConfirm';
    const Upgrade   = 'UpgradeUpgrade';
    const Result    = 'UpgradeResult';
}

/**
 * The UpgradeStatus handle all running, error and exception messages. 
 */
final class UpgradeStatus {
    const Running       = 'status_running';
    const Cancel        = 'status_cancel';
    const Cannot        = 'status_cannot';
    const Duplicate     = 'status_duplicate';
    const UploadFail    = 'status_uploadfail';
    const DownloadFail  = 'status_downloadfail';
    const Downloading   = 'status_downloading';
    const NetworkFail   = 'status_networkfail';
    const Upgrading     = "status_upgrading";
    const Upgraded      = "status_upgraded";
    const UpgradeError  = "status_upgradeerror";
    const UpgradeCrash  = "status_upgradecrash";
    const UpgradeWrong  = "status_upgradewrong";
    const DowngradeError= "status_downgradeerror";
    const NoProcedure   = "status_noprocedure";
}

/**
 * The Upgrade class will handle all follow between clent and server.
 * 
 * @extends Commander
 */
class Upgrade extends Commander {
    const CmdProcessStatus  = "ps 2>&1 | grep '%s' | grep -v 'grep'";
    const CmdEventLog       = "/img/bin/logevent/event %d '%s' &";
    const CmdRunUpgrade     = "sh '%s' > /dev/null 2>&1 &";
    const CmdLastMessage    = "tail -n 1 %s";
    const CmdUpgradeMessage = "cat %s";
    const CmdStopDownload   = "kill -9 %d";
    const CmdGetFileSize    = "wget -S --spider '%s' 2>&1 | grep Content-Length | grep '[0-9]*' | awk '{print $2}'";
    const CmdStartDownload  = "wget -q -b --tries=1 --read-timeou=10 -o /dev/null -O '%s' '%s' 2>&1 | awk '{print $5}'";

    const StageFile = '/var/tmp/www/upgrade.stage';
   
    protected $stage;
        
    /**
     * Check a file is exist on internet and get it's size.
     * 
     * @param $url
     *      A file's uri.
     */
    private function getFileSize($url) {
        if( is_string($url) ) {
            return self::frontground('i', Upgrade::CmdGetFileSize, $url);
        }
    }

    /**
     * Begin a wget download job.
     * 
     * @param $url
     *      A file's uri.
     * 
     * @param $file
     *      Where to save the $url file.
     */
    private function startDownload($url, $file) {
        if( is_string($url) && is_string($file) ) {
            return self::frontground('i', Upgrade::CmdStartDownload, $file, $url);
        }
        return 0;
    }
    
    /**
     * Cancel a wget download job.
     * 
     * @param $pid
     *      The wget's pid.
     */
    private function stopDownload($pid = 0) {
        if( is_int($pid) ) {
            self::background(Upgrade::CmdStopDownload, $pid);
        }
    }
    
    /**
     * Get the last content(line) of file.
     * 
     * @param $file
     *      File name(path).
     * 
     * @return
     *      If $file exists return the last content(line) as string otherwise return a empty string.
     */
    private function getLastMessage($file) {
        return self::frontground('s', Upgrade::CmdLastMessage, $file);
    }
    
    /**
     *  The runUpgradeScript method will start firmware upgrade.
     * 
     *  @param $script
     *      The target shell sciprt file will be run under background.
     */
    private function runUpgradeScript($script) {
        $this->background(Upgrade::CmdRunUpgrade, $script);
    }
    
    /**
     *  The sendEventLog can make system event.
     * 
     *  @param $eid
     *      A system event id.
     * 
     *  @param $msg
     *      A system event message.
     */
    private function sendEventLog($eid, $msg) {
        $this->frontground(NULL, Upgrade::CmdEventLog, $eid, $msg);
    }
    
    private function getProcessStatus($ps) {
        return $this->frontground('s', Upgrade::CmdProcessStatus, $ps);
    }
    
    /**
     * Initial the status and configure of upgrade procedure.
     * 
     * @param $step
     *      Default $step is UpgradeStep::Browse.
     * 
     * @param $status
     *      Default $status is UpgradeStatus::Running.
     */
    private function initial($step = UpgradeStep::Browse, $status = UpgradeStatus::Running) {
        if( isset($this->stage) ) {
            unset($this->stage);
        }
        $this->stage = array(
            'step'      => $step,
            'status'    => $status,
            'file'      => '',
            'pid'       => 0,
            'size'      => 0,
            'rate'      => -1,
            'info'      => NULL,
            'progress'  => FALSE,
            'result'    => FALSE,
        );
    }

    /**
     * Upgrade's construct medthod. All upgrade objects will reference to same upgrade configure file.
     */
    public function __construct() {
        if( file_exists(Upgrade::StageFile) ) {
            if( ($fp = fopen(Upgrade::StageFile, 'r')) != FALSE ) {
                $this->stage = json_decode(fgets($fp), TRUE);
                fclose($fp);
            } 
        }
        else {
           $this->initial();
        }
    }
    
    /**
     * Change upgrade step and status.
     * 
     * @param $step
     *      The $step can be one of @link UpgradeStep @endlink.
     *      Default value is NULL.
     * 
     * @param $status
     *      The $status can be one of @link UpgradeStatus @endlink.
     *      Default value is NULL.
     * 
     * @param $initial
     *      If the $initial is TRUE that will clean all currect setting before setup $step and $status.
     */
    private function setStage($step = NULL, $status = NULL, $initial = FALSE) {
        if( $initial === TRUE ) {
            $this->initial($step, $status);
        }
        if( $step !== NULL ) {
            $this->stage['step'] = $step;
        }
        if( $status !== NULL ) {
            $this->stage['status'] = $status;
        }
    }
    
    /**
     * Save the correct stage to configure file.
     * 
     * @param $step
     *      The $step can be one of @link UpgradeStep @endlink.
     *      Default value is NULL.
     * 
     * @param $status
     *      The $status can be one of @link UpgradeStatus @endlink.
     *      Default value is NULL.
     * 
     * @param $initial
     *      If the $initial is TRUE that will clean all currect setting before setup $step and $status. 
     */
    private function saveStage($step = NULL, $status = NULL, $initial = FALSE) {
        $this->setStage($step, $status);
        if( ($fp = fopen(Upgrade::StageFile, 'w')) != FALSE ) {
            fputs($fp, json_encode($this->stage));
            fclose($fp);
        }
    }

    /**
     * Get the correct stage of upgrade procedure.
     * 
     * @return
     *      A JSON format string.
     */
    public function getProgress() {
        return json_encode(array(
            'step'      => $this->stage['step'],
            'status'    => $this->stage['status'],
            'size'      => $this->stage['size'],
            'rate'      => $this->stage['rate'],
            'info'      => $this->stage['info']['firmware'],
            'show'      => $this->stage['info']['conf']['step'],
            'progress'  => $this->stage['progress'],
            'result'    => $this->stage['result']
        ));
    }

    /**
     * Check firmware is upgrading or not.
     * 
     * @return
     *      TRUE when someone is upgrading firmware otherwise is FALSE.
     */
    public function isUpgrading() {
        switch($this->stage['step']){
        case UpgradeStep::Browse:
        case UpgradeStep::Upload:
        case UpgradeStep::Download:
        case UpgradeStep::Result;
            return FALSE;
        default:
            return TRUE;
        }
    }
    
    /**
     * Check firmware upgrading is started or not.
     * 
     * @return
     *      TRUE when someone is upgrading firmware otherwise is FALSE.
     */
    public function isInitial() {
        return ($this->stage['step'] == UpgradeStep::Browse);
    }

    /**
     * Cancel firmware upgrade.
     * But only the downloading, disclaiming, confirming and error result can be canceled.
     */
    public function setCancel() {
        if( $this->stage['step'] == UpgradeStep::Upgrade ) {
            $this->setStage(NULL, UpgradeStatus::Cannot);
        } else {
            if( $this->stage['pid'] > 0 ) {
                /**
                 * Thecus NAS cannot use posix_kill to stop download file.
                 */
                //posix_kill($this->stage['pid'], SIGKILL);
                $this->stopDownload($this->stage['pid']);
            }

            if( file_exists($this->stage['file']) ) {
                unlink($this->stage['file']);
            }

            if( file_exists(Upgrade::StageFile) ) {
                unlink(Upgrade::StageFile);
            }
            
            unlink(Firmware::ExtractResult);
            Firmware::removeUpgradeFolder();
            
            $this->setStage(UpgradeStep::Result, UpgradeStatus::Cancel, TRUE);
        }
    }

    /**
     * Handle a file is uploaded from client side.
     * 
     * @param
     *      $_FILES is the rule of PHP.
     */
    public function setUpload() {
        if( $_FILES['UpgradeUploadFile']['error'] == UPLOAD_ERR_OK ) {
            if( $this->stage['step'] != UpgradeStep::Browse ) {
                $this->setStage(UpgradeStep::Result, UpgradeStatus::Duplicate);
            } else {
                $file = Firmware::getAbleFile($_FILES['UpgradeUploadFile']['size']);
                if( $file == FirmwareHandle::SpaceNotEnough ) {
                    $this->setStage(UpgradeStep::Result, FirmwareHandle::SpaceNotEnough);
                } else {
                    move_uploaded_file($_FILES['UpgradeUploadFile']['tmp_name'], $file);
                    $this->stage['file'] = $file;
                    $this->stage['size'] = $_FILES['UpgradeUploadFile']['size'];
                    $this->saveStage(UpgradeStep::Disclaim, UpgradeStatus::Running);
                }
            }
        } else {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::UploadFail);
        }
        
        /**
         * The following json format is required by ext 2.x.
         * 'success' tag can fire the success event of FormPanel.
         * 'msg' is a customer data.
         */
        die(json_encode(array(
            'success'   => TRUE,
            'msg'       => array(
                'step'      => $this->stage['step'],
                'status'    => $this->stage['status'],
                'size'      => $this->stage['size'],
                'rate'      => $this->stage['rate']
        ))));
    }

    /**
     * Download a file form internet.
     * 
     * @param $url
     *      A file's uri.
     */
    public function setDownload($url) {
        if( $this->stage['step'] != UpgradeStep::Browse ) {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::Duplicate);
            return;
        }
        
        $size = $this->getFileSize($url);

        if( $size === NULL ) {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::DownloadFail);
            return;
        }
        
        $file = Firmware::getAbleFile($size);
        if( $file == FirmwareHandle::SpaceNotEnough ) {
            $this->setStage(UpgradeStep::Result, FirmwareHandle::SpaceNotEnough);
        }
        $this->stage['file'] = $file;
        
        $pid = $this->startDownload($url, $file);
        
        if( $pid == 0 ) {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::DownloadFail);
            return;
        }
        
        $this->stage['size'] = $size;
        $this->stage['pid'] = $pid;
        $this->saveStage(UpgradeStep::Download, UpgradeStatus::Downloading);
    }

    /**
     * Get the download percentage of file.
     * 
     * @return
     *      The download percentage.
     */
    public function getDownloadRate() {
        $rate = -1;
        if( $this->stage['step'] == UpgradeStep::Download && $this->stage['status'] == UpgradeStatus::Downloading ) {
            
            $proc = sprintf('/proc/%d', $this->stage['pid']);
            if( !file_exists($proc) ) {
                $this->setStage(UpgradeStep::Result, UpgradeStatus::NetworkFail);
            }
            if( file_exists($this->stage['file']) ) {
                $size = filesize($this->stage['file']);
                $rate = floor($size/$this->stage['size']*100);
                $this->stage['rate'] = (int)$rate;
            }
            if( $rate == 100 ) {
                $this->stage['pid'] = 0;
                $this->setStage(UpgradeStep::Disclaim, UpgradeStatus::Running);
            }
            $this->saveStage();
        }
        return $rate;
    }

    /**
     * User must agree the disclaim before upgrading.
     */
    public function setDisclaim($extract) {
        if( $this->stage['step'] != UpgradeStep::Disclaim ) {
            return;
        }
        
        if( $extract == true ) {
            $info = Firmware::extract($this->stage['file']);
            $this->stage['info'] = $info;
        } else {
            $info = Firmware::getFirmwareInfo($this->stage['file']);
            $this->stage['info'] = $info;
        }
        
        if( $info['error'] == FirmwareHandle::Extracting ) {
            $this->saveStage(UpgradeStep::Disclaim, $info['error']);
            return;
        }
        
        if( $info['error'] != FirmwareHandle::ExtractSuccess ) {
            $this->saveStage(UpgradeStep::Result, $info['error']);
            return;
        }
        if( $info['upgradable'] ) {
            $this->saveStage(UpgradeStep::Confirim, UpgradeStatus::Running);
        } else {
            $this->saveStage(UpgradeStep::Result, UpgradeStatus::DowngradeError);
        }
    }
    
    /**
     * Check the upgrad script is running or not.
     * 
     * @return
     *      TRUE when upgrading otherwise is FALSE.
     */
    private function isScripting() {
        if( ($this->getProcessStatus('/tmp/upgrade/upgrade.sh') != '')    ||
            ($this->getProcessStatus('/tmp/upgrade/postup.sh') != '') ||
            ($this->getProcessStatus('/tmp/upgrade/up.sh') != '')     ||
            ($this->getProcessStatus('flashcp') != '')   ||
            ($this->getProcessStatus('fcp') != '') ) {
            return TRUE;
        }
        return FALSE;
    }

    /**
     * User apply the disclaim and start upgrade procedure.
     * Can not start the upgrade procedure in this class or object.
     * Because the upgrade procedure will kill itself.
     * 
     * @param $backupDom
     *      Backup DOM before upgrading or not.
     * 
     * @return
     *      The upgrade procedure(script file) as possible. If can not that will return an empty string.
     */
    public function setUpgrade($backupDom = FALSE) {
        if( $this->stage['step'] != UpgradeStep::Confirim ) {
            return '';
        }
        
        if( $this->isScripting() ) {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::Duplicate);
            return '';
        }
        
        if( $this->stage['info']['upgradable'] !== TRUE ) {
            $this->sendEventLog(145, 'Downgrade Error');
            $this->saveStage(UpgradeStep::Result, UpgradeStatus::DowngradeError);
            return '';
        }
        
        $db = new sqlitedb();
        $db->setvar('backup_dom', $backupDom == '1' ? '1' : '0');
        
        if( (bool)$this->stage['info']['conf']['step'] === TRUE ) {
            unlink(Firmware::UpgradeStepFile);
            touch(Firmware::UpgradeStepFile);
        }
        
        if( (bool)$this->stage['info']['conf']['result'] === TRUE ) {
            unlink(Firmware::UpgradeStepResult);
            touch(Firmware::UpgradeStepResult);
        }
        /*
        if( file_exists('/tmp/upgrade/script') ) {
            $this->runUpgradeScript('/tmp/upgrade/script');
            
        } else if( file_exists('/tmp/upgrade/postup.sh') ) {
            $this->runUpgradeScript('/tmp/upgrade/postup.sh');
            
        } else if( file_exists('/tmp/upgrade/up.sh') ) {
            $this->runUpgradeScript('/tmp/upgrade/up.sh');
            
        } else {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::NoProcedure);
        }
        */
        
        $script = '';
        if( file_exists('/tmp/upgrade/upgrade.sh') ) {
            $script = '/tmp/upgrade/upgrade.sh';
            
        } else {
            if( file_exists('/tmp/upgrade/postup.sh') ) {
                $script = '/tmp/upgrade/postup.sh';
                
            } else if( file_exists('/tmp/upgrade/up.sh') ) {
                $script = '/tmp/upgrade/up.sh';
                
            }
        }
        
        if( $script == '' ) {
            $this->setStage(UpgradeStep::Result, UpgradeStatus::NoProcedure);
        } else {
            $this->saveStage(UpgradeStep::Upgrade, UpgradeStatus::Upgrading);
        }
        
        return $script;
    }

    /**
     * Get the correct upgrade stage and status.
     * If the target firmware is a new kind of package.
     * @link getProcress @endlink method will return step log and result.
     */
    public function getUpgradeRate() {
        if( $this->stage['step'] != UpgradeStep::Upgrade ) {
            return;
        }
            
        if( $this->stage['info']['new'] ) {
            if( (bool)$this->stage['info']['conf']['step'] === TRUE ) {
                $progress = file_get_contents(Firmware::UpgradeStepFile);
                $this->stage['progress'] = $progress;
            }
        }
        
        if( !$this->isScripting() ) {
            $this->stage['result'] = 'FINISH|0|';
            
            if( $this->stage['info']['new'] ) {
                if( (bool)$this->stage['info']['conf']['result'] === TRUE ) {
                    $result = file_get_contents(Firmware::UpgradeStepResult);
                    $this->stage['result'] = $result;
                }
            } else {
                if( NAS_DB_KEY == '1' ) {
                    $lastMessage = $this->getLastMessage('/tmp/message');
                } else {
                    $lastMessage = $this->getLastMessage('/tmp/upgrade/message');
                }
    
                if( $lastMessage == 'success' ) {
                    $this->stage['result'] = 'FINISH|0|';
                } else {
                    $this->stage['result'] = 'FAILED|0|';
                }
            }

            $result = explode('|', $this->stage['result']);
            
            if( is_null($result) ) {
                $this->setStage(UpgradeStep::Result, UpgradeStatus::UpgradCrash);
            }
            if( strtoupper($result[0]) == 'FINISH' ) {
                $this->setStage(UpgradeStep::Result, UpgradeStatus::Upgraded);
            } else if( strtoupper($result[0]) == 'WRONG' ) {
                $this->setStage(UpgradeStep::Result, UpgradeStatus::UpgradeWrong);
            } else {
                $this->setStage(UpgradeStep::Result, UpgradeStatus::UpgradeError);
            }
        }
        
        $this->saveStage();
    }
}

?>
