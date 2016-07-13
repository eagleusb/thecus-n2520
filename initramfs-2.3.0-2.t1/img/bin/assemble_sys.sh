#!/bin/sh
#
# assemble sys RAID
# assemble_sys.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
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

	mount -t ext4 $mddisk $NEWROOT/raidsys/0
	if [ $? -eq 0 ]; then
		echo "mount sys OK"
	else
		echo "[ASSIST][RAID_MOUNT_FAIL][FSCK,SHUTDOWN][FSCK]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[FSCK]" ]; then
				echo "mount sys fail, try to file system check $mddisk..."
				/img/bin/pic.sh LCM_MSG "Filesystem" "Check"
				echo "[FSCK]" > /tmp/mnid.agent.in
				/sbin/fsck.ext4 -p -C0 $mddisk
				echo "file system check finished, try to mount it again..."
				mount -t ext4 $mddisk $NEWROOT/raidsys/0
				_ret=$?
				if [ $_ret -ne 0 ]; then
					#abnormal raid... stop all raid and remove folder
					stop_raid md${rootfs_mdnum}
					if [ $TDB -ne 1 ]; then
						echo "[ASSIST][RAID_REMOUNT_FAIL][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
						while [ 1 ];do
							read line < /tmp/mnid.agent.out
							if [ "$line" = "[SHUTDOWN]" ]; then
								/img/bin/pic.sh LCM_MSG "System" "Shutting down"
								echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
								poweroff -f
								break
							fi
						done
					fi
				fi
				break
			elif [ "$line" = "[SHUTDOWN]" ]; then
				/img/bin/pic.sh LCM_MSG "System" "Shutting down"
				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
				poweroff -f
				break
			fi
		done
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
		echo "Assemble RAID..."
		if [ ${force_assemble} -eq 1 ];then
			${mdadm} -A -R -f $mddisk ${mdadm_targets}
		else
			${mdadm} -A -R $mddisk ${mdadm_targets}
		fi
		if [ "$?" != "0" ];then
			echo "[ASSIST][RAID_ASSEMBLE_FAIL][REASSEMBLE,SHUTDOWN][REASSEMBLE]" > /tmp/mnid.agent.in
			while [ 1 ];do
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[REASSEMBLE]" ]; then
					${mdadm} -A -R -f $mddisk ${mdadm_targets}
					if [ "$?" != "0" ];then
						if [ $TDB -ne 1 ]; then
							echo "[ASSIST][RAID_REASSEMBLE_FAIL][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
							while [ 1 ];do
								read line < /tmp/mnid.agent.out
								if [ "$line" = "[SHUTDOWN]" ]; then
									/img/bin/pic.sh LCM_MSG "System" "Shutting down"
									echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
									poweroff -f
									break
								fi
							done
						fi
					fi
					break
				elif [ "$line" = "[SHUTDOWN]" ]; then
					/img/bin/pic.sh LCM_MSG "System" "Shutting down"
					echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
					poweroff -f
					break
				fi
			done
			stop_raid md${sys_mdnum}
			return 1
		fi
	fi
	
	local building=`cat /proc/mdstat|sed -n "/^md${sys_mdnum} /p"|grep "recovery\|resync\|reshape" |cut -d"]" -f2|cut -d"=" -f1`
	if [ -n "$building" ]; then
		echo "building"
		post_mount
	else
		echo "Check RAID Status"
		local active="$(check_inactive)"
		if [ "${active}" = "" ]; then ##active
			post_mount
		else
			#abnormal raid... stop all raid and remove folder
			stop_raid md${sys_mdnum}
			if [ $TDB -ne 1 ]; then
				echo "[ASSIST][RAID_INACTIVE][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
				while [ 1 ];do
					read line < /tmp/mnid.agent.out
					if [ "$line" = "[SHUTDOWN]" ]; then
						/img/bin/pic.sh LCM_MSG "System" "Shutting down"
						echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
						poweroff -f
						break
					fi
				done
			fi
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
echo "# Assemble sys RAID"
echo "###############################"
mdadm_targets=""
decorate_devices
check_force_assemble $mdadm_targets
force_assemble=$?
final_run_mdadm
