#!/bin/sh
if [ ! -f /tmp/ha_role ];then
  exit 1
fi
act=$1
attr1=$2
attr2=$3
attr3=$4
attr4=$5

echo $0 $act $attr1 $attr2 $attr3 $attr4

#################################################
##      Include file
#################################################
. /etc/ha/script/conf.ha
. /etc/ha/script/func.ha

#################################################
##      Variable
#################################################
role=`cat /tmp/ha_role`

#################################################
##      Init FIFO
#################################################
#rm -f ${HA_NAS_FIFO}
#mkfifo ${HA_NAS_FIFO}

#################################################
##      Function
#################################################
sys_init(){
  echo `date`-sys_init $@ >> /tmp/ha_debug_log
}

check_ver(){
  if [ "${role}" = "active" ];then
    if [ "${attr1}" = "ok" ];then
      echo "${attr2}" > ${HA_NAS_FIFO}
    fi
  else
    ${NAS_PIE} resp ${NAS_ACT} check_ver ok `cat /etc/version`
  fi
}

disable_ha(){
  if [ "${role}" = "active" ];then
    if [ "${attr1}" = "ok" ];then
      echo ok > ${HA_NAS_FIFO}
    fi
  else
    ${sqlite} ${cfgdb} "update conf set v='0' where k='ha_enable'"
    ${sqlite} ${confdb} "update conf set v='0' where k='ha_enable'"
    ${NAS_PIE} resp ${NAS_ACT} disable_ha ok
  fi
}

hi(){
  if [ "${role}" = "active" ];then
    if [ "${attr1}" = "ok" ];then
      echo ok > ${HA_NAS_FIFO}
    fi
  else
    ${NAS_PIE} resp ${NAS_ACT} hi ok
  fi
}

update_line(){
  stat_line
}

sys_halt(){
  echo `date`-sys_halt $@ >> /tmp/ha_debug_log
  if [ "${role}" = "active" ];then
    if [ "${attr1}" = "init" ];then
      echo 0 > ${FLAG_HA}
      rm -f ${HA_NAS_FIFO}
      mkfifo ${HA_NAS_FIFO}
      exec 43<> ${HA_NAS_FIFO}
      ${NAS_PIE} send ${NAS_ACT} halt
      read -t 5 result <&43
      rm -f ${HA_NAS_FIFO}
      if [ "${result}" = "ok" ];then
        echo `date`-sys_halt ret ${result} >> /tmp/ha_debug_log
        echo 1 > ${FLAG_HA}
        /img/bin/sys_halt & 
      else
        echo `date`-sys_halt ret ${result} >> /tmp/ha_debug_log
        echo 101 > ${FLAG_HA}
      fi
    elif [ "${attr1}" = "ok" ];then
      echo `date`-sys_halt ${attr1} >> /tmp/ha_debug_log
      echo ok > ${HA_NAS_FIFO}
    elif [ "${attr1}" = "fail" ];then
      echo `date`-sys_halt ${attr1} >> /tmp/ha_debug_log
      echo fail > ${HA_NAS_FIFO}
    fi
  elif [ "${role}" = "standby" ];then
    echo 0 > ${FLAG_HA}
    if [ -f ${FLAG_HA} ] && [ "`cat ${FLAG_HA}`" = "0" ] ;then
      ${NAS_PIE} resp ${NAS_ACT} halt ok
      echo 1 > ${FLAG_HA}
    else
      ${NAS_PIE} resp ${NAS_ACT} halt fail
      echo 101 > ${FLAG_HA}
    fi
  fi
}

sys_reboot(){
  echo `date`-sys_reboot $@ >> /tmp/ha_debug_log
  if [ "${role}" = "active" ];then
    if [ "${attr1}" = "init" ];then
      echo 2 > ${FLAG_HA}
      rm -f ${HA_NAS_FIFO}
      mkfifo ${HA_NAS_FIFO}
      exec 43<> ${HA_NAS_FIFO}
      ${NAS_PIE} send ${NAS_ACT} reboot
      read -t 5 result <&43
      rm -f ${HA_NAS_FIFO}
      if [ "${result}" = "ok" ];then
        echo `date`-sys_reboot ret ${result} >> /tmp/ha_debug_log
        echo 3 > ${FLAG_HA}
        /img/bin/sys_reboot &
      else
        echo `date`-sys_reboot ret ${result} >> /tmp/ha_debug_log
        echo 103 > ${FLAG_HA}
      fi
    elif [ "${attr1}" = "ok" ];then
      echo `date`-sys_reboot ${attr1} >> /tmp/ha_debug_log
      echo ok > ${HA_NAS_FIFO}
    elif [ "${attr1}" = "fail" ];then
      echo `date`-sys_reboot ${attr1} >> /tmp/ha_debug_log
      echo fail > ${HA_NAS_FIFO}
    fi
  elif [ "${role}" = "standby" ];then
    echo 2 > ${FLAG_HA}
    if [ -f ${FLAG_HA} ] && [ "`cat ${FLAG_HA}`" = "2" ];then
      ${NAS_PIE} resp ${NAS_ACT} reboot ok
      echo 3 > ${FLAG_HA}
    else
      ${NAS_PIE} resp ${NAS_ACT} reboot fail
      echo 103 > ${FLAG_HA}
    fi
  fi
}

