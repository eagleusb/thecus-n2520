#!/bin/sh
service_name=$1
modelname=`awk '/^MODELNAME/{print $2}' /proc/thecus_io`

############################
#	Check Service          #
############################
CONFFILE="/img/bin/conf/sysconf.$modelname.txt"
if [ -f $CONFFILE ];then
	result=`awk -F'=' '/^'${service_name}'/{if($1=="'${service_name}'"){printf($2)}}' $CONFFILE`
	echo $result
fi
exit
