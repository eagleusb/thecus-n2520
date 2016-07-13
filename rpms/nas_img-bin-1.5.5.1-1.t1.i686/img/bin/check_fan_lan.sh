#!/bin/sh
[ ! "`/img/bin/check_env.sh -r hwm`" == "exist" ] && exit
#exit when hardware monitor is not supported.
[ "`/img/bin/check_service.sh cpu_fan1`" == "0" \
	-a "`/img/bin/check_service.sh sys_fan1`" == "0" \
	-a "`/img/bin/check_service.sh sys_fan2`" == "0" \
	-a "`/img/bin/check_service.sh cup_temp1`" == "0" \
	-a "`/img/bin/check_service.sh sys_temp`" == "0" ] && exit

##Check Fan, Lan and Temperature Status
arch=`/img/bin/check_service.sh arch`
fan_chip=`/img/bin/check_service.sh fan_chip`
fan_temp_ui_icon=`/img/bin/check_service.sh fan_temp_ui_icon`
f75387sg_fan=`/img/bin/check_service.sh f75387sg_fan`
#CPU_FAN is CPU fan name.
CPU_FAN=`/img/bin/check_service.sh fan_cpu`
MBTYPE=`awk '/MBTYPE/ {print $2}' /proc/thecus_io`

cpu_check_point=1000
beep_time=30000
fan1_error=0
fan2_error=0
fan3_error=0
fan_repair=0
beep_enable="/tmp/beep_enable"
fan_beep=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k like 'notif_beep%'"`
echo "${fan_beep}" > ${beep_enable}
wan=$(ifconfig eth0 |grep "RUNNING")
#lan=$(ifconfig eth1 |grep "RUNNING")

max_temp=70
max_temp_ui=60
sleep_sec=60
chk_ui=1

chk_beep_count=100
beep_count=0

#smart_fan
fan_bt_0=60
fan_bt_1=50
fan_bt_2=40
fan_bt_3=25
pre_fan=0
pre_cpu_fan=0
#level_1_power=80 0xCC
#level_2_power=60 0x99
#level_3_power=45 0x72

#talktolcm="/img/bin/model/talktolcm.sh"
notification_cpu_temp(){
	echo "notification_cpu_temp"
	/img/bin/logevent/event 997 646 error email CPU
	/img/bin/sys_halt &
	exit
}

notification_sys_temp(){
	echo "notification_sys_temp"
	/img/bin/logevent/event 997 646 error email SYSTEM
	/img/bin/sys_halt &
}

notification_enc_temp(){
	echo "notification_enc_temp"
	/img/bin/logevent/event 997 646 error email ENCLOSURE
	/img/bin/sys_halt &
}

chk_cpu_temp(){
	temp_cpu=`eval ${cpu_str}`
	temp_cpu_ui=`eval ${cpu_str_ui}`
	#echo -e "temp_cpu=${temp_cpu}"
	if [ "${temp_cpu}" != "" ];then
		sleep 5
		temp_cpu=`eval ${cpu_str}`
		if [ "${temp_cpu}" != "" ];then
			notification_cpu_temp
		fi
	fi
}

chk_sys_temp(){
	temp_sys=`eval ${sys_str}`
	temp_sys_ui=`eval ${sys_str_ui}`
	#echo -e "temp_sys=${temp_sys}"
	if [ "${temp_sys}" != "" ];then
		sleep 5
		temp_sys=`eval ${sys_str}`
		if [ "${temp_sys}" != "" ];then
			notification_sys_temp
		fi
	fi
}

chk_enc_temp(){

	temp_enc=""
	temp_enc_ui=""

	for location in 52 78 104 130
	do
		if [ -e /dev/sg$location ];then
			high_temp=0
			for tmp in `sg_ses -p 0x02 /dev/sg$location | sed ':a;N;$!ba;s/\n/ /g;s/El/\n/g' | sed -nr 's/.*us: [CO].*Id.*(Te\w*)=([0-9]+) .*/\2/p;' | head -n 8`
			do
			if [ $tmp -gt $high_temp ]; then
				 high_temp=$tmp
			fi
			done
			if [ $high_temp -ge $max_temp ]; then
				sleep 5
				high_temp=0
				for tmp in `sg_ses -p 0x02 /dev/sg$location | sed ':a;N;$!ba;s/\n/ /g;s/El/\n/g' | sed -nr 's/.*us: [CO].*Id.*(Te\w*)=([0-9]+) .*/\2/p;' | head -n 8`
				do
					if [ $tmp -gt $high_temp ]; then
						high_temp=$tmp
					fi
				done
				if [ $high_temp -ge $max_temp ]; then
					notification_enc_temp
				fi
			fi
			if [ $high_temp -ge $max_temp_ui ]; then
				temp_enc_ui=1
			fi
		fi
	done
}