sys_upgrade(){
  echo `date`-sys_upgrade $@ >> /tmp/ha_debug_log
}

raid_check(){
  echo `date`-hw_check $@ >> /tmp/ha_debug_log
  if [ "${role}" = "standby" ];then
    echo 6 > ${FLAG_HA}
    ${HA_CHECK} check ${ipx3} > ${CONF_HW}_result
    if [ "`cat ${CONF_HW}_result | wc -l`" = "0" ];then
      echo 7 > ${FLAG_HA}
      ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx3}:3694/www/ha_flag
    else
      echo 107 > ${FLAG_HA}
      ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx3}:3694/www/ha_flag
      return
    fi
  fi
}

raid_create(){
  echo `date`-raid_create $@ >> /tmp/ha_debug_log
}

schedule(){
  echo `date`-schedule $@ >> /tmp/ha_debug_log
  if [ "${role}" = "active" ];then
    if [ "${attr1}" = "sync" ];then
      nas_ftpd start
      cp -f /etc/cfg/conf.db /tmp/www/conf.db
      cat /etc/cfg/crond.conf | grep 'power schedule' > /tmp/www/crond.conf
      rm -f ${HA_NAS_FIFO}
      mkfifo ${HA_NAS_FIFO}
      exec 43<> ${HA_NAS_FIFO}
      ${NAS_PIE} send ${NAS_ACT} schedule
      read -t 10 result <&43
      rm -f ${HA_NAS_FIFO}
      if [ "${result}" = "ok" ];then
        echo `date`-schedule ret ${result} >> /tmp/ha_debug_log
      else
        echo `date`-schedule ret ${result} >> /tmp/ha_debug_log
      fi
      nas_ftpd stop
    elif [ "${attr1}" = "ok" ];then
      echo `date`-schedule ${attr1} >> /tmp/ha_debug_log
      echo ok > ${HA_NAS_FIFO}
    elif [ "${attr1}" = "fail" ];then
      echo `date`-schedule ${attr1} >> /tmp/ha_debug_log
      echo fail > ${HA_NAS_FIFO}
    fi
  elif [ "${role}" = "standby" ];then
    rm -f /tmp/conf.db
    rm -f /tmp/crond.conf
    ${WGET} "ftp://nas:nas@${ipx3}:3694/www/conf.db" --directory-prefix=/tmp/
    ${WGET} "ftp://nas:nas@${ipx3}:3694/www/crond.conf" --directory-prefix=/tmp/
    if [ -f /tmp/conf.db ] && [ -f /tmp/crond.conf ];then
      cat /etc/cfg/crond.conf | grep -v 'power schedule' > /tmp/crond.conf.tmp
      cat /tmp/crond.conf >> /tmp/crond.conf.tmp
      cp -f /tmp/crond.conf.tmp /etc/cfg/crond.conf
      schedule_on_key=`${sqlite} /tmp/conf.db "select k from conf where k = 'schedule_on'"`
      schedule_on_value=`${sqlite} /tmp/conf.db "select v from conf where k = 'schedule_on'"`
      ${sqlite} ${cfgdb} "update conf set v='${schedule_on_value}' where k='${schedule_on_key}'"
      
      for key in `${sqlite} /tmp/conf.db "select k from conf where k like 'power_schedule%'"`
      do
        value=`${sqlite} /tmp/conf.db "select v from conf where k = '${key}'"`
        ${sqlite} ${cfgdb} "update conf set v='${value}' where k='${key}'"
      done
      sync
      ${NAS_PIE} resp ${NAS_ACT} schedule ok
      /img/bin/sys_halt schedule_ha &
    else
      ${NAS_PIE} resp ${NAS_ACT} schedule fail
    fi
  fi
}

raid_damaged(){
  touch /tmp/ha_raid_damaged
}

#################################################
##      Main code
#################################################

case "$1"
in
        init)
                sys_init
                ;;
        halt)
                sys_halt
                ;;
        reboot)
                sys_reboot
                ;;
        upgrade)
                sys_upgrade
                ;;
        raid_check)
                raid_check
                ;;
        raid_create)
                raid_create
                ;;
        hi)
                hi
                ;;
        disable_ha)
                disable_ha
                ;;
        check_ver)
                check_ver
                ;;
        schedule)
                schedule
                ;;
        update_line)
                update_line
                ;;
        raid_damaged)
                raid_damaged
                ;;
        *)
                echo "Usage: $0 {init|halt|reboot|upgrade|raid_check|raid_create|hi|disable_ha|check_ver|schedule|update_line|raid_damaged}"
                ;;
esac
