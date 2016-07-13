#!/bin/sh
##############################################
#
# This is on line migration raid Script for RAID 50&60
# Usage : nest_migrate_raid_online.sh $md_num
#
##############################################
mdnum=$1
nesmdnum_a=`expr $mdnum + $mdnum + 30`
nesmdnum_b=`expr $mdnum + $mdnum + 31`
restart_flag=$2
mdadm="/sbin/mdadm"
old_cfg_a="/tmp/raid_a.old"
old_cfg_b="/tmp/raid_b.old"
new_cfg_a="/tmp/raid_a.new"
new_cfg_b="/tmp/raid_b.new"
mddisk="/dev/md$mdnum"
mddisk_a="/dev/md$nesmdnum_a"
mddisk_b="/dev/md$nesmdnum_b"
mdname="md$mdnum"
raid_name="raid$mdnum"
swapdisk="/dev/md10"
sysmdnum=`expr $mdnum + 50`
sysdisk="/dev/md$sysmdnum"
gdisk="/usr/sbin/gdisk"
lock_flag="/var/tmp/raidlock"
syslog="/etc/cfg"
if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
  syslog="/syslog"
fi
save_log="/usr/bin/savelog /etc/cfg/logfile "
hlog_event="raid_migration"
event="/img/bin/logevent/event"
total_tray=`/img/bin/check_service.sh total_tray` #sysconf.N16000 total_tray=16  thecus_io MAX_TRAY: 16
strdisk=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147))  strdisk=sprintf("%s %s2",strdisk,substr($3,6,4))}END{print strdisk}'`
devices="${strdisk}";
strdisk_sys=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147))  strdisk=sprintf("%s %s3",strdisk,substr($3,6,4))}END{print strdisk}'`
devices_sys="${strdisk_sys}";


mig_flag="/var/tmp/migrate/$raid_name/mig_flag"
migsys_flag="/$raid_name/sys/migrate/migsys_flag"
migsys_key_r1="MIGRATE_R1"
migsys_key_r5="MIGRATE_R5"
migsys_key_recovery_r5="RECOVERY_R5"
small_hdd_a=""
small_hdd_b=""
small_hdd_byte_a="0"
small_hdd_byte_b="0"
addin_hdd_a=""
addin_hdd_b=""
sleep_sec=2
swap_size=2



###################################################
#
# Basic Raid Conf Check
#
###################################################

if [ -f $old_cfg_a ];
then
  old_mddisk_a=`cat $old_cfg_a | grep raiddev | cut -f3`
  if [ "$mddisk_a" = "$old_mddisk_a" ];
  then
    old_level_a=`cat $old_cfg_a | grep raid-level | cut -f3`
    old_hddlist_a=`cat $old_cfg_a | awk '/device/{print $2}' | cut -d/ -f3 | cut -d2 -f1`
  else
    echo "mdnum dosen't match."
    exit
  fi
else
  echo "old raid conf dosen't exist."
fi

if [ -f $old_cfg_b ];
then
  old_mddisk_b=`cat $old_cfg_b | grep raiddev | cut -f3`
  if [ "$mddisk_b" = "$old_mddisk_b" ];
  then
    old_level_b=`cat $old_cfg_b | grep raid-level | cut -f3`
    old_hddlist_b=`cat $old_cfg_b | awk '/device/{print $2}' | cut -d/ -f3 | cut -d2 -f1`
  else
    echo "mdnum dosen't match."
    exit
  fi
else
  echo "old raid conf dosen't exist."
fi

if [ -f $new_cfg_a ];
then
  new_mddisk_a=`cat $new_cfg_a | grep raiddev | cut -f3`
  if [ "$mddisk_a" = "$new_mddisk_a" ];
  then
    new_level_a=`cat $new_cfg_a | grep raid-level | cut -f3`
    new_disknum_a=`cat $new_cfg_a | grep nr-raid-disks | cut -f3`
    new_hddlist_a=`cat $new_cfg_a | awk '/device/{print $2}' | cut -d/ -f3 |cut -d2 -f1`
    new_chunk_a=`cat $new_cfg_a | grep chunk-size | cut -f3`
  else
    echo "old/new mdnum dosen't match."
    exit
  fi
