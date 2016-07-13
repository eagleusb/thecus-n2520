#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
gAction=$1
gTid=$2
gExternal_target_path=$3

PROCESS_NAME="/img/bin/dataguard/schedule.sh"
PWD_PATH=`pwd`
STACK_DB="/etc/cfg/stackable.db"

. /img/bin/function/lib_dataguard
. /img/bin/function/libraid

if [ ! -z "$gTid" ]; then
    eval `db_to_env "$gTid"`
    [ "$CFG_act_type" != "local" -o "$CFG_back_type" != "schedule" ] && exit

    oIFS=$IFS
    IFS="/"
    aryOPT_folder=($OPT_folder)
    IFS=$oIFS

    COUNT_FILE="/tmp/rsync_backup_${CFG_task_name}.count"
    LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
    STATUS_FILE="/tmp/rsync_backup_${CFG_task_name}.status"
    ISO_FILE="/tmp/rsync_${CFG_task_name}_iso.log"
    ISO_TMP="/tmp/rsync_${CFG_task_name}_iso_tmp.log"
    ACL_FAG="/tmp/rsync_${CFG_task_name}_${gAction}.acl"

    ACL_FILE=".rsync_${CFG_task_name}_acl"
    SMB_FOLDER="/tmp/rsync_${CFG_task_name}_smb"
    TAR_SMB_FILE="/tmp/.rsync_${CFG_task_name}_smb.tar.gz"
    BIN_SMB_FILE="/tmp/.rsync_${CFG_task_name}_smb.bin"
    DESKEY="schedule"
fi

#######################################################
#
# get source folder path for uuid
#
#######################################################
get_src_folder_path(){
    local fFolder_raid
    local fFolder_path
    local fSrc_folder_path

    fFolder_raid=`Ldataguard_check_uuid "$OPT_src_uuid"`
    for folder in "${aryPath_list[@]}"
    do
        if [ `echo "$fFolder_raid" | grep -c "/data/stackable/"` -lt 1 ]; then
            fFolder_path="${fFolder_raid}/data${folder}"
        else
            fFolder_name=`echo "${folder}" | awk -F"/" '{print $2}'`
            fFolder_path="${fFolder_raid}/data"`echo "${folder#/${fFolder_name}}"`
        fi
        if [ ! -e "$fFolder_path" ]; then
            fLoss_folder="${fLoss_folder}"`basename "${fFolder_path}"`", "
        else
            fFolder_path=`echo "${fFolder_path}" | sed "s/'/\'\\\\\\''/g"`
            fSrc_folder_path="${fSrc_folder_path}'${fFolder_path}' "
        fi
    done
    echo "${fLoss_folder}//${fSrc_folder_path}"
}

#######################################################
#
# get target folder path for uuid
#
#######################################################
get_tge_folder_path(){
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
    if [ ! -e "$fFolder_path" ]; then
        fLoss_folder="${fLoss_folder}"`basename "${fFolder_path}"`", "
    else
        fFolder_path=`echo "${fFolder_path}" | sed "s/'/\'\\\\\\''/g"`
        fTge_folder_path="${fTge_folder_path}'${fFolder_path}'"
    fi
    echo "${fLoss_folder}//${fTge_folder_path}"
}

