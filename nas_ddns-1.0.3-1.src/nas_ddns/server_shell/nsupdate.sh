#!/bin/sh

if [ $# -ne 2 ]; then
	echo "Usage: $0 fqdn ip"
	exit
fi

fqdn=$1
ip=$2

#dns_server="ns1.thecus-care.com"
dns_server="127.0.0.1"
ttl=60
key_file="./Kthecus.+157+45659.key"

function remove_fqdn(){
    para1="$1"

    fqdn_list=`mysql -p123456 -e "select fqdn from fqdn where mac in (select mac from fqdn where fqdn='${para1}') and fqdn != '${para1}'" ddns`

    echo -e "${fqdn_list}" | \
    while read target
    do
        if [ "${target}" == "" ];then
            break
        elif [ "${target}" == "fqdn" ];then
            continue
        fi

        script=/tmp/nsupdate$$
        echo > $script
        echo "server $dns_server"               >> $script
        echo "update delete $target A"          >> $script
        echo "send"                             >> $script
        nsupdate -v -k $key_file $script

        rm -rf $script

        mysql -p123456 -e "delete from fqdn where fqdn='${target}'" ddns
    done
}

remove_fqdn "${fqdn}"

script=/tmp/nsupdate$$
echo > $script
echo "server $dns_server"		>> $script
echo "update delete $fqdn A"		>> $script
echo "update add $fqdn $ttl A $ip"	>> $script
echo "send"				>> $script

#nsupdate -v -d -k $key_file $script
nsupdate -v -k $key_file $script

rm -rf $script
