#!/bin/sh
TMP_PATH=/tmp
SYS_TMP_PATH=/raid/data/_SYS_TMP
RAID_DATA_PATH=$SYS_TMP_PATH/dual_dom
SAVE_TMP_PATH=$RAID_DATA_PATH/save_tmp
SAVE_PATH=$RAID_DATA_PATH/save
CURRENT_HOUR=`date +%H`
TIME_STAMP=`date +%Y%m%d%H%M%S`
macaddr=`/img/bin/function/get_interface_info.sh get_mac eth0 | awk -F: '{printf("%s%s%s%s%s%s",$1,$2,$3,$4,$5,$6)}'`
BACKUP_PREFIX="backup_${macaddr}_"
FILE_COUNT=`ls $SAVE_PATH/$BACKUP_PREFIX* | wc -l | awk '{print($1)}'`
BACKUP_SERIAL_NUM=""

DOMA="sdaaa"
DOMB="sdaab"

PARTITION_HDA_STR=`/bin/grep ${DOMA} /proc/partitions`
PARTITION_HDB_STR=`/bin/grep ${DOMB} /proc/partitions`

DATE=`date "+%Y%m%d_%H%M"`
#DATE=`date "+%Y%m%d"`
raid_folder="NAS_Public"
dom_backup_log_path="/tmp/dom_backup_log"
if [ ! -e "${dom_backup_log_path}" ];
then
    mkdir "${dom_backup_log_path}"
fi

##################################################################
##  Function
##################################################################
function exit_script(){
    error_code=$1
    if [ "${usb_log}" == "1" ];
    then                        
        umount "${dom_backup_log_path}"
    fi                             
    exit ${error_code}
}

function savelog(){
    msg=$1
    time_stamp=`date +'%Y/%m/%d %H:%M:%S'`
    echo "${time_stamp} ${hostname} : [DOM Backup] ${msg}" >> ${log_file}
}

function checkusb(){
    usb_log="0"
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
                mount "/dev/${mount_usb}" "${dom_backup_log_path}"
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
            echo "${dom_backup_log_path}"
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
            if [ ! -e "/${data_path}/data/${raid_folder}/do_backup_log" ];
            then
                mkdir -p "/${data_path}/data/${raid_folder}/dom_backup_log"
            fi
            echo "/${data_path}/data/${raid_folder}/dom_backup_log"
        fi
    fi                                                                                                                          
}


function check_extra_file() {
    FILE_COUNT=0

    for TMP_FILE in `ls ${SAVE_PATH}/${BACKUP_PREFIX}* | sort -nr`
    do
        FILE_COUNT=$(($FILE_COUNT + 1))

        if [ $FILE_COUNT -gt 4 ];then
            echo "Delete File :"$TMP_FILE $FILE_COUNT
            rm -f $TMP_FILE
        fi
    done
}

function mount_ro() {
  mount -o remount,ro,noatime -t ext2 ${DOMA}2 /etc
  mount -o remount,ro,noatime -t ext2 ${DOMA}4 /syslog
}

function mount_rw() {
  mount -o remount,rw,noatime -t ext2 ${DOMA}2 /etc
  mount -o remount,rw,noatime -t ext2 ${DOMA}4 /syslog
}

##################################################################
##  Main code
##################################################################
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
        log_path="${dom_backup_log_path}"
    fi
else
    usb_log=1
fi
log_file="${log_path}/${DATE}_dom_backup_log"
#if [ ! -e "${log_file}" ];
#then
#    touch ${log_file}
#fi

#savelog "Log file = ${log_file}"

if [ ! -e /raid/data/ftproot ]; then
    savelog "Start backup mode"
    echo "RAID is not exist"
    savelog "RAID is not exist!"
    exit 1
fi

if [ ! -d $SAVE_PATH ]; then
    mkdir -p $SAVE_PATH
fi

if [ ! -d $SAVE_TMP_PATH ]; then
    mkdir -p $SAVE_TMP_PATH
