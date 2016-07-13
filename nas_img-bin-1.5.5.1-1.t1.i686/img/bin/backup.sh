#!/bin/bash
taskname=$1
action=$2
sqlite="/usr/bin/sqlite"
rsync="/usr/bin/rsync"
process_name="/img/bin/backup.sh"
db="/etc/cfg/conf.db"
logevent="/img/bin/logevent/event"
string_cmd="/usr/bin/specstr_handle"
log_file="/raid/data/tmp/rsync_backup.${taskname}"
tmp_raid="/raid/data/tmp/rsync_raid.${taskname}"
status_file="/tmp/rsync_backup_${taskname}.status"
count_file="/tmp/rsync_backup_${taskname}.count"
iso_file="/tmp/rsync_${taskname}_iso.log"
if [ -f /etc/cfg/isomount.db ]; then
	iso_db="/etc/cfg/isomount.db"
else
	iso_db="/etc/cfg/conf.db"
fi

if [ "$action" == "start" ];then
  action_type="Backup"
fi

check_task_processing(){
  #ps_name="$process_name $taskname"
  #process_is_exist=`/bin/ps wwww| grep "$ps_name" | grep -v grep`
  if [ -f "$status_file" ];then
    echo "1"
  fi
  return
}

get_task_info(){
  task_info=`$sqlite $db "select model,folder,ip,port,dest_folder,subfolder,username,passwd,log_folder,tmp1,tmp2,tmp3 from rsyncbackup where taskname='${taskname}'"`
  model=`echo -e "$task_info" | awk -F '|' '{print $1}'`
  folder_info=`echo -e "$task_info" | awk -F '|' '{print $2}'`
  ip=`echo -e "$task_info" | awk -F '|' '{print $3}'`
  ret=`/usr/bin/ipv6check -p "${ip}"`
  if [ "${ret}" != "ipv6 format Error" ];then
    ip="[${ip}]"
  fi
  port=`echo -e "$task_info" | awk -F '|' '{print $4}'`
  dest_folder=`echo -e "$task_info" | awk -F '|' '{print $5}'`
  subfolder=`echo -e "$task_info" | awk -F '|' '{print $6}'`
  
  if [ "${dest_folder}" == "" ];then
    target_folder="raidroot"
  else
    if [ "${subfolder}" != "" ];then
        target_folder="${dest_folder}/${subfolder}"
    else
        target_folder="${dest_folder}"
    fi
  fi
  
  if [ "${port}" == "" ];then
    port="873"
  fi

  username=`echo -e "$task_info" | awk -F '|' '{print $7}'`
  passwd=`echo -e "$task_info" | awk -F '|' '{print $8}'`
  log_folder=`echo -e "$task_info" | awk -F '|' '{print $9}'`
  encrypt_on=`echo -e "$task_info" | awk -F '|' '{print $10}'`
  compression=`echo -e "$task_info" | awk -F '|' '{print $11}'`
  sparse=`echo -e "$task_info" | awk -F '|' '{print $12}'`
}

stop_backup(){
  strExec="/bin/ps wwww | grep '${rsync} -8rltDvH' | grep 'file=$log_file' | grep -v grep | awk '{print \$1}'"
  rsync_pid=`eval $strExec`
  strExec="/bin/ps wwww | grep '${process_name} ${taskname}' | grep -v grep | grep -v ' stop' |awk '{print \$1}'"
  process_pid=`eval $strExec`
  strExec="/bin/ps wwww | grep '${process_name} ${taskname}' | grep -v grep | grep -v ' stop' |awk '{print \$9}'"
  action_type=`eval $strExec`
  
  if [ "$action_type" == "start" ];then
    action_type="Backup"
  fi
  
  kill -9 $rsync_pid $process_pid
  
  eventlog "15"
  changestatus
}

changestatus(){
  end_time=`date "+%Y/%m/%d %k:%M"`  
  $sqlite $db "update rsyncbackup set end_time='$end_time',status='$backup_status' where taskname='$taskname'"  
  rm -rf $status_file
  
  cp -rf $log_file "$log_path"
  rm -rf $log_file
  rm -rf $iso_file
  rm -rf $iso_tmp
  rm -rf $count_file
}

