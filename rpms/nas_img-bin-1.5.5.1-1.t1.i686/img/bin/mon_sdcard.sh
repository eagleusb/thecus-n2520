#!/bin/sh

. /img/bin/function/libsdcard

before_status=""
after_status=""
partition_file="/proc/partitions"
usb_hotplug="/img/bin/usb.hotplug"
hdparm="/sbin/hdparm -z"
###############################################
# get total disk device and monitor partition
#
###############################################

total_disk_dev=`check_sd_card_dev`
count="0"

while [ "$total_disk_dev" != "" ];
do
	for disk_name in ${total_disk_dev}
	do
		if [ "${disk_name}" != "" ];then
			cmd="cat \"${partition_file}\" | grep -E \" ${disk_name}[0-9]| ${disk_name}\$\""
			if [ "${count}" == "0" ];then
				before_status=""
			else
				before_status=`eval "$cmd"`
			fi
			${hdparm} /dev/${disk_name}
			sleep 1
			after_status=`eval "$cmd"`
			if [ "${before_status}" != "${after_status}" ];then
				if [ "${before_status}" == "" ] && [ "${after_status}" != "" ];then
					${usb_hotplug} add usb
				elif  [ "${before_status}" != "" ] && [ "${after_status}" == "" ];then
					${usb_hotplug} remove usb
				fi
			fi
		fi
		count="1"
		sleep 1
	done
	sleep 1 
	total_disk_dev=`check_sd_card_dev`
done
