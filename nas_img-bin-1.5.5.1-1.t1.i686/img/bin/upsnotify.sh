#!/bin/sh

echo "$# $? $1" >> /tmp/ups_notify.tmp
UPSMSG=$1

event_triger() {
	sh -c "/img/bin/logevent/event $* >/dev/null 2>&1 &" 
}

event=`echo "${UPSMSG}"|awk '{print $1}'`
echo "event[${event}]" >> /tmp/ups_notify.tmp

	case "$event"
	in
		"ONLINE" )
                        echo "1">/var/tmp/ups
			event_triger 217 ${i} 
			;;
		"ONBATT" )
			ups_usems=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ups_usems'"`
			ups_ip=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ups_ip'"`
			
      drivername=`awk -F "=" '/driver=/{print $2}' /etc/ups/ups.conf`
      
      if [ ${ups_usems} == "1" ];then
        batt_charge=`/usr/bin/upsc ${drivername}@${ups_ip}|awk -F ":" '/battery.charge:/{print $2}'`
        model=`/usr/bin/upsc ${drivername}@${ups_ip}|awk -F ":" '/ups.model:/{print $2}'`
			else
        batt_charge=`/usr/bin/upsc ${drivername}@localhost|awk -F ":" '/battery.charge:/{print $2}'`
        model=`/usr/bin/upsc ${drivername}@localhost|awk -F ":" '/ups.model:/{print $2}'`
			fi
			
			sh -c "/img/bin/logevent/event 218 \"${model}\" \"${batt_charge}\" >/dev/null 2>&1 &" 
			notif_beep=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='notif_beep'"`
			if [ "${notif_beep}" == "1" ];then
				echo "Buzzer 1" > /proc/thecus_io
				sleep 5
				echo "Buzzer 0" > /proc/thecus_io
		  fi 
			;;
		"LOWBATT" )
		        echo "0">/var/tmp/ups
			event_triger 219
			;;
		"FSD" )
			event_triger 220
			;;
		"COMMOK" )
			event_triger 221
			;;
		"COMMBAD" )
			event_triger 222
			;;
		"SHUTDOWN" )
			event_triger 223
			;;
		"REPLBATT" )
			event_triger 224
			;;
		"NOCOMM" )
			rm /var/tmp/ups
			event_triger 225
			;;
		"LOWBATT_DOWN" )
			event_triger 226
			;;
	esac
