#!/bin/sh

. /img/bin/ha/script/conf.ha
. /img/bin/ha/script/func.ha

new_check(){
  echo new_check
  echo 6 > ${FLAG_HA}
  nas_ftpd start
  ${HA_CHECK} save
  ${NAS_PIE} send ${NAS_ACT} raid_check
}

new_create(){
  echo new_create
  echo 8 > ${FLAG_HA}
  sleep 10
  echo 9 > ${FLAG_HA}
  #echo 109 > ${FLAG_HA}
  #echo 110 > ${FLAG_HA}
  #echo 111 > ${FLAG_HA}
  #echo 12 > ${FLAG_HA}
  #echo 112 > ${FLAG_HA}
  echo 13 > ${FLAG_HA}
  sleep 10
  echo 14 > ${FLAG_HA}
  sleep 10
  #echo 114 > ${FLAG_HA}
  echo 15 > ${FLAG_HA}
  #echo 115 > ${FLAG_HA}
}

## call to get disk UUID
get_uuid() {
        UUID=`mdadm -D /dev/${1} 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/UUID/ && UUID==""){UUID=$2}if($1~/Raid Level/){TYPE=$2}}END{if(TYPE!="" && UUID!="")print TYPE,UUID}'`
        echo ${UUID}
}


rebuild_init(){
  echo rebuild_init
#  echo 16 >${FLAG_HA}
  nas_ftpd start
  ${HA_CHECK} save
  cp -f /etc/cfg/conf.db /tmp/www/conf.db 
  cp -f /etc/cfg/cfg_nic0 /tmp/www/cfg_nic0
  cp -f /etc/cfg/cfg_nic1 /tmp/www/cfg_nic1
  cp -f /etc/resolv.conf /tmp/www/resolv.conf
  cat /tmp/raid0/raid_id > /tmp/www/ha_config_rebuild
  cat /tmp/raid0/raid_level >> /tmp/www/ha_config_rebuild
  sqlite /raidsys/0/smb.db "select v from conf where k='filesystem'" >> /tmp/www/ha_config_rebuild
  cat /tmp/raid0/disk_tray >> /tmp/www/ha_config_rebuild
  #${CONF_REBUILD}
}

rebuild_serv(){
  if [ "$1" = "start" ];then
    if [ -f /tmp/ha_role ] && [ "`cat /tmp/ha_role`" = "active" ];then
      enable_rebuild=`cat /tmp/www/ha_network | grep -cv '^0|0|0|'`
      if [ "${enable_rebuild}" = "1" ];then
        rebuild_init
      else
        nas_ftpd stop
      fi
    fi
  elif [ "$1" = "stop" ];then
    nas_ftpd stop
  fi
}

