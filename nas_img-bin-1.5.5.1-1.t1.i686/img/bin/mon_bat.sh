#!/bin/sh
#############################################################
#    This is for AC lose Battery Monitor
#    1.Set Battery Mode Flag 1 to /var/tmp/power/bat_mode
#    2.Check AC status
#    3.Stop Service && set sync speed to minimize
#    4.Check Battery Status , if not good, shutdown ASAP
#############################################################
event="/img/bin/logevent/event"
powerdir="/var/tmp/power"
bat_flag="/var/tmp/power/bat_flag2"
bat_mode="/var/tmp/power/bat_mode"
bat_low_flag="0"
beep_enable="/tmp/beep_enable"
echo 1 > ${beep_enable}
DEFAULT_SYNC_MAX="6000000"
DEFAULT_SYNC_MIN="60000"
BAT_SYNC_SPEED="512"
BAT_TIMEOUT=20
BAT_INTERVAL=3

# include raid_tool
#. /img/bin/raid_tool

#rebuild_speed=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='rebuild_speed'"`
#if [ $rebuild_speed ];then
#    if [ $rebuild_speed = "high" ];then
#            DEFAULT_SYNC_MAX=6000000
#        else
#            DEFAULT_SYNC_MAX=2000000
#    fi
#fi

###########################################
# Get MBTYPE & Battery Info
###########################################
MBTYPE=`awk '/^MBTYPE/{print $2}' /proc/thecus_io`

function set_bat_mode(){
    
# Make sure have /var/tmp/power                                                                                                                                                         
  if [ ! -d "$powerdir" ];then                                                                                                                                                            
    mkdir -p /var/tmp/power                                                                                                                                                             
  fi 
  echo $1 > $bat_mode   
}

function set_bat_sync_speed(){
    #echo "Setting Battery Mode Sync Speed" $BAT_SYNC_SPEED
    rt_set_speed_max "$BAT_SYNC_SPEED"
    rt_set_speed_min "$BAT_SYNC_SPEED"
}

function set_default_sync_speed(){
    echo "Setting Default Sync Speed"
    rt_set_speed_max "$DEFAULT_SYNC_MAX"
    rt_set_speed_min "$DEFAULT_SYNC_MIN"
}

# This is for battery mode stage.1 , service are still running.
function mon_acrecover(){
    ac_str="awk '/^AC_RDY/{print \$2}' /proc/thecus_io"
    mon_ac=`eval "$ac_str"`
    if [ "$mon_ac" == "LOW" ];then
        
        echo "AC is Recover,Now Double Check."
        sleep $BAT_INTERVAL
        
        mon_ac=`eval "$ac_str"`
        if [ "$mon_ac" == "LOW" ];then
            echo "OK, AC is Really Back."
            set_bat_mode 0
            #set_default_sync_speed
            exit
        fi
    fi
}

# This is for battery mode stage.2 , service stopped.
function mon_acready(){
    ac_str="awk '/^AC_RDY/{print \$2}' /proc/thecus_io"
    mon_ac=`eval "$ac_str"`
    if [ "$mon_ac" == "LOW" ];then
        
        echo "AC is Recover,Now Double Check."
        sleep $BAT_INTERVAL
        
        mon_ac=`eval "$ac_str"`
        if [ "$mon_ac" == "LOW" ];then
            echo "OK, AC is Really Back."
            set_bat_mode 0
            #/img/bin/independ_service start
            /img/bin/service start 
            #set_default_sync_speed
            exit
        fi
    fi
}

function check_nas_status(){
  upgrade_status=`ps www | grep postup.sh | grep -v grep`
  dom_status=`ps www | grep dom_restore.sh | grep -v grep`
  status="0"
  if [ "${upgrade_status}" != "" ] || [ "${dom_status}" != "" ];then
    status="1" 
  fi
  echo $status
}

function kill_migrate_proc(){
  killall migrate_raid_online.sh
  killall rsync_raid.sh
  killall rysnc
}

