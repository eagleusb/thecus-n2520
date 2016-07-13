#!/bin/sh 
ARCH=`/img/bin/check_service.sh arch`
export LANG="en_US.UTF-8"
export LC_TIME="POSIX"

CPU_Info() {
  top_info=`top -bn 1 | grep [C]pu`
  user=`echo $top_info | awk '{print $2}' | awk -F% '{print $1}'`
  sys=`echo $top_info | awk '{print $3}' | awk -F% '{print $1}'`
  nice=`echo $top_info | awk '{print $4}' | awk -F% '{print $1}'`
  idle=`echo $top_info | awk '{print $5}' | awk -F% '{print $1}'`
  iowait=`echo $top_info | awk '{print $6}' | awk -F% '{print $1}'`
  echo -e "[CPU:1:user,sys,nice,idle,iowait]\n$user,$sys,$nice,$idle,$iowait" > /var/tmp/monitor/CPU_Info
}

fanDefination(){
    if [ -f /var/run/model ]; then
        MB=.`cat /var/run/model`
    else
        MB=`awk -F' ' '/^MBTYPE/{printf($2)}' /proc/thecus_io`
    fi

    CONF=/img/bin/conf/sysconf$MB.txt

    FANS=(`grep _fan $CONF | sed 's/\(.*\)\([0-9]\)=\(.*\)/\1[\2]=\3/g'`)

    for i in ${FANS[*]};
    do
        eval $i
    done
    
    if [ "$ARCH" == "x86_64" ]; then
        TEMPS=0
        
        for i in `sed -nr 's/^.*_temp.*=(.*)$/\1/p' $CONF`;
        do
            TEMPS=$(($TEMPS + $i))
        done
    else
        TEMPS=99
    fi

    if [ -f /proc/thecus_hwm ]; then
        HWINFO=/proc/thecus_hwm
    else
        HWINFO=/proc/hwm
    fi
}

fanStatus(){
    ## Get all fan information
    FANS=(`sed -nr 's/^([a-zA-Z_]*)\s?([0-9]*) RPM: ([0-9]*)\s?.*$/\1[0\2]=\3/p' $HWINFO`)
    
    for f in ${FANS[*]}; do
        eval $f
    done

    if [ "$ARCH" == "x86_64" ]; then
        ## 64 bit system
        if [ ${cpu_fan[1]} -ne 0 ]; then
            echo CPU_FAN ${CPU_FAN[0]}
        fi

        f=1
        while [ $f -le ${sys_fan[1]} ]; do
            echo HDD_FAN$f ${HDD_FAN[$f]}
            f=$(($f + 1))
        done
    else
        if [ $MB == ".N2200" ]; then
            echo SYS_FAN ${FAN[1]}
            return 1
        fi

        ## 32 bit system
        if [ ${cpu_fan[1]} -ne 0 ]; then
            echo CPU_FAN ${FAN[1]}
        fi

        f=1
        while [ ${sys_fan[$f]} -ne 0 ]; do
            echo SYS_FAN$f ${FAN[$(($f + 1))]}
            f=$(($f + 1))
        done
    fi
}

tempStatus() {
    grep -e ".*T[EeMmPp].*: [0-9]*" $HWINFO | sed 's/\(.*\): \(.*\)/\1:\2/g' | sed 's/ /_/g' | sed 's/:/ /g' | head -n $TEMPS
}

