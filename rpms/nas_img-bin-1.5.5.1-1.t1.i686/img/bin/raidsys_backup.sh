#!/bin/sh
TIME_STAMP=`date +%Y%m%d%H%M%S`
BACKUP_PREFIX="raidsys"

md_list=`cat /proc/mdstat | awk '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
if [ "${md_list}" == "" ];then
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
fi

function check_extra_file() {
    local md=$1
    sys_tmp_path="/raid${md}/data/_SYS_TMP"
    raid_sys_path="${sys_tmp_path}/raidsys_backup"
    FILE_COUNT=0

    for TMP_FILE in `ls ${raid_sys_path}/${BACKUP_PREFIX}* | sort -nr`
    do
        FILE_COUNT=$(($FILE_COUNT + 1))

        if [ $FILE_COUNT -gt 4 ];then
            echo "Delete File :"$TMP_FILE $FILE_COUNT
            rm -f $TMP_FILE
        fi
    done
}
          
for md in $md_list
do
    raidsys_path="/raid${md}/sys"
    sys_tmp_path="/raid${md}/data/_SYS_TMP"
    raidsys_backup_path="${sys_tmp_path}/raidsys_backup"
    
    if [ -d "${raidsys_path}" ] && [ -d "${sys_tmp_path}" ];then
        if [ ! -d "${raidsys_backup_path}" ];then
            mkdir "${raidsys_backup_path}"
        fi
    else
        continue
    fi
    
    check_extra_file "${md}"
    cd "${raidsys_path}"
    tar zcvf ${raidsys_backup_path}/${BACKUP_PREFIX}_${TIME_STAMP}.tar.gz ./* 
done
