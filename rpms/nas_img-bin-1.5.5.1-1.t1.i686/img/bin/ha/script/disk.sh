#!/bin/sh
act=$1
disk_name=$2
echo $0 $1 $2 >> /tmp/ha_disk.log

. /img/bin/ha/script/conf.ha
. /img/bin/ha/script/func.ha

lun=`${DEV_MAP} ${HB_LINE} ${ipx3} lun ${disk_name}`
if [ "${lun}" != "" ] && [ "${lun}" != "NO_DEVICE" ];then
  _lodev=`${DEV_MAP} ${HB_LINE} ${ip3} dev ${lun}`
  lodev=`${RAID_UUID} ${disk_name} ${_lodev}`
  if [ "${_lodev}" != "${lodev}" ];then
    if [ "${lodev}" != "" ];then
      lun=`${DEV_MAP} ${HB_LINE} ${ip3} lun ${lodev}`
    else
      /img/bin/logevent/event 338
      exit
    fi
  fi
  monitor_lock=/var/lock/ha_monitor_${lun}
else
  lun=`${DEV_MAP} ${HB_LINE} ${ip3} lun ${disk_name}`
  if [ "${lun}" != "" ] && [ "${lun}" != "NO_DEVICE" ];then
    monitor_lock=/var/lock/ha_monitor_${lun}
  fi
fi

if [ ! -f $monitor_lock ];then
  sleep 3
  if [ ! -f $monitor_lock ];then
    echo "wait rc.ha finished!-$monitor_lock" >> /tmp/ha_disk.log
    exit
  fi
fi 


cat /proc/mdstat > /tmp/mdstat
if [ "${act}" = "add" ];then
  #cat /tmp/mdstat >> /tmp/ha_disk.log 
  if [ "`cat /tmp/mdstat | grep -c "${disk_name}[2-3]\["`" = "2" ];then
    echo "md have 2,exit" >> /tmp/ha_disk.log
    exit
  fi
  
  cat /tmp/mdstat | awk '/md[6-7][0-9]/&&/active/{i=i+NF;j=j+1}END{if (i==j*6){print 0}else{print 1}}' > /tmp/ha_raid_flag
  echo "ha_raid_flag=`cat /tmp/ha_raid_flag`" >> /tmp/ha_disk.log
  
  #check exten
  echo "check exten device" >> /tmp/ha_disk.log
  lun=`${DEV_MAP} ${HB_LINE} ${ipx3} lun ${disk_name}`
  if [ "${lun}" != "" ] && [ "${lun}" != "NO_DEVICE" ];then
    _lodev=`${DEV_MAP} ${HB_LINE} ${ip3} dev ${lun}`
    lodev=`${RAID_UUID} ${disk_name} ${_lodev}`
    if [ "${lodev}" != "" ] && [ "${lodev}" != "NO_DEVICE" ] && [ "${lodev}" != "${disk_name}" ];then
      if [ "${_lodev}" != "${lodev}" ];then
        lun=`${DEV_MAP} ${HB_LINE} ${ip3} lun ${lodev}`
      fi
      echo "lo assemble_by_order ${disk_name} ${lun} ${lodev} START" >> /tmp/ha_disk.log
      assemble_by_order ${disk_name} ${lun} ${lodev}
      echo "lo assemble_by_order ${disk_name} ${lun} ${lodev} END" >> /tmp/ha_disk.log
    fi
  else
    #check local
    echo "check local device" >> /tmp/ha_disk.log
    if [ -f /var/lock/ha_boot ];then
      echo "ha_boot ,exit" >> /tmp/ha_disk.log
      exit
    fi
  
    lun=`${DEV_MAP} ${HB_LINE} ${ip3} lun ${disk_name}`
    if [ "${lun}" != "" ] && [ "${lun}" != "NO_DEVICE" ];then
      exdev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
      exdev=`${RAID_UUID} ${disk_name} ${exdev}`
      if [ "${exdev}" != "" ] && [ "${exdev}" != "NO_DEVICE" ] && [ "${exdev}" != "${disk_name}" ];then
        echo "ex assemble_by_order ${disk_name} ${lun} ${exdev} START" >> /tmp/ha_disk.log
        assemble_by_order ${disk_name} ${lun} ${exdev}
        echo "ex assemble_by_order ${disk_name} ${lun} ${exdev} END" >> /tmp/ha_disk.log
      fi
    fi
  fi
elif [ "${act}" = "remove" ];then  
  lun=`cat /tmp/mdstat | awk "/^md6[0-9] /&&/ ${disk_name}2\[/{print substr(\\$1,4)}"`
  if [ "${lun}" != "" ];then
    mdadm /dev/md6${lun} --fail /dev/${disk_name}2
    sleep 3
    mdadm /dev/md6${lun} --remove /dev/${disk_name}2   
    mdadm /dev/md7${lun} --fail /dev/${disk_name}3
    sleep 3
    mdadm /dev/md7${lun} --remove /dev/${disk_name}3
  else
    lun=`cat /tmp/mdstat | awk "/^md7[0-9] /&&/ ${disk_name}3\[/{print substr(\\$1,4)}"`
    if [ "${lun}" != "" ];then
      mdadm /dev/md7${lun} --fail /dev/${disk_name}3
      sleep 3
      mdadm /dev/md7${lun} --remove /dev/${disk_name}3
    fi
  fi
  
  if [ "${lun}" = "" ];then 
    lun=`${DEV_MAP} ${HB_LINE} ${ipx3} lun ${disk_name}`
  fi

  if [ "${lun}" != "" ] && [ "${lun}" != "NO_DEVICE" ];then
    dev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
    if [ "$?" = "0" ] && [ "${dev}" = "${disk_name}" ];then
      ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop s 
    fi
  fi
fi
