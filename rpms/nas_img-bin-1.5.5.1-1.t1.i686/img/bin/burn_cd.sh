#!/bin/sh
logevent="/img/bin/logevent/event"
PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

umount_data(){
   flag=`df -k|grep $1|wc -l`
   mount_data=`df -k|grep $1`
   before_mount=`echo $mount_data|awk -F' ' '{print $5}'`
   before_mount=`echo $before_mount`
   mount_item="echo $mount_data|awk -F'$before_mount' '{print \$2}'"
   mount_item=`eval "$mount_item"`
   mount_item=`echo $mount_item`
   if [ $flag == 1 ];then
      umount "$mount_item"
   fi
}
                                   
diff(){
   if [ "$3" == "6121" ];then
     echo "06|01|90|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "6122" ];then
     echo "06|01|95|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "6221" ];then
     echo "06|02|88|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "6222" ];then
        echo "06|02|94|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "7121" ];then
     echo "07|01|88|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "7122" ];then
        echo "07|01|94|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "7221" ];then
     echo "07|02|83|verify_start" > /var/tmp/www/burn_log
   fi
   if [ "$3" == "7222" ];then
     echo "07|02|91|verify_start" > /var/tmp/www/burn_log
   fi
   isovfy dev=$1 > /tmp/isovfy.log 2>&1
   check_error="0"
   while [ 1 ];do
        count=`ps | grep -c "[i]sovfy"`
        if [ $count == 0 ];then
              break;
        fi
    done
    isoerror=`cat /tmp/isovfy.log | grep "No errors found" | wc -l`
    rm -rf /tmp/isovfy.log
    if [ $isoerror == 0 ];then
          echo "102|md5_error" > /var/tmp/www/burn_log
          ${logevent} 997 801 error ""
          return
    fi
    echo "06|01|100|verify_end" > /var/tmp/www/burn_log
}
desc_space(){
   Totalsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
   echo "$Totalsize"
}
iso_disc(){
   blankflag=0
   ${logevent} 997 475 info ""
   isoformatcheck=`isoinfo -i "$2"`
   if [ "$isoformatcheck" != "" ];then
         echo "102|Isoformat_error" > /var/tmp/www/burn_log
         return
   fi
   umount_data $1
   file=`cdrecord -v dev=$1 -prcap 2>&1 | grep 'Current:'`
   DeviceType=`echo $file|awk -F'Current:' '{print $2}'`
   DeviceType=`echo $DeviceType|sed 's/sequential recording//g'|sed 's/restricted  overwrite//g'`
   if [ "$DeviceType" == "none" ];then
      echo "102|disc_empty" > /var/tmp/www/burn_log
      return
   fi
   RWFLAG=`echo $file| grep RW|wc -l`
   DataBlankFlag=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Blank'|wc -l`
   if [ $RWFLAG == 1 ];then
     if [ $DataBlankFlag == 0 ];then
         blank_data $1
         blankflag=1
     fi
    else
     if [ $DataBlankFlag == 0 ];then
       echo "102|RW_error" > /var/tmp/www/burn_log
       return
     fi
                                 
   fi
   CDFLAG=`echo $file| grep CD|wc -l`
   DVDFLAG=`echo $file| grep DVD|wc -l`
   BDFLAG=`echo $file| grep BD|wc -l`
   DVDMINUS=`echo $file| grep DVD-RW|wc -l`
   DVDPLUS=`echo $file| grep DVD+RW|wc -l`
   if [ $CDFLAG == 1 ] || [ $BDFLAG == 1 ];then
       Totalsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
       ISOFilesize=`ls -l "$2" |awk -F' ' '{print $5}'`
       echo $Totalsize $ISOFilesize > /tmp/iso_disc
       if [ $ISOFilesize -gt $Totalsize ];then
          echo "102|size_error" > /var/tmp/www/burn_log
          return
       fi       
       if [ "$4" != "0" ];then
           if [ "$3" == "0" ];then
              if [ $blankflag == 0 ];then
                cdrecord -v dev=$1 step=7111 speed=$4 "$2"
               else
                cdrecord -v dev=$1 step=7112 speed=$4 "$2"
              fi  
            else
              if [ $blankflag == 0 ];then
                cdrecord -v dev=$1 step=7121 speed=$4 "$2"
               else
                cdrecord -v dev=$1 step=7122 speed=$4 "$2" 
              fi   
              if [ -f /var/tmp/www/burn_log ];
               then
                  checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
                  if [ "$checkflag" != "102" ];then
                     if [ $blankflag == 0 ];then
                       diff $1 "$2" "7121"
                      else
                       diff $1 "$2" "7122"
                     fi 
                  fi
              fi   
           fi 
        else
           if [ "$3" == "0" ];then
             if [ $blankflag == 0 ];then
                   cdrecord -v dev=$1 step=7111 "$2"
              else
                   cdrecord -v dev=$1 step=7112 "$2" 
             fi      
            else
              if [ $blankflag == 0 ];then
                   cdrecord -v dev=$1 step=7121 "$2"
               else
                   cdrecord -v dev=$1 step=7122 "$2"
              fi     
              if [ -f /var/tmp/www/burn_log ];
               then
                  checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
                  if [ "$checkflag" != "102" ];then
                     if [ $blankflag == 0 ];then 
                       diff $1 "$2" "7121"
                      else
                       diff $1 "$2" "7122" 
                     fi 
                  fi
              fi    
           fi  
       fi
   fi
   if [ $DVDFLAG == 1 ];then
       if [ $DVDMINUS == 1 ];then
         discsize=`dvd+rw-mediainfo $1 | grep 'Legacy lead-out at:'|awk -F'=' '{print $2}'`
        else
          if [ $DVDPLUS == 1 ];then
             discsize=`dvd+rw-mediainfo $1 | grep 'formatted:'|awk -F'=' '{print $2}'`
           else
             discsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
          fi
       fi   
       ISOFilesize=`ls -l "$2" |awk -F' ' '{print $5}'`
       if [ $ISOFilesize -gt $discsize ];then
            echo "102|size_error" > /var/tmp/www/burn_log
            return
       fi
       if [ "$4" != "0" ];then
          if [ "$3" == "0" ];then
            if [ $blankflag == 0 ];then
              growisofs -dvd-compat -use-the-force-luke=notray -step=7211 -Z $1="$2" -speed=$4
             else
              growisofs -dvd-compat -use-the-force-luke=notray -step=7212 -Z $1="$2" -speed=$4
            fi  
           else
            if [ $blankflag == 0 ];then
              growisofs -dvd-compat -use-the-force-luke=notray -step=7221 -Z $1="$2" -speed=$4
             else
              growisofs -dvd-compat -use-the-force-luke=notray -step=7222 -Z $1="$2" -speed=$4
            fi   
            if [ -f /var/tmp/www/burn_log ];
             then 
              checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
              if [ "$checkflag" != "102" ];then
                 if [ $blankflag == 0 ];then
                      diff $1 "$2" "7221"
                 else
                      diff $1 "$2" "7222"
                 fi 
              fi
            fi
          fi  
       else
          if [ "$3" == "0" ];then
            if [ $blankflag == 0 ];then
               growisofs -dvd-compat -use-the-force-luke=notray -step=7211 -Z $1="$2"
            else
               growisofs -dvd-compat -use-the-force-luke=notray -step=7212 -Z $1="$2"
            fi    
           else
            if [ $blankflag == 0 ];then
               growisofs -dvd-compat -use-the-force-luke=notray -step=7221 -Z $1="$2"
            else
               growisofs -dvd-compat -use-the-force-luke=notray -step=7222 -Z $1="$2"
            fi    
            if [ -f /var/tmp/www/burn_log ];
             then
              checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
              if [ "$checkflag" != "102" ];then
                 if [ $blankflag == 0 ];then
                  diff $1 "$2" "7221"
                 else
                  diff $1 "$2" "7222"
                 fi  
              fi
            fi
          fi
       fi
   fi
   eject $1
   ${logevent} 997 476 info ""

}
iso_burn(){
   ${logevent} 997 477 info ""
   cat /tmp/genisoimage.txt|sed 's/`/\\`/g' > /tmp/genisoimage1.txt
   cat /tmp/genisoimage1.txt|sed 's/\\\\=/=/g' > /tmp/genisoimage2.txt
   mv /tmp/genisoimage2.txt /tmp/genisoimage.txt
   rm -rf /tmp/genisoimage1.txt
   data=`cat /tmp/genisoimage.txt`
   if [ $3 -ge 4294967295 ];then
     eval "genisoimage -allow-limited-size -joliet-long -hide-rr-moved -r -R -J -l -L -step=80 -input-charset=UTF-8 -V '$1' -o '$2' -graft-points $data"
    else
     eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=80 -input-charset=UTF-8 -V '$1' -o '$2' -graft-points $data"
   fi 
   ${logevent} 997 478 info ""
}
cd_burn(){
    blankflag=0 
    ${logevent} 997 481 info ""
    umount_data $1
    file=`cdrecord -v dev=$1 -prcap 2>&1 | grep 'Current:'`
    DeviceType=`echo $file|awk -F'Current:' '{print $2}'`
    DeviceType=`echo $DeviceType|sed 's/sequential recording//g'|sed 's/restricted  overwrite//g'`
    if [ "$DeviceType" == "none" ];then
     echo "102|disc_empty" > /var/tmp/www/burn_log
     return
    fi
    RWFLAG=`echo $file| grep RW|wc -l`
    DataBlankFlag=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Blank'|wc -l`
    if [ $RWFLAG == 1 ];then
      if [ $DataBlankFlag == 0 ];then
       blank_data $1
       blankflag=1
      fi
     else
     if [ $DataBlankFlag == 0 ];then
      echo "102|RW_error" > /var/tmp/www/burn_log
      return
     fi
    fi
    cat /tmp/genisoimage.txt|sed 's/`/\\`/g' > /tmp/genisoimage1.txt
    cat /tmp/genisoimage1.txt|sed 's/\\\\=/=/g' > /tmp/genisoimage2.txt
    mv /tmp/genisoimage2.txt /tmp/genisoimage.txt
    rm -rf /tmp/genisoimage1.txt       
    data=`cat /tmp/genisoimage.txt`
    rm /raid/data/tmp/image.iso
    CDFLAG=`echo $file| grep CD|wc -l`
    DVDFLAG=`echo $file| grep DVD|wc -l`
    BDFLAG=`echo $file| grep BD|wc -l`
    DVDMINUS=`echo $file| grep DVD-RW|wc -l`
    DVDPLUS=`echo $file| grep DVD+RW|wc -l`
    CDMINUS=`echo $file| grep CD-RW|wc -l`
    if [ $CDFLAG == 1 ] || [ $BDFLAG == 1 ];then
      if [ $BDFLAG == 1 ];then
        discsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
        if [ $5 -gt $discsize ];then
             echo "102|size_error" > /var/tmp/www/burn_log
             return
        fi
      else
         if [ $CDFLAG == 1 ];then
             if [ $CDMINUS == 1 ];then
                  if [ $5 -gt 838860800 ];then
                       echo "102|size_error" > /var/tmp/www/burn_log
                       return
                  fi
              else
                  discsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
                  if [ $5 -gt $discsize ];then
                       echo "102|size_error" > /var/tmp/www/burn_log
                       return
                  fi
             fi
         fi
      fi   
      if [ "$3" == "0" ];then
        if [ $blankflag == 0 ];then
          if [ $5 -ge 4294967295 ];then
             eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6111 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          else
             eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6111 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          fi
        else
          if [ $5 -ge 4294967295 ];then
             eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6112 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          else
             eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6112 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          fi   
        fi  
      else
        if [ $blankflag == 0 ];then
          if [ $5 -ge 4294967295 ];then
             eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6121 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          else
             eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6121 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          fi   
        else
          if [ $5 -ge 4294967295 ];then
             eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6122 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          else
             eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6122 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          fi   
        fi  
      fi
      Totalsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
      ISOFilesize=`ls -l /raid/data/tmp/image.iso |awk -F' ' '{print $5}'`
      if [ $ISOFilesize -gt $Totalsize ];then
         echo "102|size_error" > /var/tmp/www/burn_log
         return
      fi
      if [ "$4" != "0" ];then
         if [ "$3" == "0" ];then
           if [ $blankflag == 0 ];then 
             cdrecord -v dev=$1 step=6111 speed=$4 /raid/data/tmp/image.iso
           else
             cdrecord -v dev=$1 step=6112 speed=$4 /raid/data/tmp/image.iso
           fi    
          else
           if [ $blankflag == 0 ];then
             cdrecord -v dev=$1 step=6121 speed=$4 /raid/data/tmp/image.iso
           else
             cdrecord -v dev=$1 step=6122 speed=$4 /raid/data/tmp/image.iso
           fi  
           if [ -f /var/tmp/www/burn_log ];
              then
                checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
                if [ "$checkflag" != "102" ];then
                   if [ $blankflag == 0 ];then
                      diff $1 /raid/data/tmp/image.iso "6121"
                    else
                      diff $1 /raid/data/tmp/image.iso "6122"
                   fi   
                fi
           fi     
         fi
       else
        if [ "$3" == "0" ];then
          if [ $blankflag == 0 ];then 
            cdrecord -v dev=$1 step=6111 /raid/data/tmp/image.iso
           else
            cdrecord -v dev=$1 step=6112 /raid/data/tmp/image.iso
          fi  
         else
          if [ $blankflag == 0 ];then
            cdrecord -v dev=$1 step=6121 /raid/data/tmp/image.iso
           else
            cdrecord -v dev=$1 step=6122 /raid/data/tmp/image.iso
          fi  
          if [ -f /var/tmp/www/burn_log ];
             then
               checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
               if [ "$checkflag" != "102" ];then
                    if [ $blankflag == 0 ];then
                      diff $1 /raid/data/tmp/image.iso "6121"
                    else
                      diff $1 /raid/data/tmp/image.iso "6122"
                    fi  
               fi
          fi
        fi
      fi
    fi
    if [ $DVDFLAG == 1 ];then
      if [ $DVDMINUS == 1 ];then
         discsize=`dvd+rw-mediainfo $1 | grep 'Legacy lead-out at:'|awk -F'=' '{print $2}'`
         if [ $5 -gt $discsize ];then
              echo "102|size_error" > /var/tmp/www/burn_log
              return
         fi
      else
           if [ $DVDPLUS == 1 ];then
                discsize=`dvd+rw-mediainfo $1 | grep 'formatted:'|awk -F'=' '{print $2}'`
                if [ $5 -gt $discsize ];then
                     echo "102|size_error" > /var/tmp/www/burn_log
                     return
                fi
             else
               discsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
               if [ $5 -gt $discsize ];then
                    echo "102|size_error" > /var/tmp/www/burn_log
                    return
               fi
           fi                                                                  
      fi
      if [ "$3" == "0" ];then
        if [ $blankflag == 0 ];then
         if [ $5 -ge 4294967295 ];then
            eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6211 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
         else
            eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6211 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
         fi   
        else
         if [ $5 -ge 4294967295 ];then 
            eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6212 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
         else
            eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6212 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
         fi   
        fi  
      else
        if [ $blankflag == 0 ];then
          if [ $5 -ge 4294967295 ];then
             eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6221 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          else
             eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6221 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
          fi   
        else
           if [ $5 -ge 4294967295 ];then
             eval "genisoimage -joliet-long -allow-limited-size -hide-rr-moved -r -R -J -l -L -step=6222 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
           else
             eval "genisoimage -joliet-long -hide-rr-moved -r -R -J -l -L -step=6222 -input-charset=UTF-8 -V '$2' -o /raid/data/tmp/image.iso -graft-points $data"
           fi  
        fi    
      fi
      ISOFilesize=`ls -l /raid/data/tmp/image.iso |awk -F' ' '{print $5}'`
      if [ $ISOFilesize -gt $discsize ];then
            echo "102|size_error" > /var/tmp/www/burn_log
            return
      fi
                            
      if [ "$4" != "0" ];then
           if [ "$3" == "0" ];then
             if [ $blankflag == 0 ];then
               growisofs -dvd-compat -use-the-force-luke=notray -step=6211 -Z $1=/raid/data/tmp/image.iso -speed=$4
             else
               growisofs -dvd-compat -use-the-force-luke=notray -step=6212 -Z $1=/raid/data/tmp/image.iso -speed=$4
             fi 
            else
             if [ $blankflag == 0 ];then
               growisofs -dvd-compat -use-the-force-luke=notray -step=6221 -Z $1=/raid/data/tmp/image.iso -speed=$4
             else
               growisofs -dvd-compat -use-the-force-luke=notray -step=6222 -Z $1=/raid/data/tmp/image.iso -speed=$4
             fi   
             if [ -f /var/tmp/www/burn_log ];
              then
                  checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
                  if [ "$checkflag" != "102" ];then
                     if [ $blankflag == 0 ];then
                       diff $1 /raid/data/tmp/image.iso "6221"
                     else
                       diff $1 /raid/data/tmp/image.iso "6222"
                     fi  
                  fi
             fi
           fi
       else
          if [ "$3" == "0" ];then
            if [ $blankflag == 0 ];then
              growisofs -dvd-compat -use-the-force-luke=notray -step=6211 -Z $1=/raid/data/tmp/image.iso
             else
              growisofs -dvd-compat -use-the-force-luke=notray -step=6212 -Z $1=/raid/data/tmp/image.iso 
            fi  
           else
            if [ $blankflag == 0 ];then
              growisofs -dvd-compat -use-the-force-luke=notray -step=6221 -Z $1=/raid/data/tmp/image.iso
             else
              growisofs -dvd-compat -use-the-force-luke=notray -step=6222 -Z $1=/raid/data/tmp/image.iso
            fi  
            if [ -f /var/tmp/www/burn_log ];
             then
                  checkflag=`cat /var/tmp/www/burn_log |awk -F'|' '{print $1}'`
                  if [ "$checkflag" != "102" ];then
                     if [ $blankflag == 0 ];then
                       diff $1 /raid/data/tmp/image.iso "6221"
                     else
                       diff $1 /raid/data/tmp/image.iso "6222"
                     fi  
                  fi
            fi      
          fi
      fi
    fi
    eject $1
    rm /raid/data/tmp/image.iso
    ${logevent} 997 482 info ""
}
cd_desc_to_iso(){
    ${logevent} 997 479 info ""
    Totalsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
    dd if=$1 of=$2 bs=2048 &
    while [ 1 ];do
        if [ -f $2 ];then 
          filesize=`ls -l $2|awk -F' ' '{print $5}'`
          realsize=$((filesize*100/$Totalsize))
          echo "05||$realsize|disk_iso" > /var/tmp/www/burn_log 2>&1
          if [ "$filesize" -ge "$Totalsize" ];then
            break
          fi
          count=`ps | grep "[d]d if"| wc -l`
          if [ "$count" -eq 0 ];then
               break
          fi
        fi  
    done
    echo "05||100|disk_iso" > /var/tmp/www/burn_log 2>&1 
    ${logevent} 997 480 info ""   
}
blank_data(){
      ${logevent} 997 483 info ""
      file=`cdrecord -v dev=$1 -prcap 2>&1 | grep 'Current:'`
      CDFLAG=`echo $file| grep CD|wc -l`
      DVDFLAG=`echo $file| grep DVD|wc -l`
      BDFLAG=`echo $file| grep BD|wc -l`
      if [ $CDFLAG == 1 ];then
        cdrecord -v dev=$1 blank=fast
      fi
      if [ $DVDFLAG == 1 ] || [ $BDFLAG == 1 ];then
        dvd+rw-format -force $1
      fi
      ${logevent} 997 474 info ""
}
cd_speed(){
      file=`cdrecord -v dev=$1 -prcap 2>&1 | grep 'Current:'`
      CDFLAG=`echo $file| grep CD|wc -l`
      DVDFLAG=`echo $file| grep DVD|wc -l`
      BDFLAG=`echo $file| grep BD|wc -l`
      if [ $CDFLAG == 1 ];then
           cdrecord -v dev=$1 -prcap 2>&1 | grep 'Write speed #' | while read file;do
           file1=`echo $file|awk -F'CD' '{print $2}'`
           file2=`echo $file1|awk -F'x,' '{print $1}'`
           echo $file2
           done
      else
          if [ $DVDFLAG == 1 ] || [ $BDFLAG == 1 ];then
               dvd+rw-mediainfo $1 |grep 'Write Speed #' | while read file;do
               file1=`echo "$file"|awk -F'#' '{print $2}'`
               file2=`echo "$file1"|awk -F':' '{print $2}'`
               file3=`echo "$file2"|awk -F'x' '{print $1}'`
               echo $file3
               done
          fi
      fi
      

}
cd_info(){
      DeviceType=`cdrecord -v dev=$1 -prcap 2>&1 | grep 'Current:'|awk -F'Current:' '{print $2}'`
      DeviceType=`echo $DeviceType|sed 's/sequential recording//g'|sed 's/restricted overwrite//g'`
      if [ "$DeviceType" == "none" ];then
           echo "|||"
           return
      fi
      DeviceType=`echo $DeviceType`
      RWFLAG=`echo $DeviceType|grep RW|wc -l`
      CDFLAG=`echo $DeviceType|grep CD|wc -l`
      BDFLAG=`echo $DeviceType|grep BD|wc -l`
      DLFLAG=`echo $DeviceType|grep DL|wc -l`
      BlankFlag=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Blank'|wc -l`
      if [ $CDFLAG != 0 ] || [ $BDFLAG != 0 ];then
        if [ $CDFLAG == 1 ];then
          cdrecord -v dev=$1 -prcap 2>&1 | grep 'Write speed #' | while read file;do
            file1=`echo $file|awk -F'CD' '{print $2}'`
            file2=`echo $file1|awk -F'x,' '{print $1}'`
            file3=`echo $file2",""$file3"`
            echo $file3>/tmp/cd_info
          done
        fi
        if [ $BDFLAG == 1 ];then
         cdrecord -v dev=$1 -prcap 2>&1 | grep 'Write speed #' | while read file;do
            file1=`echo $file|awk -F'BD' '{print $2}'`
            file2=`echo $file1|awk -F'x)' '{print $1}'`
            file3=`echo $file2",""$file3"`
            echo $file3>/tmp/cd_info
          done
        fi 
        file3=`cat /tmp/cd_info`
        Totalsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
        if [ $BlankFlag != 0 ];then
            echo "$DeviceType|0|$Totalsize|$file3"
        else
            if [ $DeviceType != "" ];then
               if [ $RWFLAG == 1 ];then
                 echo "$DeviceType|1||$file3"
                else
                 echo "$DeviceType|2||$file3"
               fi  
            fi
        fi
        else
           dvd+rw-mediainfo $1 |grep 'Write Speed #' | while read file;do
           file1=`echo "$file"|awk -F'#' '{print $2}'`
           file2=`echo "$file1"|awk -F':' '{print $2}'`
           file3=`echo "$file2"|awk -F'x' '{print $1}'`
           file5=`echo $file3",""$file5"`
           echo $file5>/tmp/cd_info
           done
           file5=`cat /tmp/cd_info`
           if [ $DLFLAG == 1 ];then
              Totalsize=`cdrecord -v dev=$1 -minfo 2>&1 | grep 'Total size:'|awk -F'size:' '{print $2}'`
            else
              Totalsize=`dvd+rw-mediainfo $1 2>&1|grep 'Legacy lead-out at:'|awk -F'=' '{print $2}'`
           fi   
           if [ $BlankFlag != 0 ];then
                echo "$DeviceType|0|$Totalsize|$file5"
           else
                if [ "$DeviceType" != "" ];then
                  if [ $RWFLAG == 1 ];then
                     echo "$DeviceType|1||$file5"
                   else
                     echo "$DeviceType|2||$file5"
                  fi
                fi
           fi
      fi
      rm -rf /tmp/cd_info

}
cd_check(){
     count=0
     cat /proc/scsi/scsi | grep Type: | while read file;do
     cdcheck=`echo ${file} | grep CD-ROM | wc -l`
     count=$((count+1))
     if [ $cdcheck = 1 ];
       then
         Lan1=`cat /proc/scsi/scsi | grep Host:|sed -n ${count}p|awk '{print $2}'|awk -F'scsi' '{print $2}'`
         Vendor=`cat /proc/scsi/scsi | grep Vendor:|sed -n ${count}p|awk -F':' '{print $2}'`
         Vendor=`echo $Vendor|sed 's/Model//g'`
         Vendor=`echo $Vendor`
         Model=`cat /proc/scsi/scsi | grep Vendor:|sed -n ${count}p|awk -F':' '{print $3}'`
         Model=`echo $Model|sed 's/Rev//g'`
         Model=`echo $Model`
         Lan2=`cat /proc/scsi/scsi | grep Host:|sed -n ${count}p|awk '{print $4}'`
         Lan2=$((Lan2+0))
         Lan3=`cat /proc/scsi/scsi | grep Host:|sed -n ${count}p|awk '{print $6}'`
         Lan3=$((Lan3+0))
         Lan4=`cat /proc/scsi/scsi | grep Host:|sed -n ${count}p|awk '{print $8}'`
         Lan4=$((Lan4+0))
         LanID=$Lan1:$Lan2:$Lan3:$Lan4
         devicedata=`find /sys -name sr*|grep $LanID`
         folder_count=`echo "$devicedata" | awk -F'/' '{print NF}'`
         strExec=`echo $devicedata | awk -F'/' '{tray='$folder_count';{print $tray}}' `
         strExec=`echo $strExec` 
         echo "$Vendor|$Model|/dev/$strExec"
     fi
     done
}

case "$1" in
'check')
  cd_check
  ;;
'info')
  cd_info $2
  ;;
'speed')
  cd_speed $2
  ;;
'desc_to_iso')
  cd_desc_to_iso $2 $3
  ;;
'burn_cd')
  cd_burn $2 "$3" $4 $5 $6
  ;;
'burn_iso')
  iso_burn "$2" "$3" "$4"
  ;;
'iso_disc')
  iso_disc "$2" "$3" "$4" "$5"
  ;;
'blank_data')
  blank_data $2
  ;;
'diff')
  diff $2 $3 
  ;;
'desc_space')
  desc_space $2
  ;;
*)
  # Default is "start", for backwards compatibility with previous
  # Slackware versions.  This may change to a 'usage' error someday.
  cd_burn
esac
