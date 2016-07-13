#!/bin/sh
#
# check sys RAID
# check_sys.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /img/bin/diagnostics/functions
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
	/sbin/blockdev --setra 4096 $mddisk

	diag_log "Mount sys..."
	echo "mount -t ext4 $mddisk $NEWROOT/raidsys/0" > ${diag_mpath}/${back_dir}/mount_sys.txt
	mount -t ext4 $mddisk $NEWROOT/raidsys/0 >> ${diag_mpath}/${back_dir}/mount_sys.txt 2>&1
	if [ $? -eq 0 ]; then
		diag_log "Mount sys OK"
	else
		diag_log "mount sys failed, try to file system check..."
		echo "/sbin/fsck.ext4 -p -C0 $mddisk" >> ${diag_mpath}/${back_dir}/mount_sys.txt
		/sbin/fsck.ext4 -p -C0 $mddisk >> ${diag_mpath}/${back_dir}/mount_sys.txt 2>&1

		diag_log "File system check finished, try to mount it again..."
		mount -t ext4 $mddisk $NEWROOT/raidsys/0 >> ${diag_mpath}/${back_dir}/mount_sys.txt 2>&1
		_ret=$?
		if [ $_ret -ne 0 ]; then
			#abnormal raid... stop raid
			diag_log "Mount sys still failed"
			stop_raid md${sys_mdnum}
		else
			diag_log "Mount sys OK"
		fi
	fi
}

## call to check whether inactive, active will echo ""
check_inactive() {
	cat /proc/mdstat | grep "md${sys_mdnum} " | grep "inactive"
}

## final run mdadm command to combine disks to raid
final_run_mdadm() {
	if [ ! -e "$mddisk" ];then
		mknod $mddisk b 9 ${sys_mdnum}
	fi

	if [ `cat /proc/mdstat | grep "^md${sys_mdnum} " | wc -l` -eq 0 ]; then
		diag_log "Assemble sys..."
		if [ ${force_assemble} -eq 1 ];then
			echo "${mdadm} -A -R -f $mddisk ${mdadm_targets}" > ${diag_mpath}/${back_dir}/assemble_sys.txt
			${mdadm} -A -R -f $mddisk ${mdadm_targets} >> ${diag_mpath}/${back_dir}/assemble_sys.txt 2>&1
		else
			echo "${mdadm} -A -R $mddisk ${mdadm_targets}" > ${diag_mpath}/${back_dir}/assemble_sys.txt
			${mdadm} -A -R $mddisk ${mdadm_targets} >> ${diag_mpath}/${back_dir}/assemble_sys.txt 2>&1
		fi
		if [ "$?" != "0" ];then
			diag_log "Assemble sys failed"
			stop_raid md${sys_mdnum}
			return 1
		else
			diag_log "Assemble sys OK"
		fi
	fi
	
	local building=`cat /proc/mdstat|sed -n "/^md${sys_mdnum} /p"|grep "recovery\|resync\|reshape" |cut -d"]" -f2|cut -d"=" -f1`
	if [ -n "$building" ]; then
		post_mount
	else
		local active="$(check_inactive)"
		if [ "${active}" = "" ]; then ##active
			post_mount
		else
			#abnormal raid... stop all raid and remove folder
			diag_log "Sys is inactive"
			stop_raid md${sys_mdnum}
		fi
	fi

	return 1
}

##################################################################
#
#  Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Assemble sys RAID"
echo "###############################"
mdadm_targets=""
decorate_devices
check_force_assemble $mdadm_targets
force_assemble=$?
final_run_mdadm
