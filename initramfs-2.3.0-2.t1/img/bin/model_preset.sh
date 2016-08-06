#!/bin/sh

init_env(){
	OPT=$1
	[ -n "$OPT" ] && CMDS=`echo $@ | sed 's/'$OPT'//g'` || CMDS=""
	MODEL=`awk '/^MODELNAME/ {print $2}' /proc/thecus_io`
}

# Enable button control if need.
mcu_ready(){
	case "$MODEL" in
	N4310)
		echo "PWR_LED 1" > /proc/thecus_io	#system boots up
		sleep 1
		echo "PWR_LED 2" > /proc/thecus_io	#LED blinking
		;;
	N4520|N4560)
		/img/bin/pic.sh LCM_MSG "System" "Set PIC"
		if [ "`/img/bin/check_service.sh pic24lcm`" -eq "1" ];then
			echo "PWR_S 2" > /proc/thecus_io
			sleep 1
			echo "PWR_S 1" > /proc/thecus_io
		fi
		;;
	esac
}

# Configure phy if need.
set_phy(){
	case "$MODEL" in
	N2310)
		# Configure phy for QM error issue
		/img/bin/apm86xxx_enet.sh $1
		;;
	esac
}

# Work around for Realtek phy issue that Speed is not configured on 1000M
# while NAS is connected to 1000M network.
# We will retry only once since we can't assume that the network environment
# user uses must be 1000M, maybe it is 100M or 10M.
link_speed_check(){
	local LINKUP_STR="$1"
	echo "Check NIC Link"
	/img/bin/pic.sh LCM_MSG "System" "Check NIC Link"
	sleep 1
	SPEED=`ethtool eth0 | awk -F ': ' '/Speed: /{print $2}' | sed 's/Mb\/s//g'`
	HasDectect=`/sbin/ethtool eth0 | awk -F ': ' '/Link detected: /{print $2}'`

	# do link down and link up to reset interface
	if [ "${HasDectect}" = "yes" ] && [ "${SPEED}" -lt "1000" ];then
		dmesg > /tmp/DMESG
		ifconfig eth0 down
		sleep 2
		ifconfig eth0 up

		# wait for link ready then leave here
		link_ready=0
		while [ ${link_ready} = 0 ];do
			dmesg > /tmp/DMESG2
			LinkDmesg=`diff /tmp/DMESG /tmp/DMESG2 | grep "eth0" | grep "$LINKUP_STR"`
			[ -n "${LinkDmesg}" ] && link_ready=1
			sleep 1
		done

		rm /tmp/DMESG
		rm /tmp/DMESG2
	fi
}

chk_speed(){
	case "$MODEL" in
	N2520|N2560|N4520|N4560)
		link_speed_check "link becomes ready"
		;;
	N2310|N4310)
		link_speed_check "link up"
		;;
	esac
}

dev_attach(){
	case "$MODEL" in
	N2310|N4310)
		# attach mtd8 as ubifs device
		ubiattach /dev/ubi_ctrl -m 8
		;;
	esac
}

main(){
	case "$OPT" in
	mcu)
		mcu_ready
		;;
	phy)
		set_phy $CMDS
		;;
	link)
		chk_speed
		;;
	dev)
		dev_attach
		;;
	esac
}

init_env $@
main
