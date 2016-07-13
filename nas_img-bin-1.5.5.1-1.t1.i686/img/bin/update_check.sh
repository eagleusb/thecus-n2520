#!/bin/sh
YUMEX="/img/bin/yumex"
UPDATE_CHECK="/img/bin/update_check.sh"
LOGEVENT="/img/bin/logevent/event"
crond_conf="/etc/cfg/crond.conf"
update_list="/etc/yum/update.list"
tmp_list="/var/tmp/yum.upgrade.list"

add_cron(){
    cron_exist=`cat ${crond_conf} | grep "${UPDATE_CHECK}"`
    if [ "${cron_exist}" == "" ];then
        hex=`ifconfig eth0 | awk '/ HWaddr /{print $5}' | awk -F":" '{print $6}'`
        baseint=`echo $((16#${hex}))`
        total=`echo $((${baseint}*5))`
        hour=`echo $((${total}/60))`
        min=`echo $((${total}%60))`

        echo "${min} ${hour} * * * ${UPDATE_CHECK} check_update > /dev/null 2>&1" >> ${crond_conf}
        /usr/bin/killall crond
        sleep 1
        /usr/sbin/crond
        /usr/bin/crontab ${crond_conf} -u root
    fi
}

del_cron(){
    cron_exist=`cat ${crond_conf} | grep "${UPDATE_CHECK}"`
    if [ "${cron_exist}" != "" ];then
        cat ${crond_conf} | grep -v "${UPDATE_CHECK}" > /tmp/crond.conf1
        cp -f /tmp/crond.conf1 ${crond_conf}
        /usr/bin/killall crond
        sleep 1
        /usr/sbin/crond
        /usr/bin/crontab ${crond_conf} -u root
        rm -f /tmp/crond.conf1
    fi
}

check_update(){
    ${YUMEX} --check-update > ${tmp_list}
    ret=`echo $?`

    if [ "`cat ${tmp_list}`" == "" ];then
        echo "[]" > ${tmp_list}
    fi

    if [ "${ret}" == 0 ] && [ "`diff ${update_list} ${tmp_list}`" != "" ];then
        cp -f ${tmp_list} ${update_list}
	
	if [ "`cat ${update_list} | grep '"update"'`" != "" ];then
            model=`cat /etc/manifest.txt | awk '/type/{print toupper($2)}'`
            ${LOGEVENT} 997 492 info email ${model}
        fi
    fi
}

start(){
    if [ ! -f ${update_list} ];then
        echo "[]" > ${update_list}
    fi

    if [ -f ${YUMEX} ];then
        add_cron
        check_update
    else
        del_cron
    fi
}

if [ ! -f ${YUMEX} ];then
    echo "Need ${YUMEX} to support!"
    exit
fi

case "$1" in
    boot|start)
        start
        ;;
    check_update)
        check_update
        ;;
    del_cron)
        del_cron
        ;;
    *)
        echo "Usage: {boot|start|check_update}" >&2
        exit 1
        ;;
esac
  
