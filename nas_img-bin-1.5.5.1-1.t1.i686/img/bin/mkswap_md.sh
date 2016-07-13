#!/bin/sh
##############################################
# Format : mkswap_md.sh $swapdisk_count $swapdisks
# Used for create or assemble swap raid
##############################################
mdadm="/sbin/mdadm"
swapmd="/dev/md10"
sleep_sec=2
swapdisk_count=$1
swapdisks=$2
###check swap
total_tray=`/img/bin/check_service.sh total_tray` #sysconf.N16000 total_tray=16  thecus_io MAX_TRAY: 16
for location in 52 78 104 130
do
  if [ -e /dev/sg$location ];then
    total_tray=$(($total_tray+16))
  fi
done

## call to get disk UUID
get_disk_uuid() {
  UUID=`mdadm --examine ${1} 2>/dev/null | awk 'BEGIN{OFS=";";FS=" : "}{if($1~/UUID/ && UUID==""){UUID=$2}if($1~/Raid Level/){TYPE=$2}}END{if(TYPE!="" && UUID!="")print TYPE,UUID}'`
  echo ${UUID}
}

echo "1" > /var/tmp/raidlock

${mdadm} -D ${swapmd}
if [ "$?" = "0" ];then
  #swap exist...add to swap
  swapraid="${mdadm} -a ${swapmd} $swapdisks"
  eval "${swapraid}"
else
  #create or assemble swap
  for i in ${swapdisks}
  do
    uuid=`get_disk_uuid ${i}`
    break
  done

  if [ "${uuid}" = "" ];then
    while [ $swapdisk_count -le $((${total_tray}-1)) ];do
      swapdisks="$swapdisks missing"
      swapdisk_count=$(($swapdisk_count+1))
    done

    swapraid="${mdadm} -C ${swapmd} --assume-clean -f -R -l1 --metadata=1.2 -n$total_tray $swapdisks;"
  else
    swapraid="${mdadm} -A ${swapmd} -f -R $swapdisks;"
  fi
  
  eval "${swapraid}"
  if [ "$?" != "0" ];then
    while [ $swapdisk_count -le $((${total_tray}-1)) ];do
      swapdisks="$swapdisks missing"
      swapdisk_count=$(($swapdisk_count+1))
    done
    swapraid="${mdadm} -C ${swapmd} --assume-clean -f -R -l1 -n$total_tray $swapdisks;"
    eval "${swapraid}"
  fi
  
  inraid_list=`${mdadm} -D $swapmd | awk '/active sync/{print $7}'`
  inraid_list="$inraid_list missing"
  for new_hdd in $swapdisks
  do
    match_pos=` echo $inraid_list |   awk '{match ($0, "'$new_hdd'" ); print RSTART}' `
    if [ "$match_pos" = "0" ];
    then
      addin_hdd="$addin_hdd $new_hdd"
    fi
  done
  if [ "${addin_hdd}" != "" ];then
    swapraid="${mdadm} -a ${swapmd} $addin_hdd;"
    eval "${swapraid}"
  fi
  
  /sbin/mkswap ${swapmd}
  chmod 600 ${swapmd}
  /sbin/blockdev --setra 4096 ${swapmd}
  /sbin/swapon ${swapmd}
fi

sync

echo "0" > /var/tmp/raidlock
