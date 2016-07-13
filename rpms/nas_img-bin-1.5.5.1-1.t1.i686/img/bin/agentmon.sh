#!/bin/sh

BINDIR=/img/bin

#BINDIR=/etc/test
SUPPORT_ATMEGA168=`/img/bin/check_service.sh "atmega168"`
if [ "$SUPPORT_ATMEGA168" = "0" ];then
	exit
fi

log=/tmp/agentmon.log

date=`date`
	agents=`ps | grep agent2  | grep -v grep | wc -l`
	
	if [ $agents -gt 0 ] ; then
		echo "$date: The agents alive" 
	else
		echo "$date: The agent2 is dead !!" >> $log
		
		PIDFILE=/tmp/ag_pids
		
		killall agent2
		sleep 1
		ps | grep agent2 | grep -v grep | awk '{print $1}' > $PIDFILE
		                        
		cat $PIDFILE |   \
		while read line
		do
		      echo "kill -9 $line"
		      kill -9 $line
		done;
		rm $PIDFILE
		
		
		sleep 5
		echo RESET_PIC > /proc/thecus_io
		/usr/bin/agent2 > /dev/null 2>&1 &
		sleep 2
		/img/bin/pic.sh START "" ""
		sleep 10
		/img/bin/pic.sh PWR_S "" ""
		sleep 2
	fi
