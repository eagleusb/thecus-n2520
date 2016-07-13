#! /bin/sh
##########################################################################
# For N2310 fw image upgrading.
# Description:
#     Program N2310 flash image into mtd device, but keep original MAC
#     and bootcmd variables. Check flash checksum after programming,
#     if success, beep 3 seconds then shutdown the machine, or raise
#     buzzer to keep short beeps.
##########################################################################

PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin

# Setup environment
init_env(){
	NVM_DEV="/dev/mtd0"
	MAC_ADDR="`cat /sys/class/net/eth0/address`"

	# for initramfs < 2.0.3-2 which uses busybox for dd and du,
	# need to replace it by coreutils to ensure nas_img-tools work correctly.
	RDVER_REQUIRE="initramfs 2.0.3-2.os6.ppc"
	RDVER="`cat /version`"
	MIN_RDVER="`echo -e "$RDVER_REQUIRE\n$RDVER" | sort | head -n1`"
	if [ "$MIN_RDVER" != "$RDVER_REQUIRE" ];then
		install -m 755 /tmp/$(uname -m)/dd /bin/
		install -m 755 /tmp/$(uname -m)/du /usr/bin/
	fi

	# make sure we umount all fs on mtd device before programming proccess.
	while [ -n "`grep ubi /proc/mounts`" ];do
		sync
		umount `awk '/ubi/ {print $2}' /proc/mounts`
	done
	# detach ubifs
	ubidetach -d 0

	# fw image file source
	FW_BIN="`readlink -f ${USB_MNT}/*_OS6.*.t2.bin`"
	# If there is no bin file for distribution t2 (APM series), search for
	# the bin file in old naming rule.
	[ ! -f "$FW_BIN" ] && FW_BIN="`readlink -f ${USB_MNT}/${MODELNAME}_OS6.*.bin`"
	# If there is still no bin file found, search for Elecom FW in old naming
	# rule.
	[ ! -f "$FW_BIN" ] && FW_BIN="`readlink -f ${USB_MNT}/Elecom_OS6.*.bin`"
	# No valid bin file found, upgrade failed.
	[ ! -f "$FW_BIN" ] && echo "No valid bin file found!!" && chk_result 1

	FW_SUM="`awk '{print $1}' ${FW_BIN}.md5`"
	NEW_FW_BOOT="${USB_MNT}/`echo ${MAC_ADDR} | sed 's/://g'`"

	# generated upgraded flash image
	NEW_FW_BIN="${FW_BIN}.new"
	NEW_FW_SUM="${NEW_FW_BIN}.md5"

	# tmp file on ramfs for flash image programming used
	NEW_FW_RAM="/tmp/mtd.new"

	# get version
	FW_VERSION="`imgtool apm $FW_BIN -v | awk '/apm version/ {print $4}'`"
}

usb_check_fail(){
	/img/bin/pic.sh LCM_MSG "usb" "read failure"
	echo "Buzzer 1" > /proc/thecus_io
	exit 1
}

# check usb is normal, it can cause test fail . 
check_usb(){
	local TARGET_BIN="$1"
	local EXPECTED_SUM="$2"

	TARGET_SUM="`md5sum $TARGET_BIN | awk '{print $1}'`"
	if [ "$EXPECTED_SUM" != "$TARGET_SUM" ];then
		usb_check_fail
	fi
}

gen_uenv(){
	local DES_UENV="$1"
	local TMP_UBOOTENV="/tmp/uboot.env"

	# dump uboot environment variables list from image
	imgtool apm $FW_BIN -p | sed '1,2d' > $TMP_UBOOTENV
	# update the MAC to this list and change its bootcmd
	sed -i 's/bootcmd=\(.*\)/bootcmd=run os6_self/g;
	        s/ethaddr=\(.*\)/ethaddr='$MAC_ADDR'/g' $TMP_UBOOTENV
	# generate uenv binary
	apmimggen -e $TMP_UBOOTENV
	cp uenv.bin $DES_UENV
}

gen_target_fw(){
	# copy image to ram and check if the image is read correctly.
	cp $FW_BIN $NEW_FW_RAM
	check_usb "$NEW_FW_RAM" "$FW_SUM"

	# create new uboot environment with original MAC and bootcmd settings
	local NEW_UENV="/tmp/uenv.bin"
	gen_uenv "$NEW_UENV"

	# update uenv to FW image on ram
	apmimggen -u $NEW_FW_RAM ENV $NEW_UENV
	# update version
	apmimggen -u $NEW_FW_RAM VERSION "$FW_VERSION (update:`date +'%D %T'`)"
}

program_fw(){
	local RET=1

	gen_target_fw
	# program NVM device
	busybox flashcp $NEW_FW_RAM $NVM_DEV -v
	RET=$?
	if [ "$RET" -ne 0 ];then
		# if the first time programming failed, retry once.
		busybox flashcp $NEW_FW_RAM $NVM_DEV -v
		RET=$?
	fi

	return $RET
}

# Check return code after all programming processes are done.
# Control buzzer to inform OP the result.
# @ Success: Beeps for 3 secs then shutdown.
# @ Fail   : Endless short beeps or slient forever (once reboot failed).
chk_result(){
	local RET_VAL="$1"
	if [ "$RET_VAL" -eq 0 ];then
		# fw programming successfully.
		/img/bin/pic.sh LCM_MSG "FW Upgrade PASS" " "
		echo "FW Upgrade PASS"
		if [ "$SECOND_BOOT" -eq 1 ];then
			# reboot new FW successfully.
			echo "Buzzer 1" > /proc/thecus_io
			sleep 3
			echo "Buzzer 0" > /proc/thecus_io
			poweroff -f
		else
			# reboot to make sure the machine able to boot again.
			touch "$NEW_FW_BOOT"
			reboot -f
		fi
	else
		/img/bin/pic.sh LCM_MSG "FW Upgrade FAIL" " "
		echo "FW Upgrade FAIL"
		while true; do
			echo "Buzzer 1" > /proc/thecus_io
			sleep 1
			echo "Buzzer 0" > /proc/thecus_io
			sleep 1
		done 
		exit
	fi
}

################################################################
#     Main section
################################################################
main(){
	if [ -f "$NEW_FW_BOOT" ];then
		SECOND_BOOT=1
		rm -rf $NEW_FW_BOOT
		# Reboot successfully, means the upgrade result is safe.
		chk_result "0"
	else
		SECOND_BOOT=0
		program_fw
		RET=$?
		chk_result "$RET"
	fi
}

init_env
main

