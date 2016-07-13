#!/bin/sh 
remote_ip=$1
ftp_user=$2
ftp_pwd=$3
taskname=$4
folder=$5
producer=$6
action=$7
raid_name="raid"
retry_loop="50"
vpn_log="/tmp/vpn.log"
photo="_NAS_Picture_"
smb_path="/etc/samba/smb.conf"
nsync_tmp=`/usr/bin/sqlite /etc/cfg/global.db "select v from global where k='nsync_tmp'"`
mode=`/usr/bin/sqlite /etc/cfg/conf.db "select nsync_mode from nsync where task_name='${taskname}'"`
rsync_acl="/img/bin/rsync_acl.sh"


############################
# check VPN connection
############################
check_vpn(){
	task=$1
	target_ip=$2
	user=$3
	passwd=$4
	nsync_exist=`/bin/ps ww| grep "/img/bin/nsync.sh ${target_ip}" | grep -v grep`
	openvpn_exist=`/bin/ps ww | grep "/usr/sbin/openvpn --dev tun --persist-tun --persist-key --proto tcp-client" | grep -v grep | awk '{printf("%s,%s,%s\n",$1,$16,$22)}'`
	vpn_exist="0"
	for vpn_item in ${openvpn_exist}
	do
		openvpn_pid=`echo ${vpn_item} | awk -F',' '{print $1}'`
		#running_task=`echo ${vpn_item} | awk -F',' '{print substr($2,length($2)-12,length($2)-17)}'`
		running_task=`echo ${vpn_item} | awk -F',' '{print substr($2,14,length($2)-17)}'`
		openvpn_ip=`echo ${vpn_item} | awk -F',' '{print $3}'`
		#echo "ip = ${vpn_ip} = ${target_ip}"
		if [ "${nsync_exist}" != "" ] && [ "${openvpn_exist}" != "" ] && [ "${openvpn_ip}" == "${target_ip}" ];
		then
			cp /var/run/vpn.${running_task}.pid /var/run/vpn.${task}.pid
			cp /var/run/vpn.${running_task}.gw /var/run/vpn.${task}.gw
			echo "${user}" > /var/run/vpn.${task}.user
			echo "${passwd}" >> /var/run/vpn.${task}.user
			vpn_exist="1"
			break
		fi
	done
	echo ${vpn_exist}
}

#################################
# Get Bandwidth of Nsync setting
#################################
get_bandwidth(){
    ip_sharing=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nic1_nat'"`
    bandwidth="0"
    
    if [ "${ip_sharing}" == "1" ];then
        nsync_qos=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nsync_qos'"`
        
        if [ "${nsync_qos}" != "1gbit" ];then
            bandwidth=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nsync_qos'" | awk -F 'mbit' '{if($1!="") printf("%d",$1*128)}'`
        fi
    fi

    echo ${bandwidth}
}

#raidno=`/bin/cat /tmp/smb.conf | awk -F '/' '/data\/'${folder}'$/{print $2}'`
strExec="/bin/cat ${smb_path} | awk -F'=' '/\/${folder}$/{print substr(\$2,2,length(\$2)-1)}'"
raidpath=`eval ${strExec}`
if [ "${raidpath}" == "" ] && [ "${folder}" == "${photo}" ];
then
	master_raid=`ls -l /raid/ | awk '/data/{print $11}' | awk -F '/' '{print $2}'`
	raidpath="/${master_raid}/data/${photo}"
fi
############################
# check samba share exist
############################
if [ ! -d "${raidpath}" ];then
	/bin/rm "/$raid_name/sys/ftp.pid/$taskname"
	/bin/rm "/$raid_name/sys/ftp.pid/$taskname.child"
	/bin/rm "/$raid_name/sys/${taskname}.status"
	exit;
	if [ "${action}" != "delete" ];
	then
		exit;
	fi
	share_status="none"
fi
############################
#  nsync Default Dir Check
############################
if [ ! -d "/$raid_name/${nsync_tmp}/" ];then
        /bin/mkdir /$raid_name/${nsync_tmp}
fi
if [ ! -d "/$raid_name/sys" ];then
	/bin/mkdir /$raid_name/sys
fi
if [ ! -d "/$raid_name/sys/ftp.pid" ];then
        /bin/mkdir /$raid_name/sys/ftp.pid
