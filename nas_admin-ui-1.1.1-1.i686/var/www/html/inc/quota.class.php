<?php
require_once(INCLUDE_ROOT.'commander.class.php');

define('QUOTA_DB', (NAS_DB_KEY == 1) ? '/etc/cfg/conf.db' : '/etc/cfg/quota.db' );

abstract class Quota extends Commander {
    const CmdShell          = '/img/bin/rc/rc.user_quota %s';
    const CmdQuotaSetShow   = '/img/bin/rc/rc.user_quota set_conf sync_show %s';
    const CmdQuotaIsPrompt  = '/img/bin/rc/rc.user_quota get_conf sync_show';
    const CmdQuotaIsCancel  = '/img/bin/rc/rc.user_quota is_cancel';
    const CmdQuotaIsLock    = '/img/bin/rc/rc.user_quota is_lock';
    const CmdQuotaCancel    = '/img/bin/rc/rc.user_quota stop_sync';
    const CmdQuotaSync      = '/img/bin/rc/rc.user_quota quota_sync > /dev/null 2>&1 &';
    const CmdGetQuotaSync   = '/img/bin/rc/rc.user_quota get_need_sync';
    const CmdSetQuotaSync   = '/img/bin/rc/rc.user_quota set_need_sync %s';
    const CmdSetUserQuota   = '/img/bin/rc/rc.user_quota set_quota %s "%d" %d';
    const CmdGetUser        = '/img/bin/rc/rc.user_quota user_list %s "%s"';
    const CmdGetUserInfo    = '/img/bin/rc/rc.user_quota check_used %s "%s"';
    const CmdSetQuota       = '/usr/bin/sqlite %s "update quota set size=\'%d\' where role=\'%s\' and name=\'%s\'"';
    const CmdGetUserId      = '/usr/bin/sqlite %s "select id from quota where role=\'%s\' and name=\'%s\'"';

    static function isReboot() {
        return self::frontground('s', "/img/bin/rc/rc.user_quota is_reboot") == '1';
    }
    
    static private function isLock() {
        return self::frontground('s', Quota::CmdQuotaIsLock) == '1';
    }
    
    static private function isPrompt() {
        return self::frontground('s', Quota::CmdQuotaIsPrompt) == '1';
    }
    
    static private function isCancel() {
        return self::frontground('s', Quota::CmdQuotaIsCancel) == '1';
    }
    
    static function serviceSyncCancel() {
        self::frontground(NULL, Quota::CmdQuotaCancel);
        
        return self::getAction();
        return array(
            'action' => 'serviceCanceling'
        );
    }
    
    static function setPrompt($show = TRUE) {
        self::frontground(NULL, Quota::CmdQuotaSetShow, ($show ? '1' : '0'));
        return array(
            'action' => 'noPrompt'
        );
    }
    
    static function getAction() {
        if( self::isReboot() ) {
            return array(
                'action' => 'serviceReboot'
            );
        }
    
        if( self::isCancel() ) {
            return array(
                'action' => 'serviceCanceling'
            );
        }
        
        if( self::isLock() ) {
            return array(
                'action' => 'serviceSyncing'
            );
        }
        
        if( self::isPrompt() ) {
            return array(
                'action' => 'serviceUnSync'
            );
        }

        return array(
            'action' => ''
        );
    }
    
    static function sync() {
        self::setPrompt(false);
        self::background(Quota::CmdQuotaSync);
        
        //return self::getAction();
        return array(
            'action' => 'serviceSyncing'
        );
    }
    
    static function getSync() {
        $quota = self::frontground('a', Quota::CmdGetQuotaSync);
        if( is_array($quota) ) {
            for( $i = 0 ; $i < count($quota) ; $i++ ) {
                if( trim($quota[$i]) != '' ) {
                    $conf = explode( '|', $quota[$i] );
                    unset($quota[$i]);
                    preg_match('/Q([ny])S([ny])/', $conf[2], $status);
                    $quota[$i] = array (
                        'type'          => $conf[0],
                        'name'          => $conf[1],
                        'supp'          => $status[1] == 'y',
                        'sync'          => $status[2] == 'y',
                        'fs'            => strtoupper($conf[3]),
                        'estimation'    => $conf[4]
                    );
                } else {
                    unset($quota[$i]);
                }
            }
        }
        
        return array(
            'action' => 'raidSynchronize',
            'result' => $quota
        );
    }
    
