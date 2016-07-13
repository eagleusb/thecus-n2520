#!/bin/sh

SYS_TMP_PATH=/raid/data/_SYS_TMP
RAID_DATA_PATH=$SYS_TMP_PATH/dual_dom
SAVE_TMP_PATH=$RAID_DATA_PATH/save_tmp
SAVE_PATH=$RAID_DATA_PATH/save
TALKTOLCM="/img/bin/pic.sh"
macaddr=`/img/bin/function/get_interface_info.sh get_mac eth0 | awk -F: '{printf("%s%s%s%s%s%s",$1,$2,$3,$4,$5,$6)}'`
BACKUP_PREFIX="backup_${macaddr}_"
FILE_COUNT=`ls $SAVE_PATH/$BACKUP_PREFIX* | wc -l | awk '{print($1)}'`
DOM_B_DD_FLAG=/etc/DOMB_DD_FLAG
BOOTDEV=""
CHECKSUM_CMD="/usr/bin/md5sum"
CHECKSUM_FLAG=0
REPAIR_FLAG=0
DOMB_TO_DOMA=0
TYPENAME=`grep type /etc/manifest.txt | cut -f 2`
LOOP_DEVICE=`/sbin/losetup -f`

partition_count=4
####Dom B Upgrade partition (1,2,3,4)
DOMB="sdaab"
DOMB_DEV="/dev/${DOMB}"
DOMB_DIR_BASE=/tmp/domb_dir_base
DOMB_DIR_PART1=$DOMB_DIR_BASE/part1
DOMB_DIR_PART2=$DOMB_DIR_BASE/part2
DOMB_DIR_PART3=$DOMB_DIR_BASE/part3
DOMB_DIR_PART6=$DOMB_DIR_BASE/part4
if [ ! -d "${DOMB_DIR_BASE}" ];
then
    mkdir -p "${DOMB_DIR_BASE}"
fi

####Dom A Upgrade partition (1,2,3,4)
DOMA="sdaaa"
DOMA_DEV="/dev/${DOMA}"
DOMA_DIR_BASE=/tmp/doma_dir_base
DOMA_DIR_PART1=$DOMA_DIR_BASE/part1
DOMA_DIR_PART2=$DOMA_DIR_BASE/part2
DOMA_DIR_PART3=$DOMA_DIR_BASE/part3
DOMA_DIR_PART5=$DOMA_DIR_BASE/part4
if [ ! -d "${DOMA_DIR_BASE}" ];
then
    mkdir -p "${DOMA_DIR_BASE}"
fi

DOM_A_EXIST_STR=`/bin/grep ${DOMA} /proc/partitions`
DOM_B_EXIST_STR=`/bin/grep ${DOMB} /proc/partitions`
DOM_B_BOOT_STR=`/bin/grep domb /proc/cmdline`

if [ "${DOM_B_BOOT_STR}" == "" ];then
  BOOTDEV=${DOMA}
else
  BOOTDEV=${DOMB}
fi

CHECKSUM_DIR="/tmp/checksum_dir"
if [ ! -d "${CHECKSUM_DIR}" ];
then
    mkdir "${CHECKSUM_DIR}"
fi

DATE=`date "+%Y%m%d_%H%M"`
#DATE=`date "+%Y%m%d"`
raid_folder="NAS_Public"
dom_repair_log_path="/tmp/dom_repair_log"
if [ ! -e "${dom_repair_log_path}" ];
then
    mkdir "${dom_repair_log_path}"
fi

###############################################################
##    Function
###############################################################
function log_event(){
    msg=$1
    error_code=$2
    if [ "`/img/bin/check_service.sh atmega168`" == "1" ];then
      ${TALKTOLCM} LCM_MSG "" "${msg}"
     else
      ${TALKTOLCM} LCM_MSG "${TYPENAME}" "${msg}"
    fi
    if [ "${error_code}" != "1" ];
    then
        echo "Buzzer 1" > /proc/thecus_io
        sleep 2
        echo "Buzzer 0" > /proc/thecus_io
    fi
    sleep 3
    echo "usb log = ${usb_log}"
    if [ "${usb_log}" == "1" ];
    then
        /bin/umount -l -f "${dom_repair_log_path}"
    fi
    exit ${error_code}
}

