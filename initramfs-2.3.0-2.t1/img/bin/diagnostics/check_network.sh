#!/bin/sh
#
# check network
# check_network.sh
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /img/bin/diagnostics/functions

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################

##################################################################
#
#  Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Check network"
echo "###############################"
diag_log "Check network..."

ifconfig -a > ${diag_mpath}/${back_dir}/ifconfig.txt 2>&1

ip_addr=`ifconfig eth0 | grep "inet addr:" | awk -F" " '{printf $2}' | awk -F: '{printf $2}'`
if [ "${ip_addr}" = "" ]; then
    ifconfig -a | grep eth0 >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
	diag_log "Cannot get IP address, please make sure the network is connected"
    else
	# eth0 not enabled
	diag_log "Network device eth0 cannot be enable, maybe it's hardware or driver problem"
    fi
else
    diag_log "Network is OK, the IP address in diagnostics mode is ${ip_addr}"
fi

