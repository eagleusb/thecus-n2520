#!/bin/sh
#
# check swap RAID
# check_swap.sh "devices"
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /img/bin/diagnostics/functions
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
		diag_log "Swap on"
	else
		diag_log "Swap on failed"
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
		diag_log "Assemble swap..."
		if [ ${force_assemble} -eq 1 ];then
			echo "${mdadm} -A -R -f $mddisk ${mdadm_targets}" > ${diag_mpath}/${back_dir}/assemble_swap.txt
			${mdadm} -A -R -f $mddisk ${mdadm_targets} >> ${diag_mpath}/${back_dir}/assemble_swap.txt 2>&1
		else
			echo "${mdadm} -A -R $mddisk ${mdadm_targets}" > ${diag_mpath}/${back_dir}/assemble_swap.txt
			${mdadm} -A -R $mddisk ${mdadm_targets} >> ${diag_mpath}/${back_dir}/assemble_swap.txt 2>&1
		fi
		if [ "$?" != "0" ];then
			diag_log "Assemble swap failed" 
			stop_raid md${swap_mdnum}
			return 1
		else
			diag_log "Assemble swap OK"
		fi
	fi
	
	local building=`cat /proc/mdstat|sed -n "/^md${swap_mdnum} /p"|grep "recovery\|resync\|reshape" |cut -d"]" -f2|cut -d"=" -f1`
	if [ -n "$building" ]; then
		swap_on
	else
		local active="$(check_inactive)"
		if [ "${active}" = "" ]; then ##active
			swap_on
		else
			#abnormal raid... stop all raid and remove folder
			diag_log "Swap is inactive"
			stop_raid md${swap_mdnum}
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
echo "# Assemble swap RAID"
echo "###############################"
mdadm_targets=""
decorate_devices
check_force_assemble $mdadm_targets
force_assemble=$?
final_run_mdadm
