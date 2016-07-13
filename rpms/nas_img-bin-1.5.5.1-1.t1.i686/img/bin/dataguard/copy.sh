#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
action=${1}
tid=${2}
external_tge=${3}
external_src=${4}

. /img/bin/function/lib_dataguard

logevent="/img/bin/logevent/event"
RSYNC="/usr/bin/rsync"
PROCESS_NAME="/img/bin/dataguard/copy.sh"

gRet="0"

if [ ! -z "$tid" ]; then ## 情況為非 allstop 行為
    eval `db_to_env $tid`

    oIFS=$IFS
    IFS='/'
    aryOPT_folder=($OPT_folder)
    IFS=$oIFS

    COUNT_FILE="/tmp/rsync_backup_${CFG_task_name}.count"
    LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
    STATUS_FILE="/tmp/rsync_backup_${CFG_task_name}.status"
    ISO_FILE="/tmp/rsync_${CFG_task_name}_iso.log"
    ISO_TMP="/tmp/rsync_${CFG_task_name}_iso_tmp.log"
fi

####################
rsync_backup(){
    local fSource_path_list=$1
    local fTarget_path_list=$2
    local fLog_file_tmp=$3
    local fIso_tmp=$4

    strexec="$RSYNC $RSYNC_PARA $CHMOD_ACL $DEL --log-file=\"$fLog_file_tmp\" --progress --timeout=600 --exclude-from=\"$fIso_tmp\" ${fSource_path_list} \"${fTarget_path_list}/\" > $COUNT_FILE"
    eval "$strexec"

    ret=`echo $?`

    if [ "$ret" != "137" ]; then
        if [ "$ret" != "" -a "$ret" != "0" ]; then
            eventlog "$CFG_task_name" "$ret" "$action" "$log_path" "" "$CFG_act_type"
            gRet=""
        fi
    else
        eventlog "$CFG_task_name" "37" "$action" "$log_path" "" "$CFG_act_type"
        gRet=""
    fi
}

