#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
action=$1
tid=$2
libbackup="/img/bin/function/lib_dataguard"
. ${libbackup}

if [ "${tid}" == "" ];then
  echo "Task id is null."
  exit
fi

check_raid
eval `db_to_env $tid`

if [ "${CFG_task_name}" == "" ];then
  echo "tid not found!"
  exit
fi

if [ "`echo ${OPT_src_path} | grep \"^\/raid[0-9]\/data\"`" != "" ];then
  OPT_src_path=`echo ${OPT_src_path} | sed 's/\/raid[0-9]\/data//g'`
fi

if [ "`echo ${OPT_src_path} | grep \"^\/raid6[0-9]\/data\"`" != "" ];then
  OPT_src_path=`echo ${OPT_src_path} | sed 's/\/raid6[0-9]\/data//g'`
fi

sqlite="/usr/bin/sqlite"
rsync_test="/img/bin/rsync_test.sh"    
mgmt_nasconfig="/img/bin/dataguard/mgmt_nasconfig.sh"    
lsync_conf="/tmp/lsyncd_${CFG_task_name}.conf"
lsyncd="/usr/bin/lsyncd"
lsyncd_pid_data="/tmp/lsyncd_pid.txt"
pid="/tmp/lsyncd_pid_${CFG_task_name}"
process_name="/img/bin/dataguard/remote_backup.sh"
string_cmd="/usr/bin/specstr_handle"
passwd_file="/tmp/rsync.${CFG_task_name}"
log_file="/raid/data/tmp/rsync_backup.${CFG_task_name}"
log_file_status="/raid/data/tmp/rsync_backup.${CFG_task_name}.status"
status_file="/tmp/rsync_backup_${CFG_task_name}.status"
count_file="/tmp/rsync_backup_${CFG_task_name}.count"
iso_file="/tmp/rsync_${CFG_task_name}_iso.log"
iso_tmp="/tmp/rsync_${CFG_task_name}_iso_tmp.log"
process_file="/tmp/rsync_${CFG_task_name}_progress"
acl_file="/tmp/rsync_${CFG_task_name}_acl"

stop_backup(){
    log_flag="0"
    if [ "${CFG_back_type}" == "realtime" ];then
        pids=`cat ${pid}`
        if [ "${pids}" == "" ];then      
            pids=`ps | grep "/usr/bin/lsyncd /tmp/lsyncd_${CFG_task_name}.conf" | awk '{print $1}'`
        fi
        
        if [ "${pids}" != "" ];then      
            kill -9 ${pids}
            rm "${pid}"
            rm "${log_file_status}"
            log_flag="1"
            types="Backup"
        else
            # If task status keeps "terminating" and there is no process to kill, then we update status to "terminate" and delete status file.
            if [ "${CFG_status}" == "2" ];then
                rm -rf $status_file
                ${Ldataguard_sqlite} ${Ldataguard_backupdb} "update task set last_time='$end_time',status=15 where task_name='$CFG_task_name'"
            fi
        fi 
    else  
        strExec="/bin/ps wwww | grep '${rsync} -8rltDvH' | grep 'file=$log_file ' | grep -v grep | awk '{print \$1}'"
        rsync_pid=`eval $strExec`      
        strExec="/bin/ps wwww | grep '${process_name}' | grep ' ${tid}$' | grep -v grep | grep -v ' stop' |awk '{print \$1}'"
        process_pid=`eval $strExec`
        if [ "${rsync_pid}" != "" -o "${process_pid}" != "" ];then
            strExec="/bin/ps wwww | grep '${process_name}' | grep ' ${tid}$' | grep -v grep | grep -v ' stop' |awk '{print \$7}'"
            types=`eval $strExec`  
            kill -9 $rsync_pid $process_pid
            log_flag="1"
        fi
    fi
  
    if [ "${OPT_remote_back_type}" == "iscsi" ];then
        tfolder=`echo ${OPT_src_folder} | awk -F':' '{print $2}'`
        iscsi_service "${tfolder}" "start"
    fi
    
    if [ "${log_flag}" == "1" ];then
        eventlog "${CFG_task_name}" "15" "${types}" "" ""
        changestatus "${CFG_task_name}"
    fi 
}

