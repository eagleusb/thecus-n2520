#!/bin/sh
##############################################
# Format : mksys_md.sh $sysdisk_count $sysdisks
# Used for create or assemble sys raid
##############################################
mdadm="/sbin/mdadm"
if [ $3 -ge 60 ] || [ $3 -ge 10 ];then
  sysmdnum=`expr $3 + 10`
else
  sysmdnum=`expr $3 + 50`
fi
sysmd="/dev/md$sysmdnum"
sleep_sec=2
sysdisk_count=$1
sysdisks=$2
###check sys
force_assemble="True"
## call to get disk UUID
get_disk_uuid() {
  UUID=`mdadm --examine ${1} 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/UUID/ && UUID==""){UUID=$2}if($1~/Raid Level/){TYPE=$2}}END{if(TYPE!="" && UUID!="")print TYPE,UUID}'`
  echo ${UUID}
}

get_hours() {
  HOURS=0
#  Mon Oct 18 18:32:59 CST 2010
  YEAR=`echo -n $1 | tail -c 4`
  YEAR=`expr $YEAR - 1970`
  WEEK=`echo $1 | awk '{print $1}'`
  MONTH=`echo $1 | awk '{print $2}'`
  DAY=`echo $1 | awk '{print $3}'`
  HOUR=`echo $1 | awk '{print $3}'`
  
  HOURS=`expr $HOURS + 24 \* $DAY - 24`
  case "$MONTH"
  in
  Jan)
    HOURS=`expr $HOURS + 24 \* 30 \* 0`
    ;;
  Feb)
    HOURS=`expr $HOURS + 24 \* 30 \* 1`
    ;;
  Mar)
    HOURS=`expr $HOURS + 24 \* 30 \* 2`
    ;;
  Apr)
    HOURS=`expr $HOURS + 24 \* 30 \* 3`
    ;;
  May)
    HOURS=`expr $HOURS + 24 \* 30 \* 4`
    ;;
  Jun)
    HOURS=`expr $HOURS + 24 \* 30 \* 5`
    ;;
  Jul)
    HOURS=`expr $HOURS + 24 \* 30 \* 6`
    ;;
  Aug)
    HOURS=`expr $HOURS + 24 \* 30 \* 7`
    ;;
  Sep)
    HOURS=`expr $HOURS + 24 \* 30 \* 8`
    ;;
  Oct)
    HOURS=`expr $HOURS + 24 \* 30 \* 9`
    ;;
  Nov)
    HOURS=`expr $HOURS + 24 \* 30 \* 10`
    ;;
  Dec)
    HOURS=`expr $HOURS + 24 \* 30 \* 11`
    ;;
  esac
  
  HOURS=`expr $HOURS + 24 \* 30 \* 12 \* $YEAR`
  
  echo ${HOURS}
}

get_disk_update_time() {
  DATE=`mdadm --examine ${1} 2>/dev/null | grep 'Update Time' | awk -F' : ' '{print $2}'`
  hours=`get_hours "$DATE"`
  echo ${hours}
}

get_disk_eventid() {
  EVENTID=`mdadm --examine ${1} 2>/dev/null | grep Events | awk '{print $3}'`
  echo ${EVENTID}
}

get_raid_uuid() {
  UUID=`mdadm -D ${1} 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/UUID/ && UUID==""){UUID=$2}if($1~/Raid Level/){TYPE=$2}}END{if(TYPE!="" && UUID!="")print UUID}'`
  echo ${UUID}
}

check_force_assemble() {
  force_assemble="True"
  lastest_update_time=0
  min_event_id=0
  for i in $1
  do
    if [ $lastest_update_time -eq 0 ];then
      lastest_update_time=`get_disk_update_time ${i}`
      min_event_id=`get_disk_eventid ${i}`
    fi
    current_update_time=`get_disk_update_time ${i}`
    current_event_id=`get_disk_eventid ${i}`
    if [ $lastest_update_time -gt $current_update_time ];then
      if [ `expr $lastest_update_time - $current_update_time` -ge 12 ];then
        force_assemble="False"
      fi
      lastest_update_time= $current_update_time
    elif [ $current_update_time -gt $lastest_update_time ];then
      if [ `expr $current_update_time - $lastest_update_time` -ge 12 ];then
        force_assemble="False"
      fi
    fi
    if [ $min_event_id -gt $current_event_id ];then
      if [ `expr $lastest_update_time - $current_event_id` -ge 50 ];then
        force_assemble="False"
      fi
      min_event_id= $current_event_id
    elif [ $current_event_id -gt $min_event_id ];then
      if [ `expr $current_event_id - $min_event_id` -ge 50 ];then
        force_assemble="False"
      fi
    fi
  done
}

echo "1" > /var/tmp/raidlock

${mdadm} -D ${sysmd}
if [ "$?" = "0" ];then
  #raid sys exist...error exit
  exit
else
  check_force_assemble ${sysdisks}
  for i in ${sysdisks}
  do
    uuid=`get_disk_uuid ${i}`
    break
  done

  if [ "${uuid}" = "" ];then
    if [ "${force_assemble}" = "True" ];then
      sysraid="${mdadm} -C ${sysmd} --assume-clean -f -R -l1 -n$sysdisk_count $sysdisks;/sbin/mkfs.ext4 -t ext4 -m 0 -b 4096 $sysmd;chmod 600 ${sysmd}"
    else
      sysraid="${mdadm} -C ${sysmd} --assume-clean -R -l1 -n$sysdisk_count $sysdisks;/sbin/mkfs.ext4 -t ext4 -m 0 -b 4096 $sysmd;chmod 600 ${sysmd}"
    fi
  else
    if [ "${force_assemble}" = "True" ];then
      sysraid="${mdadm} -A -R -f ${sysmd} $sysdisks;"
    else
      sysraid="${mdadm} -A -R ${sysmd} $sysdisks;"
    fi
  fi
  
  echo "sysraid=$sysraid" > /tmp/mksys_md$sysmdnum.tmp

  eval "${sysraid}"

  inraid_list=`${mdadm} -D $sysmd | awk '/active sync/{print $7}'`
  inraid_list2=`${mdadm} -D $sysmd | awk '/rebuilding/{print $7}'`
  inraid_list="$inraid_list $inraid_list2 missing"
  for new_hdd in $sysdisks
  do
    match_pos=` echo $inraid_list |   awk '{match ($0, "'$new_hdd'" ); print RSTART}' `
    if [ "$match_pos" = "0" ];
    then
      addin_hdd="$addin_hdd $new_hdd"
    fi
  done
  if [ "${addin_hdd}" != "" ];then
    sysraid="${mdadm} -A ${sysmd} $addin_hdd;"
    eval "${sysraid}"
  fi

  mkdir -p /raidsys/$3
  mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro ${sysmd} /raidsys/$3
  if [ "$?" != "0" ];then
    /img/bin/logevent/event 997 819 error email ${sysmd}
    /img/bin/pic.sh LCM_MSG "Check FS," "Please wait."
    /sbin/e2fsck -fy ${sysmd}
    mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro ${sysmd} /raidsys/$3
    if [ "$?" != "0" ];then
      /img/bin/logevent/event 997 820 error email ${sysmd}
      /img/bin/pic.sh LCM_MSG "Repair FS," "Failed!"
    else
      /img/bin/logevent/event 997 488 info email ${sysmd}
      /img/bin/pic.sh LCM_MSG "Repair FS," "Success!"
    fi
  fi
  
  if [ ! $? -eq 0 ];then
    rm -rf /raidsys/$3
    mdadm -S ${sysmd}
  fi

fi

sync

echo "0" > /var/tmp/raidlock
