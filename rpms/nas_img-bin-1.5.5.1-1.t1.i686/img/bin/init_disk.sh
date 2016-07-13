#!/bin/sh
#
# init_disk.sh "device"
#
# Initial Installation Mode:
#	partition
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
device="$1"

        
##################################################################
#
#  Second, declare sub routines needed
#
##################################################################
# clean the partition and md info first
clean_disk() {
	echo "clean the disk ..."
	local _pnum
	
        _pnum=`${sgdisk} -p /dev/$device | grep "^   " | wc -l`
        j=1
        while [ $j -le ${_pnum} ] || [ $j -le 10 ]
        do
                ${mdadm} --zero-superblock /dev/$device$j >/dev/null 2>/dev/null
                j=$(($j+1))
        done
        ${mdadm} --zero-superblock /dev/$device >/dev/null 2>/dev/null
        ${sgdisk} -Z /dev/$device >/dev/null 2>/dev/null
        ${sgdisk} -o /dev/$device >/dev/null 2>/dev/null

}

# create the partition 
partition() {
	echo "create partition ..."
	local _device

        _device="/dev/${device}"
        for j in ${rootfs_partnum} ${reserve_partnum} ${swap_partnum} ${sys_partnum} ${data_partnum}	# 4 5 1 3 2
        do
                if [ $j -eq ${data_partnum} ]; then
                        $sgdisk -N $j -t $j:FD00 $_device 
                        $sgdisk -c $j:THECUS $_device
                else
                        $sgdisk -n $j:${pstart[$j]}:${pend[$j]}	-t $j:FD00 $_device
                        if [ $j -eq ${rootfs_partnum} ]; then
                                $sgdisk -c $j:`uname -m`-THECUS $_device
                        fi
                fi
                if [ $? -ne 0 ]; then
                        #error 002 $j
			echo "Create partition $j failed."
                fi
        done
        # display the partition
        $sgdisk -p $_device
}

##################################################################
#
#  Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Initial Disk"
echo "###############################"
partition_match ${device} ${rootfs_partnum}	
if [ $? -eq 1 ]; then	
        # rootfs partition is match
        Mode=0
else
        # rootfs partition is not match
        Mode=1

        #0. clean old info on disk
        clean_disk

        #1. partition
        partition
fi

