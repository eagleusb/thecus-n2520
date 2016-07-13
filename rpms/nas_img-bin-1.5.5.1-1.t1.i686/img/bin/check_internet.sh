#!/bin/sh

#1: DNS Fail
#2: External IP Fail
check_dns(){
    RESOLV_CONF="/etc/resolv.conf"
    
    if [ "`cat ${RESOLV_CONF} | grep nameserver`"  == "" ];then
        echo 1
        exit
    fi
}

check_ip(){
    external_ip="`/usr/bin/wget -T 10 -t 5 http://checkip.dyndns.org/ -q -O - |sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`"
    
    if [ "${external_ip}"  == "" ];then
        echo 2
        exit
    fi
}

main(){
    check_dns
    check_ip
}

main
echo 0
