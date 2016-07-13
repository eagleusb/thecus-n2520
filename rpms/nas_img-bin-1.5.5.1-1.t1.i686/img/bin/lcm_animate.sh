#!/bin/sh
PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PIC_MSG="/img/bin/pic.sh"
title="$1"
msg="$2"
exit_word="$3"

if [ "$title" == "" ] || [ "$msg" == "" ] || [ "$exit_word" == "" ]; then
    echo "Need title, msg or exit_word"
    exit
fi 

msg_len=`echo "${msg}" | wc -L`
if [ $msg_len -le 16 ];then
    length=$((16-$msg_len))
else
    ${PIC_MSG} LCM_MSG "$title" "$msg"
    exit 0
fi

while [ 1 ]
do
    i=1
    str=""
    ${PIC_MSG} LCM_MSG "$title" "$msg${str}"
    sleep 1
    while [ $i -le $length ]
    do
        str="${str}."
        ${PIC_MSG} LCM_MSG "$title" "$msg${str}"
        i=$((${i} + 1))
        sleep 1
    done

    key_exist=`ps | grep "$exit_word" | grep -v grep |grep -v "$0"`
    if [ "${key_exist}" == "" ];then
        echo "BTN_OP 4" > /proc/thecus_io
        exit 0
    fi
done
