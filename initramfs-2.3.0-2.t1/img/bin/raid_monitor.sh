#!/bin/sh
#
# Monitor RAID action(add/remove), called by udev
# Usage: raid_monitor.sh add|remove diskname
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
lockfile="/tmp/raid_monitor.lock"
action="$1"
diskname="$2"
#disktray="$3"

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################
setLock() {
	touch $lockfile >/dev/null 2>/dev/null
}

unLock() {
	rm -f $lockfile >/dev/null 2>/dev/null
}

is_degrade() {
	local status=`${mdadm} -D /dev/md${data_mdnum} | awk -F' ' '/State :/{printf($4)}' | awk -F, '{printf $1}'`
	local recover=`${mdadm} -D /dev/md${data_mdnum} | awk -F' ' '/State :/{printf($5)}'`
	if [ "$status" = "degraded" ] && [ "$recover" != "recovering" ];then
		# Get Degrade RAID
		return 1
	else
		return 0
	fi
}

hot_add() {
	echo "$diskname added"
	
	is_degrade

	if [ $? -ne 0 ]; then
		echo "RAID degraded, rebuild it..."

		${mdadm} /dev/md${rootfs_mdnum} --remove faulty >/dev/null 2>/dev/null
		${mdadm} /dev/md${swap_mdnum} --remove faulty >/dev/null 2>/dev/null
		${mdadm} /dev/md${data_mdnum} --remove faulty >/dev/null 2>/dev/null
		${mdadm} /dev/md${sys_mdnum} --remove faulty >/dev/null 2>/dev/null

		# clean hotplug disk
		local _pnum=`${sgdisk} -p ${diskname} | grep "^   " | wc -l`
		i=1
		while [ $i -le ${_pnum} ] || [ $i -le 10 ]
		do
			${mdadm} --zero-superblock ${diskname}$i >/dev/null 2>/dev/null
			i=$(($i+1))
		done
		${mdadm} --zero-superblock ${diskname} >/dev/null 2>/dev/null
		$sgdisk -Z $diskname >/dev/null 2>/dev/null
		$sgdisk -o $diskname >/dev/null 2>/dev/null

		# create partition for hotplug disk
		for j in ${rootfs_partnum} ${reserve_partnum} ${swap_partnum} ${sys_partnum} ${data_partnum}    # 4 5 1 3 2 
		do
			if [ $j -eq ${data_partnum} ]; then
				$sgdisk -N $j -t $j:FD00 $diskname
				$sgdisk -c$j:$MODEL $diskname
			else
				$sgdisk -n $j:${pstart[$j]}:${pend[$j]} -t $j:FD00 $diskname
				if [ $j -eq ${rootfs_partnum} ]; then
					$sgdisk -c$j:`uname -m`-THECUS $diskname
				fi
			fi
			if [ $? -ne 0 ]; then
				echo "Create partition $j failed."
			fi
			${mdadm} --zero-superblock ${diskname}$j
		done
		sleep 1
		sync

		# rebuild
		${mdadm} /dev/md${rootfs_mdnum} --add  "${diskname}${rootfs_partnum}"
		if [ $? -ne 0 ]; then
        		/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
			if [ $TDB -ne 1 ]; then
				echo "[ASSIST][RAID_ADD_DISK_FAIL][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[SHUTDOWN]" ]; then
					/img/bin/pic.sh LCM_MSG "System" "Shutting down"
            				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
					poweroff -f
				else
					/img/bin/pic.sh LCM_MSG "System" "Booting"
                			echo "[BOOTING]" > /tmp/mnid.agent.in
				fi
			fi
		fi
		${mdadm} /dev/md${swap_mdnum} --add  "${diskname}${swap_partnum}"
		if [ $? -ne 0 ]; then
        		/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
			if [ $TDB -ne 1 ]; then
				echo "[ASSIST][RAID_ADD_DISK_FAIL][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[SHUTDOWN]" ]; then
					/img/bin/pic.sh LCM_MSG "System" "Shutting down"
            				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
					poweroff -f
				else
					/img/bin/pic.sh LCM_MSG "System" "Booting"
                			echo "[BOOTING]" > /tmp/mnid.agent.in
				fi
			fi
		fi
		${mdadm} /dev/md${data_mdnum} --add  "${diskname}${data_partnum}"
		if [ $? -ne 0 ]; then
        		/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
			if [ $TDB -ne 1 ]; then
				echo "[ASSIST][RAID_ADD_DISK_FAIL][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[SHUTDOWN]" ]; then
					/img/bin/pic.sh LCM_MSG "System" "Shutting down"
            				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
					poweroff -f
				else
					/img/bin/pic.sh LCM_MSG "System" "Booting"
                			echo "[BOOTING]" > /tmp/mnid.agent.in
				fi
			fi
		fi
		${mdadm} /dev/md${sys_mdnum} --add  "${diskname}${sys_partnum}"
		if [ $? -ne 0 ]; then
        		/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
			if [ $TDB -ne 1 ]; then
				echo "[ASSIST][RAID_ADD_DISK_FAIL][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
				read line < /tmp/mnid.agent.out
				if [ "$line" = "[SHUTDOWN]" ]; then
					/img/bin/pic.sh LCM_MSG "System" "Shutting down"
            				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
					poweroff -f
				else
					/img/bin/pic.sh LCM_MSG "System" "Booting"
                			echo "[BOOTING]" > /tmp/mnid.agent.in
				fi
			fi
		fi
	fi
}

hot_remove() {
	echo "$diskname is removed"

	${mdadm} /dev/md${swap_mdnum} --fail ${diskname}${swap_partnum}
	${mdadm} /dev/md${swap_mdnum} --remove ${diskname}${swap_partnum}
 
	${mdadm} /dev/md${rootfs_mdnum} --remove faulty
	${mdadm} /dev/md${swap_mdnum} --remove faulty
	${mdadm} /dev/md${data_mdnum} --remove faulty
	${mdadm} /dev/md${sys_mdnum} --remove faulty
}

##################################################################
#
#  Finally, exec main code
#
##################################################################
while [ -f $lockfile ]
do
	sleep 1
done

setLock

# set disktray
echo "$diskname" | grep "^/dev" >/dev/null 2>&1
if [ $? -eq 0 ]; then
	# diskname is "/dev/sda" format
	devname=`echo "$diskname" | awk -F'/' '{print $3}'`
else
	# diskname is "sda" format
	devname="$diskname"
fi
disktray=`cat /proc/scsi/scsi | grep "Disk:${devname} Model:" | cut -d":" -f3 | cut -d" " -f1`

if [ ! -f /proc/thecus_io ]; then
	_max_tray=0
else
	_max_tray=`cat /proc/thecus_io | awk '/MAX_TRAY/{print $2}'`
fi

if [ $disktray -gt ${_max_tray} ]; then
	unLock
	exit 1
fi

case "$action" in
	add)
		hot_add
		;;
	remove)
		hot_remove
		;;
	*)
		;;
esac

unLock
exit 0
