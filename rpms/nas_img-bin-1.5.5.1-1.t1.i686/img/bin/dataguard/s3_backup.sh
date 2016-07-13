#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
export LANG=en_US.UTF-8

action=$1
tid=$2
libbackup="/img/bin/function/lib_dataguard"
. ${libbackup}

if [ "${tid}" == "" ];then
    echo "Task id is null."
    exit
fi

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
s3_test="/img/bin/dataguard/s3_test.sh"    
mgmt_nasconfig="/img/bin/dataguard/mgmt_nasconfig.sh"    
s3cmd="/img/bin/dataguard/s3cmd/s3cmd"
process_name="/img/bin/dataguard/s3_backup.sh"
string_cmd="/usr/bin/specstr_handle"
default_conf_file="/img/bin/dataguard/s3cmd/s3_default_conf"
conf_file="/tmp/s3_${CFG_task_name}_conf"
log_file_status="/raid/data/tmp/s3_backup.${CFG_task_name}.status"
status_file="/tmp/s3_backup_${CFG_task_name}.status"
iso_file="/tmp/s3_${CFG_task_name}_iso.log"
iso_tmp="/tmp/s3_${CFG_task_name}_iso_tmp.log"
progress_file="/raid/data/tmp/s3_${CFG_task_name}_progress"
log_file="/raid/data/tmp/s3_backup.${CFG_task_name}"