fi
######################################
#stop|delete => kill local information
#when stop exit 
######################################
if [ "${action}" == "stop" ];
then
  if [ "${producer}" == "rsync" ];then
    /bin/ps wwww | grep password-file="/tmp/rsync.${taskname}" | grep -v grep | awk '{print $1}' > "/$raid_name/sys/ftp.pid/$taskname"
  fi
	child_pid=`/bin/cat "/$raid_name/sys/ftp.pid/$taskname.child"`
	/bin/kill -9 ${child_pid}
	id=`/bin/cat "/$raid_name/sys/ftp.pid/$taskname"`
	/bin/kill -9 $id
	#echo "status task_cancel" > "/$raid_name/sys/${taskname}.status"
	#/img/bin/end_nsync "$id" "$taskname" "task_cancel" "0"
	/img/bin/end_nsync "$id" "$taskname" "113"
	/bin/rm -fr "/$raid_name/sys/ftp.pid/$taskname"
	/bin/rm -fr "/$raid_name/sys/ftp.pid/$taskname.child"
	exit
fi
######################################
#check pid in current process or not
#if format of pid is corrent do check
######################################
if [ -f "/$raid_name/sys/ftp.pid/${taskname}" ];then
	/img/bin/logevent/event 997 319 error "" "${taskname}" > /dev/null 2>&1
	/img/bin/logevent/event 997 212 "" email "${taskname}" > /dev/null 2>&1
	echo "Process still Running!"
	exit
fi

echo "" > "/$raid_name/sys/ftp.pid/${taskname}"

######################################################
#connect => check producer => vpn connection start
#operations [start|restore|delete]
######################################################
if [ "${producer}" == "thecus" ];then
	test_ip="0.0.0.0"
        echo "active vpn connection"
	echo "status start_vpn" > "/$raid_name/sys/${taskname}.status"
	echo "${taskname} ${remote_ip}" >> ${vpn_log}
	vpn_exist=`check_vpn ${taskname} ${remote_ip} "${ftp_user}" "${ftp_pwd}"`
	echo "vpn = ${vpn_exist}"
	if [ "${vpn_exist}" == "0" ];
	then
		/img/bin/openvpn/vpn_client.sh "${taskname}" "${remote_ip}" "${ftp_user}" "${ftp_pwd}"
        fi
        until [ "$retry_loop" -eq "0" ];
        do
                if [ -f "/var/run/vpn.${taskname}.gw" ];
                then
                	remote_ip=`cat "/var/run/vpn.${taskname}.gw"`
                	test_ip=$remote_ip
                	break;
                fi
                retry_loop=`expr $retry_loop - "1"`
                sleep 2
	done
	if [ "${test_ip}" == "0.0.0.0" ];
	then
		vpn_pidf="/var/run/vpn.${taskname}.pid"
		if [ -s $vpn_pidf ];
		then
			kill `cat "${vpn_pidf}"` >/dev/null 2>&1
			echo "status vpn_fail" > "/$raid_name/sys/${taskname}.status"
			/img/bin/end_nsync "$id" "$taskname" "VPN_FAIL" "0"
			rm -f "/$raid_name/sys/ftp.pid/${taskname}"
			exit 1
		fi
	fi
fi
##########################
#	Start syncing
##########################
if [ "${action}" == "restore" ];
then
	/img/bin/logevent/event 997 123 info "" "${taskname}" "RESTORE START" > /dev/null 2>&1
else
	/img/bin/logevent/event 997 123 info "" "${taskname}" "START" > /dev/null 2>&1
fi
sleep 1
host=`/bin/cat /etc/HOSTNAME`
#mac=`ifconfig eth0 |grep "HWaddr" |cut -d":" -f5`-`ifconfig eth0 |grep "HWaddr" |cut -d":" -f6`-`ifconfig eth0 |grep "HWaddr" |cut -d":" -f7`
mac=`ifconfig eth0 | awk '/eth0/{print $5}' | awk -F: '{printf "%s-%s-%s\n",$4,$5,$6}'`
host=${host}-$mac
#if [ "$share_status" = "none" ];then
#  /bin/mkdir "/$raid_name/data/${folder}"
#fi
cd "${raidpath}"
if [ "${producer}" == "thecus" ];then
	echo "/usr/bin/ftp $remote_ip 2000 \"$ftp_user\" \"$ftp_pwd\" $host \"/$raid_name/${nsync_tmp}/${taskname}\" \"$action\" \"${raidpath}\" \"${mode}\""
	/usr/bin/ftp $remote_ip 2000 "$ftp_user" "$ftp_pwd" $host "/$raid_name/${nsync_tmp}/${taskname}" "$action" 1 "${raidpath}" "${mode}"
	RET=$?
