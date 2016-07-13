#!/bin/sh
#
# assemble swap RAID
# assemble_swap.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
devices="$1"
mddisk="/dev/md${swap_mdnum}"

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
		mdadm_targets=${mdadm_targets}"/dev/${i}${swap_partnum} "
		j=$(($j+1))
	done

	return $j
}

## swap on action
swap_on() {
	/sbin/blockdev --setra 4096 $mddisk
	swapon $mddisk
	if [ $? -eq 0 ]; then
		echo "swapon OK"
	else
		echo "swapon failed"
		stop_raid md${swap_mdnum}
	fi
}

## call to check whether inactive, active will echo ""
check_inactive() {
	cat /proc/mdstat | grep "md${swap_mdnum} " | grep "inactive"
}

## final run mdadm command to combine disks to raid
final_run_mdadm() {
	if [ ! -e "$mddisk" ];then
		mknod $mddisk b 9 ${swap_mdnum}
	fi

	if [ `cat /proc/mdstat | grep "^md${swap_mdnum} " | wc -l` -eq 0 ]; then
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
			stop_raid md${swap_mdnum}
			return 1
		fi
	fi
	
	local building=`cat /proc/mdstat|sed -n "/^md${swap_mdnum} /p"|grep "recovery\|resync\|reshape" |cut -d"]" -f2|cut -d"=" -f1`
	if [ -n "$building" ]; then
		echo "building"
		swap_on
	else
		echo "Check RAID Status"
		local active="$(check_inactive)"
		if [ "${active}" = "" ]; then ##active
			swap_on
		else
			#abnormal raid... stop all raid and remove folder
			stop_raid md${swap_mdnum}
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
echo "# Assemble swap RAID"
echo "###############################"
mdadm_targets=""
decorate_devices
check_force_assemble $mdadm_targets
force_assemble=$?
final_run_mdadm
