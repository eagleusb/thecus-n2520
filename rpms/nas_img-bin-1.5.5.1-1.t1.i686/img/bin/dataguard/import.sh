#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
action=${1}
tid=${2}
external_tge=${3}
external_src=${4} 

. /img/bin/function/lib_dataguard

logevent="/img/bin/logevent/event"
RSYNC="/usr/bin/rsync"
PROCESS_NAME="/img/bin/dataguard/import.sh"

usrfdr="/img/bin/user_folder.sh"    
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

    strexec="$RSYNC $RSYNC_PARA $DEL --log-file=\"$fLog_file_tmp\" --progress --timeout=600 --exclude-from=\"$fIso_tmp\" \"${fSource_path_list}\" \"${fTarget_path_list}/\" > $COUNT_FILE"
    eval "$strexec"

    ret=`echo $?`

    if [ "$ret" != "137" ]; then
        if [ "$ret" != "" -a "$ret" != "0" ]; then
            fSource_path_list=`basename $fSource_path_list`
            eventlog "$CFG_task_name" "$ret" "$action" "$log_path" "$fSource_path_list" "$CFG_act_type"
            gRet=""
        fi
    else
        fTarget_path_list=`basename $fTarget_path_list`
        eventlog "$CFG_task_name" "37" "$action" "$log_path" "$fTarget_path_list" "$CFG_act_type"
        gRet=""
    fi
}

####################
backup_task(){
    if [ "$CFG_back_type" != "import" ]; then
        echo "backup type is not import ..."
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
    if [ "$OPT_entire_external_copy" == "0" ]; then ## 來源為 External: /raid0/data/<external>/[path]/folder
        fSource_path_list=`Ldataguard_backup_source "$CFG_task_name" "$path_list" "$external_src"`
        fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
        fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`
    fi

    echo "$fLoss_folder" | sed 's/,$//g'
    if [ ! -z "$fLoss_folder" ]; then ## 確認來源是否存在
        eventlog "$CFG_task_name" "16" "$action" "$log_path" "$fLoss_folder" "$CFG_act_type"
        [ -z "$fSource_folder" ] && Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$action" && exit
    fi

    eval "arySource_folder=($fSource_folder)"
    ## List Source path ]]



    ## List Target path [[
    ## RAID: /raid/data/ftproot/<folder: Vender_Model_Partition>

    fLoss_folder="" ## 清掉之前的
    raid_num=`echo ${OPT_target#/raid}` ## 取得該目標 RAID 組號碼

    if [ "$OPT_permission" == "public" ]; then
        guest_only="yes"
    elif [ "$OPT_permission" == "private" ]; then
        guest_only="no"
    fi

    for ((i=0;i<${#arySource_folder[@]};i++)) ## 備份目錄個數必需全有對應
    do
        tge_folder=`basename "${arySource_folder[$i]}"`
        sed_folder=`echo "${tge_folder}" |sed 's/[ ();&=\|]/\\\&/g'`
        #sed_folder=`echo "${tge_folder}" |sed 's/[~@$%^&()-={}; .,]/\\\&/g'`

        ## 找出不分大小寫之目錄名; 不管是不是在 stackable 之下
        path=`ls -l ${ftproot} |egrep -i "/${sed_folder}$|/stackable/${sed_folder}/data$" |sed -nr 's/.* -> (\/.*)$/\1/p'`

        if [ ! -z "$path" ]; then
            folder_msg="[ $tge_folder ] to" ## 因為參數格式, 所以組合成一個檔夾更名訊息 (orig)
            j="1"

            while [ -d "${ftproot}/${tge_folder}-$j" ] ## 找出尚未佔用過的檔案更名代號
            do
                j=$((j+1)) 
            done

            tge_folder="${tge_folder}-$j"
        fi

        if [ ! -d "${ftproot}/${tge_folder}" ]; then ## 建立不存在的目錄
             strexec="$usrfdr add \"$tge_folder\" $raid_num \"\" 1 $guest_only" ## 建立在所指定的 RAID 組號碼之下
             eval "$strexec"
        fi

        if [ ! -z "$j" ]; then
            folder_msg="$folder_msg [ $tge_folder ]" ## 因為參數格式, 所以組合成一個檔夾更名訊息 (renamed)
            eventlog "$CFG_task_name" "41" "$action" "$log_path" "$folder_msg" "$CFG_act_type" ## 表示有更新目錄檔名; 發出一個記錄
        fi

        raid_root_path=`Ldataguard_get_raid_root_path "$tge_folder"` ## 包含 stackable

        ## 檢查目錄
        if [ ! -d "${raid_root_path}" ]; then
            raid_root_path=`basename $raid_root_path`
            fLoss_folder="${fLoss_folder}"`echo "${raid_root_path}" | awk -F"/" '{print $5}'`", "
        else
            fTarget_folder="${fTarget_folder}'${raid_root_path}' "
        fi

    done

    eval "aryTarget_folder=($fTarget_folder)"

    echo "$fLoss_folder" | sed 's/,$//g'
    if [ ! -z "$fLoss_folder" ]; then ## 確認目標路徑是否存在
        eventlog "$CFG_task_name" "37" "$action" "$log_path" "$fLoss_folder" "$CFG_act_type"
        Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$action"
        exit
    fi
    ## List Target path ]]

    if [ "${OPT_sync_type}" == "sync" ]; then
        DEL="--delete"
    elif [ "${OPT_sync_type}" == "incremental" ]; then
        DEL=""
    fi

    RSYNC_PARA="-8rltDvH"

    for ((i=0; i<${#arySource_folder[@]}; i++))
    do
        ## 執行備份, 一對一
        rsync_backup "${arySource_folder[$i]}/" "${aryTarget_folder[$i]}" "$LOG_TMP" "$ISO_TMP"
        chown -R nobody.users "${aryTarget_folder[$i]}"

        if [ "$guest_only" == "yes" ]; then
            chmod 777 -R "${aryTarget_folder[$i]}"
        else
            chmod 700 -R "${aryTarget_folder[$i]}"
        fi
    done

    if [ "$gRet"  == "0"  ]; then ## 全部動作正常, 送一個事件記錄
        eventlog "$CFG_task_name" "$gRet" "$action" "$log_path" "" "$CFG_act_type"
    fi

    Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$action"
}

####################
stop_task(){
    if [ -z "$tid" ]; then
        task_id_list=(`$Ldataguard_sqlite $Ldataguard_backupdb "select tid from task where back_type='import' and act_type='local'"`)
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

