#!/bin/sh
MBTYPE=`awk '/^MBTYPE/{print $2}' /proc/thecus_io` 
MODELNAME=`awk '/^MODELNAME/{print $2}' /proc/thecus_io`
if [ "${MODELNAME}" == "N4800" ];then
  I2C_GET="/usr/sbin/i2cget -y -f 0"
  I2C_SET="/usr/sbin/i2cset -y -f 0"
else
  I2C_GET="/usr/sbin/i2cget -y 0"
  I2C_SET="/usr/sbin/i2cset -y 0"
fi
    
I2C_ADDRESS="0x00"
F75387_REG_CONFIGURE="0x01"
F75387_REG_V1="0x11"
F75387_REG_T1="0x14"

TEMP_MAX=60
VOLT_MAX=230
VOLT_GOOD=220
VOLT_MIN=210
CHARGE_RETRY_COUNT=0

BATTERY_NO="0"
BATTERY_LOW="1"
BATTERY_GOOD="2"
BATTERY_CHARGING="3"
MAX_CHARGE_ATTEMPTS=5

BATTERY_INFO_DIR="/var/tmp/power"
BATTERY_FLAG_FILE="/var/tmp/power/bat_flag2"
BATTERY_INFO_FILE="/var/tmp/power/bat_info"
bat_mode="/var/tmp/power/bat_mode"
event="/img/bin/logevent/event"



function has_battery_gpio() {
    HAS_BATTERY_GPIO=`awk '/^HAS_BAT/{print $2}' /proc/thecus_io`
    HAS_BATTERY_GPIO=`echo ${HAS_BATTERY_GPIO}|tr [A-Z] [a-z]`
    echo ${HAS_BATTERY_GPIO}
}

function charge_gpio_status() {
    BATTERY_CHARGING_GPIO=`awk '/^BAT_CHARG/{print $2}' /proc/thecus_io`
    BATTERY_CHARGING_GPIO=`echo ${BATTERY_CHARGING_GPIO}|tr [A-Z] [a-z]`
    echo ${BATTERY_CHARGING_GPIO}	
}


