#!/bin/sh
if [ $# -lt 1 ];then
        echo $0 Pri_WAN
        exit 1
fi
                
Pri_IP=$1

. /etc/ha/script/conf.ha

CHK_MD0=`cat /proc/mdstat | grep -c '^md0 : active'`
if [ "${CHK_MD0}" = "0" ];then
	echo "No RAID md0!"
	exit 1
fi

total_haraid_limit=`/img/bin/check_service.sh total_haraid_limit`
total_haraid_limit=`expr ${total_haraid_limit} - 1`

#/img/bin/service stop > /dev/null 2>&1
lsdev=`cat /proc/mdstat | awk "/md[0-${total_haraid_limit}] :/{print \\$1}" | sort`

for dev in $lsdev
do
  DEV_COUNT=`cat /proc/mdstat | awk "/${dev} : /{print NF-4}"`
  DEV_SD=`cat /proc/mdstat | awk "/${dev} : /{for (i=5;i<NF+1;i++){split(\\\$i,dev,\\"[\\");printf \\"/dev/%s \\",dev[1]}}"`
  echo $DEV_COUNT,$DEV_SD
  mount_point=`mount | awk "/^\\/dev\\/${dev} /{print \\\$3}"`
  if [ x${mount_point} != x ];then
    fuser -km ${mount_point}
  fi
  umount -l /dev/${dev}
  if [ x`mount|grep -c "^/dev/${dev} "` = x1 ];then
    echo "Umount native RAID failed, can't be transferred to HA RAID" >> /var/log/ha-error
    exit 1
  fi

  if [ "`mount | grep -c '/sys/kernel/config'`" = "0" ];then
    ${RC_INITIATOR} start
  fi

  ret=`${Export_iSCSI} ${Pri_IP} ${HB_LINE} add ${dev}`

  if [ "$ret" != "1" ];then
    echo "Export iSCSI Block Fail!" >> /var/log/ha-error
    exit 1
  fi

done
exit 0
