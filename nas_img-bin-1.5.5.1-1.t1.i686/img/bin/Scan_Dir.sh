#!/bin/sh
Scan_Dir_start() {
    . /img/bin/function/libraid
    local Lmaster_raid=`Lraid_get_master_raid`
    local Lmaster_id=`echo "${Lmaster_raid}" | awk '{print substr($0,5)}'`
    local fRaidIdList=`Lraid_check_raid_exist $Lmaster_id`
    if [ $fRaidIdList == "1" ];
    then
        return;
    fi
    devicedata=`find /sys -name sr*|grep $1`
    while [ "$devicedata" == "" ]
    do
       sleep 1
       devicedata=`find /sys -name sr*|grep $1`
    done
    folder_count=`echo "$devicedata" | awk -F'/' '{print NF}'`
    strExec=`echo $devicedata | awk -F'/' '{tray='$folder_count';{print $tray}}' `
    strExec=`echo $strExec`
    check_data=`/img/bin/burn_cd.sh check|grep $strExec`
    Vendor=`echo $check_data|awk -F'|' '{print $1}'`
    Model=`echo $check_data|awk -F'|' '{print $2}'`
    if [ ! -d "/raid/data/USBHDD/CD" ];then
       mkdir /raid/data/USBHDD/CD
    fi
    chown nobody.nogroup /raid/data/USBHDD/CD
    Prepare_Data=`eval "echo /raid/data/USBHDD/CD/$Vendor $Model"`
    flag=`ls "$Prepare_Data"|grep "$Vendor $Model"|wc -l`
    count=$((flag+1))
    Data=`eval "echo /raid/data/USBHDD/CD/$Vendor $Model[$count]"`
    Data1=`eval "echo $Vendor $Model[$count]"`
    mkdir "$Data"
    chown nobody.nogroup "$Data"  
    eval "/usr/bin/auto-eject-cdrom /dev/$strExec $1 -VM '$Data1' &"
}
Scan_Dir_stop(){
       process_count=`ps www|grep $1|grep -v grep|grep -v Scan_Dir.sh|wc -l`
       process_id=`ps www|grep $1|grep -v grep|grep -v Scan_Dir.sh|awk -F' ' '{print $1}'`
       Vendor_Model=`ps www|grep $1|grep -v grep|grep -v Scan_Dir.sh|awk -F'-VM' '{print $2}'`
       if [ $process_count == 0 ];then
          return
       fi
       kill -9 $process_id
       Vendor_Model=`echo $Vendor_Model`
       Data=`eval "echo /raid/data/USBHDD/CD/$Vendor_Model"`
       flag=`ls $Data|grep "$Vendor_Model"|wc -l`
       echo $flag
       if [ $flag > 0 ];then
          umount "$Data"
          rmdir "$Data"
       fi
}
case "$1" in
'start')
    Scan_Dir_start $2
    ;;
'stop')
    Scan_Dir_stop $2
    ;;
*)
    exit 1
    ;;
esac
