#!/bin/sh
SPIN_DOWN=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='disks_spin_down'"`
for i in `cat /proc/scsi/scsi | grep Thecus | cut -d: -f4 | cut -d" " -f1`
do
  /sbin/hdparm -S $SPIN_DOWN /dev/$i
done
