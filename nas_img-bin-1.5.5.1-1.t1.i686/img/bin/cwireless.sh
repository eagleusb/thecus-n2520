#!/bin/sh -x
sqlite="/usr/bin/sqlite"
db="/etc/cfg/wireless.db"
ifconfig="/sbin/ifconfig"
dhcp_pid="/var/run/dhcp0.pid"
conf_db="/etc/cfg/conf.db"
dhcp_script="/img/bin/udhcpc_script.sh"
wpa_supplicant="/usr/sbin/wpa_supplicant"
route="/sbin/route"
wpa_log="/tmp/wpa.log"
dev="wth0"
change_wan_dev="breth0"
global_dev="eth0"
wpa_pid="/var/run/cwireless.pid"

check_auth(){
	auth=`${sqlite} ${db} "select v from cwireless where k='auth'"`
	bssid=`${sqlite} ${db} "select v from cwireless where k='bssid'"`
	if [ "${auth}" == "wpa_psk" ] || [ "${auth}" == "wpa2_psk" ];
	then
		check_auth="0"
		c=0
        while [  "$c" != "60" ]
		do
			check_auth_info=`cat ${wpa_log} | grep "CTRL-EVENT-CONNECTED" | tail -n 1 | awk '{printf("%s,%s",toupper($6),$7)}'`
			check_auth_bssid=`echo ${check_auth_info} | awk -F',' '{print $1}'`
			check_auth_res=`echo ${check_auth_info} | awk -F',' '{print $2}'`
			if [ "${check_auth_bssid}" == "${bssid}" ] && [ "${check_auth_res}" == "completed" ];
			then
				check_auth="1"
				break
			fi
			sleep 1
			c=$(($c+1));
		done
		if [ "${check_auth}" == "0" ];
		then
			echo "`date` Auth Fail" >> ${wpa_log}
			pid=`cat ${wpa_pid}`
			if [ "${pid}" != "" ];
			then
				kill -9 ${pid}
			fi
			exit 1
		fi
	fi
	sleep 1
}

get_ip(){
	dhcp_enable=`${sqlite} ${conf_db} "select v from conf where k='nic1_ipv4_dhcp_client'"`
	hostname=`${sqlite} ${conf_db} "select v from conf where k='nic1_hostname'"`
	gateway=`${sqlite} ${conf_db} "select v from conf where k='nic1_gateway'"`

	if [ "${dhcp_enable}" == "1" ];
	then
		echo "Get dhcp IP"
		#/sbin/udhcpc -s ${dhcp_script} -b -h ${hostname} -i ${global_dev} -p ${dhcp_pid} &
		/sbin/udhcpc -t 5 -n -s ${dhcp_script} -b -h ${hostname} -i ${dev} -p ${dhcp_pid} &
	else
		echo "static"
		ip=`${sqlite} ${conf_db} "select v from conf where k='nic1_ip'"`
		netmask=`${sqlite} ${conf_db} "select v from conf where k='nic1_netmask'"`
		#${ifconfig} ${global_dev} ${ip} netmask ${netmask}
		${ifconfig} ${dev} ${ip} netmask ${netmask}
		${route} add default gw ${gateway}
	fi
}

case "$1"
in
	check_dhcp)
		check_auth
		get_ip
	;;
	*)
		echo "Usage: $0 { check }"
	;;
esac
exit
