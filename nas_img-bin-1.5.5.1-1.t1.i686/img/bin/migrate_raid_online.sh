#!/bin/sh
##############################################
#
# This is on line migration raid Script
# Usage : migrate_raid_online.sh $md_num
#
##############################################
mdnum=$1
restart_flag=$2
mdadm="/sbin/mdadm"
old_cfg="/tmp/raid.old"
new_cfg="/tmp/raid.new"
mddisk="/dev/md$mdnum"
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
strdisk=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147)) strdisk=sprintf("%s %s2",strdisk,substr($3,6,4))}END{print strdisk}'`
devices="${strdisk}";
strdisk_sys=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147)) strdisk=sprintf("%s %s3",strdisk,substr($3,6,4))}END{print strdisk}'`
devices_sys="${strdisk_sys}";
ui_opt_unlock="/tmp/ui_opt_unlock"

mig_flag="/var/tmp/migrate/$raid_name/mig_flag"
migsys_flag="/$raid_name/sys/migrate/migsys_flag"
migsys_key_r1="MIGRATE_R1"
migsys_key_r5="MIGRATE_R5"
migsys_key_recovery_r5="RECOVERY_R5"
small_hdd=""
small_hdd_byte="0"
addin_hdd=""
sleep_sec=2
swap_size=2



###################################################
#
# Basic Raid Conf Check
#
###################################################

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
    return 1
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
      return 1
    fi
  fi
}

function check_size_r5() {
  # get old smallest disk and size
  for old_hdd in $old_hddlist
  do
    disk_size=$((`gdisk -l "/dev/"$old_hdd | grep "Disk /dev/$old_hdd" | cut -d" " -f3`/2/1024/1024))
    if [ $small_hdd_byte = 0 ] || [ `echo $small_hdd_byte $disk_size | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];
    then
      small_hdd_byte=$disk_size
      small_hdd=$old_hdd
    fi
  done

  echo "Smallest Disk:$small_hdd Size:$small_hdd_byte"

  for new_hdd in $addin_hdd
  do
    new_disk_size=$((`gdisk -l "/dev/"$new_hdd | grep "Disk /dev/$new_hdd" | cut -d" " -f3`/2/1024/1024))
    echo "New Disk $new_hdd Size:$new_disk_size"
    if [ `echo $small_hdd_byte $new_disk_size | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];
    then
      echo "New Disk $new_hdd Smaller than $small_hdd"
      echo "Stop Migration"
      return 1
    fi
  done
}