elif [ "${producer}" == "rsync" ];then
    touch "/raid/sys/ftp.pid/${taskname}"
    echo "$ftp_pwd" > "/tmp/rsync.${taskname}"
    chmod 600 "/tmp/rsync.${taskname}"
    tmp_count_file="/tmp/${taskname}_count"
    tmp_log="/tmp/${taskname}.log"
    log="/tmp/${taskname}_log"
    tmp_acl="/tmp/${taskname}.acl"
  
    /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --delete --timeout=180 --password-file="/tmp/rsync.${taskname}" "$ftp_user@$remote_ip::rsync_backup/$host/${taskname}.acl" "${tmp_acl}"
    check_acl_mode=$?
    /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --delete --timeout=180 --password-file="/tmp/rsync.${taskname}" "$ftp_user@$remote_ip::rsync_backup/$host/${taskname}.log" "${tmp_log}"
    RET=$?
    
    if [ "${RET}" == "0" ];then
      cat "${tmp_log}" | awk '/^\+\+\+\+\+\+\+\+\+ /{print $1}' |wc -l > "${tmp_count_file}"
    fi
    
    bwlimit="0"
    #bwlimit=`get_bandwidth`
    
    if [ "${action}" == "start" ]; then
        ls -1R | wc -l > "${tmp_count_file}"
        if [ "${mode}" == "0" ]; then
            /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --delete --timeout=180 --bwlimit="${bwlimit}" --log-file="${log}" --password-file="/tmp/rsync.${taskname}" "${raidpath}" "$ftp_user@$remote_ip::rsync_backup/$host"
        else
            /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --log-file="${log}" --timeout=180 --bwlimit="${bwlimit}" --password-file="/tmp/rsync.${taskname}" "${raidpath}" "$ftp_user@$remote_ip::rsync_backup/$host"
        fi
	RET=$?
    elif [ "${action}" == "restore" ]; then
        if [ "${mode}" == "0" ]; then
            /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --delete --timeout=180 --bwlimit="${bwlimit}" --log-file="${log}" --password-file="/tmp/rsync.${taskname}" "$ftp_user@$remote_ip::rsync_backup/$host/$folder/" "${raidpath}"
        else
            /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --log-file="${log}" --timeout=180 --bwlimit="${bwlimit}" --password-file="/tmp/rsync.${taskname}" "$ftp_user@$remote_ip::rsync_backup/$host/$folder/" "${raidpath}"
        fi
        RET=$?
	$rsync_acl "set" "${taskname}" 
    fi
    
    if [ "${RET}" == "0" ] && [ "${action}" = "start" ]; then
        RET="109"
    elif [ "${RET}" == "0" ] && [ "${action}" = "restore" ]; then
        RET="110"
    elif [ "${RET}" == "5" ]; then
        RET="100"
        err_msg=`cat "${log}" | grep "@ERROR: chroot failed"`
        if [ "${err_msg}" != "" ];then
            RET="103"
        fi
        
        err_msg=`cat "${log}" | grep "@ERROR: auth failed on module"`
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
         
    if [ "${action}" == "start" ] || [ "${action}" == "stop" ];then
        raidno=`/bin/cat /etc/samba/smb.conf | awk -F '/' '/data\/'${folder}'$/{print $2}'`
        if [ "${mode}" == "0" ];then
          if [ "${RET}" == "109" ];then
            cat "${log}" | egrep '<f|cd' | awk -F'<f|cd' '{print $2}' > "${tmp_log}"
          else
            cat "${log}" | egrep '<f|cd' | awk -F'<f|cd' '{print $2}' >> "${tmp_log}"
          fi
        else
            cat "${log}" | egrep '<f|cd' | awk -F'<f|cd' '{print $2}' >> "${tmp_log}"
        fi        
        $rsync_acl "get" "${taskname}" "${raidno}" "${raidpath}"  "${mode}" "${ftp_user}" "${remote_ip}" "${host}" "${check_acl_mode}"
        /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --delete --timeout=180 --password-file="/tmp/rsync.${taskname}" "${tmp_log}" "$ftp_user@$remote_ip::rsync_backup/$host/${taskname}.log" 
    fi

    rm -rf "/raid/sys/ftp.pid/${taskname}"
    rm -rf "/tmp/rsync.${taskname}"
    rm -rf "${log}"
    rm -rf "${tmp_count_file}"
    rm -rf "${tmp_log}"
else
	echo "/usr/bin/ftp $remote_ip 20 \"$ftp_user\" \"$ftp_pwd\" $host \"/$raid_name/${nsync_tmp}/${taskname}\" \"$action\" \"${raidpath}\" \"${mode}\""
	/usr/bin/ftp $remote_ip 20 "$ftp_user" "$ftp_pwd" $host "/$raid_name/${nsync_tmp}/${taskname}" "$action" 0 "${raidpath}" "${mode}"
	RET=$?
fi

if [ "${RET}" != "137" ];
then
	id=`/bin/cat "/$raid_name/sys/ftp.pid/$taskname"`
	/img/bin/end_nsync "${id}" "${taskname}" "${RET}"
fi

exit
