#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
#	if [ xxx ]; then
#		install_start (initial installation mode, such as: partition, create RAID, mkfs, 
#						add /etc/fstab, mount rootfs, yum install, modify rootfs config)
#	else
#		raid_start (normal booting, such as: assemble RAID, add /etc/fstab, mount rootfs)
#	fi
#	
#	return to init script to switch_root.
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /lib/library
. /img/bin/diagnostics/functions

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################
get_usb_diagnostic_flag() {
		local _normal
		local _strExec
		local _mount_usbs 
		local _mount_usb
		local _check_mount

		[ -d ${diag_mpath} ] || mkdir ${diag_mpath}

		_normal=`cat /proc/scsi/scsi | grep "Intf:USB" | awk '/Thecus:/{FS=" ";printf("%s\n",$3)}' | awk -F: '{printf("%s\n",$2)}'`
		for i in ${_normal}
		do
				_strExec="cat /proc/partitions|awk '/${i}/{FS=\" \";print \$4}'"
				_mount_usbs=`eval ${_strExec}`
				for _mount_usb in ${_mount_usbs}
				do
						_check_mount=`mount|\
				awk '/\/dev\/'${_mount_usb}' /&&/\'${diag_mpath}'/'`
						if [ "${_chkmount}" == "" ];then
								/bin/mount /dev/${_mount_usb} ${diag_mpath}
								if [ $? -ne 0 ]; then
										continue
								fi
						fi
						if [ -f ${diag_mpath}/${diag_flag_file} ]; then
								usb_diagnostic=1												
								return
						else
								umount ${diag_mpath}
						fi
				done
		done
}

factory_test(){
		PIC_MSG="/img/bin/pic.sh"
		factory_sh="factory_test.sh"
		factory_folder="gofactory"
		mountpath="/mnt"
		factory_path="/mnt2"
		app_factory=0
		usb_factory=0
		
		[ ! -d ${mountpath} ] && mkdir ${mountpath}
		mkdir ${factory_path}
		[ -z "$OS_RPMS" ] && return

		/bin/mount -o ro -t $NVM_FS ${OS_RPMS} ${factory_path}
		##Factory function test Server Mode --check loop status##
		if [ -f ${factory_path}/${factory_folder}/${factory_sh} ];then
				app_factory=1
		fi

		satacount=`cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2`
		cat /proc/scsi/scsi >> /tmp/factory.log
		##Factory function test Server Mode --check start from usb##
		strExec="cat /proc/scsi/scsi|awk	'/Intf:USB/{FS=\" \";printf(\"%s:%s\n\",\$2,\$3)}'|awk -F: '{printf(\"%s\n\",\$4)}'"
		normal=`eval ${strExec}`
		echo "$normal" >> /tmp/factory.log
		for i in $normal ;do
				strExec="cat /proc/partitions|awk '/${i}$|${i}[0-9]/{FS=\" \";print \$4}'"
				mount_usbs=`eval ${strExec}`
				for mount_usb in $mount_usbs ;do
						#create folder
						strexec="mount|awk '/\/dev\/${mount_usb}/&&/\/mnt/'"
						chkmount=`eval ${strexec}`
						if [ "${chkmount}" == "" ];then
								/bin/mount -o umask=0,fmask=001,uid=99,gid=99 "/dev/${mount_usb}" "${mountpath}"

								if [ $? = 0 ];then
										if [ -f ${mountpath}/${factory_folder}/${factory_sh} ];then
												/bin/mount -o remount,rw ${OS_RPMS} ${factory_path}
												cp -Rrf ${mountpath}/${factory_folder} ${factory_path}
												sync
												if [ $? = 0 ] && [ -f ${factory_path}/${factory_folder}/${factory_sh} ];then
														usb_factory=1
												fi
										fi
										umount ${mountpath}
								fi
						fi
				
						if [ $usb_factory -eq 1 ];then
								break;
						fi
				done
	
				if [ $usb_factory -eq 1 ];then
						break;
				fi
		done

		if [ ${usb_factory} -eq 1 ] && [ ${app_factory} -eq 1 ];then
				#release factorey mode
				if [ -f ${factory_path}/${factory_folder}/${factory_sh} ];then
						/bin/mount -o remount,rw ${OS_RPMS} ${factory_path}
						rm -rf ${factory_path}/${factory_folder}
				fi
				sync
		else
				if [ ${usb_factory} -eq 1 ] || [ ${app_factory} -eq 1 ];then
						##Start Factory test
						if [ -f ${factory_path}/${factory_folder}/${factory_sh} ];then
								/bin/mount -o remount,rw ${OS_RPMS} ${factory_path}
								ln -sf ${factory_path}/${factory_folder} /etc
								sh /etc/${factory_folder}/${factory_sh} &
						fi

						if [ "${ACPI}" = "1" ]; then
								/usr/sbin/acpid
								/img/bin/pic.sh PWR_S "" ""
						fi

						exit
				fi
		fi

		/bin/umount ${factory_path}
}

