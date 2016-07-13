#!/bin/sh
if [ -f /var/tmp/www/burn_log ];
 then
      finish=`cat /var/tmp/www/burn_log|awk -F'|' '{print $3}'`
      if [ "$finish" == "100" ];then
             exit
      fi
fi      
logevent="/img/bin/logevent/event"
killall -9 burn_cd.sh
killall -9 cdrecord
killall -9 dvd+rw-format
genisoimage_count=`ps wwww | grep genisoimage|grep -v grep|wc -l`
flag_iso="" 
if [ $genisoimage_count -gt 0 ];then
   data1=`ps wwww | grep genisoimage|awk -F'-o' '{print $2}'`
   data2=`echo "$data1" |awk -F'-graft-points' '{print $1}'`
   data3=`echo $data2`
   if [ -f "$data3" ];then
       if [ "$data3" != "/raid/data/tmp/image.iso" ];then
             flag_iso="1"
             rm -rf "$data3"
       fi
   fi
fi   
killall -9 genisoimage
killall -9 growisofs
if [ -d /raid/data/tmp/aaa ];then
   umount /raid/data/tmp/aaa 2>&1
   rm -rf /raid/data/tmp/aaa 2>&1
fi
if [ -d /raid/data/tmp/bbb ];then
   umount /raid/data/tmp/bbb 2>&1
   rm -rf /raid/data/tmp/bbb 2>&1
fi
killall -9 isovfy 
rm -rf /raid/data/tmp/image.iso
if [ "$flag_iso" == "1" ];then
  ${logevent} 997 487 info ""
else
  ${logevent} 997 484 info ""
fi  
                                            