fi

if [ $CURRENT_HOUR -lt 1 ]; then
    echo "Auto mode"
    rm -f $TMP_PATH/SUCCESS
    rm -rf $SAVE_TMP_PATH/*
    if [ "$1" = "" ];then
      exit_script 1
    fi
fi

if [ -e $TMP_PATH/SUCCESS ] && [ "$1" = "" ]; then
    echo "Auto mode, but not on schedule time"
    exit_script 0
fi

if [ -e $SAVE_TMP_PATH/SUCCESS ] && [ "$1" = "" ]; then
    echo "Auto mode, but not on schedule time"
    exit_script 0
fi

savelog "Start backup mode"
if [ -e $SAVE_TMP_PATH/ERROR ]; then
    echo "Last time is ERROR"
    savelog "Last time is ERROR"
    rm -f $SAVE_TMP_PATH/ERROR
fi

rm -rf $SAVE_TMP_PATH/REAL_SUCCESS

echo "2" > /tmp/ddom_status

if [ $FILE_COUNT -eq 0 ];then
    BACKUP_SERIAL_NUM=0000000
else
    BACKUP_SERIAL_NUM=`ls $SAVE_PATH/$BACKUP_PREFIX* | sort -nr | head -n 1 | cut -d "/" -f 7 | awk -F_ '{printf("%07d",$3+1);}'`
fi

BACKUP_FILE="$BACKUP_PREFIX""$BACKUP_SERIAL_NUM""_$TIME_STAMP""_`cat /etc/version`"

touch $SAVE_TMP_PATH/ERROR
dd if=/dev/${DOMA} of=$SAVE_TMP_PATH/$BACKUP_FILE

domsize=`/img/bin/check_service.sh domsize`

if [ "${domsize}" == "1024" ];then
  doma1_md5=`dd if=/dev/${DOMA} bs=512 count=201537 | md5sum`
  backupfile1_md5=`dd if=$SAVE_TMP_PATH/$BACKUP_FILE bs=512 count=201537 | md5sum`

  doma3_md5=`dd if=/dev/${DOMA} bs=512 count=1669248 skip=249921 | md5sum`
  backupfile3_md5=`dd if=$SAVE_TMP_PATH/$BACKUP_FILE bs=512 count=1669248 skip=249921 | md5sum`
else
  doma1_md5=`dd if=/dev/${DOMA} bs=512 count=198338 | md5sum`
  backupfile1_md5=`dd if=$SAVE_TMP_PATH/$BACKUP_FILE bs=512 count=198338 | md5sum`
    
  doma3_md5=`dd if=/dev/${DOMA} bs=512 count=684480 skip=247938 | md5sum`
  backupfile3_md5=`dd if=$SAVE_TMP_PATH/$BACKUP_FILE bs=512 count=684480 skip=247938 | md5sum`
fi
 
if [ "$doma1_md5" = "$backupfile1_md5" ] && [ "$doma3_md5" = "$backupfile3_md5" ]; then
    check_extra_file
    mv -f $SAVE_TMP_PATH/$BACKUP_FILE $SAVE_PATH

    if [ "$1" = "" ]; then
        touch $SAVE_TMP_PATH/SUCCESS
        touch $TMP_PATH/SUCCESS
    fi
    touch $SAVE_TMP_PATH/REAL_SUCCESS

    #log to success
    savelog "Backup DOM A success"
    /img/bin/raidsys_backup.sh
    #/img/bin/logevent/information 130 $BACKUP_FILE
else
    #log to error
    savelog "Backup DOM A failed!"
    #/img/bin/logevent/event 997 652 error email
    rm $SAVE_TMP_PATH/$BACKUP_FILE

    if [ "$1" = "SCHEDULE" ]; then
        touch $SAVE_TMP_PATH/SUCCESS
        touch $TMP_PATH/SUCCESS
    fi
fi
rm -f $SAVE_TMP_PATH/ERROR
#mount_rw
sync
exit_script 0