##################################################################
#
#	Finally, exec main code
#
##################################################################
logger "Run 99mount-root.sh ... Start"
logger "[Info]: Basic Information" \
"Model = $(cat /proc/thecus_io | grep MODELNAME | cut -f2 -d':' | tr -d ' ')" \
"Firmware = $(cat /etc/version)" \
"nas_initramfs = $(cat /version)"

/img/bin/btn_dispatcher > /dev/null 2>&1 &
udevsettle

# Get NVMDEV OS_RPMS OS_FLAGS parameters by get_nvm_device()
get_nvm_device
export NVMDEV OS_RPMS OS_FLAGS NVM_FS

/img/bin/pic.sh LCM_MSG "System" "Check FT"
sleep 1
factory_test
/img/bin/pic.sh LCM_MSG "System" "Booting"
sleep 1

devs_num=0
devices=""
get_plugged_devices

# get usb diagnostic flag
usb_diagnostic=0
get_usb_diagnostic_flag
if [ ${usb_diagnostic} -eq 1 ]; then
		# Diagnostics mode
		sh ${diag_work}/diagnostics.sh "$devices" $devs_num
		exit
fi

# check if the third partition exists, if not, try to create it.
if [ "$NVM_FS" = "ext4" -a -n "$OS_FLAGS" -a ! -e "$OS_FLAGS" ]; then
		part2_end=`fdisk -l ${NVMDEV} | grep "${OS_RPMS}" | awk '{print $3}'`
		if [ "${part2_end}" != "" ] && [ $((${part2_end})) -gt 2048 ]; then
				part3_start=$((${part2_end}+1))
				echo "n" > /tmp/fdisk.conf
				echo "p" >> /tmp/fdisk.conf
				echo "3" >> /tmp/fdisk.conf
				echo "${part3_start}" >> /tmp/fdisk.conf
				echo "+3M" >> /tmp/fdisk.conf
				echo "w" >> /tmp/fdisk.conf
				fdisk ${NVMDEV} < /tmp/fdisk.conf
				sync
				${mkext4} ${OS_FLAGS}
				sync
		fi
fi

[ -d ${flag_path} ] || mkdir ${flag_path}
if [ -n "$OS_FLAGS" ];then
	mount -t $NVM_FS ${OS_FLAGS} ${flag_path}
	if [ $? -ne 0 -a "$NVM_FS" = "ext4" ]; then
		/sbin/fsck.ext4 -p -C0 ${OS_FLAGS}
		mount -t $NVM_FS ${OS_FLAGS} ${flag_path}
	fi
fi

if [ $devs_num -lt 1 ]; then
	echo "###############################"
	echo "# No disk plugged"
	echo "###############################"
	/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
	if [ $TDB -ne 1 ]; then
		echo "[ASSIST][NO_DISK_EXIST][SHUTDOWN][SHUTDOWN]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[SHUTDOWN]" ]; then
				/img/bin/pic.sh LCM_MSG "System" "Shutting down"
				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
				poweroff -f
				break
			fi
		done
	fi
	exit
fi

nomatch_num=0
nopart_num=0
for dev in ${devices}
do
	partition_match ${dev} ${rootfs_partnum}
	pmatch=$?
	if [ ${pmatch} -ne 1 ] || [ ! "`uname -m`-THECUS" = "`partition_name ${dev} ${rootfs_partnum}`" ]; then
		#not match rootfs partition
		nomatch_num=$((${nomatch_num}+1))
	fi

	partition_exist ${dev}
	pexist=$?
	if [ ${pexist} -ne 1 ]; then
		# no partition exists
		nopart_num=$((${nopart_num}+1))
	fi
done

#Mode=0: valid,Normal booting; 1: invalid/empty Installation; 2. Diagnostics mode
if [ ${nomatch_num} -ne $devs_num ]; then
	# one or more disk match the rootfs partition
	Mode=0
else
	# all the disks do not match the rootfs partition
	Mode=1

	# ask user for auto create data RAID or not
	/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
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


	# there is one(or more) disk have partition exist, then ask user to clean or not.
	if [ ${nopart_num} -ne $devs_num ]; then
		echo "[ASSIST][DISK_EXIST_DATA][CONTINUE,SHUTDOWN][CONTINUE]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[CONTINUE]" ]; then
				echo "user decide to clean disk, and goto initial install"
				break
			elif [ "$line" = "[SHUTDOWN]" ]; then
				echo "user decide to shutdown system"
				/img/bin/pic.sh LCM_MSG "System" "Shutting down"
				echo "[SHUTTING_DOWN]" > /tmp/mnid.agent.in
				poweroff -f
				break
			fi
		done
	fi
fi

if [ $Mode -eq 0 ]; then
	# Normal booting
	sh /img/bin/normal_boot.sh "$devices" $devs_num
elif [ $Mode -eq 1 ]; then
	# Initial installation mode
	sh /img/bin/init_install.sh "$devices"	$devs_num $auto_create
#elif [ $Mode -eq 2 ]; then
#	# Diagnostics mode
#	sh /img/bin/diagnostics.sh "$devices" $devs_num
fi

logger "[Info]: cat /proc/mdstat" "$(cat /proc/mdstat)"
logger "Run 99mount-root.sh ... End"
umount ${flag_path}