temperature_loop(){
	#####################################################
	#	Check CPU Temperature
	#####################################################
	if [ "${is_chk_cpu}" -gt "0" ];then
		chk_cpu_temp
	fi

	#####################################################
	#	Check SYSTEM Temperature
	#####################################################
	if [ "${is_chk_sys}" -gt "0" ];then
		chk_sys_temp
	fi

	if [ "${is_chk_enc}" -gt "0" ];then
		chk_enc_temp
	fi

	if [ "${temp_sys_ui}" == "" ] && [ "${temp_cpu_ui}" == "" ] && [ "${temp_enc_ui}" == "" ]; then
		chk_ui=1
	else
		chk_ui=0
	fi

	if [ "${fan_temp_ui_icon}" == "1" ];then
			echo "${chk_ui}">/var/tmp/temperature
	fi
}

notification_fan1(){
	notify_rpm1=$1
	notify_temp1=$2
	#echo "fan1 error = $fan1_error"
	if [ "$fan1_error" -ne "1" ]; then
		/img/bin/logevent/event 997 308 error "" "${hostname}" "${fan1_name}" "${notify_rpm1}" "${notify_temp1}" &
		/img/bin/logevent/event 997 216 "error" email "${hostname}" "${fan1_name}" &

		if [ "${fan_temp_ui_icon}" == "1" ];then
			echo "0">/var/tmp/fan
		fi
		fan1_error=1
	fi

	if [ "$fan_beep" != "0" ] && [ "${fan_beep}" != "2" ];then
		echo "Buzzer 1" > /proc/thecus_io
	fi
}

notification_fan2(){
	notify_rpm1=$1
	notify_temp1=$2
	#echo "fan2 error = $fan2_error"
	if [ "$fan2_error" -ne "1" ]; then
		/img/bin/logevent/event 997 308 error "" "${hostname}" "${fan2_name}" "${notify_rpm1}" "${notify_temp1}" &
		/img/bin/logevent/event 997 216 "error" email "${hostname}" "${fan2_name}" &
		if [ "${fan_temp_ui_icon}" == "1" ];then
			echo "0">/var/tmp/fan
		fi
		fan2_error=1
	fi

	if [ "$fan_beep" != "0" ] && [ "${fan_beep}" != "2" ];then
		echo "Buzzer 1" > /proc/thecus_io
	fi
}

notification_fan3(){
	notify_rpm1=$1
	if [ "$fan3_error" -ne "1" ]; then
		/img/bin/logevent/event 997 320 error "" "${hostname}" "${fan3_name}" "${notify_rpm1}" "" &
		/img/bin/logevent/event 997 216 "error" email "${hostname}" "${fan3_name}" &
		if [ "${fan_temp_ui_icon}" == "1" ];then
			echo "0">/var/tmp/fan
		fi
		fan3_error=1
	fi

	if [ "$fan_beep" != "0" ] && [ "${fan_beep}" != "2" ];then
		echo "Buzzer 1" > /proc/thecus_io
	fi
}

buzzer_off(){
	echo "Buzzer 0" > /proc/thecus_io
}

#[ID 4831] Change the smart fan rule.
check_spin_down(){
	# IS_SPINDOWN: 0->spin up, 1->spin down
	local IS_SPINDOWN="0"
	for DISK in `awk '/Disk/ {print $3}' /proc/scsi/scsi | awk -F ':' '{print $2}'`;do
		local SPIN_STATE=`hdparm -C /dev/$DISK | awk '/drive state/ {print $4}'`
		if [ "$SPIN_STATE" != "standby" ];then
			IS_SPINDOWN="0"
			break
		else
			IS_SPINDOWN="1"
		fi
	done
	return $IS_SPINDOWN
}

