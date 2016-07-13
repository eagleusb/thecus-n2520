#/bin/sh
dev1=$1
dev2=$2

if [ "$dev2" = "" ] || [ "$dev2" = "NO_DEVICE" ];then
  echo NO_DEVICE
  exit 0
fi

#echo "RAID_UUID $dev1 $dev2" >> /tmp/ha_disk.log

dev1_ruuid=`mdadm -E /dev/${dev1}3 | awk '/Array UUID/{print $4}'`
dev2_ruuid=`mdadm -E /dev/${dev2}3 | awk '/Array UUID/{print $4}'`

if [ "${dev1_ruuid}" = "${dev2_ruuid}" ] || [ "${dev1_ruuid}" = "" ] || [ "${dev2_ruuid}" = "" ] ;then
#  echo "RAID_UUID $dev1_ruuid $dev2_ruuid" >> /tmp/ha_disk.log
  echo ${dev2}
  exit 0
fi

cat /proc/scsi/scsi | awk '/Model:IBLOCK/{gsub("Disk:","",$3);print $3}' | \
while read dev
do
  #echo ${dev}
  if [ "${dev}" = "${dev1}" ];then
    continue
  fi
  
  dev_ruuid=`mdadm -E /dev/${dev}3 | awk '/Array UUID/{print $4}'`

  if [ "${dev_ruuid}" = "${dev1_ruuid}" ];then
    echo ${dev} 
    exit 0
  fi
done
