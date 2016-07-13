#!/bin/sh 
. /img/bin/ha/script/conf.ha
. /img/bin/ha/script/func.ha

raid_st0=1
raid_df0=`df -h | awk '/\/raid60$/&&/^\/dev\/md60 /{print $3}'`
raid_df_count=0

while [ -f /tmp/ha_role ]
do
  echo "`date`-ha_stat" >> ${HA_STAT_LOG}
  echo "`cat /tmp/ha_role`" >> ${HA_STAT_LOG}
  if [ "`cat /tmp/ha_role`" = "active" ];then
    echo "`date`-stat_raid" >> ${HA_STAT_LOG}

    if [ -f /tmp/ha_rebuild_flag ];then
      if [ "`cat /tmp/ha_rebuild_flag`" = "wait" ];then
        /img/bin/ha/script/raid.sh rebuild init
        echo ok > /tmp/ha_rebuild_flag
        sleep 60
      else
        rm -f /tmp/ha_rebuild_flag
      fi
    fi
    
    raid_st1=`cat /tmp/raid6[0-9]/rss | grep -cv Healthy`
    if [ "${raid_st1}" = "0" ];then
      raid_st1=`cat /tmp/raid6[0-9]/ha_rss | grep -c Degrade`
    fi
    
    if [ "${raid_st1}" = "0" ] && [ -f /tmp/ha_raid_damaged ];then
      rm /tmp/ha_raid_damaged
    fi
    
    raid_df1=`df -h | awk '/\/raid60$/&&/^\/dev\/md60 /{print $3}'`
    if [ "${raid_df1}" != "${raid_df0}" ];then
      raid_df0=${raid_df1}
      raid_df_count=`expr $raid_df_count + 1`
      if [ $raid_df_count -gt 6 ];then
        raid_df_count=0
        cat /proc/mdstat > /tmp/mdstat
        stat_raid > /tmp/ha_status_tmp
        mv /tmp/ha_status_tmp /var/tmp/www/ha_status
      fi
    fi

    if [ "${raid_st1}" != "0" ] || [ "${raid_st0}" != "${raid_st1}" ] || [ "`cat /tmp/www/ha_status`" = "" ] || [ "`cat /tmp/www/ha_status | grep -c Finish\|1\|1`" != "2" ];then 
      cat /proc/mdstat > /tmp/mdstat
      stat_raid > /tmp/ha_status_tmp
      mv /tmp/ha_status_tmp /var/tmp/www/ha_status
    
      if [ "`cat /tmp/mdstat | grep -c 'recovery ='`" != "0" ] || [ "`cat /tmp/mdstat | grep -c 'resync ='`" != "0" ];then
        if [ "`cat /proc/sys/vm/drop_caches`" != "3" ];then
          echo 3 > /proc/sys/vm/drop_caches
        fi
      else
        if [ "`cat /proc/sys/vm/drop_caches`" != "0" ];then
          echo 0 > /proc/sys/vm/drop_caches
        fi
      fi

      stat_line
      if [ "`cat /tmp/ha_role`" = "active" ];then
        if [ ! -f /var/lock/ha_st_lock ] && [ "`cat /var/tmp/www/ha_network | grep -c '^[01]|0|[01]|'`" = '1' ];then
          if [ "`cat /proc/scsi/scsi|grep -c 'Model:IBLOCK'`" = "1" ] && [ "`iscsiadm -m session|grep -c ${ipx3}:3260,1`" != "1" ];then
            discovery=`iscsiadm -m discovery -tst --portal ${ipx3}:3260 2>/dev/null|awk "/${ipx3}:3260/&&/nas:iscsi.ha/{print 1}"`
            if [ "${discovery}" = "1" ];then
              ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} start s
            fi
          fi
        fi
      fi
    fi
    raid_st0=${raid_st1}
  else
    if [ -f /var/tmp/www/ha_status ];then
      rm /var/tmp/www/ha_status
    fi
    stat_line
  fi
  if [ -f /tmp/www/disable_nas_ftpd ];then
    nas_ftpd stop
    rm /tmp/www/disable_nas_ftpd
  fi
  echo "`date`-stat_log" >> ${HA_STAT_LOG}
  stat_log
  sleep 10
done