#######################################################
#
# check task name folder
#
#######################################################
check_create_sfolder(){
    local fFolder_path="$1"
    local fPath_list

    eval "fFolder_path=($fFolder_path)"
    for ((i=0;i<${#fFolder_path[@]};i++))
    do
        folder="${fFolder_path[$i]}/${CFG_task_name}"
        [ ! -d "${folder}" ] && mkdir "${folder}" && chown nobody.nogroup "${folder}"
        folder=`echo "${folder}" | sed "s/'/\'\\\\\\''/g"`
        fPath_list="${fPath_list}'${folder}' "
    done
    echo "$fPath_list" | sed 's/ $//g'
}

#######################################################
#
# start task and restore task
#
#######################################################
backup_task(){
    local fSource_path_list
    local arySource_folder
    local fTarget_path_list
    local fLoss_folder
    local fSource_folder
    local fTarget_folder
    local fTarget_smbdb
    local fTarget_folder_name
    local fGuest_only
    local fTarget_folder_root
    local fError="0"

    check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${gAction}"
    Ldataguard_check_status "$CFG_task_name" "$STATUS_FILE" "$gAction" "$CFG_act_type"
    Ldataguard_get_raid_status "$CFG_task_name" "$gAction" "$LOG_TMP" "$log_path"  "$CFG_act_type"
    Ldataguard_get_migrate_status "$CFG_task_name" "$gAction" "$LOG_TMP" "$log_path"  "$CFG_act_type"

    get_iso_info "$ISO_FILE"
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
    eval "aryPath_list=($path_list)"

    #########################################
    #      Source and Target path list      #
    #########################################
    if [ "$gAction" == "start" ]; then
        #####   source path   #####
        fSource_path_list=`get_src_folder_path`
        fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
        fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
        fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`

        if [ ! -z "$fLoss_folder" ]; then
            fError=$(($fError+1))
            eventlog "$CFG_task_name" "16" "$gAction" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
            [ -z "$fSource_folder" ] && Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" && exit
        fi

        #####   target path   #####
        if [ "$OPT_device_type" != "1" ]; then
            fTarget_path_list=`get_tge_folder_path`
        else
            fTarget_path_list=`Ldataguard_backup_target "$CFG_task_name" "$OPT_target" "$OPT_target_tag" "$OPT_device_type" "$gExternal_target_path"`
        fi
        fLoss_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $1}'`
        fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
        fTarget_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $2}'`

        if [ -z "$fTarget_folder" ]; then
            fError=$(($fError+1))
            eventlog "$CFG_task_name" "37" "$gAction" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
            Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
            exit
        fi

        [ "$OPT_create_sfolder" == "1" ] && fTarget_folder=`check_create_sfolder "$fTarget_folder"`
        eval "fTarget_folder=$fTarget_folder"
        fTarget_folder_tmp=`echo "$fTarget_folder" | sed 's/\`/\\\\\`/g'`
    elif [ "$gAction" == "restore" ]; then
        #####   source path   #####
        if [ "$OPT_device_type" != "1" ]; then
            fTarget_path_list=`get_tge_folder_path`
        else
            fTarget_path_list=`Ldataguard_backup_target "$CFG_task_name" "$OPT_target" "$OPT_target_tag" "$OPT_device_type" "$gExternal_target_path"`
        fi
        fLoss_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $1}'`
        fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
        fTarget_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $2}'`

        if [ -z "$fTarget_folder" ]; then
            fError=$(($fError+1))
            eventlog "$CFG_task_name" "16" "$gAction" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
            Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
            exit
        fi

        [ "$OPT_create_sfolder" == "1" ] && fTarget_folder=`check_create_sfolder "$fTarget_folder"`
        eval "fTarget_folder=${fTarget_folder}"

        for folder in "${aryPath_list[@]}"
        do
            if [ -z "${OPT_path}" -a `echo "$fTarget_folder" | grep -c "/data/stackable/"` -lt 1 ]; then
                src_folder="${fTarget_folder}${folder}"
            else
                fFolder_name=`echo "${folder}" | awk -F"/" '{print $2}'`
                if [ "$gAction" == "start" ]; then
                    src_folder="${fTarget_folder}"`echo "${folder#/${fFolder_name}}"`
                elif [ "$gAction" == "restore" ]; then
                    src_folder="${fTarget_folder}/"`basename "${folder}"`
                fi
            fi

            if [ ! -e "$src_folder" ]; then
                fLoss_folder="${fLoss_folder}"`basename "${src_folder}"`", "
            else
                src_folder=`echo "${src_folder}" | sed "s/'/\'\\\\\\''/g"`
                fSource_folder="${fSource_folder}'${src_folder}' "
            fi
        done

        fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
        if [ ! -z "$fLoss_folder" ]; then
            fError=$(($fError+1))
            eventlog "$CFG_task_name" "16" "$gAction" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
            [ -z "$fSource_folder" ] && Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" && exit
        fi

        #####   target path   #####
        fTarget_path_list=`get_src_folder_path`
        fLoss_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $1}'`
        fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
        fTarget_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $2}'`

        if [ -z "$fTarget_folder" ]; then
            fError=$(($fError+1))
            eventlog "$CFG_task_name" "37" "$gAction" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
            Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
            exit
        else
            eval "aryTarget_folder=($fTarget_folder)"
            fTarget_folder=`dirname "${aryTarget_folder[0]}"`
            fTarget_folder_tmp=`echo "$fTarget_folder" | sed 's/\`/\\\\\`/g'`
        fi
    fi

    if [ "$gAction" == "start" ]; then
        if [ "$OPT_device_type" == "0" ]; then
            fTarget_folder_name=`echo "$OPT_target" | awk -F"/" '{print $2}'`
            if [ `echo "$fTarget_folder" | grep -c "/data/stackable/"` -lt 1 ]; then
                fTarget_smbdb=`Ldataguard_get_folder_smbdb "$OPT_dest_uuid"`
                fGuest_only=`$Ldataguard_sqlite ${fTarget_smbdb} "select \"guest only\" from smb_specfd where share='$fTarget_folder_name';select \"guest only\" from smb_userfd where share='$fTarget_folder_name'"`
            else
                fTarget_smbdb="$STACK_DB"
                fGuest_only=`$Ldataguard_sqlite ${fTarget_smbdb} "select \"guest_only\" from stackable where share='$fTarget_folder_name'"`
            fi
            fTarget_folder_root=`Ldataguard_get_raid_root_path "$fTarget_folder_name"`
            if [ "$fGuest_only" == "yes" ]; then
                setfacl --remove-all -d -m user::rwx,group::rwx,other::rwx -P -R "$fTarget_folder_root"; chmod 777 -R "$fTarget_folder_root"
            fi
        fi
    elif [ "$gAction" == "restore" ]; then
        if [ `echo "$fTarget_folder" | grep -c "/data/stackable/"` -lt 1 ]; then
            fTarget_smbdb=`Ldataguard_get_folder_smbdb "$OPT_src_uuid"`
        else
            fTarget_smbdb="$STACK_DB"
        fi
    fi

    #########################################
    #                 rsync                 #
    #########################################
    RSYNC_PARA="-8rltDvH"
    if [ "$OPT_device_type" == "0" ]; then
        RSYNC_PARA="${RSYNC_PARA}X"
        if [ "$gAction" == "start" ] || [ "$gAction" == "restore" ];then
            if [ "$fGuest_only" == "yes" ]; then
                CHMOD_ACL="--chmod=ugo=rwX"
                [ "$OPT_acl" == "1" ] && RSYNC_PARA="${RSYNC_PARA}og"
            elif [ "$fGuest_only" == "no" ]; then
                [ "$OPT_acl" == "1" ] && RSYNC_PARA="${RSYNC_PARA}ogA"
            fi
        fi
    fi

    if [ "${OPT_sync_type}" == "sync" ]; then
        DEL="--delete"
    elif [ "${OPT_sync_type}" == "incremental" ]; then
        DEL=""
    fi
    
    strexec="$rsync $RSYNC_PARA $CHMOD_ACL $DEL --log-file=\"$LOG_TMP\" --progress --timeout=600 --exclude-from=\"$ISO_TMP\" ${fSource_folder} \"${fTarget_folder_tmp}/\" > $COUNT_FILE"
    eval "$strexec"
    ret=`echo $?`
    if [ "$ret" != "137" ]; then
        [ "$ret" != "" -a "$ret" != "0" ] && fError=$(($fError+1)) && eventlog "$CFG_task_name" "$ret" "$gAction" "$LOG_TMP" "" "$CFG_act_type"
    else
        fError=$(($fError+1))
        eventlog "$CFG_task_name" "37" "$gAction" "$LOG_TMP" "" "$CFG_act_type"
    fi
    
    [ "$fError" -lt 1 ] && eventlog "$CFG_task_name" "0" "$gAction" "$LOG_TMP" "" "$CFG_act_type"
    
    touch "$ACL_FAG"
    if [ "$gAction" == "start" ]; then
        backup_status=400
    elif [ "$gAction" == "restore" ]; then
        backup_status=401
    fi
    for ((i=0;i<10;i++))
    do
        $Ldataguard_sqlite $Ldataguard_backupdb "update task set status='$backup_status' where task_name='$CFG_task_name'"
        [ `echo $?` == "0" ] && break
        sleep 1
    done
    
    eval "arySource_folder=($fSource_folder)"
    if [ "$gAction" == "start" ]; then
        if [ "${OPT_sync_type}" == "sync" ] && [ -f "${fTarget_folder}/${ACL_FILE}" ]; then
            rm -rf "${fTarget_folder}/${ACL_FILE}"
        fi
        if [ "$OPT_device_type" != "1" ]; then
            owner="nobody.users"
        else
            owner="nobody.nogroup"
        fi
        
        #####   get acl   #####
        for folder_name in "${arySource_folder[@]}"
        do
            getfacl -Rn "$folder_name" 2> /dev/null >> "${fTarget_folder}/${ACL_FILE}"

            if [ "$OPT_acl" != "1" ];then
                chown -R "$owner" "${fTarget_folder}/`basename \"${folder_name}\"`"
            fi
        done
        sed -i 's/file: raid/file: \/raid/g' "${fTarget_folder}/${ACL_FILE}"
        chown -R "$owner" "${fTarget_folder}/${ACL_FILE}"
        
        #####   tar zcvf /tmp/.rsync_${CFG_task_name}_smb.bin   #####
        [ ! -d "$SMB_FOLDER" ] && mkdir "$SMB_FOLDER"
        if [ `echo "$fSource_folder" | grep -c "/data/stackable/"` -lt 1 ]; then
            fSource_smbdb=`Ldataguard_get_folder_smbdb "$OPT_src_uuid"`
            raidid=`echo "$fSource_smbdb" | awk -F"/" '{print $2}'`
            cp "$fSource_smbdb" "${SMB_FOLDER}/${raidid}_smb.db"
        else
            cp "$STACK_DB" "${SMB_FOLDER}/"
        fi
        cd "$SMB_FOLDER"
        tar zcvf "$TAR_SMB_FILE" *
        /usr/bin/des -E -k "$DESKEY" "$TAR_SMB_FILE" "$BIN_SMB_FILE"
        cp "$BIN_SMB_FILE" "${fTarget_folder}/"
        chown -R "$owner" "${fTarget_folder}/"`basename "${BIN_SMB_FILE}"`
        cd "$PWD_PATH"
    elif [ "$gAction" == "restore" ]; then
        #####   tar zxvf /tmp/.rsync_${CFG_task_name}_smb.bin   #####
        cp "`echo "${arySource_folder[0]%${aryOPT_folder[0]}}"`"`basename "$BIN_SMB_FILE"` "$BIN_SMB_FILE"
        /usr/bin/des -D -k "$DESKEY" "$BIN_SMB_FILE" "$TAR_SMB_FILE"
        [ ! -d "$SMB_FOLDER" ] && mkdir "$SMB_FOLDER"
        tar zxvf "$TAR_SMB_FILE" -C "$SMB_FOLDER"
    
        #####   set smb.db   #####
        smb_db=`ls -l ${SMB_FOLDER}/raid[0-9]*_smb.db | awk '{print $9}'`
        [ -z "$smb_db" ] && smb_db="${SMB_FOLDER}/stackable.db"
        for folder_name in "${arySource_folder[@]}"
        do
            setfacl -R -P -b "${fTarget_folder}/`basename \"${folder_name}\"`"  #remove acl
        done
        setfacl --restore="`echo "${arySource_folder[0]%${aryOPT_folder[0]}}"`${ACL_FILE}"      # set acl
        
        for folder_name in "${arySource_folder[@]}"
        do
            if [ `echo "$fTarget_folder" | grep -c "/data/stackable/"` -lt 1 ]; then
                if [ "$OPT_path" == "" ]; then
                    smb_db=`ls -l ${SMB_FOLDER}/raid[0-9]*_smb.db | awk '{print $9}'`
                    fTarget_folder_name=`echo "${folder_name}" | awk -F"/" '{print $NF}'`
                    fGuest_only=`$Ldataguard_sqlite "$smb_db" "select \"guest only\" from smb_specfd where share='$fTarget_folder_name';"`
                    if [ ! -z "$fGuest_only" ]; then
                        sql_cmd="${sql_cmd}update smb_specfd set \"guest only\"='$fGuest_only' where share='$fTarget_folder_name';"
                    else
                        fGuest_only=`$Ldataguard_sqlite "$smb_db" "select \"guest only\" from smb_userfd where share='$fTarget_folder_name';"`
                        sql_cmd="${sql_cmd}update smb_userfd set \"guest only\"='$fGuest_only' where share='$fTarget_folder_name';"
                    fi
                else
                    smb_db="$fTarget_smbdb"
                    fTarget_folder_name=`echo "${OPT_path}" | awk -F"/" '{print $2}'`
                    fGuest_only=`$Ldataguard_sqlite "$smb_db" "select \"guest only\" from smb_specfd where share='$fTarget_folder_name';"`
                    if [ -z "$fGuest_only" ]; then
                        fGuest_only=`$Ldataguard_sqlite "$smb_db" "select \"guest only\" from smb_userfd where share='$fTarget_folder_name';"`
                    fi
                fi
            else
                smb_db="$fTarget_smbdb"
                fTarget_folder_name=`echo "${OPT_path}" | awk -F"/" '{print $2}'`
                fGuest_only=`$Ldataguard_sqlite ${smb_db} "select \"guest_only\" from stackable where share='$fTarget_folder_name'"`
            fi
            
            if [ "$OPT_acl" != "1" ];then
                chown -R nobody.users "${fTarget_folder}/`basename \"${folder_name}\"`"
            fi
            if [ "$fGuest_only" == "yes" ]; then
                setfacl --remove-all -d -m user::rwx,group::rwx,other::rwx -P -R "${fTarget_folder}/`basename \"${folder_name}\"`"
                chmod -R 777 "${fTarget_folder}/`basename \"${folder_name}\"`"
            else
                fTarget_folder_root=`Ldataguard_get_raid_root_path "$fTarget_folder_name"`
                fmask=`stat "${fTarget_folder_root}" | sed -nr 's/Access: \([0-9]([0-9]*)\/.*\)/\1/p'`
                chmod -R "$fmask" "${fTarget_folder}/`basename \"${folder_name}\"`"
            fi
        done
        [ ! -z "$sql_cmd" ] && echo "BEGIN TRANSACTION;${sql_cmd}COMMIT;" | $Ldataguard_sqlite "$fTarget_smbdb"
    
        /img/bin/rc/rc.samba restart                                            # restart samba
    fi
    rm -rf "$SMB_FOLDER" "$TAR_SMB_FILE" "$BIN_SMB_FILE"
    rm -rf "/tmp/mdadm_list"

    Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path" "$gAction"
}

