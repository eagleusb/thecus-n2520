#!/bin/sh 
tc="/sbin/tc"
iptables="/sbin/iptables"

nsync_qos_start() {
  # eth0
  $tc qdisc add dev eth0 root handle 1:0 cbq bandwidth 1000Mbit \
    avpkt 1000
  $tc class add dev eth0 parent 1:0 classid 1:1 cbq bandwidth 1000Mbit  \
    rate 1000Mbit maxburst 20 avpkt 1000 bounded
  $tc qdisc add dev eth0 parent 1:1 handle 30: sfq
  $tc filter add dev eth0 parent 1:0 protocol ip handle 1 fw flowid 1:1
  # eth1
  $tc qdisc add dev eth1 root handle 1:0 cbq bandwidth 1000Mbit \
    avpkt 1000
  $tc class add dev eth1 parent 1:0 classid 1:1 cbq bandwidth 1000Mbit  \
    rate 1000Mbit maxburst 20 avpkt 1000 bounded
  $tc qdisc add dev eth1 parent 1:1 handle 30: sfq
  $tc filter add dev eth1 parent 1:0 protocol ip handle 1 fw flowid 1:1
}

nsync_qos_stop() {
   $tc qdisc del dev eth0 root > /dev/null 2>&1
   $tc qdisc del dev eth1 root > /dev/null 2>&1
   $iptables -t mangle -F
}

nsync_qos_restart() {
  nsync_qos_stop
  nsync_qos_start
}

nsync_qos_status() {
  $tc qdisc show
  $tc class show dev eth0
  $iptables -t mangle -nvL OUTPUT
}

nsync_qos_chg_rate() {
  if [ "$1" != "" ]; then
    if [ `$tc -s qdisc | grep "qdisc cbq 1:" | wc -l` -eq 0 ]; then
      nsync_qos_restart
    fi 
    $tc class change dev eth0 parent 1:0 classid 1:1 cbq bandwidth 1000Mbit  \
      rate $1 maxburst 20 avpkt 1000 bounded
  fi
}

nsync_qos_add() {
  if [ "$1" != "" ]; then
#    $iptables -t mangle -A OUTPUT -d $1/32 -m tcp -p tcp --dport 20 -j MARK --set-mark 1
    $iptables -t mangle -A OUTPUT -m owner --pid-owner $1 -j MARK --set-mark 1
  fi
}

nsync_qos_del() {
  if [ "$1" != "" ]; then
#    $iptables -t mangle -D OUTPUT -d $1/32 -m tcp -p tcp --dport 20 -j MARK --set-mark 1
    $iptables -t mangle -D OUTPUT -m owner --pid-owner $1 -j MARK --set-mark 1
  fi
}
IPSHARING=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nic1_ip_sharing'"`
ACT8023ad=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='nic1_mode_8023ad'"`
if [ "${ACT8023ad}" == "" ];
then
	ACT8023ad="none"
fi
ACTTRACK="0"
if [ "${ACT8023ad}" = "none" ];then
	if [ "${IPSHARING}" = "1" ];then
case "$1" in
   'add')
      nsync_qos_add $2
      ;;
   'del')
      nsync_qos_del $2
      ;;
   'rate')
     nsync_qos_chg_rate $2 
      ;;
   'start')
      nsync_qos_start
      ;;
   'stop')
      nsync_qos_stop
      ;;
   'restart')
      nsync_qos_restart
      ;;
   'status')
      nsync_qos_status
      ;;
   *)
      #echo "usage $0 start|stop|restart|status|add ip|del ip|rate xxx" 
      echo "usage $0 start|stop|restart|status|add pid|del pid|rate xxx" 
      ;;
esac
	fi
fi
