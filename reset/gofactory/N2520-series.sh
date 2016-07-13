#! /bin/sh
##########################################################################
# For OS6 bin file upgarded
# Desc: Program N4520/N2520 flash/emmc with given new image files.
#       It will beep 3 secs to indicate a successful write then power off
#       the box automatically; else it will keep 1s short beeps, and 
#       request manually shutdown.
#       Checksum will be used to determine the term 'successful write'
##########################################################################

PATH=$PATH:/usr/local/sbin:/img/bin:/usr/lib/nas_img-tools:/tmp

# Setup environment
init_env(){
	CONF="/tmp/upgrade.conf"
	EMMC_DEV="/dev/mmcblk0"
	FLASH_DEV="/dev/mtdblock0"

	# Install necessary binaries for imgtool; which binaries need to be
	# installed depends by initramfs version.
	if [ ! -f "/version" ];then
		# This is old initramfs which has lack of necessary utilities
		# for imgtool.
		cp /tmp/$(uname -m)/du /usr/bin/
		cp /tmp/$(uname -m)/md5sum /usr/bin/
		cp /tmp/$(uname -m)/sha256sum /usr/bin/
		chmod +x /usr/bin/du /usr/bin/md5sum /usr/bin/sha256sum
	else 
		install -m 755 /tmp/$(uname -m)/dd /bin/
		install -m 755 /tmp/$(uname -m)/du /usr/bin/
	fi

    [ -f /proc/mounts ] || mount -t proc proc /proc
    MY_MMC_SIZE="`awk '/mmcblk0\>/ {print $3}' /proc/partitions`"
    [ $MY_MMC_SIZE -lt 2000000 ] && MY_MMC_SIZE=2G || MY_MMC_SIZE=4G
	# make sure we umount eMMC before programming proccess.
	while [ -n "`cat /proc/mounts | grep mmcblk`" ];do
		sync
		umount /dev/mmcblk* > /dev/null 2>&1
	done

	# eMMC image file source
	EMMC_BIN="`readlink -f ${USB_MNT}/*_OS6.*.t1.${MY_MMC_SIZE}.bin`"
	# If there is no bin file for distribution t1 (IntelCE series), search
	# for the bin file in old naming rule.
	[ ! -f "$EMMC_BIN" ] &&\
		EMMC_BIN="`readlink -f ${USB_MNT}/N2520_OS6.*.${MY_MMC_SIZE}.bin`"
	[ -f "$EMMC_BIN" ] && EMMC_SUM="`awk '{print $1}' ${EMMC_BIN}.md5`"

	# flash image files source
 	FLASH_BIN="`readlink -f ${USB_MNT}/${MODELNAME}-spi_nor*.bin`"
	FLASH_SUM="`awk '{print $1}' ${FLASH_BIN}.md5`"
	FLASH_DIR="`echo $FLASH_BIN | sed 's/.bin//g'`"
	CEFDK="`readlink -f ${FLASH_DIR}/gen5_[sd]c*.bin`"
	CEFDK_SUM="`awk '{print $1}' ${CEFDK}.md5`"
	FW8051="`readlink -f ${FLASH_DIR}/gen5_pm8051_*.bin`"
	FW8051_SUM="`awk '{print $1}' ${FW8051}.md5`"
	SPLASH="${FLASH_DIR}/thecuslogo_480.bmp"
	SPLASH_SUM="`awk '{print $1}' ${SPLASH}.md5`"
	SCRIPT="${FLASH_DIR}/boots"

	# MFH table recovery used
	MFH_RECOVER="$USB_MNT/mfhtbl.rcv"
	MFH_OFFSET=$((0x80000))

	# generated upgraded flash image
	NEW_FLASH_BIN="${FLASH_BIN}.new"
	NEW_FLASH_SUM="${NEW_FLASH_BIN}.md5"
	NEW_EMMC_SUM="${EMMC_BIN}.new.md5"

	# tmp file on ramfs for flash image programming used
	FLASH_NEW="/tmp/mtd.new"
	dd if=$FLASH_DEV of=$FLASH_NEW

	# get version
	FLASH_VER="`imgtool flash $FLASH_BIN -v |\
		awk '/flash version/ {print $4}'`"
}

