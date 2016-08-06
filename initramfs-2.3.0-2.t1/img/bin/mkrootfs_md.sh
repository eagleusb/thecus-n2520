#!/bin/sh
#
# create rootfs RAID, and rpm install, modify config
# mkrootfs_md.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /lib/library
devices="$1"
mddisk="/dev/md${rootfs_mdnum}"
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
		mdadm_targets=${mdadm_targets}"/dev/${i}${rootfs_partnum} "
		j=$(($j+1))
	done

	return $j
}

## do post mount raid action
post_mount() {
	local _ret=1

	echo "try to mount runtime system..."
	logger "Mount Rootfs ... Start"
	check_debug_flag 30
	DEBUG_FLAG="$?"

	/sbin/blockdev --setra 4096 $mddisk

	mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT 2>> $LOG_FILE

	_ret=$?
	if [ $_ret -ne 0 ]; then
		#abnormal raid... stop all raid and remove folder
		stop_raid md${rootfs_mdnum}
	fi

	return $_ret
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Create runtime system RAID"
echo "###############################"
logger "Make Rootfs RAID ... Start"
check_debug_flag 28
DEBUG_FLAG="$?"

# create RAID
if [ ! -e "$mddisk" ];then
	mknod $mddisk b 9 ${rootfs_mdnum}
fi
mdadm_targets=""
decorate_devices
raid_dev_num=$?
total_tray=`cat /proc/thecus_io | grep MAX_TRAY | awk '{print $2}'`
while [ $raid_dev_num -le $((${total_tray}-1)) ];do
	mdadm_targets="$mdadm_targets missing"
	raid_dev_num=$(($raid_dev_num+1))
done
uuid=""
echo "create RAID1 for runtime system..."
${mdadm} --create $mddisk --force --level=1 --raid-devices=${raid_dev_num} $mdadm_targets --run 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Rootfs RAID ... Fail" 
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
	
	logger "Make Rootfs RAID ... Pass" 
	for _dev in $mdadm_targets
	do
		uuid=`${mdadm} --examine ${_dev} 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/UUID/ && UUID==""){UUID=$2}if($1~/Raid Level/){TYPE=$2}}END{if(TYPE!="" && UUID!="")print UUID}'`
		break
	done 
	sync
fi

# make file system
echo "make file system for runtime system..."
logger "Make Rootfs FileSystem ... Start" 
check_debug_flag 29
DEBUG_FLAG="$?"

${mkext4} ${mkext4_option} $mddisk 2>> $LOG_FILE
if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Make Rootfs FileSystem ... Fail" 
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
	logger "Make Rootfs FileSystem ... Pass" 
	sync
fi

# mount
post_mount

if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
	logger "Mount Rootfs ... Fail"
	echo "mount runtime system fail!"
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
	exit 1
else
	logger "Mount Rootfs ... Pass"
	# start install rootfs rpms
	/img/bin/rpm_install.sh "$uuid"
	RET=$?
	/img/bin/pic.sh LCM_MSG "RAID" "Initial"
	echo "[RAID_INITIAL]" > /tmp/mnid.agent.in

	exit $RET
fi
