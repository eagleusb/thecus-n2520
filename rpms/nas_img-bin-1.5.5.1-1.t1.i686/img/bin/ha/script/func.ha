#!/bin/sh
#################################################
##	Vars defined
#################################################
pwd="/usr"
script_path="/etc/ha/script/"

ha_auto_failback=`${sqlite} ${confdb} "select v from conf where k='ha_auto_failback'"`
ha_role_db=`${sqlite} ${confdb} "select v from conf where k='ha_role'"`
if [ "${ha_role_db}" = "0" ];then 
    ip1=`${sqlite} ${confdb} "select v from conf where k='ha_primary_ip1'"`
    ipx1=`${sqlite} ${confdb} "select v from conf where k='ha_standy_ip1'"`
    ip3=`${sqlite} ${confdb} "select v from conf where k='ha_primary_ip3'"`
    ipx3=`${sqlite} ${confdb} "select v from conf where k='ha_standy_ip3'"`
    node_name=`${sqlite} ${confdb} "select v from conf where k='ha_primary_name'"`
    node_namex=`${sqlite} ${confdb} "select v from conf where k='ha_standy_name'"`
else
    ip1=`${sqlite} ${confdb} "select v from conf where k='ha_standy_ip1'"`
    ipx1=`${sqlite} ${confdb} "select v from conf where k='ha_primary_ip1'"`
    ip3=`${sqlite} ${confdb} "select v from conf where k='ha_standy_ip3'"`
    ipx3=`${sqlite} ${confdb} "select v from conf where k='ha_primary_ip3'"`
    node_name=`${sqlite} ${confdb} "select v from conf where k='ha_standy_name'"`
    node_namex=`${sqlite} ${confdb} "select v from conf where k='ha_primary_name'"`
fi
virtual_interface=eth0
bond=`/img/bin/function/get_interface_info.sh check_eth_bond eth0`
if [ "${bond}" != "" ];then
  virtual_interface=bond0
fi

#HA virtual IP select
#eth2,ipv4,ipv6
if [ "`echo ${ip1} | grep -c '[[:alnum:]],[0-9]*.[0-9]*.[0-9]*.[0-9]*,'`" != "0" ];then
  if [ "`echo ${ipx1} | grep -c '[[:alnum:]],[0-9]*.[0-9]*.[0-9]*.[0-9]*,'`" != "0" ];then
    ip1_interface=`echo ${ip1} | awk -F',' '{print $1}'`
    ip1_v4=`echo ${ip1} | awk -F',' '{print $2}'`
    ip1_v6=`echo ${ip1} | awk -F',' '{print $3}'`
    
    ipx1_interface=`echo ${ipx1} | awk -F',' '{print $1}'`
    ipx1_v4=`echo ${ipx1} | awk -F',' '{print $2}'`
    ipx1_v6=`echo ${ipx1} | awk -F',' '{print $3}'`
    
    ip1=${ip1_v4}
    ipx1=${ipx1_v4}
    
    virtual_prefix=`ifconfig ${ip1_interface} | awk -F'/' "/inet6 addr: ${ip1_v6}\//{print \\$2}" | awk '{print $1}'`
    
    virtual_interface=`${sqlite} ${confdb} "select v from conf where k='ha_virtual_ip'" | awk -F',' '{print $1}'`
    virtual_v4=`${sqlite} ${confdb} "select v from conf where k='ha_virtual_ip'" | awk -F',' '{print $2}'`
    virtual_v6=`${sqlite} ${confdb} "select v from conf where k='ha_virtual_ip'" | awk -F',' '{print $3}'`
  fi
fi

#gateway change to indicator_ip
check_indicator=`${sqlite} ${confdb} "select count(*) from conf where k='ha_indicator_ip'"`
if [ "${check_indicator}" = "0" ];then
  indicator_interface=${virtual_interface}
  indicator_v4=`${sqlite} ${confdb} "select v from conf where k='nic1_gateway'"`
  indicator_v6=`${sqlite} ${confdb} "select v from conf where k='nic1_ipv6_gateway'"`
#  ${sqlite} ${cfgdb} "insert into conf('k','v') values ('ha_indicator_ip','${indicator_interface},${indicator_v4},${indicator_v6}')"
#  if [ "${cfgdb}" != "${confdb}" ];then
#    ${sqlite} ${confdb} "insert into conf('k','v') values ('ha_indicator_ip','${indicator_interface},${indicator_v4},${indicator_v6}')"
#  fi
else
  indicator_interface=`${sqlite} ${confdb} "select v from conf where k='ha_indicator_ip'" | awk -F',' '{print $1}'`
  indicator_v4=`${sqlite} ${confdb} "select v from conf where k='ha_indicator_ip'" | awk -F',' '{print $2}'`
  indicator_v6=`${sqlite} ${confdb} "select v from conf where k='ha_indicator_ip'" | awk -F',' '{print $3}'`
fi
indicator_ip=${indicator_v4}

check_exist_raid(){
    local device=/dev/$1
    if [ "`sgdisk -p ${device} | grep -c 'FD00  Linux RAID'`" = "3" ];then
        if [ "`mdadm -E ${device}3 | grep -c 'Array UUID'`" = "1" ];then
            if [ "`mdadm -E ${device}2 | grep -c 'Array UUID'`" = "1" ];then
                return 0
            fi
        fi
    fi
    return 1
}

init_check(){
    local role=$1
    local device=/dev/md0
    if [ "`cat /proc/mdstat | grep -c '^md0 '`" = "0" ];then
      echo "No md0 find!"
      /img/bin/logevent/event 334
      ${sqlite} /etc/cfg/conf.db "update conf set v='0' where k='ha_enable'"
      ${sqlite} ${confdb} "update conf set v='0' where k='ha_enable'"
      /img/bin/ha/script/stop_ha.sh
      /img/bin/service boot &
      exit
    fi
    if [ "${role}" = "1" ];then
        if [ ! -f /raidsys/0/ha_inited ];then
            while true;do
                ${WGET} ftp://nas:nas@${ipx3}:3694/ha_role -O /tmp/ha_rolex
                if [ "`cat /tmp/ha_rolex`" = "active" ];then
                    touch /raidsys/0/ha_inited
                    touch /tmp/disable_nas_ftpd
                    ${WPUT} /tmp/disable_nas_ftpd ftp://nas:nas@${ipx1}:3694/www/disable_nas_ftpd
                    rm /tmp/disable_nas_ftpd
                    break
                fi
            done
        fi
    fi
}

run_sync_ha(){
    restore=$1
    /usr/bin/lockfile /var/lock/ha_sync.lock
    killall sync_ha_cf.sh
    killall ha_status.sh
    rm -f /var/lock/ha_sync.lock
    if [ "${restore}" = "1" ];then
        /etc/ha/script/sync_ha_cf.sh restore > /dev/null 2>&1
        if [ "$?" != "2" ] || [ "`ls -l /raid/sys/ha.*.tar.md5|wc -l`" = "0" ];then
            /etc/ha/script/sync_ha_cf.sh > /dev/null 2>&1 &
        fi
    else
        /etc/ha/script/sync_ha_cf.sh > /dev/null 2>&1 &
    fi
    /etc/ha/script/ha_status.sh > /dev/null 2>&1 &
}

