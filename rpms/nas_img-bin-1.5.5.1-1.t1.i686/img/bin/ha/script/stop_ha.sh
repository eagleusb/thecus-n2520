#!/bin/sh
action=$1
. /img/bin/ha/script/conf.ha
. /img/bin/ha/script/func.ha
ha_role=`cat /tmp/ha_role`
if [ "`pidof heartbeat`" = "" ];then
  exit
fi
if [ -f /tmp/ha_stop ];then
  exit
fi
if [ "${action}" = "damaged" ];then
  ${NAS_PIE} send ${NAS_ACT} raid_damaged 
fi 
touch /tmp/ha_stop
/img/bin/ha/script/rc.ha hbstop &
ha_wait=0
while [ -f /tmp/ha_stop ];do
  sleep 12
  ha_wait=`expr $ha_wait + 1`
  if [ $ha_wait -gt 5 ];then
    killall heartbeat
    /img/bin/ha/script/rc.ha stop
    rm -f /tmp/ha_stop
  fi
done

/sbin/ifconfig ${HB_LINE} 0.0.0.0 down

if [ -f /tmp/ha_raid_damaged ];then
  rm /tmp/ha_raid_damaged
fi 

if [ "$ha_role" = "standby" ];then
  touch /tmp/ha_stop
  /img/bin/ha/script/rc.ha stop_standby
fi

if [ "${action}" = "damaged" ];then
  ${sqlite} /etc/cfg/conf.db "update conf set v='0' where k='ha_enable'"
  ${sqlite} ${confdb} "update conf set v='0' where k='ha_enable'"
fi
