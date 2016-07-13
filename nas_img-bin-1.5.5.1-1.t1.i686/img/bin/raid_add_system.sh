#!/bin/sh
# This script is transformed from ::add_system() in nas_admin-ui/inc/raid.class.php
# At this moment, only N2310 will add system disks in this way. N2520 will no longer
# have sda4 sdb4 for the system disk.

init_env(){
	DEVICES="$1"
	local CHECK=`awk '/sda|sdb|sdc|sdd/ && /md70/' /proc/mdstat`
	if [ -n "$CHECK" ]; then
		MD70_ON_DISK=1
	else
		MD70_ON_DISK=0
	fi
}

main(){
	if [ $MD70_ON_DISK -eq 1 ]
	then
		/sbin/mdadm --add /dev/md70 $DEVICE
	fi
}

clean_up(){
	true
}

init_env "$@"
main     "$@"
clean_up "$@"
