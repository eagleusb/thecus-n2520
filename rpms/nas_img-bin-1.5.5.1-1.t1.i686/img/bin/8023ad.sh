#!/bin/sh
######################################################################################
#    Usage :
#    
#    1. Configure
#
#       # 8023ad.sh -m < none | lbrr | actbkp >
#       none   : no port trunking
#       lbrr   : load balance round robin
#       actbkp : active_backup
#
#    2. Startup script
#
#       # 8023ad.sh
#
#    Note : 
#        - Please insert an entry into database for ('nic1_mode_8023ad','none')
#
#         - check existence and location of all instances described in 
#          global variables section
#    
#        - this script strongly depends on database. 
#          Turn on debug mode before deploy it.
#
#    Revision : 
#    
#        - 0817 Bug : /etc/ifenslave file does not exist
#
######################################################################################
# Global Variables
##############################
kernel_version=`uname -r`
module=/lib/modules/${kernel_version}/kernel/drivers/net/bonding/bonding.ko
tab=conf
debug=0
CONFDB="/etc/cfg/conf.db"
SQLITE="/usr/bin/sqlite"
LOGEVENT="/img/bin/logevent/event"
#mtu=`/usr/bin/sqlite ${db} "select v from conf where k='nic1_jumbo'"`
ETHTOOL="/sbin/ethtool"

. /img/bin/function/libnetwork
. /img/bin/function/vardef.conf

##############################
# Parameters 
##############################

