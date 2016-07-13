#!/bin/sh
smbd_log_enable="$1"
afpd_log_enable="$2"
ftpd_log_enable="$3"
iscsi_log_enable="$4"
sshd_log_enable="$5"
dom_access_db_path="/syslog/access.db"
raid_access_db_path="/raid/data/tmp/access.db"
SQLITE="/usr/bin/sqlite"
confdb="/etc/cfg/conf.db"
du="/usr/bin/du"

get_db(){
    access_db(){
        db_value=(size_items role access_log_enabled access_log_folder)
        echo "BEGIN TRANSACTION;"
        for value in ${db_value[@]}; do
            echo "SELECT * FROM conf WHERE k='$value';"
        done
        echo "COMMIT;"
    }
    access_db | $SQLITE $confdb | while read line; do
        echo `echo $line | cut -d \| -f 1`=\"`echo $line | cut -d \| -f 2`\"    
    done
}

eval `get_db`
if [ "$access_log_enabled" != "1" ];then
    echo "Access log disabled."
    exit
fi

if [ "$smbd_log_enable" == "1" ] || [ "$afpd_log_enable" == "1" ] || [ "$ftpd_log_enable" == "1" ] || [ "$iscsi_log_enable" == "1" ] || [ "$sshd_log_enable" == "1" ];then
    echo "Access log for service."
else
    echo "No service to monitor"
    exit
fi

if [ "$access_log_folder" == "" ] || [ ! -d "/raid/data/ftproot/$access_log_folder" ];then
      access_log_folder="NAS_Public" 
fi

access_log_path="/var/run/access_log"
sshd_log_path="${access_log_path}/sshd"
ftpd_log_path="${access_log_path}/ftpd"
smbd_log_path="${access_log_path}/smbd"
iscsi_log_path="${access_log_path}/iscsi"
afpd_log_path="${access_log_path}/afpd"

save_path="/raid/data/ftproot/$access_log_folder/access_log"

if [ ! -d "$save_path" ];then
    mkdir -p "$save_path"
    chown nobody.nogroup $save_path
fi

sys_path=`/bin/ls -l /raid/sys | awk -F' ' '{printf $11}'`
data_path=`/bin/ls -l /raid/data | awk -F' ' '{printf $11}'`
access_file="/tmp/access_file"
count="0"
sys_db_path="/syslog/sys_log.db"

if [ "$sys_path" != "" ] || [ "$data_path" != "" ];then
    db_path="${raid_access_db_path}"
    if [ -f /syslog/access.db ];then
        number_items=`$SQLITE /syslog/access.db "select count(*) from access_info"`
        if [ "$number_items" != "0" ] || [ "$number_items" != "" ];then
            cp /syslog/access.db /raid/data/tmp/
            rm -rf /syslog/access.db
        else 
            rm -rf /syslog/access.db
        fi
    fi
    ssh_save="0"
else
    db_path="${dom_access_db_path}"
    ssh_save="1"    
fi

if [ ! -f ${db_path} ];then
    $SQLITE $db_path "create table access_info(Connection_type,Date_time,Users,Source_ip,Computer_name,size,Event,tmp,level,filetype,action)"
else
    check_table=`$SQLITE $db_path ".schema"`
    if [ "$check_table" == "" ];then
        $SQLITE $db_path "create table access_info(Connection_type,Date_time,Users,Source_ip,Computer_name,size,Event,tmp,level,filetype,action)"
    fi
fi

