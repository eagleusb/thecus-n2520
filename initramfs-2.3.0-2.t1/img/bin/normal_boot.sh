#!/bin/sh
#
# normal_booting.sh "devices" devices_num
#
# Normal Booting Mode:
#	1. assemble rootfs RAID
#	2. assemble data RAID
#	3. assemble sys RAID
#	4. assemble swap RAID
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

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################

##################################################################
#
#	Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Normal booting"
echo "###############################"
logger "Booting ... Start"
# check if each runtime system partition is RAID1
i=1
for dev in ${devices}
do
	devs[$i]="${dev}"
	is_raid1[$i]=0
	uuid[$i]=`get_uuid ${devs[$i]} ${rootfs_partnum}`
	if [ "${uuid[$i]}" != "" ]; then
		echo "${uuid[$i]}" | grep "^raid1;"
		if [ $? -eq 0 ]; then
			# sd? runtime system is RAID1
			is_raid1[$i]=1
		fi
	fi
	i=$(($i+1))
done

# choose first runtime system to mount
rootfs_devs=""
rootfs_uuid=""
for((i=1;i<=${devs_num};i++))
do
	if [ ${is_raid1[$i]} -eq 1 ]; then
		if [ "${rootfs_uuid}" = "" ]; then
			rootfs_uuid="${uuid[$i]}"
			rootfs_devs="${devs[$i]}"
		else
			if [ "${uuid[$i]}" = "${rootfs_uuid}" ]; then
				rootfs_devs="${rootfs_devs} ${devs[$i]}"
			fi
		fi
	fi
done

#	assemble rootfs RAID
sh /img/bin/assemble_rootfs.sh "${rootfs_devs}"


# check if rpm installed successfully
if [ ! -f $NEWROOT/etc/.rootfs_rpm ]; then
	# rpm may be not installed successfully, so clear newroot then
	# re-install rootfs rpms.
	dirs=`ls ${NEWROOT}/ | grep -v "lost+found"`
	for dir in $dirs
	do
		rm -rf ${NEWROOT}/$dir
	done

	sync

	/img/bin/rpm_install.sh
fi

