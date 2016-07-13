#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
gAction=$1
sqlite="/usr/bin/sqlite"
db="/etc/cfg/backup.db"
lsyncd="/usr/bin/lsyncd"
. /img/bin/function/lib_dataguard
hotplugremove(){
  task_id_list=(`"$Ldataguard_sqlite" "$Ldataguard_backupdb" "select tid from task where back_type='realtime' and act_type='local'"`)
  for task_id in ${task_id_list[@]}
  do
          flagm="0"
          eval `db_to_env $task_id`
          if [ "${OPT_device_type}" == "1" ];then
              dlist=`Ldataguard_external_path`
              for data in $dlist
              do
                if [  -f "$data$OPT_target/$OPT_target_tag" ];then
                         flagm="1"
                         break
                fi
              done
              if [ $flagm == "0" ];then
                stop $task_id
              fi
          fi
  done           
}
hotplugadd(){
   task_id_list=(`"$Ldataguard_sqlite" "$Ldataguard_backupdb" "select tid from task where back_type='realtime' and act_type='local' and status<>'1' "`)
   for task_id in ${task_id_list[@]}
   do
       eval `db_to_env $task_id`
       if [ "${OPT_sys_status}" == "1" ];then
            dlist=`Ldataguard_external_path`
            for data in $dlist
            do
                if [  -f "$data$OPT_target/$OPT_target_tag" ];then
                     start $task_id
                fi
            done
       fi
   done    
}
source_root_path(){
    local fFolder_raid
    local fFolder_path
    local fSrc_folder_path
    
    fFolder_raid=`Ldataguard_check_uuid "$OPT_src_uuid"`
    for folder in "${path_list[@]}"
     do
        if [ `echo "$fFolder_raid" | grep -c "/data/stackable/"` -lt 1 ]; then
              fFolder_path="${fFolder_raid}/data${folder}"
        else
              fFolder_name=`echo "${folder}" | awk -F"/" '{print $2}'`
              fFolder_path="${fFolder_raid}/data"`echo "${folder#/${fFolder_name}}"`
        fi
        if [ ! -e "$fFolder_path" ] ;then
              fLoss_folder="${fLoss_folder}"`basename "${fFolder_path}"`", "
        else
              fFolder_path=`echo "${fFolder_path}" | sed "s/'/\'\\\\\\''/g"`
              fSrc_folder_path="${fSrc_folder_path}'${fFolder_path}' "
        fi
     done
        echo "${fLoss_folder}//${fSrc_folder_path}"
}
target_root_path(){
    local fFolder_raid
    local fFolder_path
    local fTge_folder_path   
    
    fFolder_raid=`Ldataguard_check_uuid "$OPT_dest_uuid"`
    
    if [ `echo "$fFolder_raid" | grep -c "/data/stackable/"` -lt 1 ]; then
        fFolder_path="${fFolder_raid}/data${OPT_target}"
    else
        fFolder_name=`echo "${OPT_target}" | awk -F"/" '{print $2}'`
        fFolder_path="${fFolder_raid}/data"`echo "${OPT_target#/${fFolder_name}}"`
    fi
    if [ ! -e "$fFolder_path" ] ;then
         fLoss_folder="${fLoss_folder}"`basename "${fFolder_path}"`", "
    else
         fFolder_path=`echo "${fFolder_path}" | sed "s/'/\'\\\\\\''/g"`
         fTge_folder_path="${fTge_folder_path}'${fFolder_path}'"
    fi
    
    echo "${fLoss_folder}//${fTge_folder_path}"                     
}             
conf(){
  tid=$1
  eval `db_to_env $tid`
  if [ "$CFG_back_type" != "realtime" ];then
       return
  fi
  LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
  STATUS_FILE="/tmp/rsync_backup_${CFG_task_name}.status"
  check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${gAction}"
  Ldataguard_get_raid_status "$CFG_task_name" "${gAction}" "$LOG_TMP" "$log_path"  "$CFG_act_type"
  Ldataguard_get_migrate_status "$CFG_task_name" "${gAction}" "$LOG_TMP" "$log_path"  "$CFG_act_type"
  Ldataguard_check_status "$CFG_task_name" "$STATUS_FILE" "${gAction}" "$CFG_act_type"
  lsync_conf="/tmp/lsyncd_${CFG_task_name}.conf"
  log_file="/raid/data/tmp/lsync_backup.${CFG_task_name}"
  path_list=""

  if [ "$OPT_sync_type" == "sync" ];then
        model="0"
    else
       if [ "$OPT_sync_type" == "incremental" ];then
         model="1"
       fi    
  fi
  if [ "${model}" == "0" ] && [ "${OPT_acl}" == "1" ];then
      sync_data=", \"--delete\", \"-A\""
  elif [ "${model}" != "0" ] && [ "${OPT_acl}" == "1" ];then
      sync_data=", \"-A\""
  elif [ "${model}" == "0" ] && [ "${OPT_acl}" != "1" ];then
      sync_data=", \"--delete\""
  fi
  if [ "$OPT_filesize_enable" == "1" ];then
         if  [ "${OPT_minisize}" != "" ];then
                 sync_data=$sync_data", \"--min-size=${OPT_minisize}\""
         fi
         if  [ "${OPT_maxisize}" != "" ];then
                 sync_data=$sync_data", \"--max-size=${OPT_maxisize}\""
         fi
  fi
  if  [ "${OPT_include_enable}" == "1" ];then
     count=`echo $OPT_include_type|awk -F',' '{print NF}'`
     for ((i=1;i<=$count;i++))
     do
        strExec="echo '$OPT_include_type' | awk -F',' '{print \$$i}'"
        item=`eval $strExec`
        sync_data=$sync_data", \"--include=${item}\""
     done
     sync_data=$sync_data", \"--include=*/\", \"--exclude=*\""
  fi
  if  [ "${OPT_exclude_enable}" == "1" ];then
     count=`echo $OPT_exclude_type|awk -F',' '{print NF}'`
     for ((i=1;i<=$count;i++))
     do
        strExec="echo '$OPT_exclude_type' | awk -F',' '{print \$$i}'"
        item=`eval $strExec`
        sync_data=$sync_data", \"--exclude=${item}\""
     done
  fi
  if [ "$OPT_device_type" == "0" ];then
        rsync_para="-8rtDvHX"
   else
        rsync_para="-8rtDvH"
  fi
  if [ "${OPT_symbolic_link}" == "1" ];then
      rsync_para="${rsync_para}l"
  fi
  ISO_TMP="/tmp/rsync_${CFG_task_name}_iso_tmp.log"
  ISO_FILE="/tmp/rsync_${CFG_task_name}_iso.log"
  get_iso_info "$ISO_FILE"
  touch "$ISO_TMP"
  path="${OPT_path}/${OPT_folder}"
  cat "$ISO_FILE" | \
  while read iso_path
  do
      folder_name=`echo "${path}" | awk -F"/" '{print $2}'`
      echo "${iso_path}" | awk -F"/" "{if (\$2==\"$folder_name\")print \$NF}" >> "$ISO_TMP"
  done
  path=`echo "${path}" | sed "s/'/\'\\\\\\''/g"`
  path_list="${path_list}'${path}' "
  eval "path_list=($path_list)"
  fSource_path_list=`source_root_path`
  fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
  fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
  fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`
  if [ ! -z "$fLoss_folder" ]; then
       eventlog "$CFG_task_name" "16" "${gAction}" "$Ldataguard_fLog_tmp" "$fLoss_folder" "$CFG_act_type"
       if [ -z "$fSource_folder" ]; then
            Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
            exit
       fi
  fi
  eval "fSource_folder=($fSource_folder)"
  if [ "$OPT_device_type" != "1" ]; then
      fTarget_path_list=`target_root_path`
  else
      fTarget_path_list=`Ldataguard_backup_target "$CFG_task_name" "$OPT_target" "$OPT_target_tag" "$OPT_device_type" ""`
  fi
  fLoss_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $1}'`
  fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
  fTarget_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $2}'`
  eval "fTarget_folder=$fTarget_folder"
  if [ -z "$fTarget_folder" ]; then
       eventlog "$CFG_task_name" "37" "${gAction}" "$Ldataguard_fLog_tmp" "$fLoss_folder" "$CFG_act_type"
       Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
       exit
  fi
  log_rootpathreal=`Ldataguard_get_raid_root_path "$OPT_log_folder"`
  if [ "$fSource_folder" == "" ];then
         exit
  fi
  if [ "$fTarget_folder" == "" ];then
         exit
  fi
  if [ "$OPT_device_type" != "1" ]; then
         owner="nobody.users"
  else
         owner="nobody.nogroup"
  fi
  chown -R "$owner" "${fTarget_folder}"
  start_time=`date "+%Y%m%d_%H%M%S"`

  if [ "$gAction" == "start" ]; then
    echo "" > ${lsync_conf}
          
    echo "sync{" >> ${lsync_conf}
    echo "   default.rsync," >> ${lsync_conf}
    echo "   source=\"${fSource_folder}\"," >> ${lsync_conf}
    # filter the name of source folder and add to target
    new_folder=`echo ${fSource_folder} | awk -F'/' '{print $NF}'`
    echo "   target=\"${fTarget_folder}/${new_folder}\"," >> ${lsync_conf}
    echo "   rsyncOpts={\"${rsync_para}\", \"--chmod=ugo=rwX\", \"--log-file=${log_rootpathreal}/LOG_Data_Guard/${CFG_task_name}_start.${start_time}\",\"--exclude-from=${ISO_TMP}\", \"--timeout=600\"${sync_data}}" >> ${lsync_conf}
    echo "}" >> ${lsync_conf}
  elif [ "$gAction" == "restore" ]; then
    #COUNT_FILE was used to store rsync status
    COUNT_FILE="/tmp/rsync_backup_${CFG_task_name}.count"  
    sync_data=`echo ${sync_data} | sed  "s/,//g"`
    strexec="$rsync ${rsync_para} --log-file=\"${log_rootpathreal}/LOG_Data_Guard/${CFG_task_name}_start.${start_time}\" --exclude-from=\"${ISO_TMP}\" --timeout=600 ${sync_data} \"${fTarget_folder}\" \"${fSource_folder}/\" > $COUNT_FILE"
  fi
  
}
create(){
  tid=$1
  eval `db_to_env $tid`
  if [ "${OPT_device_type}" == "1" ];then
     echo "" > /raid/data/ftproot"$OPT_path""/$OPT_folder""/$OPT_target_tag"
     echo "" > "$2""$OPT_target""/$OPT_target_tag"
  fi
          
}
modify(){
  stop $1
  eval `db_to_env $tid`
  if [ "$OPT_device_type" == "1" ];then
      if [ "$OPT_target" == "" ]; then
         fFolder_path="$2"
      else
         fFolder_path="$2${OPT_target}"
      fi
      touch "${fFolder_path}/${OPT_target_tag}"
      touch "/raid/data/ftproot""$OPT_path""/$OPT_folder""/${OPT_target_tag}"
  fi
}