smbd_function(){
        while read info < ${smbd_log_path}
        do
            if [ "${info}" == "quit" ];then
                break
            elif [ "${info}" == "" ];then
                continue
            fi            
            lockfile /tmp/access_lock
            
            OLD_IFS=$IFS; IFS='|'; set -- ${info}; IFS=$OLD_IFS
            
            date_time=$1
            user=$2
            ip=$3
            Computer_name=$4
            get_action=$6
            size=""
            if [ "${get_action}" == "open" ];then
                getword2=$11
                if [ "${getword2}" == "." ];then
                    event=$5
                    action="Open"
                    file_type="Folder"
                else
                    folder1=$5
                    folder2=$9
                    act=$8
                    if [ -d "/raid/data/ftproot/${folder1}/${folder2}" ];then
                        file_type="Folder"
                    else
                        file_type="File"
                        sync
                        size=(`${du} -h "/raid/ftproot/${folder1}/${folder2}"`)
                    fi
                    
                    if [ "${act}" == "w" ];then
                        action="Write"
                    else
                        if [ "${file_type}" == "Folder" ];then
                            action="Open"
                        else
                            action="Read"
                        fi
                    fi
                                            
                    if [ "${folder2}" == "." ];then
                        event="${folder1}"
                    else
                        event="${folder1}/${folder2}"
                    fi
                fi
                level="Info"                                
            elif [ "${get_action}" == "rename" ];then
                folder1=$5
                rename_file1=$8
                rename_file2=$9
                if [ "${rename_file2_tmp}" == "${rename_file2}" ];then
                    event=""
                else
                    event="${folder1}/${rename_file1}->${folder1}/${rename_file2}"    
                fi
                rename_file2_tmp="${rename_file2}"                 
                size=(`${du} -h "/raid/ftproot/${folder1}/${rename_file2}"`)
                level="Info"
                if [ -d "/raid/data/${folder1}/${rename_file2}" ];then
                    file_type="folder"
                else
                    file_type="file"
                fi
                action="Rename"                
            elif [ "${get_action}" == "rmdir" ];then
                folder1=$5
                folder2=$8
                level="Info"
                action="Delete"
                file_type="Folder"
                event="${folder1}/${folder2}"
            elif [ "${get_action}" == "mkdir" ];then
                folder1=$5
                folder2=$8
                level="Info"
                action="Create"
                file_type="Folder"
                event="${folder1}/${folder2}"
            elif [ "${get_action}" == "unlink" ];then
                folder1=$5
                folder2=$8
                level="Info"
                action="Delete"
                file_type="File"
                event="${folder1}/${folder2}"
            fi
            
            if [ "${event}" != "" ];then
                echo "samba|${date_time}|${user}|${ip}|${Computer_name}|${size}|${event}||${level}|${file_type}|${action}" >> ${access_file}
            fi
            rm -f /tmp/access_lock
        done
}

afpd_function(){
        while read info < ${afpd_log_path}
        do
            if [ "${info}" == "quit" ];then
                break
            elif [ "${info}" == "" ];then
                continue
            fi            
            lockfile /tmp/access_lock
            
            OLD_IFS=$IFS; IFS='|'; set -- ${info}; IFS=$OLD_IFS
            
            date_time=$1
            afpd_info=$3
            set -- ${afpd_info}
            getwording=$2
            if [ "${getwording}" == "Login" ];then
                event="Login OK"
                ip=$8
                user=$4
                level="Info"
            elif [ "${getwording}" == "logout" ];then
                event="Logout OK"
                ip=$8
                user=$4
                level="Info"
            elif [ "${getwording}" == "by" ] || [ "${getwording}" == "authentication" ];then
                getwording=`echo ${info} |awk -F'|' '{print $3}'|awk -F' ' '{print $3}'`
                if [ "${getwording}" == "failure;" ];then
                    event="Login Fail"
                    ip=`echo "$9" | awk -F'=' '{print $2}'`
                    user=`echo "$10" | awk -F'=' '{print $2}'`    
                fi          
                level="Error"              
            fi
            echo "AFP|${date_time}|${user}|${ip}|||${event}||${level}||" >> ${access_file}
            rm -f /tmp/access_lock
        done
}

