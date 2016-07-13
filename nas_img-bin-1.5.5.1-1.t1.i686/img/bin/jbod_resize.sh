#!/bin/sh
##############################################
# Format : jbod_resize.sh $mdnum
##############################################
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

mdnum=$1
syslog="/etc/cfg"
if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
  syslog="/syslog"
fi
event="/img/bin/logevent/event"
save_log="/usr/bin/savelog /etc/cfg/logfile "
hlog_event="raid_expansion"

if [ "$mdnum" = "" ];then
  if [ -f /etc/.jbod_resize ]; then
    mdnum="`cat /etc/.jbod_resize`"
  else
    mdnum="0"
  fi
fi
echo $mdnum > /etc/.jbod_resize

echo "Busy 2" > /proc/thecus_io


echo 1 > /var/tmp/raidlock
use_encrypt=`sqlite /raidsys/$mdnum/smb.db "select v from conf where k='encrypt'"`
if [ "$use_encrypt" == "1" ] ;then
	md_name="`encr_util -g $mdnum`"
	encr_util -r "$mdnum"
else
  md_name="md${mdnum}"
fi
fsmode=`sqlite /raidsys/$mdnum/smb.db "select v from conf where k='filesystem'"`
raid_name=`sqlite /raidsys/$mdnum/smb.db "select v from conf where k='raid_name'"`
${save_log} "${hlog_event}" "start,$md_name"
${event} 997 413 info email "${raid_name}" "${fsmode}"
echo "Please wait ... resizing ..." > /var/tmp/raid$mdnum/rss
sync

partprobe /dev/$md_name
sleep 3
success=1
echo 100 > /proc/sys/vm/swappiness
sleep 3
case "$fsmode" in
  xfs)
    xfs_growfs /raid$mdnum
    ;;
  ext3|ext4)
    /img/bin/service stop
    /img/bin/stop_volume.sh $mdnum
    e2fsck -fy /dev/$md_name -C 0  > /var/tmp/raid$mdnum/rss
    if [ $? -le 1 ]; then
      resize2fs /dev/$md_name -pF  > /var/tmp/raid$mdnum/rss
      if [ $? -eq 0 ]; then
	echo "Healthy" > /var/tmp/raid$mdnum/rss
        /img/bin/start_volume.sh $mdnum
	[ -x /opt/VisoGuard/shell/module.rc ] && /opt/VisoGuard/shell/module.rc expand $mdnum
      else
        success = 0
      fi
    else
      success = 0
    fi
    /img/bin/service start
    ;;
  btrfs)
    btrfsctl -r max /raid$mdnum
    ;;
esac

if [ $? -eq 0 ] && [ $success -eq 1 ]; then
  ${save_log} "${hlog_event}" "end,$md_name"
  ${event} 997 414 info email "${raid_name}" "${fsmode}"
  echo 0 > /var/tmp/raidlock
  echo "Healthy" > /var/tmp/raid$mdnum/rss
  echo "Busy 0" > /proc/thecus_io
  #echo "`date \"+%Y/%m/%d %H:%M:%S\"` `hostname` $raid_name resize successfully." >> /syslog/information
  ${event} 997 490 info email "${raid_name}"
  rm -f /etc/.jbod_resize
else
  ${save_log} "${hlog_event}" "end,$md_name"
  ${event} 997 632 error email "${raid_name}" "${fsmode}"
  umount /raid$mdnum
  [ "$use_encrypt" == "1" ] && encr_util -d "$mdnum"
  mdadm --stop /dev/md${mdnum}
  echo 0 > /var/tmp/raidlock
  echo "Busy 0" > /proc/thecus_io
  #echo "`date \"+%Y/%m/%d %H:%M:%S\"` `hostname` $raid_name resize fail." >> /syslog/information
  ${event} 997 491 info email "${raid_name}"
fi
echo 60 > /proc/sys/vm/swappiness