function savelog(){
    msg=$1
    time_stamp=`date +'%Y/%m/%d %H:%M:%S'`
    echo "${time_stamp} ${hostname} : [DOM Restore] ${msg}" >> ${log_file}
}

function checkusb(){
    usb_log="0"
    #${TALKTOLCM} LCM_MSG "${TYPENAME}" "Check usb"
    strExec="cat /proc/scsi/scsi | grep \"Intf:USB\" | awk  '/Thecus:/{FS=\" \";printf(\"%s:%s\n\",\$2,\$3)}' | awk -F: '{printf(\"%s\n\",\$4)}'"
    normal=`eval ${strExec}`
    for i in $normal ;
    do
        strExec="cat /proc/partitions|awk '/${i}[0-9]/||/${i}$/{FS=\" \";print \$4}'"
        mount_usbs=`eval ${strExec}`
        for mount_usb in $mount_usbs ;
        do
            #create folder
            strexec="mount|awk '/\/dev\/${mount_usb}/&&/\/tmp/'"
            chkmount=`eval ${strexec}`
            if [ "${chkmount}" == "" ];
            then
                mount "/dev/${mount_usb}" "${dom_repair_log_path}"
                if [ $? = 0 ];
                then
                    usb_log="1"
                    break
                fi
            else
                usb_log="1"
                break
            fi
        done
        if [ "${usb_log}" == "1" ];
        then
            sync
            echo "${dom_repair_log_path}"
            break
        fi
    done
}

function checkraid(){
    raidlog="0"                                                                               
    strExec="/bin/ls -l /raid | awk -F' ' '{printf \$11}' | awk -F'/' '{printf \$2}'"
    data_path=`eval ${strExec}`
    if [ "${data_path}" != "" ];
    then
        raidlog="1"
    else                                        
        raidlog="0"
    fi             
    if [ "${raidlog}" == "1" ];
    then                                                                               
        strExec="/bin/mount | grep ${data_path}"
        mount_data=`eval ${strExec}`
        if [ "${mount_data}" == "" ];
        then
            raidlog="0"
        else
            raidlog="1"
            if [ ! -e "/${data_path}/data/${raid_folder}/do_repair_log" ];
            then
                mkdir -p "/${data_path}/data/${raid_folder}/dom_repair_log"
            fi
            echo "/${data_path}/data/${raid_folder}/dom_repair_log"
        fi
    fi                                                                                                                          
}

mount_ro() {
  bootdevice=$1
  mount -o remount,ro,noatime -t ext2 ${bootdevice}2 /etc
  mount -o remount,ro,noatime -t ext2 ${bootdevice}4 /syslog
}

mount_rw() {
  bootdevice=$1
  mount -o remount,rw,noatime -t ext2 ${bootdevice}2 /etc
  mount -o remount,rw,noatime -t ext2 ${bootdevice}4 /syslog
}

domb_repair_to_doma() {
    #create_dom_to_dom_dir
    #mount_dom_to_dom_dir
    #dom_to_dom_copy
    #umount_dom_to_dom_dir
    echo "Buzzer 1" > /proc/thecus_io
    
    if [ "${BOOTDEV}" == "sdaaa" ];then
      mount /dev/sdaab2 /mnt
      touch /mnt/ResetDefault
      sync
      umount /dev/sdaab2
    fi

    mount_ro "/dev/${BOOTDEV}"
    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "DOM Fail"
    sleep 2
    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair Start"

    dd if=/dev/sdaab of=/dev/sdaaa bs=512 count=1967553
    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair 33%"
    sync
    
    dd if=/dev/sdaaa bs=512 count=1967553 | md5sum > /tmp/sdaaa.md5
    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair 66%"

    dd if=/dev/sdaab bs=512 count=1967553 | md5sum > /tmp/sdaab.md5
    result=`diff /tmp/sdaaa.md5 /tmp/sdaab.md5`

    if [ "${result}" != "" ];then
      dd if=/dev/sdaab of=/dev/sdaaa bs=512 count=1967553
    fi
    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair 100%"

    sync

    mount_rw "/dev/${BOOTDEV}"

    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair Finish!"
    echo "Buzzer 0" > /proc/thecus_io
    sleep 2
}