ftpd_function(){
        continue_flag="1"
        while read info < ${ftpd_log_path}
        do
            if [ "${info}" == "quit" ];then
                break
            fi            
            
            OLD_IFS=$IFS; IFS='|'; set -- ${info}; IFS=$OLD_IFS
            
            getwording=`echo "$2" | awk '{print $3}'`
            if [ "${info}" == "" ] || [ "${continue_flag}" == "8" -a "${getwording}" == "Logout." ];then
                continue_flag="1"
                continue
            fi
            
            lockfile /tmp/access_lock
            
            date_time=$1
            size=""
            if [ "${getwording}" == "Authentication" ];then
                event="Login Fail"
                ip=`echo "$2" | awk -F'[(@)]' '{print $3}'`
                user=`echo "$2" | awk '{print $7}'|sed 's/\[*\]*//g'`
                action="Connect"
                continue_flag="8" 
                level="Error"               
            elif [ "${getwording}" == "Logout." ];then
                user=`echo "$2" | awk -F'[(@)]' '{print $2}'`
                ip=`echo "$2" | awk -F'[(@)]' '{print $3}'`
                if [ "${user}" == "?" ];then
                    event=""
                elif [ "${user}" == "ftp" ];then
                    event="Logout OK"
                    user="nobody"
                else
                    event="Logout OK"
                fi
                action="Connect"
                level="Info"
                continue_flag="1"
            elif [ "${getwording}" == "Anonymous" ];then                
                event="Login OK"
                ip=`echo "$2" | awk -F'[(@)]' '{print $3}'`
                user="nobody" 
                action="Connect"
                continue_flag="1"
                level="Info"                         
            else
                level=`echo "$2" | awk '{print $2}'`
                if [ "${level}" == "[NOTICE]" ];then
                    user=`echo "$2" | awk -F'[(@)]' '{print $2}'`
                    if [ "${user}" == "ftp" ];then
                        user="nobody"
                    fi
                    ip=`echo "$2" | awk -F'[(@)]' '{print $3}'`
                    
                    event=$3
                    if [ "`echo ${event}| grep '.uploaded$'`" != "" ];then
                        file_type="File"
                        filepath=`echo ${event}| grep '.uploaded$'| sed 's/ uploaded$//g'`
                        action="Upload"
                    elif [ "`echo ${event}| grep '.downloaded$'`" != "" ];then 
                        file_type="File"
                        filepath=`echo ${event}| grep '.downloaded$'| sed 's/ downloaded$//g'`
                        action="Download"
                    elif [ "`echo ${event}| grep '.File renamed$'`" != "" ];then 
                        file_type="File"
                        action="Rename"
                    elif [ "`echo ${event}| grep '.Directory created$'`" != "" ];then 
                        file_type="Folder"
                        action="Create"
                    elif [ "`echo ${event}| grep '.Directory removed$'`" != "" ];then 
                        file_type="Folder"
                        action="Delete"
                    elif [ "`echo ${event}| grep '.Deleted$'`" != "" ];then 
                        file_type="File"
                        action="Delete"
                    fi
                    
                    if [ "${action}" == "Upload" ] || [ "${action}" == "Download" ];then
                        size=(`${du} -h "/raid/ftproot/${filepath}"`)
                    fi
                    
                    level="Info"
                    continue_flag="1"    
                elif [ "${level}" == "[INFO]" ];then
                    user=`echo "$2" | awk '{print $3}'`
                    ip=`echo "$2" | awk -F"[(@)]" '{print $3}'`
                    continue_flag=$((${continue_flag} + 1))
                    if [ "${continue_flag}" != "3" ];then
                        action="Connect"
                        event="Login OK"
                    else
                        event=""    
                    fi
                    level="Info"       
                fi            
            fi
            
            if [ "${event}" != "" ];then
                echo "FTP|${date_time}|${user}|${ip}||${size}|${event}||${level}|${file_type}|${action}" >> ${access_file}
            fi
			rm -f /tmp/access_lock
        done
}

iscsi_function(){
        while read info < ${iscsi_log_path}
        do
            if [ "${info}" == "quit" ];then
                break
            elif [ "${info}" == "" ];then
                continue
            fi            
            lockfile /tmp/access_lock
            
            OLD_IFS=$IFS; IFS='|'; set -- ${info}; IFS=$OLD_IFS 
            
            date_time=$1
            if [ "`echo \"${info}\" | grep \"is not authorized to access iSCSI target portal\"`"  != "" ];then
                ip=""
                user=`echo "$2" | awk '{print $5}'`
                event="${user} is not authorized to access iSCSI target portal"
                level="Error"        
            elif [ "`echo \"${info}\" | grep \"Received iSCSI login request from\"`"  != "" ];then
                ip=`echo "$2" | awk '{print $7}'`
                event="Received iSCSI login request"
                user=""
                level="Info"
            else
                Targetname=$4
                event=""
                ip=$3
                user=$5
                get_event=`echo "$2" |awk '{print $3}'`
                if [ "${get_event}" == "login." ];then
                    event="iSCSI Login successful to ${Targetname}"
                    level="Info"
                else
                    event="iSCSI Logout successful from ${Targetname}"
                    level="Info"
                fi
            
                if [ "${Targetname}" == "" ] && [ "${user}" != "" ];then
                    event="Discovery iSCSI Target "
                fi
            fi
            
            if [ "${event}" != "" ];then
                echo "iSCSI|${date_time}|${user}|${ip}|||${event}||${level}||" >> ${access_file}
            fi
            rm -f /tmp/access_lock
        done
}            

