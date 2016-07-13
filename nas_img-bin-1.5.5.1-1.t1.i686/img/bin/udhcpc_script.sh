#!/bin/sh

# udhcpc script edited by Tim Riker <Tim@Rikers.org>

[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
CONFDB="/etc/cfg/conf.db"
SQLITE="/usr/bin/sqlite"
LOGEVENT="/img/bin/logevent/event"
dbip=""
dbnetmask=""
TMPCHECKFILE="/var/tmp/net_init"
NetVal=`cat ${TMPCHECKFILE}`
DNS_FILE="/tmp/${interface}_dns"

. /img/bin/function/libnetwork

if [ -n "$broadcast" ]; then
    BROADCAST="broadcast $broadcast"
else
    BROADCAST="broadcast +"
fi

[ -n "$subnet" ] && NETMASK="netmask $subnet"

nic=`Lnet_trans_interface_to_nic "${interface}"`

dbinfo=`${SQLITE} ${CONFDB} "select * from conf where k like '${nic}%'"`
db_dns_type=`${SQLITE} ${CONFDB} "select v from conf where k='nic1_dns_type'"`
default_gateway=`${SQLITE} ${CONFDB} "select v from conf where k='default_gateway'"`
if [ -f "${DNS_FILE}" ];then
    rm ${DNS_FILE}
fi

case "$1" in
    deconfig)
        #/sbin/ifconfig $interface 0.0.0.0
        dbip=`Lnet_get_net_info "${dbinfo}" "${nic}" "ipv4_default_ip"`
        error=0
        tmpid=`${SQLITE} ${CONFDB} "select id from link_base_data where ip='${dbip}'"`

        if [ "${tmpid}" != "" ];then
            check_result=`Lnet_check_link_interface ${tmpid}`
            if [ "${check_result}" == "0" ];then
                error=1
            fi
        fi

        tmpip=`${SQLITE} ${CONFDB} "select v from conf where k like '%_ip' and k <>'${nic}_ip' and k <>'${nic}_ipv4_default_ip' and v='${dbip}'"`

        if [ "${error}" == "0" ] && [ "${tmpip}" == "" ];then
            dbnetmask=`Lnet_get_net_info "${dbinfo}" "${nic}" "netmask"`
            Lnet_up_ipv4_static "$interface" "${dbip}" "${dbnetmask}"
        else
            /sbin/ifconfig $interface 0.0.0.0
            net_index=`awk -F'|' '/^'${interface}'\|/{print $2}' ${Lnet_ALL_NET_INTERFACE}`
            nic_name=`Lnet_get_nic_name "${net_index}"`
            ${LOGEVENT} 997 528 warning email "${nic_name}"                    ## setting dhcp fail and ip constant
        fi

        ${SQLITE} ${CONFDB} "update conf set v='' where k='${nic}_dynamic_gateway'"
        /img/bin/ipchg.sh $interface "${dbip}"
        ;;

    renew|bound)
        pre_ip=`ifconfig $interface | grep "inet addr:" | cut -d":" -f2 | cut -d" " -f1`
        if [ "${pre_ip}" != "${ip}" ]; then
            /sbin/ifconfig $interface $ip $NETMASK $BROADCAST

            if [ "${default_gateway}" == "${interface}" ] && [ "$NetVal" == "0" ];then
                if [ -n "$router" ] ; then
                    echo "deleting routers"
                    while route del default gw 0.0.0.0 dev $interface ; do
                        :
                    done
                fi

            fi

            for i in $router ; do
                if [ "$i" != "" ];then
                    ${SQLITE} ${CONFDB} "update conf set v='${i}' where k='${nic}_dynamic_gateway'"
                    if [ "${default_gateway}" == "${interface}" ] && [ "$NetVal" == "0" ];then
                        route add default gw $i dev $interface
                    fi
                fi
            done

            for i in $dns ; do
                echo $i >> ${DNS_FILE}
                [ -n "$domain" ] && echo search $domain >> ${DNS_FILE}
            done


            if [ "${db_dns_type}" == "1" ];then
                if [ "${interface}" == "eth0" ];then
                    echo -n > $RESOLV_CONF
		    rm -f /tmp/wire_dns

                    [ -n "$domain" ] && echo search $domain >> $RESOLV_CONF

                    for i in $dns ; do
                        echo adding dns $i
                        echo nameserver $i >> $RESOLV_CONF
			echo nameserver $i >> /tmp/wire_dns
                    done
		    ## WLAN router and Name werver
                    WLAN_DEVICE=`/usr/bin/nmcli dev list | grep -B1 "GENERAL.TYPE" | grep -B1 "wireless" | grep "DEVICE" | cut -d: -f2 | awk '{print $1}'`
                    wireless_GW=`/usr/bin/nmcli dev list iface $WLAN_DEVICE | grep "GATEWAY:" | cut -d: -f2 | xargs`
		    if [ -n "$wireless_GW" ]; then
                        WLAN_DNS=`nmcli dev list iface $WLAN_DEVICE | grep DNS: | cut -d: -f2 | xargs`
                        for i in $WLAN_DNS;
                        do
                            echo "nameserver $i" >> $RESOLV_CONF
                        done

			while route del default gw $wireless_GW dev $WLAN_DEVICE ; do
                        :
                        done
			route add default gw $wireless_GW dev $WLAN_DEVICE metric 2
                    fi
                fi
            fi

            /img/bin/ipchg.sh $interface $ip $subnet $broadcast
        fi
        ;;
esac

exit 0
