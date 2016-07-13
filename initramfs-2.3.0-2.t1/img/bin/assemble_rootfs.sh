#!/bin/sh
#
# assemble rootfs RAID
# assemble_rootfs.sh "devices"
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
	local j=0

	for i in ${devices}
	do
		mdadm_targets=${mdadm_targets}"/dev/${i}${rootfs_partnum} "
		j=$(($j+1))
	done

	return $j
}

## do post mount raid action
post_mount() {
	logger "Post Mount ... Start"
	check_debug_flag 43
	DEBUG_FLAG="$?"

	local _ret=1

	echo "try to mount runtime system..."

	/sbin/blockdev --setra 4096 $mddisk

	mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT 2>> $LOG_FILE

	_ret=$?

	if [ ${_ret} -eq 0 -a "$DEBUG_FLAG" == "0" ];then
		logger "Post Mount ... Pass"
	else
		logger "Post Mount ... Fail"
		#auto fsck and remount
		umount $mddisk
		echo "mount runtime system fail, try to file system check $mddisk..."
		logger "Check FileSystem ... Start"
		/img/bin/pic.sh LCM_MSG "Filesystem" "Check"
		echo "[FSCK]" > /tmp/mnid.agent.in
		/sbin/fsck.ext4 -p -C0 $mddisk
		logger "Check FileSystem ... End"
		echo "file system check finished, try to mount it again..."
		logger "Re-Post Mount ... Start"
		mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT 2>> $LOG_FILE
		_ret=$?

		if [ ${_ret} -eq 0 -a "$DEBUG_FLAG" == "0" ];then
			logger "Re-Post Mount ... Pass"
		else
			logger "Re-Post Mount ... Fail"
			#abnormal raid... stop all raid and remove folder
			stop_raid md${rootfs_mdnum}
			if [ $TDB -ne 1 ]; then
				/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
				echo "[ASSIST][RAID_REMOUNT_FAIL][SHUTDOWN,RE_INSTALL][SHUTDOWN]" > /tmp/mnid.agent.in
				while [ 1 ];do
					read line < /tmp/mnid.agent.out
					if [ "$line" = "[RE_INSTALL]" -o "$line" = "[CONTINUE]" ]; then
						sh /img/bin/init_install.sh "$devices"	$devs_num
						break
					elif [ "$line" = "[SHUTDOWN]" ]; then
						handle_critical_error
						break
					fi
				done
			fi
		fi
	fi	
	return $_ret
}

## call to check whether inactive, active will echo ""
check_inactive() {
	cat /proc/mdstat | grep "md${rootfs_mdnum} " | grep "inactive"
}

## final run mdadm command to combine disks to raid
final_run_mdadm() {
	logger "Final Run Mdadm ... Start"
	check_debug_flag 42
	DEBUG_FLAG="$?"

	local _ret=1
	if [ ! -e "$mddisk" ];then
		mknod $mddisk b 9 ${rootfs_mdnum}
	fi

	echo "Assemble RAID..."
	if [ ${force_assemble} -eq 1 ];then
		logger "Final Run Mdadm ... Force Assemble First"
		${mdadm} -A -R -f $mddisk ${mdadm_targets} 2>> $LOG_FILE
	else
		logger "Final Run Mdadm ... Normal Assemble"
		${mdadm} -A -R $mddisk ${mdadm_targets} 2>> $LOG_FILE
	fi
	
	_ret=$?
	if [ $_ret -eq 0 -a "$DEBUG_FLAG" == "0" ]; then
		logger "Final Run Mdadm ... Force Assemble First Pass"
		logger "Final Run Mdadm ... Pass"
	else
		#auto re assemble
		${mdadm} -S $mddisk
		logger "Final Run Mdadm ... Force Assemble First Fail"
		logger "Final Run Mdadm ... Force Assemble Again"
		${mdadm} -A -R -f $mddisk ${mdadm_targets} 2>> $LOG_FILE
		
		_ret=$?
	
		if [ $_ret -eq 0 -a "$DEBUG_FLAG" == "0" ]; then
			logger "Final Run Mdadm ... Force Assemble Again Pass"
			logger "Final Run Mdadm ... Pass"

		else
			#abort assemble rootfs, ask user to re-install it or not
			logger "Final Run Mdadm ... Force Assemble Again Fail"
			${mdadm} -S $mddisk
			if [ $TDB -ne 1 ]; then
				/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
				echo "[ASSIST][RAID_REASSEMBLE_FAIL][SHUTDOWN,RE_INSTALL][SHUTDOWN]" > /tmp/mnid.agent.in
				logger "Ask User for the Next Action ..."
				while [ 1 ];do
					read line < /tmp/mnid.agent.out
					if [ "$line" = "[RE_INSTALL]" -o "$line" = "[CONTINUE]" ]; then
						logger "[User]: I want to install ..."
						sh /img/bin/init_install.sh "$devices"	$devs_num
						break
					elif [ "$line" = "[SHUTDOWN]" ]; then
						logger "[User]: I want to shutdown ..."
						handle_critical_error
						break
					fi
				done
			fi
			return 1
		fi 
	fi

	#check if raid is inactive
	logger "Check RAID Is Active ... Start"
	check_debug_flag 45
	DEBUG_FLAG="$?"

	local active="$(check_inactive)"
	if [ "${active}" = "" -a "$DEBUG_FLAG" == "0" ]; then
		logger "Check RAID Is Active ... Pass"
		post_mount
	else
		#inactive raid... stop all raid and remove folder
		logger "Check RAID Is Active ... Fail"
		${mdadm} -S $mddisk
		if [ $TDB -ne 1 ]; then
			/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
			echo "[ASSIST][RAID_INACTIVE][SHUTDOWN,RE_INSTALL][SHUTDOWN]" > /tmp/mnid.agent.in
			while [ 1 ];do
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[RE_INSTALL]" -o "$line" = "[CONTINUE]" ]; then
					sh /img/bin/init_install.sh "$devices"	$devs_num
					break
				elif [ "$line" = "[SHUTDOWN]" ]; then
					handle_critical_error
					break
				fi
			done
		fi
	fi

	return 1
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Assemble runtime system RAID"
echo "###############################"
logger "Assemble Rootfs RAID ... Start"

if [ "$devices" = "" ]; then
	devs_num=0
	get_plugged_devices
fi

mdadm_targets=""
decorate_devices
check_force_assemble $mdadm_targets
force_assemble=$?
final_run_mdadm

logger "Assemble Rootfs RAID ... End"