####################
backup_task(){
    if [ "$CFG_back_type" != "copy" ]; then
        echo "backup type is not copy ..."
        exit
    fi

    check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${action}"
    Ldataguard_check_status "$CFG_task_name" "$STATUS_FILE" "$action" "$CFG_act_type"
    Ldataguard_get_raid_status "$CFG_task_name" "$action" "$LOG_TMP" "$log_path" "$CFG_act_type"
    Ldataguard_get_migrate_status "$CFG_task_name" "$action" "$LOG_TMP" "$log_path" "$CFG_act_type"
    get_iso_info $ISO_FILE
    touch "$ISO_TMP"

    for folder in "${aryOPT_folder[@]}"
    do
        path="${OPT_path}/${folder}"
        cat "$ISO_FILE" | \
        while read iso_path
        do
            folder_name=`echo "${path}" | awk -F"/" '{print $2}'`
            echo "${iso_path}" | awk -F"/" "{if (\$2==\"$folder_name\")print \$NF}" >> "$ISO_TMP"
        done
        path=`echo "${path}" | sed "s/'/\'\\\\\\''/g"`
        path_list="${path_list}'${path}' "
    done

    [ -z "$OPT_entire_external_copy" ] && OPT_entire_external_copy="0" ## 一開始有可能為空值
    
    ## List Source path [[ 
    if [ "$OPT_entire_external_copy" == "0" ]; then
        ## RAID: /raid#/data/[path]/folder
        ## External: /raid0/data/<external>/[path]/<folder>

        fSource_path_list=`Ldataguard_backup_source "$CFG_task_name" "$path_list" "$external_src"`
        fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
        fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`
    else
        ## External: /raid0/data/<externals>

        external_count=`echo "$external_src" | awk -F'//' '{print NF}'` ## 取得 external source 個數 (包含含有空白路徑)
        for ((i=1;i<=$external_count;i++))
        do
            aaaa="echo '$external_src' |awk -F'//' '{print \$${i}}'"
            qq=`eval $aaaa`
            if [ ! -d "${qq}" ]; then
                qq=`basename $qq`
                fLoss_folder="${fLoss_folder}"`echo "${qq}" | awk -F"/" '{print $5}'`", "
            else
                fSource_folder="${fSource_folder}'${qq}/' "
            fi
        done
    fi

    echo "$fLoss_folder" | sed 's/,$//g'
    if [ ! -z "$fLoss_folder" ]; then ## 確認來源是否存在
        eventlog "$CFG_task_name" "16" "$action" "$log_path" "$fLoss_folder" "$CFG_act_type"
        [ -z "$fSource_folder" ] && Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$action" && exit
    fi

    eval "arySource_folder=($fSource_folder)"
    ## List Source path ]]

    ## List Target path [[
    fLoss_folder=""

    if [ "$OPT_entire_external_copy" == "0" ]; then
        ##     RAID: /raid#/data/<target>
        ## External: /raid0/data/<external>/[target]

        fTarget_path_list=`Ldataguard_backup_target "$CFG_task_name" "$OPT_target" "$OPT_target_tag" "$OPT_device_type" "$external_tge" "$OPT_entire_external_copy"`
        fLoss_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $1}'`
        fTarget_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $2}'`

        eval "fTarget_folder=$fTarget_folder"

        fTarget_folder=`echo "$fTarget_folder" | sed 's/\`/\\\\\`/g'` ## 因為內嵌特殊字元, 導至路徑析出錯誤之修正
    else
        ## RAID: /raid#/data/<target>/<folder: Vender_Model_partition>
        ## RAID: /raid/data/stackable/<target_root>/data/<target_sub>/<folder: Vender_Model_partition>

        for ((i=0;i<${#arySource_folder[@]};i++)) ## 備份目錄個數必需全有對應
        do
            if [ ! -d "${ftproot}${OPT_target}/${aryOPT_folder[$i]}" ]; then
                mkdir "${ftproot}${OPT_target}/${aryOPT_folder[$i]}"
            fi

            if [ ! -d "${ftproot}${OPT_target}/${aryOPT_folder[$i]}" ]; then
                fLoss_folder="${fLoss_folder}"`echo "${aryOPT_folder[$i]}" | awk -F"/" '{print $5}'`", "
            else
                fTarget_folder="${fTarget_folder}'${ftproot}${OPT_target}/${aryOPT_folder[$i]}' "
            fi
        done

        eval "aryTarget_folder=($fTarget_folder)"
    fi

    echo "$fLoss_folder" | sed 's/,$//g'
    if [ ! -z "$fLoss_folder" ]; then ## 確認目標路徑是否存在
        eventlog "$CFG_task_name" "37" "$action" "$log_path" "$fLoss_folder" "$CFG_act_type"
        Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$action"
        exit
    fi
    ## List Target path ]]

    if [ "$OPT_device_type" != "1" ]; then
        rootfdr_name=`echo "$OPT_target" |awk -F '/' '{print $2}'`
        raid_root_path=`Ldataguard_get_raid_root_path "$rootfdr_name"`
    fi

    if [ "$OPT_device_type" == "0" ]; then
        
        if [ `echo "$raid_root_path" |awk -F '/' '{print $4}'` == "stackable" ]; then
            fGuest_only=`$Ldataguard_sqlite "/etc/cfg/stackable.db" "select \"guest_only\" from stackable where share='$rootfdr_name';"`
        else
            fTarget_smbdb=`Ldataguard_get_folder_smbdb "$OPT_dest_uuid"`
            fGuest_only=`$Ldataguard_sqlite ${fTarget_smbdb} "select \"guest only\" from smb_specfd where share='$rootfdr_name';select \"guest only\" from smb_userfd where share='$rootfdr_name'"`
        fi

        if [  "$fGuest_only" == "yes" ]; then ## 該 rootfdr 是 public 目錄
            ## 移除 ACL
            setfacl --remove-all -d -m user::rwx,group::rwx,other::rwx -P -R "$raid_root_path"

            ## 再變更權限
            chmod 777 -R "$raid_root_path"
        fi
    fi

    if [ "$OPT_device_type" == "0" ]; then
        RSYNC_PARA="-8rltDvHX"
    else
        RSYNC_PARA="-8rltDvH"
    fi

    if [ "$OPT_device_type" == "0" ]; then
        if [ "$OPT_acl" == "1" ]; then
            RSYNC_PARA="${RSYNC_PARA}A"
        fi
    fi

    if [ "$OPT_device_type" != "1" -a "$fGuest_only" == "yes" ]; then
        CHMOD_ACL="--chmod=ugo=rwX"
    fi

    if [ "${OPT_sync_type}" == "sync" ]; then
        DEL="--delete"
    elif [ "${OPT_sync_type}" == "incremental" ]; then
        DEL=""
    fi

    if [ "$OPT_entire_external_copy" == "1" ]; then
        for ((i=0; i<${#arySource_folder[@]}; i++))
        do
            rsync_backup "${arySource_folder[$i]}" "${aryTarget_folder[$i]}" "$LOG_TMP" "$ISO_TMP" ## 執行備份, 一對一
            chown -R nobody.users "${aryTarget_folder[$i]}"
        done
    else
        rsync_backup "${fSource_folder}" "${fTarget_folder}" "$LOG_TMP" "$ISO_TMP" ## 執備份行, 多對一

        if [ "$OPT_device_type" == "1" ]; then 
            chown -R nobody.nogroup "$fTarget_folder"
        else
            chown -R nobody.users "$fTarget_folder"
            chmod 777 -R "$fTarget_folder"
        fi
    fi

    if [ "$gRet"  == "0"  ]; then ## 全部動作正常, 送一個事件記錄
        eventlog "$CFG_task_name" "$gRet" "$action" "$log_path" "" "$CFG_act_type"
    fi

    Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$action"
}

####################
stop_task(){
    if [ -z "$tid" ]; then
        task_id_list=(`$Ldataguard_sqlite $Ldataguard_backupdb "select tid from task where back_type='copy' and act_type='local'"`)
        for task_id in ${task_id_list[@]}
        do
            eval `db_to_env $task_id`
            LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
            Ldataguard_stop_task "$CFG_tid" "$CFG_task_name" "$PROCESS_NAME" "$LOG_TMP" "$OPT_log_folder" "$CFG_act_type"
        done
    else
        Ldataguard_stop_task "$CFG_tid" "$CFG_task_name" "$PROCESS_NAME" "$LOG_TMP" "$OPT_log_folder" "$CFG_act_type"
    fi
}

########################################
case "$action"
in
    start)
        backup_task
        ;;
    stop|allstop)
        stop_task
        ;;
    *)
        echo "Usage: $0 { start | stop | allstop }"
        ;;
esac

