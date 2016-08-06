#!/bin/sh
#
# create swap RAID
# mkswap_md.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /lib/library
devices="$1"
mddisk="/dev/md${swap_mdnum}"

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################
## call to decorate devices string for use
decorate_devices() {
	j=0

	for i in ${devices}
	do
		mdadm_targets=${mdadm_targets}"/dev/${i}${swap_partnum} "
		j=$(($j+1))
	done

	return $j
}

## swapon action
swap_on() {
	echo "swap on..."
	logger "Swap On ... Start"
	check_debug_flag 27
	DEBUG_FLAG="$?"

	/sbin/blockdev --setra 4096 $mddisk

	swapon $mddisk 2>> $LOG_FILE
	if [ $? -eq 0 -a "$DEBUG_FLAG" == "0" ]; then
		echo "swap on OK"
		logger "Swap On ... Pass"
	else
		echo "swap on failed"
		logger "Swap On ... Fail"
		stop_raid md${swap_mdnum}
		/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
		if [ $TDB -ne 1 ]; then
			echo "[ASSIST][RAID_CREATE_FAIL][BLANK][BLANK]" > /tmp/mnid.agent.in
			while [ 1 ];do
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[BLANK]" ]; then
					handle_critical_error
					break
				fi
			done
		fi
	fi
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Create swap RAID"
echo "###############################"
logger "Make Swap RAID ... Start"
check_debug_flag 25
DEBUG_FLAG="$?"

# create RAID
if [ ! -e "$mddisk" ];then
	mknod $mddisk b 9 ${swap_mdnum}
fi
mdadm_targets=""
decorate_devices
raid_dev_num=$?
total_tray=`cat /proc/thecus_io | grep MAX_TRAY | awk '{print $2}'`
while [ $raid_dev_num -le $((${total_tray}-1)) ];do
	mdadm_targets="$mdadm_targets missing"
	raid_dev_num=$(($raid_dev_num+1))
done
echo "create RAID1 for swap partition..."
${mdadm} --create $mddisk --assume-clean --force --level=1 --raid-devices=${raid_dev_num} $mdadm_targets --run 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Swap RAID ... Fail"
	for i in "$mdadm_targets"
	do
		logger "[Info]: mdadm --examine $i " "$(mdadm --examine $i)"
	done
	/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
	if [ $TDB -ne 1 ]; then
		echo "[ASSIST][RAID_CREATE_FAIL][BLANK][BLANK]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[BLANK]" ]; then
				handle_critical_error
				break
			fi
		done
	fi
else
	logger "Make Swap RAID ... Pass"
fi

# make file system
echo "make swap..."
logger "Make Swap FileSystem ... Start"
check_debug_flag 26
DEBUG_FLAG="$?"

${mkswap} $mddisk 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Swap FileSystem ... Fail"
	/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
	if [ $TDB -ne 1 ]; then
		echo "[ASSIST][RAID_MAKEFS_FAIL][BLANK][BLANK]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[BLANK]" ]; then
				handle_critical_error
				break
			fi
		done
	fi
else
	logger "Make Swap FileSystem ... Pass"
fi

# swap on 
swap_on

sync