stop_sync_ha(){
    /usr/bin/lockfile /var/lock/ha_sync.lock
    killall sync_ha_cf.sh
    killall ha_status.sh
    rm -f /var/lock/ha_sync.lock
}

ext_check(){
  local i=$1

  MC=$(/sbin/tune2fs -l $i | grep -E "Mount count:" | tr -d "Mount count:")
  #MMC=$(/sbin/tune2fs -l $i | grep -E "Maximum mount count:" | tr -d "Maximum mount count:")
  MMC=30
  if [ "$MC" -ge "$MMC" ]; then
    echo "auto e2fsck $i" >> /tmp/ha_disk.log
    /img/bin/logevent/event 997 489 info email $i
    /img/bin/pic.sh LCM_MSG "Check FS," "Please wait."
    /sbin/e2fsck -fy $i
    /bin/sync
    /bin/sync
    /bin/sync
    /img/bin/logevent/event 997 488 info email $i
    /img/bin/pic.sh LCM_MSG "Check FS," "Done!"
  fi
  if [ `tune2fs -l $i | grep "Filesystem state:" | grep errors | wc -l` -eq 1 ]; then
    echo "tune2fs $i with errors, do e2fsck $i ..." >> /tmp/ha_disk.log
    /img/bin/logevent/event 997 821 error email $i
    /img/bin/pic.sh LCM_MSG "Check FS," "Please wait."
    /sbin/e2fsck -fy $i
    /bin/sync
    /img/bin/logevent/event 997 488 info email $i
    /img/bin/pic.sh LCM_MSG "Check FS," "Done!"
  fi
}

mount_fs(){
    local md_data=$1
    local raid_data=$2
    local fsmode=$3

    echo "mount_fs $@" >> /tmp/ha_disk.log

    if [ "`cat /proc/mdstat | grep -c '^md60 : active'`" = "0" ];then
      return
    fi

    mounted=1

    case "$fsmode" in
        xfs)
            mount -t xfs -o attr2,noatime,nodiratime,nobarrier,inode64 ${md_data} ${raid_data}
        ;;
        ext3)
            ext_check ${md_data}
            mount -t ext3 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro ${md_data} ${raid_data}
        ;;
        ext4)
            ext_check ${md_data}
            mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro ${md_data} ${raid_data}
        ;;
        btrfs)
            mount -t btrfs -o rw,noatime,nodiratime ${md_data} ${raid_data}
        ;;
    esac
    
    if [ "$?" != "0" ];then
      mounted=0

      /img/bin/logevent/event 997 819 error email ${md_data}
      /img/bin/pic.sh LCM_MSG "Check FS," "Please wait."

      case "$fsmode" in
        xfs)
          /sbin/xfs_repair ${md_data}
          if [ "$?" = "2" ];then
            /sbin/xfs_repair -L ${md_data}
          fi
          /bin/sync
          mount -t xfs -o attr2,noatime,nodiratime,nobarrier,inode64 ${md_data} ${raid_data}
        ;;
        ext3)
          /sbin/e2fsck -fy ${md_data} -C 1
          /bin/sync
          mount -t ext3 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro ${md_data} ${raid_data}
        ;;
        ext4)
          /sbin/e2fsck -fy ${md_data} -C 1
          /bin/sync
          mount -t ext4 -o user_xattr,acl,rw,data=writeback,noatime,nodiratime,barrier=0,errors=remount-ro ${md_data} ${raid_data}
        ;;
        btrfs)
          /sbin/btrfsck ${md_data} -C 1
          /bin/sync
          mount -t btrfs -o rw,noatime,nodiratime ${md_data} ${raid_data}
        ;;
      esac
    fi
    ret=$?

    if [ "${mounted}" = "0" ];then
      if [ "${ret}" != "0" ];then
        /img/bin/logevent/event 997 820 error email ${md_data}
        /img/bin/pic.sh LCM_MSG "Check FS," "Failed!"
        return 1
      else
        /img/bin/logevent/event 997 488 info email ${md_data}
        /img/bin/pic.sh LCM_MSG "Check FS," "Done!"
      fi
    fi
    return 0
}