# [ID 4835] To control the fan speed.
set_f75387sg_fan(){
	local TEMP=$1
	local LOW_SPEED=$2

	fan_bt_0=48
	fan_bt_1=42

	check_spin_down
	local IS_SPINDOWN=$?

	if [ "${TEMP}" -gt "${fan_bt_0}" ] || [ "${IS_SPINDOWN}" == "0" ];then
	# The system fan is set "duty=255" when temperature is higher than upper
	# boundary or at least one of the disks spins up.
		if [ "${pre_fan}" != "0" ];then
			pre_fan=0
			echo ${f75387sg_fan} duty 255 > /proc/hwm
		fi
	else
		if [ "${pre_fan}" != "1" ];then
			pre_fan=1
			echo ${f75387sg_fan} duty "${LOW_SPEED}" > /proc/hwm
		fi
	fi
}

adjust_tmp401(){
	local temp=$1
	if [ "${temp}" = "" ];then
		temp=99
	fi

	fan_bt_0=45
	fan_bt_1=27

	if [ ${temp} -gt ${fan_bt_0} ];then
		if [ "${pre_fan}" != "0" ];then
			pre_fan=0
			echo 100 > /sys/class/pwm/pwm.4:1/duty_ns
		fi
	elif [ ${temp} -gt ${fan_bt_1} ] && [ ${temp} -le ${fan_bt_0} ];then
		if [ "${pre_fan}" != "1" ];then
			pre_fan=1
			echo 74 > /sys/class/pwm/pwm.4:1/duty_ns
		fi
	else
		if [ "${pre_fan}" != "2" ];then
			pre_fan=2
			echo 0 > /sys/class/pwm/pwm.4:1/duty_ns
		fi
	fi
}

#[ID 4831] Change the smart fan rule.
# 1. The speed of fan will come up when the temperature is higher than upper
# 	 boundary or at least one of the disks spins up.
# 2. The speed of fan will come down when all of the disks spin down.
adjust_f75387sg(){
	local temp=$1
	if [ "${temp}" = "" ];then
		temp=99
	fi

	if [ "$MBTYPE" == "805" ] || [ "$MBTYPE" == "804" ];then
		# For issue 4835, the CPU fan speed will be set to "duty=60" when boot
		# to SW, if the hardware monitor support the control of CPU fan.
		if [ "$pre_cpu_fan" != "1" ] && [ "$CPU_FAN" != "" ];then
			echo ${CPU_FAN} duty 60 > /proc/hwm
			pre_cpu_fan=1
		fi
		# When all disks spin down, the system fan is set to "duty=0".
		set_f75387sg_fan ${temp} '0'
	else
		# The system fan is set "duty=11" when all of the disks spin down.
		set_f75387sg_fan ${temp} '11'
	fi
}

adjust_ITE8728(){
	if [ ${temp} -gt ${fan_bt_0} ];then
		if [ "${pre_fan}" != "0" ];then
			pre_fan=0
			echo "REG 1 0x63 0xFF" > /proc/hwm
			echo "REG 1 0x6B 0xFF" > /proc/hwm
			echo "REG 1 0x73 0xFF" > /proc/hwm
		fi
	elif [ ${temp} -gt ${fan_bt_1} ] && [ ${temp} -le ${fan_bt_0} ];then
		if [ "${pre_fan}" != "1" ];then
			pre_fan=1
			echo "REG 1 0x63 0xCC" > /proc/hwm
			echo "REG 1 0x6B 0xCC" > /proc/hwm
			echo "REG 1 0x73 0xCC" > /proc/hwm
		fi
	elif [ ${temp} -gt ${fan_bt_2} ] && [ ${temp} -le ${fan_bt_1} ];then
		if [ "${pre_fan}" != "2" ];then
			pre_fan=2
			echo "REG 1 0x63 0xB2" > /proc/hwm
			echo "REG 1 0x6B 0xB2" > /proc/hwm
			echo "REG 1 0x73 0xB2" > /proc/hwm
		fi
	elif [ ${temp} -gt ${fan_bt_3} ] && [ ${temp} -le ${fan_bt_2} ];then
		if [ "${pre_fan}" != "3" ];then
			pre_fan=3
			echo "REG 1 0x63 0x99" > /proc/hwm
			echo "REG 1 0x6B 0x99" > /proc/hwm
			echo "REG 1 0x73 0x99" > /proc/hwm
		fi
	else
		if [ "${pre_fan}" != "4" ];then
			pre_fan=4
			echo "REG 1 0x63 0x00" > /proc/hwm
			echo "REG 1 0x6B 0x00" > /proc/hwm
			echo "REG 1 0x73 0x00" > /proc/hwm
		fi
	fi
}

