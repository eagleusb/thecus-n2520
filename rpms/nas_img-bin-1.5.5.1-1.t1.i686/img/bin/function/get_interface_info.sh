#!/bin/sh
interface=$2

. /img/bin/function/libnetwork

get_ip(){
  ip=`execute_get_ip $interface`
  echo $ip
}

get_mask(){
  mask=`execute_get_mask $interface`
  echo $mask
}

get_mac(){
  mac=`execute_get_mac $interface`
  echo $mac
}

get_ipv6(){
  ip=`execute_get_ipv6 $interface`
  echo $ip
}

check_eth_bond(){
    local feth=$1
    local fid

    fid=`check_bond $feth` 

    echo "${fid}"
}

get_nic_name(){
    local fInterface=$1
    local fIndex
    local fName
    
    if [ "`echo "$fInterface" | grep 'bond'`" == "" ];then
        fIndex=`awk -F'\|' '/^'$fInterface'\|/{print $2}' ${Lnet_ALL_NET_INTERFACE}`
        fName=`Lnet_get_nic_name $fIndex`
    else
        fName="${fInterface:0:4}$((${fInterface:4} + 1))"
    fi
    
    echo "$fName"
}

case "$1"
in
   get_ip)
           ip=`get_ip`  
           echo $ip                   
           ;;
   get_ipv6)
           ip=`get_ipv6`
           echo $ip                   
           ;;
   get_mask)
           mask=`get_mask`
           echo $mask                   
           ;;
   get_mac)
           mac=`get_mac`
           echo $mac                   
           ;;
   check_eth_bond)
           id=`check_eth_bond $2`
           echo "${id}"
           if [ "${id}" != "" ];then
               exit 1
           else
               exit 0
           fi
           ;;
   get_nic_name)
           get_nic_name "$2" 
           ;;
   *)
           echo "Usage: $0 { get_ip interface | get_mask interface | get_mac interface |*}"
           RETVAL=1
           ;;
esac
