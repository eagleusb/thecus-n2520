sqlite="/usr/bin/sqlite"
confdb="/etc/cfg/conf.db"
recycle_doc="/tmp/recycle_doc" 
sqlite_result() {
     sqlcmd="select v from conf where k='$1'"
     ${sqlite} ${confdb} "${sqlcmd}"
}
smb_dataago=`sqlite_result "smb_dataago"`
advance_smb_recycle=`sqlite_result "advance_smb_recycle"`
if [ "$advance_smb_recycle" == "1" ] && [ "$smb_dataago" != "0" ];then
    if [ "$smb_dataago" -gt 0 ];then
        smb_dataago=$((smb_dataago-1))
        echo $smb_dataago
    fi
    md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
    if [ "${md_list}" == "" ];then
        md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
    fi  
    for md in $md_list  
    do
        if [ -d "/raid$md/" ];then
            raid_id=`cat /var/tmp/raid$md/raid_id`
                    
            if [ -d /raid$md/data/_NAS_Recycle_${raid_id} ];then
                echo "find /raid$md/data/_NAS_Recycle_${raid_id}/* -ctime +$smb_dataago -print -exec rm -rf {}"
                result=`find /raid$md/data/_NAS_Recycle_${raid_id}/* -ctime +$smb_dataago -print -exec rm -rf "{}" ";"`
            fi
        fi
    done    
fi  

${sqlite} /etc/cfg/stackable.db "select share from stackable" > ${recycle_doc}
                                                                              
if [ -n "`cat ${recycle_doc}`" ];then                                         
    while read info                                                           
    do                                                                        
        if [ -d /raid/data/stackable/${info}/_NAS_Recycle_${info} ];then      
            echo "find /raid/data/stackable/${info}/_NAS_Recycle_${info}/* -ctime +$smb_dataago -print -exec rm -rf {}"
            result=`find /raid/data/stackable/${info}/_NAS_Recycle_${info}/* -ctime +$smb_dataago -print -exec rm -rf "{}" ";"`
        fi                                                                                                                     
    done < ${recycle_doc}                                                                                                      
    rm -f ${recycle_doc}                                                                                                       
fi              