adjust_ITE8728_F75387SG(){
	if [ ${temp} -gt ${fan_bt_0} ];then
		if [ "${pre_fan}" != "0" ];then
			pre_fan=0
			echo REG 1 0x75 0xFF > /proc/f75387sg1
			echo REG 1 0x85 0xFF > /proc/f75387sg1
			echo REG 1 0x75 0xFF > /proc/f75387sg2
			echo REG 1 0x85 0xFF > /proc/f75387sg2
		fi
	elif [ ${temp} -gt ${fan_bt_1} ] && [ ${temp} -le ${fan_bt_0} ];then
		if [ "${pre_fan}" != "1" ];then
			pre_fan=1
			echo REG 1 0x75 0xFF > /proc/f75387sg1
			echo REG 1 0x85 0xFF > /proc/f75387sg1
			echo REG 1 0x75 0xFF > /proc/f75387sg2
			echo REG 1 0x85 0xFF > /proc/f75387sg2
			sleep 3
			echo REG 1 0x75 0x1C > /proc/f75387sg1
			echo REG 1 0x85 0x1C > /proc/f75387sg1
			echo REG 1 0x75 0x1C > /proc/f75387sg2
			echo REG 1 0x85 0x1C > /proc/f75387sg2
		fi
	elif [ ${temp} -gt ${fan_bt_2} ] && [ ${temp} -le ${fan_bt_1} ];then
		if [ "${pre_fan}" != "2" ];then
			pre_fan=2
			echo REG 1 0x75 0xFF > /proc/f75387sg1
			echo REG 1 0x85 0xFF > /proc/f75387sg1
			echo REG 1 0x75 0xFF > /proc/f75387sg2
			echo REG 1 0x85 0xFF > /proc/f75387sg2
			sleep 3
			echo REG 1 0x75 0x17 > /proc/f75387sg1
			echo REG 1 0x85 0x17 > /proc/f75387sg1
			echo REG 1 0x75 0x17 > /proc/f75387sg2
			echo REG 1 0x85 0x17 > /proc/f75387sg2
		fi
	elif [ ${temp} -gt ${fan_bt_3} ] && [ ${temp} -le ${fan_bt_2} ];then
		if [ "${pre_fan}" != "3" ];then
			pre_fan=3
			echo REG 1 0x75 0xFF > /proc/f75387sg1
			echo REG 1 0x85 0xFF > /proc/f75387sg1
			echo REG 1 0x75 0xFF > /proc/f75387sg2
			echo REG 1 0x85 0xFF > /proc/f75387sg2
			sleep 3
			echo REG 1 0x75 0x12 > /proc/f75387sg1
			echo REG 1 0x85 0x12 > /proc/f75387sg1
			echo REG 1 0x75 0x12 > /proc/f75387sg2
			echo REG 1 0x85 0x12 > /proc/f75387sg2
		fi
	else
		if [ "${pre_fan}" != "4" ];then
			pre_fan=4
			echo REG 1 0x75 0x00 > /proc/f75387sg1
			echo REG 1 0x85 0x00 > /proc/f75387sg1
			echo REG 1 0x75 0x00 > /proc/f75387sg2
			echo REG 1 0x85 0x00 > /proc/f75387sg2
		fi
	fi
}

smart_fan(){
	local temp=$1
	#temp=`cat /proc/hwm | awk '/CPU_TEMP/{print $2}'`
	if [ "${temp}" = "" ];then
		temp=99
	fi

	case "${fan_chip}" in
		'tmp401')
			adjust_tmp401 "${temp}"
		;;
		'f75387sg')
			adjust_f75387sg "${temp}"
		;;
		'ITE8728')
			adjust_ITE8728 "${temp}"
		;;
		'ITE8728|F75387SG')
			adjust_ITE8728_F75387SG "${temp}"
		;;
	esac
} 

############################
# Check Fan Lan For oxnas N2200 (mbtyp=401)
############################

