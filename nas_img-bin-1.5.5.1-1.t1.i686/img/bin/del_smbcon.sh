#!/bin/sh

share=$1
pids=`/usr/bin/smbstatus -S | awk "/^${share}\\\0x20/{print \\\$(NF-6)}"`
for pid in ${pids}
do
	#echo $pid
	kill ${pid}
done
