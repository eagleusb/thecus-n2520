#!/bin/sh
###########################################
#
#    This is for Battery Check,
#    Return 0 for No Battery.
#    Return 1 for Battery Good.
#    Return 2 for Battery Voltage Low.
#
###########################################

event="/img/bin/logevent/event"
powerdir="/var/tmp/power"
bat_flag="/var/tmp/power/bat_flag2"
BATNO="0"
BATLOW="1"
BATGOOD="2"

MODELNAME=`awk '/^MODELNAME/{print $2}' /proc/thecus_io`
if [ "${MODELNAME}" == "N4800" ];then
  I2C_GET="/usr/sbin/i2cget -y -f 0"
else
  I2C_GET="/usr/sbin/i2cget -y 0"
fi

BATTERY_VOLT_MIN=210
I2C_ADDRESS=0x00

###########################################
# Get MBTYPE & Battery Info 
###########################################
MBTYPE=`awk '/^MBTYPE/{print $2}' /proc/thecus_io` 
HAS_BAT=`awk '/^HAS_BAT/{print $2}' /proc/thecus_io`
#BAT_RDY=`awk '/^BAT_RDY/{print $2}' /proc/thecus_io`
BAT_CHARG=`awk '/^BAT_CHARG/{print $2}' /proc/thecus_io`
AC_RDY=`awk '/^AC_RDY/{print $2}' /proc/thecus_io`

function i2cget_dec() {
    TMP_VAR=`${I2C_GET} ${I2C_ADDRESS} $1 | cut -d x -f 2`
    return `echo $((16#$TMP_VAR))`
}

###########################################
# Make sure have /var/tmp/power 
###########################################
if [ ! -d "$powerdir" ];then
    mkdir -p /var/tmp/power
fi

if [ ! -f "$bat_flag" ];then
    echo "$BATNO" > "$bat_flag"
fi

bat_stat="$BATNO"

function check_bat_sts(){
    i2cget_dec 0x11
    BATTERY_VOLT=$?

    if [ "$AC_RDY" == "LOW" ];then

        if [ "$HAS_BAT" == "LOW" ] ;then
#            if [ "$BAT_RDY" != "LOW" ];then
            if [ $BATTERY_VOLT -lt ${BATTERY_VOLT_MIN} ];then
                bat_stat="$BATLOW"
                # event #
            
            else
                bat_stat="$BATGOOD"
            fi
        else
    	    bat_stat="$BATNO"
        fi
    else
#        if [ "$BAT_RDY" != "LOW" ];then
        if [ $BATTERY_VOLT -lt ${BATTERY_VOLT_MIN} ];then
            bat_stat="$BATLOW"     
            # event #              
                                                                               
        else                       
            bat_stat="$BATGOOD"    
        fi                          
    fi        
    echo "$bat_stat" > "$bat_flag"
}

case "$MBTYPE" in
    "500")
        I2C_ADDRESS=0x2D
        check_bat_sts
        echo "$bat_stat"
        ;;
    "501")
        I2C_ADDRESS=0x2D
        check_bat_sts
        echo "$bat_stat"
        ;;
    "502")
        I2C_ADDRESS=0x2D
        check_bat_sts
        echo "$bat_stat"
        ;;
    "701")
        I2C_ADDRESS=0x2D
        check_bat_sts
        echo "$bat_stat"
        ;;
    *)
    	echo "$BATNO";
        ;;
esac
