#!/bin/sh 
#/var/log/information,/var/log/warning,/var/log/error
MAX_LINES=100
. /img/bin/logevent/sysinfo

for log_type in information warning error
do
  lines=`cat ${log_path}${log_type} | wc -l`
  cutlines=`expr \( ${lines} \+ ${MAX_LINES} \) \/ ${MAX_LINES} \* ${MAX_LINES} \- ${MAX_LINES}`
  if [ ${cutlines} -gt 0 ]; then
    cat ${log_path}${log_type} | sed 1,${cutlines}d > ${log_path}${log_type}.tmp
    cp ${log_path}${log_type}.tmp ${log_path}${log_type}
    rm ${log_path}${log_type}.tmp
  fi
done
