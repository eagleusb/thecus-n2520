#!/bin/sh
hd_num="$2"
hd_dev="/dev/sd$2"
smart_log_folder="/var/tmp/HD"
logevent="/img/bin/logevent/event"
smart_cmd="/usr/sbin/smartctl -d $4" 
hd_serial=$3 

disktray=`awk '/Disk:sd'${hd_num}' /{tray=substr(\$2,6);printf("%d",tray)}' /proc/scsi/scsi`
max_tray=`cat /proc/thecus_io | grep "MAX_TRAY:" | cut -d" " -f2`
if [ ${disktray} -gt ${max_tray} ]; then
  disktray="$(($disktray/26-1))-$(($disktray%26))"
fi

if [ "$1" == "start" ];then
  test_type=$5
fi

smart_log_name="/var/tmp/HD/smart_${hd_serial}"

get_sn(){
  cmd="${smart_cmd} -i ${hd_dev} | awk -F':' '/Serial Number/{print substr(\$2,5,length(\$2))}'"
  check_hd_serial=`eval ${cmd}`
  echo "${check_hd_serial}"
}


#######################################
# Add hd smart record
# Input : State(testing or ok or stop)
#         date(test date)
#         selfpid(PID of this process)
# output: null
######################################
add_hd_record(){
  testdate=$2
  testtype=${test_type}

  case "$1" in
  'stop') 
    state="2"
    testtype=`cat ${smart_log_name} | awk -F'=' '/Test Type/{print $2}'`
    test_result=" "
    progress="0"
    testdate=`cat ${smart_log_name} | awk -F'=' '/Test Date/{print $2}'`
    selfpid=""
    ;;
  0) 
    state="0"
    progress="0"
    test_result=`${smart_cmd} -H ${hd_dev} | awk -F': ' 'NR==5 && /test result/{print \$2}'` 
    selfpid=""
    ;; 
  41) 
    state="0"
    progress="0"
    test_result="Interrupted by the host with a hard or soft reset" 
    selfpid=""
    ;; 
  *)
    state="1"
    test_result="Testing"
    progress=`${smart_cmd} -c ${hd_dev} | awk  'NR==10{print substr(\$1,0,length(\$1)-1)}'`
    progress=`expr 100 - ${progress}`
    selfpid=$3
    ;;
  esac
    
  echo -e "State=${state}\nTest Type=${testtype}\nProgress=${progress}\nTest Result=${test_result}\nTest Date=${testdate}\nPID=${selfpid}\nSN=${hd_serial}\nHD_Id=${hd_num}\n" > ${smart_log_name}
}

#######################################
# Stop smart test
# Input : null
# output: null
######################################
smart_stop(){
  check_hd_serial=`get_sn`
  
  if [ "${hd_serial}" != "${check_hd_serial}" ];then
    echo "1"
    exit 1
  fi
  
  cmd="cat ${smart_log_name} | awk -F'=' '/State/{print \$2}'"
  smart_start_flag=`eval ${cmd}`    

  if [ "${smart_start_flag}" != "1" ];then
    echo "1"
    exit 1
  fi
  
  execpid=`cat ${smart_log_name} | awk -F'=' '/PID/{print $2}'`
    
  if [ "${execpid}" != "" ];then
    check_kill_status=`kill -9 ${execpid}` 
    
    if [ "${check_kill_status}" == "" ];then
      ${smart_cmd} -X ${hd_dev} > /dev/null  2>&1
      add_hd_record "stop"
      ${logevent} 997 507 warning email "${disktray}"
    fi
  fi     
}

#######################################
# Start smart test
# Input : null
# output: 0: normal
#         1: no disk
######################################
smart_start(){
  check_hd_serial=`get_sn`
  
  if [ "${hd_serial}" != "${check_hd_serial}" ] || [ "${check_hd_serial}" == "" ] || [ "${check_hd_serial}" == "[No Information Found]" ];then
    echo "1";
    exit 1;
  fi  
  
  cmd="find ${smart_log_folder} | wc -l"
  check_folder=`eval ${cmd}`

  if [ ${check_folder} == 0 ];then
    mkdir -p ${smart_log_folder}
  fi
    
  smart_test_date=`date`
  smart_status_cmd="${smart_cmd} -c ${hd_dev} | awk 'NR==9 &&/Self-test execution status/{print substr(\$5,0,length(\$5)-1)}'"
  selfpid=$$ 
  cmd="cat ${smart_log_name} | awk -F'=' '/State/{print \$2}'"
  smart_start_flag=`eval ${cmd}`    
  
  if [ "${smart_start_flag}" == "1" ];then
    echo "1"
    exit 1
  fi

  ${smart_cmd} -t ${test_type} ${hd_dev} > /dev/null 2>&1
  ${logevent} 997 434 info email "${disktray}"
     
  while [ true ] 
  do
    smart_status_check=`eval ${smart_status_cmd}`
       
    if [ "${smart_status_check}" == "" ];then
      add_hd_record "stop"
      ${logevent} 997 507 warning email "${disktray}"
      exit 1
    else
      add_hd_record "${smart_status_check}" "${smart_test_date}" "${selfpid}"
    fi
         
    if [ "${smart_status_check}" == "41" ];then
      break
    fi
    
    if [ "${smart_status_check}" == "0" ];then
      cmd="cat ${smart_log_name} | awk -F'=' '/Test Result/{print \$2}'"
      smart_status=`eval ${cmd}`
        
      if [ "${smart_status}" == "PASSED" ];then
        ${logevent} 997 435 info email "${disktray}"
      else
        ${logevent} 997 650 error email "${disktray}"
      fi
  
      break
    fi

    sleep 5
  done
}


case "$1" in
'start')
  smart_start
  ;;
'stop')
  smart_stop
  ;;
*)
  echo "Usage: $0 {start hd_id hd_sn hd_type test_type|stop hd_id hd_sn hd_type}"
  ;;
esac
