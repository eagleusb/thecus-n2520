#!/bin/sh 
# test_c $ip $mode $task_name $user $passwd
T_VPN_IP=$1
T_MODE=$2
T_NAME=$3
T_ID=$4
T_PW=$5

ln -s /root/.netrc /

T_SAVED_SYNC=`cat /proc/sys/net/ipv4/tcp_syn_retries`
DEF_PORT="21"
DEF_RETRY="1"
T_I="50"

cmd1="/img/bin/nsync/f1"
cmd2="/img/bin/nsync/f2"
cmd3="/img/bin/nsync/f3"
cmd4="/img/bin/nsync/f4"
VPN_CONNECTED="0"
MY_MAC=`ifconfig eth0 |grep eth0|awk '{print $5}'`
MY_TMP=`echo "/tmp/msg.${MY_MAC}"`
#echo "Mode=$T_MODE"
testpath="/var/run"
if [ ! -e ${testpath} ];then
	mkdir -p ${testpath}
fi
rm -rf ${testpath}/vpn.${T_NAME}.pid
rm -rf ${testpath}/vpn.${T_NAME}.gw
rm -rf ${testpath}/vpn.${T_NAME}.user

disp_result() {
	RET_CODE=$1
	VAL=$2
	#echo "VPN?[$VPN_CONNECTED]"
	if [ "$VPN_CONNECTED" -eq "1" ]; then
		T_PID=`cat "/var/run/vpn.${T_NAME}.pid"`
		kill $T_PID
		rm -f "${testpath}/vpn.${T_NAME}.pid"
		rm -f "${testpath}/vpn.${T_NAME}.gw"
		rm -f "${testpath}/vpn.${T_NAME}.user"
	fi
	scan_result "$RET_CODE" "${VAL}"
	exit 0
}

scan_result(){
	CODE=$1
	VAL=$2
	language=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='admin_lang'"`
	lang_db="/img/language/language.db"
	MSG=`/usr/bin/sqlite ${lang_db} "select msg from ${language} where function='nsync' and value='${CODE}'"`
	if [ "${VAL}" != "" ];
	then
		MSG=`printf "${MSG}" "${VAL}"`
	fi
	if [ "${MSG}" == "" ];
	then
		MSG=`/usr/bin/sqlite ${lang_db} "select msg from ${language} where function='nsync' and value='999'"`
	fi
	success=`echo "${MSG}" | awk -F':' '{print $1}'`
	MSG=`echo "${MSG}" | awk -F':' '{print $2}'`
	echo ${MSG}
}

if [ "$T_MODE" == "thecus" ]; then
	T_IP="0.0.0.0"
	VPN_CONNECTED="1"
	#echo "Using VPN mode"
	if [ -f "${testpath}/vpn.${T_NAME}.gw" ]; then
		VPN_CONNECTED="2"
		T_IP=`cat "${testpath}/vpn.${T_NAME}.gw"`
	else
	 	/img/bin/openvpn/vpn_client.sh "$T_NAME" "$T_VPN_IP" "$T_ID" "$T_PW" "$testpath"
#	 	/etc/vpn_client.sh "$T_NAME" "$T_VPN_IP" "$T_ID" "$T_PW" "$testpath"
	fi
	until [ "$T_I" -eq "0" ];
	do
		if [ -f "${testpath}/vpn.${T_NAME}.gw" ]; then
			T_IP=`cat "${testpath}/vpn.${T_NAME}.gw"`
			break;
		fi
		T_I=`expr $T_I - "1"`
		sleep 2
	done
	if [ "${T_IP}" != "0.0.0.0" ]; then
		#echo "VPN OK!"
		T_PORT="2000 1"
	else
		disp_result "112"
	fi
elif [ "$T_MODE" == "rsync" ]; then
    T_IP="$T_VPN_IP"
else
	T_IP="$T_VPN_IP"	
	T_PORT="$DEF_PORT"
fi

echo "$DEF_RETRY" > /proc/sys/net/ipv4/tcp_syn_retries
echo "machine ${T_IP} login ${T_ID} password ${T_PW}" > /root/.netrc
chmod 0600 /root/.netrc
#RES=`cat /img/bin/nsync/f1 | /usr/bin/ftp ${T_IP} ${T_PORT} 2>/dev/null`

if [ "$T_MODE" == "rsync" ]; then
    rm -rf "/tmp/rsync_${T_NAME}"
    mkdir "/tmp/rsync_${T_NAME}"
    log="/tmp/${taskname}_log"
    
    echo "${T_PW}" > "/tmp/rsync.${T_NAME}"
    chmod 600 "/tmp/rsync.${T_NAME}"
    RES=`/usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --timeout=30 --log-file="${log}" --password-file="/tmp/rsync.${T_NAME}" "/tmp/rsync_${T_NAME}/" ${T_ID}@${T_IP}::rsync_backup 2>/dev/null`
else
RES=`/usr/bin/ftp ${T_IP} ${T_PORT} 2>/dev/null`
fi

RET=$?
if [ "${RET}" != "" ];
then
    if [ "$T_MODE" == "rsync" ]; then
        if [ "${RET}" == "0" ]; then
            RET="107"
        elif [ "${RET}" == "5" ]; then
            RET="100"
            err_msg=`cat "${log}" | grep "@ERROR: chroot failed"`
            if [ "${err_msg}" != "" ];then
                RET="103"
            fi
        
            err_msg=`cat "${log}" | grep " @ERROR: auth failed on module"`
            if [ "${err_msg}" != "" ];then
                RET="101"
            fi

            err_msg=`cat "${log}" | grep "@ERROR: max connections"`
            if [ "${err_msg}" != "" ];then
                RET="114"
            fi            
        elif [ "${RET}" == "10" ]; then
            RET="100"
        elif [ "${RET}" == "11" ]; then
            RET="106"
        elif [ "${RET}" == "12" ]; then
            RET="108"
        elif [ "${RET}" == "137" ]; then
            RET="137"
        elif [ "${RET}" == "23" ]; then
            RET="109"
        elif [ "${RET}" == "30" ]; then
            RET="102"
        else
            RET="999"
        fi

        rm -rf "/tmp/rsync.${T_NAME}"
        rm -rf "/tmp/rsync_${T_NAME}"
        rm -rf "${log}"
    fi
    
	echo "$T_SAVED_SYNC" > /proc/sys/net/ipv4/tcp_syn_retries
	disp_result "${RET}" "${T_IP}"
fi
rm -f /root/.netrc
rm -f /.netrc
exit