repair_disk_dump() {
    backup_file=$1
    target_dev=$2
    repair_file_count=$3
    savelog "[${repair_file_count}] Image file repair to ${target_dev}"

    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair DOM"
    sleep 2

#    if [ -e /tmp/dd_stat ];then
#        rm /tmp/dd_stat
#    fi

    echo "Buzzer 1" > /proc/thecus_io
    mount_ro "/dev/${BOOTDEV}"
    dd if=${backup_file} of=${target_dev} bs=512 count=1967553
#    until [ -e /tmp/dd_stat ]
#    do
#        sleep 1
#    done

#    CURR_STAT=`cat /tmp/dd_stat`
#    until [ $CURR_STAT = "100%" ]
#    do
        #update_lcm_pogress $CURR_STAT
#        ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair [$3] $CURR_STAT"
#        /img/bin/buzzer.sh 1
#        sleep 5
#        CURR_STAT=`cat /tmp/dd_stat`
#    done

#    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair [$3] 100%"

    echo "Buzzer 0" > /proc/thecus_io
    sync
    mount_rw "/dev/${BOOTDEV}"
    ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Repair Finish!"
    sleep 2
}

function mount_device(){
    bootdevice=$1
    n=$2
    if [ ! -d "${CHECKSUM_DIR}/part${n}" ];
    then
        mkdir -p "${CHECKSUM_DIR}/part${n}"
    fi
    
    if [ "${n}" == "3" ];then
      /sbin/losetup -n -e AES128 ${LOOP_DEVICE} /dev/"${bootdevice}${n}"
      mount -o noatime ${LOOP_DEVICE} "${CHECKSUM_DIR}/part${n}"
    else
      mount -o noatime /dev/"${bootdevice}${n}" "${CHECKSUM_DIR}/part${n}"
    fi
    
    if [ $? != 0 ];
    then
        ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Chksum Fail M${n}"
        sleep 3
    fi
}

function umount_device(){
    bootdevice=$1
    n=$2
    umount "${CHECKSUM_DIR}/part${n}"
    if [ $? != 0 ];
    then
        ps_list=`fuser -m "${CHECKSUM_DIR}/part${n}"`
        for pno in ${ps_list}
        do
            kill -9 ${pno}
        done
        sleep 3
        umount "${CHECKSUM_DIR}/part${n}"
        if [ $? != 0 ];
        then
            ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Chksum Fail UM${n}"
            sleep 3
        fi
        sleep 3
    fi
    
    if [ "${n}" == "3" ];then
      /sbin/losetup -d ${LOOP_DEVICE}
    fi
}

function checksum_rom(){
    bootdevice=$1
    rom_count=3
    check_count=0
    rom_item[0]="${CHECKSUM_DIR}/part3/opt.rom"
    rom_item[1]="${CHECKSUM_DIR}/part3/usrlib64.rom"
    rom_item[2]="${CHECKSUM_DIR}/part3/zoneinfo.rom"

    mount_device "${bootdevice}" 3

    for((i=0;i<${rom_count};i=i+1))
    do
        now_checksum=`${CHECKSUM_CMD} "${rom_item[$i]}" | awk '{print $1}'`
        old_checksum=`cat "${rom_item[$i]}.sum" | awk '{print $1}'`
        if [ "${now_checksum}" != "${old_checksum}" ];
        then
            echo "Boot device checksum fail"
            if [ "${bootdevice}" == "${DOMA}" ];
            then
                CHECKSUM_FLAG=1
            else
                CHECKSUM_FLAG=2
                ${TALKTOLCM} LCM_MSG "${TYPENAME}" "Chksum Fail"
                sleep 3
            fi
            break
        fi
        echo "${now_checksum} = ${old_checksum}__"
    done
    umount_device "${bootdevice}" 3
    echo "${i}, ${bootdevice}, ${rom_item[i]}"
}