sshd_function(){
        while read info < ${sshd_log_path}
        do
            if [ "${info}" == "quit" ];then
                break
            elif [ "${info}" == "" ];then
                continue
            fi            
            lockfile /tmp/access_lock
            
            OLD_IFS=$IFS; IFS='|'; set -- ${info}; IFS=$OLD_IFS
            
            date_time=$1
            getwording=`echo "$3" | awk '{print $1}'`
            if [ "${getwording}" == "Accepted" ];then
                event="Login OK"
                ip=`echo "$3" | awk '{print $6}'`
                user=`echo "$3" | awk '{print $4}'`
                pid=$2
                level="Info"
            elif [ "${getwording}" == "Closing" ];then
                event="Logout OK"
                ip=`echo "$3" | awk '{print $4}'`
                pid=$2           
                user=""
                if [ -f ${access_file} ];then
                  user=`cat ${access_file} | awk -F"|" "/^SSH|/&&/|${pid}|/{print \\$3}" | tail -1`
                fi
                if [ "${user}" = "" ];then
                  user=`$SQLITE $db_path "select Users from access_info where tmp='${pid}' and Source_ip='${ip}'"`
                fi
                level="Info"
            elif [ "${getwording}" == "Failed" ];then
                event="Login Fail"
                user=`echo "$3" | awk '{print $4}'`
                if [ ${user} == "invalid" ];then
                    user=`echo "$3" | awk '{print $6}'`
                    ip=`echo "$3" | awk '{print $8}'`
                else
                    user=`echo "$3" | awk '{print $4}'`
                    ip=`echo "$3" | awk '{print $6}'`
                fi
                pid=""
                level="Error"
            fi 
            echo "SSH|${date_time}|${user}|${ip}|||${event}|${pid}|${level}||" >> ${access_file}
            rm -f /tmp/access_lock
        done
}

rm -f /tmp/access_lock

if [ "$smbd_log_enable" == "1" ];then
    smbd_function &
fi
    
if [ "$afpd_log_enable" == "1" ];then
    afpd_function &
fi
  
if [ "$ftpd_log_enable" == "1" ];then
    ftpd_function &
fi
    
if [ "$iscsi_log_enable" == "1" ];then
    iscsi_function &
fi
     
if [ "$sshd_log_enable" == "1" ];then
    sshd_function &
fi
    
while true
do
    sleep 10
    lockfile /tmp/access_lock
    if [ -f ${access_file} ] && [ -s ${access_file} ];then
        $SQLITE $db_path ".import $access_file access_info"
        rm -f ${access_file}    
    fi    
    rm -f /tmp/access_lock
    
    count=$(($count+1))
    if [ "$count" == "6" ];then
        if [ "$size_items" == "" ];then
            size_tmp=60000
            size_items=10000
        else
            size_tmp=$(($size_items+1))
        fi
        
        lockfile /tmp/access_lock
        Items=`$SQLITE $db_path "select count(*) from access_info"`
        if [ ${Items} -ge ${size_tmp} ];then
            if [ "$role" == "save" ] && [ "$ssh_save" != "1" ];then
				if [ ! -d "$save_path" ];then
					mkdir -p "$save_path"  
                    chown nobody.nogroup $save_path
				fi
                time_now=`date "+%Y%m%d_%H%M%S"`
                echo -e "\xEF\xBB\xBF" > ${save_path}/log_${time_now}.csv
                echo '"Service","Date","User Name","Source IP","Computer Name","Size","Event","Level"' >> ${save_path}/log_${time_now}.csv
                $SQLITE -csv $db_path "select Connection_type,Date_time,Users,Source_ip,Computer_name,size,Event,level from access_info limit $size_items" >> ${save_path}/log_${time_now}.csv
                chown nobody.nogroup ${save_path}/log_${time_now}.csv
            fi
            $SQLITE $db_path "delete from access_info where rowid < (select rowid from access_info limit $size_items,1)"
        fi
        
        Items=`$SQLITE $sys_db_path "select count(*) from sysinfo"`
        if [ $Items -ge $size_tmp ];then
            if [ "$role" == "save" ] && [ "$ssh_save" != "1" ];then
				if [ ! -d "$save_path" ];then
					mkdir -p "$save_path"
                    chown nobody.nogroup $save_path
				fi
                time_now=`date "+%Y%m%d_%H%M%S"`
                echo -e "\xEF\xBB\xBF" > ${save_path}/system_log_${time_now}.csv
                echo '"Date Time","Event","Level"' >> ${save_path}/system_log_${time_now}.csv
                $SQLITE -csv $sys_db_path "select Date_time,Details,level from sysinfo limit $size_items" >> ${save_path}/system_log_${time_now}.csv
                chown nobody.nogroup ${save_path}/system_log_${time_now}.csv
            fi
            $SQLITE $sys_db_path "delete from sysinfo where rowid < (select rowid from sysinfo limit $size_items,1)"
        fi
        rm -f /tmp/access_lock
        
        count="0"
    fi
done