rebuild_create(){
  echo rebuild_create
#  echo 18 >${FLAG_HA}
  total_line=`cat /tmp/ha_config_rebuild | wc -l`
  raid56_count=`expr \( $total_line + 1 \) / 2`
  line=0
  cat /tmp/ha_config_rebuild | \
  while read conf
  do
    if [ "${line}" = "0" ];then
      raid_id="${conf}"
    elif [ "${line}" = "1" ];then
      raid_level="${conf}"
      if [ "${raid_level}" = "J" ];then
        raid_level=linear
      fi
    elif [ "${line}" = "2" ];then
      raid_fs="${conf}"
    else
      raid_disk=`echo ${conf} | tr -d \\"`
      raid_disk_ten=`expr $raid_disk / 26`
      if [ $raid_disk_ten -gt 0 ];then
        tray_ten=`expr $raid_disk_ten + 96`
        
        raid_disk_div=`expr $raid_disk % 26`
        tray_div=`expr $raid_disk_div + 96`
        raid_disk="sd`printf \\\\$(printf '%03o' ${tray_ten})``printf \\\\$(printf '%03o' ${tray_div})`"
      else
        tray=`expr $raid_disk + 96`
        raid_disk="sd`printf \\\\$(printf '%03o' ${tray})`"
      fi
      raid_mdsys_list="$raid_mdsys_list /dev/${raid_disk}3"
      if [ "${raid_level}" = "50" ] || [ "${raid_level}" = "60" ] && [ ${line} -gt ${raid56_count} ];then
        raid_mdata_list1="$raid_mdata_list1 /dev/${raid_disk}2"
      else
        raid_mdata_list="$raid_mdata_list /dev/${raid_disk}2"
      fi
      
      clean_disk /dev/${raid_disk} 512
    fi
                                                                            
    line=`expr ${line} + 1`
    if [ ${line} = ${total_line} ];then
      #create
      echo $raid_mdsys_list
      echo $raid_mdata_list
      disk_count=`echo $raid_mdsys_list | wc -w`

      sh -x /img/bin/mksinglesys_md.sh ${disk_count} "${raid_mdsys_list}" 0 > /tmp/create_mksys.50.log 2>&1
      
      disk_count=`echo $raid_mdata_list | wc -w`
      if [ "${raid_level}" = "50" ];then
        echo $raid_mdata_list1
        /sbin/mdadm --create /dev/md30 --force --chunk=64 --level=5 --raid-devices=${disk_count} ${raid_mdata_list} --run > /tmp/create_raid.30.log 2>&1
        /sbin/mdadm --create /dev/md31 --force --chunk=64 --level=5 --raid-devices=${disk_count} ${raid_mdata_list1} --run > /tmp/create_raid.31.log 2>&1
        /sbin/mdadm --create /dev/md0 --force --chunk=64 --level=0 --raid-devices=2 /dev/md30 /dev/md31 --run > /tmp/create_raid.0.log 2>&1
      elif [ "${raid_level}" = "60" ];then
        echo $raid_mdata_list1
        /sbin/mdadm --create /dev/md40 --force --chunk=64 --level=6 --raid-devices=${disk_count} ${raid_mdata_list} --run > /tmp/create_raid.40.log 2>&1
        /sbin/mdadm --create /dev/md41 --force --chunk=64 --level=6 --raid-devices=${disk_count} ${raid_mdata_list1} --run > /tmp/create_raid.41.log 2>&1
        /sbin/mdadm --create /dev/md0 --force --chunk=64 --level=0 --raid-devices=2 /dev/md40 /dev/md41 --run > /tmp/create_raid.0.log 2>&1
      else
        /sbin/mdadm --create /dev/md0 --force --chunk=64 --level=${raid_level} --raid-devices=${disk_count} ${raid_mdata_list} --run > /tmp/create_raid.0.log 2>&1
      fi
      
      mdnum=0
      raid_name=raid${mdnum}
      md_name=md${mdnum}
      rmdir /$raid_name
      mkdir -p /$raid_name
      rmdir /raidsys/$mdnum
      ln -sf /raidsys/$mdnum /$raid_name/sys
      sleep 1
      /img/bin/smbdb.sh raidDefault $raid_name "${raid_id}" $fsmode
      sleep 1
      sqlite /raidsys/0/smb.db "update conf set v='${raid_fs}' where k='filesystem'"
               
      sysnum=`expr $mdnum + 50`

      activedisk=`mdadm -D /dev/md${sysnum} |awk -F'active sync' '/active sync/{disklist=sprintf("%s %s",disklist,substr($2,9,5))}END{print disklist}'`
      for savedisk in $activedisk
      do
        /usr/bin/save_super /dev/$savedisk ${syslog}/sbdump.CR_$savedisk
      done
     
      activedisk=`mdadm -D /dev/${md_name} |awk -F'active sync' '/active sync/{disklist=sprintf("%s %s",disklist,substr($2,9,5))}END{print disklist}'`
      for savedisk in $activedisk
      do
        /usr/bin/save_super /dev/$savedisk ${syslog}/sbdump.CR_$savedisk
      done
      uuid=`get_uuid ${md_name}`
      echo "${uuid}" > /$raid_name/sys/uuid

      nesnum=`expr $mdnum + $mdnum + 30`
      if [ `cat /proc/mdstat | grep "^md$nesnum " | wc -l` -ne 0 ]; then
        activedisk=`mdadm -D /dev/md${nesnum} |awk -F'active sync' '/active sync/{disklist=sprintf("%s %s",disklist,substr($2,9,5))}END{print disklist}'`
        for savedisk in $activedisk
        do
          /usr/bin/save_super /dev/$savedisk ${syslog}/sbdump.CR_$savedisk
        done
        uuid=`get_uuid md$nesnum`
        echo "${uuid}" > /$raid_name/sys/uuid_a
      fi

      nesnum=`expr $mdnum + $mdnum + 31`
      if [ `cat /proc/mdstat | grep "^md$nesnum " | wc -l` -ne 0 ]; then
        activedisk=`mdadm -D /dev/md${nesnum} |awk -F'active sync' '/active sync/{disklist=sprintf("%s %s",disklist,substr($2,9,5))}END{print disklist}'`
        for savedisk in $activedisk
        do
          /usr/bin/save_super /dev/$savedisk ${syslog}/sbdump.CR_$savedisk
        done
        uuid=`get_uuid md$nesnum`
        echo "${uuid}" > /$raid_name/sys/uuid_b
      fi
    fi
  done
  
  cat /proc/mdstat > /tmp/mdstat
  if [ "`cat /tmp/mdstat | grep -c '^md0 '`" = "1" ] && [ "`cat /tmp/mdstat | grep -c '^md50 '`" = "1" ];then
    touch /raidsys/0/ha_raid
    touch /raidsys/0/ha_inited
    echo 19 >${FLAG_HA}
  else
    echo 119 >${FLAG_HA}
  fi
}