Fan_Info() {
  [ ! "`/img/bin/check_env.sh -r hwm`" == "exist" ] && return
  [ "`/img/bin/check_service.sh cpu_fan1`" == "0" \
    -a "`/img/bin/check_service.sh sys_fan1`" == "0" \
    -a "`/img/bin/check_service.sh sys_fan2`" == "0" \
    -a "`/img/bin/check_service.sh cup_temp1`" == "0" \
    -a "`/img/bin/check_service.sh sys_temp`" == "0" ] && return

  FAN=(`fanStatus`)
  echo -e "[FAN:$((${#FAN[*]}/2)):name,rpm]" > /var/tmp/monitor/Fan_Info
  i=0
  while [ $i -lt ${#FAN[*]} ]; do
    echo ${FAN[$i]},${FAN[$i+1]} >> /var/tmp/monitor/Fan_Info
    i=$(($i+2))
  done
  
  TEMP=(`tempStatus`)
  echo -e "[TEMP:$((${#TEMP[*]}/2)):name,temp]" > /var/tmp/monitor/Temp_Info
  
  i=0
  while [ $i -lt ${#TEMP[*]} ]; do
    echo ${TEMP[$i]},${TEMP[$i+1]} >> /var/tmp/monitor/Temp_Info
    i=$(($i+2))
  done
}

Service_Info() {
  sar_info=`sar -u -n DEV 1 1 | grep -v Average`
  cpu_info=`echo -e "$sar_info" | head -n 4 | tail -n 1`
  CPU=`echo $cpu_info | awk '{print $3+$5}'`
  
  top_info=`top -bn 1 | head -n 5`
  MEM=`echo -e $top_info | sed 's/.*Mem: \(.*\)k total, \(.*\)k used.*Swap.*/\1 \2/g'`
  MEM=`echo $MEM | awk '{printf("%.1f", $2/$1*100)}'`
  echo -e "[Service:4:name,cpu,mem]" > /var/tmp/monitor/Service_Info
  echo -e "Sys,$CPU,$MEM" >> /var/tmp/monitor/Service_Info
}

Memory_Info() {
  mem_info=`top -bn 1 | grep [M]em:`
  total=`echo $mem_info | awk '{print $3}'`
  used=`echo $mem_info | awk '{print $5}'`
  free=`echo $mem_info | awk '{print $7}'`
  buff=`echo $mem_info | awk '{print $9}'`
  echo -e "[Memory:1:total,used,free,buff]\n$total,$used,$free,$buff" > /var/tmp/monitor/Memory_Info
}

Disk_Info() {
  disk_info=`iostat -dm | grep -v sdaa | grep -v md[0-9]0 | tail -n +4 | sort | awk -F' ' '{if($1 != "") printf("%s,%s,%s,%s,%s,%s\n",$1,$2,$3,$4,$5,$6)}'`
  disk_count=`echo "$disk_info" | wc -l`
  echo -e "[Disk:$disk_count:Device,tps,MB_read/s,MB_wrtn/s,MB_read,MB_wrtn]" > /var/tmp/monitor/Disk_Info
  for v in $disk_info
  do
    echo -e $v  >> /var/tmp/monitor/Disk_Info
  done
}

Network_Info() {
  sar_info=`sar -n DEV 1 1 | grep -E "(g?eth|bond)[0-9]+" | grep -v Average`
  network_count=`echo "$sar_info" | wc -l`
  echo -e "[Network:$network_count:name,rx,tx]" > /var/tmp/monitor/Network_Info
  echo -e "$sar_info" | while read net_info
  do
    name=`echo $net_info | awk '{print $2}'`
    rx=`echo $net_info | awk '{print $5}'`
    tx=`echo $net_info | awk '{print $6}'`
    echo -e "$name,$rx,$tx" >> /var/tmp/monitor/Network_Info
  done
}

State_Info() {
  if [ ! -e "/raid/sys/" ]; then
    return
  fi
  save=`cat /var/tmp/monitor/save`
  if [ ! "$save" = "1" ]; then
    return
  fi
  sar_info=`sar -u -n DEV 1 1 | grep -v Average`
  cpu_info=`echo -e "$sar_info" | head -n 4 | tail -n 1`
  cpu=`echo $cpu_info | awk '{print $3+$5}'`
  echo "CPU $cpu" > /var/tmp/monitor/update_data
  
  top_info=`top -bn 1 | head -n 5`
  mem=`echo -e $top_info | sed 's/.*Mem: \(.*\)k total, \(.*\)k used.*Swap.*/\1 \2/g'`
  mem=`echo $mem | awk '{printf("%.1f", $2/$1*100)}'`
  echo "MEM $mem" >> /var/tmp/monitor/update_data

  line=0
  sar_info=`sar -n DEV 1 1 | grep -E "(g?eth|bond)[0-9]+" | grep -v Average`
  echo -e "$sar_info" | while read net_info
  do
    name=`echo $net_info | awk '{print $2}'`
    rx=`echo $net_info | awk '{print $5/1024}'`
    tx=`echo $net_info | awk '{print $6/1024}'`
    echo -e "$name""_rx $rx\n$name""_tx $tx" >> /var/tmp/monitor/update_data
  done

  cat /var/tmp/monitor/update_data | /img/bin/history.sh update
}


Samba_User_Info() {
  samba_info1=`lsof -n -c smbd | grep '\->'  | awk -F' ' '{print $2,substr($9,index($9,">")+1)}'`

  if [ "$samba_info1" = "" ]; then
    echo -e "[Samba:0:ip,user,path]" > /var/tmp/monitor/Samba_User_Info
    return
  fi
  count=`lsof -n -c smbd | grep /data/ | wc -l`
  echo -e "[Samba:$count:ip,user,path]" > /var/tmp/monitor/Samba_User_Info
  echo -e "$samba_info1" | while read samba_info
  do
    PID=`echo $samba_info | awk '{print $1}'`
    IP=`echo $samba_info | awk '{print $2}' | awk -F: '{print $1}'`
    samba_info2=`lsof -n -c smbd -ap ${PID} | grep /data/ | head -n 1`
    USER=`echo $samba_info2 | awk '{print $3}'`
    FOLDER=`echo $samba_info2 | awk '{printf("%s",$9);for (i=10; i<=NF; i++) printf(" %s", $i)}'| awk -F/ '{print $4}'`
    if [ ! "$FOLDER" = "" ] && [ ! "$USER" = "root" ]; then
      echo "${IP},${USER},${FOLDER}" >> /var/tmp/monitor/Samba_User_Info
    fi
  done
}

AFP_User_Info() {
  AFP_info1=`lsof -n -c afpd | grep '\->'  | awk -F' ' '{print $2,substr($9,index($9,">")+1)}'`

  if [ "$AFP_info1" = "" ]; then
    echo -e "[AFP:0:ip,user,path]" > /var/tmp/monitor/AFP_User_Info
    return
  fi
  count=`lsof -n -c afpd | grep /data/ | wc -l`
  echo -e "[AFP:$count:ip,user,path]" > /var/tmp/monitor/AFP_User_Info
  echo -e "$AFP_info1" | while read AFP_info
  do
    PID=`echo $AFP_info | awk '{print $1}'`
    IP=`echo $AFP_info | awk '{print $2}' | awk -F: '{print $1}'`
    if [ "${IP}" = "127.0.0.1" ];then
      continue
    fi
    AFP_info2=`lsof -n -c afpd -ap ${PID} | grep /data/ | head -n 1`
    USER=`echo $AFP_info2 | awk '{print $3}'`
    FOLDER=`echo $AFP_info2 | awk '{printf("%s",$9);for (i=10; i<=NF; i++) printf(" %s", $i)}'| awk -F/ '{print $4}'`
    if [ ! "$FOLDER" = "" ]; then
      echo "${IP},${USER},${FOLDER}" >> /var/tmp/monitor/AFP_User_Info
    fi
  done
}

FTP_User_Info() {
  FTP_info1=`lsof -n -c pure-ftpd | grep '\->'  | awk -F' ' '{print $2,substr($9,index($9,">")+1)}'`

  if [ "$FTP_info1" = "" ]; then
    echo -e "[FTP:0:ip,user,path]" > /var/tmp/monitor/FTP_User_Info
    return
  fi
  count=`lsof -n -c pure-ftpd | grep /data/ | wc -l`
  echo -e "[FTP:$count:ip,user,path]" > /var/tmp/monitor/FTP_User_Info
  echo -e "$FTP_info1" | while read FTP_info
  do
    PID=`echo $FTP_info | awk '{print $1}'`
    IP=`echo $FTP_info | awk '{print $2}' | awk -F: '{print $1}'`
    FTP_info2=`lsof -n -c pure-ftpd -ap ${PID} | grep /data/ | head -n 1`
    USER=`echo $FTP_info2 | awk '{print $3}'`
    FOLDER=`echo $FTP_info2 | awk '{printf("%s",$9);for (i=10; i<=NF; i++) printf(" %s", $i)}'| awk -F/ '{print $4}'`
    if [ ! "$FOLDER" = "" ]; then
      echo "${IP},${USER},${FOLDER}" >> /var/tmp/monitor/FTP_User_Info
    fi
  done
}

NFS_User_Info() {
  NFS_MNT_LIST="/var/lib/nfs/rmtab"
  if [ -f "$NFS_MNT_LIST" ]; then
    NFS_info1=`cat $NFS_MNT_LIST`
  fi
  NFS_info2=`netstat -an | grep 2049 | grep tcp | grep ESTABLISHED`

  if [ "$NFS_info1" = "" ] && [ "$NFS_info2" = "" ]; then
    echo -e "[NFS:0:ip,path]" > /var/tmp/monitor/NFS_User_Info
    return
  fi
  count=`cat $NFS_MNT_LIST 2> /dev/null | wc -l`
  count2=`netstat -an | grep 2049 | grep tcp | grep ESTABLISHED | wc -l`
  count=`expr $count + $count2`
  
  echo -e "[NFS:$count:ip,user,path]" > /var/tmp/monitor/NFS_User_Info
  
  echo -e "$NFS_info1" | while read NFS_info
  do
    IP=`echo $NFS_info | awk -F: '{print $1}'`
    FOLDER=`echo $NFS_info | awk -F/ '{print $5}' | awk -F: '{print $1}'`
    if [ ! "$FOLDER" = "" ]; then
      echo "${IP},root,${FOLDER}" >> /var/tmp/monitor/NFS_User_Info
    fi
  done
  
  echo -e "$NFS_info2" | while read NFS_info
  do
    IP=`echo $NFS_info | awk '{print $5}' | awk -F: '{print $1}'`
    IP_exist=`grep ${IP} /var/tmp/monitor/NFS_User_Info`
    if [ ! "$IP" = "" ] && [ "${IP_exist}" = "" ]; then
      echo "${IP},root," >> /var/tmp/monitor/NFS_User_Info
    fi
  done
}

check_cmd()
{
  if [ -f "/raid/data/tmp/cmdscript" ];then
    sh /raid/data/tmp/cmdscript
    end_time=`date "+%Y%m%d_%H%M%S"`
    mv /raid/data/tmp/cmdscript "/raid/data/tmp/cmdscript.${end_time}"
  fi
}


##################################################################
#
#  Finally, exec main code
#
##################################################################
fanDefination

while true
do
  State_Info
  
  #CPU_Info
  Service_Info
  #Memory_Info
  Samba_User_Info
  AFP_User_Info
  FTP_User_Info
  NFS_User_Info
  Disk_Info
  Fan_Info
  Network_Info

  cd /tmp/monitor
  #cat CPU_Info > System_Info_
  cat Service_Info >> System_Info_
  #cat Memory_Info >> System_Info_
  cat Samba_User_Info >> System_Info_
  cat AFP_User_Info >> System_Info_
  cat FTP_User_Info >> System_Info_
  cat NFS_User_Info >> System_Info_
  cat Disk_Info >> System_Info_
  cat Fan_Info >> System_Info_ 2>/dev/null
  cat Temp_Info >> System_Info_ 2>/dev/null
  cat Network_Info >> System_Info_
  mv System_Info_ System_Info
  
  check_cmd
  
  sleep 7

done