function get_battery_temp() {
    TMP_VAR=`${I2C_GET} ${I2C_ADDRESS} ${F75387_REG_T1} | cut -d x -f 2`
    echo $((16#${TMP_VAR}))
}

function get_battery_voltage() {
    TMP_VAR=`${I2C_GET} ${I2C_ADDRESS} ${F75387_REG_V1} | cut -d x -f 2`
    echo $((16#${TMP_VAR}))
}

function update_info() {
    echo "Voltage=${BATTERY_VOLT}" > ${BATTERY_INFO_FILE}
    echo "Temperature=${BATTERY_TEMP}" >> ${BATTERY_INFO_FILE}
    echo "ChargeRetryCount=${CHARGE_RETRY_COUNT}" >> ${BATTERY_INFO_FILE}
}

function get_info() {
    if [ "$1" == "ChargeRetryCount" ];then
        VALUE=`cat ${BATTERY_INFO_FILE} |grep ChargeRetryCount |awk -F 'ChargeRetryCount=' '{print $2}'`
    elif [ "$1" == "Voltage" ];then
        VALUE=`cat ${BATTERY_INFO_FILE} |grep Voltage |awk -F 'Voltage=' '{print $2}'`
    elif [ "$1" == "Temperature" ];then
        VALUE=`cat ${BATTERY_INFO_FILE} |grep Temperature |awk -F 'Temperature=' '{print $2}'`
    else
	VALUE=""
    fi
    echo ${VALUE}
}

function show_battery() {
    echo $1 > ${BATTERY_FLAG_FILE}
}


function is_system_booting() {
    if [ -f "/tmp/boot_ok1" ];then
        echo "no"
    else
        echo "yes"
    fi
}

function chip_init() {
    #set to thermistor mode
    REG_VAL=`${I2C_GET} ${I2C_ADDRESS} ${F75387_REG_CONFIGURE}`
    if [ "${REG_VAL}" != "0x00" ];then
        ${I2C_SET} ${I2C_ADDRESS} ${F75387_REG_CONFIGURE} 0x00
        sleep 1
    fi

}

function start_charge() {
    echo BAT_CHARG 1 > /proc/thecus_io
    CHARGE_RETRY_COUNT=0
}

function stop_charge() {
    echo BAT_CHARG 0 > /proc/thecus_io
    CHARGE_RETRY_COUNT=0
}

function main() {
    
    #check crond job
    BATTERY_CROND=`cat /etc/cfg/crond.conf |grep charge_bat`
    if [ "${BATTERY_CROND}" == "" ];then
        echo "*/30 * * * * /img/bin/charge_bat.sh" >> /etc/cfg/crond.conf
    fi
    
    #check Battery GPIO
    if [ `has_battery_gpio` == "high" ];then
 	      show_battery ${BATTERY_NO}
        exit
    fi

    #get current temp and voltage
    BATTERY_TEMP=`get_battery_temp`
    BATTERY_VOLT=`get_battery_voltage`
    
    #is system booting?
    if [ `is_system_booting` == "yes" ];then
        if [ "${AC_RDY}" == "HIGH" ];then
          echo "power Fail ..."
          echo 0 0 ACPWR 0 > /var/tmp/oled/pipecmd
          /img/bin/logevent/event 997 510 warning email 
          /img/bin/sys_halt       
        else 
	  if [ ${BATTERY_VOLT} -lt ${VOLT_MIN} ];then
	      start_charge
 	      show_battery ${BATTERY_CHARGING}
          else
	      stop_charge
 	      show_battery ${BATTERY_GOOD}
	  fi
	fi
	update_info
        exit
    fi

    #get Charge Retry Count Value in record
    CHARGE_RETRY_COUNT=`get_info ChargeRetryCount`
    if [ "${CHARGE_RETRY_COUNT}" == "" ];then
        CHARGE_RETRY_COUNT=0
    fi

    #Battery Overheat?
    if [ ${BATTERY_TEMP} -gt ${TEMP_MAX} ];then
        #if charging stop charging
        if [ `charge_gpio_status` == "high" ];then
	    stop_charge
        fi
	if [ ${BATTERY_VOLT} -lt ${VOLT_MIN} ];then
            show_battery ${BATTERY_LOW}
	else
            show_battery ${BATTERY_GOOD}
 	fi
	update_info
	exit
    fi

    #Battery Temperature normal
    #None Charge State
    if [ `charge_gpio_status` == "low" ];then
        #battery voltage below MIN
        if [ ${BATTERY_VOLT} -lt ${VOLT_MIN} ];then
	    #Charge has failed, keep showing low
	    if [ ${CHARGE_RETRY_COUNT} == 255 ];then
 	        show_battery ${BATTERY_LOW}
	    else
  	 	#start charging bettery
	        start_charge
 	        show_battery ${BATTERY_CHARGING}
	    fi
	else
 	    show_battery ${BATTERY_GOOD}
        fi	
    else
        if [ ${BATTERY_VOLT} -gt ${VOLT_GOOD} ];then
	    stop_charge
 	    show_battery ${BATTERY_GOOD}
        else
	    if [ ${BATTERY_VOLT} -gt `get_info Voltage` ];then
		CHARGE_RETRY_COUNT=0
 	        show_battery ${BATTERY_CHARGING}
	    else
		if [ ${CHARGE_RETRY_COUNT} -ge ${MAX_CHARGE_ATTEMPTS} ];then
                    ${event} 997 ${event_ID} "error" "email"
	    	    stop_charge
		    CHARGE_RETRY_COUNT=255
 	            show_battery ${BATTERY_LOW}
		else
		    CHARGE_RETRY_COUNT=$((${CHARGE_RETRY_COUNT}+1))
 	            show_battery ${BATTERY_CHARGING}
	        fi	
 	    fi
 	fi
    fi
    update_info
}

if [ ! -d ${BATTERY_INFO_DIR} ];then
    mkdir -p ${BATTERY_INFO_DIR}
fi

if [ ! -f ${BATTERY_FLAG_FILE} ];then
    touch ${BATTERY_FLAG_FILE}
fi

if [ ! -f ${BATTERY_INFO_FILE} ];then
    touch ${BATTERY_INFO_FILE}
fi



AC_RDY=`awk '/^AC_RDY/{print \$2}' /proc/thecus_io`
if [ "${AC_RDY}" == "HIGH" ];then
    echo 1 > ${bat_mode}
else
    echo 0 > ${bat_mode}    
fi

case "${MBTYPE}" in
    "500")
        I2C_ADDRESS=0x2D
	event_ID="688"
	chip_init
	main
        ;;
    "501")
        I2C_ADDRESS=0x2D
	event_ID="688"
	chip_init
	main
        ;;
    "502")
        I2C_ADDRESS=0x2D
	event_ID="688"
	chip_init
	main
        ;;
    "701")
        I2C_ADDRESS=0x2D
	event_ID="689"
	chip_init
	main
        ;;
    *)
        ;;
esac
