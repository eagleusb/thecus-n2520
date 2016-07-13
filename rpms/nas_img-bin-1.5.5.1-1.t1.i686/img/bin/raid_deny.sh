#!/bin/sh
ACT=$1
ha_enable=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ha_enable'"`
RAID_DENY=""
for lun in 0 1 2 3 4 60 61 62 63 64
do 
  raid_status=/tmp/raid${lun}/rss
  if [ -f ${raid_status} ];then 
    raid_name=`cat /tmp/raid${lun}/raid_id`
    if [ `grep -ic Formatting ${raid_status}` -eq 1 ];then 
      RAID_DENY="${RAID_DENY} & ${raid_name}-Formatting"
    elif [ `grep -ic resizing ${raid_status}` -eq 1 ];then 
      RAID_DENY="${RAID_DENY} & ${raid_name}-Expansion"
    elif [ `grep -ic Migrating ${raid_status}` -eq 1 ];then 
      RAID_DENY="${RAID_DENY} & ${raid_name}-Migrating"
    elif [ "${ACT}" = "schedule" -o "${ha_enable}" = "1" ];then
      if [ `grep -ic Recovering ${raid_status}` -eq 1 ];then 
        RAID_DENY="${RAID_DENY} & ${raid_name}-Rebuilding"
      elif [ `grep -ic recovery ${raid_status}` -eq 1 ];then 
        RAID_DENY="${RAID_DENY} & ${raid_name}-Rebuilding"
      elif [ -f /tmp/lns.lock ];then
        RAID_DENY="${RAID_DENY} & ${raid_name}-File System Checking"
      fi
    fi
  fi
done

if [ "${RAID_DENY}" != "" ];then
  echo ${RAID_DENY} | awk '{print substr($0,3,64)}'
  exit 1
fi
exit 0
