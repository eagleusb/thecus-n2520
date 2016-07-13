#!/bin/sh 

#################################################
##  Master RAID Set
##  called by raid_start, post create, start_volume.sh
#################################################
#
mdnum=$1
sqlite_cmd="/usr/bin/sqlite"
is_master="0"

getold_masterraid() {
  graidname=`ls -la /raid |awk -F\/ '{print $3}'`
  echo "$graidname"
}

echo "1" > /var/tmp/raidlock

if [ "$mdnum" != "" ];then
  #Set master raid
  master_raidname="raid$mdnum"
  db_file="/raidsys/$mdnum/smb.db"
    
  is_master=`$sqlite_cmd $db_file "select v from conf where k='raid_master'"`
  
  if [ "$is_master" = "0" ];then
    #change master-->umount old master raid sub device first
    old_raidname=`getold_masterraid`
    if [ "$old_raidname" != "" ];then
      str_exec="mount|awk -F\  '/\/$old_raidname\/data\/USBHDD/{print \$3}'"
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
      done

      str_exec="mount|awk -F\  '/\/$old_raidname\/data\/eSATAHDD/{print \$3}'"
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
      done
    fi
    #clean old master raid
    mdlist=`awk -F ':' '/^md[0-9] /||/^md6[0-9]/{print $1}'  /proc/mdstat|sort -u`
    for mdname in $mdlist
    do
      mdnum=`echo "$mdname"|awk '{h=substr($1,0,2);n=substr($1,3);if (h=="md") printf("%d\n",n);}'`
      db_file="/raidsys/$mdnum/smb.db"
      $sqlite_cmd $db_file "update conf set v='0' where k='raid_master'"
    done
  fi
else
  ##Select Master Raid Number and Name from DB
  getmaster="0"
  mdlist=`awk -F ':' '/^md[0-9] /||/^md6[0-9]/{print $1}'  /proc/mdstat|sort -u`
  for mdname in $mdlist
  do
    mdnum=`echo "$mdname"|awk '{h=substr($1,0,2);n=substr($1,3);if (h=="md") printf("%d\n",n);}'`
    raid_name="raid$mdnum"

    if [ "$master_raidname" = "" ];then
      ##select first raid as default master
      master_raidname="$raid_name"
    fi
    strExec="df |awk -F' ' '/\/$raid_name/{tcount=tcount+1}END{printf(\"%d\",tcount)}'"
    chkraid=`eval ${strExec}`
    if [ $chkraid -gt 0 ] || [ -f /raidsys/$mdnum/ha_raid ];then
      db_file="/raidsys/$mdnum/smb.db"
      ismaster=`$sqlite_cmd $db_file "select v from conf where k='raid_master'"`
      if [ "$ismaster" = "1" ] && [ "$getmaster" = "0" ];then
        ##select first master raid
        master_raidname="$raid_name"
        getmaster="1"
        is_master="1"
      elif [ "$ismaster" = "1" ];then
        ##set other raid master to 0
        $sqlite_cmd $db_file "update conf set v='0' where k='raid_master'"
      fi
    fi
  done
fi

#set raid to master raid
if [ ! "$master_raidname" = "" ];then

  mdnum=`echo "$master_raidname"|awk -Fraid '{print $2}'`
  db_file="/raidsys/$mdnum/smb.db"
  $sqlite_cmd $db_file "update conf set v='1' where k='raid_master'"

  if [ $mdnum -ge 60 ] && [ $mdnum -le 64 ];then
    mdnum=`expr $mdnum - 60`
    db_file="/raidsys/$mdnum/smb.db"
    $sqlite_cmd $db_file "update conf set v='1' where k='raid_master'"
  fi

  rm -rf /raid
  ln -sf /$master_raidname/data /raid

  rm -rf /var/tmp/rss
  ln -sf /var/tmp/$master_raidname/rss /var/tmp/rss

  /img/bin/usb.hotplug add usb
  /img/bin/usb.hotplug add esata
else
  rm -rf /raid
fi
echo "0" > /var/tmp/raidlock