else
  echo "new raid conf dosen't exist."
fi

if [ -f $new_cfg_b ];
then
  new_mddisk_b=`cat $new_cfg_b | grep raiddev | cut -f3`
  if [ "$mddisk_b" = "$new_mddisk_b" ];
  then
    new_level_b=`cat $new_cfg_b | grep raid-level | cut -f3`
    new_disknum_b=`cat $new_cfg_b | grep nr-raid-disks | cut -f3`
    new_hddlist_b=`cat $new_cfg_b | awk '/device/{print $2}' | cut -d/ -f3 |cut -d2 -f1`
    new_chunk_b=`cat $new_cfg_b | grep chunk-size | cut -f3`
  else
    echo "old/new mdnum dosen't match."
    exit
  fi
else
  echo "new raid conf dosen't exist."
fi

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

function led_light() {
  if [ "$1" != "" ] && [ "$2" != "" ]
  then
    echo "S_LED $1 $2" > /proc/thecus_io
  fi
}


## inetrface to drive thecus_io
function drive_thecus_io() {
    #echo "$1" > ${thecus_io} 

    echo "for Show LED: BUSY or Fail"
    led_light ${1} ${2}
}

function led_busy() {
        if [ ! "$1" = "" ]
        then
                cmd="Busy"
                act="${1}"
                drive_thecus_io "${cmd}" "${1}"
        fi
}

function check_healthy() {
  if [ $1 = "" ] || [ ! -f "/var/tmp/$1/rss" ];
  then
    echo "Raid dosen't Exist!!"
    exit
  else
    echo "Checking RSS..."
    raid_status=`cat /var/tmp/$1/rss`
    raid_id=`cat /var/tmp/$1//raid_id`
    if [ "$raid_status" = "Healthy" ];
    then
      #echo "Healthy"
      return 0
    else
      #echo "Not Healthy"
      exit
    fi
  fi
}

function check_size_r5() {
  # get old smallest disk and size
  for old_hdd in $old_hddlist_a
  do
    disk_size=`gdisk -l "/dev/"$old_hdd | grep "Disk /dev/$old_hdd" | cut -d" " -f3`
    if [ $small_hdd_byte_a = 0 ] || [ `echo $small_hdd_byte_a $disk_size | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];
    then
      small_hdd_byte_a=$disk_size
      small_hdd_a=$old_hdd
    fi
  done
  echo "Smallest Disk:$small_hdd_a Size:$small_hdd_byte_a"

  for new_hdd in $addin_hdd_a
  do
    new_disk_size=`gdisk -l "/dev/"$new_hdd | grep "Disk /dev/$new_hdd" | cut -d" " -f3`
    echo "New Disk $new_hdd Size:$new_disk_size"
    if [ `echo $small_hdd_byte_a $new_disk_size | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];
    then
      echo "New Disk $new_hdd Smaller than $small_hdd_a"
      echo "Stop Migration"
      exit
    fi
  done
  
  for old_hdd in $old_hddlist_b
  do
    disk_size=`gdisk -l "/dev/"$old_hdd | grep "Disk /dev/$old_hdd" | cut -d" " -f3`
    if [ $small_hdd_byte_b = 0 ] || [ `echo $small_hdd_byte_b $disk_size | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];
    then
      small_hdd_byte_b=$disk_size
      small_hdd_b=$old_hdd
    fi
  done
  echo "Smallest Disk:$small_hdd_b Size:$small_hdd_byte_b"

  for new_hdd in $addin_hdd_b
  do
    new_disk_size=`gdisk -l "/dev/"$new_hdd | grep "Disk /dev/$new_hdd" | cut -d" " -f3`
    echo "New Disk $new_hdd Size:$new_disk_size"
    if [ `echo $small_hdd_byte_b $new_disk_size | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];
    then
      echo "New Disk $new_hdd Smaller than $small_hdd_b"
      echo "Stop Migration"
      exit
    fi
  done
}

