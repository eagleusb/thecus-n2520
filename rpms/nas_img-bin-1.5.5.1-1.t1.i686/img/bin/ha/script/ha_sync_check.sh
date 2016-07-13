#!/bin/sh 
exit
echo "`date`-HA_SYNC_CHECK start" >> /tmp/ha_disk.log
ha_initdead=`sqlite /etc/cfg/conf.db "select v from conf where k='ha_initdead'"`
#ha_initdead=`expr ${ha_initdead} + ${ha_initdead}`
interval=1
count=0
touch /var/lock/ha_boot
while [ ${count} -le ${ha_initdead} ] && [ -f /var/lock/ha_boot ]
do
    count=`expr ${count} + ${interval}`
    sleep ${interval}
done
rm /var/lock/ha_boot
echo "`date`-HA_SYNC_CHECK end" >> /tmp/ha_disk.log
