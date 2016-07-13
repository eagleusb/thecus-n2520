#!/bin/sh
. /img/bin/functions

get_plugged_devices() {
        local _max_tray=0
        local _dev=""

	if [ ! -f /proc/thecus_io ]; then
            _max_tray=0
        else
            _max_tray=`cat /proc/thecus_io | awk '/MAX_TRAY/{print $2}'`
        fi

        for((i=1;i<=${_max_tray};i++))
        do
            _dev=`cat /proc/scsi/scsi | grep "Tray:$i Disk:" | cut -d":" -f4 | cut -d" " -f1`
            if [ "${_dev}" != "" ]; then
                if [ ${devs_num} -eq 0 ]; then
                    devices="${_dev}"
                else
                    devices="${devices} ${_dev}"
                fi
                devs_num=$(($devs_num+1))
            fi
        done 
}

umount -f /sysroot

devs_num=0
devices=""
get_plugged_devices

$mdadm -S /dev/md${rootfs_mdnum}
$mdadm -S /dev/md${swap_mdnum}
$mdadm -S /dev/md${sys_mdnum}
$mdadm -S /dev/md${data_mdnum}
for dev in ${devices}
do
	echo "clean old raid info on ${dev}"
	$mdadm --zero-superblock /dev/${dev}${rootfs_partnum}
	$mdadm --zero-superblock /dev/${dev}${swap_partnum}
	$mdadm --zero-superblock /dev/${dev}${sys_partnum}
	$mdadm --zero-superblock /dev/${dev}${data_partnum}
	echo "clean old partition table on ${dev}"
	$sgdisk -Z /dev/${dev}
done

echo "clean finished"