start(){
  tid=$1
  eval `db_to_env $tid`
  pid="/raid/data/tmp/lsyncd_pid_${CFG_task_name}"
  conf $1

  if [ "$gAction" == "start" ]; then
    ${lsyncd} ${lsync_conf} -pidfile ${pid} > /dev/null 2>&1 &
  elif [ "$gAction" == "restore" ]; then
    eval "$strexec"

    if [ "$?" != "137" ]; then
        eventlog "$CFG_task_name" "$?" "$gAction" "$log_path" "" "$CFG_act_type"
        gRet=""
    else
        eventlog "$CFG_task_name" "37" "$gAction" "$log_path" "" "$CFG_act_type"
        gRet=""
    fi

    Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$gAction"
  fi
}

stop(){
  tid=$1
  eval `db_to_env $tid`
  pid="/raid/data/tmp/lsyncd_pid_${CFG_task_name}"
  check_log_folder "$CFG_task_name" "$OPT_log_folder" "start"
  pids=`/bin/ps wwww | grep "lsync" | grep "${CFG_task_name}" | grep -v grep | awk '{print $1}'`
  if [ "${pids}" != "" ];then
    kill -9 ${pids}
  fi
  if [ "${pids}" != "" ] || [ -f /tmp/rsync_backup_${CFG_task_name}.status ]; then
    eventlog "$CFG_task_name" "15" "start" "" "" "$CFG_act_type"
    LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
    Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$OPT_log_folder"
    rm -rf $pid
  fi
}
allstop(){
  $sqlite $db "select tid from task where back_type='realtime' and act_type='local'" | while read file;do
    stop ${file} 
  done
}
allstart(){
  $sqlite $db "select tid from task where back_type='realtime' and act_type='local'" | while read file;do
    sys_status=`$sqlite $db "select value from opts where tid=$file and key='sys_status'"`
    if [ "$sys_status" == "1" ];then
       start $file
    fi
  done
}

  
case "$1"
in
   start|restore)
     start $2
     ;;
   stop)
     stop $2
     ;;
   create)
     create $2 $3
     ;;
   modify)
     modify $2 $3
     ;;  
   allstart)
     gAction="start" 
     allstart
     ;;  
   allstop)
     allstop
     ;;
   hotplugadd)
     hotplugadd
     ;;
   hotplugremove)
     hotplugremove
     ;;  
   *)
     echo "Usage: $0 { conf | start | stop }"
     ;;
esac
