#!/bin/sh
. /img/bin/ha/script/conf.ha

check_list="/img/bin/ha/script/ha_setting_list"

filename="ha_conf_hw"
htdocs="/tmp/www"
local_setting="${htdocs}/${filename}"
remote_setting="/tmp/${filename}"
ha_enable=`${sqlite} ${cfgdb} "select v from conf where k='ha_enable'"`
ha_role=`${sqlite} ${cfgdb} "select v from conf where k='ha_role'"`

if [ -f "${local_setting}" ];then
  rm "${local_setting}"
fi

function save_setting()
{
  cat "${check_list}" | \
  while read conf
  do
    key=`echo "$conf" | awk -F'=' '{print $1}'`
    if [ "${key}" != "" ];then
      case "$key" in
        MODELNAME)
          MODELNAME=`awk '/^MODELNAME/{print $2}' /proc/thecus_io`
          echo "${key}|${MODELNAME}" >> "${local_setting}"
          ;;
        FWVersion)
          FWVersion=`cat /etc/version`
          echo "${key}|${FWVersion}" >> "${local_setting}"
          ;;
        RAM)
          RAM=`cat /proc/meminfo | grep ^MemTotal |awk '{print $2}'`
          echo "${key}|${RAM}" >> "${local_setting}"
          ;;
        sd*)
          str_exec="awk '{if (\$4==\"${key}\") print \$3}' /proc/partitions"
          disk_size=`eval ${str_exec}`
          echo "${key}|${disk_size}" >> "${local_setting}"
          ;;
        raid[0-4])
          disk_used_file="/tmp/disk_used_file"
          tray_log="/tmp/disk_tray"
          
          if [ -f "${disk_used_file}" ];then
            rm -f ${disk_used_file}
          fi
          
          rm -f $tray_log
          raidno=`echo ${key} | awk -F'_' '{print substr($1,5)}'`
          disk=`/sbin/mdadm -D /dev/md${raidno} 2>/dev/null | awk -F'active sync' '/active sync/{print $2}'|awk -F\/ '{printf("Disk:%s\n",substr($3,0,3))}'`
          for v in $disk
          do
            disk_num=`cat /proc/scsi/scsi |awk /$v/'{if($3=='\"$v\"')print $2}'|awk -F: '{printf("\"%s\"\n",$2)}'`
            echo -e "$disk_num" >> $tray_log
          done
          
          if [ -f "$tray_log" ];then
            cat "/tmp/${key}/disk_tray"| sort |\
            while read disk
            do
              echo -n "${disk} " | sed 's/\"//g' >> ${disk_used_file}
            done
          
            echo "${key}|`cat ${disk_used_file}`" >> "${local_setting}"
            rm -f ${disk_used_file}
            rm -f $tray_log
          else
            echo "${key}|" >> "${local_setting}"
          fi
          ;;
        raid[0-4]_size)
          raidno=`echo ${key} | awk -F'_' '{print substr($1,5)}'`
          str_exec="cat /proc/partitions | awk '{if (\$4==\"md${raidno}\") print \$3}'"
          raid_size=`eval ${str_exec}`
          raid_name=""
          if [ -f "/raid${raidno}/sys/smb.db" ];then
            raid_name=`${sqlite} /raid${raidno}/sys/smb.db "select v from conf where k='raid_name'"`
          fi
          echo "${key}|${raid_size},${raid_name}" >> "${local_setting}"
          ;;
        *)
          ${sqlite} ${cfgdb} "select k,v from conf where k='$key'" >> "${local_setting}"
          ;;
      esac
    fi
  done
}