##############################
# Sysconfig 
##############################
if [ "$#" == "0" ] || [ "$#" == "1" ]; then
    HaInterface=`${SQLITE} ${CONFDB} "select v from conf where k='ha_heartbeat'"`
    if [ "${HaInterface}" != "" ];then
        Ret=`Lnet_check_ha_interface "${HaInterface}"`
        if [ "$Ret" == "1" ];then
            Mac=`ifconfig ${HaInterface} | awk '/ HWaddr /{print $5}'`
            Id_List=`${SQLITE} ${CONFDB} "select id from link_interface where mac='${Mac}'"`
            Net_Index=`awk -F'|' '/^'${HaInterface}'\|/{print $2}' ${Lnet_ALL_NET_INTERFACE}`
            Nic_Name=`Lnet_get_nic_name "${Net_Index}"`

            if [ "${Id_List}" != "" ];then
                for Id in ${Id_List}
                do
                    if [ "$Id" != "" ];then
                        ${SQLITE} ${CONFDB} "delete from link_base_data where id='${Id}'"
                        ${SQLITE} ${CONFDB} "delete from link_interface where id='${Id}'"
                        ${LOGEVENT} 997 530 warning email "$((${Id}+1))" "${Nic_Name}"                    ## delete link
                    fi
                done
            fi
        fi
    fi

    LinkList=`${SQLITE} $CONFDB "select * from link_base_data order by id"`

    for LinkData in $LinkList
    do
        if [ "$LinkData" != "" ];then
            Id=`echo "${LinkData}" | awk -F'|' '{print $1}'`
            CheckLinkInfo=`Lnet_check_link_interface ${Id}`
            if [ "${CheckLinkInfo}" == "1" ];then
                ${SQLITE} ${CONFDB} "delete from link_base_data where id='${Id}'"
                ${SQLITE} ${CONFDB} "delete from link_interface where id='${Id}'"
                ${LOGEVENT} 997 529 warning email "$((${Id}+1))"                    ## delete link
            fi
        fi 
    done

    IdList=(`${SQLITE} $CONFDB "select id from link_base_data order by id"`)
    
    for((i=0;i<${#IdList[@]};i++))
    do
        if [ "$i" != "${IdList[$i]}" ];then
            ${SQLITE} $CONFDB "update link_base_data set id='$i' where id='${IdList[$i]}'"
            ${SQLITE} $CONFDB "update link_interface set id='$i' where id='${IdList[$i]}'"
            ${LOGEVENT} 997 538 warning email "$((${IdList[$i]}+1))" "$((${i}+1))"                    ## delete link
        fi 
    done

    if [ "$#" == "0" ];then
        LinkList=`${SQLITE} $CONFDB "select * from link_base_data order by id"`
    else
        Eth=$1
        Mac=`ifconfig ${Eth} | awk '/ HWaddr /{print $5}'`
        Id=`${SQLITE} ${CONFDB} "select id from link_interface where mac='${Mac}'"`
        if [ "${Id}" == "" ];then
            exit
        else
            LinkList=`${SQLITE} $CONFDB "select * from link_base_data where id='${Id}'"`
        fi
    fi
    
    for LinkData in $LinkList
    do
        if [ "$debug" == "1" ]; then echo "Current Mode : $mode"; fi
        if [ "$LinkData" != "" ];then
            Id=`echo "${LinkData}" | awk -F'|' '{print $1}'`
            CheckLinkInfo=`Lnet_check_link_interface ${Id}`

            if [ "${CheckLinkInfo}" == "0" ];then
                Mode=`echo "${LinkData}" | awk -F'|' '{print $2}'`
                Ip=`echo "${LinkData}" | awk -F'|' '{print $5}'`
                Netmask=`echo "${LinkData}" | awk -F'|' '{print $6}'`
                Ipv6En=`echo "${LinkData}" | awk -F'|' '{print $8}'`
                Ipv4En=`echo "${LinkData}" | awk -F'|' '{print $3}'`

                if [ "${Ipv6En}" == "1" ];then
                    Ipv6Addr=`echo "${LinkData}" | awk -F'|' '{print $10}'`
                    Ipv6Len=`echo "${LinkData}" | awk -F'|' '{print $11}'`
                    Ipv6Gateway=`echo "${LinkData}" | awk -F'|' '{print $12}'`
                fi

                Mtu=`echo "${LinkData}" | awk -F'|' '{print $13}'`

                case $Mode in
                    lbrr)
                        # LB RR
                        echo "LB RR"
                        #/usr/bin/sqlite $db "update conf set v='lbxor' where k='nic1_mode_8023ad'"
                        modprobe bonding -o bond${Id} miimon=100 mode=0 updelay=300 xmit_hash_policy=layer2
                        ;;
                    actbkp)
                        # ACTIVE BACKUP 
                        echo "ACTIVE BACKUP"
                        modprobe bonding -o bond${Id} miimon=100 mode=1 updelay=300 xmit_hash_policy=layer2

                        ;;
                    lbxor)
                        # LB XOR 
                        echo "LB XOR"
                        modprobe bonding -o bond${Id} miimon=100 mode=2 updelay=300 xmit_hash_policy=layer2

                        ;;
                    bcast)
                        # Broadcast
                        echo "BROADCAST"
                        modprobe bonding -o bond${Id} miimon=100 mode=3 updelay=300 xmit_hash_policy=layer2
                        ;;
                    8023ad)
                        # 802.3ad support 
                        echo "802.3ad Support"
                        modprobe bonding -o bond${Id} miimon=100 mode=4 updelay=300 xmit_hash_policy=layer2
                        ;;
                    bltlb)
                        # Balance TLB
                        echo "Balance TLB"
                        modprobe bonding -o bond${Id} miimon=100 mode=5 updelay=300 xmit_hash_policy=layer2
                        ;;
                    blalb)
                        # Balance ALB
                        echo "Balance ALB"
                        modprobe bonding -o bond${Id} miimon=100 mode=6 updelay=300 xmit_hash_policy=layer2
                        ;;
                    *)
                        echo "Not support mode : $mode";
                        continue
                        ;;
                esac
                ifconfig bond${Id} up
                MacList=`${SQLITE} ${CONFDB} "select mac from link_interface where id='${Id}'"`

                for Mac in $MacList
                do
                    EthName=`cat ${Lnet_ALL_NET_INTERFACE} | awk -F'|' '/\|'${Mac}'$/{print $1}'`
                    if [ "${EthName}" != "" ];then
                        DPid=`ps wwww|awk '/udhcpc /&&/ '$EthName'$/{print $1}'`
                        if [ "${DPid}" != "" ];then
                            kill -9 ${DPid}
                        fi
                        
                        fHasCon=`${ETHTOOL} ${EthName} | awk -F ': ' '/Link detected: /{print $2}'`
                        if [ "${fHasCon}" == "yes" ];then
                            touch `printf $SYS_ETH_UP_FLAG ${EthName}`
                            touch `printf $SYS_ETH_DOWN_FLAG ${EthName}`
                        fi
                        ifenslave bond${Id} ${EthName}
                        sleep 1
                        NicName=`Lnet_trans_interface_to_nic "${EthName}"`
                        ${SQLITE} ${CONFDB} "update conf set v='' where k='${NicName}_dynamic_gateway'"
                    fi
                done

                if [ "${Ipv4En}" == "1" ];then
                    ifconfig bond${Id} $Ip netmask $Netmask broadcast + 
                fi
                
                Ipv6File="/proc/sys/net/ipv6/conf/bond${Id}/disable_ipv6"
                echo 0 > "/proc/sys/net/ipv6/conf/bond${Id}/autoconf"
                echo 0 > "/proc/sys/net/ipv6/conf/bond${Id}/accept_ra"
                echo 1 > "${Ipv6File}"

                if [ "${Ipv6En}" == "1" ];then
                    echo 0 > "${Ipv6File}"
                    Lnet_up_ipv6_static "bond${Id}" "${Ipv6Addr}" "${Ipv6Len}" "${Ipv6Gateway}"
                fi

                ifconfig bond${Id} mtu $Mtu
            else
                ${SQLITE} ${CONFDB} "delete from link_base_data where id='${Id}'"
                ${SQLITE} ${CONFDB} "delete from link_interface where id='${Id}'"
                ${LOGEVENT} 997 529 warning email "${Id}"                    ## delete link
            fi
        fi
    done
    exit 0;
    
else
    opt=$1
    mode=$2
    
    if [ "$debug" == "1" ]; then echo "Mode :$mode"; fi
    if [ $opt == "-m" ]; then
        case $mode in
        
        lbrr)
            /usr/bin/sqlite $db "update conf set v='$mode' where k='nic1_mode_8023ad'"
            ;;
        actbkp)
            /usr/bin/sqlite $db "update conf set v='$mode' where k='nic1_mode_8023ad'"
            ;;
        none)
            /usr/bin/sqlite $db "update conf set v='$mode' where k='nic1_mode_8023ad'"
            ;;
        *)
            echo "Not supported mode : $mode"
            echo "Usage : $0 <lbrr | actbkp | none>"
            exit 1;
        esac
    else
        if [ $opt == "-s" ]; then
            mode=`/usr/bin/sqlite $db "select v from conf where k='nic1_mode_8023ad'"`
            echo "Mode: $mode";    
        else    
            echo "Wrong option : $opt"
        fi
    fi
    exit 0;
fi