# check readback md5sum by item
chk_flash_sum(){
	local ITEM="$1"
	local SRC_SUM="$2"
	local ENTRY=""

	case $ITEM in
	CEFDK) ENTRY="CEFDK S1"
		;;
	FW8051) ENTRY="UC8051_FW"
		;;
	SPLASH) ENTRY="Splash Screen"
		;;
	SCRIPT) ENTRY="Script"
		;;
	VERSION) ENTRY="User Offset"
		;;
	esac

	# get entry information from MFH table
	local ENTRY_INFO="`imgtool flash $FLASH_NEW -s |\
		awk -F':' '/'"$ENTRY"'/ {print $2}'`"
	local OFFSET="`echo $ENTRY_INFO | awk '{print $1}'`"
	local SIZE="`echo $ENTRY_INFO | awk '{print $2}'`"
	# specify CEFDK size as 512kB
	[ "$ITEM" = "CEFDK" ] && SIZE=$((0x80000))
	# MFH table doesn't include version length, set it manually
	[ "$ITEM" = "VERSION" ] && SIZE=512

	# get readback checksum
	local TMPSUM="`dd if=$FLASH_NEW bs=1 skip=$((OFFSET)) count=$((SIZE)) |\
		md5sum | awk '{print $1}'`"

	[ "$TMPSUM" = "$SRC_SUM" ] && return 0 || return 1
}

# Program eMMC image and check the readback checksum
# set EMMC_RET as 0 if check ok.
program_emmc(){
	local SRC_IMG=$1
	local SRC_SUM=$2
	if [ -f "$SRC_IMG" ];then
		# get version
		EMMC_VER="`imgtool emmc $SRC_IMG -v |\
			awk -F'.' '/emmc version/ {print $2}'`"
		/img/bin/pic.sh LCM_MSG "eMMC(${EMMC_VER})" "programming..."
		echo "eMMC(${EMMC_VER}) programming..."
		dd if=$SRC_IMG of=$EMMC_DEV bs=1M
		sync

		# readback eMMC for md5sum check

        SRC_SIZE="`ls -l ${SRC_IMG} | awk '{print $5}'`"
        COUNT=$(( SRC_SIZE / 1024 / 1024 ))
        local RB_SUM="`dd if=$EMMC_DEV bs=1M count=$COUNT |\
            md5sum | awk '{print $1}'`"
		[ "$SRC_SUM" = "$RB_SUM" ] && EMMC_RET=0 || EMMC_RET=1
	else
		EMMC_RET=1
	fi
}

# Program flash image and check the readback checksum
# set FLASH_RET as 0 if check ok.
program_flash(){
	local SRC_IMG=$1
	local SRC_SUM=$2
	if [ -f "$SRC_IMG" ];then
		FLASH_VER="`imgtool flash $SRC_IMG -v |\
			awk '/flash version/ {print $4}'`"
		# Erase flash device first
		/img/bin/pic.sh LCM_MSG "flash upgrade" "erasing..."
		echo "flash upgrade erasing..."
		tr '\000' '\377' < /dev/zero | dd of=$FLASH_DEV bs=1K count=4096
		sync
		# programming
		/img/bin/pic.sh LCM_MSG "$FLASH_VER" "programming..."
		echo "$FLASH_VER" "programming..."
		dd if=$SRC_IMG of=$FLASH_DEV
		sync

		# readback flash for md5sum check
		local RB_SUM="`dd if=$FLASH_DEV bs=1M count=4 | md5sum |\
			awk '{print $1}'`"
		[ "$SRC_SUM" = "$RB_SUM" ] && FLASH_RET=0 || FLASH_RET=1
	else
		FLASH_RET=1
	fi
}

