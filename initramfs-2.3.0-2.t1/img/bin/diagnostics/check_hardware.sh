#!/bin/sh
#
# check hardware 
# check_hardware.sh "$devices" $devs_num
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
echo "# Check Hardware"
echo "###############################"
#diag_log "Memory test, it will take a long time, please be patient..."
diag_log "Memory test..."
mem_free=`cat /proc/meminfo |grep "MemFree" |awk -F" " '{printf $2}'`
if [ "${mem_free}" = "" ]; then
    diag_log "Cannot get free memory size"
else
   mem_free=`expr ${mem_free} - 51200`	# 50M memory for memtester 
fi
if [ ${mem_free} -le 0 ]; then
    diag_log "The free memory is not enough for running memory test application"
else
    # Since we are still in developing OS 6,
    # test the whole memory will spend half an hour,
    # which is too lang for developing, 
    # so we test only 200MB memory temporarily.
    [ ${mem_free} -gt 204800 ] && mem_free=204800
    echo "${memtester} ${mem_free}K 1" > ${diag_mpath}/${back_dir}/memtester.txt
    ${memtester} ${mem_free}K 1 > /tmp/memtest.log 2>&1
    if [ $? -eq 0 ]; then
	diag_log "Memory test OK"
    else
	diag_log "Memory test failed"
    fi 
    cat /tmp/memtest.log | col -b >> ${diag_mpath}/${back_dir}/memtester.txt 2>&1
    rm -f /tmp/memtest.log
fi

diag_log "CPU check..."
cat /proc/cpuinfo > ${diag_mpath}/${back_dir}/cpuinfo.txt 2>&1

diag_log "Disk check..."
cat /proc/scsi/scsi > ${diag_mpath}/${back_dir}/scsi.txt 2>&1
for dev in ${devices}
do
	echo "${smartctl} --all -d sat /dev/${dev}" > ${diag_mpath}/${back_dir}/smart_${dev}.txt
	${smartctl} --all -d sat /dev/${dev} >> ${diag_mpath}/${back_dir}/smart_${dev}.txt 2>&1
done