function wait_acrecover(){
    mon_acrecover
    #set_bat_sync_speed
    check_time=0
    while [ $check_time -lt $BAT_TIMEOUT  ];
    do
        mon_acrecover
        pwr_beep=`cat ${beep_enable}`                                                                                                                                          
        if [ ${pwr_beep} -eq 1 ];then
            # FIXME!!! This is not support for AMD/LX800 base model.                                                                                                                                         
            echo "Buzzer 1" > /proc/thecus_io
            sleep 3
            echo "Buzzer 0" > /proc/thecus_io          
        fi
        
        bat_stat=`sh /img/bin/check_bat.sh`
        if [ "${bat_stat}" == "1" ];then
            break;
        fi
        
        #set_bat_sync_speed   # just make sure hot_add won't change speed. 
        sleep $BAT_INTERVAL
        check_time=`expr $check_time + 1`          
                       
    done
}

function mon_battery(){
    mon_acready
    #set_bat_sync_speed
    /img/bin/service stop 
    #/img/bin/independ_service stop
    check_time=0
    while [ $check_time -lt $BAT_TIMEOUT  ];
    do
        mon_acready
        
        pwr_beep=`cat ${beep_enable}`                                                                                                                                          
        if [ ${pwr_beep} -eq 1 ];then                                                                                                                                         
           echo "Buzzer 1" > /proc/thecus_io
           sleep 3
           echo "Buzzer 0" > /proc/thecus_io 
        fi                          
        
        bat_stat=`sh /img/bin/check_bat.sh` 
        nas_status=`check_nas_status`
        if [ "${bat_stat}" == "1" ];then
            if [ "${bat_low_flag}" == "0" ];then
              ${event} 997 511 warning email
              bat_low_flag="1"
            fi
           
            if [ "${nas_status}" == "1" ];then
              echo "Battery Capacity is Low.Emergency, but nas process upgrade or dom backup"
              # FIXME!!! Need to do more while postup.sh running              
            else
              echo "Battery Capacity is Low.Emergency Shutdown."
              kill_migrate_proc
              /img/bin/sys_halt batteryoff
              exit
            fi
        fi
        #set_bat_sync_speed   # just make sure hot_add won't change speed.
        sleep $BAT_INTERVAL
        check_time=`expr $check_time + 1`
        if [ "${nas_status}" == "1" ] && [ $check_time -eq $BAT_TIMEOUT ] ;then
          check_time=`expr $check_time - 1`
        fi
    done
    echo "Battery Timeout going to Emergency Shutdown!!"
    # FIXME!!! Need to do more while postup.sh running
    kill_migrate_proc
    /img/bin/sys_halt batteryoff
}

###########################################
# Check AC ready or Not
###########################################
AC_RDY=`awk '/^AC_RDY/{print \$2}' /proc/thecus_io`

case "$MBTYPE" in
    "500" )
        if [ "$AC_RDY" != "Low" ];
        then
            echo "Running Battery Mode."
            set_bat_mode 1
            wait_acrecover
            mon_battery
        else
            echo "AC is Ready."
        fi    
        ;;
    "501" )
        if [ "$AC_RDY" != "Low" ];
        then
            echo "Running Battery Mode."
            set_bat_mode 1
            wait_acrecover
            mon_battery
        else
            echo "AC is Ready."
        fi    
        ;;
    "502" )
        if [ "$AC_RDY" != "Low" ];
        then
            echo "Running Battery Mode."
            set_bat_mode 1
            wait_acrecover
            mon_battery
        else
            echo "AC is Ready."
        fi    
        ;;
    "701" )
        if [ "$AC_RDY" != "LOW" ];
        then
            echo "Running Battery Mode."
            set_bat_mode 1
            wait_acrecover
            mon_battery
        else
            echo "AC is Ready."
        fi    
        ;;
    *)
        echo "Not Support Battery Mode!!"
        exit
        ;;

esac