# Update new flash image by item and check the readback checksum.
# set FLASH_RET as 0 if check ok.
update_flash(){
	local ITEM="$1"
	eval local FILE="\$$ITEM"
	eval local FSUM="\$${ITEM}_SUM"

	# for boot script and version items,
	# need to create raw data bin file first.
	case $ITEM in
	SCRIPT)
		ceimggen -b $FILE
		FILE="`readlink -f ./boots.bin`"
		FSUM="`md5sum $FILE | awk '{print $1}'`"
		;;
	VERSION)
		ceimggen -v "$FLASH_VER (update:`date +'%D %T'`)"
		FILE="`readlink -f ./fver.bin`"
		FSUM="`md5sum $FILE | awk '{print $1}'`"
		;;
	esac

	# programming flash item
	if [ -f "$FILE" ];then
		/img/bin/pic.sh LCM_MSG "flash updating" "$ITEM"
		ceimggen -u flash ${FLASH_NEW} ${ITEM} ${FILE}
		sync

		# check md5
		chk_flash_sum "$ITEM" "$FSUM"
		FLASH_RET=$?
	else
		FLASH_RET=1
	fi	
}

# Use recover MFH image to update MFH table
recover_mfhtbl(){
	# set 'DEVICE' parameter for libce reference
	DEVICE=$FLASH_NEW
	dd if=$MFH_RECOVER of=$DEVICE bs=1 seek=$((MFH_OFFSET)) conv=notrunc
	sync
	# update MFH sha5 checksum individually
	source libce
	set_mfh_signature
	FLASH_RET=0
}

usb_check_fail(){
	/img/bin/pic.sh LCM_MSG "usb" "read failure"
	echo "Buzzer 1" > /proc/thecus_io
	exit 1
}

# check usb is normal, it can cause test fail . 
check_usb(){
	local tmpfile=/tmp/check_usb.$$.$RANDOM.tmp
	local A B
        cat $NEW_FLASH_SUM 
	cat_ret=$?
        md5sum $NEW_FLASH_BIN > $tmpfile 2>&1
        md_ret=$?
	if [ "$cat_ret" -eq "0" ] && [ "$md_ret" -eq "0" ];then
		A=`awk '{print $1}' $tmpfile`
		B=`awk '{print $1}' $NEW_FLASH_SUM`
		[ "$A" != "$B" ] && usb_check_fail 	
	else
		usb_check_fail
        fi
}

# Double check flash
dbchk_flash(){
	[ ! -f "$NEW_FLASH_SUM" ] && FLASH_RET=0 && return 0

	# check md5sum again
	/img/bin/pic.sh LCM_MSG "flash" "double check..."
	echo "flash double check..."
	md5sum -c $NEW_FLASH_SUM
	FLASH_RET=$?
	# re-program flash again if checksum is failed.
	[ "$FLASH_RET" -ne 0 ] && \
		program_flash "$NEW_FLASH_BIN" "`awk '{print $1}' $NEW_FLASH_SUM`"

	if [ "$FLASH_RET" -eq 0 ];then
		rm -rf $NEW_FLASH_BIN
	else
		# backup new flash image by MAC address if upgrading failed.
		MAC="`ifconfig eth0 | awk '/HWaddr/ {print $5}'`"
		mv $NEW_FLASH_BIN ${NEW_FLASH_BIN}.${MAC}
	fi

	rm -rf $NEW_FLASH_SUM
}

# Double check eMMC
dbchk_emmc(){
	[ ! -f "$NEW_EMMC_SUM" ] && EMMC_RET=0 && return 0

	# check md5sum again
	/img/bin/pic.sh LCM_MSG "eMMC" "double check..."
	echo "eMMC double check..."
	local DEVSUM="`dd if=$EMMC_DEV bs=1M count=512 | md5sum | awk '{print $1}'`"
	[ "$DEVSUM" = "$EMMC_SUM" ] && EMMC_RET=0 || EMMC_RET=1
	# re-program flash again if checksum is failed.
	[ "$EMMC_RET" -ne 0 ] && \
		program_emmc "$EMMC_BIN" "$EMMC_SUM"

	rm -rf $NEW_EMMC_SUM
}

