#!/bin/sh
total_tray=`/img/bin/check_service.sh total_tray` #sysconf.N16000 total_tray=16  thecus_io MAX_TRAY: 16
strdisk=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147)) strdisk=sprintf("%s %s2",strdisk,substr($3,6,4))}END{print strdisk}'`
devices="${strdisk}";
strdisk_sys=`cat /proc/scsi/scsi | sort -u |awk '/Thecus:/{tray=substr($2,6,2);if(int(tray)<='$total_tray' || (int(tray)>=53 && int(tray)<=147)) strdisk=sprintf("%s %s3",strdisk,substr($3,6,4))}END{print strdisk}'`
devices_sys="${strdisk_sys}";

## Fetch current time
TIME_STAMP=`date +%Y%m%d_%H%M%S`
## Initial dump folder
DUMP_FOLDER="/syslog/sbdump"
[ ! -d "${DUMP_FOLDER}" ] && mkdir -p ${DUMP_FOLDER}

function backup_superblock() {
  for savedisk in $devices
  do
    /usr/bin/save_super /dev/$savedisk ${DUMP_FOLDER}/${1}${savedisk}_${TIME_STAMP}
  done
  
  for savedisk in $devices_sys
  do
    /usr/bin/save_super /dev/$savedisk ${DUMP_FOLDER}/${1}${savedisk}_${TIME_STAMP}
  done
}

backup_superblock $1

