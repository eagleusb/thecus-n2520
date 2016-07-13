#!/bin/sh

##Used for mount and create /raid# /raidsys/#, keep raid exist
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

mdnum=$1
sysmdnum=`expr $mdnum + 50`
sysmd="/dev/md$sysmdnum"
raid_name="raid$mdnum"
datadisk="/dev/md$mdnum"
encr_start="/usr/bin/encr_start"

strExec="df |awk -F' ' '/\/$raid_name/{print (\$6)}'"
raid_data=`eval ${strExec}`
if [ "${raid_data}" != "" ];then
  exit
fi

strExec="df |awk -F' ' '/raidsys\/$mdnum\$/{print (\$6)}'"
raid_sys=`eval ${strExec}`
if [ "${raid_sys}" != "" ];then
  exit
fi

rm -rf /$raid_name
mkdir -p /$raid_name
rm -rf /raidsys/$mdnum
mkdir -p /raidsys/$mdnum
mount -t ext4 -o rw,noatime ${sysmd} /raidsys/$mdnum

use_encrypt=`/usr/bin/sqlite /raidsys/$mdnum/smb.db "select v from conf where k='encrypt'"`
if [ "$use_encrypt" = "1" ];then
  if [ ! -f /etc/.jbod_resize ]; then
    ${encr_start} $mdnum
    if [ "$?" != "0" ];then
      exit 1
    fi
  fi
  datadisk="/dev/`encr_util -g $mdnum`"
fi

fsmode=`/usr/bin/sqlite /raidsys/$mdnum/smb.db "select v from conf where k='filesystem'"`
case "$fsmode" in
  xfs)
    mount -t xfs -o attr2,noatime,nodiratime,nobarrier,inode64 $datadisk /$raid_name
  ;;
  ext3)
    mount -t ext3 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $datadisk /$raid_name
  ;;
  ext4)
    mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro $datadisk /$raid_name
  ;;
  btrfs)
    mount -t btrfs -o rw,noatime,nodiratime $datadisk /$raid_name
  ;;
esac

if [ $? -eq 0 ]; then
  mkdir -p /tmp/$raid_name
  rm /$raid_name/sys
  ln -sf /raidsys/$mdnum /$raid_name/sys
  /img/bin/set_masterraid.sh
else
  umount /$raid_name
  rm -rf /$raid_name
  if [ "$use_encrypt" = "1" ];then
    encr_util -d "$mdnum"
  fi
  umount /raidsys/$mdnum
  rm -rf /raidsys/$mdnum
fi