fan_lan_oxnas(){

	while :
	do
		new_fan_beep=`cat ${beep_enable}`
		if [ ${new_fan_beep} != ${fan_beep} ] && [ ${new_fan_beep} != "" ];
		then
			fan_beep=${new_fan_beep}
		fi
		hostname=`echo $HOSTNAME`
		#echo "host = $hostname"


		#####################################################
		#		Check Systm fan2
		#####################################################
		if [ "${SYS_FAN1}" == "1" ];
		then
			fan2=$(cat /proc/hwm |grep "FAN 1"|cut -d " " -f4)
			if [ "$fan2" -le "0" ]; then
				notification_fan2
			else

				if [ ${fan2_error} == "1" ]; then
					buzzer_off
				fi

				if [ "${fan_temp_ui_icon}" == "1" ];then
						echo "1">/var/tmp/fan
				fi
				fan2_error=0
			fi
		fi

		temperature_loop
		sleep ${sleep_sec}
		clear
	done
}

fan_lan_x86_64(){
	i=0
	while [ "$i" -le "${SYS_FAN1}" ]
	do
		fan_error[$i]=0
		i=$(($i+1))
	done

	for location in 52 78 104 130
	do
		if [ -e /dev/sg$location ];then
			ENC_NUM=$(( $location/26-1 ))
			ENC_FAN=$(($ENC_FAN+2))
			i=0
			while [ "$i" -le 2 ]
			do
				fan_error[$(( $ENC_NUM*4+$i ))]=0
				i=$(($i+1))
			done
		fi
	done

	while :
	do
		new_fan_beep=`cat ${beep_enable}`
		if [ ${new_fan_beep} != ${fan_beep} ] && [ ${new_fan_beep} != "" ];then
			fan_beep=${new_fan_beep}
		fi
		hostname=`echo $HOSTNAME`
		#echo "host = $hostname"

		#####################################################
		#		Check CPU fan
		#####################################################
		if [ "${CPU_FAN1}" == "1" ];then
			cpu_temp=$(cat /proc/hwm |grep "CPU_TEMP"|cut -d ":" -f2|sed 's/ //g')
			cpu_fan1=$(cat /proc/hwm |grep "CPU_FAN"|cut -d ":" -f2|sed 's/ //g')
			if [ "$cpu_temp" -ge "30" -a "$cpu_fan1" -le "0" ]; then
				notification_fan1 "${cpu_fan1}" "${cpu_temp}"
			else
				fan1_error=0
			fi
		fi

		#####################################################
		#		Check Systm fan
		#####################################################
		fan_ok=0
		high_temp=0
		templist=`cat /proc/hwm |grep "_TEMP"|grep -v CPU|sed 's/ //g'`
		for temp in $templist
		do
			temp2=$(echo ${temp} |cut -d ":" -f2|sed 's/ //g')
			if [ ${temp2} -ge ${high_temp} ];then
				high_temp=${temp2}
			fi
		done

		smart_fan ${high_temp}
		sleep 3

		i=1
		fanlist=`cat /proc/hwm |grep FAN|grep -v CPU | grep -v SYS_FAN |sed 's/ //g'`
		for fan in $fanlist
		do
			if [ "$i" -le "${SYS_FAN1}" ];then
				fan2=$(echo ${fan} |cut -d ":" -f2|sed 's/ //g')

				if [ "${high_temp}" -ge "30" -a "$fan2" -le "0" ]; then
					if [ "${fan_error[$i]}" == "0" ];then
						fan2_name="system(${i})"

						#fan2_error=0 let notification_fan2 to send log, then fan2_error will be set to 1
						fan2_error=0
						notification_fan2 "${fan2}" "${high_temp}"
						sleep_sec=30
					else
						if [ "$fan_beep" != "0" ] && [ "${fan_beep}" != "2" ];then
							echo "Buzzer 1" > /proc/thecus_io
						fi
					fi

					fan_error[$i]=1
					if [ "${fan_temp_ui_icon}" == "1" ];then
							echo "0">/var/tmp/fan
					fi
				else
					fan_ok=$(($fan_ok+1))
					fan_error[$i]=0
				fi
			fi

			i=$(($i+1))
		done

		if [ "$fan_ok" -eq "${SYS_FAN1}" ]; then
			fan2_error=0
		fi

		if [ "${is_chk_enc}" -gt "0" ];then
			fan_ok=0
			for location in 52 78 104 130
			do
				if [ -e /dev/sg$location ];then
					i=0
					fanlist=`sg_ses -p 0x2 /dev/sg$location | grep 'Actual speed' | head -n 3 | tail -n 2 | cut -d= -f2 | cut -d' ' -f1`
					for fan3 in $fanlist
					do
						if [ "$fan3" -le "0" ]; then
							if [ "${fan_error[$(( $ENC_NUM*4+$i ))]}" == "0" ];then
								fan3_name="D16000-$ENC_NUM #${i}"
								fan3_error=0
								notification_fan3 "${fan3}"
								sleep_sec=30
							else
								if [ "$fan_beep" != "0" ] && [ "${fan_beep}" != "2" ];then
									echo "Buzzer 1" > /proc/thecus_io
								fi
							fi
							fan_error[$(( $ENC_NUM*4+$i ))]=1
							if [ "${fan_temp_ui_icon}" == "1" ];then
									echo "0">/var/tmp/fan
							fi
						else
							fan_ok=$(($fan_ok+1))
							fan_error[$(( $ENC_NUM*4+$i ))]=0
						fi
						i=$(($i+1))
					done
				fi
			done

			if [ "$fan_ok" -eq "${ENC_FAN}" ]; then
				fan3_error=0
			fi
		fi

		if [ ${fan1_error} == "0" ] && [ ${fan2_error} == "0" ] && [ ${fan3_error} == "0" ]; then
			if [ "`cat /var/tmp/fan`" == "0" ];then
				buzzer_off
			fi
			sleep_sec=60

			if [ "${fan_temp_ui_icon}" == "1" ];then
					echo "1">/var/tmp/fan
			fi
		fi

		temperature_loop
		sleep ${sleep_sec}
		clear
	done
}

