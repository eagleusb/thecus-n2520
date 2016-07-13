#!/bin/sh
source /img/bin/function/libmodule

##Used for umount and delete /raid# /raidsys/#, keep raid exist
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

mdnum=$1
sysmdnum=`expr $mdnum + 50`
sysmd="/dev/md$sysmdnum"
raid_name="raid$mdnum"

##
 # In this function, if root_on_emmc exists, then it resets symbolic link
 # of modules to rootfs.
 ##
reset_module_to_rootfs

str_exec="mount|awk -F\  '/\/$raid_name\//{print \$3}'"
mount_datadisk=`eval "$str_exec"`
for datadisk in $mount_datadisk
do
  blockproc=`/sbin/fuser -m ${datadisk}`
  for theproc in $blockproc
  do
    kill -9 $theproc
    sleep 1
  done
  umount -f ${datadisk}
  if [ $? != 0 ];
  then
    exit
  fi
done

blockproc=`/sbin/fuser -m /$raid_name`
for theproc in $blockproc
do
  kill -9 $theproc
  sleep 1
done
umount -f /$raid_name
if [ $? != 0 ];
then
  exit
fi

use_encrypt=`sqlite /raidsys/$mdnum/smb.db "select v from conf where k='encrypt'"`
if [ "$use_encrypt" = "1" ];then
  if [ ! -f /etc/.jbod_resize ]; then
    encr_util -d "$mdnum"
  fi
fi

rm -rf /$raid_name

blockproc=`/sbin/fuser -m /raidsys/$mdnum`
for theproc in $blockproc
do
  kill -9 $theproc
  sleep 1
done
umount -f $sysmd
if [ $? != 0 ];
then
  exit
fi

rm -rf /raidsys/$mdnum

sleep 1

