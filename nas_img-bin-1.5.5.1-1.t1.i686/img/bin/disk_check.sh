#!/bin/sh

#==================================================
#        FILE:  rc.webdav
#       USAGE:  start|stop|restart|reload|boot
# DESCRIPTION:
#       NOTES:  none
#      AUTHOR:
#     VERSION:  1.0.0
#     CREATED:
#    REVISION:
#==================================================

#==================================================
#  Variable Defined
#==================================================
TRAY_COUNT=""                     ## This NAS MAX tray number
DISK_NO_LIST=""                   ## All disk tray no list
DISK_MAPPING=""                   ## Array of map tray no to device name
SAVE_SMART=""                     ## All SMART info on this time
TIME_STAMP=""                     ## For record log name use
SMARTCTL="/usr/sbin/smartctl"     ## For OS5(64),OS6
FLAG_FILE="/etc/disk_ckeck_flag"  ## Record latest check week number of year and disk info before
LOG_FOLDER="/syslog/disk_check"   ## Record all SMART info to log each week
LOG_NAME=""
INTERVAL_9="5000"                    ## Power on hours interval basic
LIMIT_184="0"                     ## ID 184 check basic

#==================================================
#  Function Defined
#==================================================

#################################################
#         NAME:  
#  DESCRIPTION:  
#      PARAM 1:  None
#       RETURN:  None
#################################################
init_env(){

    ## This model's MAX tray number
    TRAY_COUNT=`awk '/^MAX_TRAY/{print $2}' /proc/thecus_io`

    ## Current disks tray no list
    DISK_NO_LIST=`cat /proc/scsi/scsi | \
               awk  '/Thecus:/{FS=" ";printf("%s\n",$2)}' | \
               awk -F: '{if (($2<='${TRAY_COUNT}')&&($2>0)) {printf("%s ",$2)}}'`

    ## Mapping disk name to tray no by use array
    for diskno in ${DISK_NO_LIST}
    do
        DISK_MAPPING["${diskno}"]=`cat /proc/scsi/scsi |\
                                 awk '/ Tray:'${diskno}' /{print $3}' |
                                 awk -F: '{print $2}'`
    done

    ## Fetch current time
    TIME_STAMP=`date +%Y%m%d_%H%M%S`

    ## Initial log folder and file name
    [ ! -d "${LOG_FOLDER}" ] && mkdir -p "${LOG_FOLDER}"
    LOG_NAME="${LOG_FOLDER}/check_disk.${TIME_STAMP}"
}

#################################################
#         NAME:
#  DESCRIPTION:
#      PARAM 1:  None
#       RETURN:  None
#################################################
smart_log(){
    local disk_no="$2"
    local logevent="/img/bin/logevent/event"

    ## Get the & SN info of this disk
    local disk_name="${DISK_MAPPING[$disk_no]}"
    local model_family=`$SMARTCTL -i "/dev/${disk_name}" | grep -i "Model Family:" | awk -F':' '{print $2}' | sed 's/^[ ]*//g'`
    local serial_number=`$SMARTCTL -i "/dev/${disk_name}" | grep -i "Serial Number:" | awk -F':' '{print $2}' | sed 's/^[ ]*//g'`

    ## Combine
    local add_info=""
    [ ! -z "${model_family}" ] && [ ! -z "${serial_number}" ] && add_info="(${model_family},${serial_number})"
    [ ! -z "${model_family}" ] && [ -z "${serial_number}" ] && add_info="(${model_family})"
    [ -z "${model_family}" ] && [ ! -z "${serial_number}" ] && add_info="(${serial_number})"

    case "$1"
    in
        5)
            local before_value="$3"
            local current_value="$4"
            $logevent 997 493 "info" "email" "Reallocated_Sector_Ct" "${current_value}" "${disk_no}" "${before_value}" "${add_info}"
        ;;
        9)
            local current_value="$3"
            $logevent 997 494 "info" "email" "Power_On_Hours" "${disk_no}" "${current_value}" "${add_info}"
        ;;
        184)
            local current_value="$3"
            $logevent 997 539 "warning" "email" "End-to-End_Error" "${disk_no}" "${current_value}" "${add_info}"
        ;;
        197)
            local before_value="$3"
            local current_value="$4"
            $logevent 997 493 "info" "email" "Current_Pending_Sector" "${current_value}" "${disk_no}" "${before_value}" "${add_info}"
        ;;
        FN)
            $logevent 997 540 "warning" "email" "${disk_no}" "${add_info}"
        ;;
        *)
            echo "Error parameter of logevent"
            return 1
        ;;
    esac
}

