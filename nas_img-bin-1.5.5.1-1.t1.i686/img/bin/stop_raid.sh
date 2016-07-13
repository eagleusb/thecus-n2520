#!/bin/sh
#This script is used for reboot/poweroff

PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

init(){
	. /img/bin/function/stamps.list
    md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
    if [ "${md_list}" == "" ];then
        md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
    fi

	interval=3
}

# Detach encrypted device
stop_encdev(){
	local MDNUM="$1"
	local ENCDEV="`encr_util -g $MDNUM`"
	local RET=1

	while [ "$RET" -ne 0 ];do
		sync
		encr_util -d "$MDNUM"
		RET=$?
		[ "$RET" -eq 0 ] && break
		fuser -k "/dev/$ENCDEV"
		sleep $interval
	done
}

stopMD(){
    local md="$1"
    local use_encrypt="$2"
    count=0
    ret=1

	# detach encrypted volumn before stop RAID.
	[ "$use_encrypt" == "1" ] && stop_encdev "$md"

    while [ "${ret}" != "0" ]
    do
        sync
        mdadm -S /dev/md${md}
        ret="$?"

        if [ "${ret}" == "0" ];then
            break
        else
            fuser -k /dev/md${md}
        fi

        count=$((count+1))
        sleep ${interval}
    done

	return $ret
}

umount_raid(){
    raid="$1"
    count=0
    ret=1

    while [ "${ret}" != "0" ]
    do
        sync
        umount ${raid}
        ret="$?"

        if [ "${ret}" == "0" ];then
            break
        else
            fuser -k ${raid}
        fi

        count=$((count+1))
        sleep ${interval}
    done

	return $ret
}

main(){
    for md in $md_list
    do
        local SMB_DB="/raidsys/$md/smb.db"
        local use_encrypt=`sqlite $SMB_DB "select v from conf where k='encrypt'"`
        umount_raid "/raid${md}"
        umount_raid "/raidsys/${md}"
        stopMD "${md}" "$use_encrypt"
        stopMD "5${md}" "0"
    done

    swapoff /dev/md10
    mdadm -S /dev/md10

	# Stamp finish flag
	touch $STAMP_RAID_STOP
}

init
main
