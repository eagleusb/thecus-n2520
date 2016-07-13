#!/bin/sh
if [ $# -lt 3 ];then
	echo $0 Pri_WAN HB_LINE add md/remove
	exit 1
fi

Pri_IP=$1
IF=$2
ACT=$3
MD=$4

. /etc/ha/script/conf.ha

domainname=`/usr/bin/sqlite ${confdb} "select v from conf where k='nic1_domainname'"|awk -F. '{print $1 " " $2 " " $3}'`
ha_name=`/usr/bin/sqlite ${confdb} "select v from conf where k='ha_virtual_name'" |tr [:upper:] [:lower:]`

revdomain=`reverse_domain $domainname`

INIT_IQN=`${RC_INITIATOR} initiator_iqn | tr /A-Z/ /a-z/`
PRI_IQN="iqn.2007-08.${revdomain}:stackable-server.${ha_name}"

This_IP=`ifconfig ${IF} | \
        awk '/inet addr:/{split($2,ip,":");print ip[2]}'`
        
This_MAC=`${DEV_MAP} ${IF} ${This_IP} mac`

Export_IQN="iqn.2010-08.${revdomain}.nas:iscsi.ha.${This_MAC}"
Export_IQN_Enable="${TARGET_ISCSI}/${Export_IQN}/tpgt_1/enable"

remove_export(){
    if [ -d "${TARGET_ISCSI}/${Export_IQN}" ];then
	echo -n 0 > ${Export_IQN_Enable}
	rmdir ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/np/*

        for TMP_DIR in `ls ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/acls/`
        do
            for TMP_LUN in `ls ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/acls/${TMP_DIR}/ | grep "lun_"`
            do
		rm ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/acls/${TMP_DIR}/${TMP_LUN}/${TMP_LUN}
		rmdir ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/acls/${TMP_DIR}/${TMP_LUN}
            done
	    rmdir ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/acls/${TMP_DIR}
        done
		
        for TMP_DIR in `ls ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/lun/`

        do
            for TMP_LUN in `ls ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/lun/${TMP_DIR}/ | grep "lio_"`
            do
		rm ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/lun/${TMP_DIR}/${TMP_LUN}
            done
            rmdir ${TARGET_ISCSI}/${Export_IQN}/tpgt_1/lun/${TMP_DIR}
        done

        rmdir ${TARGET_ISCSI}/${Export_IQN}/tpgt_1
	rmdir ${TARGET_ISCSI}/${Export_IQN}
    fi

    #disable the lun and remove the folder in the kernel, and delete the files
    lun_list=`ls ${TARGET_CORE}/iblock_0/`
    for lun in ${lun_list}
    do
        if [ -d "${TARGET_CORE}/iblock_0/${lun}" ];then
            rmdir ${TARGET_CORE}/iblock_0/${lun}
        fi
    done

    rmdir ${TARGET_CORE}/iblock_0/
}

if [ "$ACT" = "add" ];then
	#echo $ACT	
	${RC_ISCSI} ha ${PRI_IQN} ${MD} > /dev/null 2>&1
elif [ "$ACT" = "remove" ];then
	#echo $ACT	
	remove_export > /dev/null 2>&1
fi

iscsiadm -m discovery -tst --portal ${This_IP}:3260 2> /dev/null | grep -c "${Export_IQN}"
