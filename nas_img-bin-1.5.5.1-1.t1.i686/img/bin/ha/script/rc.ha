#!/bin/sh -x
#################################################
##	Vars defined
#################################################
pwd="/opt/ha"
sqlite="/usr/bin/sqlite"
confdb="/etc/cfg/ha.db"
script_path="/etc/ha/script/"

readlink /etc/ha > /dev/null 2>&1
if [ $? -eq 1 ];then
  rm -rf /etc/ha
  ln -fs /img/bin/ha /etc/
fi

if [ x$1 = xboot ] || [ x$1 = xapply ] ;then
  cp /etc/cfg/conf.db ${confdb}
fi

cp /img/bin/ha/ha.d/authkeys.bak /etc/cfg/authkeys.ha
chmod 600 /etc/cfg/authkeys.ha

. ${script_path}/conf.ha
. ${script_path}/func.ha
. /img/bin/function/vardef.conf

#################################################
##	Database value	
#################################################
enable=`${sqlite} ${confdb} "select v from conf where k='ha_enable'"`
init_dead=`${sqlite} ${confdb} "select v from conf where k='ha_initdead'"`
#assume_clean=`${sqlite} ${confdb} "select v from conf where k='ha_assume_clean'"`
hostname=`${sqlite} ${confdb} "select v from conf where k='nic1_hostname'"`
ha_primary_name=`${sqlite} ${confdb} "select v from conf where k='ha_primary_name'"`
ha_standy_name=`${sqlite} ${confdb} "select v from conf where k='ha_standy_name'"`

if [ "${ha_role_db}" = "0" ];then
        if [ "${hostname}" != "${ha_primary_name}" ];then
                ha_primary_name=${hostname}
                ${sqlite} ${confdb} "update conf set v='${hostname}' where k='ha_primary_name'"
                ${sqlite} ${cfgdb} "update conf set v='${hostname}' where k='ha_primary_name'"
        fi
else
        if [ "${hostname}" != "${ha_standy_name}" ];then
                ha_standy_name=${hostname}
                ${sqlite} ${confdb} "update conf set v='${hostname}' where k='ha_standy_name'"
                ${sqlite} ${cfgdb} "update conf set v='${hostname}' where k='ha_standy_name'"
        fi
fi

#################################################
##	Declare subroutine
#################################################

start_hb() {
	if [ x$enable = x1 ];then
  		/img/bin/service stop
                rm -f /tmp/ha_role
                rm -f /var/www/html/htdocs/ha_role
		${RC_INITIATOR} status
		if [ "$?" = "1" ];then
			${RC_INITIATOR} start
		fi
		
		${RAID_IBLOCK} ${ipx1}
		/img/bin/rc/rc.snmpd boot
		/img/bin/rc/rc.ups start
		/img/bin/rc/rc.cupsd start
		/img/bin/rc/rc.sshd boot
		/img/bin/rc/rc.sys_monitor boot
                init_check ${ha_role_db}

		echo "HB Status : start ..."
		/etc/ha/script/gen_ha_cf.sh
		/etc/ha/init.d/heartbeat start
		echo standby > /tmp/ha_role
		echo standby > /var/www/html/htdocs/ha_role
		${HA_STAT} > /dev/null 2>&1 &
		${CHK_TREE}
		cp -f /etc/ha/script/shortcut.db /etc/cfg/shortcut.db
		/img/bin/logevent/event 152
		${script_path}/check_setting.sh save
                touch /tmp/boot_ok1
                echo "`date`-start_hb end" >> /tmp/ha_disk.log
	fi
}

stop_hb() {
	echo "HB Status : stop ..."
	/etc/ha/init.d/heartbeat stop
	/img/bin/logevent/event 153
}