###############################################################
##    Main code
###############################################################
###############################################################
#   Check log site
###############################################################
log_in_memory="0"
log_path=`checkusb`
if [ "${log_path}" == "" ];
then
    usb_log=0
    log_path=`checkraid`
    if [ "${log_path}" == "" ];
    then
        log_in_memory="1"
        log_path="${dom_repair_log_path}"
    fi
else
    usb_log=1
fi
log_file="${log_path}/${DATE}_dom_repair_log"
if [ ! -e "${log_file}" ];
then
    touch ${log_file}
fi

#savelog "Log file = ${log_file}"
savelog "Start repair mode"
###############################################################
checksum_rom "${BOOTDEV}"
echo "checksum flag = ${CHECKSUM_FLAG}"

if [ ${CHECKSUM_FLAG} == 0 ];
then
    if [ "${BOOTDEV}" == "${DOMA}" ];
    then
        echo "Boot from DOM A";
        savelog "Boot from DOM A"
        log_event "DOM A boot" 1
        exit 1
    else
        echo "Repair Mode, repair DOM A"
        DOMB_TO_DOMA=1
        REPAIR_FLAG=1
    fi
else
    if [ "${BOOTDEV}" == "${DOMA}" ];
    then
        echo "Repair Mode, repair DOM A"
        DOMB_TO_DOMA=0
        REPAIR_FLAG=1
        #savelog "Backup config file"
    else
        echo "Boot DOM checksum fail and DOM A fail"
        savelog "Boot DOM checksum fail and DOM A fail"
        log_event "DOM B Fail" 100        
    fi
fi
echo "Repair flag = ${REPAIR_FLAG}"

if [ "`gdisk -l /dev/md0 | grep -c 'FD00  Linux RAID'`" == "3" ];then
  ln -fs /img/bin/ha /etc/ha
  /img/bin/ha/script/initiator.sh start
  ifconfig eth2 192.168.3.200
  ip1=`ifconfig eth0 | awk '/inet addr:/{gsub(/addr:/,"");print $2}'`
  ip3=`ifconfig eth2 | awk '/inet addr:/{gsub(/addr:/,"");print $2}'`
  /img/bin/ha/script/iscsi_export.sh $ip1 eth2 add
  /img/bin/ha/script/iscsi_block.sh eth2 $ip3 list p
  /img/bin/ha/script/iscsi_block.sh eth2 $ip3 start p
  sleep 3
  dev=`/img/bin/ha/script/iscsi_dev_map.sh eth2 $ip3 dev`
  mdadm -A /dev/md1 -R /dev/${dev}2
  if [ -e "/raid0" ];then 
    mkdir /raid0
  fi

  mount /dev/md1 /raid0
  FILE_COUNT=`ls $SAVE_PATH/$BACKUP_PREFIX* | wc -l | awk '{print($1)}'`
fi
                  
###############################################################
##    Check RAID exist
###############################################################
if [ ! -e /raid/data ] && [ ${DOMB_TO_DOMA} == 1 ];then
    if [ ! -e $DOM_B_DD_FLAG ];
    then
        savelog "Copy DOM B to DOM A"
        touch $DOM_B_DD_FLAG
        domb_repair_to_doma
        exit 0
    else
        echo "DOM A Fail"
        savelog "DOM A Fail"
        log_event "DOM A Fail" 1
    fi
fi

