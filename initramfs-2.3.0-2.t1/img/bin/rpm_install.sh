#!/bin/sh

. /img/bin/functions
. /lib/library

mount_usb(){
	local UMNT="$1"
	USBDISK="`awk '/Intf:USB/ {print $3}' /proc/scsi/scsi | cut -d":" -f2`"
	[ -z "$USBDISK" ] && return 1

	# mount USB if existed
	if [ -n "`grep " ${USBDISK}1$" /proc/partitions`" ];then
		mount -o ro "/dev/${USBDISK}1" $UMNT
	else
		mount -o ro "/dev/${USBDISK}" $UMNT
	fi
}

mount_rpm(){
	# rpm install runtime system
	mkdir -p /rpm
	USB_MNT="/usb"
	mkdir -p $USB_MNT
	umount $USB_MNT
	mount_usb "$USB_MNT"

	if [ -d "$USB_MNT/${MODEL}/rootfs_rpms" ];then
		# external installation for development
		mount -o bind $USB_MNT/${MODEL}/rootfs_rpms /rpm
		RET=$?
	else
		mount -o ro -t $NVM_FS $OS_RPMS /rpm
		RET=$?
	fi

	return $RET
}

install_rpm(){

	logger "Rpm Install ... Start"
	check_debug_flag 44
	DEBUG_FLAG="$?"

	# prepare NEWROOT environment for rpm installation
	mkdir -p ${NEWROOT}/proc ${NEWROOT}/sys ${NEWROOT}/dev
	mount -t proc proc ${NEWROOT}/proc
	mount -t sysfs sysfs ${NEWROOT}/sys
	mount -o bind /dev ${NEWROOT}/dev

	local installing_rpm_log="$LOG_DIR/installing_rpm.log"
	RPM_LIST="`ls /rpm/*.rpm`"
	rpm -iv --root $NEWROOT $RPM_LIST --nodeps --force 2> $installing_rpm_log

	 # check all the rpms are installed successfully
	
	logger "Rpm Install Check ... Start"
        installing_count=`ls /rpm/*.rpm | wc -l`
        installed_count=` rpm -qa --root $NEWROOT | wc -l`
	logger "installing_count=$installing_count"
	logger " installed_count=$installed_count"
        if [ "$installing_count" != "$installed_count" -o "$DEBUG_FLAG" == "1" ];then
		logger "Rpm Install Check ... Fail"
                install_missing_rpm
        fi
	logger "Rpm Install Check ... End"

	# clean environment
	umount ${NEWROOT}/proc
	umount ${NEWROOT}/sys
	umount ${NEWROOT}/dev
}

install_missing_rpm(){
	
	logger "Rpm Re-Install ... Start"
        local installing_rpm_fail_list="$LOG_DIR/installing_rpm_fail.list"
        local installing_rpm_list="$LOG_DIR/installing_rpm.list"
        local installed_rpm_list="$LOG_DIR/installed_rpm.list"

	# limited usage of some commands in busybox
	for i in `ls /rpm/*.rpm | sort`
	do
		basename $i '.rpm' >> $installing_rpm_list
	done

        rpm -qa --root $NEWROOT | sort > $installed_rpm_list
        comm -23 $installing_rpm_list $installed_rpm_list > $installing_rpm_fail_list
        cat $installing_rpm_fail_list | \
        while read line
        do
                local retry_num=3
		local retry_count=1
                while [ $retry_count -le $retry_num ]
                do
			logger "Rpm Re-Install ... Package \"$line\", retry=$retry_count"
                        rpm -iv --root $NEWROOT "/rpm/${line}.rpm" --nodeps --force && break
                        ((retry_count=retry_count+1))
                done
        done
	logger "Rpm Re-Install ... End"
}


install_rootfs(){
	echo "RPM install runtime system, it will take a long time, please wait ..."
	/img/bin/pic.sh LCM_MSG "System" "Installation"
	echo "[SYSTEM_INSTALL]" > /tmp/mnid.agent.in
	eval install_rpm $TO_TRASH
	sync

	# setup workaround environment
	if [ -f "${USB_MNT}/${MODEL}/setup.sh" ];then
		eval sh ${USB_MNT}/${MODEL}/setup.sh "${USB_MNT}/${MODEL}" $TO_TRASH
	elif [ -f "/${MODEL}/setup.sh" ];then
		eval sh /${MODEL}/setup.sh "/${MODEL}" $TO_TRASH
	fi
	sync

	[ -f $NEWROOT/testrw ] && rm -f $NEWROOT/testrw
	touch $NEWROOT/testrw
	if [ $? -eq 0 ]; then	# if $NEWROOT is still OK
		touch $NEWROOT/etc/.rootfs_rpm
		sync
	fi
	rm -f $NEWROOT/testrw
	umount /rpm
	rm -rf /rpm
	umount $USB_MNT
	rm -rf $USB_MNT


	# set runtime system configure
	echo "Setting runtime system..."
	set_config
	sync

	return 0
}

rpm_fail(){
	logger "Rpm Install ... Fail"
	rm -rf /rpm
	umount $USB_MNT
	rm -rf $USB_MNT

	echo "Can not mount the rpm packages partition."
	/img/bin/pic.sh LCM_MSG "Please Check" "intelligentNAS"
	if [ $TDB -ne 1 ]; then
		echo "[ASSIST][RPM_NOT_FOUND][BLANK][BLANK]" > /tmp/mnid.agent.in
		while [ 1 ];do
			read line < /tmp/mnid.agent.out
			if [ "$line" = "[BLANK]" ]; then
				handle_critical_error
				break
			fi
		done
	fi

	return 1
}

mount_rpm && install_rootfs || rpm_fail
exit $?
