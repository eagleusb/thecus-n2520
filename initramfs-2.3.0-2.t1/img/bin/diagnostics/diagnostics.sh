#!/bin/sh
#
# diagnostics.sh "devices" devices_num
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
echo "###############################"
echo "# Diagnostics mode"
echo "###############################"
diag_log "Start diagnostic mode"

# create backup dir
rm -rf ${diag_mpath}/${back_dir}
mkdir -p ${diag_mpath}/${back_dir}

# check network
sh ${diag_work}/check_network.sh

# check plugged disk
diag_log "Check plugged disk..." 
fdisk -l > ${diag_mpath}/${back_dir}/fdisk.txt 2>&1

nomatch_num=0
nopart_num=0
for dev in ${devices}
do
	${sgdisk} -p /dev/${dev} > ${diag_mpath}/${back_dir}/sgdisk_${dev}.txt 2>&1
	partition_match ${dev} ${rootfs_partnum}
	pmatch=$?
	if [ ${pmatch} -ne 1 ]; then
		nomatch_num=$((${nomatch_num}+1))
	fi
	
	partition_exist ${dev}
	pexist=$?
	if [ ${pexist} -ne 1 ]; then    # no partition exists
		nopart_num=$((${nopart_num}+1))
	fi
done

#Mode=0: Normal booting; 1: Installation; 2. Ask user
if [ ${nomatch_num} -eq $devs_num ]; then	# all the disks are not match the partition
    if [ ${nopart_num} -eq $devs_num ]; then    # all the disks have no partition exists, goto initial install
	Mode=1
    else	# there is one(or more) disk have partition exist, so ask user to decide to clean or not.	
	Mode=2
    fi
else	# there is one (or more) disk match the rootfs partition, so try to assemble it
    Mode=0
fi

md_list=`cat /proc/mdstat | grep 'md[0-9]' | awk -F " " '/md/{printf("%s\n",$1)}'`
for md in $md_list
do
	${mdadm} -S /dev/$md
done

if [ $devs_num -lt 1 ]; then
    diag_log "There is no disk plugged"
elif [ $Mode -eq 1 ]; then
    diag_log "Cannot find any partition, maybe you need goto initial installation mode"
elif [ $Mode -eq 2 ]; then
    diag_log "Cannot find runtime system partition, but system detect hard drive exists other data, please ask user to clean disk or not"
else
    diag_log "Disk $devices plugged"
    # check Storage
    sh ${diag_work}/check_Storage.sh "$devices" $devs_num
fi

# check RPM installation
cat /proc/mounts | grep "$NEWROOT" | grep "/dev/md${rootfs_mdnum}" >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
    sh ${diag_work}/check_rpm.sh
fi

# backup system status for debug
sh ${diag_work}/backup_systatus.sh

# stop raid
stop_raid md${data_mdnum}
stop_raid md${sys_mdnum}
stop_raid md${rootfs_mdnum}
stop_raid md${swap_mdnum}

# check HW
sh ${diag_work}/check_hardware.sh "$devices" $devs_num

# tar backup files
cd ${diag_mpath}/
tar zcpf ${back_dir}.tgz ${back_dir}
rm -rf ${diag_mpath}/${back_dir}
des -E -k ${enckey} ${back_dir}.tgz ${back_dir}.bin
rm -f ${back_dir}.tgz
cd - 

# delete diagnostic flag file
diag_log "delete ${diag_flag_file}"
rm -f ${diag_mpath}/${diag_flag_file}
sync

# umount usb storage 
diag_log "umount usb storage"
diag_log "shutdown system"
umount -f ${diag_mpath}
rm -rf ${diag_mpath}

# shutdown system 
poweroff -f

exit