changestatus(){
  local CFG_task_name="$1" 
  backup_status=`cat /tmp/backup_status_file_${CFG_task_name}`
  end_time=`date "+%Y/%m/%d %k:%M"`  
  
  ret=1
  while [ "${ret}" != "0" ]
  do
    ${Ldataguard_sqlite} ${Ldataguard_backupdb} "update task set last_time='$end_time',status='$backup_status' where task_name='$CFG_task_name'"
    ret=$?
    sleep 1
  done      
  rm -rf $status_file
  rm -rf $process_file
  cp -rf $log_file "$log_path"
  rm -rf $log_file
  rm -rf $iso_file
  #rm -rf $count_file
  rm -rf /tmp/backup_status_file_${CFG_task_name}
  rm -rf "${iso_tmp}"
  rm -rf ${passwd_file}

  if [ "`ps | grep '[l]syncd '`" == "" ];then
      rm -f ${lsyncd_pid_data}
  fi
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

backup_action(){
  ret=`/usr/bin/ipv6check -p "${OPT_ip}"`
  if [ "${ret}" != "ipv6 format Error" ];then
    OPT_ip="[${OPT_ip}]"
  fi
  
  if [ "${OPT_dest_folder}" == "" ];then
      target_folder="raidroot"
  else
     if [ "${OPT_subfolder}" != "" ];then
        target_folder="${OPT_dest_folder}/${OPT_subfolder}"
     else
        target_folder="${OPT_dest_folder}"
     fi
  fi

  if [ "${OPT_port}" == "" ];then
     OPT_port="873"
  fi

  if [ "${OPT_timeout}" == "" ];then
     OPT_timeout="600"
  fi

###check process###  
  has_process=`check_task_processing "${status_file}"`  
  if [ "$has_process" != "1" ];then
###check_raid_status###
    touch $status_file
    raid_status=`get_raid_status`

    if [ "${raid_status}" == "1" ];then
      eventlog "${CFG_task_name}" "35" "${action}" "$log_file" "" 
      changestatus "${CFG_task_name}"
      exit
    fi

    raid_status=`get_migrate_status`
    if [ "${raid_status}" == "1" ];then
      eventlog "${CFG_task_name}" "31" "${action}" "$log_file" ""
      changestatus "${CFG_task_name}"
      exit
    fi
    
    if [ "${OPT_remote_back_type}" == "iscsi" ];then
        iscsi_target=`echo ${OPT_src_folder} | awk -F':' '{print $2}' | awk -F'_' '{print $2}'`
        iscsi_warn_log="iSCSI Target [${iscsi_target}] will be disabled when task [${action}]."
    fi
    
###start event log###
    $logevent 997 457 info email "${CFG_task_name}" "${action}" "${iscsi_warn_log}" 
    #rm -rf $log_file
    rm -rf $count_file
###update db end_time and task status###
    end_time=`date "+%Y/%m/%d %k:%M"`
    log_time=`date "+%Y%m%d%H%M%S"`
    backup_status="1"
    
    ret=1
    while [ "${ret}" != "0" ]
    do
      $Ldataguard_sqlite $Ldataguard_backupdb "update task set last_time='$end_time',status='$backup_status' where task_name='$CFG_task_name'"
      ret=$?
      sleep 1
    done      

###get task info###    
    #get_task_info

    if [ "${OPT_remote_back_type}" == "full" ];then
      OPT_src_folder=`ls -1 "/raid/data/ftproot" | sed '/^_P2P_DownLoad_/d' | sed '/^data/d' | sed '/^snapshot/d' | sed '/^_NAS_Module_Source_/d' | sed '/^_Module_Folder_/d' | sed '/^iSCSI_*/d' | sed '/^eSATAHDD/d' | sed '/^USBHDD/d' | sed -e :x -e '$!N; s/\n/\//;tx'`
      ${mgmt_nasconfig} check_nas_folder "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "${OPT_username}" "${OPT_passwd}" "${OPT_src_folder}"
    elif [ "${OPT_remote_back_type}" == "iscsi" ];then
      para_inplace=" --inplace --partial"
      OPT_src_folder=`echo ${OPT_src_folder} | awk -F':' '{print $2}'`
    fi

    partial=""
    if [ "${OPT_inplace}" == "1" ];then
          if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
              #I=1 , P=1
              partial=", \"--inplace\""
          else
              partial="--inplace"
          fi
    else
        if [ "${OPT_partial}" == "1" ];then
          #I=0 , P=1
          if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
              #I=1 , P=1
              partial=", \"--partial-dir=.dataguard\""
          else
              partial="--partial-dir=.dataguard"
          fi
        fi
    fi

    sync_data=""
    if [ "${OPT_sync_type}" == "sync" ];then
      if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
          sync_data=", \"--delete\" , \"--delete-after\""
      else
          sync_data="--delete --delete-after"
      fi
    fi

    para_bwlimit=""    
    if [ "${OPT_speed_limit_KB}" != "" ] && [ "${OPT_speed_limit_KB}" != "0" ];then
        #speed=$((${OPT_speed_limit} * 1024))
        speed=${OPT_speed_limit_KB}
        if [ "${speed}" != "" ];then
            if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
                para_bwlimit=", \"--bwlimit=${speed}\""
            else
                para_bwlimit="--bwlimit=${speed}"
            fi
        fi
    fi

    rsync_para="-8rltDvH"
    if [ "${OPT_compress}" == "1" ];then
      rsync_para="${rsync_para}z"
    fi

    if [ "${OPT_sparse}" == "1" ];then
      rsync_para="${rsync_para}S"
    fi
    
    if [ "${OPT_acl}" == "1" ];then
      rsync_para="${rsync_para}ogA"
      chmod_acl=""
    else
      if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
          chmod_acl=", \"--chmod=ugo=rwX\""
      else
          chmod_acl="--chmod=ugo=rwX"
      fi  
    fi

    if [ "${OPT_encryption}" == "1" ];then
      test_result=`${rsync_test} "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "test" "${OPT_username}" "${OPT_passwd}" "2"`
      test_ret=`echo ${test_result}|awk '{print $NF}'`
      
      if [ "${test_ret}" == "711" ] || [ "${test_ret}" == "712" ] || [ "${test_ret}" == "713" ];then
        eventlog "${CFG_task_name}" "12" "${action}" "" ""
        changestatus "${CFG_task_name}"
        exit 
      fi

      if [ -f "/etc/ssh/id_dsa.new" ] && [ -f "/etc/ssh/id_dsa.pub.new" ];then
        ssh_option=" -i /etc/ssh/id_dsa.new"
      else
        ssh_option=" -i /etc/ssh/id_dsa"
      fi
      
    fi    
###get iso info###
    get_iso_info "${iso_file}"

###get source folder###
    folder_count=`echo "$OPT_src_folder" | awk -F'/' '{print NF}'`
    total_folder=""
    lose_folder=""
    target_lose_folder=""
    RET_tmp1="0"
    RET_tmp2="0"
###get source folder path###
    for ((i=1;i<=$folder_count;i++))
    do
      strExec="echo '$OPT_src_folder' | awk -F'/' '{print \$$i}'"
      single_folder=`eval $strExec`
      check_folder_path=`echo "${OPT_src_path}" | awk -F'/' '{print $2}'`
      if [ "${check_folder_path}" == "" ];then
          folder_path="${ftproot}/${single_folder}"
          folder="${single_folder}"
          folder_path_re="${ftproot}/${single_folder}"
          
          tmp_destfolder="${single_folder}"         
      else
          folder="${OPT_src_path}/${single_folder}"
          folder_path="${ftproot}${folder}"          
          folder_path_re="${ftproot}/${check_folder_path}"
                    
          tmp_localfolder=`echo ${folder} |sed "s/^\/${check_folder_path}//g"`
          folder_restore_test=`echo ${folder} |sed "s/^\/${check_folder_path}/\${check_folder_path}/g"`
          tmp_destfolder="${folder}"                                           
      fi
      subfolder_count=`echo "$folder" | awk -F'/' '{print NF}'`
      if [ "${OPT_dest_folder}" != "" ] ;then
        if [ "${check_folder_path}" == "" ];then
           tmp_destfolder="/${single_folder}"
        fi
        
        if [ "${OPT_subfolder}" != "" ];then
           tmp_destfolder="/${OPT_subfolder}${tmp_destfolder}"
        fi
      fi
      
      stack_flag="0"
          
      if [ "${OPT_dest_folder}" == "" ];then
        if [ "${check_folder_path}" == "" ];then
           check_remote_folder_path="${folder}"
        else
           check_remote_folder_path="${check_folder_path}"
        fi
        test_result=`${rsync_test} "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "${check_remote_folder_path}" "${OPT_username}" "${OPT_passwd}"`
        test_ret=`echo ${test_result}|awk '{print $NF}'`
      else
        if [ "$i" == "1" ];then 
          test_result=`${rsync_test} "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "${OPT_dest_folder}" "${OPT_username}" "${OPT_passwd}"`
          test_ret=`echo ${test_result}|awk '{print $NF}'`

          if [ "${test_ret}" == "703" ];then
            target_lose_folder="${OPT_dest_folder}"
            break
          fi

          if [ "${test_ret}" == "700" ];then
            eventlog "${CFG_task_name}" "10" "${action}" "" ""
            changestatus "${CFG_task_name}"
            exit 
          fi
          
          if [ "${test_ret}" == "701" ];then
            eventlog "${CFG_task_name}" "32" "${action}" "" ""
            changestatus "${CFG_task_name}"
            exit 
          fi
                
          if [ "${test_ret}" == "709" ];then
            eventlog "${CFG_task_name}" "38" "${action}" "" ""
            changestatus "${CFG_task_name}"
            exit 
          fi
        fi
      fi
      
      if [ "${action}" == "Restore" ];then
         if [ "${OPT_dest_folder}" == "" ] && [ "${subfolder_count}" -gt "2" ];then          
             test_result=`${rsync_test} "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "${folder_restore_test}" "${OPT_username}" "${OPT_passwd}"`
             test_ret=`echo ${test_result}|awk '{print $NF}'`
         elif [ "${OPT_dest_folder}" != "" ] && [ "${subfolder_count}" -gt "2" ];then              
             test_result=`${rsync_test} "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "${OPT_dest_folder}${tmp_destfolder}" "${OPT_username}" "${OPT_passwd}"`
             test_ret=`echo ${test_result}|awk '{print $NF}'`
         fi
      fi

      if [ "${action}" == "Restore" ];then
          if [ "${test_ret}" == "703" ];then
            target_lose_folder="$folder ${target_lose_folder}"
          else
            if [ ! -d "$folder_path" ];then                         
              if [ -d "${folder_path_re}" ];then  
                  mkdir -p "${folder_path}"                                              
              else
                  if [ "${OPT_remote_back_type}" == "iscsi" ];then
                    if [ -d "${OPT_iscsi_full_path}" ];then
                      raidno=`echo {iscsi_full_path} |awk -F\/ '{print $2}' | awk -F'raid' '{print $2}'`
                      /img/bin/user_folder.sh "add" "${folder}" "${raidno}" "iSCSI Target" "no" "no"
                    else
                      raidno=`ls -la /raid |awk -F\/ '{print $3}' | awk -F'raid' '{print $2}'`
                      /img/bin/user_folder.sh "add" "${folder}" "${raidno}" "iSCSI Target" "no" "no"
                    fi
                  else
                    lose_folder="$folder ${lose_folder}"
                  fi
              fi
            fi
          fi
          
          if [ "${test_ret}" == "707" -a "${lose_folder}" == "" ];then
            total_folder="${total_folder}$folder:"
          fi
      else
          if [ -d "${folder_path}" ];then
            if [ "${test_ret}" == "707" ];then
              if [ "${OPT_dest_folder}" == "" ];then
                sub_folder=${tmp_localfolder}
                t_dest_folder=${check_folder_path}
              else            
                sub_folder=${tmp_destfolder}
                t_dest_folder=${OPT_dest_folder}
              fi
              total_folder="${total_folder}$folder:"

              build_folder=`${rsync_test} "${CFG_task_name}" "${OPT_ip}" "${OPT_port}" "${t_dest_folder}" "${OPT_username}" "${OPT_passwd}" "${OPT_encryption}" "${sub_folder}"`
            else
              target_lose_folder="$folder ${target_lose_folder}"
            fi
          else
            lose_folder="$folder ${lose_folder}"
          fi
      fi
    done

    if [ "$total_folder" != "" ];then
      if [ "${lose_folder}" != "" ];then
        eventlog "${CFG_task_name}" "16" "${action}" "$log_file" "${lose_folder}" 
      fi

      if [ "${target_lose_folder}" != "" ];then
        eventlog "${CFG_task_name}" "37" "${action}" "$log_file" "$target_lose_folder"
      fi
          
###start backup###
      if [ "${action}" == "Backup" ] || [ "${action}" == "Restore" ];then
        echo "${OPT_passwd}" > "${passwd_file}"
        chmod 600 "${passwd_file}"

###execute rsync###
          sum=0          
          
          if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
             echo "settings = {" > ${lsync_conf}
             echo "   logfile    = \"${log_path}_filelist\"," >> ${lsync_conf}
#             echo "   statusFile = \"${log_path}_lsyncd_status\"," >> ${lsync_conf}
             echo "   nodaemon   = false," >> ${lsync_conf}
             echo "}" >> ${lsync_conf}
             echo "" >> ${lsync_conf}
          fi
              	
          folder_count=$((`echo "$total_folder" | awk -F':' '{print NF}'`-1))
          for((i=1;i<=$folder_count;i++))
          do
            folder_info=`echo "$total_folder" | awk -F':' '{print $'$i'}'`                    
            tmp_folder_count=`echo "$folder_info" | awk -F'/' '{print NF}'`
            if [ "${tmp_folder_count}" -lt "2" ];then
                tmp_folder="${ftproot}/$folder_info/"
            else
                tmp_folder="${ftproot}$folder_info/"
            fi
            folder_info2=`echo ${folder_info} |sed "s/^\/${check_folder_path}/\${check_folder_path}/g"`
            
            iso_folder=`echo "${folder_info2}" | awk -F'/' '{print $1}'`
            
            if [ "${OPT_dest_folder}" == "" ];then
                target_folder="${folder_info2}"
                log_folder="${target_folder}"
            else
                if [ "${OPT_subfolder}" != "" ];then               
                    target_folder="${OPT_dest_folder}/${OPT_subfolder}/${folder_info2}"
                else               
                    target_folder="${OPT_dest_folder}/${folder_info2}"
                fi
                log_folder="${OPT_dest_folder}"
            fi
            
            if [ "${action}" == "Backup" -a "${OPT_backup_conf}" == "1" ];then
              get_acl "${tmp_folder}" "${acl_file}"
            fi

            tmp_folder="$tmp_folder"
            
		    touch "${iso_tmp}"	
            cat "${iso_file}" | \
            while read iso_path
            do
                tnf=`echo "${iso_path}" | awk -F'/' '{print NF}'` 
                echo "${iso_path}" | awk -F'/' "{if (\$2==\"$iso_folder\")print \$$tnf}" >> "${iso_tmp}"
            done

            if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
                echo "sync{" >> ${lsync_conf}
                echo "   default.rsync," >> ${lsync_conf}
                echo "   source=\"${tmp_folder}\"," >> ${lsync_conf}
            
                if [ "${OPT_encryption}" == "1" ];then
                   target_folder=`echo "${target_folder}" | sed 's/ /\\\\\\\ /g'`
                   echo "   target=\"root@${OPT_ip}:${ftproot}/${target_folder}\"," >> ${lsync_conf}
                   echo "   rsyncOpts={\"${rsync_para}\", \"-e\", \"/usr/bin/ssh ${ssh_option} -p 23 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\", \"--log-file=${log_path}\", \"--timeout=${OPT_timeout}\", \"--safe-links\", \"--exclude-from=${iso_tmp}\"${sync_data}${chmod_acl}${partial}${para_bwlimit}}" >> ${lsync_conf}
                else
                   echo "   target=\"${OPT_username}@${OPT_ip}::${target_folder}\"," >> ${lsync_conf}
                   echo "   rsyncOpts={\"${rsync_para}\", \"--port=${OPT_port}\", \"--log-file=${log_path}\", \"--timeout=${OPT_timeout}\", \"--safe-links\", \"--exclude-from=${iso_tmp}\",\"--password-file=${passwd_file}\"${sync_data}${chmod_acl}${partial}${para_bwlimit}}" >> ${lsync_conf}
                fi
                echo "}" >> ${lsync_conf}    
            else
                if [ "${action}" == "Restore" ] && [ "${OPT_encryption}" == "1" ];then
                   target_folder=`echo "${target_folder}" | sed 's/ /\\\ /g'` 
                   backup_path="\"root@${OPT_ip}:${ftproot}/${target_folder}/\" \"$tmp_folder\""
                elif [ "${action}" == "Restore" ] && [ "${OPT_encryption}" != "1" ];then    
                   backup_path="\"${OPT_username}@${OPT_ip}::${target_folder}/\" \"$tmp_folder\""
                elif [ "${action}" == "Backup" ] && [ "${OPT_encryption}" == "1" ];then
                   target_folder=`echo "${target_folder}" | sed 's/ /\\\ /g'`
                   backup_path="\"$tmp_folder\" \"root@${OPT_ip}:${ftproot}/${target_folder}\""
                else   
                   backup_path="\"$tmp_folder\" \"${OPT_username}@${OPT_ip}::${target_folder}\""
                fi
                
                if [ "${OPT_remote_back_type}" == "iscsi" ];then
                  rsync_para="${rsync_para}ogA"
                  tfolder=`echo "${tmp_folder}" | awk -F'/' '{print $5}'`
                  iscsi_service "${tfolder}" "stop"
                fi
            
                if [ "${OPT_encryption}" == "1" ];then
                                      strExec="$rsync ${rsync_para} ${para_inplace} ${para_bwlimit} --progress -e \"/usr/bin/ssh ${ssh_option} -p 23 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no\" --log-file=\"$log_file\" ${chmod_acl} --timeout=${OPT_timeout} --safe-links --exclude-from='$iso_tmp' ${sync_data} ${partial} $backup_path > ${process_file}"
                else
                   strExec="$rsync ${rsync_para} ${para_inplace} ${para_bwlimit} --progress --log-file=\"$log_file\" --port=${OPT_port} ${chmod_acl} --timeout=${OPT_timeout} --safe-links --exclude-from='$iso_tmp' ${sync_data} ${partial} --password-file=\"${passwd_file}\" $backup_path > ${process_file}"
                fi
                eval $strExec
                RET=$?
                if [ "${action}" == "Restore" ];then
                    chown -R nobody:users $tmp_folder
                fi
                
                if [ "${OPT_remote_back_type}" == "iscsi" ];then
                  tfolder=`echo "${tmp_folder}" | awk -F'/' '{print $5}'`
                  
                  if [ "${action}" == "Restore" ];then
                    iscsi_restore "${tfolder}"
                  fi
                  
                  iscsi_service "${tfolder}" "start"
                fi
                
                tmp_count=`sed -nr 's/.*to-check=(.*)\/(.*)\)/ \2/p' ${process_file} | tail -n 1`
                if [ "${tmp_count}" != "" ];then
                  sum=$(($sum + $tmp_count))
                  echo $sum > ${count_file}
                fi

                if [ "$RET" != "137" ];then
                    if [ "$RET" != "0" ];then
                      RET_tmp1="$RET"
                      eventlog "${CFG_task_name}" "$RET" "${action}" "$log_file" "${log_folder}" 
                    fi
                else
                    RET_tmp2="$RET"
                fi
                    
            fi
          done
          
          if [ "${CFG_back_type}" == "realtime" ] && [ "${action}" == "Backup" ];then
            ${lsyncd} ${lsync_conf} -pidfile ${pid} > /dev/null 2>&1 &
          else
            ###set status#####
            if [ "$RET_tmp2" != "137" ];then
                if [ "$RET_tmp1" == "0" ];then
                    eventlog "${CFG_task_name}" "$RET" "${action}" "$log_file" ""
                    changestatus "${CFG_task_name}"
                else
                    changestatus "${CFG_task_name}"
                fi
            fi
          fi
          
          if [ "${action}" == "Backup" -a "${OPT_backup_conf}" == "1" ];then            
            backup_conf_to_remote "${CFG_task_name}" "${OPT_username}" "${OPT_passwd}" "${OPT_ip}" "${OPT_port}"
            rm -rf $acl_file
          fi
      fi
    else          
      if [ "$lose_folder" != "" ];then
        eventlog "${CFG_task_name}" "16" "${action}" "$log_file" "$lose_folder"
      fi

      if [ "$target_lose_folder" != "" ];then
        eventlog "${CFG_task_name}" "37" "${action}" "$log_file" "$target_lose_folder"
      fi

      if [ "${test_ret}" == "700" ];then
        eventlog "${CFG_task_name}" "10" "${action}" "$log_file" ""
      fi

      if [ "${test_ret}" == "701" ];then
        eventlog "${CFG_task_name}" "32" "${action}" "$log_file" ""
      fi
          
      changestatus "${CFG_task_name}"
      exit 
    fi
  else
    eventlog "${CFG_task_name}" "34" "${action}" "$log_file" "" #processing  
    exit
  fi
}

add_cron(){
  if [ "${OPT_schedule_enable}" == "0" ];then
    del_cron
    exit
  fi

  OPT_backup_time=`echo $OPT_backup_time | sed 's/,/ /g'`
  Ldataguard_crond_control "${tid}" "${process_name}" "add" "Backup" "${OPT_backup_time}"
}

del_cron(){
  Ldataguard_crond_control "${tid}" "${process_name}" "remove" "Backup"
}

iscsi_service(){
  local iscsifolder=$1
  local action=$2

  iscsi_conf="/raid/data/ftproot/${iscsifolder}/.iscsi_conf.bin"
  path=`readlink /raid/data/ftproot/${iscsifolder}`
  raid_no=`echo "${path}" | awk -F'/' '{print $2}' | sed 's/^raid//g'`
  iscsi_name=`echo ${iscsifolder}|sed 's/^iSCSI_//g'`
  
  if [ "${raid_no}" == "" ] || [ "${iscsi_name}" == "" ];then
    echo "No data with this iSCSI folder -- ${folder}"
    return
  fi
  
  if [ "${action}" == "stop" ];then
    /usr/bin/des -k iscsi_conf -E /raid${raid_no}/sys/smb.db ${iscsi_conf}
    /img/bin/rc/rc.iscsi delete ${iscsi_name} ${raid_no}
  elif [ "${action}" == "start" ];then
    rm ${iscsi_conf}
    /img/bin/rc/rc.iscsi add ${iscsi_name} ${raid_no}
  fi
}

iscsi_restore(){
  local iscsifolder=$1
  iscsi_conf="/raid/data/ftproot/${iscsifolder}/.iscsi_conf.bin"
  tsmb_db="/raid/data/ftproot/${iscsifolder}/smb.db"
  
  if [ "${iscsi_conf}" == "" ];then
    echo "No this iscsi config."
    return
  fi    
  
  path=`readlink /raid/data/ftproot/${iscsifolder}`
  raid_no=`echo "${path}" | awk -F'/' '{print $2}' | sed 's/^raid//g'`
  iscsi_name=`echo ${iscsifolder}|sed 's/^iSCSI_//g'`
      
  if [ "${raid_no}" == "" ] || [ "${iscsi_name}" == "" ];then
    echo "No data with this iSCSI folder -- ${folder}"
    return
  fi
  
  /usr/bin/des -k iscsi_conf -D "${iscsi_conf}" "${tsmb_db}"
  if [ "${tsmb_db}" == "" ];then
    echo "No this smb.db, maybe des fail."
    return
  fi
  
  chmod 777 "${tsmb_db}"
  
  #delete the iscsi config in Source
  iscsi_count=`$sqlite /raid${raid_no}/sys/smb.db "select * from iscsi where name='$iscsi_name'" | wc -l`
  if [ $iscsi_count -gt 0 ];then
    $sqlite /raid${raid_no}/sys/smb.db "delete from iscsi where name='$iscsi_name'"
    lunnamelist=`$sqlite /raid${raid_no}/sys/smb.db "select name from lun where target='$iscsi_name'"`
    $sqlite /raid${raid_no}/sys/smb.db "delete from lun where target='$iscsi_name'"
    for v in $lunnamelist
    do
      $sqlite /raid${raid_no}/sys/smb.db "delete from lun_acl where lunname='$v'"
    done
  fi
  
  get_info=`$sqlite ${tsmb_db} "select alias,name,enabled,chap,user,pass,chap_mutual,user_mutual,pass_mutual,year,month,crc_data,crc_header,v1,v2,v3,v4,v5 from iscsi where name='$iscsi_name'"`
  alias=`echo -e "$get_info" | awk -F '|' '{print $1}'`
  name=`echo -e "$get_info" | awk -F '|' '{print $2}'`
  enabled=`echo -e "$get_info" | awk -F '|' '{print $3}'`
  chap=`echo -e "$get_info" | awk -F '|' '{print $4}'`
  user=`echo -e "$get_info" | awk -F '|' '{print $5}'`
  pass=`echo -e "$get_info" | awk -F '|' '{print $6}'`
  chap_mutual=`echo -e "$get_info" | awk -F '|' '{print $7}'`
  user_mutual=`echo -e "$get_info" | awk -F '|' '{print $8}'`
  pass_mutual=`echo -e "$get_info" | awk -F '|' '{print $9}'`
  year=`echo -e "$get_info" | awk -F '|' '{print $10}'`
  month=`echo -e "$get_info" | awk -F '|' '{print $11}'`
  crc_data=`echo -e "$get_info" | awk -F '|' '{print $12}'`
  crc_header=`echo -e "$get_info" | awk -F '|' '{print $13}'`
  v1=`echo -e "$get_info" | awk -F '|' '{print $14}'`
  v2=`echo -e "$get_info" | awk -F '|' '{print $15}'`
  v3=`echo -e "$get_info" | awk -F '|' '{print $16}'`
  v4=`echo -e "$get_info" | awk -F '|' '{print $17}'`
  v5=`echo -e "$get_info" | awk -F '|' '{print $18}'`
  $sqlite /raid${raid_no}/sys/smb.db "insert into iscsi values ('$alias','$name','$enabled','$chap','$user','$pass','$chap_mutual','$user_mutual','$pass_mutual','$year','$month','$crc_data','$crc_header','$v1','$v2','$v3','$v4','$v5')"
  
  lunnamelist=`$sqlite ${tsmb_db} "select name from lun where target='$iscsi_name'"`
  for v in $lunnamelist
  do     
    get_info=`$sqlite ${tsmb_db} "select target,name,thin,id,percent,block,serial,v1,v2 from lun where target='$iscsi_name' and name='$v'"`
    target1=`echo -e "$get_info" | awk -F '|' '{print $1}'`
    name=`echo -e "$get_info" | awk -F '|' '{print $2}'`
    thin=`echo -e "$get_info" | awk -F '|' '{print $3}'`
    id=`echo -e "$get_info" | awk -F '|' '{print $4}'`
    percent=`echo -e "$get_info" | awk -F '|' '{print $5}'`
    block=`echo -e "$get_info" | awk -F '|' '{print $6}'`
    serial=`echo -e "$get_info" | awk -F '|' '{print $7}'`
    v1=`echo -e "$get_info" | awk -F '|' '{print $8}'`
    v2=`echo -e "$get_info" | awk -F '|' '{print $9}'`

    $sqlite /raid${raid_no}/sys/smb.db "insert into lun values ('$target1','$name','$thin','$id','$percent','$block','$serial','$v1','$v2')"

    acl_list=`$sqlite ${tsmb_db} "select init_iqn from lun_acl where lunname='$v'"`
    for client_iqn in $acl_list
    do
        get_info=`$sqlite ${tsmb_db} "select init_iqn, lunname, privilege,v1,v2 from lun_acl where lunname='$v' and init_iqn='${client_iqn}'"`    
        init_iqn=`echo -e "$get_info" | awk -F '|' '{print $1}'`
        lunname=`echo -e "$get_info" | awk -F '|' '{print $2}'`
        privilege=`echo -e "$get_info" | awk -F '|' '{print $3}'`
        v1=`echo -e "$get_info" | awk -F '|' '{print $4}'`
        v2=`echo -e "$get_info" | awk -F '|' '{print $5}'`
        $sqlite /raid${raid_no}/sys/smb.db "insert into lun_acl values ('$init_iqn','$lunname','$privilege','$v1','$v2')"
    done
  done
                                                                       
  rm /raid/data/ftproot/${iscsifolder}/.iscsi_conf.bin
  rm "${tsmb_db}"
}

#######################################################
#
#  det remote conf list
#
#######################################################
remote_file_size(){
  if [ "${OPT_remote_back_type}" != "iscsi" ];then
    echo "No support."
    return
  fi

  echo "${OPT_passwd}" > "${passwd_file}"
  chmod 600 "${passwd_file}"
  
  if [ "${OPT_subfolder}" != "" ];then
    target_folder="${OPT_dest_folder}/${OPT_subfolder}"
  else
    target_folder="${OPT_dest_folder}"
  fi
  
  if [ "${target_folder}" == "" ];then
    target_path="${OPT_src_folder}/"
  else
    target_path="${OPT_dest_folder}/${OPT_src_folder}/"
  fi
  
  /usr/bin/rsync --list-only --port=${OPT_port} "${OPT_username}@${OPT_ip}::${target_path}" --password-file=${passwd_file} > /tmp/rsync_"${CFG_task_name}"_capacity
  
  if [ ! -f "/tmp/rsync_${CFG_task_name}_capacity" ];then
    echo 0
    return
  fi
  
  file_list=`cat /tmp/rsync_"${CFG_task_name}"_capacity | awk '{print $2}'`
  total=0
  for size in $file_list
  do
    total=$((${total} + ${size}))
  done
  
  echo ${total}
  rm /tmp/rsync_"${CFG_task_name}"_capacity
  rm ${passwd_file}
}

case "$action"
in
  Backup|Restore)
    check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${action}"
    backup_action
    ;;
  stop)
    check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${action}"
    stop_backup
    ;;
  add_cron)
    add_cron
    ;;  
  del_cron)
    del_cron
    ;;  
  iscsi)
    get_iscsi_conf $2
    ;;
  remote_capacity)
    remote_file_size
    ;;
  *)			
    echo "Usage: $0 { Backup | stop | Restore | boot}"
    ;;
esac
