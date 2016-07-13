<?php
include_once(INCLUDE_ROOT.'info/sysinfo.class.php');
require_once(INCLUDE_ROOT.'sqlitedb.class.php');

define('Monitor', '/var/tmp/monitor/System_Info');

function history($type = 'h') {
    $dbfile = "";
    if( file_exists('/raid/sys/history.db') ) {
        $dbfile = '/raid/sys/history.db';
    } else if( file_exists('/raidsys/0/history.db') ) {
        $dbfile = '/raidsys/0/history.db';
    } else {
        die(json_encode(null));
    }
    
    switch( $type ) {
    case 'm':
        $cmd = array(
            "SELECT k, strftime('%s', t) * 1000, v FROM mt;",
            "SELECT k, strftime('%s', t) * 1000, v FROM m;"
        );
        break;
    case 'd':
        $cmd = array(
            "SELECT k, strftime('%s', t) * 1000, v FROM dt;",
            "SELECT k, strftime('%s', t) * 1000, v FROM d  WHERE t >= datetime('now', '-30 days');"
        );
        break;
    case 'h':
    default:
        $cmd = array(
            "SELECT k, strftime('%s', t) * 1000, v FROM ht;",
            "SELECT k, strftime('%s', t) * 1000, v FROM h  WHERE t >= datetime('now', '-48 hours');"
        );
        break;
    }
    
    $data = array();
    
    if( ($db = new PDO("sqlite:$dbfile")) ) {
        
        for( $i = 0 ; $i < count($cmd) ; $i++ ) {
            $st = $db->query($cmd[$i]);
            
            if( $st == false ) {
                die(json_encode(null));
            }
            
            $result = $st->fetchAll();
            
            for($j = 0 ; $j < count($result) ; $j++){
                $id = $result[$j][0];
                if( $id != 'c' ) {
                    if( !isset($data[$id]) )
                        $data[$id] = array();
                    
                    array_push( $data[$id], array(
                        0 => $result[$j][1] + 0,
                        1 => sprintf('%.1f', $result[$j][2]) + 0
                    ));
                }
            }
        }
        
        unset($db);
    }
    die(json_encode($data));
}

function monitor() {
    $monitors = array();
    $monitors['CPU'] = array(
        'type'      => 'spline',
        'yaxis'     => 0, // usage yaxis
        'series'    => array('CPU')
    );
    $monitors['Memory'] = array(
        'type'      => 'spline',
        'yaxis'     => 0, // usage yaxis
        'series'    => array('Memory')
    );
    if (trim(shell_exec("/img/bin/check_service.sh cpu_fan1")) != "0" ||
      trim(shell_exec("/img/bin/check_service.sh sys_fan1")) != "0" ||
      trim(shell_exec("/img/bin/check_service.sh sys_fan2")) != "0" ){
        $monitors['Fan'] = array(
            'type'      => 'spline',
            'yaxis'     => 1, // rpm yaxis
            'series'    => array()
        );
    }
    if (trim(shell_exec("/img/bin/check_service.sh cup_temp1")) != "0" ||
      trim(shell_exec("/img/bin/check_service.sh sys_temp")) != "0"){
        $monitors['Temperature'] = array(
            'type'      => 'spline',
            'yaxis'     => 2, // temp yaxis
            'series'    => array()
        );
    }
    $monitors['Network'] = array(
        'type'      => 'spline',
        'yaxis'     => 3, // MB/s yaxis
        'series'    => array()
    );
    $monitors['Samba'] = array(
        'type'      => 'column',
        'yaxis'     => 4, // connection yaxis
        'series'    => array('Samba')
    );
    $monitors['AFP'] = array(
        'type'      => 'column',
        'yaxis'     => 4, // connection yaxis
        'series'    => array('AFP')
    );
    if (trim(shell_exec("/img/bin/check_service.sh nfs")) != "0"){
        $monitors['NFS'] = array(
            'type'      => 'column',
            'yaxis'     => 4, // connection yaxis
            'series'    => array('NFS')
        );
    }
    $monitors['FTP'] = array(
        'type'      => 'column',
        'yaxis'     => 4, // connection yaxis
        'series'    => array('FTP')
    );
    
    $data = file(Monitor);
    for( $i = 0 ; $i < count($data) ; $i++ ) {
        preg_match('/^\[(.*):(.*):(.*)\]/', trim($data[$i]), $match);
        $name = $match[1];
        $name = $name == 'FAN' ? 'Fan' : $name;
        $name = $name == 'TEMP' ? 'Temperature' : $name;
        
        for( $i++ ; $i < count($data) ; $i++ ) {
            if( $data[$i][0] == '[' ) {
                $i--;
                break;
            } else {
                $record = explode(',', trim($data[$i]));
                
                //monitor
                switch( $name ) {
                case 'Fan':
                    array_push($monitors['Fan']['series'], $record[0]);
                    break;
                case 'Temperature':
                    array_push($monitors['Temperature']['series'], $record[0]);
                    break;
                case 'Network':
                    array_push($monitors['Network']['series'], $record[0]);
                    break;
                }
            }
        }
    }
    return $monitors;
}

