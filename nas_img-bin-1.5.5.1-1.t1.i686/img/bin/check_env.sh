#!/bin/sh
DEBUG=on
ENV_DIR=/tmp/env
[ ! -d "$ENV_DIR" ] && mkdir -p $ENV_DIR
usage()
{
    echo "Usage: `basename $0` [options] [function name]"
    echo "[options]"
    echo "-r: read environment setting"
    echo "-c: check environment setting"
    echo "-a: check all environment setting"
    exit 2
}
check_hwm(){
	HWM=/proc/hwm
	[ ! -f "$HWM" ] && echo hwm is not exist && return
	[ "`cat $HWM`" == "" ] && echo the content of hwm is empty && return
	[ -n "`cat $HWM | head -n1 | grep "not found"`" ] && echo hwm is not found && return
	touch $ENV_DIR/hwm
}
case $1 in
	"-r")
		[ -f "$ENV_DIR/$2" ] && echo exist && exit
		;;
	"-a")
		ENV_LIST="hwm" #seperate function name by space
		[ "${DEBUG}" == "on" ] && ERR_LOG="2>> /dev/null" || ERR_LOG=""
		for env in $ENV_LIST; do
			eval check_${env} $ERR_LOG
		done
		;;
	"-c")
		[ -f "$ENV_DIR/$2" ] && rm -rf "$ENV_DIR/$2"
		[ "${DEBUG}" == "on" ] && ERR_LOG="2>> /dev/null" || ERR_LOG=""
		eval check_$2 $ERR_LOG
		;;
	[-]*|*)
		usage
		;;
esac
