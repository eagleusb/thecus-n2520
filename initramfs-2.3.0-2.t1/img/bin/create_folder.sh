#!/bin/sh
. /img/bin/functions
raid_mnt="$NEWROOT/raid0"
raid_data="${raid_mnt}/data"
raidLable="RAID"

#################################################
##  Define subroutine
#################################################
## called to sleep 1 sec and call sync system call
pause() {
  sleep 1
  sync
}

## use to steal space from user hd
wickie() {
  snapshot=`/img/bin/check_service.sh snapshot`
  esata_count=`/img/bin/check_service.sh esata_count`
  intelligent_nas=`/img/bin/check_service.sh intelligent_nas`

  mkdir	-p $raid_data
  ln	-fs	/raidsys/0	$raid_mnt/sys
  ln	-fs	../sys		$raid_data/sys
  ln	-fs	.			$raid_data/data
  mkdir -p $raid_data/tmp
  #mkdir -p $raid_data/_NAS_Picture_
  mkdir -p $raid_data/_NAS_Media
  mkdir -p $raid_data/NAS_Public
  mkdir -p $raid_data/USBCopy
  mkdir -p $raid_data/USBHDD
#  mkdir -p $raid_data/_NAS_Module_Source_
  if [ "$esata_count" != "0" ];then
    mkdir -p $raid_data/eSATAHDD
  fi

  mkdir -p $raid_data/_SYS_TMP
  mkdir -p $raid_data/ftproot
  if [ "$snapshot" != "0" ];then
    mkdir -p $raid_data/snapshot
  fi

  mkdir -p $raid_data/module
  mkdir -p $raid_data/module/cfg
  mkdir -p $raid_data/module/cfg/module.rc
  raid_id=${raidLable}
  if [ $raid_id != "" ];then
    mkdir -p $raid_data/_NAS_Recycle_${raid_id}
  fi  
  $sqlite $raid_data/module/cfg/module.db 'create table mod (module,gid,predicate,object)'
  $sqlite $raid_data/module/cfg/module.db 'create table module (name,version,description,enable,updateurl,icon,mode,homepage,ui)'
  
  #chown nobody:users $raid_data/_NAS_Picture_
  chown nobody:users $raid_data/_NAS_Media
  chown nobody:users $raid_data/USBCopy
  chown nobody:users $raid_data/USBHDD
  chown nobody:users $raid_data/NAS_Public
  if [ "$esata_count" != "0" ];then
    chown nobody:users $raid_data/eSATAHDD
  fi
#  chown nobody:users $raid_data/_NAS_Module_Source_
  if [ "$snapshot" != "0" ];then
    chown nobody:users $raid_data/snapshot
  fi

  if [ $raid_id != "" ];then
    chown nobody:users $raid_data/_NAS_Recycle_${raid_id}
    create_share _NAS_Recycle_${raid_id} yes
  fi  
  
  #create_share _NAS_Picture_ yes
  create_share _NAS_Media yes
  create_share USBCopy yes
  create_share USBHDD usby "Used for external USB HDDs only."
  create_share NAS_Public yes
  if [ "$esata_count" != "0" ];then
    create_share eSATAHDD usby "Used for eSATA HDDs only."
  fi
#  create_share _NAS_Module_Source_ yes
  if [ "$snapshot" != "0" ];then
    create_share snapshot no "Used for snapshots only."
  fi

  if [ "$intelligent_nas" == "1" ];then
      ln -sf /raid/data/_NAS_Media $raid_data/NAS_Public/_NAS_Media
  fi

#$sqlite /app/cfg/conf.db "delete from nsync"
#  cat /app/cfg/crond.conf | grep -v nsync.sh > /tmp/crond.conf
#  cp /tmp/crond.conf /app/cfg/crond.conf
#  /usr/bin/killall crond;sleep 1;/usr/sbin/crond -L /dev/null
#  /usr/bin/crontab /app/cfg/crond.conf -u root
}

##Leon 2005/07/21 create raid,create special folder share
create_share() {
  if [ "${2}" = "yes" ]; then
    chmod 774 $raid_data/${1}
    ${setfacl} -m other::rwx $raid_data/${1}
    ${setfacl} -d -m other::rwx $raid_data/${1}
    guest=yes
  elif [ "${2}" = "no" ]; then
    chmod 700 $raid_data/${1}
    ${setfacl} -m other::--- $raid_data/${1}
    ${setfacl} -d -m other::--- $raid_data/${1}
    guest=no
  elif [ "${2}" = "usby" ]; then
    chmod 774 $raid_data/${1}
    ${setfacl} -m other::rwx $raid_data/${1}
    guest=yes
  elif [ "${2}" = "ehdd" ]; then
    chmod 0755 $raid_data/${1}
    guest=yes
  elif [ "${2}" = "usbn" ]; then
    ${setfacl} -m other::r-x $raid_data/${1}
    guest=no
  else
    ${setfacl} -m other::r-x $raid_data/${1}
    ${setfacl} -d -m other::r-x $raid_data/${1}
    guest=yes
  fi

  comment=""
  if [ "${3}" != "" ]; then
    comment=${3}
  fi

        map_hidden="no"
        if [ "$guest" = "no" ] ; then
              map_hidden="yes"
        fi

#  ln -sf ../${1} $raid_data/ftproot
}

#################################################
##  main
#################################################

wickie
pause
exit 0