rebuild_conf(){
  local virtual_interface

  for key in `sqlite /tmp/conf.db "select k from conf where k like 'ha_%'"`
  do
    value=`sqlite /tmp/conf.db "select v from conf where k='${key}'"`
    if [ "`sqlite /etc/cfg/conf.db "select count(*) from conf where k='${key}'"`" = "0" ];then
      sqlite /etc/cfg/conf.db "insert into conf('k','v') values ('${key}','${value}')"
    else
      sqlite /etc/cfg/conf.db "update conf set v='${value}' where k='${key}'"
    fi
  done

  conf_ha_role=`sqlite /tmp/conf.db "select v from conf where k='ha_role'"`
  if [ "$conf_ha_role" = "0" ];then
    sqlite /etc/cfg/conf.db "update conf set v='1' where k='ha_role'"
    virtual_interface=`sqlite /tmp/conf.db "select v from conf where k='ha_standy_ip1'" | awk -F',' '{print $1}'`
    nic1_ip=`sqlite /tmp/conf.db "select v from conf where k='ha_standy_ip1'" | awk -F',' '{print $2}'`
    nic1_hostname=`sqlite /tmp/conf.db "select v from conf where k='ha_standy_name'"`
  elif [ "$conf_ha_role" = "1" ];then
    sqlite /etc/cfg/conf.db "update conf set v='0' where k='ha_role'"
    virtual_interface=`sqlite /tmp/conf.db "select v from conf where k='ha_primary_ip1'" | awk -F',' '{print $1}'`
    nic1_ip=`sqlite /tmp/conf.db "select v from conf where k='ha_primary_ip1'" | awk -F',' '{print $2}'`
    nic1_hostname=`sqlite /tmp/conf.db "select v from conf where k='ha_primary_name'"`
  fi
  nic1_domainname=`sqlite /tmp/conf.db "select v from conf where k='nic1_domainname'"`

  if [ `echo ${virtual_interface} | grep -c bond` = '0' ];then
    if [ "${virtual_interface}" = "eth0" ];then
      netcard=nic1
      old_ip=`cat /tmp/cfg_nic0 | awk '/ifconfig/&&/netmask/{print $3}'`
      cat /tmp/cfg_nic0 | awk "{gsub(\" $old_ip \",\" $nic1_ip \");print \$0}" > /etc/cfg/cfg_nic0
    elif [ "${virtual_interface}" = "eth1" ];then
      netcard=nic2
      old_ip=`cat /tmp/cfg_nic1 | awk '/ifconfig/&&/netmask/{print $3}'`
      cat /tmp/cfg_nic1 | awk "{gsub(\" $old_ip \",\" $nic1_ip \");print \$0}" > /etc/cfg/cfg_nic1
    else
      netcard=${virtual_interface}
    fi
    for key in `sqlite /tmp/conf.db "select k from conf where k like '${netcard}_%'"`
    do
      value=`sqlite /tmp/conf.db "select v from conf where k='${key}'"`
      if [ "`sqlite /etc/cfg/conf.db "select count(*) from conf where k='${key}'"`" = "0" ];then
        sqlite /etc/cfg/conf.db "insert into conf('k','v') values ('${key}','${value}')"
      else
        sqlite /etc/cfg/conf.db "update conf set v='${value}' where k='${key}'"
      fi
    done
    sqlite /etc/cfg/conf.db "update conf set v='${nic1_ip}' where k='${netcard}_ip'"
  else
    bond_id=`echo ${virtual_interface}|tr -d bond`
    sqlite /etc/cfg/conf.db "update link_base_data set ip='${nic1_ip}' where id='${bond_id}'"
  fi

  sqlite /etc/cfg/conf.db "update conf set v='${nic1_hostname}' where k='nic1_hostname'"
  hostname ${nic1_hostname}
  printf "127.0.0.1\tlocalhost\n${nic1_ip}\t${nic1_hostname}.${nic1_domainname}\t${nic1_domainname}\n" > /etc/hosts  
  printf "${nic1_hostname}.${nic1_domainname}" > /etc/HOSTNAME

  cp -f /tmp/resolv.conf /etc/
  #cp -f /tmp/conf.db /etc/cfg/
  sqlite /etc/cfg/conf.db "update conf set v='1' where k='ha_enable'"
  sync

}

