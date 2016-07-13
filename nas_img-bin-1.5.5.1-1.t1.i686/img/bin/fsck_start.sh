#!/bin/sh
/img/bin/service stop

PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

get_error_msg(){
  case $1 in
    "0")
      echo "No errors."
      ;;
    "1")
      echo "File system errors corrected."
      ;;
    "2")
      echo "File system errors corrected, system should be rebooted."
      ;;
    "4")
      echo "File system errors left uncorrected."
      ;;
    "8")
      echo "Operational error."
      ;;
    "16")
      echo "Usage or syntax error."
      ;;
    "32")
      echo "File system check canceled by user request."
      ;;
    "128")
      echo "Shared library error."
      ;;
    "-1")
      echo "File system check fail."
      ;;
    "N/A")
      echo "Not Access."
      ;;
    *)
      echo "Unknow exit code, please check information."
      ;;
  esac
}

get_language_word(){
  lang=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='admin_lang'"`
  msg=`/usr/bin/sqlite /var/www/html/language/language.db "select msg from $lang where function='$1' and value='$2'"`
  echo "$msg"
}


#======================================================
#	Check Which on want do file system check
#======================================================
tmp_fsck_dev="/tmp/fsck_dev"
md_num=`cat ${tmp_fsck_dev}`
event="/img/bin/logevent/event"
save_log="/usr/bin/savelog  /etc/cfg/logfile"
hlog_event="filesystem_check_mode"
${event} 997 419 info "" "Starting FileSystem Check"
${save_log} "${hlog_event}" "start"

for num in $md_num
do
  raid_name="raid${num}"
  disk_tray=`cat /var/tmp/${raid_name}/disk_tray | awk -F'\"' '{printf("%s,",$2)}' | awk '{print substr($0,0,length($0)-1)}'`
  raid_level=`cat /tmp/${raid_name}/raid_level`
  use_encrypt=`sqlite /raidsys/$num/smb.db "select v from conf where k='encrypt'"`
  raid_dbname=`sqlite /raidsys/$num/smb.db "select v from conf where k='raid_name'"`
  if [ "$use_encrypt" == "1" ] ;then
    md_name="`encr_util -g $num`"
  else
    md_name="md${num}"
  fi
  echo $md_name
  fsck_time=`date +%Y/%m/%d\ %H:%M:%S`
  /usr/bin/sqlite /$raid_name/sys/smb.db "update conf set v='$fsck_time' where k='fsck_last_time'"
  fsmode=`/usr/bin/sqlite /$raid_name/sys/smb.db "select v from conf where k='filesystem'"`
  case "$fsmode" in
  xfs)
  	cmd_sys='/usr/bin/lns -c "/run/initramfs/sbin/xfs_repair /dev/'${md_name}' 2>&1" -o "/tmp/lns_sys.log"'
    ;;
  ext3|ext4)
  	cmd_sys='/usr/bin/lns -c "/sbin/e2fsck -fy /dev/'${md_name}' -C 1" -o "/tmp/lns_sys.log"'
    ;;
  btrfs)
  	cmd_sys='/usr/bin/lns -c "/run/initramfs/sbin/btrfsck  /dev/'${md_name}' -C 1" -o "/tmp/lns_sys.log"'
    ;;
  esac
  #==========================================================
  #	Main
  #==========================================================
  rm -f /tmp/lns_*
  e2fsck_exit_data=""
  e2fsck_exit_sys=""

  #kill process before umount
  blockproc=`/sbin/fuser -m /$raid_name`
  for theproc in $blockproc
  do
    kill -9 $theproc
    sleep 1
  done
  /bin/umount /$raid_name
  if [ $? != 0 ];
  then
    ${save_log} "${hlog_event}" "umount"
  fi

  sync
  sleep 2

    #cmd_sys='/img/bin/lns5200 -c "/sbin/e2fsck -fy /dev/'${md_name}'/sys -C 1" -o "/tmp/lns_sys.log"'
    eval $cmd_sys 2>&1
    while [ "$e2fsck_exit_sys" == "" ]
    do
      e2fsck_exit_sys=`/usr/bin/awk -F"]" '/EXITCODE/{print $2}' /tmp/lns_sys.log`
      sleep 1
    done
    exit_msg_sys=`get_error_msg $e2fsck_exit_sys`

  lv0_name=`get_language_word fsck lv0`
  #sys_name=`get_language_word fsck syslv`
  exit_code=`get_language_word fsck exit_code`
  lv0_exit_msg=`get_language_word fsck exit_code_$e2fsck_exit_data`
  sys_exit_msg=`get_language_word fsck exit_code_$e2fsck_exit_sys`
  fsck=`get_language_word fsck fsck`

   echo -e "[${raid_dbname}] RAID$raid_level ( $disk_tray ) $sys_name : $exit_code = $e2fsck_exit_sys , $sys_exit_msg" >> /tmp/fsck.log



  /bin/mount /dev/$md_name /${raid_name}
  if [ $? != 0 ];
  then
    ${save_log} "${hlog_event}" "mount"
  fi
  if [ "$e2fsck_exit_sys" == "0" ];
  then
    ${event} 997 421 info "" "${fsck}" "${disk_tray}" "${sys_exit_msg}"
    ${event} 997 227 "info" email "${disk_tray}"
  else
    if [ "$e2fsck_exit_sys" != "0" ] && [ "$e2fsck_exit_sys" != "" ];
    then
      ${event} 997 422 info "" "${fsck}" "${disk_tray}" "${sys_name}" "${exit_code}" "${e2fsck_exit_sys}" "${sys_exit_msg}"
    fi
    ${event} 997 228 "" email "${disk_tray}" "${e2fsck_exit_sys}" "${exit_msg_sys}"
  fi
  if [ -e "/tmp/fsck_stop" ];
  then
    /bin/rm /tmp/fsck_stop
    ${event} 997 420 info "" "End of FileSystem Check"
    ${save_log} "${hlog_event}" "stop"
    exit
  fi
done
sleep 1
${event} 997 420 info "" "End of FileSystem Check"
${save_log} "${hlog_event}" "end"
/bin/rm -f /tmp/lns.lock
exit 0
