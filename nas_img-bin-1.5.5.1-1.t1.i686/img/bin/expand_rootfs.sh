#!/bin/sh
##############################################
# Format : expand_rootfs.sh $rootfsdisks
# Used for expand rootfs raid
##############################################
. /img/bin/functions
rootfsdisks="$1"
new_num=0
new_devs=""
# check if the rootfs is on hard drive (say, md70 = sda4 + sdb4)
# for N2520 series, the new version root is on md70 = mmcblk0p4
# for N2310 series, the new version root is on md70 = flash partition
is_md70_on_disk(){
	local CHECK=`awk '/sdb|sda|sdc|sdd/ && /md70/' /proc/mdstat`
	if [ -n "$CHECK" ]; then
		MD70_ON_DISK=1
	else
		MD70_ON_DISK=0
	fi
}

is_md70_on_disk

if [ $MD70_ON_DISK -eq 0 ]
then
	echo "rootfs is not on hard drive (say, sda4/sdb4/sdc4/sdc4), no need to do expand, exit."
	exit 
fi

for dev in ${rootfsdisks}
do
	${mdadm} -D /dev/md${rootfs_mdnum} | grep "${dev}" > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		if [ ${new_num} -eq 0 ]; then
			new_devs="${dev}"
		else
			new_devs="${new_devs} ${dev}"
		fi
		new_num=$(($new_num+1))
	fi 
done

if [ ${new_num} -gt 0 ] && [ "${new_devs}" != "" ]; then
	dev_num=`${mdadm} -D /dev/md${rootfs_mdnum} | grep -E "active sync|spare" | wc -l`
	dev_num=$(($dev_num+$new_num))
	${mdadm} /dev/md${rootfs_mdnum} --add ${new_devs}
else
	echo "${rootfsdisks} already in rootfs RAID"
fi