#################################################
#         NAME:
#  DESCRIPTION:
#      PARAM 1:  None
#       RETURN:  None
#################################################
smart_check(){
    local smart_info=""
    local disk_no=$1
    local disk_name="${DISK_MAPPING[$disk_no]}"

    ## Fetch this disk SMART, and exit if can't get any info
    smart_info=`$SMARTCTL -A "/dev/${disk_name}" | awk '{printf("%s\\\n"),$0}'`
    [ -z "${smart_info}" ] && echo "Can't fetch tray no.$1 disk's SAMRT info" && return 1

    ## Initial parameters
    local Current_5=""
    local Current_9=""
    local Current_184=""
    local Current_197=""
    local Before_5=""
    local Before_9_Basic=""
    local Before_197=""

    ## Get current disk SMART info
    Current_5=`echo -e ${smart_info} | awk '/^\s*5 /{print $NF}'`
    Current_9=`echo -e ${smart_info} | awk '/^\s*9 /{print $NF}'`
    Current_184=`echo -e ${smart_info} | awk '/^\s*184 /{print $NF}'`
    Current_197=`echo -e ${smart_info} | awk '/^\s*197 /{print $NF}'`
    [ -z "${Current_5}" ] && Current_5="NONE"
    [ -z "${Current_9}" ] && Current_9="NONE"
    [ -z "${Current_184}" ] && Current_184="NONE"
    [ -z "${Current_197}" ] && Current_197="NONE"

    ## Get disk SMART info before
    if [ -f ${FLAG_FILE} ];then
        local before_smart=`cat ${FLAG_FILE} | awk 'NR>1 && /^'${disk_no}' /{print $0}'`
        Before_5=`echo ${before_smart} | awk '{print $2}'`
        Before_9_Basic=`echo ${before_smart} | awk '{print $3}'`
        Before_197=`echo ${before_smart} | awk '{print $4}'`
    fi
    [ -z "${Before_5}" ] && Before_5="NONE"
    [ -z "${Before_9_Basic}" ] && Before_9_Basic="NONE"
    [ -z "${Before_197}" ] && Before_197="NONE"

    ## Don't send log at 1st execute (5,197)
    if [ -f ${FLAG_FILE} ];then
        [ "${Current_5}" != "${Before_5}" ] && smart_log "5" "${disk_no}" "${Before_5}" "${Current_5}"
        [ "${Current_197}" != "${Before_197}" ] && smart_log "197" "${disk_no}" "${Before_197}" "${Current_197}"
    fi

    ## Check ID 9
    if [ "${Current_9}" != "NONE" ] && [ "${Before_9_Basic}" != "NONE" ];then
        if [ "$[ Current_9 - Before_9_Basic ]" -gt "${INTERVAL_9}" ];then
            smart_log "9" "${disk_no}" "${Current_9}"
        fi
    fi

    ## Check ID 184
    [ "${Current_184}" != "NONE" ] && \
    [ "${Current_184}" -gt "${LIMIT_184}" ] && smart_log "184" "${disk_no}" "${Current_184}" 

    ## Check "TYPE = Pre-failed" & "WHEN_FAILED = FAILING_NOW" status
    local failing_now=`echo -e ${smart_info} | grep -i "Pre-failed" | grep -i "FAILING_NOW"`
    [ ! -z "${failing_now}" ] && smart_log "FN" "${disk_no}"

    ## Record info to flag file
    local save_Current_9=""
    if [ "${Current_9}" == "NONE" ];then
        save_Current_9="${Current_9}"
    else
        ## Only record the interval limit for judge, ex: 5000,10000
        save_Current_9="$[ (Current_9 / INTERVAL_9 ) * INTERVAL_9 ]"
    fi

    ## Record to flag file
    SAVE_SMART="${SAVE_SMART}${disk_no} ${Current_5} ${save_Current_9} ${Current_197}\n"

    ## Record to syslog log file
    echo "===== /dev/${disk_name} =====" >> ${LOG_NAME}
    $SMARTCTL -iA "/dev/${disk_name}" >> ${LOG_NAME}
}

#################################################
#         NAME:
#  DESCRIPTION:
#      PARAM 1:  None
#       RETURN:  None
#################################################
check(){

    ## Don't check disk if don't have any disks
    [ -z "${DISK_NO_LIST}" ] && echo "Can't find any disk device to check" && exit 1

    local latest_week=""
    [ -f "${FLAG_FILE}" ] && latest_week=`cat ${FLAG_FILE} | awk 'NR==1{print $1}'`
    local cur_week=`date +%U`

    ## Check when : 1. Didn't execute disk check before
    ## 2. Current week number of year is differ with latest check week number
    if [ ! -f "${FLAG_FILE}" ] || [ "${cur_week}" != "${latest_week}" ] ;then
        for diskno in ${DISK_NO_LIST}
        do
            smart_check ${diskno}
        done

        ## Check the numbers of log files is greater than 50, and remove oldest 5
        if [ `ls ${LOG_FOLDER} | wc -l` -gt 50 ];then
            ls ${LOG_FOLDER} | head -n5 | awk '{printf("'${LOG_FOLDER}'/%s "),$0}' | xargs rm -f
        fi

        ## Record current week number of year to flag if disk check finish
        echo "Check all disks SMART finish"
        echo "${cur_week}" > ${FLAG_FILE}
        echo -e "${SAVE_SMART}" >> ${FLAG_FILE}
        exit 0
    else
        echo "This week had been checked"
        exit 0
    fi
}

#################################################
#         NAME:
#  DESCRIPTION:
#      PARAM 1:  None
#       RETURN:  None
#################################################
add_crond(){
    local crond_conf="/etc/cfg/crond.conf"
    local on_crond=`cat ${crond_conf} | grep $0`

    if [ -z "${on_crond}" ];then
        echo "0 0 * * * $0 check > /dev/null 2>&1" >> ${crond_conf}
        /usr/bin/crontab $crond_conf -u root
    fi
}

#################################################
#         NAME:
#  DESCRIPTION:
#      PARAM 1:  None
#       RETURN:  None
#################################################
main(){
    case "$1"
    in
        boot)
            add_crond
            check &
            ;;
        check)
            check
            ;;
        *)
            echo "Usage: $0 { boot | check }"
            exit 1
            ;;
    esac
}

#==================================================
#  Main Code
#==================================================
init_env
main $1

