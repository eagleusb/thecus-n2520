#!/bin/sh
hd_log_folder="/var/tmp/HD"
hd_dev="/dev/sd$2"
hd_num=$2
block_cmd="/sbin/badblocks"
logevent="/img/bin/logevent/event"
hd_tmp_log="${hd_log_folder}/hdbtmp${hd_num}"
hd_log="${hd_log_folder}/badblock_"
hd_serial=$3
log_loc="${hd_log}${hd_serial}"

disktray=$hd_serial
max_tray=`cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2`
if [ ${disktray} -gt ${max_tray} ]; then
  disktray="$(($disktray/26-1))-$(($disktray%26))"
fi

if [ "$1" == "start" ];then
  hd_type=$4
  smart_cmd="/usr/sbin/smartctl -d ${hd_type}"
fi

################################################
#  get content of /var/tmp/HD/hdbtmpx
################################################
check_tmp_log(){
  cmd="cat ${hd_tmp_log}"
  hd_tmp_log_sn=`eval ${cmd}`
 
  echo $hd_tmp_log_sn
}


################################################
#Stop bad block scanning
#Input:NULL
#Output:NULL
################################################
block_stop(){
  hd_tmp_log_sn=`check_tmp_log`

  if [ "${hd_tmp_log_sn}" != "${hd_serial}" ];then
    echo "1"
    exit 1
  fi

  check_scan_status=`cat ${log_loc} | awk -F'=' '/State/{print $2}'`
  
  if [ "${check_scan_status}" != 1 ];then
    echo "1"
    exit 1  
  fi
  
  rm ${hd_tmp_log}
  cmd="cat ${log_loc} | awk -F'=' '/PID/{print \$2}'"
  PID=`eval ${cmd}`
  cmd="cat ${log_loc} | awk -F'=' '/Badblock/{print \$2}'"
  badblock=`eval ${cmd}`
  kill -9 ${PID}
  ${logevent} 997 506 warning email "${disktray}"
  echo -e "State=2\nProgress=0\nBadblock=${badblock}\nPID=\nSN=${hd_serial}\nHD_Id=${hd_num}\n" > ${log_loc}
}


################################################
#Start bad block scanning
#Input:NULL
#Output:NULL
################################################
block_start(){
#  check_hd_type=`echo $hd_serial | awk '{print substr($1,1,3)}'`
  
#  if [ "${check_hd_type}" != "usb" ];then
#    cmd="${smart_cmd} -i ${hd_dev} | awk -F':' '/Serial Number/{print substr(\$2,5,length(\$2))}'"
#    check_hd_serial=`eval ${cmd}`
    
#    if [ "${hd_serial}" != "${check_hd_serial}" ] || [ "${check_hd_serial}" == "" ];then
#      echo "1"
#      exit 1  
#    fi
#  fi 

  cmd="find ${hd_log_folder} | wc -l"
  check_folder=`eval ${cmd}`
  
  if [ ${check_folder} == 0 ];then
    mkdir -p ${hd_log_folder}
  fi
    
  cmd="cat ${log_loc} | awk -F'=' '/State/{print \$2}'"
  block_start_flag=`eval ${cmd}`
        
  if [ "${block_start_flag}" == "1" ];then
    exit 1
  fi

  ${logevent} 997 432 info email "${disktray}"
  echo "${hd_serial}" > ${hd_tmp_log} 
  ${block_cmd} ${hd_dev} &
}


################################################
#Bad block scanning complete
#Input:NULL
#Ouput:NULL
################################################
block_end(){
  hd_tmp_log_sn=`check_tmp_log`

  if [ "${hd_tmp_log_sn}" != "${hd_serial}" ];then
    echo "1"
    exit 1
  fi
  
  rm ${hd_tmp_log}     
  cmd="cat ${log_loc} | awk -F'=' '/Badblock/{print \$2}'"
  badblock_status=`eval ${cmd}`
  
  if [ "${badblock_status}" == "0" ];then
    ${logevent} 997 433 info email "${disktray}" 
  else
    ${logevent} 997 649 error email "${disktray}"
  fi
}

case "$1" in
'start')
   block_start
   ;;
'stop')
   block_stop
   ;;
'end')
   block_end
   ;;
*)
  echo "Usage: $0 {start hd_id hd_sn hd_type | stop hd_id hd_sn | end hd_id hd_sn}"
  ;;
esac
