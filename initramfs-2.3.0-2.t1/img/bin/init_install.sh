#!/bin/sh
#
# init_install.sh "devices" devices_num $auto_create
#
# Initial Installation Mode:
#	0. clean old info on disk
#	1. partition
#	2. create rootfs RAID, and yum install, modify config
#	3. create swap RAID
#	4. create sys RAID, and add UUID and smbdb file
#	5. create data RAID, and create folder
# then return to init to switch_root into rootfs
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /lib/library
devices="$1"
devs_num=$2
auto_create=$3

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################
# clean the partition and md info first
clean_disk() {
	logger "Clean Disk ... Start"
	logger "[Info]: cat /proc/scsi/scsi" "$(cat /proc/scsi/scsi)"
	check_debug_flag 21
	DEBUG_FLAG="$?"

	echo "clean the disk ..."
	local _pnum
	local _psize
	
	for i in ${devices}
	do
		_pnum=`${sgdisk} -p /dev/$i | grep "^  " | wc -l`
		j=1
		while [ $j -le ${_pnum} ] || [ $j -le 10 ]
		do
			${mdadm} --zero-superblock /dev/$i$j >/dev/null 2>/dev/null
			j=$(($j+1))
		done
		${mdadm} --zero-superblock /dev/$i >/dev/null 2>/dev/null
		${sgdisk} -oZ /dev/$i >/dev/null 2>> $LOG_FILE

		_pnum=`${sgdisk} -p /dev/$i | grep "^  " | wc -l`
		if [ ${_pnum} -ge 1 -o "$DEBUG_FLAG" == "1" ];then
			logger "Clean Disk ... Fail"
			#clean disk fail, try to dd disk
			echo "dd the disk $i ..."
			_psize=`cat /proc/partitions | grep ${i}$ | awk -F' ' '{print $3}'`
			_psize=$((${_psize}-100))
			logger "dd Disk ... Start"
			dd if=/dev/zero of=/dev/$i bs=1k count=100
			dd if=/dev/zero of=/dev/$i bs=1k count=100 seek=$_psize
			logger "dd Disk ... End"
			logger "Re-Clean Disk ... Start"
			${sgdisk} -oZ /dev/$i >/dev/null 2>> $LOG_FILE
			if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
				logger "Re-Clean Disk ... Fail"
				if [ $TDB -ne 1 ]; then
					/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
					echo "[ASSIST][CLEAN_DISK_FAIL][BLANK][BLANK]" > /tmp/mnid.agent.in
					while [ 1 ];do
						read line < /tmp/mnid.agent.out
						if [ "$line" = "[BLANK]" ]; then
							handle_critical_error
							break
						fi
					done
				fi
			else
				logger "Re-Clean Disk ... Pass"
			fi
			
		fi
	done
}

# create the partition 
partition() {
	logger "Create Partition ... Start"
	check_debug_flag 24
	DEBUG_FLAG="$?"

	echo "create partition ..."
	local _device
	
	for i in ${devices}
	do
		_device="/dev/${i}"
		for j in ${rootfs_partnum} ${reserve_partnum} ${swap_partnum} ${sys_partnum} ${data_partnum}	# 4 5 1 3 2
		do
			if [ $j -eq ${data_partnum} ]; then
				$sgdisk -N $j -t $j:FD00 $_device 2>> $LOG_FILE
				$sgdisk -c $j:THECUS $_device 2>> $LOG_FILE
			else
				$sgdisk -n $j:${pstart[$j]}:${pend[$j]}	-t $j:FD00 $_device 2>> $LOG_FILE
				if [ $j -eq ${rootfs_partnum} ]; then
					$sgdisk -c $j:`uname -m`-THECUS $_device 2>> $LOG_FILE
				fi
			fi
			if [ $? -ne 0 -o "$DEBUG_FLAG" == "1" ]; then
				logger "Create Partition $j ... Fail"
				if [ $TDB -ne 1 ]; then
					/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
					echo "[ASSIST][PARTITION_FAIL][BLANK][BLANK]" > /tmp/mnid.agent.in
					while [ 1 ];do
						read line < /tmp/mnid.agent.out
						if [ "$line" = "[BLANK]" ]; then
							handle_critical_error
							break
						fi
					done
				fi
			else
				logger "Create Partition ${_device}${j} ... Pass"
				${mdadm} --zero-superblock ${_device}${j}> /dev/null 2> /dev/null
			fi
		done
		# display the partition
		$sgdisk -p $_device
		logger "[Info]: sgdisk -p $_device" "$(sgdisk -p  $_device)" 
	done
	udevsettle
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Initial installation"
echo "###############################"
logger "Installation ... Start"
if [ "$devices" = "" ]; then
	devs_num=0
	get_plugged_devices
fi
/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
if [ "$auto_create" = "" ]; then
	echo "[ASSIST][RAID_CREATE_METHOD][AUTO_CREATE,MANUAL_CREATE][AUTO_CREATE]" > /tmp/mnid.agent.in
	while [ 1 ];do
		read line < /tmp/mnid.agent.out
		if [ "$line" = "[AUTO_CREATE]" ]; then
			auto_create=1
			break
		elif [ "$line" = "[MANUAL_CREATE]" ]; then
			auto_create=0
			break
		fi
	done
	echo "user decide to clean disk, and goto initial install"
fi

# To record the RAID creation (manually or automatically) to log file
case "$auto_create" in
"0")
	logger "[User]: I create RAID manually"
	;;
"1")
	logger "[User]: I create RAID automatically"
	;;
*)
	# un-defined now
	;;
esac

md_list=`cat /proc/mdstat | grep 'md[0-9]' | awk -F " " '/md/{printf("%s\n",$1)}'`
for md in $md_list
do
	${mdadm} -S /dev/$md
done

/img/bin/pic.sh LCM_MSG "RAID" "Initial"
echo "[RAID_INITIAL]" > /tmp/mnid.agent.in
logger "Raid Initial ... Start"
#	0. clean old info on disk
clean_disk

#	1. partition
partition

#	2. create swap RAID first to extend memory size
sh /img/bin/mkswap_md.sh "$devices"

#	3. create rootfs RAID
sh /img/bin/mkrootfs_md.sh "$devices"

if [ $? -eq 0 ]; then
	if [ $auto_create -eq 1 ]; then

		#	4. create sys RAID
		sh /img/bin/mksys_md.sh "$devices"

		#	5. create data RAID
		sh /img/bin/mkdata_md.sh "$devices"

		# 	6. stop swap, data, sys RAID, and raid_start will assemble them in rootfs
		md_list=`cat /proc/mdstat | grep 'md[0-9]' | grep -v "md${rootfs_mdnum}" | awk -F " " '/md/{printf("%s\n",$1)}'`
		for md in $md_list
		do
			stop_raid $md
		done
	fi
fi
logger "Raid Initial ... End"
logger "Installation ... End"