try_clean_raid(){
    local raid_sys=$1
    local raid_data=$2

    rmdir ${raid_sys}
    mkdir -p ${raid_sys}
    mkdir -p ${raid_data}
    rm -f ${raid_data}/*
}

assemble_sys(){
    local md_sys=$1
    local raid_sys=$2
    local device=$3
    local xdevice=$4

    local devices=${device}3
    if [ "${xdevice}" != "" ];then
      devices="${devices} ${xdevice}3"
    fi
    mdadm -A -R ${md_sys} ${devices} >> /tmp/ha_disk.log 2>&1
}

mount_sys(){
    local md_sys=$1
    local raid_sys=$2

    echo "mount_sys $@" >> /tmp/ha_disk.log
    
    mount -t xfs -o rw,noatime ${md_sys} ${raid_sys}
    if [ x$? = x32 ];then
        /img/bin/logevent/event 997 819 error email ${md_sys}
        /img/bin/pic.sh LCM_MSG "Check FS," "Please wait."
        xfs_repair ${md_sys}
        if [ x$? = x2 ];then 
            xfs_repair -L ${md_sys}
        fi
        /bin/sync
        mount -t xfs -o rw,noatime ${md_sys} ${raid_sys}
        if [ "$?" != "0" ];then
          /img/bin/logevent/event 997 820 error email ${md_sys}
          /img/bin/pic.sh LCM_MSG "Check FS," "Failed!"
          return 1
        else
          /img/bin/logevent/event 997 488 info email ${md_sys}
          /img/bin/pic.sh LCM_MSG "Check FS," "Done!"
          return 0
        fi
    else
       return 0
    fi
}
 
init_assemble_raid(){
    local md_sys=$1
    local raid_sys=$2
    local dev=$3
    local lun=$4
    local xdev

    echo "init_assemble_raid $@" >> /tmp/ha_disk.log

  if [ -f /tmp/ha_raid_damaged ];then
    rm /tmp/ha_raid_damaged
    return 1
  fi

  ping -c 1 -q -I ${HB_LINE} ${ipx3} > /dev/null 2>&1
  if [ "$?" = "0" ];then 
    discovery=`iscsiadm -m discovery -tst --portal ${ipx3}:3260 2>/dev/null|awk "/${ipx3}:3260/&&/nas:iscsi.ha/{print 1}"`
    if [ "${discovery}" = "1" ];then
      ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} start s
      xdev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
      xdev=`${RAID_UUID} ${dev} ${xdev}`
      if [ $? = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
        if [ "`cat /tmp/ha_exten_disks | grep -c "^${xdev}$"`" =  "0" ];then
          rm /tmp/ha_exten_disks
          echo $lun >> /tmp/ha_exten_disks
          echo $xdev >> /tmp/ha_exten_disks
          touch /var/lock/ha_monitor_${lun}
          echo "try by disk add ${xdev}" >> /tmp/ha_disk.log
        else
          echo "has disk add ${xdev}" >> /tmp/ha_disk.log
          /img/bin/ha/script/disk.sh add ${xdev}
        fi
        return 2
      fi
    fi
  fi
        
    while [ -f /var/lock/ha_boot ];do
      ping -c 1 -q -I ${HB_LINE} ${ipx3} > /dev/null 2>&1
      if [ "$?" = "0" ];then 
        discovery=`iscsiadm -m discovery -tst --portal ${ipx3}:3260 2>/dev/null|awk "/${ipx3}:3260/&&/nas:iscsi.ha/{print 1}"`
        if [ "${discovery}" = "1" ];then
          ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} start s
          xdev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
          xdev=`${RAID_UUID} ${dev} ${xdev}`
          if [ $? = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
            touch /var/lock/ha_monitor_${lun}
            echo "try by disk add ${xdev}" >> /tmp/ha_disk.log
            #/img/bin/ha/script/disk.sh add ${xdev}
            return 2
          fi
        fi
      fi
    done
    echo "/var/lock/ha_boot not exist" >> /tmp/ha_disk.log
    return 1
}

assemble_exist_raid(){    
    #argv
    local dev=$1
    local lun=$2
    local opt=$3
    
    echo "assemble_exist_raid $@" >> /tmp/ha_disk.log

    local device=/dev/${dev}
    local _sys=7${lun}
    local _data=6${lun}
    
    local raid_sys=/raidsys/${_data}
    local raid_data=/raid${_data}
    
    local md_sys=/dev/md${_sys}
    local md_data=/dev/md${_data}

    #try clean
    try_clean_raid ${raid_sys} ${raid_data}
    
    if [ "${opt}" = "" ];then
      echo 'wait init_deadtime to assemble two partition' >> /tmp/ha_disk.log
      #wait init_deadtime to assemble two partition
      init_assemble_raid ${md_sys} ${raid_sys} ${dev} ${lun}
      ret=$?
      if [ "$ret" = "0" ];then
        rm ${raid_data}/sys
        ln -fs /raidsys/${_data} ${raid_data}/sys
        is_master=`sqlite /raidsys/${lun}/smb.db "select v from conf where k='raid_master'"`
        if [ "${is_master}" = "1" ];then
            /img/bin/set_masterraid.sh 6${lun}
        fi
        return 0
      elif [ "$ret" = "2" ];then
        return 0
      fi
    
      echo 'timeout init_deadtime to assemble two partition' >> /tmp/ha_disk.log
    fi

    #assemble raid sys & mount
    assemble_sys ${md_sys} ${raid_sys} ${device}
    mount_sys ${md_sys} ${raid_sys}

    if [ "`mount | grep -c "^${md_sys} "`" = "0" ];then
	umount -l ${md_sys}
	mdadm -S ${md_sys}
        echo '[HA System] : Current file system(xfs) error.' >> /var/log/ha-error
        echo '[HA System] : Current file system(xfs) error.' >> /tmp/ha_disk.log
        killall ha_status.sh
        /etc/ha/script/ha_status.sh > /dev/null 2>&1 &
        return 1
    else
        mdadm -A -R ${md_data} ${device}2
	if [ "0" = "0" ];then
            mount_fs ${md_data} ${raid_data} ${fsmode} `${sqlite} ${raid_sys}/smb.db "select v from conf where k='filesystem'"`
            if [ "`mount | grep -c "^${md_data} "`" = "0" ];then
	        umount -l ${md_sys}
	        mdadm -S ${md_sys}
                echo "[HA RAID] : Current file system($fsmode) error." >> /var/log/ha-error
                echo "[HA RAID] : Current file system($fsmode) error." >> /tmp/ha_disk.log
                 killall ha_status.sh
                /etc/ha/script/ha_status.sh > /dev/null 2>&1 &
                return 1
            else
                rm ${raid_data}/sys
                ln -fs /raidsys/${_data} ${raid_data}/sys
                rm ${raid_data}/data/sys
                ln -fs /raidsys/${_data} ${raid_data}/data/sys
                is_master=`sqlite /raidsys/${lun}/smb.db "select v from conf where k='raid_master'"`
                if [ "${is_master}" = "1" ];then
                    /img/bin/set_masterraid.sh 6${lun}
                fi
                if [ "${opt}" != "" ];then
                  mdadm ${md_sys} --add /dev/${opt}3
                  mdadm ${md_data} --add /dev/${opt}2
                fi
                return 0
            fi
	else
	    umount -l ${md_sys}
	    mdadm -S ${md_sys}
	    echo '[HA RAID] : Assemble current RAID failed, wait other RAID join' >> /var/log/ha-error
	    echo '[HA RAID] : Assemble current RAID failed, wait other RAID join' >> /tmp/ha_disk.log
            return 1
        fi
    fi
}

clean_disk(){
    local device=$1
    local block=$2

    /usr/sbin/sgdisk -oZ ${device} > /dev/null
    if [ "$?" = "2" ];then
      /usr/sbin/gdisk ${device} < /img/bin/gdisk_clean.conf > /dev/null
      /usr/sbin/sgdisk -oZ ${device} > /dev/null
    fi

    if [ "${block}" = "512" ];then
      /usr/sbin/gdisk ${device} < /img/bin/gdisk.conf > /dev/null
    else
      /usr/sbin/gdisk ${device} < /img/bin/gdisk.conf.4096 > /dev/null
    fi
    mdadm --zero-superblock ${device}1 > /dev/null 2>&1
    mdadm --zero-superblock ${device}2 > /dev/null 2>&1
    mdadm --zero-superblock ${device}3 > /dev/null 2>&1
}

assemble_assume_clean(){
    #argv
    local dev=$1
    local lun=$2

    local device=/dev/${dev}
    local _sys=7${lun}
    local _data=6${lun}

    local raid_info=/var/tmp/raid${_data}/

    local raid_sys=/raidsys/${_data}
    local raid_data=/raid${_data}

    local md_sys=/dev/md${_sys}
    local md_data=/dev/md${_data}

    local xdev
    local xdevice
    local standby_raid_check

    clean_disk ${device}

    local raidLable=`${sqlite} /raidsys/${lun}/smb.db "select v from conf where k='raid_name'"`
    local fsmode=`${sqlite} /raidsys/${lun}/smb.db "select v from conf where k='filesystem'"`
    is_master=`sqlite /raidsys/${lun}/smb.db "select v from conf where k='raid_master'"`
    /img/bin/smbdb.sh raidDefault raid${lun} "${raidLable}" ${fsmode}

    standby_raid_check=0

    while true;do
        discovery=`iscsiadm -m discovery -tst --portal ${ipx3}:3260 2>/dev/null|awk "/${ipx3}:3260/&&/nas:iscsi.ha/{print 1}"`
        if [ "${discovery}" = "1" ];then
          ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} start s
          xdev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
          xdev=`${RAID_UUID} ${dev} ${xdev}`
          if [ $? = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
            xdevice=/dev/${xdev}
            check_exist_raid ${xdev}
            if [ "$?" != "0" ];then
                clean_disk ${xdevice}
                sh -x /img/bin/mksinglesys_md.sh 2 "${device}3 ${xdevice}3" ${_data} > /tmp/create_mksys.${_sys}.log 2>&1
                /sbin/mdadm --create ${md_data} --assume-clean --bitmap=internal --force --chunk=64 --level=raid1 --raid-devices=2 ${device}2 ${xdevice}2 --run > /tmp/create_raid.${_data}.log 2>&1
                break
            else
                assemble_exist_raid "${xdev}" "${lun}" "${dev}"
                standby_raid_check=1
                break
            fi
          fi
        fi
	if [ "`iscsiadm -m session | grep -c 'iqn.2010-08.com.thecus.nas:iscsi.ha'`" = "2" ];then
            break
	fi
    done

    if [ "$standby_raid_check" = "0"  ];then
        mkdir -p ${raid_info}

        echo HA${lun} > ${raid_info}/raid_id
        echo 1 > ${raid_info}/raid_level
        sh -x /img/bin/post_create ${_data} 100 HA${lun} 0 ${fsmode} "" > /tmp/post_create.${_data}.log 2>&1
        echo Healthy > ${raid_info}/rss
    fi
    
    rm ${raid_data}/sys
    ln -fs /raidsys/${_data} ${raid_data}/sys
    if [ "${is_master}" = "1" ];then
      /img/bin/set_masterraid.sh 6${lun}
    fi

    if [ "$standby_raid_check" = "1"  ];then
         return 2
    else
         touch /var/lock/ha_initasm
         return 1
    fi
}


assemble_new_raid(){
    #argv
    local dev=$1
    local lun=$2
    local device=/dev/${dev}
    local _sys=7${lun}
    local _data=6${lun}
    
    local raid_info=/var/tmp/raid${_data}/
    
    local raid_sys=/raidsys/${_data}
    local raid_data=/raid${_data}
    
    local md_sys=/dev/md${_sys}
    local md_data=/dev/md${_data}

    clean_disk ${device}

    local raidLable=`${sqlite} /raidsys/${lun}/smb.db "select v from conf where k='raid_name'"`
    local fsmode=`${sqlite} /raidsys/${lun}/smb.db "select v from conf where k='filesystem'"`
    is_master=`sqlite /raidsys/${lun}/smb.db "select v from conf where k='raid_master'"`
    /img/bin/smbdb.sh raidDefault raid${lun} "${raidLable}" ${fsmode}
      
    sh -x /img/bin/mksinglesys_md.sh 2 "missing ${device}3" ${_data} > /tmp/create_mksys.${_sys}.log 2>&1
    /sbin/mdadm --create ${md_data} --force --chunk=64 --level=raid1 --raid-devices=2 missing ${device}2 --run > /tmp/create_raid.${_data}.log 2>&1

    mkdir -p ${raid_info}

    echo HA${lun} > ${raid_info}/raid_id
    echo 1 > ${raid_info}/raid_level
    sh -x /img/bin/post_create ${_data} 100 HA${lun} 0 ${fsmode} "" > /tmp/post_create.${_data}.log 2>&1
    echo Healthy > ${raid_info}/rss
    
    rm ${raid_data}/sys
    ln -fs /raidsys/${_data} ${raid_data}/sys
    if [ "${is_master}" = "1" ];then
      /img/bin/set_masterraid.sh 6${lun}
    fi
    return 0
}

get_hours() {
  HOURS=0
#  Mon Oct 18 18:32:59 CST 2010
  YEAR=`echo -n $1 | tail -c 4`
  YEAR=`expr $YEAR - 1970`
  WEEK=`echo $1 | awk '{print $1}'`
  MONTH=`echo $1 | awk '{print $2}'`
  DAY=`echo $1 | awk '{print $3}'`
  HOUR=`echo $1 | awk '{print $3}'`

  HOURS=`expr $HOURS + 24 \* $DAY - 24`
  case "$MONTH"
  in
  Jan)
    HOURS=`expr $HOURS + 24 \* 30 \* 0`
    ;;
  Feb)
    HOURS=`expr $HOURS + 24 \* 30 \* 1`
    ;;
  Mar)
    HOURS=`expr $HOURS + 24 \* 30 \* 2`
    ;;
  Apr)
    HOURS=`expr $HOURS + 24 \* 30 \* 3`
    ;;
  May)
    HOURS=`expr $HOURS + 24 \* 30 \* 4`
    ;;
  Jun)
    HOURS=`expr $HOURS + 24 \* 30 \* 5`
    ;;
  Jul)
    HOURS=`expr $HOURS + 24 \* 30 \* 6`
    ;;
  Aug)
    HOURS=`expr $HOURS + 24 \* 30 \* 7`
    ;;
  Sep)
    HOURS=`expr $HOURS + 24 \* 30 \* 8`
    ;;
  Oct)
    HOURS=`expr $HOURS + 24 \* 30 \* 9`
    ;;
  Nov)
    HOURS=`expr $HOURS + 24 \* 30 \* 10`
    ;;
  Dec)
    HOURS=`expr $HOURS + 24 \* 30 \* 11`
    ;;
  esac

  HOURS=`expr $HOURS + 24 \* 30 \* 12 \* $YEAR`

  echo ${HOURS}
}

get_disk_update_time() {
  DATE=`mdadm --examine ${1} 2>/dev/null | awk -F' : ' '/Update Time/{print $2}'`
  hours=`get_hours "$DATE"`
  echo ${hours}
}

# asemble all/old-partition/new-partition
assemble_raid(){
  local _sys=$1
  local _data=$2
  local md_sys=$3
  local md_data=$4
  local partition=$5
  local lun=$6
  local partition1=$7

  local raid_sys=/raidsys/${_data}
  local raid_data=/raid${_data}
  echo "assemble_raid $@" >> /tmp/ha_disk.log 
  local partition2=${partition}2
  local partition3=${partition}3

  if [ "${partition1}" != "" ];then
    partition3="${partition3} ${partition1}3"
    partition2="${partition2} ${partition1}2"
  else
    partition3="${partition3}"
    partition2="${partition2}"
  fi
  
  cat /proc/scsi/scsi | grep Model:IBLOCK >> /tmp/ha_disk.log
  
  echo "mdadm -A -R -f ${md_sys} ${partition3}" >> /tmp/ha_disk.log
  mdadm -A -R -f ${md_sys} ${partition3} >> /tmp/ha_disk.log 2>&1
  mount_sys ${md_sys} ${raid_sys}
  if [ "`mount | grep -c "^${md_sys} "`" = "0" ];then
    umount -l ${md_sys}
    mdadm -S ${md_sys}
    echo '[HA System] : Current file system(xfs) error.' >> /var/log/ha-error
    echo '[HA System] : Current file system(xfs) error.' >> /tmp/ha_disk.log
    killall ha_status.sh
    /etc/ha/script/ha_status.sh > /dev/null 2>&1 &
    return 1
  else
    echo "mdadm -A -R -f ${md_data} ${partition2}" >> /tmp/ha_disk.log
    mdadm -A -R -f ${md_data} ${partition2} >> /tmp/ha_disk.log 2>&1
    if [ "0" = "0" ];then
      mount_fs ${md_data} ${raid_data} `${sqlite} ${raid_sys}/smb.db "select v from conf where k='filesystem'"`

      if [ "`mount | grep -c "^${md_data} "`" = "0" ];then
	umount -l ${md_sys}
	mdadm -S ${md_sys}
        echo "[HA RAID] : Current file system($fsmode) error." >> /var/log/ha-error
        echo "[HA RAID] : Current file system($fsmode) error." >> /tmp/ha_disk.log
        killall ha_status.sh
        /etc/ha/script/ha_status.sh > /dev/null 2>&1 &
        return 1
      else
        rm ${raid_data}/sys
        ln -fs /raidsys/${_data} ${raid_data}/sys
        rm ${raid_data}/data/sys
        ln -fs /raidsys/${_data} ${raid_data}/data/sys
        is_master=`sqlite /raidsys/${lun}/smb.db "select v from conf where k='raid_master'"`
        if [ "${is_master}" = "1" ];then
          /img/bin/set_masterraid.sh 6${lun}
          run_sync_ha 1
        fi
        return 0
      fi
    fi
  fi
}

# add old/new-partition
add_partition(){
  local md_sys=$1
  local md_data=$2
  local partition=$3

  echo "add_partition $@" >> /tmp/ha_disk.log 
  echo "mdadm ${md_sys} --add ${partition}3" >> /tmp/ha_disk.log
  mdadm ${md_sys} --add ${partition}3 >> /tmp/ha_disk.log  2>&1
  echo "mdadm ${md_data} --add ${partition}2" >> /tmp/ha_disk.log
  mdadm ${md_data} --add ${partition}2 >> /tmp/ha_disk.log 2>&1
  sleep 1
  if [ "`mdadm -D ${md_data} | grep -c " ${partition}2$"`" = "0" ];then
    sleep 10
    echo "mdadm ${md_data} --add ${partition}2" >> /tmp/ha_disk.log
    mdadm ${md_data} --add ${partition}2 >> /tmp/ha_disk.log 2>&1
  fi
  return $?
}

# remove old-partition & stop raid
remove_partition_stop_raid(){
  local md_sys=$1
  local md_data=$2
  local partition=$3
  local mdsys_event=`mdadm -D ${md_sys} | awk '/Events/{print $3}'`
  local mdata_event=`mdadm -D ${md_data} | awk '/Events/{print $3}'`

  echo "remove_partition_stop_raid $@" >> /tmp/ha_disk.log 
  
  stop_sync_ha
  
  if [ "${mdsys_event}" != "" ];then
    umount -l ${md_sys}
    mdadm ${md_sys} --fail ${partition}3
    sleep 3
    mdadm ${md_sys} --remove ${partition}3
    if [ $? != 0 ];then
      echo "remove ${partition}3 fail" >> /tmp/ha_disk.log
      mount >> /tmp/ha_disk.log
      /bin/ps w >> /tmp/ha_disk.log
    fi
  fi
  mdadm --stop ${md_sys}
  
  if [ "${mdata_event}" != "" ];then
    umount -l ${md_data}
    mdadm ${md_data} --fail ${partition}2
    sleep 3
    mdadm ${md_data} --remove ${partition}2
    if [ $? != 0 ];then
      mount >> /tmp/ha_disk.log
      echo "remove ${partition}2 fail" >> /tmp/ha_disk.log
      /bin/ps w >> /tmp/ha_disk.log
    fi
  fi
  mdadm --stop ${md_data}

  return $?
}

# fix ha raid
error_fix_ha(){
  local md=$1
  local disk=$2
  return 0
}

service_on(){
    if [ -d /raid ];then
        echo "Real Service on"  >> /tmp/ha_disk.log
        rm -f /var/run/service_stop
        /img/bin/service boot
    fi
    return 0
}

service_off(){
    if [ ! -f /var/run/service_stop ];then
        echo "Real Service off"  >> /tmp/ha_disk.log
        /img/bin/service stop 
        killall -9 system_monitor.sh
        touch /var/run/service_stop
    fi
    return 0
}

assemble_by_order(){
    #argv
    local dev=$1
    local lun=$2
    local odev=$3
    local device=/dev/${dev}
    local odevice=/dev/${odev}
    local _sys=7${lun}
    local _data=6${lun}

    local raid_info=/var/tmp/raid${_data}/
    
    local raid_sys=/raidsys/${_data}
    local raid_data=/raid${_data}
    
    local md_sys=/dev/md${_sys}
    local md_data=/dev/md${_data}
    
    local odev_sectors=`/usr/sbin/sgdisk -p ${odevice}2 | awk '/Disk \/dev\/sd/{print $3}'`
    local dev_sectors=`/usr/sbin/sgdisk -p ${device}2 | awk '/Disk \/dev\/sd/{print $3}'`

    cat /proc/mdstat > /tmp/mdstat 2>/dev/null
    if [ "`cat /tmp/mdstat | grep -c "${odevice}[2-3]\["`" = "2" ] && [ "`cat /tmp/mdstat | grep -c "${device}[2-3]\["`" = "2" ];then
      echo "md have 2,exit" >> /tmp/ha_disk.log
      return 1
    fi
                        
    local in_sys=`cat /tmp/mdstat | awk "/^md${_sys} /&&/ ${odev}3\[/{print \\$1}"`
    local in_data=`cat /tmp/mdstat | awk "/^md${_data} /&&/ ${odev}2\[/{print \\$1}"`
    
    echo "in_sys=$in_sys in_data=$in_data" >> /tmp/ha_disk.log

    mdadm -D ${md_sys} > /tmp/mdadm.${_sys} 2>/dev/null
    mdadm -D ${md_data} > /tmp/mdadm.${_data} 2>/dev/null
    mdadm -E ${odevice}2 > /tmp/mdadm.${odev}2 2>/dev/null
    mdadm -E ${odevice}3 > /tmp/mdadm.${odev}3 2>/dev/null
    mdadm -E ${device}2 > /tmp/mdadm.${dev}2 2>/dev/null
    mdadm -E ${device}3 > /tmp/mdadm.${dev}3 2>/dev/null

    local dev_event=`cat /tmp/mdadm.${dev}3 | awk '/Events/{print $3}'`
    local odev_event=`cat /tmp/mdadm.${odev}3 | awk '/Events/{print $3}'`
    local md_event=`cat /tmp/mdadm.${_sys} | awk '/Events/{print $3}'`

    local Ddev_event=`cat /tmp/mdadm.${dev}2 | awk '/Events/{print $3}'`
    local Dodev_event=`cat /tmp/mdadm.${odev}2 | awk '/Events/{print $3}'`
    local Dmd_event=`cat /tmp/mdadm.${_data} | awk '/Events/{print $3}'`

    if [ "${dev_event}" = "" ];then
        clean_disk ${device}
        if [ -f /raidsys/0/ha_inited ];then
          nas_ftpd start
        fi
        dev_event=0
    fi
    if [ "${odev_event}" = "" ];then
        clean_disk ${odevice}
        if [ -f /raidsys/0/ha_inited ];then
          nas_ftpd start
        fi
        odev_event=0
    fi
    if [ "${md_event}" = "" ];then
        md_event=0
    fi
    
    if [ "${Ddev_event}" = "" ];then
        Ddev_event=0
    fi
    if [ "${Dodev_event}" = "" ];then
        Dodev_event=0
    fi
    if [ "${Dmd_event}" = "" ];then
        Dmd_event=0
    fi

    echo "dev_event=$dev_event odev_event=$odev_event md_event=$md_event" >> /tmp/ha_disk.log
    echo "Ddev_event=$Ddev_event Dodev_event=$Dodev_event Dmd_event=$Dmd_event" >> /tmp/ha_disk.log

    odev2_active=`cat /tmp/mdadm.${odev}2 | grep -c 'Device Role : Active device'`
    odev3_active=`cat /tmp/mdadm.${odev}3 | grep -c 'Device Role : Active device'`
    odev_active=`expr ${odev2_active} + ${odev3_active}`
    dev2_active=`cat /tmp/mdadm.${dev}2 | grep -c 'Device Role : Active device'`
    dev3_active=`cat /tmp/mdadm.${dev}3 | grep -c 'Device Role : Active device'`
    dev_active=`expr ${dev2_active} + ${dev3_active}`
    
    echo "odev_active=$odev_active dev_active=$dev_active" >> /tmp/ha_disk.log

    odev2_recovery=`cat /tmp/mdadm.${odev}2 | grep -c 'Recovery Offset'`
    odev3_recovery=`cat /tmp/mdadm.${odev}3 | grep -c 'Recovery Offset'`
    odev_recovery=`expr ${odev2_recovery} + ${odev3_recovery}`
    dev2_recovery=`cat /tmp/mdadm.${dev}2 | grep -c 'Recovery Offset'`
    dev3_recovery=`cat /tmp/mdadm.${dev}3 | grep -c 'Recovery Offset'`
    dev_recovery=`expr ${dev2_recovery} + ${dev3_recovery}`
    
    echo "odev_recovery=$odev_recovery dev_recovery=$dev_recovery" >> /tmp/ha_disk.log
 
    assemble_by=0
    if [ ${odev_event} -gt ${dev_event} ];then
#      if [ `expr ${odev_event} - ${dev_event}` -le 50 ];then
#        assemble_by=1
#      else
        if [ "${dev_event}" = "0" ] && [ ${odev_sectors} -gt ${dev_sectors} ];then
          assemble_by=0
          echo "Add HA raid failed, size is not match!" >> /tmp/ha_disk.log
          /img/bin/logevent/event 333 > /dev/null 2>&1
        else
          assemble_by=2
        fi
#      fi
    elif [ ${odev_event} -lt ${dev_event} ];then
#      if [ `expr ${dev_event} - ${odev_event}` -le 50 ];then
#        assemble_by=3
#      else
        assemble_by=4
#      fi
    else #sys same event
      if [ ${Dodev_event} -gt ${Ddev_event} ];then
        assemble_by=2
      elif [ ${Dodev_event} -lt ${Ddev_event} ];then
        assemble_by=4
      else
        if [ "${md_event}" != "0" ];then
          assemble_by=2
        else
          assemble_by=5
        fi
      fi
    fi
    
    echo "assemble_by $assemble_by" >> /tmp/ha_disk.log

    if [ "${assemble_by}" != "0" ];then
      #check disk in raid
      if [ "${in_sys}" != "" ] && [ "${in_data}" != "" ] || [ "${md_event}" = "0" ];then
        #check active & recovery
        if [ "${odev_active}" = "2" ] && [ "${odev_recovery}" = "0" ];then 
          if [ ${assemble_by} = "1" ] || [ ${assemble_by} = "3" ]  || [ ${assemble_by} = "4" ] || [ ${assemble_by} = "5" ];then
            echo "service stop" >> /tmp/ha_disk.log
              service_off
            ret=0
            if [ "${md_event}" != "0" ];then
              echo "remove old-disk  stop raid" >> /tmp/ha_disk.log
                remove_partition_stop_raid ${md_sys} ${md_data} ${odevice}
                ret=$?
            fi
            if [ "${ret}" = "0" ] && [ ${assemble_by} != "4" ] ;then
              echo re-asemble all >> /tmp/ha_disk.log
              assemble_raid ${_sys} ${_data} ${md_sys} ${md_data} ${device} ${lun} ${odevice}
              if [ "`cat /proc/mdstat|awk "/${dev}/&&/${odev}/{print}"| wc -l`" != "2" ];then
                 umount_stop_ha_md
                assemble_by=`expr ${assemble_by} + 1`
              else
                echo service boot >> /tmp/ha_disk.log
                  service_on
              fi
            fi
            if [ ${assemble_by} = "4" ];then
              echo re-asemble new-disk >> /tmp/ha_disk.log
                assemble_raid ${_sys} ${_data} ${md_sys} ${md_data} ${device} ${lun}
              echo re-add old-disk >> /tmp/ha_disk.log
                add_partition ${md_sys} ${md_data} ${odevice}
              echo service boot >> /tmp/ha_disk.log
                service_on
            fi
          fi
          if [ ${assemble_by} = "2" ];then 
            if [ "${in_sys}" = "" ] || [ "${in_data}" = "" ];then
              echo re-asemble old-disk >> /tmp/ha_disk.log
                assemble_raid ${_sys} ${_data} ${md_sys} ${md_data} ${odevice} ${lun}
              echo service boot >> /tmp/ha_disk.log
                service_on
            fi
            echo re-add new-disk >> /tmp/ha_disk.log
              add_partition ${md_sys} ${md_data} ${device}
          elif [ ${assemble_by} = "6" ];then
            echo re-asemble old-disk >> /tmp/ha_disk.log
              assemble_raid ${_sys} ${_data} ${md_sys} ${md_data} ${odevice} ${lun}
            echo re-add new-disk >> /tmp/ha_disk.log
              add_partition ${md_sys} ${md_data} ${device}
            echo service boot >> /tmp/ha_disk.log
              service_on
          fi
        #check active & recovery
        elif [ "${dev_active}" = "2" ] && [ "${dev_recovery}" = "0" ];then
          echo service stop >> /tmp/ha_disk.log
            service_off
          echo "remove old-disk stop raid" >> /tmp/ha_disk.log
            remove_partition_stop_raid ${md_sys} ${md_data} ${odevice}
          echo re-asemble new-disk >> /tmp/ha_disk.log
            assemble_raid ${_sys} ${_data} ${md_sys} ${md_data} ${device} ${lun}
          echo re-add old-disk >> /tmp/ha_disk.log
            add_partition ${md_sys} ${md_data} ${odevice}
          echo service boot >> /tmp/ha_disk.log
            service_on
        elif [ "${dev_active}" = "0" ] && [ "${dev_recovery}" = "0" ];then
          echo service stop >> /tmp/ha_disk.log
            service_off
          assemble_assume_clean ${odev} ${lun}
          echo service boot >> /tmp/ha_disk.log
            service_on
        else #check active & recovery
          echo fix ha raid >> /tmp/ha_disk.log
            error_fix_ha
        fi #check active & recovery
      else #check disk in raid
        if [ "${dev_active}" = "2" ] && [ "${dev_recovery}" = "0" ];then
          echo service stop >> /tmp/ha_disk.log
            service_off
          echo remove old-disk stop raid >> /tmp/ha_disk.log
            remove_partition_stop_raid ${md_sys} ${md_data} ${odevice}
          echo re-asemble new-disk >> /tmp/ha_disk.log
            assemble_raid ${_sys} ${_data} ${md_sys} ${md_data} ${device} ${lun}
          echo re-add old-disk >> /tmp/ha_disk.log
            add_partition ${md_sys} ${md_data} ${odevice}
          echo service boot >> /tmp/ha_disk.log
            service_on
        else
          echo fix ha raid 1>> /tmp/ha_disk.log
            error_fix_ha
        fi
      fi #check disk in raid
    fi
}

    
clean_dual_dom_flag(){
    #delete the REPAIR file to clear the record of dual dom repair when system boot and ha start successfully
    if [ -e /raid/data/tmp/save_tmp/REPAIR ]; then
        rm -f /raid/data/tmp/save_tmp/REPAIR
    fi

    if [ -e /raid/data/_SYS_TMP/dual_dom/save_tmp/REPAIR ]; then
        rm -f /raid/data/_SYS_TMP/dual_dom/save_tmp/REPAIR
    fi    
}

umount_stop_ha_md(){
  local md

  stop_sync_ha
  
  for md in `cat /proc/mdstat | awk '/md[6-7][0-9] :/{print $1}' | sort`
  do
    mount_point=`mount | awk "/^\\/dev\\/${md} /{print \\$3}"`
    if [ x${mount_point} != x ];then
      fuser -km ${mount_point}
    fi
    umount -l /dev/${md}
    mdadm -S /dev/${md}
  done
}

stop_ha(){
    local md
    local dev

    stop_sync_ha
    
    if [ ! -f /tmp/ha_stop ];then
        lockfile /var/run/service_boot
        rm /var/run/service_boot
        lockfile /var/run/service_stop
        rm /var/run/service_stop
        service_off
        sleep 3
        echo standby > /tmp/ha_role
        echo standby > /var/www/html/htdocs/ha_role
        cp -f /etc/ha/script/shortcut.db /etc/cfg/shortcut.db
    fi
    
    umount_stop_ha_md

    ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop p
    ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop s
    ${Export_iSCSI} ${ip1} ${HB_LINE} remove
    
    if [ -f /tmp/ha_stop ];then
        ${Export_iSCSI} ${ipx1} ${HB_LINE} remove
        ${RC_INITIATOR} stop
        rm /tmp/ha_role
        rm /var/www/html/htdocs/ha_role
        rm -f /tmp/ha_stop
    else
        for dev in `cat /proc/mdstat | awk '/md[0-9] :/{print $1}' | sort`
        do
            ${Export_iSCSI} ${ipx1} ${HB_LINE} add ${dev}
        done
        /img/bin/rc/rc.snmpd boot
        /img/bin/rc/rc.ups start
        /img/bin/rc/rc.cupsd start
	/img/bin/rc/rc.sshd boot
	/img/bin/rc/rc.sys_monitor boot
    fi
    umount_stop_ha_md
    /img/bin/logevent/event 155
}

stat_line(){
    local lun
    local dev
    local xdev
        
    active_line=1
    standby_line=1
    heartbeat_line=1
    
    arping -I ${indicator_interface} -c 1 -q ${indicator_ip}
    if [ "$?" = 0 ];then
        active_line=0
    fi
    
    arping -I ${indicator_interface} -c 1 -q ${ipx1}
    if [ "$?" = 0 ];then
        standby_line=0
    fi
    
    arping -I ${HB_LINE} -c 1 -q ${ipx3}
    if [ "$?" = 0 ];then
        heartbeat_line=0
    fi
   
    
    rebuild_role=""
    if [ -f /var/tmp/www/ha_status ];then
      lun=`cat /var/tmp/www/ha_status | awk -F'|' '/Rebuilding/&&/data/{print substr($1,3)}' | head -1`
      if [ "${lun}" != "" ];then
        rebuild_role=0
        rebuild=`mdadm -D /dev/md6${lun} | awk '/spare rebuilding/{sub(/\/dev\//,"");print $7}'`
        dev=`${DEV_MAP} ${HB_LINE} ${ip3} dev ${lun}`
        xdev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
        xdev=`${RAID_UUID} ${dev} ${xdev}`
        if [ $? = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
          if [ "${xdev}2" = "${rebuild}" ];then
            rebuild_role=1
          fi
        fi
      fi
    fi

    if [ "${ha_role_db}" = "0" ];then 
      lin_stat="${active_line}|${heartbeat_line}|${standby_line}|${rebuild_role}"        
    else
      lin_stat="${standby_line}|${heartbeat_line}|${active_line}|${rebuild_role}"        
    fi
    echo $lin_stat > /var/tmp/www/ha_network    
}

pre_stat_raid(){
    #check mdstat
    #cat /proc/mdstat > /tmp/mdstat

    /bin/df -h | \
    awk '/\/dev\/md[6-7][0-9]/{printf "%s\n%s/%s\n",substr($1,8),$3,$2}'| \
    while read md;read capacity
    do
        cat /tmp/mdstat | sed -n "/^md${md} :/,/^md/p" | \
        awk "{ \
            if ((\$1~/^md6[0-9]/)&&(\$1~/^md${md}/))    {printf \"\\nHA%s|data\",substr(\$1,4)} \
            else if ((\$1~/^md7[0-9]/)&&(\$1~/^md${md}/))   {printf \"\\nHA%s|sys\",substr(\$1,4)} \
            else if (\$2~/recovery/)       {printf \"|%s|%s|%s|${capacity}|Rebuilding\",\$4,substr(\$6,8),substr(\$7,7)} \
            else if (\$1~/resync=DELAYED/) {printf \"|0%%|0min|0K/sec|${capacity}|Waiting\"} \
        }" |
        awk -F'|' "\$1~/^HA/{ \
            if (\$3==\"\"){printf \"%s||||${capacity}|Finish\\n\",\$0} \
            else {print \$0} \
        }"
    done
    
    for mdno in 0 1 2 3 4
    do    
        if [ "`/bin/ps|grep -c "[p]ost_create 6${mdno}"`" != "0" ];then
          echo "HA${mdno}|data||||N/A|Formatting"
        fi
    done
}

stat_log(){
    if [ -f /var/log/ha-log ];then
        cat /var/log/ha-log | \
        awk -F: '/ heartbeat: /||/ ipfail: /{ \
            printf "%s|%s:%s:%s|%s%s%s%s\n", \
            tolower(substr($5,2)),$1,$2,substr($3,0,2),substr($6,2),$7,$8,$9}' | \
        grep -v 'Consider setting' | \
        grep -v 'Core dumps' | \
        grep -v 'Logging daemon is disabled' | \
        grep -v 'killed by signal' | \
        grep -v 'dumped core' | \
        grep -v 'process died' | \
        grep -v 'Both comm processes for channel 2 have died' | \
        tail -60  > /var/tmp/www/ha_log
    fi
}

stat_raid(){

pre_stat_raid > /tmp/ha_status

for lun in 0 1 2 3 4
do
  chk_data=`cat /tmp/mdstat | grep -c "^md6${lun} :"`
  chk_sys=`cat /tmp/mdstat | grep -c "^md7${lun} :"`
  
  dev=`${DEV_MAP} ${HB_LINE} ${ip3} dev ${lun}`
  if [ $? = 0 ] && [ "${dev}" != "" ] && [ "${dev}" != "NO_DEVICE" ];then
    xdev_ret=1
    _xdev=`${DEV_MAP} ${HB_LINE} ${ipx3} dev ${lun}`
    xdev=`${RAID_UUID} ${dev} ${_xdev}`
    if [ $? = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
      xdev_ret=0
    fi
    
    if [ "${_xdev}" != "${xdev}" ];then
      lun=`cat /tmp/mdstat | awk "/ ${dev}2\[/{gsub(\"md6\",\"\",\\$1);print \\$1}"`
      chk_data=0
      if [ "${lun}" != "" ];then
        chk_data=1
      fi
      lun=`cat /tmp/mdstat | awk "/ ${dev}3\[/{gsub(\"md7\",\"\",\\$1);print \\$1}"`
      chk_sys=0
      if [ "${lun}" != "" ];then
        chk_sys=1
      fi
    fi
    
    if [ "$chk_data" = "1" ];then
      active=`cat /tmp/mdstat | awk "/^md6${lun} :/{print match(\\$0, /${dev}2/)}"`
      if [ $active -gt 0 ];then
        active=1
      fi
      if [ $xdev_ret = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
        standby=`cat /tmp/mdstat | awk "/^md6${lun} :/{print match(\\$0, /${xdev}2/)}"`
        if [ $standby -gt 0 ];then
          standby=1
        fi
        if [ "${ha_role_db}" = "1" ];then
          echo "`cat /tmp/ha_status | grep "^HA${lun}|data"`|${standby}|${active}"
        else
          echo "`cat /tmp/ha_status | grep "^HA${lun}|data"`|${active}|${standby}"
        fi
      else
        if [ "${ha_role_db}" = "1" ];then
          echo "`cat /tmp/ha_status | grep "^HA${lun}|data"`|0|${active}"
        else
          echo "`cat /tmp/ha_status | grep "^HA${lun}|data"`|${active}|0"
        fi
      fi
    fi
    
    if [ "$chk_sys" = "1" ];then
      _active=`cat /tmp/mdstat | awk "/^md7${lun} :/{print match(\\$0, /${dev}3/)}"`
      if [ $_active -gt 0 ];then
        _active=1
      fi
      if [ $xdev_ret = 0 ] && [ "${xdev}" != "" ] && [ "${xdev}" != "NO_DEVICE" ];then
        _standby=`cat /tmp/mdstat | awk "/^md7${lun} :/{print match(\\$0, /${xdev}3/)}"`
        if [ $_standby -gt 0 ];then
          _standby=1
        fi
        if [ "${ha_role_db}" = "1" ];then
          echo "`cat /tmp/ha_status | grep "^HA${lun}|sys"`|${_standby}|${_active}"
        else
          echo "`cat /tmp/ha_status | grep "^HA${lun}|sys"`|${_active}|${_standby}"
        fi
      else
        if [ "${ha_role_db}" = "1" ];then
          echo "`cat /tmp/ha_status | grep "^HA${lun}|sys"`|0|${_active}"
        else
          echo "`cat /tmp/ha_status | grep "^HA${lun}|sys"`|${_active}|0"
        fi
      fi
    fi
  else
    if [ "$chk_data" = "1" ];then
      if [ "${ha_role_db}" = "1" ];then
        echo "`cat /tmp/ha_status | grep "^HA${lun}|data"`|1|0"
      else
        echo "`cat /tmp/ha_status | grep "^HA${lun}|data"`|0|1"
      fi
    fi
    if [ "$chk_sys" = "1" ];then
      if [ "${ha_role_db}" = "1" ];then
        echo "`cat /tmp/ha_status | grep "^HA${lun}|sys"`|1|0"
      else
        echo "`cat /tmp/ha_status | grep "^HA${lun}|sys"`|0|1"
      fi
    fi
  fi
done
}

nas_ftpd(){
  #NAS_FTPD
  local act=$1
  if [ "$act" = "start" ];then
    killall bftpd
    ${NAS_FTPD}
  elif [ "$act" = "stop" ];then
    killall bftpd
  fi
}

virtual_ipv4(){
  local intf=$1
  local act=$2
  if [ "${virtual_v4}" = "" ];then
    return 
  fi
  if [ "$act" = "add" ];then
    if [ "`ifconfig | grep -c '^eth0:'`" = "0" ];then
      netmask=`ifconfig ${intf} | awk -F: '/Mask:/{print $4}'`
      ifconfig ${intf}:0 ${virtual_v4} netmask ${netmask} broadcast +
    fi
  elif [ "$act" = "del" ];then
    intf_x=`ifconfig | awk '/^eth0:/{print $1}'`
    if [ "${intf_x}" != "" ];then
      ifconfig ${intf_x} down
    fi
  fi
}

virtual_ipv6(){
  local act=$1
  local ha_virtual_name=`${sqlite} ${confdb} "select v from conf where k='ha_virtual_name'"`
  local nic1_domainname=`${sqlite} ${confdb} "select v from conf where k='nic1_domainname'"`
  
  if [ "$act" = "add" ];then
    if [ "`cat /etc/hosts|grep -c "^${virtual_v4}.${ha_virtual_name}.${nic1_domainname}.${ha_virtual_name}$"`" = "0" ];then
      echo -e "${virtual_v4}\t${ha_virtual_name}.${nic1_domainname}\t${ha_virtual_name}" >> /etc/hosts
    fi
    
    if [ "${virtual_v6}" != "" ];then
      echo virtual ipv6 add
      ip -6 addr add ${virtual_v6}/${virtual_prefix} dev ${virtual_interface}
    fi
  elif [ "$act" = "del" ];then
    if [ "`cat /etc/hosts|grep -c "^${virtual_v4}.${ha_virtual_name}.${nic1_domainname}.${ha_virtual_name}$"`" != "0" ];then
      sed -i /"${virtual_v4}\t${ha_virtual_name}.${nic1_domainname}\t${ha_virtual_name}"/d /etc/hosts
    fi
    
    if [ "${virtual_v6}" != "" ];then
      echo virtual ipv6 del
      ip -6 addr del ${virtual_v6}/${virtual_prefix} dev ${virtual_interface}
    fi
  fi
}