arch=`/img/bin/check_service.sh arch`

case "$arch" in

	'oxnas')
		SYS_FAN1=`/img/bin/check_service.sh sys_fan1`

		fan1_name=""
		fan2_name="system"
		fan3_name=""

		is_chk_cpu="0"
		is_chk_sys="1"
		cpu_str=""
		sys_str="awk '/^Temp 1: /{if(\$3>=${max_temp}) print \$3}' \/proc\/hwm"
		sys_str_ui="awk '/^Temp 1: /{if(\$3>=${max_temp_ui}) print \$3}' \/proc\/hwm"

		fan_lan_oxnas
		;;
	'x86_64')
		max_temp=90
		max_temp_ui=90

		CPU_FAN1=`/img/bin/check_service.sh cpu_fan1`
		SYS_FAN1=`/img/bin/check_service.sh sys_fan1`
		ENC_FAN=0

		fan1_name="cpu"
		fan2_name="system"
		fan3_name="enclosure"

		is_chk_cpu=`/img/bin/check_service.sh cup_temp1`
		is_chk_sys=`/img/bin/check_service.sh sys_temp`
		is_chk_enc=`/img/bin/check_service.sh enclosure`

		if [ "${is_chk_cpu}" == "" ];then
			is_chk_cpu=0
		fi

		if [ "${is_chk_sys}" == "" ];then
			is_chk_sys=0
		fi

		if [ "${is_chk_enc}" == "" ];then
			is_chk_enc=0
		fi
		is_chk_enc=1

		cpu_str="cat /proc/hwm | grep TEMP | grep CPU | awk -F\":\" '{if(\$2>=${max_temp}) print \$2}' | sed 's/ //g'"
		cpu_str_ui="cat /proc/hwm |grep TEMP | grep CPU |awk -F\":\" '{if(\$2>=${max_temp_ui}) print \$2}'|sed 's/ //g'"
		sys_str="cat /proc/hwm | grep TEMP | grep -v CPU | awk -F\":\" '{if(\$2>=${max_temp}) print \$2}' | sed 's/ //g'"
		sys_str_ui="cat /proc/hwm |grep TEMP | grep -v CPU |awk -F\":\" '{if(\$2>=${max_temp_ui}) print \$2}'|sed 's/ //g'"

		fan_lan_x86_64
		;;
	*)
		# Default is "start", for backwards compatibility with previous
		# Slackware versions. This may change to a 'usage' error someday.
		echo "Usage : "
esac
