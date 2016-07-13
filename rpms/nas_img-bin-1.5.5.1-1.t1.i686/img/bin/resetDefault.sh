#!/bin/sh 
PIC_MSG=/img/bin/pic.sh
touch /etc/ResetDefault
/bin/sync

${PIC_MSG} LCM_MSG "System" "Reset to default"
echo "Buzzer 1" > /proc/thecus_io
sleep 3
echo "Buzzer 0" > /proc/thecus_io

#clear the quota limit
/img/bin/rc/rc.user_quota reset_quota

#service stop
/img/bin/service stop
#erase log file
if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
	/bin/cat /dev/null > /syslog/error
	/bin/cat /dev/null > /syslog/information
	/bin/cat /dev/null > /syslog/warning
	rm /syslog/upgrade.log
	rm -f /syslog/error_dist
else
	/bin/cat /dev/null > /var/log/error
	/bin/cat /dev/null > /var/log/information
	/bin/cat /dev/null > /var/log/warning
	rm -f /raid/sys/error_dist
fi
#delete winbindd temp file
/bin/rm -rf /var/lib/samba/winbindd_idmap.tdb
/bin/rm -rf /var/lib/samba/winbindd_cache.tdb

#delete share folder
#/bin/rm -rf /raid/share*
/bin/rm -rf /raid/tmp/*
rm -rf /etc/mediaserver.conf

cp -f /img/bin/default_cfg/default/etc/cfg/shortcut.db /etc/cfg/shortcut.db

#disable user module
if [ -f /raid/data/module/cfg/module.db ];then
        mods=`/usr/bin/sqlite /raid/data/module/cfg/module.db "select name from module where enable = 'Yes'"`
        for mod in $mods
        do
                /raid/data/module/"$mod"/shell/enable.sh "$mod" Yes
        done
        /usr/bin/sqlite /raid/data/module/cfg/module.db "update module set enable = 'No' where enable = 'Yes'"
fi

if [ -f "/syslog/sys_log.db" ];then
    /usr/bin/sqlite /syslog/sys_log.db "delete from sysinfo"
fi

#Reduce the time at OQA stage.
#If memory release failed, we will show on system log page.
set_log(){
        local SQLITE="/usr/bin/sqlite"
        local DB_PATH="/syslog/sys_log.db"
        local HOSTNAEM=`cat /var/run/model`
        local TIME=`date +"%Y-%m-%d %H:%M:%S"`
        local ERROR_MSG="Kernel command reset fail."

        $SQLITE $DB_PATH "insert into sysinfo(Date_time,Details,level) values('${TIME}',\"[${HOSTNAME}] : ${ERROR_MSG}\",'Error')"
}

HAS_XBMC=`rpm -q XBMC| awk -F'-' '{print $2}'`
if [ -n "$HAS_XBMC" ];then
    XBMC_EN="-xbmc"
else
    XBMC_EN=""
fi

if [ -n "`grep nmyx25 /proc/mtd`" ];then
    TYPE="flash"
    DEVICE="/dev/mtdblock0"
    # check RAM size
    RAM_SIZE="`awk '/MemTotal/ {print $2}' /proc/meminfo`"
    [ "$RAM_SIZE" -lt 1048576 ] && MEM="1g" || MEM="2g"
    BOOTS="boots_${MEM}${XBMC_EN}.bin"
    [ -e "$DEVICE" ] && \
        /usr/local/sbin/ceimggen -u $TYPE $DEVICE SCRIPT /boot/$BOOTS
    RESULT=$?
    if [ "$RESULT" != "0" ];then
        set_log
    fi
fi

/usr/bin/sqlite /etc/cfg/stackable.db "delete from stackable"
/img/bin/smbdb.sh resetDefault
old_master_id=`ls -la /raid |awk -F\/ '{print $3}' | awk -F'raid' '{print $2}'`
/img/bin/set_masterraid.sh $old_master_id
rm /etc/cfg/quota.db
rm /etc/cfg/backup.db
/img/bin/sys_reboot