eventlog(){
  result="$1"
  tmplog="$2"
  folder_name="$3"
  backup_status=$result
  
  #some case is the return value, and other cases are the values that we defined
  case "$result"
  in
    0)
      if [ "$action" == "start" ];then
        backup_status="7"
        if [ "$lose_folder" != "" ];then         
          backup_status="16"
        elif [ "$target_lose_folder" != "" ];then         
          backup_status="37"
        else
          $logevent 997 458 info email "${taskname}" "$action_type" 
        fi
      fi  
      ;;
    5)
      err_msg=`cat "${tmplog}" | grep " @ERROR: auth failed on module"`
      if [ "${err_msg}" != "" ];then
          $logevent 997 680 error email "${taskname}" "$action_type"
          backup_status="32"
      fi

      err_msg=`cat "${tmplog}" | grep "@ERROR: Unknown module"`
      if [ "${err_msg}" != "" ];then
          $logevent 997 677 error email "${taskname}" "$action_type" "$target_lose_folder"
          backup_status="37"
      fi

      err_msg=`cat "${tmplog}" | grep "@ERROR: chroot failed"`
      if [ "${err_msg}" != "" ];then
          $logevent 997 670 error email "${taskname}" "$action_type"
          backup_status="12"
      fi
        
      err_msg=`cat "${tmplog}" | grep "@ERROR: max connections"`
      if [ "${err_msg}" != "" ];then
          $logevent 997 679 error email "${taskname}" "$action_type"
          backup_status="38"
      fi
      ;;
    10)
      $logevent 997 667 error email "${taskname}" "$action_type"
      backup_status="10"
      ;;      
    12)      
      if [ "${encrypt_on}" == "1" ];then
        $logevent 997 682 error email "${taskname}" "$action_type"
        backup_status="998"
      else
        err_msg=`grep "No space left" $tmplog`
        if [ "$err_msg" != "" ];then
          $logevent 997 670 error email "${taskname}" "$action_type" "$folder_name"
          backup_status="12"
        else        
          err_msg=`grep "File too large (27)" $tmplog`
          if [ "$err_msg" != "" ];then
            $logevent 997 671 error email "${taskname}" "$action_type" "$folder_name"
            backup_status="23"
          else
            $logevent 997 667 error email "${taskname}" "$action_type"
            backup_status="10"
          fi
        fi
      fi
      ;;
    15)
      $logevent 997 459 info email "${taskname}" "$action_type"
      backup_status="15"
      ;;
    16)      
      $logevent 997 668 error email "${taskname}" "$action_type" "$folder_name" 
      backup_status="16"      
      ;;
    23)
      err_msg=`grep 'failed: Read-only file system' $tmplog`
      if [ "${err_msg}" != "" ];then
        $logevent 997 669 error email "${taskname}" "$action_type" "$folder_name"
        backup_status="9"
      else
        err_msg=`grep 'rename' $tmplog`
        if [ "${err_msg}" != "" ];then
          $logevent 997 675 error email "${taskname}" "$action_type" "$folder_name"
        else
          $logevent 997 671 error email "${taskname}" "$action_type" "$folder_name"
        fi
      fi
      ;;
    24)
      $logevent 997 676 error email "${taskname}" "$action_type" "$folder_name"
      ;;
    30)
      $logevent 997 672 error email "${taskname}" "$action_type" "$folder_name"
      ;;
    31)
      $logevent 997 515 warning email "${taskname}" "$action_type"
      ;;
    32)
      $logevent 997 680 error email "${taskname}" "$action_type" 
      backup_status="32"
      ;;
    34)  
      $logevent 997 514 warning email "${taskname}" "$action_type"
      backup_status="31"
      ;;
    35)
      $logevent 997 516 warning email "${taskname}" "$action_type"
      backup_status="31"
      ;;
    36)
      $logevent 997 670 error email "${taskname}" "$action_type" "$folder_name"
      backup_status="12"
      ;;
    37)
      $logevent 997 677 error email "${taskname}" "$action_type" "$folder_name"
      backup_status="37"      
      ;;
    38)
      $logevent 997 679 error email "${taskname}" "$action_type"
      backup_status="38"
      ;;
    255)
      $logevent 997 683 error email "${taskname}" "$action_type"
      backup_status="997"
      ;;
    *)
      $logevent 997 673 error email "${taskname}" "$action_type"
      backup_status="999"
      ;;
  esac  
}

