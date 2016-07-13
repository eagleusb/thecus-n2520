#!/bin/sh
sleep 20
lsyncd_pid_data="/tmp/lsyncd_pid.txt"
task1="cat $lsyncd_pid_data|grep '$1 '|awk -F'--log-file=' '{print \$2}'"
task2=`eval $task1`
task3=`echo $task2|awk -F' ' '{print $4}'`
task4=`basename "$task3"`
task5=`echo $task4|awk -F'.' '{print $2}'`
tmpexec="cat ${lsyncd_pid_data} | grep -v '$1 ' > /tmp/lsyncd_pid.bak"
eval $tmpexec
mv /tmp/lsyncd_pid.bak ${lsyncd_pid_data}

if [ "${task5}" != "" ];then
    pids=`/bin/ps wwww | grep "lsync" | grep "lsyncd_pid_${task5}" | grep -v grep | awk '{print $1}'`
 
    if [ "${pids}" == "" ];then
        /img/bin/logevent/event 997 673 error email "${task5}" "start" ""
    fi
fi

