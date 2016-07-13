#!/bin/sh
act=$1
disk_name=$2
logevent="/img/bin/logevent/event"
mdadm="/sbin/mdadm"
iscsi_list=`cat /proc/scsi/scsi | grep "Intf:iSCSI" | cut -d":" -f4 | cut -d" " -f1`

## call to get disk UUID
get_uuid() {
  UUID=`mdadm --examine /dev/${1}2 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/Device UUID/ && UUID==""){UUID=$2}}END{print UUID}'`
  echo ${UUID}
}

sleeped=0
while [ "$ProviderName" = "" ]
do
  connect_list=`ls /tmp/hv_client/connect/`
  for connect in ${connect_list}
  do
    if [ $disk_name = "`cat /tmp/hv_client/connect/$connect | awk -F\| '{print $4}'`" ];then
      ProviderName="`cat /tmp/hv_client/connect/$connect | awk -F\| '{print $6}'`"
      IP=$connect
      break
    fi
  done
  if [ $sleeped -ge 20 ];then
    break
  fi
  sleeped=$(($sleeped+5))
  sleep 5
done
  
if [ "${act}" = "add" ];then
  check_active=`sqlite /etc/cfg/conf.db "select v from conf where k='hv_enable'"`
  if [ ! "${check_active}" = "1" ];then
    exit
  fi
  
  ${logevent} 997 806 info email "$ProviderName" "$IP"

  if [ `cat /proc/mdstat | grep -c "${disk_name}[2-3]\["` -ge 1 ];then
    echo "md have $disk_name, return" >> /tmp/hv_disk.log
    exit
  fi
  
  echo "add $disk_name" >> /tmp/hv_disk.log
  sh -x /img/bin/rc/rc.hv HugeVolume_start > /tmp/HugeVolume_start_log 2>&1
  
  #HV_check=1
  #volume_list=`cat /proc/mdstat | awk -F: '/^md1[1-9] :/{print substr($1,3)}' | sort -u`
  #for volumenum in $volume_list
  #do
  #  cat /raidsys/$volumenum/HVuuid | while read uuid
  #  do
  #    got_member=0
  #    for i in $iscsi_list
  #    do
  #      if [ "$uuid" = "`get_uuid ${i}`" ];then
  #        got_member=1
  #        break
  #      fi
  #    done
  #    if [ $got_member -eq 0 ];then
  #      HV_check=0
  #      exit
  #    fi
  #  done
  #done
  
  #if [ $HV_check -eq 1 ];then
  #  /img/bin/rc/rc.hv HugeVolume_start
  #fi
elif [ "${act}" = "remove" ];then  
  if [ `cat /proc/mdstat | grep -c "${disk_name}[2-3]\["` -eq 0 ];then
    echo "md dont have $disk_name, exit" >> /tmp/hv_disk.log
    exit
  fi
  if [ "`tail -n 1 /tmp/hv_disk.log`" = "remove $disk_name" ];
  then
    exit
  fi

  ${logevent} 997 807 warning email "$ProviderName" "$IP"
  echo "remove $disk_name" >> /tmp/hv_disk.log
  if mkdir /tmp/HVlock; then
    sh -x /img/bin/rc/rc.hv HugeVolume_stop > /tmp/HugeVolume_stop_log 2>&1
    rmdir /tmp/HVlock
  fi
  /img/bin/rc/rc.hv logout ${disk_name}

elif [ "${act}" = "update" ];then
  md_num=$disk_name
  
  echo 1 > /raidsys/".($md_num)."/HugeVolume

fi