function check_setting()
{
  remote_ip=$1
  save_setting

  if [ -f "${remote_setting}" ];then
    rm "${remote_setting}"
  fi
  
  if [ "${remote_ip}" != "" ];then
    ${WGET} "ftp://nas:nas@${remote_ip}:3694/www/${filename}" --directory-prefix=/tmp 
    
    if [ "`echo $?`" != "0" ];then
      echo "get_setting_fail"
      exit
    fi
  else
    echo "remote_ip_empty"
    exit
  fi 

  standby_null=""
  active_null=""
  disk_error=""    
  
  cat "${check_list}" | \
  while read conf
  do
    key=`echo "$conf" | awk -F'=' '{print $1}'`
    remark=`echo "$conf" | awk -F'=' '{print $2}'`
    
    if [ "$key" != "" ];then
      set1=`cat ${local_setting}| grep "$key|" | awk -F'|' '{print $2}'`
      set2=`cat ${remote_setting}|  grep "$key|" | awk -F'|' '{print $2}'`
      
      case "$key" in
        RAM)
          if [ "${set1}" != "${set2}" ];then
            if [ "${set1}" -lt "${set2}" ];then
              ret=$((${set2} - ${set1}))
              gap=$((${set2} / 10))
            else
              ret=$((${set1} - ${set2}))
              gap=$((${set1} / 10))
            fi
            
            if [ "${ret}" -gt "${gap}" ];then
              echo "${key}_error"
              exit
            fi
          fi
          ;;
        sd*)
          if [ "${set1}" != "${set2}" ];then
            if [ "${set1}" == "" ];then
              if [ "${standby_null}" == "" ];then
                standby_null="${remark}"
              else
                standby_null="${standby_null},${remark}"
              fi
              if [ -f /tmp/www/ha_flag ] && [ "`cat /tmp/www/ha_flag`" = "16" ];then
                echo "standby_disk_null|{$remark}"
                exit
              fi
            fi

            if [ "${set2}" == "" ];then
              if [ "${active_null}" == "" ];then
                active_null="${remark}"
              else
                active_null="${active_null},${remark}"
              fi
                                                                          
              if [ -f /tmp/www/ha_flag ] && [ "`cat /tmp/www/ha_flag`" = "16" ];then
                echo "active_disk_null|{$remark}"
                exit
              fi
            fi

            if [ "${set1}" != "" ] && [ "${set2}" != "" ];then
              if [ "${set1}" -gt "${set2}" ];then
                ret=0
              else
                ret=$((${set2} - ${set1}))
              fi

              if [ "${ret}" -gt "1024" ];then
                if [ "${disk_error}" == "" ];then
                  disk_error="${remark}"
                else
                  disk_error="${disk_error},${remark}"
                fi
                                                                          
                if [ ! -f /raidsys/0/ha_raid ] && [ -f /tmp/www/ha_flag ];then
                  if [ "`cat /tmp/www/ha_flag`" = "16" ];then
                    echo "disk_error|{$remark}"
                    exit
                  fi
                fi
              fi
            fi
          fi
          ;;
        raid[0-4])
          if [ -f /tmp/www/ha_flag ];then
            if [ "`cat /tmp/www/ha_flag`" = "16" ] || [ "`cat /tmp/www/ha_flag`" = "16.5" ];then
              continue
            fi
          fi

          if [ "${standby_null}" != "" ];then
            echo "standby_disk_null|${standby_null}"
            exit
          fi
          
          if [ "${active_null}" != "" ];then
            echo "active_disk_null|${active_null}"
            exit
          fi
          
          if [ "${disk_error}" != "" ];then
            echo "disk_error|${disk_error}"
            exit
          fi
        
          if [ "${set1}" != "${set2}" ];then
            echo "disk_tray_error|${remark}"
            exit
          fi
          ;;
        raid[0-4]_size)
          if [ -f /tmp/www/ha_flag ];then
            if [ "`cat /tmp/www/ha_flag`" = "16" ] || [ "`cat /tmp/www/ha_flag`" = "16.5" ];then
              continue
            fi
          fi

          raidsize1=`echo "${set1}" | awk -F',' '{print $1}'`
          raidid1=`echo "${set1}" | awk -F',' '{print $2}'`
          raidsize2=`echo "${set2}" | awk -F',' '{print $1}'`
          raidid2=`echo "${set2}" | awk -F',' '{print $2}'`
          
          if [ "${raidsize1}" != "${raidsize2}" ];then
            if [ "${raidsize1}" -lt "${raidsize2}" ];then
              echo "raid_size_error|${raidid1}^${raidid2}"
              exit
            fi
          fi
          ;;
        ha_*)
          if [ "${key}" == "ha_role" ];then
            ${sqlite} ${cfgdb} "update conf set v='1' where k='${key}'"
          elif [ "${key}" == "ha_standy_name" ];then
            if [ ! -f /tmp/www/ha_flag ] || [ "`cat /tmp/www/ha_flag`" != "16" ] && [ "`cat /tmp/www/ha_flag`" != "16.5" ];then
              nic1_hostname=`${sqlite} ${cfgdb} "select v from conf where k='nic1_hostname'"`
              if [ "${set2}" != "${nic1_hostname}" ];then
                echo "${key}_error"
                exit
              fi
            fi
            ${sqlite} ${cfgdb} "update conf set v='${set2}' where k='${key}'"
          elif [ "${key}" == "ha_standy_ip1" ];then
            local virtual_interface=`echo ${set2} | awk -F',' '{print $1}'`
            if [ ! -f /tmp/www/ha_flag ] || [ "`cat /tmp/www/ha_flag`" != "16" ] && [ "`cat /tmp/www/ha_flag`" != "16.5" ];then
              if [ `echo ${virtual_interface} | grep -c bond` = '0' ];then
                if [ "${virtual_interface}" = "eth0" ];then
                  netcard=nic1
                elif [ "${virtual_interface}" = "eth1" ];then
                  netcard=nic2
                else
                  netcard=${virtual_interface}
                fi
                nic_ip=`${sqlite} ${confdb} "select v from conf where k='${netcard}_ip'"`
              else
                bond_id=`echo ${virtual_interface}|tr -d bond`
                nic_ip=`${sqlite} ${confdb} "select ip from link_base_data where id='${bond_id}'"`
              fi
              if [ "`echo ${set2}|awk -F',' '{print $2}'`" != "${nic_ip}" ];then
                echo "${key}_error"
                exit
              fi
            else
              if [ `echo ${virtual_interface} | grep -c bond` = '1' ];then
                bond_id=`echo ${virtual_interface}|tr -d bond`
                nic_ip=`${sqlite} ${confdb} "select ip from link_base_data where id='${bond_id}'"`
                if [ "${nic_ip}" = "" ];then
                  echo "${key}_error"
                  exit
                fi
              fi
            fi
            ${sqlite} ${cfgdb} "update conf set v='${set2}' where k='${key}'"
          else
            if [ "`${sqlite} ${cfgdb} "select count(*) from conf where k='${key}'"`" = "0" ];then
              ${sqlite} ${cfgdb} "insert into conf('k','v') values ('${key}','')"
            fi
            ${sqlite} ${cfgdb} "update conf set v='${set2}' where k='${key}'"
          fi          

          ret=`echo $?`
          if [ "${ret}" != "0" ];then
            echo "save_error"
            exit
          fi
          ;;
        *)
          if [ "${set1}" != "${set2}" ];then
            echo "${key}_error"
            exit
          fi
          ;;
      esac
    fi
  done
}

case "$1" in
  save)
    save_setting
    ;;
  check)
    check_setting $2
    ;;
  *)
    echo "Usage: {save|check}" >&2
    exit 1
    ;;  
esac

