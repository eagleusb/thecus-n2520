#!/bin/sh
#
# check rootfs RAID
# check_rootfs.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /img/bin/diagnostics/functions
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
	local _ret=1

	/sbin/blockdev --setra 4096 $mddisk

	diag_log "Mount runtime system..."
	echo "mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT" > ${diag_mpath}/${back_dir}/mount_rootfs.txt
	mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT >> ${diag_mpath}/${back_dir}/mount_rootfs.txt 2>&1
	_ret=$?
	if [ $_ret -ne 0 ];then
		diag_log "Mount runtime system failed, try to file system check..."
		echo "/sbin/fsck.ext4 -p -C0 $mddisk" > ${diag_mpath}/${back_dir}/fsck.txt
		/sbin/fsck.ext4 -p -C0 $mddisk >> ${diag_mpath}/${back_dir}/fsck.txt 2>&1

		diag_log "File system check finished, try to mount it again..."
		echo "mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT" >> ${diag_mpath}/${back_dir}/mount_rootfs.txt
		mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $mddisk $NEWROOT >> ${diag_mpath}/${back_dir}/mount_rootfs.txt 2>&1
		_ret=$?
		if [ $_ret -ne 0 ]; then
			#abnormal raid... stop all raid and remove folder
			diag_log "Mount runtime system still failed"
			stop_raid md${rootfs_mdnum}
		else
			diag_log "Mount runtime system OK"
		fi
	else
		diag_log "Mount runtime system OK"
	fi

	return $_ret
}

## call to check whether inactive, active will echo ""
check_inactive() {
	cat /proc/mdstat | grep "md${rootfs_mdnum} " | grep "inactive"
}

## final run mdadm command to combine disks to raid
final_run_mdadm() {
	if [ ! -e "$mddisk" ];then
		mknod $mddisk b 9 ${rootfs_mdnum}
	fi

	if [ `cat /proc/mdstat | grep "^md${rootfs_mdnum} " | wc -l` -eq 0 ]; then
		diag_log "Assemble runtime system..."
		if [ ${force_assemble} -eq 1 ];then
			echo "${mdadm} -A -R -f $mddisk ${mdadm_targets}" > ${diag_mpath}/${back_dir}/assemble_rootfs.txt
			${mdadm} -A -R -f $mddisk ${mdadm_targets} >> ${diag_mpath}/${back_dir}/assemble_rootfs.txt 2>&1
		else
			echo "${mdadm} -A -R $mddisk ${mdadm_targets}" > ${diag_mpath}/${back_dir}/assemble_rootfs.txt
			${mdadm} -A -R $mddisk ${mdadm_targets} >> ${diag_mpath}/${back_dir}/assemble_rootfs.txt 2>&1
		fi
		if [ "$?" != "0" ];then
			diag_log "Assemble runtime system failed"
			stop_raid md${rootfs_mdnum}
			return 1
		else
			diag_log "Assemble runtime system OK"
		fi
	fi
	
	local building=`cat /proc/mdstat|sed -n "/^md${rootfs_mdnum} /p"|grep "recovery\|resync\|reshape" |cut -d"]" -f2|cut -d"=" -f1`
	if [ -n "$building" ]; then
		post_mount
	else
		local active="$(check_inactive)"
		if [ "${active}" = "" ]; then ##active
			post_mount
		else
			#abnormal raid... stop all raid and remove folder
			diag_log "Runtime system is inactive"
			stop_raid md${rootfs_mdnum}
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
echo "# Assemble runtime system RAID"
echo "###############################"
mdadm_targets=""
decorate_devices
check_force_assemble $mdadm_targets
force_assemble=$?
final_run_mdadm

