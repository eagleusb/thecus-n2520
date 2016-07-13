#!/bin/sh 
##############################################
#  Usage : migrate_raid.sh $md_num
##############################################
mdnum=$1

raid_name="raid$mdnum"
md_name="md$mdnum"
mddisk="/dev/$md_name"
mdname="$md_name"

old_raidconf="/tmp/raid.old"
new_raidconf="/tmp/raid.new"
syslog="/etc/cfg"
if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
  syslog="/syslog"
fi
total_tray=`/img/bin/check_service.sh total_tray` #sysconf.N16000 total_tray=16  thecus_io MAX_TRAY: 16
strdisk=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray') strdisk=sprintf("%s %s2",strdisk,substr($3,6,4))}END{print strdisk}'`
devices="${strdisk}";
strdisk_sys=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray') strdisk=sprintf("%s %s3",strdisk,substr($3,6,4))}END{print strdisk}'`
devices_sys="${strdisk_sys}";
###############################################
#  Save log part
###############################################
syslog="/etc/cfg"
if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
  syslog="/syslog"
fi
save_log="/usr/bin/savelog /etc/cfg/logfile "
hlog_event="raid_migration"
status_path="/var/tmp/${raid_name}"
raid_id=`cat ${status_path}/raid_id`
mig_flag="/var/tmp/migrate/$raid_name/mig_flag"
migsys_flag="/$raid_name/sys/migrate/migsys_flag"
migsys_key_r0="MIGRATE_R0"
##############################################
#  Old RAID level and tray list
##############################################
old_level=`cat /var/tmp/${raid_name}/raid_level`
hlog_old_level="raid${old_level}"
old_level="RAID${old_level}"
old_device=`mdadm -D /dev/md${mdnum} | awk '/active sync/{print substr($7,6,3)}'`
old_count="1"
for device in $old_device
do
  if [ "${device}" != "" ];
  then
    if [ "${old_count}" == "1" ];
    then
      old_disk_tray=`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${device}' /{printf("Tray%s",substr($2,6))}'`
    else
      old_disk_tray="${old_disk_tray},"`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${device}' /{printf("Tray%s",substr($2,6))}'`
    fi
    old_count=$((${old_count}+1))
  fi
done
##############################################
#  New RAID level and tray list
##############################################
new_level=`cat ${new_raidconf} | awk -F' ' '/raid-level/{printf("%s",$2)}'`
hlog_new_level="raid${new_level}"
new_level="RAID${new_level}"
new_device=`cat ${new_raidconf} | awk -F' ' '/device/{print substr($2,6,length($2)-6)}'`
new_count="1"
for device in $new_device
do
  if [ "${device}" != "" ];
  then
    if [ "${new_count}" == "1" ];
    then
      new_disk_tray=`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${device}' /{printf("Tray%s",substr($2,6))}'`
    else
      new_disk_tray="${new_disk_tray},"`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${device}' /{printf("Tray%s",substr($2,6))}'`
    fi
    new_count=$((${new_count}+1))
  fi
done
fail="0"
echo "${raid_id},${old_level},${hlog_old_level},${old_disk_tray},${new_level},${hlog_new_level},${new_disk_tray}"
###############################################
event="/img/bin/logevent/event"
event_mode="Migration"
##############################################

function update_status() {
    ## format parameter 1 : message
    ##        parameter 2 : raid name
    if [ "$1" != "" ] && [ "$2" != "" ]; then

        rss_folder="/var/tmp/$2"
        raidnum_stat="$rss_folder/rss"
        if [ ! -e $rss_folder ];then
            mkdir -p ${rss_folder}
        fi
        echo "$1" > ${raidnum_stat}
    fi
}

function set_migrate_pool() {
  if [ ! -d "/$raid_name/sys/migrate" ];then
    mkdir -p "/$raid_name/sys/migrate"
  fi

  if [ ! -d "/var/tmp/migrate/$raid_name" ];then
    mkdir -p "/var/tmp/migrate/$raid_name"
  fi
}

function backup_superblock() {
  for savedisk in $devices
  do
    /usr/bin/save_super /dev/$savedisk ${syslog}/sbdump.${1}${savedisk}
  done
  
  for savedisk in $devices_sys
  do
    /usr/bin/save_super /dev/$savedisk ${syslog}/sbdump.${1}${savedisk}
  done
}


function umount_all() {
  sh -x /img/bin/stop_volume.sh $mdnum > /tmp/stop_volume.log 2>&1
  if [ $? != 0 ];
  then
    fail=1
  fi
  sync
  mdadm -S ${mddisk}
  if [ $? != 0 ];
  then
    ${event} 997 609 error email "${event_mode}" "${raid_id}"
    ${save_log} "${hlog_event}" "stop"
    fail="1"
  fi
}
################################################
#  Main
################################################
if [ -f "${old_raidconf}" ];
then
  if [ -f "${new_raidconf}" ];
  then
    ${save_log} "${hlog_event}" "start"
    /img/bin/logevent/event 997 403 info email "${raid_id}" "${old_level},${old_disk_tray}" "${new_level},${new_disk_tray}"
    backup_superblock "BM_"
    set_migrate_pool
    ########################################
    #  Stop service 
    ########################################
    sleep 2
    /img/bin/service stop 
    sleep 1
    
    umount_all
    if [ "$fail" = "1" ]
    then
      exit
    fi

    ########################################
    #  Start Migrate
    ########################################
    update_status "Migrating RAID Starting ...." $raid_name
    echo "$migsys_key_r0" > $migsys_flag
    echo "$migsys_key_r0" > $mig_flag
    echo "1" > /var/tmp/raidlock
    sh -x /img/bin/migrate_start.sh $mdnum "${raid_id}" "${old_level},${old_disk_tray}" "${new_level},${new_disk_tray}" "${hlog_old_level},${old_disk_tray},${hlog_new_level},${new_disk_tray}" > /tmp/migrate_start.log 2>&1 &
  fi
fi