rebuild_check(){
  echo rebuild_check
  local ipx3=$1
  local interface=$2
  local ip3=`echo ${ipx3} | awk -F. '{printf "%s.%s.%s.%s\n",$1,$2,$3,255-$4}'`
  echo 16 > ${FLAG_HA}
  if [ "${interface}" = "" ];then
    interface=${HB_LINE}
  fi

  ifconfig ${interface} down
  sleep 10
  ifconfig ${interface} ${ip3} netmask 255.255.255.0 broadcast +
  sleep 5
  
  cat /proc/mdstat > /tmp/mdstat
  if [ -f /raidsys/0/ha_raid ] && [ -f /raidsys/0/ha_inited ];then
    if [ "`cat /tmp/mdstat | grep -c '^md0 '`" = "1" ] && [ "`cat /tmp/mdstat | grep -c '^md50 '`" = "1" ];then
      echo 16.5 > ${FLAG_HA}
    fi
  fi

  echo wait > /tmp/ha_rebuild_flag
  ${WPUT} /tmp/ha_rebuild_flag ftp://nas:nas@${ipx3}:3694/ha_rebuild_flag
  rebuild_result=""
  for count in 0 1 2 3 4 5
  do
    ${WGET} "ftp://nas:nas@${ipx3}:3694/ha_rebuild_flag" --directory-prefix=/tmp/
    rebuild_result=`cat /tmp/ha_rebuild_flag`
    rm -f /tmp/ha_rebuild_flag
    if [ "$rebuild_result" = "ok" ];then
      break
    fi
    sleep 5
  done

  if [ "$rebuild_result" != "ok" ];then
    echo 'get_setting_fail' > ${CONF_HW}_result
  else
    ${HA_CHECK} check ${ipx3} > ${CONF_HW}_result
  fi
          
  if [ "`cat ${CONF_HW}_result | wc -l`" = "0" ];then
    rm -f /tmp/conf.db
    count=0
    while [ ! -f /tmp/conf.db ]
    do
      ${WGET} "ftp://nas:nas@${ipx3}:3694/www/conf.db" --directory-prefix=/tmp/
      ${WGET} "ftp://nas:nas@${ipx3}:3694/www/cfg_nic0" --directory-prefix=/tmp/
      ${WGET} "ftp://nas:nas@${ipx3}:3694/www/cfg_nic1" --directory-prefix=/tmp/
      ${WGET} "ftp://nas:nas@${ipx3}:3694/www/resolv.conf" --directory-prefix=/tmp/
      sleep 5
      count=`expr $count + 1`
      if [ "$count" = "10" ];then
        break
      fi
    done
    
    if [ ! -f /tmp/conf.db ] || [ "`sqlite /tmp/conf.db "select v from conf where k='ha_enable'"`" != "1" ];then
      echo 117 > ${FLAG_HA}
      if [[ "${interface}" =~ ^eth* ]];then
        ifconfig "${interface}" down
      else
        /img/bin/rc/rc.tengb stop
        /img/bin/rc/rc.tengb start
      fi
      return
    else
      rebuild_conf
    fi

    if [ -f /raidsys/0/ha_raid ] && [ -f /raidsys/0/ha_inited ] && [ "`cat /tmp/mdstat | grep -c '^md0 '`" = "1" ] && [ "`cat /tmp/mdstat | grep -c '^md50 '`" = "1" ];then
      echo 19 >${FLAG_HA}
    else
      echo 17 > ${FLAG_HA}
      rm -f /tmp/ha_config_rebuild
      ${WGET} "ftp://nas:nas@${ipx3}:3694/www/ha_config_rebuild" --directory-prefix=/tmp/
      rebuild_create
    fi
  else
    echo 117 > ${FLAG_HA}
    if [[ "${interface}" =~ ^eth* ]];then
      ifconfig "${interface}" down
    else
      /img/bin/rc/rc.tengb stop
      /img/bin/rc/rc.tengb start
    fi
  fi
  return
}

#################################################
##      Main code
#################################################

case "$1"
in
  new)
    if [ "$2" = "check" ];then
      new_check
    elif [ "$2" = "create" ];then
      new_create
    fi
    ;;
  rebuild)
    if [ "$2" = "serv" ];then
      rebuild_serv $3
    elif [ "$2" = "init" ];then
      rebuild_init
    elif [ "$2" = "check" ];then
      rebuild_check $3 $4
    elif [ "$2" = "create" ];then
      rebuild_create
    fi
    ;;
  *)
    echo "Usage: $0 {new|rebuild} {serv (start|stop)|init|check target_ip interface|create}"
    ;;
esac

