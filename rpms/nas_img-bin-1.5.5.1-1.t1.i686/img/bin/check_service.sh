#!/bin/sh
service_name=$1

############################
#	ModelName check        #
############################
THECUS_MODEL="/var/run/model"
if [ ! -f $THECUS_MODEL ];then 
	exit
fi

modelname=`cat ${THECUS_MODEL}`

############################
#	Check Service          #
############################
CONFFILE="/img/bin/conf/sysconf.$modelname.txt"
if [ -f $CONFFILE ];then
	result=`awk -F'=' '/^'${service_name}'/{if($1=="'${service_name}'"){printf($2)}}' $CONFFILE`
	# Since we can't ensure if 0 has any special meaning for other services,
	# we only set default value for encrypt_raid for the time being instead
	# of assigning default value 0 for all non-existed items to avoid any
	# unexpected condition.
	if [ -z "$result" ];then
		# set default value to 0 for non-existed item.
		case "$service_name" in
		encrypt_raid)
			result=0
			;;
		esac
	fi
	echo $result
fi
exit
