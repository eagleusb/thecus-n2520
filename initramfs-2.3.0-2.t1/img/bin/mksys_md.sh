#!/bin/sh
#
# create sys RAID
# mksys_md.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /lib/library
devices="$1"
mddisk="/dev/md${sys_mdnum}"

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################
## call to decorate devices string for use
decorate_devices() {
	local j=0

	for i in ${devices}
	do
		mdadm_targets=${mdadm_targets}"/dev/${i}${sys_partnum} "
		j=$(($j+1))
	done

	return $j
}

## mount raid action
post_mount() {
	echo "will mount sys RAID in rootfs..."
	logger "Mount Sys ... Start"
	check_debug_flag 33
	DEBUG_FLAG="$?"

	/sbin/blockdev --setra 4096 $mddisk

	# create raid path
	[ -d $NEWROOT/raidsys/0 ] || mkdir -p $NEWROOT/raidsys/0

	# mount sys RAID
	mount -t ext4 $mddisk $NEWROOT/raidsys/0 2>> $LOG_FILE

	_ret=$?
	if [ $_ret -ne 0 ]; then
		#abnormal raid... stop raid
		stop_raid md${sys_mdnum}
	fi

	return $_ret
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Create sys RAID"
echo "###############################"
logger "Make Sys RAID ... Start"
check_debug_flag 31
DEBUG_FLAG="$?"

# create RAID
if [ ! -e "$mddisk" ];then
	mknod $mddisk b 9 ${sys_mdnum}
fi
mdadm_targets=""
decorate_devices
raid_dev_num=$?
total_tray=`cat /proc/thecus_io | grep MAX_TRAY | awk '{print $2}'`
while [ $raid_dev_num -le $((${total_tray}-1)) ];do
	mdadm_targets="$mdadm_targets missing"
	raid_dev_num=$(($raid_dev_num+1))
done
echo "create RAID1 for sys partition..."
${mdadm} --create $mddisk --force --level=1 --raid-devices=${raid_dev_num} $mdadm_targets --run 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Sys RAID ... Fail"
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
	logger "Make Sys RAID ... Pass"
fi

# make file system
echo "make file system for sys partition..."
logger "Make Sys FileSystem ... Start"
check_debug_flag 32
DEBUG_FLAG="$?"

${mkext4} ${mkext4_option} $mddisk 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Sys FileSystem ... Fail"
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
	logger "Make Sys FileSystem ... Pass"
fi

# mount
post_mount

# smbdb.sh
if [ $? -eq 0 -a "$DEBUG_FLAG" == "0" ]; then
	logger "Mount Sys ... Pass"
	/img/bin/smbdb.sh raidDefault
else
	logger "Mount Sys ... Fail"
	echo "generate default fail, cannot mount $mddisk"
	/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
	if [ $TDB -ne 1 ]; then
		echo "[ASSIST][RAID_INIT_MOUNT_FAIL][BLANK][BLANK]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[BLANK]" ]; then
				handle_critical_error
				break
			fi
		done
	fi
fi

sync