###############################################################
##    Check repair count
###############################################################
if [ ! -d $SAVE_TMP_PATH ]; then
    mkdir -p $SAVE_TMP_PATH
fi

if [ ! -d $SAVE_PATH ]; then
    mkdir -p $SAVE_PATH
fi

if [ ! -d $SAVE_TMP_PATH ]; then
    mkdir -p $SAVE_TMP_PATH
fi

if [ ! -e $SAVE_TMP_PATH/REPAIR ];
then
    REPAIR_COUNT=0
    touch $SAVE_TMP_PATH/REPAIR
else
    REPAIR_COUNT=`cat $SAVE_TMP_PATH/REPAIR`

    if [ -z "$REPAIR_COUNT" ];
    then
        REPAIR_COUNT=0
    fi
fi

###############################################################
##    Manual mode
##    Chose file by myself  
###############################################################
if [ "$1" = "MANUAL" ] && [ -n "$2" ]; then
    if [ "0" != "$2" ] && [ "B" != "$2" ] && [ $FILE_COUNT -ge $2 ]; then
        REPAIR_FILE=`ls $SAVE_PATH/$BACKUP_PREFIX* |sed -n "$2"p`
        REPAIR_COUNT=$2
    elif [ "B" = "$2" ]; then
        REPAIR_COUNT=$FILE_COUNT
    else
        echo "File Index $2 error!!"
        savelog "File index ${2} error"
        log_event "Index $2 error!" 101
    fi
else
    REPAIR_FILE=`ls $SAVE_PATH/$BACKUP_PREFIX* |sort -r|sed -n "$(($REPAIR_COUNT+1))"p`
fi

###############################################################
##    Repair mode
###############################################################
REPAIR_VER=`basename $REPAIR_FILE | awk -F '_' '{print $5}' | awk -F '.' '{print $1$2$3}'`
DOM_VER=`cat /etc/version | awk -F '.' '{print $1$2$3}'`

if [ "$1" = "MANUAL" ] && [ ! -z "$2" ]; then
    INCREASE_COUNT=0
else
    INCREASE_COUNT=1
fi

if [ $FILE_COUNT -gt $REPAIR_COUNT ] && [ $REPAIR_VER -lt $DOM_VER ];
then
    if [ $INCREASE_COUNT -eq 1 ]; then
        echo "$(($REPAIR_COUNT+1))" > $SAVE_TMP_PATH/REPAIR
    fi
    echo "Repair version is too lower"
    savelog "Repari version is too lower"
    log_event "Ver. not match" 0
fi

if [ $REPAIR_COUNT -eq 0 ]; then
    #Backup DOM A
    rm -f $SAVE_TMP_PATH/original_*
    mount_ro "/dev/${BOOTDEV}"
    #dd if=${DOMA_DEV} of=$SAVE_TMP_PATH/original_`cat /etc/version`
    mount_rw "/dev/${BOOTDEV}"
fi

if [ $REPAIR_COUNT -gt $FILE_COUNT ]; then
    #buzzer
    echo "No image file can fix DOM"
    savelog "No image file can fix DOM"
    log_event "DOM fail" 102
elif [ $REPAIR_COUNT -eq $FILE_COUNT ]; then
    #Restore from DOM B
    touch $DOM_B_DD_FLAG
    if [ ${DOMB_TO_DOMA} == 1 ];
    then
      domb_repair_to_doma
    else
      if [ "${DOM_B_EXIST_STR}" != "" ];then
        domb_repair_to_doma
      else
        echo "Single DOM Fail"
        savelog "Single DOM fail"
        log_event "DOM fail" 100
      fi
    fi
else
    repair_disk_dump $REPAIR_FILE ${DOMA_DEV} "$(($FILE_COUNT-$REPAIR_COUNT))"
fi

if [ $INCREASE_COUNT -eq 1 ]; then
    echo "$(($REPAIR_COUNT+1))" > $SAVE_TMP_PATH/REPAIR
fi

exit 0