start_ha(){
  echo "`date`-start_ha start" >> /tmp/ha_disk.log
  touch /var/lock/ha_st_lock
  
  #changed by heartbeat fifo
  if [ -f "${FLAG_HA}" ];then
    CAT_FLAG_HA=`cat ${FLAG_HA}`
    if [ "${CAT_FLAG_HA}" = "1" ];then
      /img/bin/sys_halt &
      rm /var/lock/ha_st_lock
      exit
    elif [ "${CAT_FLAG_HA}" = "3" ];then
      /img/bin/sys_reboot &
      rm /var/lock/ha_st_lock
      exit
    fi
  fi
            
  ha_enable=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ha_enable'"`
  if [ "${ha_enable}" = "0" ];then
      rm /var/lock/ha_st_lock
      exit
  fi
  
  if [ "`ifconfig ${virtual_interface} | grep -c 'inet addr:'`" = "0" ];then
    /img/bin/ha/script/ifaction ${virtual_interface} 
  fi

  virtual_ipv6 add

  if [ `cat /proc/mdstat | grep -c '^md[0-9] :'` -ge 1 ];then
    /img/bin/service stop
    echo active > /tmp/ha_role
    echo active > /var/www/html/htdocs/ha_role
    if [ ! -f /raidsys/0/ha_inited ];then
      nas_ftpd start
      touch /raidsys/0/ha_inited
    fi
    ${CHK_TREE}
    ${Export_iSCSI} ${ipx1} ${HB_LINE} remove
    for dev in `cat /proc/mdstat | awk '/md[0-9] :/{print $1}' | sort`
    do
      ${Export_iSCSI} ${ip1} ${HB_LINE} add ${dev}
    done
    ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} start p
    sleep 3
    
    setup=0
    for lun in 0 1 2 3 4
    do
        dev=`${DEV_MAP} ${HB_LINE} ${ip3} dev ${lun}`
        if [ $? = 0 ] && [ "${dev}" != "" ] && [ "${dev}" != "NO_DEVICE" ];then
            check_exist_raid ${dev}
            if [ "$?" = "0" ];then
                touch /var/lock/ha_monitor_${lun}
                assemble_exist_raid "${dev}" "${lun}" ""
    		setup=2
            else
                if [ ${ASSUME_CLEAN} = "1" ];then
                    assemble_assume_clean ${dev} ${lun}
                    setup=$?
                else
                    assemble_new_raid ${dev} ${lun}
       		    setup=1
                fi
                touch /var/lock/ha_monitor_${lun}
            fi
        fi
    done
    if [ -d /raid ];then
      run_sync_ha `expr $setup - 1`
      /img/bin/service boot
      clean_dual_dom_flag
    fi
    
    /img/bin/logevent/event 154
    echo "`date`-start_ha end" >> /tmp/ha_disk.log
    
  else
    echo "No md0 find!" >> /tmp/ha_disk.log
    /img/bin/logevent/event 334
    ${sqlite} /etc/cfg/conf.db "update conf set v='0' where k='ha_enable'"
    ${sqlite} ${confdb} "update conf set v='0' where k='ha_enable'"
    /img/bin/ha/script/stop_ha.sh
    /img/bin/rc/rc.sshd boot
  fi        
  rm /var/lock/ha_st_lock
}

stop_ha(){
    echo "`date`-stop_ha start" >> /tmp/ha_disk.log
    touch /var/lock/ha_st_lock

    virtual_ipv6 del

    stop_sync_ha
    rm -f /var/lock/ha_monitor_*

    if [ ! -f /tmp/ha_stop ];then
        /img/bin/service stop
        sleep 3
        echo standby > /tmp/ha_role
        echo standby > /var/www/html/htdocs/ha_role
        cp -f /etc/ha/script/shortcut.db /etc/cfg/shortcut.db
    fi

    umount_stop_ha_md

    ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop p
    ${ISCSI_BLOCK} ${HB_LINE} ${ipx3} stop s
    ${Export_iSCSI} ${ip1} ${HB_LINE} remove

    if [ -f /tmp/ha_stop ];then
        ${Export_iSCSI} ${ipx1} ${HB_LINE} remove
        ${RC_INITIATOR} stop
        rm /tmp/ha_role
        rm /var/www/html/htdocs/ha_role
        rm -f /tmp/ha_stop
    else
        for dev in `cat /proc/mdstat | awk '/md[0-9] :/{print $1}' | sort`
        do
            ${Export_iSCSI} ${ipx1} ${HB_LINE} add ${dev}
        done
        /img/bin/service stop
        /img/bin/rc/rc.snmpd boot
        /img/bin/rc/rc.ups start
        /img/bin/rc/rc.cupsd start
        /img/bin/rc/rc.sshd boot
	/img/bin/rc/rc.sys_monitor boot
        /img/bin/logevent/event 155
    fi
    ${CHK_TREE}
    umount_stop_ha_md
    rm /tmp/ha_exten_disks
    nas_ftpd stop
    echo "`date`-stop_ha end" >> /tmp/ha_disk.log
    rm /var/lock/ha_st_lock
    killall ha_status.sh
    /etc/ha/script/ha_status.sh > /dev/null 2>&1 &
}

stop_standby(){
  stop_ha
}

cancel_ha(){
    if [ "${ha_role_db}" = "0" ];then
      rm ${FLAG_HA}
      nas_ftpd stop
      rm /tmp/www/ha_conf_hw
    elif [ "${ha_role_db}" = "1" ];then
      rm /tmp/www/ha_conf_hw
      rm /tmp/ha_conf_hw
    fi
}

check_version(){
  rm -f ${HA_NAS_FIFO}
  mkfifo ${HA_NAS_FIFO}
  exec 43<> /tmp/ha_fifo
  ${NAS_PIE} send ${NAS_ACT} check_ver
  read -t 5 result <&43
  rm -f ${HA_NAS_FIFO}
  #echo "$result"
  if [ "`cat /etc/version`" != "$result" ];then
    echo "HA is enabled, but the version of active and standby nas is different!"
  fi
}