#######################################################
#
# create target tag and set crontab
#
#######################################################
create_task(){
    local fFolder_name
    local fFolder_path
    local fTask_folder

    if [ "$OPT_device_type" != "1" ]; then                                      #target folder is raid
        fFolder_name=`echo "$OPT_target" | awk -F"/" '{print $2}'`
        fFolder_rootpath=`Ldataguard_get_raid_root_path "$fFolder_name"`
        fFolder_path="${fFolder_rootpath}"`echo "${OPT_target#/${fFolder_name}}"`
    else                                                                        #target folder is external
        if [ "$OPT_target" == "" ]; then
            fFolder_path="${gExternal_target_path}"
        else
            fFolder_path="${gExternal_target_path}${OPT_target}"
        fi
    fi

    if [ "$OPT_create_sfolder" == "1" ]; then
        fTask_folder="${fFolder_path}/${CFG_task_name}"
        [ ! -d "$fTask_folder" ] && mkdir "${fTask_folder}" && chown nobody.users "${fTask_folder}"
    else
        fTask_folder="${fFolder_path}"
    fi

    [ "$OPT_device_type" == "1" ] && touch "${fFolder_path}/${OPT_target_tag}"

    backup_time=`echo $OPT_backup_time | sed 's/,/ /g'`
    if [ "$OPT_schedule_enable" == "1" ]; then
        Ldataguard_crond_control "$CFG_tid" "$PROCESS_NAME" "add" "start" "$backup_time"
    else
        Ldataguard_crond_control "$CFG_tid" "$PROCESS_NAME" "remove" "start" "$backup_time"
    fi
}

