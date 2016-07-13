#!/bin/sh
PATH="$PATH:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin"
mkdir="/bin/mkdir"
rmdir="rm -rf"
export LD_LIBRARY_PATH=/usr/lib
ntfs_3g="/usr/bin/ntfs-3g"

[ -d /raid/sys ] || exit
[ -d /raid/data ] || exit

[ -f /tmp/eject ] && rm /tmp/eject

checkesata(){
  esata=` mount |grep "$tmp"`
}

add_esata(){
  partition=`cat /proc/partitions | awk '/'${tmp1}'$|'${tmp1}'[0-9]/{FS=" ";print $4}'| awk -F$tmp1 '{print "'$tmp1'"$2}'`
  for j in $partition
  do 
    src=${j}
    if [ $j = $tmp1 ];then
      des="${tmp}"
    else
      part=`echo $j | awk -F$tmp1 '{print $2}'`
      des="${tmp}/${part}"
    fi
    $mkdir -p /raid/data/eSATAHDD/${des}
    /bin/mount -o utf8,umask=0,fmask=001,uid=99,gid=99 /dev/${src} /raid/data/eSATAHDD/${des}
    if [ $? -eq 0 ]; then
      mount_path="\/dev\/${src}"
      fs_type=`/bin/mount | awk -F" " '/'$mount_path'/{printf($5)}'`
      if [ "$fs_type" == "vfat" ] || [ "$fs_type" == "ntfs" ] || [ "$fs_type" == "msdos" ] || [ "$fs_type" == "fat" ]; then
        #/bin/umount /dev/${src}
        #sleep 1
        if [ "$fs_type" == "vfat" ] || [ "$fs_type" == "msdos" ];then
          /bin/mount -o remount,utf8,umask=0,fmask=001,uid=99,gid=99,shortname=mixed /dev/${src} /raid/data/eSATAHDD/${des}
        elif [ "$fs_type" == "ntfs" ]; then
          /bin/umount /dev/${src}
          sleep 1 
          ${ntfs_3g} /dev/${src} /raid/data/eSATAHDD/${des} -o umask=0,fmask=001,uid=99,gid=99
          if [ "$?" != "0" ]; then
            /bin/mount -o remount,utf8,umask=0,fmask=001,uid=99,gid=99 /dev/${src} /raid/data/eSATAHDD/${des}
          fi
        else
          /bin/mount -o remount,utf8,umask=0,fmask=001,uid=99,gid=99 /dev/${src} /raid/data/eSATAHDD/${des}
        fi
      fi
      if [ "$?" = "0" ];then
        flag=1
        setfacl -R -P -b /raid/data/eSATAHDD/${des}
        setfacl -R -P -m other::rwx /raid/data/eSATAHDD/${des}
        setfacl -R -P -d -m other::rwx /raid/data/eSATAHDD/${des}
      fi
    else
      cd /raid/data/eSATAHDD/
      rmdir ${des}
    fi
  done
}

esata_tray=`/img/bin/check_service.sh esata`
esata_count=`/img/bin/check_service.sh esata_count`
md_hd_list=`cat /proc/scsi/scsi | sort -u |awk "/ Tray:${esata_tray}/{print \\\$3}" | cut -d":" -f2`

while [ ${esata_count} -gt 1 ]
do
  esata_tray=`expr ${esata_tray} + 1`
  md_hd_list=$md_hd_list" "`cat /proc/scsi/scsi |awk "/ Tray:${esata_tray}/{print \\\$3}" | cut -d":" -f2`
  esata_count=`expr ${esata_count} - 1`
done

[ -f /raid/sys/acl_esata ] || getfacl /raid/data/eSATAHDD > /raid/sys/acl_esata

for md_hd in $md_hd_list
do
  tray_id=`cat /proc/scsi/scsi |awk "/Disk:${md_hd} /{print \\\$2}" | cut -d":" -f2`
  tmp="esata"`expr ${tray_id} - ${esata_tray} + 1`
  tmp1=$md_hd
  
  checkesata
  if [ "$esata" != "" ];then
    break
  fi
  add_esata
done

