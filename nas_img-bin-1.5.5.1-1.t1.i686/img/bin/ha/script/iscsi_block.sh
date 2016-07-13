#!/bin/sh
if [ $# -lt 3 ];then
	echo $0 HB_LINE IP3_other start/stop/list p/s
	exit 1
fi

IF=$1
IP=$2
ACT=$3
ROLE=$4

. /etc/ha/script/conf.ha

This_IP=`ifconfig ${IF} | \
	awk '/inet addr:/{split($2,ip,":");print ip[2]}'`
	
This_MAC=`${DEV_MAP} ${IF} ${This_IP} mac`

Other_MAC=`${DEV_MAP} ${IF} ${IP} mac`

domainname=`/usr/bin/sqlite ${confdb} "select v from conf where k='nic1_domainname'"|awk -F. '{print $1 " " $2 " " $3}'`

revdomain=`reverse_domain $domainname`

if [ "$ACT" = "start" ];then
    if [ "$ROLE" = "p" ];then
#	if [ "`${DEV_MAP} ${IF} ${This_IP}`" = "NO_DEVICE" ];then
		iscsiadm -m node -T iqn.2010-08.${revdomain}.nas:iscsi.ha.${This_MAC} -p ${This_IP}:3260 --login > /dev/null 2>&1
#		if [ "$?" = "1" ];then exit 1; fi
#	fi
   fi
   if [ "$ROLE" = "s" ];then
#	if [ "`${DEV_MAP} ${IF} ${IP}`" = "NO_DEVICE" ];then
		iscsiadm -m node -T iqn.2010-08.${revdomain}.nas:iscsi.ha.${Other_MAC} -p ${IP}:3260 --login > /dev/null 2>&1
#		if [ "$?" = "1" ];then exit 1; fi
#	fi
   fi
	exit 0
elif [ "$ACT" = "stop" ];then
    if [ "$ROLE" = "p" ];then
#	if [ "`${DEV_MAP} ${IF} ${This_IP}`" != "NO_DEVICE" ];then
		iscsiadm -m node -T iqn.2010-08.${revdomain}.nas:iscsi.ha.${This_MAC} -p ${This_IP}:3260 --logout > /dev/null 2>&1
#		if [ "$?" = "1" ];then exit 1; fi
#	fi
   fi
   if [ "$ROLE" = "s" ];then
#	if [ "`${DEV_MAP} ${IF} ${IP}`" != "NO_DEVICE" ];then
		iscsiadm -m node -T iqn.2010-08.${revdomain}.nas:iscsi.ha.${Other_MAC} -p ${IP}:3260 --logout > /dev/null 2>&1
#		if [ "$?" = "1" ];then exit 1; fi
#	fi
    fi
	exit 0
elif [ "$ACT" = "list" ];then
    if [ "$ROLE" = "p" ];then
	iscsiadm -m discovery -tst --portal ${This_IP}:3260
   fi
   if [ "$ROLE" = "s" ];then
	iscsiadm -m discovery -tst --portal ${IP}:3260
   fi
fi
exit 1