disable_ha(){
  echo 21 > ${FLAG_HA}
  rm -f ${HA_NAS_FIFO}
  mkfifo ${HA_NAS_FIFO}
  exec 43<> /tmp/ha_fifo
  ${NAS_PIE} send ${NAS_ACT} disable_ha
  read -t 5 result <&43
  rm -f ${HA_NAS_FIFO}
  if [ "${result}" = "ok" ];then
      echo 22 > ${FLAG_HA}
  else
      echo 122 > ${FLAG_HA}
  fi
}

enable_ha(){
    local ipx1=$1
    if [ -f /tmp/ha_role ];then
      echo 20 > ${FLAG_HA}
      return
    fi 
 
    if [ "${ha_role_db}" = "0" ];then
        echo 4 > ${FLAG_HA}
        nas_ftpd start
        ${HA_CHECK} save
    elif [ "${ha_role_db}" = "1" ];then
        echo 4 > ${FLAG_HA}
        if [ `ifconfig ${virtual_interface} | grep -c "inet addr:$ipx1 "` = "1" ];then
          echo 'error_standby_ip' > ${CONF_HW}_result
        else
          rm -f /tmp/ha_rolex
          ${WGET} ftp://nas:nas@${ipx1}:3694/ha_role -O /tmp/ha_rolex
          if [ "`cat /tmp/ha_rolex`" != "" ];then
            rm -f /tmp/ha_rolex
            if [ "`cat /tmp/ha_rolex`" = "active" ];then
              echo 'get_setting_fail' > ${CONF_HW}_result
            else
              echo 'plz_run_recovery' > ${CONF_HW}_result
            fi
            echo 105 > ${FLAG_HA}
            return
          else
            ${HA_CHECK} check ${ipx1} > ${CONF_HW}_result
          fi
        fi
        if [ "`cat ${CONF_HW}_result | wc -l`" = "0" ];then
          echo 5 > ${FLAG_HA}
          ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx1}:3694/www/ha_flag
        else
          echo 105 > ${FLAG_HA}
          ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx1}:3694/www/ha_flag
          ${WPUT} ${CONF_HW}_result ftp://nas:nas@${ipx1}:3694/www/ha_conf_hw_result
          return
        fi
#        cat ${CONF_HW}_result
        count=0
        timeout=600
        while true
	do
          rm ${FLAG_POWER}
          ${WGET} ftp://nas:nas@${ipx1}:3694/www/ha_flag_power -O ${FLAG_POWER}
          if [ -f ${FLAG_POWER} ];then
            CAT_FLAG_POWER=`cat ${FLAG_POWER}`
            if [ "${CAT_FLAG_POWER}" != "" ];then
              break
            fi
          fi
          sleep 1
          count=`expr $count + 1`
          if [ $count -ge $timeout ];then
            break
          fi
        done
        if [ "${CAT_FLAG_POWER}" = "halt" ];then
          if [ $count -ge $timeout ];then
            echo 101 > ${FLAG_HA}
            ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx1}:3694/www/ha_flag
          else    
            echo 1 > ${FLAG_HA}
            ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx1}:3694/www/ha_flag
            /img/bin/sys_halt &
            #echo /img/bin/sys_halt 
          fi
        elif [ "${CAT_FLAG_POWER}" = "reboot" ];then
          if [ $count -ge $timeout ];then
            echo 103 > ${FLAG_HA}
            ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx1}:3694/www/ha_flag
          else    
            echo 3 > ${FLAG_HA}
            ${WPUT} ${FLAG_HA} ftp://nas:nas@${ipx1}:3694/www/ha_flag
            /img/bin/sys_reboot &
            #echo /img/bin/sys_reboot
          fi
        fi
    fi
}
#################################################
##	Main code
#################################################

case "$1"
in
	start)
		if [ "`cat /tmp/ha_role`" != "active" ];then
		  start_ha
		fi
		;;
	stop_standby)			
		stop_standby
		;;
	stop)			
	        if [ "`cat /tmp/ha_role`" = "active" ];then
		  stop_ha
		else
		  rm -f /tmp/ha_stop
		fi
		;;
	boot)
		start_hb
		;;
	hbstart)
		start_hb
		;;
	hbstop)
		stop_hb
		;;
	apply|enable)
		enable_ha $2
		;;
	disable)
		disable_ha
		;;
	cancel)
		cancel_ha
		;;
	check_version)
		check_version
		;;
	*)			
		echo "Usage: $0 {start|stop|boot|hbstart|hbstop|apply|cancel|enable|disable|check_version}"
		;;
esac