function update() {
    $gdata = array();
    $series = array();
    $data = file(Monitor);
    for( $i = 0 ; $i < count($data) ; $i++ ) {
        preg_match('/^\[(.*):(.*):(.*)\]/', trim($data[$i]), $match);
        $name = $match[1];
        $name = $name == 'FAN' ? 'Fan' : $name;
        $name = $name == 'TEMP' ? 'Temperature' : $name;
        
        switch($name) {
        case 'Samba':
        case 'NFS':
        case 'AFP':
        case 'FTP':
            $series[$name] = 0;
        }
        
        for( $i++ ; $i < count($data) ; $i++ ) {
            if( $data[$i][0] == '[' ) {
                $i--;
                break;
            } else {
                $record = explode(',', trim($data[$i]));
                
                //series
                switch( $name ) {
                case 'Service':
                    $record[1] += 0;
                    $record[2] += 0;
                    $series['CPU'] = isset($series['CPU']) ? $series['CPU'] + $record[1] : $record[1];
                    $series['Memory'] = isset($series['Memory']) ? $series['Memory'] + $record[2] : $record[2];
                    break;
                case 'Disk':
                    break;
                case 'Fan':
                case 'Temperature':
                    $series[$record[0]] = $record[1] + 0;
                    break;
                case 'Network':
                    $series[$record[0]] = sprintf('%.1f',($record[1] + $record[2]) / 1024) + 0;
                    break;
                default:
                    if( !isset($series[$name]) ) {
                        $series[$name] = 0;
                    } else {
                        $series[$name]++;
                    }
                }
                
                //gdata
                switch( $name ) {
                case 'Service':
                    $record[1] += 0;
                    $record[1] .= ' %';
                    array_push($gdata, array('CPU', $record[0], $record[1]));
                    $record[2] += 0;
                    $record[2] .= ' %';
                    array_push($gdata, array('Memory', $record[0], $record[2]));
                    break;
                case 'Fan':
                    $record[1] .= ' RPM';
                    break;
                case 'Temperature':
                    $record[1] .= ' °C';
                    break;
                case 'Network':
                    $record[1] = sprintf('RX: %.1f MB/s',( $record[1] / 1024));
                    $record[2] = sprintf('TX: %.1f MB/s',( $record[2] / 1024));
                    break;
                }
                
                array_unshift($record, $name);
                array_push($gdata, $record);
            }
        }
    }
    $sysinfo = new SYSINFO();
    $uptime = $sysinfo->getINFO();
    return $result = array(
        'uptime'    => &$uptime,
        'gdata'     => &$gdata,
        'series'    => &$series
    );
}

switch($_REQUEST['action']) {
case null:
    $db = new sqlitedb();
    $tpl->assign('save', $db->getvar('monitor',json_encode(null)));
    $tpl->assign('monitors', json_encode(monitor()));
    $tpl->assign('saveHistory', $db->getvar('save_history', '0'));
    
    $hasRaid = file_exists('/raid/sys/smb.db') || file_exists('/raidsys/0/smb.db');
    $tpl->assign('hasRaid', $hasRaid);
    
    $hasHistory = file_exists('/raid/sys/history.db') || file_exists('/raidsys/0/history.db');
    $tpl->assign('hasHistory', $hasHistory);
    
    $db->db_close();
    $tpl->assign('words', json_encode($session->PageCode("monitor")));
    
    $nic = Commander::fg("a", "/img/bin/rc/rc.net get_network_info | sed -nr 's/(g?eth[0-9]+|bond)\\|([^\\|]*).*/\"\\1\":\"\\2\"/p'");
    array_pop($nic);
    for( $i = 0 ; $i < count($nic); ++$i ) {
        if( preg_match("/\"bond\":\"(.*)\"/", $nic[$i], $tmp) ) {
            $nic[$i] = sprintf("\"bond%d\":\"LINK%d\"", $tmp[1], $tmp[1]+1);
        }
    }
    $nic = sprintf("{%s}", join(",", $nic));
    
    $tpl->assign('nic', $nic);
    break;
case 'update':
    die(json_encode(update()));
case 'history':
    history($_REQUEST['params']);
    die();
}


?>