    static function setSync($conf) {
        if( is_array($conf) ) {
            for( $i = 0 ; $i < count($conf) ; $i++ ) {
                if( is_string($conf[$i]['type']) && is_string($conf[$i]['name']) ) {
                    $type = $conf[$i]['type'];
                    $name = $conf[$i]['name'];
                    unset($conf[$i]);
                    $conf[$i] = "\"$type|$name\"";
                    
                }
            }
            
            $arg = implode(' ', $conf);
            if( count($arg) > 0 ) {
                //$arg = sprintf(self::CmdSetQuotaSync, $arg);
                self::frontground(NULL, Quota::CmdSetQuotaSync, $arg);
                return self::sync();
            }
        }
        
        return self::sync();
    }
    
    private static function getUser($type, $id) {
        //$id = $_REQUEST['params'];
        $users = self::frontground('a', self::CmdGetUser, $type, $id);
        
        $result = array();
        for( $i = 0 ; $i < count($users) ; $i++ ) {
            if( $users[$i] == '' ) {
                break;
            }
            $tmp = explode('|', $users[$i]);
            $size = $tmp[1] == 'Unsupported' ? $tmp[1] : (int)$tmp[1] / 1024;
            array_push($result, array(
                'name' => $tmp[0],
                'quotasize' => $size,
            ));
        }
        
        return $result;
    }
    
    static function getLocalUser($id) {
        return array(
            'action' => 'localUser',
            'result' => self::getUser('local_user', $id)
        );
    }
    
    static function getAdUser($id) {
        return array(
            'action' => 'adUser',
            'result' => self::getUser('ad_user', $id)
        );
    }
    
    private static function getUserInfo($type, $id) {
        //$id = $_REQUEST['params'];
        $users = self::frontground('a', self::CmdGetUserInfo, $type, $id);
        $result = array();
        for( $i = 0 ; $i < count($users) ; $i++ ) {
            if( $users[$i] == '' ) {
                break;
            }
            //var_dump($users[$i]);
            $tmp = explode('|', $users[$i]);
            $limit = $tmp[2] === 'Unsupported' ? $tmp[2] : (double)$tmp[2] / 1024.0;
            $size  = $tmp[3] === '' ? $tmp[3] : (double)$tmp[3] / 1024.0;
            array_push($result, array(
                'name'      => $tmp[0],
                'fs'        => strtoupper($tmp[1]),
                'quotalimit'=> $limit,
                'quotasize' => $size,
            ));
        }
        
        return $result;
    }
    
    static function getLocalUserInfo($id) {
        return array(
            'action' => 'localUserInfo',
            'result' => self::getUserInfo('local_user', $id)
        );
    }
    
    static function getAdUserInfo($id) {
        return array(
            'action' => 'adUserInfo',
            'result' => self::getUserInfo('ad_user', $id)
        );
    }
    
    static function setService($enable) {
        $db = new sqlitedb();
        $db->setvar('quota', $enable);
        unset($db);
        
        if( $enable == '1' ) {
            Commander::frontground(NULL, "/img/bin/rc/rc.user_quota reboot > /dev/null 2>&1");
            //$action = 'serviceReboot';
        } else {
            Commander::frontground(NULL, "/img/bin/rc/rc.user_quota stop > /dev/null 2>&1");
            //$action = 'serviceDisabled';
        }

        // redirect to reboot page when the quota service enable/disable
        $action = 'serviceReboot';
        
        return array(
            'action' => &$action,
            'result' => NULL
        );
    }
    
    private static function setQuota($type, $name, $size) {
        self::frontground(NULL, self::CmdSetQuota, QUOTA_DB, $size, $type, $name );
    }
    
    private static function getUserId($type, $name) {
        return self::frontground('i', self::CmdGetUserId, QUOTA_DB, $type, $name);
    }
    
    private static function setUserQuota($type, $uuid, $size) {
        self::frontground(NULL, self::CmdSetUserQuota, $type, $uuid, $size );
    }
    
    static function setLocalUserQuota($modify) {
        for( $i = 0 ; $i < count($modify) ; $i++ ) {
            $name = $modify[$i]["name"];
            $size = (int)$modify[$i]["quotasize"] * 1024;
            self::setQuota('local_user', $name, $size);
            
            $uuid = self::getUserId('local_user', $name);
            
            //$size *= 1024;
            self::setUserQuota('local_user', $uuid, $size);
        }
        
        return array(
            'action' => 'localUserModified'
        );
    }
    
    static function setAdUserQuota($modify) {
        for( $i = 0 ; $i < count($modify) ; $i++ ) {
            $name = $modify[$i]["name"];
            $size = (int)$modify[$i]["quotasize"] * 1024;
            self::setQuota('ad_user', $name, $size);
            
            $uuid = self::getUserId('ad_user', $name);
            
            //$size *= 1024;
            self::setUserQuota('ad_user', $uuid, $size);
        }
        
        return array(
            'action' => 'adUserModified'
        );
    }
}
?>
