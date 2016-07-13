#!/bin/sh
###############################################################
#
# This is for volume encryption.
# Check USB Disk can Mount and Writable
# 
###############################################################
#led_light="/img/bin/model/led_light.sh"
mkdir="/bin/mkdir -p"
usbpath="/mnt/usb"
mount_point=""
max_key=5
key_time=`date +%Y%m%d_%H%M%S`
file_name=".tmp_${key_time}"
usb_mount="/raid/data/USBHDD"
export LD_LIBRARY_PATH=/opt/lib64
ntfs_3g="/usr/bin/ntfs-3g"
esata_tray=`/img/bin/check_service.sh esata`
esata_count=`/img/bin/check_service.sh esata_count`

USB_TRAY=${esata_tray}
while [ ${esata_count} -gt 0 ]
do
  USB_TRAY=`expr ${USB_TRAY} + 1`
  esata_count=`expr ${esata_count} - 1`
done

function mount_usbdisk(){

  strExec="cat /proc/scsi/scsi|awk  '/Intf:USB/{FS=\" \";printf(\"%s:%s\n\",\$2,\$3)}'|awk -F: '{printf(\"%s\n\",\$4)}'"
  normal=`eval ${strExec}`

  if [ "${normal}" == "" ];
    then
      echo "No USB device be detected!" >> /tmp/encr_start.tmp
      exit -1
  fi
  for i in $normal
  do
    strExec="cat /proc/partitions|awk '/${i}$|${i}[0-9]/{FS=\" \";print \$4}'"
    mount_usbs=`eval ${strExec}` 
    for mount_usb in $mount_usbs
    do
      #################################################################
      #   create folder
      #################################################################
      chkmount=$(mount|grep "/dev/$mount_usb ")
      if [ "${chkmount}" == "" ];
      then
        ${mkdir} "${usbpath}/${mount_usb}"
        chown -R nobody:nogroup "${usbpath}/${mount_usb}"
        #${led_light} Copy 1 > /dev/null 2>&1 
        /bin/mount -o utf8,umask=0,fmask=001,uid=99,gid=99 "/dev/${mount_usb}" "${usbpath}/${mount_usb}"
        if [ $? -eq 0 ]; then
          mount_path="\/dev\/${mount_usb}"
          fs_type=`/bin/mount | awk -F" " '/'$mount_path'/{printf($5)}'`
          if [ "$fs_type" == "vfat" ] || [ "$fs_type" == "ntfs" ] || [ "$fs_type" == "msdos" ] || [ "$fs_type" == "fat" ]; then
            #/bin/umount /dev/${tmp1}${j}
            #sleep 1
            if [ "$fs_type" == "vfat" ] || [ "$fs_type" == "msdos" ];then
              /bin/mount -o remount,utf8,umask=0,fmask=001,uid=99,gid=99,shortname=mixed "/dev/${mount_usb}" "${usbpath}/${mount_usb}"
            elif [ "$fs_type" == "ntfs" ]; then
              /bin/umount /dev/${mount_usb}
              sleep 1
              ${ntfs_3g} "/dev/${mount_usb}" "${usbpath}/${mount_usb}" -o umask=0,fmask=001,uid=99,gid=99
              if [ "$?" != "0" ]; then
                /bin/mount -o remount,utf8,umask=0,fmask=001,uid=99,gid=99 "/dev/${mount_usb}" "${usbpath}/${mount_usb}"
              fi
            else
              /bin/mount -o remount,utf8,umask=0,fmask=001,uid=99,gid=99 "/dev/${mount_usb}" "${usbpath}/${mount_usb}"
            fi
          fi
        fi
      fi
      mount_ok=$(mount|grep "/dev/$mount_usb ")
      if [ "${mount_ok}" == "" ];
      then
        rm -rf "${usbpath}/${mount_usb}"
      else
        break
      fi
    done
    if [ "${mount_ok}" != "" ];then
     mount_point="${usbpath}/${mount_usb}"
     break
    fi
  done
}


function get_usbdisk(){
  str_exec="df|awk -F' ' '/\/data\/USBHDD/{print \$6}' | awk -F/ '{print \$5}'"
  mount_usbhdd=`eval "$str_exec"`
  if [ "$mount_usbhdd" != "" ];then
    for i in $mount_usbhdd
    do
      usb_device="${i}"
      mount_point="$usb_mount/${i}"
      mount_ok="$usb_mount/${i}"
      break
    done
  else
    mount_usbdisk
  fi
}

function umount_usbdisk(){
  str_exec="df|awk -F' ' '/\/mnt\/usb/{print substr(\$1,6)}'"
  mount_usbhdd=`eval "$str_exec"`
  for i in $mount_usbhdd
  do
    if [ "${i}" != "" ];
    then
      umount -f "/dev/${i}"
    fi
  done
}

get_usbdisk

if [ "${mount_ok}" == "" ];then
echo "Can't get a writable usb key!!" >> /tmp/encr_start.tmp
exit -1
fi

# Just make sure file name won't duplicate, try same time with 5 keys.
while [ -e $mount_point/${file_name}.key ] && [ ${file_retry} -lt $max_key ] ;
do
  file_name="${file_name}${file_retry}"
  file_retry=`expr $file_retry + 1`
done

# Create random key file
head -c 3705 /dev/urandom | uuencode -m - | head -n 66 | tail -n 65 >  $mount_point/$file_name.key

key_retry=0
while [ ! -e $mount_point/$file_name.key ] && [ ${key_retry} -lt $max_key ];
do
  sync
  key_retry=`expr $key_retry + 1`
  sleep 3
done

# Can't get usb key file
if [ ! -e $mount_point/$file_name.key ];then
  echo "Can't get a writable usb key!!" >> /tmp/encr_start.tmp
  exit -1
fi

echo "1"
rm $mount_point/$file_name.key
umount_usbdisk
