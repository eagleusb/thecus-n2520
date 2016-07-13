#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin

RESOLV_CONF="/etc/resolv.conf"
DHCPLOG="/tmp/getdhcp"
SYSSTART="/tmp/sys_start"

update_interface()
{
  #[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
  [ -n "$subnet" ] && NETMASK="netmask $subnet"
  BROADCAST="broadcast +"
  /sbin/ifconfig $interface up
  /sbin/ifconfig $interface $ip $NETMASK $BROADCAST
}

update_routes()
{
  if [ -n "$router" ]
  then
    echo "deleting routes"
    while /sbin/route del default gw 0.0.0.0 dev $interface
    do :
    done

    for i in $router
    do
      /sbin/route add default gw $i dev $interface
    done
  fi
}

update_dns()
{
  echo -n > $RESOLV_CONF
  [ -n "$domain" ] && echo domain $domain >> $RESOLV_CONF
  for i in $dns
  do
    echo adding dns $i
    echo nameserver $i >> $RESOLV_CONF
  done
}

deconfig()
{
  /sbin/ifconfig $interface 0.0.0.0
}

update_host()
{
	if [ "$interface" = "eth0" ] || [ "$interface" = "bond0" ];then
		STRSQL="select v from conf where k='nic1_hostname'"
		hostname=`/usr/bin/sqlite /etc/cfg/conf.db "${STRSQL}"`
		STRSQL="select v from conf where k='nic1_domainname'"
		domainname=`/usr/bin/sqlite /etc/cfg/conf.db "${STRSQL}"`
		
		hostsfile="/etc/hosts"
		
		echo "127.0.0.1       localhost" > ${hostsfile}
		echo "${ip}       ${hostname}.${domainname}       ${hostname}" >> ${hostsfile}
	fi
}

update_nic2() {
	nic2interface="eth1"
	nic2ip=`echo "$ip"|awk -F'.' '{ip1=$1;printf("%d.%d.%d.%d",ip1+1,$2,$3,$4)}'`
	if [ "$nic2ip" != "" ];then
		/sbin/ifconfig $interface up
		/sbin/ifconfig $nic2interface $nic2ip $NETMASK $BROADCAST
	fi
}

case "$1" in
  bound)
    update_nic2;
    
    update_interface;
    update_routes;
    update_dns;
    update_host;
    
    touch ${DHCPLOG}
  ;;

  renew)
    update_nic2;
    
    update_interface;
    update_routes;
    update_dns;
    update_host;

    touch ${DHCPLOG}
  ;;

  deconfig)
    deconfig;
  ;;

  *)
    echo "Usage: $0 {bound|renew|deconfig}"
    exit 1
    ;;
esac

exit 0