function check_size_r1() {
  old_mdsize=$((`gdisk -l $mddisk | grep $mddisk | cut -d" " -f3`/2/1024/1024))
  echo "Old MdDisk Size:$old_mdsize."

  for new_hdd in $addin_hdd
  do
    new_disk_size=$((`gdisk -l "/dev/"$new_hdd | grep "Disk /dev/$new_hdd" | cut -d" " -f3`/2/1024/1024))
    echo "New Disk $new_hdd Size:$new_disk_size"
    if [ $small_hdd_byte = 0 ] || [ `echo $new_disk_size $small_hdd_byte | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];then
      small_hdd_byte=$new_disk_size
      small_hdd=$new_hdd
    fi
  done

  if [ "$new_level" = "5" ];then
    new_mdsize=$(((`echo ${small_hdd_byte}| awk '{print int($1)}'`-${swap_size})*(${new_disknum}-1)))
    echo "new_mdsize:$new_mdsize"
  elif  [ "$new_level" = "6" ];then
    new_mdsize=$(((`echo ${small_hdd_byte}| awk '{print int($1)}'`-${swap_size})*(${new_disknum}-2)))
    echo "new_mdsize:$new_mdsize"
  fi

  if [ `echo $old_mdsize $new_mdsize | awk '{if ($1>$2) print 1; else print 0}'` -gt 0 ];then
    echo "New Md Size Smaller than Old one"
    return 1
  fi 

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
  echo "$addin_hdd" > /$raid_name/sys/migrate/addin_hdd
}


function gdisk_hdd() {
  if [ "$addin_hdd" != "" ];
  then
    for new_hdd in $addin_hdd
    do
      /img/bin/init_disk.sh $new_hdd
      device="/dev/$new_hdd"
      sleep 1
      sync
    done
  fi
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
  ## Monitor RAID stat until RAID build finished
  swap_build=`/bin/cat /proc/mdstat | sed -n '/^md10 /,/^md[0-9]/p' | awk '/recovery/||/resync/||/reshape/{if (NR==3) print 1; else print 0;}'`
  while [ "${swap_build}" = "1" ]
  do
    sleep ${sleep_sec}
    swap_build=`/bin/cat /proc/mdstat | sed -n '/^md10 /,/^md[0-9]/p' | awk '/recovery/||/resync/||/reshape/{if (NR==3) print 1; else print 0;}'`
  done

}

function wait_data() {
  ## Monitor RAID stat until RAID build finished
  data_build=`/bin/cat /proc/mdstat | sed -n '/^md[0-9] /,/^md[0-9]/p' | awk '/recovery/||/resync/||/reshape/{if (NR==3) print 1; else print 0;}'`
  while [ "${data_build}" = "1" ]
  do
    sleep ${sleep_sec}
    data_build=`/bin/cat /proc/mdstat | sed -n '/^md[0-9] /,/^md[0-9]/p' | awk '/recovery/||/resync/||/reshape/{if (NR==3) print 1; else print 0;}'`
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

function get_spare_disk(){
  spare_list=`${mdadm} -D $mddisk | awk '/spare/{print $6}'`
  echo "$spare_list" > /$raid_name/sys/migrate/migsys_spare_list
}

function get_disk_tray(){
  old_count="1"
  for old_disk in $old_hddlist
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
  for new_disk in $new_hddlist
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


function migrate_r5_restart(){
  addin_hdd=`cat /$raid_name/sys/migrate/addin_hdd`
  spare_list=`cat /$raid_name/sys/migrate/migsys_spare_list`
  echo 20000 > /proc/sys/dev/raid/speed_limit_min

  if [ "$spare_list" != "" ];then
    for spare_disk in $spare_list
    do
        ${mdadm} ${mddisk} -a $spare_disk
    done
  fi

  echo "Make Swap."
  make_swap
  make_sys
  wait_swap
  wait_data
  echo 1000 > /proc/sys/dev/raid/speed_limit_min
  backup_superblock "AM_"
  ${event} 997 404 info email "${raid_id}" "RAID${old_level}" "RAID${new_level}"
  rm $migsys_flag
  rm $mig_flag
  
}


function migrate_mdadm(){
  echo "Migrate by mdadm"
  check_healthy "$raid_name"
  if [ "$?" != "0" ];then
    return
  fi
  update_status "Migrating RAID ..." $raid_name
  #migrate data folder
  set_migrate_pool
  #hdd_list to disk_tray
  get_disk_tray
  
  ${save_log} "${hlog_event}" "start"
  ${event} 997 403 info email "${raid_id}" "RAID${old_level},${old_disk_tray}" "RAID${new_level},${new_disk_tray}"
  backup_superblock "BM_"

  get_spare_disk
  if [ "$spare_list" != "" ];then
    ${mdadm} ${mddisk} -r $spare_list
  fi
  
  #addin_hdd
  get_new_hdd
  echo "Got New HDD List:$addin_hdd"
  if  [ $old_level -eq 1 ];then
    check_size_r5
    if [ "$?" != "0" ];then
      return
    fi
    check_size_r1
    if [ "$?" != "0" ];then
      return
    fi
    echo "$migsys_key_r1" > $migsys_flag
    echo "$migsys_key_r1" > $mig_flag
  else
    check_size_r5
    if [ "$?" != "0" ];then
      return
    fi
    echo "$migsys_key_r5" > $migsys_flag
    echo "$migsys_key_r5" > $mig_flag
  fi
  gdisk_hdd
  echo 20000 > /proc/sys/dev/raid/speed_limit_min

  for new_hdd in $addin_hdd
  do
    add_list="$add_list /dev/${new_hdd}2"
  done
  ${mdadm} --add ${mddisk} $add_list
  echo "$migsys_key_recovery_r5" > $mig_flag
  set_sysflag_r5
  ${mdadm} --grow ${mddisk} --level=$new_level --raid-disk=$new_disknum

  if [ "$spare_list" != "" ];then
    for spare_disk in $spare_list
    do
        ${mdadm} ${mddisk} -a $spare_disk
    done
  fi
  
  echo "Make Swap."
  make_swap
  make_sys
  wait_swap
  wait_data
  echo 1000 > /proc/sys/dev/raid/speed_limit_min
  backup_superblock "AM_"
  ${event} 997 404 info email "${raid_id}" "RAID${old_level}" "RAID${new_level}"
  rm $migsys_flag
  rm $mig_flag
}

migrate_raidlock
touch ${ui_opt_unlock}
if [ "$restart_flag" = "restart" ];then
  migrate_r5_restart
else
  migrate_mdadm
fi
migrate_raidunlock
rm -f ${ui_opt_unlock}
exit

