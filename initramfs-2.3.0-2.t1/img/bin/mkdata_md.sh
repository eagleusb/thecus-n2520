#!/bin/sh
#
# create data RAID
# mkdata_md.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /lib/library
devices="$1"
mddisk="/dev/md${data_mdnum}"

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
		mdadm_targets=${mdadm_targets}"/dev/${i}${data_partnum} "
		j=$(($j+1))
	done

	return $j
}

## mount raid action
post_mount() {
	echo "mount data RAID..."
	logger "Mount Data ... Start"
	check_debug_flag 36
	DEBUG_FLAG="$?"

	/sbin/blockdev --setra 4096 $mddisk

	# create raid path
	[ -d $NEWROOT/raid0 ] || mkdir -p $NEWROOT/raid0
		ln -fs /raid0/data $NEWROOT/raid

	# mount data RAID 
	mount -t ext4 -o acl $mddisk $NEWROOT/raid0 2>> $LOG_FILE

	_ret=$?
	if [ $_ret -ne 0 ]; then
		#abnormal raid... stop raid
		stop_raid md${data_mdnum}
	fi

	return $_ret
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Create data RAID"
echo "###############################"
logger "Make Data RAID ... Start"
check_debug_flag 34
DEBUG_FLAG="$?"

# create RAID
if [ ! -e "$mddisk" ];then
	mknod $mddisk b 9 ${data_mdnum}
fi
mdadm_targets=""
decorate_devices
raid_dev_num=$?
if [ $raid_dev_num -eq 1 ]; then
	# if one disk, create data as JBOD
	echo "create JBOD for data partition..."
	logger "Make Data RAID ... Level = JBOD"
	${mdadm} --create $mddisk --force --level=linear --raid-devices=${raid_dev_num} $mdadm_targets --run 2>> $LOG_FILE
elif [ $raid_dev_num -eq 2 ]; then
	# if two disks, create data as RAID1
	echo "create RAID1 for data partition..."
	logger "Make Data RAID ... Level = 1"
	${mdadm} --create $mddisk --assume-clean --force --level=1 --raid-devices=${raid_dev_num} $mdadm_targets --run 2>> $LOG_FILE
else
	# if more than three disks, create data as RAID5
	echo "create RAID5 for data partition..."
	logger "Make Data RAID ... Level = 5"
	${mdadm} --create $mddisk --assume-clean --force --level=5 --raid-devices=${raid_dev_num} $mdadm_targets --run 2>> $LOG_FILE
fi

if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Data RAID ... Fail"
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
	logger "Make Data RAID ... Pass"
fi

# make file system
echo "make file system for data partition..."
logger "Make Data FileSystem ... Start"
check_debug_flag 35
DEBUG_FLAG="$?"

sleep 1
${mkext4} ${mkext4_option} $mddisk 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Data FileSystem ... Fail"
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
	logger "Make Data FileSystem ... Pass"
fi

# mount
post_mount

# create folder
if [ $? -eq 0 -a "$DEBUG_FLAG" == "0" ]; then
	logger "Mount Data ... Pass"
	/img/bin/create_folder.sh
else
	logger "Mount Data ... Fail"
	echo "create default folder fail, cannot mount $mddisk"
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