#######################################################
#
# stop task and all stop task
#
#######################################################
stop_task(){
    if [ -z "$gTid" ]; then
        task_id_list=(`"$Ldataguard_sqlite" "$Ldataguard_backupdb" "select tid from task where back_type='schedule' and act_type='local'"`)
        for task_id in ${task_id_list[@]}
        do
            eval `db_to_env $task_id`
            LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
            SMB_FOLDER="/tmp/rsync_${CFG_task_name}_smb"
            TAR_SMB_FILE="/tmp/.rsync_${CFG_task_name}_smb.tar.gz"
            BIN_SMB_FILE="/tmp/.rsync_${CFG_task_name}_smb.bin"
            Ldataguard_stop_task "$CFG_tid" "$CFG_task_name" "$PROCESS_NAME" "$LOG_TMP" "$OPT_log_folder" "$CFG_act_type"
            rm -rf "$SMB_FOLDER" "$TAR_SMB_FILE" "$BIN_SMB_FILE"
        done
    else
        Ldataguard_stop_task "$CFG_tid" "$CFG_task_name" "$PROCESS_NAME" "$LOG_TMP" "$OPT_log_folder" "$CFG_act_type"
        rm -rf "$SMB_FOLDER" "$TAR_SMB_FILE" "$BIN_SMB_FILE"
    fi
    rm -rf "/tmp/mdadm_list"
}

#######################################################
#
# remove crontab
#
#######################################################
remove_task(){
    Ldataguard_crond_control "$CFG_tid" "$PROCESS_NAME" "remove" "start" "$OPT_backup_time"
}

case "$gAction"
in
    create|modify)
        create_task
        ;;
    start|restore)
        backup_task
        ;;
    stop|allstop)
        stop_task
        ;;
    remove)
        remove_task
        ;;
    *)
        echo "Usage: $0 { create | start | restore | stop | allstop | remove }"
        ;;
esac