stop_backup(){
    strExec="/bin/ps wwww | grep '${s3cmd} --config=${conf_file} ' | grep -v grep | awk '{print \$1}'"
    s3_pid=`eval $strExec`      
    strExec="/bin/ps wwww | grep '${process_name}' | grep ' ${tid}$' | grep -v grep | grep -v ' stop' |awk '{print \$1}'"
    process_pid=`eval $strExec`
    if [ "${s3_pid}" != "" -o "${process_pid}" != "" ];then
        strExec="/bin/ps wwww | grep '${process_name}' | grep ' ${tid}$' | grep -v grep | grep -v ' stop' |awk '{print \$7}'"
        types=`eval $strExec`  
        kill -9 $s3_pid $process_pid
        log_flag="1"
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
    cp $log_file $log_path
    rm -rf $progress_file
    rm -rf $log_file
    rm -rf $iso_file
    rm -rf /tmp/backup_status_file_${CFG_task_name}
    rm -rf "${iso_tmp}"
    rm ${conf_file}
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
    if [ "${OPT_dest_folder}" == "" ];then
        eventlog "${CFG_task_name}" "37" "${action}" "$log_file" "" "S3 Bucket"
        changestatus "${CFG_task_name}"
        exit
    else
        if [ "${OPT_subfolder}" != "" ];then
            target_folder="${OPT_dest_folder}/${OPT_subfolder}"
        else
            target_folder="${OPT_dest_folder}"
        fi
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

    ###start event log###
    $logevent 997 457 info email "${CFG_task_name}" "${action}"
    
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

    test_result=`${s3_test} "${CFG_task_name}" "${OPT_username}" "${OPT_passwd}" "${OPT_dest_folder}" "${OPT_subfolder}"`
    test_ret=`echo ${test_result}|awk '{print $NF}'`
      
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
                
    if [ "${test_ret}" == "703" ];then
        target_lose_folder="${OPT_dest_folder}/${OPT_subfolder}"
        break
    fi

    if [ "${test_ret}" == "710" ] || [ "${test_ret}" == "" ];then
        eventlog "${CFG_task_name}" "" "${action}" "" ""
        changestatus "${CFG_task_name}"
        exit 
    fi
    
    cp ${default_conf_file} ${conf_file}
    echo "access_key = ${OPT_username}" >> ${conf_file}
    echo "secret_key = ${OPT_passwd}" >> ${conf_file}
    echo "progress_file = \"${progress_file}\"" >> ${conf_file}
    chmod 600 ${conf_file}
    
    if [ "${OPT_sync_type}" == "sync" ];then
        sync_para="--delete-removed"
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
            folder="${single_folder}"
            folder_path="${ftproot}/${folder}"
            folder_path_re="${ftproot}/${single_folder}"
            
            tmp_destfolder="${folder}"
        else
            folder="${OPT_src_path}/${single_folder}"
            folder_path="${ftproot}${folder}"          
            folder_path_re="${ftproot}/${check_folder_path}"
                    
            tmp_localfolder=`echo ${folder} |sed "s/^\/${check_folder_path}//g"`
            folder_restore_test=`echo ${folder} |sed "s/^\/${check_folder_path}/\${check_folder_path}/g"`
            tmp_destfolder="${folder}"                                           
        fi
        
        if [ "${OPT_dest_folder}" != "" ] ;then
            if [ "${check_folder_path}" == "" ];then
                tmp_destfolder="${single_folder}"
            fi
        
            if [ "${OPT_subfolder}" != "" ];then
                tmp_destfolder="${OPT_subfolder}/${tmp_destfolder}"
            fi
        fi
      
        if [ "${action}" == "Restore" ];then
            test_result=`${s3_test} "${CFG_task_name}" "${OPT_username}" "${OPT_passwd}" "${OPT_dest_folder}" "${tmp_destfolder}"`
            test_ret=`echo ${test_result}|awk '{print $NF}'`
            folder_err=0

            if [ "${test_ret}" == "703" ];then
                target_lose_folder="$folder ${target_lose_folder}"
                folder_err=1
            else
                if [ ! -d "$folder_path" ];then                         
                    if [ -d "${folder_path_re}" ];then  
                        mkdir -p "${folder_path}"                                              
                    else
                        lose_folder="${folder} ${lose_folder}"
                        folder_err=1
                    fi
                fi
            fi
          
            if [ "${test_ret}" == "707" -a "${folder_err}" == "0" ];then
                total_folder="${total_folder}$folder:"
            fi
        else
            if [ -d "${folder_path}" ];then
                total_folder="${total_folder}$folder:"
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
            folder_count=$((`echo "$total_folder" | awk -F':' '{print NF}'`-1))
            for((i=1;i<=$folder_count;i++))
            do
                folder_info=`echo "$total_folder" | awk -F':' '{print $'$i'}'`                    
                tmp_folder_count=`echo "$folder_info" | awk -F'/' '{print NF}'`
                if [ "${tmp_folder_count}" -lt "2" ];then
                    local_folder="${ftproot}/$folder_info/"
                else
                    local_folder="${ftproot}$folder_info/"
                fi
                
                target_bottom_folder=`echo ${folder_info} | awk -F'/' '{print $NF}'`
                log_folder="${OPT_dest_folder}"
            
                if [ "${OPT_subfolder}" != "" ];then               
                    target_folder="${OPT_dest_folder}/${OPT_subfolder}/${target_bottom_folder}/"
                else               
                    target_folder="${OPT_dest_folder}/${target_bottom_folder}/"
                fi

                if [ "${action}" == "Restore" ];then
                    backup_path="\"s3://${target_folder}\" \"$local_folder\""
                else   
                    backup_path="\"$local_folder\" \"s3://${target_folder}\""
                fi
                
                strExec="${s3cmd} --config=${conf_file} --acl-public --progress sync ${sync_para} $backup_path > ${log_file} 2>&1"
                eval $strExec
                RET=$?
                
                if [ "$RET" != "0" ];then
                    eventlog "${CFG_task_name}" "$RET" "${action}" "$log_file" "${log_folder}" 
                fi
            done
          
            if [ "$RET" == "0" ];then
                eventlog "${CFG_task_name}" "$RET" "${action}" "$log_file" ""
            fi

            changestatus "${CFG_task_name}"
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
  *)			
    echo "Usage: $0 { Backup | Restore | stop | add_cron | del_cron}"
    ;;
esac