# Check return code after all programming processes are done.
# Control buzzer to inform OP the result.
# @ Success: Beeps for 3 secs.
# @ Fail   : Endless short beeps
chk_result(){
	RET=$((EMMC_RET+FLASH_RET))
       EMMC_CONF=`awk '{if($2=="yes"){print $1}}' $CONF`
	case $RET in
	0)  # both eMMC and flash are programmed successfully.
		if [ "$SECOND_BOOT" -ne 1 ];then
			if [ "$EMMC_CONF" == "eMMC" ];then
	        	/img/bin/pic.sh LCM_MSG "eMMC Upgrade PASS" " "
			    echo "eMMC Upgrade PASS"
			    echo "Buzzer 1" > /proc/thecus_io
		    	sleep 3
			    echo "Buzzer 0" > /proc/thecus_io
			    poweroff -f
			else 
            	# if this is 1st programming, reboot for double check
				/img/bin/pic.sh LCM_MSG "1st pass, reboot" "for 2nd check"
				echo "1st pass, reboot for 2nd check"
				reboot -f
			fi
		else
			# this is second boot
			/img/bin/pic.sh LCM_MSG "Upgrade PASS" " "
			echo "Upgrade PASS"
			echo "Buzzer 1" > /proc/thecus_io
			sleep 3
			echo "Buzzer 0" > /proc/thecus_io
		fi
		;;
	1|2)  # one of these two devices is programmed failed or
		  # both devices are programmed failed.
		/img/bin/pic.sh LCM_MSG "Upgrade FAIL" " "
		echo "Upgrade FAIL"
		while true; do
			echo "Buzzer 1" > /proc/thecus_io
			sleep 1
			echo "Buzzer 0" > /proc/thecus_io
			sleep 1
		done 
		exit
		;;
	esac
}

################################################################
#     Main section
################################################################
main(){
	FLASH_RET=0
	EMMC_RET=0
	# check if this is the second boot for image validation
	if [ -f "$NEW_FLASH_SUM" -o -f "$NEW_EMMC_SUM" ];then
		SECOND_BOOT=1
                check_usb
		dbchk_flash
		#dbchk_emmc
	else
		SECOND_BOOT=0
		FU_FLAG=0
		# check upgrade items by config file
		for x in `awk '{if($2=="yes"){print $1}}' $CONF`;do
			case $x in
			eMMC)
				program_emmc "$EMMC_BIN" "$EMMC_SUM"
				if [ "$EMMC_RET" = "1" ];then
					echo "Program eMMC failed, try again ..."
					EMMC_RET=0
					program_emmc "$EMMC_BIN" "$EMMC_SUM"
				fi
				# comment out eMMC stamp file to avoid double check since
				# our initramfs will program eMMC space while booting,
				# therefore the second boot check is meaningless.
				#touch $NEW_EMMC_SUM
				;;
			flash_cefdk)
				update_flash "CEFDK"
				FU_FLAG=1
				;;
			flash_8051)
				update_flash "FW8051"
				FU_FLAG=1
				;;
			flash_logo)
				update_flash "SPLASH"
				FU_FLAG=1
				;;
			flash_bootscript)
				update_flash "SCRIPT"
				FU_FLAG=1
				;;
			flash_mfh)
				recover_mfhtbl
				FU_FLAG=1
				;;
			esac
			[ "$FLASH_RET" -ne 0 -o "$EMMC_RET" -ne 0 ] && break
		done

		# if we have upgraded any flash image, update version here and write
		# the programmed tmp file to flash device.
		if [ "$FU_FLAG" -eq 1 -a "$FLASH_RET" -eq 0 ];then
			update_flash "VERSION"
			if [ "$FLASH_RET" -eq 0 ];then
				md5sum $FLASH_NEW > $NEW_FLASH_SUM
				cp -a $FLASH_NEW $NEW_FLASH_BIN
				program_flash "$FLASH_NEW" "`awk '{print $1}' $NEW_FLASH_SUM`"
			fi
		fi
	fi

	chk_result
}

init_env
main

