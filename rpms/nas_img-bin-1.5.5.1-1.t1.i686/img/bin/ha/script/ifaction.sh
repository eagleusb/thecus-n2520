#!/bin/sh

. /img/bin/ha/script/conf.ha
. /img/bin/ha/script/func.ha
. /img/bin/function/libnetwork
. /img/bin/function/vardef.conf

interface=$1
dbnic=`Lnet_trans_interface_to_nic "${interface}"`
netindex=`awk -F'|' '/^'${interface}'\|/{print $2}' ${Lnet_ALL_NET_INTERFACE}`
nic_name=`Lnet_get_nic_name "${netindex}"`
nic1_dhcp=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nic1_ipv4_dhcp_client'"`
dhcp=`/usr/bin/sqlite  /etc/cfg/conf.db "select v from conf where k='${dbnic}_ipv4_dhcp_client'"`
gateway=`/usr/bin/sqlite  /etc/cfg/conf.db "select v from conf where k='${dbnic}_gateway'"`
is_hearbeat=`Lnet_check_ha_interface "${interface}"`
vip_eth=`Lnet_check_vip_interface ${interface}` 
is_bond=`check_bond ${interface}`
ipv6=`/usr/bin/sqlite  /etc/cfg/conf.db "select v from conf where k='${dbnic}_ipv6_enable'"`
ipv6_type=`/usr/bin/sqlite  /etc/cfg/conf.db "select v from conf where k='${dbnic}_ipv6_connection_type'"`
net_cmd="/img/bin/rc/rc.net"
default_gateway=`/usr/bin/sqlite  /etc/cfg/conf.db "select v from conf where k='default_gateway'"`
ETHTOOL="/sbin/ethtool"

/usr/bin/killall udpr
/usr/sbin/udpr &
 
IsLink=`${ETHTOOL} ${interface} | awk  '/Link detected:/{printf $3}'`
if [ "${is_hearbeat}" != "1" ] && [ "${is_bond}" == "" ] && [ "${IsLink}" == "yes" ];then
  Lnet_up_net "${interface}"
  if [ "${default_gateway}" == "${interface}" ];then
    if [ "${dhcp}" != "1" ];then
      if [ "${gateway}" != "" ];then
        route del default gw ${gateway} ${interface}
        route add default gw ${gateway} ${interface}
      fi
    fi
  fi
  ${net_cmd} "start_dhcp_server" "${interface}" "${netindex}"
  if [ ! -f /tmp/ha_role ] || [ ! -f /tmp/boot_ok1 ] || [ "${vip_eth}" != "1" ] && [ "${dhcp}" == "0" ];then
    new_ip=`/img/bin/function/get_interface_info.sh get_ip ${interface}`
    if [ "${new_ip}" != "" ];then
      /img/bin/ipchg.sh "${interface}" "${new_ip}"
    fi
  fi
elif [ "${is_hearbeat}" != "1" ] && [ "${is_bond}" != "" ] && [ "${IsLink}" == "yes" ];then
  /img/bin/rc/rc.net up_one_bond "${is_bond}" "${default_gateway}" 
fi

exit 0
