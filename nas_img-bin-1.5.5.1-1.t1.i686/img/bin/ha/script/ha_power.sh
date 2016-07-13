#!/bin/sh
. /img/bin/ha/script/conf.ha

pidof_heartbeat=`pidof heartbeat`

if [ -f /tmp/ha_role ] && [ "${pidof_heartbeat}" != "" ];then
  if [ "$1" = "init" ] && [ "$2" = "halt" ];then
    /img/bin/ha/script/nas_act.sh halt init
  elif [ "$1" = "init" ] && [ "$2" = "reboot" ];then
    /img/bin/ha/script/nas_act.sh reboot init
  fi
else
  if [ "$1" = "init" ] && [ "$2" = "halt" ];then
    rm ${FLAG_POWER}
    echo halt > ${FLAG_POWER}
    for i in 0 1 2 3 4 5
    do
      if [ -f ${FLAG_HA} ];then
        CAT_FLAG_HA=`cat ${FLAG_HA}`
        if [ "${CAT_FLAG_HA}" = "1" ];then 
          /img/bin/sys_halt &
          #echo /img/bin/sys_halt 
          break
        fi
      fi
      sleep 1
    done
    if [ "${CAT_FLAG_HA}" != "1" ];then
      echo 101 > ${FLAG_HA}
    fi
  elif [ "$1" = "init" ] && [ "$2" = "reboot" ];then
    rm ${FLAG_POWER}
    echo reboot > ${FLAG_POWER}
    for i in 0 1 2 3 4 5
    do
      if [ -f ${FLAG_HA} ];then
        CAT_FLAG_HA=`cat ${FLAG_HA}`
        if [ "${CAT_FLAG_HA}" = "3" ];then 
          /img/bin/sys_reboot &
          #echo /img/bin/sys_reboot
          break
        fi
      fi
      sleep 1
    done
    if [ "${CAT_FLAG_HA}" != "3" ];then
      echo 103 > ${FLAG_HA}
    fi
  fi
fi