function get_new_hdd() {
  for new_hdd in $new_hddlist_a
    do
      match_pos=` echo $old_hddlist_a |   awk '{match ($0, "'$new_hdd'" ); print RSTART}' `
      if [ "$match_pos" = "0" ];
      then
        addin_hdd_a="$addin_hdd_a $new_hdd"
      fi
  done
  for new_hdd in $new_hddlist_b
    do
      match_pos=` echo $old_hddlist_b |   awk '{match ($0, "'$new_hdd'" ); print RSTART}' `
      if [ "$match_pos" = "0" ];
      then
        addin_hdd_b="$addin_hdd_b $new_hdd"
      fi
  done
  echo "$addin_hdd_a" "$addin_hdd_b"> /$raid_name/sys/migrate/addin_hdd
}

function gdisk_hdd() {
  if [ "$addin_hdd_a $addin_hdd_b" != "" ];
  then
    for new_hdd in $addin_hdd_a $addin_hdd_b
    do
      /img/bin/init_disk $new_hdd
      device="/dev/$new_hdd"
      sleep 1
      sync
    done
  fi
}

function make_sys() {
  if [ "$addin_hdd_a $addin_hdd_b" != "" ];
  then
    for new_hdd in $addin_hdd_a $addin_hdd_b
      do
      sys_partition="/dev/${new_hdd}3"
      ${mdadm} $sysdisk -a ${sys_partition}
    done
  fi
}

function make_swap() {
  if [ "$addin_hdd_a $addin_hdd_b" != "" ];
  then
    for new_hdd in $addin_hdd_a $addin_hdd_b
      do
      swap_partition="/dev/${new_hdd}1"
      ${mdadm} $swapdisk -a ${swap_partition}
    done
  fi
}

function wait_swap() {
  ## Monitor RAID stat until RAID build finished
  swap_build=`/bin/cat /proc/mdstat | sed -n '/^md10 /,/^md[0-9]/p' | awk '/recovery/||/resync/||/reshape/{if (NR==3) print 1; else print 0;}'`
  while [ "${swap_build}" = "1" ]
  do
    sleep ${sleep_sec}
    swap_build=`/bin/cat /proc/mdstat | sed -n '/^md10 /,/^md[0-9]/p' | awk '/recovery/||/resync/||/reshape/{if (NR==3) print 1; else print 0;}'`
  done

}