get_raid_array(){
  strExec="awk -F ':' '/^md[0-9] /||/^md6[0-9]/{print substr(\$1,3)}'  /proc/mdstat| sort -u"
  raid_array=`eval $strExec`
}

get_raid_status(){
  raid_status=`cat "/var/tmp/raidlock"`
  echo $raid_status
  return
}

get_iso_info(){
	if [ -f /etc/cfg/isomount.db ]; then
		$sqlite $iso_db "select point from isomount" > "${iso_file}"
	else
		$sqlite $iso_db "select point from mount" > "${iso_file}"
	fi
}

get_migrate_status(){
  get_raid_array
  echo -e "$raid_array" | \
  while read info
  do 
    raid_status=`cat "/raid${info}/sys/migrate/lock"`
    if [ "$raid_status" == "1" ];then
      echo "1"
      return
    fi
  done
}

get_raid_info(){
  get_raid_array
  echo -e "$raid_array" | \
  while read info
  do 
    raid_id=`cat "/var/tmp/raid${raid_no}/raid_id"`
    if [ "$raid_id" != "" ];then
      echo "raid${raid_no}:${raid_id}" >> $tmp_raid
    fi
  done 
}

backup_action(){
###check process###  
  has_process=`check_task_processing`  
  if [ "$has_process" != "1" ];then
###check_raid_status###
    touch $status_file
    raid_status=`get_raid_status`

    if [ "${raid_status}" == "1" ];then
      eventlog "35" "$log_file"
      changestatus
      exit
    fi

    raid_status=`get_migrate_status`
    if [ "${raid_status}" == "1" ];then
      eventlog "31" "$log_file"
      changestatus
      exit
    fi    
###start event log###
    $logevent 997 457 info email "${taskname}" "${action_type}"
    rm -rf $log_file
    rm -rf $count_file
#    rm -rf $tmp_raid
###update db end_time and task status###
    end_time=`date "+%Y/%m/%d %k:%M"`
    log_time=`date "+%Y%m%d%H%M%S"`
    backup_status="1"
    $sqlite $db "update rsyncbackup set end_time='$end_time',status='$backup_status' where taskname='$taskname'"
    sleep 1
#get raid info    
#    get_raid_info

###get task info###    
    get_task_info

    sync_data=""
    if [ "${model}" == "0" ];then
      sync_data="--delete"
    fi
    
    rsync_para="-8rltDvH"
    if [ "${compression}" == "1" ];then
      rsync_para="${rsync_para}z"
    fi

    if [ "${sparse}" == "1" ];then
      rsync_para="${rsync_para}S"
    fi

    if [ "${encrypt_on}" == "1" ];then
      test_result=`/img/bin/rsync_test.sh "${taskname}" "${ip}" "${port}" "test" "${username}" "${passwd}" "2"`
      test_ret=`echo ${test_result}|awk '{print $NF}'`
      
      if [ "${test_ret}" == "711" ] || [ "${test_ret}" == "712" ] || [ "${test_ret}" == "713" ];then
        eventlog "12"
        changestatus
        exit 
      fi
    fi    
###get iso info###
    get_iso_info

###get source folder###
    folder_count=`echo "$folder_info" | awk -F'::' '{print NF}'`
    total_folder=""
    lose_folder=""
    target_lose_folder=""
    RET_tmp1="0"
    RET_tmp2="0"
###get source folder path###
    for ((i=1;i<=$folder_count;i++))
    do
      strExec="echo '$folder_info' | awk -F'::' '{print \$$i}'"
      folder=`eval $strExec`
      awk_folder=`${string_cmd} "awk" "${folder}"`
      strExec="cat /etc/samba/smb.conf | awk -F' = ' '/\/${awk_folder}$/&&/path = /{print \$2}'"
      folder_path=`eval $strExec`
      stack_flag="0"
      if [ "${folder_path}" == "" ];then
        strExec="cat /etc/samba/smb.conf | awk -F' = ' '/\/data\/stackable\/${awk_folder}\/data$/&&/path = /{print \$2}'"
        folder_path=`eval $strExec`
        stack_flag="1"
      fi
          
      if [ "${dest_folder}" == "" ];then
        test_result=`/img/bin/rsync_test.sh "${taskname}" "${ip}" "${port}" "${folder}" "${username}" "${passwd}"`
        test_ret=`echo ${test_result}|awk '{print $NF}'`
      else
        if [ "$i" == "1" ];then 
          test_result=`/img/bin/rsync_test.sh "${taskname}" "${ip}" "${port}" "${dest_folder}" "${username}" "${passwd}"`
          test_ret=`echo ${test_result}|awk '{print $NF}'`

          if [ "${test_ret}" == "703" ];then
            target_lose_folder="${dest_folder}"
            break
          fi

          if [ "${test_ret}" == "700" ];then
            eventlog "10"
            changestatus
            exit 
          fi
          
          if [ "${test_ret}" == "701" ];then
            eventlog "32"
            changestatus
            exit 
          fi
                
          if [ "${test_ret}" == "709" ];then
            eventlog "38"
            changestatus
            exit 
          fi
        fi
      fi
          
          
      if [ "${folder_path}" != "" ];then
        if [ -d "$folder_path" ] && [ "${test_ret}" == "707" ];then
          if [ "${dest_folder}" == "" ];then
            total_folder="$total_folder$folder_path:"
          else
            if [ "${stack_flag}" == "1" ];then
              folder_path=`echo "$folder_path" | awk '{print substr($0,1,length($0)-5)}'`
            fi
            total_folder="${total_folder} '$folder_path'"
          fi
        else
          if [ ! -d "$folder_path" ];then
            lose_folder="$folder ${lose_folder}"  
          fi    
              
          if [ "${test_ret}" == "703" ] && [ "${dest_folder}" == "" ];then
            target_lose_folder="$folder ${target_lose_folder}"
          fi    
        fi
      else
        lose_folder="$folder ${lose_folder}"
      fi
    done

    if [ "$total_folder" != "" ];then
      if [ "${lose_folder}" != "" ];then
        eventlog "16" "$log_file" "$lose_folder" 
      fi

      if [ "${target_lose_folder}" != "" ];then
        eventlog "37" "$log_file" "$target_lose_folder"
      fi
          
###start backup###
      if [ "${action}" == "start" ];then
        echo "${passwd}" > "/tmp/rsync.${taskname}"
        chmod 600 "/tmp/rsync.${taskname}"

###execute rsync###
        if [ "${dest_folder}" == "" ];then
          oIFS=$IFS
          IFS=":"
          sum=0
          for fd in $total_folder
          do
            sum=$(($sum + `ls -1R "$fd" | sed '/^$/d' | sed '/:$/d' | wc -l`))
          done
          echo $sum > ${count_file}
          IFS=$oIFS
              	
          folder_count=$((`echo "$total_folder" | awk -F':' '{print NF}'`-1))
          for((i=1;i<=$folder_count;i++))
          do
            tmp_folder=`echo "$total_folder" | awk -F':' '{print $'$i'}'`
            tmp_folder="$tmp_folder/"
            source_folder=`echo "$tmp_folder" | awk -F'/' '{print $4}'`
            #check for stackable folder
            if [ "${source_folder}" == "stackable" ];then
              source_folder=`echo "$tmp_folder" | awk -F'/' '{print $5}'`
            fi
            
            tmp_folder="'$tmp_folder'"
			
            iso_tmp="/tmp/rsync_${taskname}_iso_tmp.log"
            cat "$iso_file" | awk -F'/' "{if (\$2==\"$source_folder\")print \$3}" > "${iso_tmp}"

            if [ "${encrypt_on}" == "1" ];then
              strExec="$rsync ${rsync_para} -e \"/usr/bin/ssh -p 23 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\" --log-file=\"$log_file\" --chmod=ugo=rwX --timeout=600 --exclude-from='$iso_tmp' ${sync_data} $tmp_folder \"root@${ip}:/raid/data/ftproot/${source_folder}/\""
            else
              strExec="$rsync ${rsync_para} --log-file=\"$log_file\" --port=${port} --chmod=ugo=rwX --timeout=600 --exclude-from='$iso_tmp' ${sync_data} --password-file=\"/tmp/rsync.${taskname}\" $tmp_folder \"${username}@${ip}::${source_folder}\""
            fi

            eval $strExec
            RET=$?
            if [ "$RET" != "137" ];then
              if [ "$RET" != "0" ];then
                RET_tmp1="$RET"
                eventlog "$RET" "$log_file" "$tmp_folder"
              fi
            else
              RET_tmp2="$RET"
            fi
          done
          
          ##
          ###set status#####
          if [ "$RET_tmp2" != "137" ];then
            if [ "$RET_tmp1" == "0" ];then
              eventlog "$RET" "$log_file"
              changestatus
            else
              changestatus
            fi
          fi
        else
          strExec="ls -1R $total_folder | sed '/^$/d' | sed '/:$/d' | wc -l > \"${count_file}\""
          eval $strExec
              	              
          if [ "${encrypt_on}" == "1" ];then
            strExec="$rsync ${rsync_para} -e \"/usr/bin/ssh -p 23 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\" --log-file=\"$log_file\" --chmod=ugo=rwX --timeout=600 --exclude-from='$iso_tmp' ${sync_data} $total_folder \"root@${ip}:/raid/data/ftproot/${target_folder}\""
          else
            strExec="$rsync ${rsync_para} --log-file=\"$log_file\" --port=${port} --chmod=uo=rwX --timeout=600 --exclude-from='$iso_file' ${sync_data} --password-file=\"/tmp/rsync.${taskname}\" $total_folder \"${username}@${ip}::${target_folder}\""
          fi
          eval $strExec

          RET=$?
          
          ##
          ###set status#####
          if [ "$RET" != "137" ];then
            eventlog "$RET" "$log_file"
            changestatus
          fi
        fi
      fi
    else          
      if [ "$lose_folder" != "" ];then
        eventlog "16" "$log_file" "$lose_folder" 
      fi

      if [ "$target_lose_folder" != "" ];then
        eventlog "37" "$log_file" "$target_lose_folder"
      fi

      if [ "${test_ret}" == "700" ];then
        eventlog "10"
      fi

      if [ "${test_ret}" == "701" ];then
        eventlog "32"
      fi
          
      changestatus
      exit 
    fi
  else
    eventlog "34"  "$log_file" #processing  
    exit
  fi
}

check_log_folder(){
  get_task_info
  
  if [ ! -d "/raid/data/ftproot/$log_folder/LOG_Rsync_Backup" ];then
    mkdir -m 777 "/raid/data/ftproot/$log_folder/LOG_Rsync_Backup"
    chown nobody.nogroup "/raid/data/ftproot/$log_folder/LOG_Rsync_Backup"
  fi

  start_time=`date "+%Y%m%d_%H%M%S"`
  
  if [ "${action_type}" == "" ];then
    action_type="Terminate"
  fi
  
  log_path="/raid/data/ftproot/$log_folder/LOG_Rsync_Backup/${taskname}_${action_type}.${start_time}"
}

case "$action"
in
  start)
    check_log_folder
    backup_action
    ;;
  stop)
    check_log_folder
    stop_backup
    ;;
  *)			
    echo "Usage: $0 { start | stop }"
    ;;
esac
