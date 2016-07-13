#!/bin/sh
# This is a tool to batch control thecus_io
#Ex. sh /img/bin/ctrl_thecus_io.sh "Busy:2 PWR_LED:1"
[ -z "$1" ] && exit
echo $1 | sed "s/ /\n/g" | while read line;do
        ITEM=`echo $line | awk -F":" '{print $1}'`
		VALUE=`echo $line | awk -F":" '{print $2}'`
        echo $ITEM $VALUE > /proc/thecus_io
done

