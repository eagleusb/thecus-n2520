#!/bin/sh
#
# check_Storage.sh "devices" devices_num
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /img/bin/diagnostics/functions
devices="$1"
devs_num=$2

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################

##################################################################
#
#  Finally, exec main code
#
##################################################################

if [ $devs_num -eq 1 ]; then
	# one disk
	# check rootfs
	echo "${mdadm} --examine /dev/${devices}${rootfs_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_rootfs.txt
	${mdadm} --examine /dev/${devices}${rootfs_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_rootfs.txt 2>&1
	uuid=`get_uuid $devices ${rootfs_partnum}`
	if [ "$uuid" != "" ]; then
		echo "$uuid" | grep "^raid1;"
		if [ $? -eq 0 ]; then	# runtime system is RAID1
			sh ${diag_work}/check_rootfs.sh "$devices"
		else
			diag_log "Runtime system partition is not RAID1"
		fi
	else
		diag_log "Cannot get runtime system UUID"
	fi

	# check data
	echo "${mdadm} --examine /dev/${devices}${data_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_data.txt
	${mdadm} --examine /dev/${devices}${data_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_data.txt 2>&1
	uuid=`get_uuid $devices ${data_partnum}`
	if [ "$uuid" != "" ]; then  # data is a RAID
		sh ${diag_work}/check_data.sh "$devices"
	else
		diag_log "Cannot get data UUID"
	fi

	# check sys
	echo "${mdadm} --examine /dev/${devices}${sys_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_sys.txt
	${mdadm} --examine /dev/${devices}${sys_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_sys.txt 2>&1
	uuid=`get_uuid $devices ${sys_partnum}`
	if [ "$uuid" != "" ]; then
		echo "$uuid" | grep "^raid1;"
		if [ $? -eq 0 ]; then	# sys is RAID1
			sh ${diag_work}/check_sys.sh "$devices"
		else
			diag_log "Sys partition is not RAID1"
		fi
	else
		diag_log "Cannot get sys UUID"
	fi

	# check swap
	echo "${mdadm} --examine /dev/${devices}${swap_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_swap.txt
	${mdadm} --examine /dev/${devices}${swap_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_swap.txt 2>&1
	uuid=`get_uuid $devices ${swap_partnum}`
	if [ "$uuid" != "" ]; then
		echo "$uuid" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # swap is RAID1
			sh ${diag_work}/check_swap.sh "$devices"
		else	# swap is not RAID1
			diag_log "Swap partition is not RAID1"
		fi
	else
		# swap is no RAID
		diag_log "Swap partition is not a RAID"
	fi

else
	# two disk
	j=1
	for i in ${devices}
	do
		devs[$j]="$i"
		j=$(($j+1))
	done

	# check rootfs
	echo "${mdadm} --examine /dev/${devs[1]}${rootfs_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_rootfs.txt
	${mdadm} --examine /dev/${devs[1]}${rootfs_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_rootfs.txt 2>&1
	echo "${mdadm} --examine /dev/${devs[2]}${rootfs_partnum}" >> ${diag_mpath}/${back_dir}/mdadm_examine_rootfs.txt
	${mdadm} --examine /dev/${devs[2]}${rootfs_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_rootfs.txt 2>&1
	a_is_raid1=0
	b_is_raid1=0
	a_uuid=`get_uuid ${devs[1]} ${rootfs_partnum}`
	if [ "${a_uuid}" != "" ]; then
		echo "${a_uuid}" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # sda runtime system is RAID1
			a_is_raid1=1
		fi
	fi
	b_uuid=`get_uuid ${devs[2]} ${rootfs_partnum}`
	if [ "${b_uuid}" != "" ]; then
		echo "${b_uuid}" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # sdb runtime system is RAID1
			b_is_raid1=1
		fi
	fi
	if [ ${a_is_raid1} -eq 1 ]; then
		if [ ${b_is_raid1} -eq 1 ] && [ "${a_uuid}" = "${b_uuid}" ]; then
			# assemble sda & sdb
            		sh ${diag_work}/check_rootfs.sh "${devs[1]} ${devs[2]}"
		else
			# assemble sda
			sh ${diag_work}/check_rootfs.sh "${devs[1]}"
		fi
	elif [ ${b_is_raid1} -eq 1 ]; then
		# assemble sdb
		sh ${diag_work}/check_rootfs.sh "${devs[2]}"
		# if sda runtime system is not RAID1 but sdb is, 
		# it means sda is not used in our NAS and sdb is used in our NAS, 
		# so we need set sdb to first condition, sda is second.
		dev_tmp=${devs[1]}
		devs[1]="${devs[2]}"
		devs[2]="${dev_tmp}"
	else
		diag_log "Runtime system partition is not RAID1"
	fi

	# check data
	echo "${mdadm} --examine /dev/${devs[1]}${data_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_data.txt
	${mdadm} --examine /dev/${devs[1]}${data_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_data.txt 2>&1
	echo "${mdadm} --examine /dev/${devs[2]}${data_partnum}" >> ${diag_mpath}/${back_dir}/mdadm_examine_data.txt
	${mdadm} --examine /dev/${devs[2]}${data_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_data.txt 2>&1
	a_is_raid=0
	b_is_raid=0
	a_uuid=`get_uuid ${devs[1]} ${data_partnum}`
	if [ "${a_uuid}" != "" ]; then	# sda data is a RAID
		a_is_raid=1
	fi
	b_uuid=`get_uuid ${devs[2]} ${data_partnum}`
	if [ "${b_uuid}" != "" ]; then	# sdb data is a RAID
		b_is_raid=1
	fi
	if [ "${a_is_raid}" -eq 1 ]; then
		if [ ${b_is_raid} -eq 1 ] && [ "${a_uuid}" = "${b_uuid}" ]; then
			# assemble sda & sdb
	        	sh ${diag_work}/check_data.sh "${devs[1]} ${devs[2]}"
		else
			# assemble sda
	        	sh ${diag_work}/check_data.sh "${devs[1]}"
		fi
	elif [ "${b_is_raid}" -eq 1 ]; then
		# assemble sdb
		sh ${diag_work}/check_data.sh "${devs[2]}"
	else
		diag_log "Data partition is not a RAID"
	fi

	# check sys
	echo "${mdadm} --examine /dev/${devs[1]}${sys_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_sys.txt
	${mdadm} --examine /dev/${devs[1]}${sys_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_sys.txt 2>&1
	echo "${mdadm} --examine /dev/${devs[2]}${sys_partnum}" >> ${diag_mpath}/${back_dir}/mdadm_examine_sys.txt
	${mdadm} --examine /dev/${devs[2]}${sys_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_sys.txt 2>&1
	a_is_raid1=0
	b_is_raid1=0
	a_uuid=`get_uuid ${devs[1]} ${sys_partnum}`
	if [ "${a_uuid}" != "" ]; then
		echo "${a_uuid}" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # sda sys is RAID1
			a_is_raid1=1
		fi
	fi
	b_uuid=`get_uuid ${devs[2]} ${sys_partnum}`
	if [ "${b_uuid}" != "" ]; then
		echo "${b_uuid}" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # sdb sys is RAID1
			b_is_raid1=1
		fi
	fi
	if [ ${a_is_raid1} -eq 1 ]; then
		if [ ${b_is_raid1} -eq 1 ] && [ "${a_uuid}" = "${b_uuid}" ]; then
			# assemble sda & sdb
			sh ${diag_work}/check_sys.sh "${devs[1]} ${devs[2]}"
		else
			# assemble sda
			sh ${diag_work}/check_sys.sh "${devs[1]}"
		fi
	elif [ ${b_is_raid1} -eq 1 ]; then
		# assemble sdb
		sh ${diag_work}/check_sys.sh "${devs[2]}"
	else
		diag_log "Sys partition is not RAID1"
	fi

	# check swap
	echo "${mdadm} --examine /dev/${devs[1]}${swap_partnum}" > ${diag_mpath}/${back_dir}/mdadm_examine_swap.txt
	${mdadm} --examine /dev/${devs[1]}${swap_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_swap.txt 2>&1
	echo "${mdadm} --examine /dev/${devs[2]}${swap_partnum}" >> ${diag_mpath}/${back_dir}/mdadm_examine_swap.txt
	${mdadm} --examine /dev/${devs[2]}${swap_partnum} >> ${diag_mpath}/${back_dir}/mdadm_examine_swap.txt 2>&1
	a_is_raid1=0
	b_is_raid1=0
	a_uuid=`get_uuid ${devs[1]} ${swap_partnum}`
	if [ "${a_uuid}" != "" ]; then
		echo "${a_uuid}" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # sda swap is RAID1
			a_is_raid1=1
		fi
	fi
	b_uuid=`get_uuid ${devs[2]} ${swap_partnum}`
	if [ "${b_uuid}" != "" ]; then
		echo "${b_uuid}" | grep "^raid1;"
		if [ $? -eq 0 ]; then   # sdb swap is RAID1
			b_is_raid1=1
		fi
	fi
	if [ ${a_is_raid1} -eq 1 ]; then
		if [ ${b_is_raid1} -eq 1 ] && [ "${a_uuid}" = "${b_uuid}" ]; then
			# assemble sda & sdb
			sh ${diag_work}/check_swap.sh "${devs[1]} ${devs[2]}"
		else
			# assemble sda
			sh ${diag_work}/check_swap.sh "${devs[1]}"
		fi
	elif [ ${b_is_raid1} -eq 1 ]; then
		# assemble sdb
		sh ${diag_work}/check_swap.sh "${devs[2]}"
	else
		diag_log "Swap partition is not RAID1"
	fi
fi

cat /proc/mdstat > ${diag_mpath}/${back_dir}/mdstat.txt