function set_sysflag_r5(){
  if [ -d "/$raid_name/sys/migrate" ];then
    rm -r "/$raid_name/sys/migrate"
    mkdir -p "/$raid_name/sys/migrate"
  fi
  echo "$migsys_key_recovery_r5" > "$migsys_flag"
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

function set_migrate_pool() {
  if [ ! -d "/$raid_name/sys/migrate" ];then
    mkdir -p "/$raid_name/sys/migrate"
  fi

  if [ ! -d "/var/tmp/migrate/$raid_name" ];then
    mkdir -p "/var/tmp/migrate/$raid_name"
  fi
}

function migrate_raidlock() {
  echo "1" > "$lock_flag"
}

function migrate_raidunlock() {
  echo "0" > "$lock_flag"
}

function get_disk_tray(){
  old_count="1"
  for old_disk in $old_hddlist_a $old_hddlist_b
  do
    if [ "${old_disk}" != "" ];
    then
      if [ "${old_count}" = "1" ];
      then
        old_disk_tray=`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${old_disk}' /{printf("Tray%s",substr($2,6))}'`
      else
        old_disk_tray="${old_disk_tray},"`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${old_disk}' /{printf("Tray%s",substr($2,6))}'`
      fi
      old_count=$((${old_count}+1))
    fi
  done

  new_count="1"
  for new_disk in $new_hddlist_a $new_hddlist_b
  do
    if [ "${new_disk}" != "" ];
    then
      if [ "${new_count}" = "1" ];
      then
        new_disk_tray=`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${new_disk}' /{printf("Tray%s",substr($2,6))}'`
      else
        new_disk_tray="${new_disk_tray},"`cat /proc/scsi/scsi | awk -F' ' '/Disk:'${new_disk}' /{printf("Tray%s",substr($2,6))}'`
      fi
      new_count=$((${new_count}+1))
    fi
  done

  echo $new_disk_tray > /$raid_name/sys/migrate/new_disk_tray
  echo $old_disk_tray > /$raid_name/sys/migrate/old_disk_tray

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

function nest_migrate_r5_restart(){
  addin_hdd=`cat /$raid_name/sys/migrate/addin_hdd`
  echo 20000 > /proc/sys/dev/raid/speed_limit_min

  echo "Make Swap."
  make_swap
  make_sys
  wait_swap
  echo 1000 > /proc/sys/dev/raid/speed_limit_min
  backup_superblock "AM_"
  ${event} 997 404 info email "${raid_id}" "RAID${old_level_a}" "RAID${new_level_a}"
  rm $migsys_flag
  rm $mig_flag
  
}


function nest_migrate_mdadm(){
  echo "Nest Migrate by mdadm"
  check_healthy "$raid_name"
  update_status "Migrating RAID ..." $raid_name
  #migrate data folder
  set_migrate_pool
  ########################################
  #  Stop service
  ########################################
  sleep 2
  /img/bin/service stop
  sleep 1

  #hdd_list to disk_tray
  get_disk_tray
  
  ${save_log} "${hlog_event}" "start"
  ${event} 997 403 info email "${raid_id}" "RAID${old_level_a},${old_disk_tray}" "RAID${new_level_a},${new_disk_tray}"
  backup_superblock "BM_"

  #addin_hdd
  get_new_hdd
  echo "Got New HDD List:$addin_hdd_a $addin_hdd_b"
  umount_all

  check_size_r5
  echo "$migsys_key_r5" > $migsys_flag
  echo "$migsys_key_r5" > $mig_flag

  gdisk_hdd
  echo 20000 > /proc/sys/dev/raid/speed_limit_min

  for new_hdd in $addin_hdd_a
  do
    add_list_a="$add_list_a /dev/${new_hdd}2"
  done
  ${mdadm} --add ${mddisk_a} $add_list_a
  
  for new_hdd in $addin_hdd_b
  do
    add_list_b="$add_list_b /dev/${new_hdd}2"
  done
  ${mdadm} --add ${mddisk_b} $add_list_b
  echo "$migsys_key_recovery_r5" > $mig_flag
  set_sysflag_r5
  ${mdadm} --grow ${mddisk_a} --level=$new_level_a --raid-disk=$new_disknum_a
  ${mdadm} --grow ${mddisk_b} --level=$new_level_b --raid-disk=$new_disknum_b

  echo "Make Swap."
  make_swap
  make_sys
  wait_swap
  ${mdadm} -A ${mddisk} -U devicesize ${mddisk_a} ${mddisk_b}
  echo 1000 > /proc/sys/dev/raid/speed_limit_min
  backup_superblock "AM_"
  ${event} 997 404 info email "${raid_id}" "RAID${old_level_a}" "RAID${new_level_a}"
  rm $migsys_flag
  rm $mig_flag
  
  sh -x /img/bin/start_volume.sh $mdnum > /tmp/start_volume.tmp 2>&1
  ################################################
  #       Start service
  ################################################
  /img/bin/service start
}

migrate_raidlock
if [ "$restart_flag" = "restart" ];then
  nest_migrate_r5_restart
else
  nest_migrate_mdadm
fi
migrate_raidunlock
exit

