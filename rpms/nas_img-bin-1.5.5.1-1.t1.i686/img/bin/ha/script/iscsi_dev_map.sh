#/bin/sh
if [ $# -lt 3 ];then
	echo $0 IF IP [dev lun]/mac/[lun dev]
	exit 1
fi
                
IF=$1
IP=$2
cmd=$3
lun=$4

. /etc/ha/script/conf.ha

domainname=`/usr/bin/sqlite ${confdb} "select v from conf where k='nic1_domainname'"|awk -F. '{print $1 " " $2 " " $3}'`

revdomain=`reverse_domain $domainname`


This_IP=`ifconfig ${IF} | \
	awk '/inet addr:/{split($2,ip,":");print ip[2]}'`
	
if [ "${IP}" = "${This_IP}" ];then
	MAC=`ifconfig ${IF} | \
		awk '/HWaddr/{split($5,mac,":");printf "%s%s%s%s%s%s\n",mac[1],mac[2],mac[3],mac[4],mac[5],mac[6]}' | \
		tr /A-Z/ /a-z/`
else
	master_data=`readlink /raid`
	master_sys=`readlink ${master_data}/../sys`

	arping -q -f -w 0 -I $IF $IP
	if [ "$?" = "0" ];then
		MAC=`arp -n -i ${IF} | grep ${IP} | \
			awk '{split($4,mac,":");printf "%s%s%s%s%s%s\n",mac[1],mac[2],mac[3],mac[4],mac[5],mac[6]}'`
		if [ -d ${master_sys}/ha ];then
			echo $MAC > ${master_sys}/ha/${IP}.MAC
		fi
        elif [ -f ${master_sys}/ha/${IP}.MAC ];then
                MAC=`cat ${master_sys}/ha/${IP}.MAC`
	fi
fi

if [ "$cmd" = "mac" ];then
	echo $MAC
else
	if [ x$MAC = x ] || [ "`iscsiadm -m session 2>&1 | grep -c "iqn.2010-08.${revdomain}.nas:iscsi.ha.${MAC}"`" = "0" ];then
		echo NO_DEVICE
	else
		if [ "$cmd" = "lun" ];then
			iscsiadm -m session -P 3 | \
			awk '{ \
				if ($1=="Target:"){printf "\n%s ",$2} \
				else if($2=="Channel" && $6=="Lun:"){printf "%s ",$7} \
				else if($1=="Attached" && $2=="scsi"){printf "%s ",$4} \
			}' | \
			awk "/iscsi.ha.$MAC/{ \
				if (\$3==\"$lun\"){print \$2} \
				else if (\$5==\"$lun\"){print \$4} \
				else if (\$7==\"$lun\"){print \$6} \
				else if (\$9==\"$lun\"){print \$8} \
				else if (\$11==\"$lun\"){print \$10} \
			}" 
		else
			iscsiadm -m session -P 3 | \
			awk '{ \
				if ($1=="Target:"){printf "\n%s ",$2} \
				else if($2=="Channel" && $6=="Lun:"){printf "%s ",$7} \
				else if($1=="Attached" && $2=="scsi"){printf "%s ",$4} \
			}' | \
			awk "/iscsi.ha.$MAC/{ \
				if (\$2==$lun){print \$3} \
				else if (\$4==$lun){print \$5} \
				else if (\$6==$lun){print \$7} \
				else if (\$8==$lun){print \$9} \
				else if (\$10==$lun){print \$11} \
			}" 
		fi
	fi	
fi
