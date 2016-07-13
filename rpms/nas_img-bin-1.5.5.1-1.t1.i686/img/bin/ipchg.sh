#!/bin/sh
#/img/bin/ipchg.sh $interface $ip $subnet $broadcast
ip=$2
TMPCHECKFILE="/var/tmp/net_init"

if [ "$1" = "eth0" ]; then
    STRSQL="select v from conf where k='nic1_hostname'"
    hostname=`/usr/bin/sqlite /etc/cfg/conf.db "${STRSQL}"`
    STRSQL="select v from conf where k='nic1_domainname'"
    domainname=`/usr/bin/sqlite /etc/cfg/conf.db "${STRSQL}"`
    echo "127.0.0.1         localhost" > /etc/hosts
    echo "${ip}             ${hostname}.${domainname}       ${hostname}" >> /etc/hosts
fi

NetVal=`cat ${TMPCHECKFILE}`
if [ "$NetVal" == "0" ];then
    /img/bin/rc/rc.upnpd restart
    /img/bin/rc/rc.samba restart
    /img/bin/rc/rc.ddns stop
    /img/bin/rc/rc.ddns boot
    /img/bin/rc/rc.tftp stop
    /img/bin/rc/rc.tftp boot 
    /img/bin/rc/rc.iscsi stop
    /img/bin/rc/rc.iscsi boot
fi
