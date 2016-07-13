#!/bin/sh
. /etc/ha/script/conf.ha
. /etc/ha/script/func.ha

while true
do
    /usr/bin/lockfile /var/lock/ha_monitor.lock
    
    if [ "`iscsiadm -m session|grep -c ${ipx3}:3260,1`" = "1" ];then
        ping -c 1 -q -I ${HB_LINE} ${ipx3}
        if [ "$?" != "0" ];then
            ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop s
            iscsiadm -m session
        fi
    else
        ping -c 1 -q -I ${HB_LINE} ${ipx3}
        if [ "$?" = "0" ];then
            iscsiadm -m discovery -tst --portal ${ipx3}:3260 > /dev/null 2>&1
            if [ x$? = x0 ];then
                ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop s
                ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} start s
            fi
        fi
    fi            
    rm -f /var/lock/ha_monitor.lock
    sleep 5
done

