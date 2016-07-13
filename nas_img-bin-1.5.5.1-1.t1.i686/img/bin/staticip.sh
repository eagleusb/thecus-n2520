#!/bin/sh
interface=$1
ifaddr=$2
ifmask=$3

. /img/bin/function/vardef.conf

chk_ipchg(){
        strExec="ifconfig $interface|awk -F: '/ inet addr:/{print \$2}'|awk '{print \$1}'"
	orgip=`eval "$strExec"`
	if [ "$orgip" != "$ifaddr" ];then
		echo "1"
	else
		echo "0"
	fi
}

ipchg=`chk_ipchg`

function restart_service(){
	if [ "$ipchg" = "1" ];then
		(/img/bin/service stop;sleep 1;/img/bin/service start) &
	fi
}

if [ "$interface" = "eth0" ];then
	mode_8023ad=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nic1_mode_8023ad'"`
	nic1_gateway=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nic1_gateway'"`
	defgw=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='default_gateway'"`
	if [ "${ifaddr}" != "" ];then
		if [ "${ifmask}" != "" ];then
			if [ "${defgw}" == "${interface}" ];then
				echo -e "#!/bin/sh\n/sbin/ifconfig eth0 up\n/sbin/ifconfig eth0 ${ifaddr} netmask ${ifmask} broadcast +\n/sbin/route add default gw ${nic1_gateway}" > /etc/cfg/cfg_nic0
			else    
				echo -e "#!/bin/sh\n/sbin/ifconfig eth0 up\n/sbin/ifconfig eth0 ${ifaddr} netmask ${ifmask} broadcast +\n" > /etc/cfg/cfg_nic0
			fi
			killall udhcpc
			sleep 1
			if [ "$mode_8023ad" != "" ] && [ "$mode_8023ad" != "none" ];then
				/img/bin/8023ad.sh eth0
				if [ "${defgw}" == "${interface}" ];then
					bondid=`/img/bin/function/get_interface_info.sh "check_eth_bond" "eth0"`
					if [ "${bondid}" != "" ];then
					    /img/bin/rc/rc.net change_default_gw "eth0" "${bondid}"
					fi
				fi
				restart_service
				exit 0
			fi

			touch `printf $SYS_ETH_DOWN_FLAG eth0`
			ifconfig eth0 0.0.0.0 down
			touch `printf $SYS_ETH_UP_FLAG eth0`
			sh /etc/cfg/cfg_nic0
			restart_service			
		fi
	fi
else 
	if [ "$interface" = "eth1" ];then
		if [ "${ifaddr}" != "" ];then
			if [ "${ifmask}" != "" ];then
				fHasCon=`/sbin/ethtool eth1 | awk -F ': ' '/Link detected: /{print $2}'`
				if [ "${fHasCon}" == "yes" ];then
					echo -e "#!/bin/sh\n/sbin/ifconfig $interface up\n/sbin/ifconfig $interface ${ifaddr} netmask ${ifmask} broadcast +" > /etc/cfg/cfg_nic1
					touch `printf $SYS_ETH_DOWN_FLAG eth0`
					ifconfig $interface 0.0.0.0 down
					touch `printf $SYS_ETH_UP_FLAG eth0`
					sh /etc/cfg/cfg_nic1
					/usr/bin/sqlite /etc/cfg/conf.db "update conf set v='0' where k='nic2_ipv4_dhcp_client'"
                                fi
			fi
		fi
	fi
fi	

