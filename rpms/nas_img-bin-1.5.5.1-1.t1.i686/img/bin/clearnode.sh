#!/bin/sh
#
# Clear iSCSI initiator node for ip and port

IPPORT=$1
ISCSIADM="/sbin/iscsiadm"

if [ "$IPPORT" != "" ];then
	strExec="$ISCSIADM -m node|awk '/$IPPORT/'| sed 's@\[\(.*\)\] .*@\1@g'"
	nodelist=`eval "$strExec"`
	for node in $nodelist
	do
	    $ISCSIADM -m node $node -o delete
	done 
fi
