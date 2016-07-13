#!/bin/sh -x
##############################################
#  Usage : migrate_start.sh $md_num
##############################################
mdnum=$1
md_name="md$mdnum"
mddisk="/dev/$md_name"
mdadm="/sbin/mdadm"
raid_name="raid$mdnum"
swapdisk="/dev/md10"
sysmdnum=`expr $mdnum + 50`
sysdisk="/dev/md$sysmdnum"
old_cfg="/tmp/raid.old"
new_cfg="/tmp/raid.new"
recoveryfile="/tmp/recovery.bin"
raid_id=$2
old_value=$3
new_value=$4
hlog_value=$5
save_log="/usr/bin/savelog /etc/cfg/logfile "
hlog_event="raid_migration"
event="/img/bin/logevent/event"
event_mode="Migration"
mig_flag="/var/tmp/migrate/$raid_name/mig_flag"
migsys_flag="/$raid_name/sys/migrate/migsys_flag"
total_tray=`/img/bin/check_service.sh total_tray` #sysconf.N16000 total_tray=16  thecus_io MAX_TRAY: 16
strdisk=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147)) strdisk=sprintf("%s %s2",strdisk,substr($3,6,4))}END{print strdisk}'`
devices="${strdisk}"
strdisk_sys=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147)) strdisk=sprintf("%s %s3",strdisk,substr($3,6,4))}END{print strdisk}'`
devices_sys="${strdisk_sys}";

syslog="/etc/cfg"
if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
  syslog="/syslog"
fi

if [ -f $old_cfg ];
then
  old_mddisk=`cat $old_cfg | grep raiddev | cut -f3`
  if [ "$mddisk" = "$old_mddisk" ];
  then
    old_level=`cat $old_cfg | grep raid-level | cut -f3`
    old_hddlist=`cat $old_cfg | awk '/device/{print $2}' | cut -d/ -f3 | cut -d2 -f1`
  else
    echo "mdnum dosen't match."
    exit
  fi
else
  echo "old raid conf dosen't exist."
fi

if [ -f $new_cfg ];
then
  new_mddisk=`cat $new_cfg | grep raiddev | cut -f3`
  if [ "$mddisk" = "$new_mddisk" ];
  then
    new_level=`cat $new_cfg | grep raid-level | cut -f3`
    new_disknum=`cat $new_cfg | grep nr-raid-disks | cut -f3`
    new_hddlist=`cat $new_cfg | awk '/device/{print $2}' | cut -d/ -f3 |cut -d2 -f1`
    new_chunk=`cat $new_cfg | grep chunk-size | cut -f3`
  else
    echo "old/new mdnum dosen't match."
    exit
  fi
else
  echo "new raid conf dosen't exist."
fi

## call to get disk UUID
get_uuid() {
        UUID=`mdadm -D /dev/${1} 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/UUID/ && UUID==""){UUID=$2}if($1~/Raid Level/){TYPE=$2}}END{if(TYPE!="" && UUID!="")print TYPE,UUID}'`
        echo ${UUID}
}

function get_disk_tray(){
  old_count="1"
  for old_disk in $old_hddlist
  do
    if [ "${old_disk}" != "" ];
    then
      if [ "${old_count}" == "1" ];
      then
        old_disk_tray=`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${old_disk}'/{printf("Tray%s",substr($2,6))}'`
      else
        old_disk_tray="${old_disk_tray},"`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${old_disk}'/{printf("Tray%s",substr($2,6))}'`
      fi
      old_count=$((${old_count}+1))
    fi
  done

  new_count="1"
  for new_disk in $new_hddlist
  do
    if [ "${new_disk}" != "" ];
    then
      if [ "${new_count}" == "1" ];
      then
        new_disk_tray=`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${new_disk}'/{printf("Tray%s",substr($2,6))}'`
      else
        new_disk_tray="${new_disk_tray},"`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${new_disk}'/{printf("Tray%s",substr($2,6))}'`
      fi
      new_count=$((${new_count}+1))
    fi
  done

}

function get_new_hdd() {
  for new_hdd in $new_hddlist
    do
      match_pos=` echo $old_hddlist |   awk '{match ($0, "'$new_hdd'" ); print RSTART}' `
      if [ "$match_pos" = "0" ];
      then
        addin_hdd="$addin_hdd $new_hdd"
      fi
  done
}

function make_sys() {
  if [ "$addin_hdd" != "" ];
  then
    for new_hdd in $addin_hdd
      do
      sys_partition="/dev/${new_hdd}3"
      ${mdadm} $sysdisk -a ${sys_partition}
    done
  fi
}

function make_swap() {
  if [ "$addin_hdd" != "" ];
  then
    for new_hdd in $addin_hdd
      do
      swap_partition="/dev/${new_hdd}1"
      ${mdadm} $swapdisk -a ${swap_partition}
    done
  fi
}

function wait_swap() {
  swap_build=`/bin/cat /proc/mdstat |sed -n '/^md10 /,/^md[0-9]/p' | awk '/recovery/||/resync/{if (NR>4) print 1; else print 0;}'`
  while [ "${swap_build}" = "1" ]
  do
    sleep ${sleep_sec}
    swap_build=`/bin/cat /proc/mdstat |sed -n '/^md10 /,/^md[0-9]/p' | awk '/recovery/||/resync/{if (NR>4) print 1; else print 0;}'`
  done
}

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
sleep 10
mknod ${mddisk} b 9 $mdnum
update_status "Migrating RAID ...." $raid_name
echo "1" > /var/tmp/raidlock
/img/bin/raidreconf -o "$old_cfg" -n "$new_cfg" -m "$mddisk" >/tmp/migration.log 2>&1
if [ $? != 0 ];
then
  ${event} 997 635 error email "${event_mode}"
  ${save_log} "${hlog_event}" "fail"
  update_status "Migrating Fail!" $raid_name
  fail=1
  exit
fi

uuid=`get_uuid ${md_name}`
echo "${uuid}" > /$raid_name/sys/uuid
get_disk_tray
get_new_hdd
make_swap
make_sys
wait_swap

sh -x /img/bin/start_volume.sh $mdnum > /tmp/start_volume.tmp 2>&1
if [ $? != 0 ];
then
  fail=1
fi

################################################
#       Start service
################################################
/img/bin/service start

echo "0" > /var/tmp/raidlock
if [ "${fail}" == "0" ];
then
  ${save_log} "${hlog_event}" "success"
else
  ${save_log} "${hlog_event}" "fail"
fi
${event} 997 404 info email "${raid_id}" "${old_value}" "${new_value}"
backup_superblock "AM_"
rm $migsys_flag
rm $mig_flag
