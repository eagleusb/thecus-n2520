#!/bin/sh
act=$1
conf=/etc/cfg/conf.db
thread_time=`date`

echo "$thread_time - Start $act" >> /tmp/ha_sync.log

md5_quota=''
md5_shortcut=''
md5_wireless=''
md5_global=''
md5_stackable=''
md5_conf=''
md5_crond=''
md5_passwd=''
md5_group=''
md5_passdb=''
md5_secrets=''
md5_localtime=''

get_md5(){
  md5_quota=`md5sum /etc/cfg/quota.db|cut -d ' ' -f 1`
  md5_backup=`md5sum /etc/cfg/backup.db|cut -d ' ' -f 1`
  md5_shortcut=`md5sum /etc/cfg/shortcut.db|cut -d ' ' -f 1`
  md5_wireless=`md5sum /etc/cfg/wireless.db|cut -d ' ' -f 1`
  md5_global=`md5sum /etc/cfg/global.db|cut -d ' ' -f 1`
  md5_stackable=`md5sum /etc/cfg/stackable.db|cut -d ' ' -f 1`
  md5_conf=`md5sum /etc/cfg/conf.db|cut -d ' ' -f 1`
  md5_crond=`md5sum /etc/cfg/crond.conf|cut -d ' ' -f 1`
  md5_passwd=`md5sum /etc/passwd|cut -d ' ' -f 1`
  md5_group=`md5sum /etc/group|cut -d ' ' -f 1`
  md5_passdb=`md5sum /etc/cfg/samba/passdb.tdb|cut -d ' ' -f 1`
  md5_secrets=`md5sum /etc/cfg/samba/secrets.tdb|cut -d ' ' -f 1`
  md5_localtime=`md5sum /tmp/localtime|cut -d ' ' -f 1`
}

check_md5(){
  if [ "`md5sum /etc/cfg/quota.db | grep -c $md5_quota`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/backup.db | grep -c $md5_backup`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/shortcut.db | grep -c $md5_shortcut`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/wireless.db | grep -c $md5_wireless`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/global.db | grep -c $md5_global`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/stackable.db | grep -c $md5_stackable`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/conf.db | grep -c $md5_conf`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/crond.conf | grep -c $md5_crond`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/passwd | grep -c $md5_passwd`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/group | grep -c $md5_group`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/samba/passdb.tdb | grep -c $md5_passdb`" = "0" ];then return 1;fi
  if [ "`md5sum /etc/cfg/samba/secrets.tdb | grep -c $md5_secrets`" = "0" ];then return 1;fi
  if [ "`md5sum /tmp/localtime | grep -c $md5_localtime`" = "0" ];then return 1;fi
#  if [ "`md5sum  | grep -c $`" = "0" ];then return 1;fi
  return 0
}

#debug test
#get_md5
#check_md5
#exit

list_conf(){
  echo /etc/cfg/quota.db
  echo /etc/cfg/backup.db
  echo /etc/cfg/shortcut.db
  echo /etc/cfg/wireless.db  
  echo /etc/cfg/global.db
  echo /etc/cfg/stackable.db
  echo /etc/cfg/conf.db
  echo /etc/cfg/crond.conf  
  echo /etc/passwd
  echo /etc/group
  echo /etc/cfg/samba/passdb.tdb
  echo /etc/cfg/samba/secrets.tdb
  echo /tmp/localtime
}

backup_cfg(){
  while true
  do
    master_data=`readlink /raid`
    master_sys=`readlink ${master_data}/../sys`
    if [ ! -d "${master_data}" ] || [ ! -d "${master_sys}" ];then
      echo "$thread_time - no ${master_data} or ${master_sys}" >> /tmp/ha_sync.log
      sleep 5
      continue
    fi
    if [ ! -d "${master_sys}/ha" ];then
      mkdir -p ${master_sys}/ha/
    fi 
    
    /usr/bin/lockfile /var/lock/ha_sync.lock
    
    readlink /etc/localtime > /tmp/localtime
    if [ -f ${master_sys}/ha.0000000000.tar ] && [ -f ${master_sys}/ha.9999999999.tar ];then
      rm -f ${master_sys}/ha.9999999999.tar*
    fi
    times=`ls ${master_sys}/ha.*.tar | sort -nr | head -n 1 | cut -d "/" -f 4 | awk -F"." '{printf("%010d",$2+1);}'`
    if [ "${times}" == "" ] || [ ${times} -le 0 ];then
      times="0000000000"
    fi
    echo "$thread_time - backup $times" >> /tmp/ha_sync.log
    
    sqlite /etc/cfg/conf.db "select v from conf where k='ha_enable'"
    if [ x$? = x0 ];then
      echo "$thread_time - check md5" >> /tmp/ha_sync.log
      check_md5
      if [ x$? = x1 ];then
        get_md5
        echo "$thread_time - do tar" >> /tmp/ha_sync.log
        tar cpf /tmp/ha.${times}.tar `list_conf` >> /tmp/ha_sync.log 2>&1
        md5sum /tmp/ha.${times}.tar > ${master_sys}/ha.${times}.tar.md5
        ls -al /tmp/ha.*.tar* >> /tmp/ha_sync.log
        sync
        mv /tmp/ha.${times}.tar ${master_sys}
        sync
      fi
    fi
    
    count=0
    for backup_file in `ls ${master_sys}/ha.*.tar | sort -nr`
    do
      if [ -f ${backup_file}.md5 ] && [ x`cat ${backup_file}.md5 |wc -l` = x1 ];then
        count=`expr $count + 1`
      else
        rm -f ${backup_file}
      fi 
      if [ $count -gt 2 ];then
        rm -f ${backup_file} ${backup_file}.md5
      fi
    done

    rm -f /var/lock/ha_sync.lock
    if [ "`/bin/ps | grep -c '[Hh]a_status.sh'`" = "0" ] && [ ! -f /tmp/stop_ha_status ];then
      /img/bin/ha/script/ha_status.sh > /dev/null 2>&1 &
    fi
    sleep 5
  rm -f /tmp/ha_sync.log
  done
}

restore_cfg(){
  master_data=`readlink /raid`
  master_sys=`readlink ${master_data}/../sys`
  if [ ! -d "${master_sys}/ha" ] || [ ! -d "${master_data}" ];then
    echo "$thread_time - restore - no ${master_data}/ha or ${master_sys}" >> /tmp/ha_sync.log
    return 2
  fi
  
  if [ ! -d /tmp/ha_restore ];then
    mkdir /tmp/ha_restore
  fi

  restore=0
  
  for backup_file in `ls ${master_sys}/ha.*.tar | sort -nr`
  do
    echo "$thread_time - restore - try $backup_file" >> /tmp/ha_sync.log
    cp "${backup_file}" /tmp/
    restore_file=/tmp/`basename ${backup_file}`
    md5sum ${restore_file} > ${restore_file}.md5
    diff ${restore_file}.md5 ${backup_file}.md5
    if [ $? = 0 ];then
      restore=1
      echo "$thread_time - restore - tar ${restore_file}" >> /tmp/ha_sync.log
      tar xvf ${restore_file} -C /tmp/ha_restore  >> /tmp/ha_sync.log 2>&1
      break  
    fi
  done

  if [ "${restore}" = "1" ];then
    if [ -f /tmp/ha_restore/tmp/localtime ];then
      timezone=`cat /tmp/ha_restore/tmp/localtime`
      if [ "${timezone}" != "" -a -f "${timezone}" ];then
        echo "$thread_time - restore - ${timezone}" >> /tmp/ha_sync.log
        /bin/ln -fs ${timezone} /etc/localtime
      fi
    fi

    echo "$thread_time - restore - db -start" >> /tmp/ha_sync.log
    cd /tmp/ha_restore
    cp ./etc/cfg/quota.db /etc/cfg/quota.db
    cp ./etc/cfg/backup.db /etc/cfg/backup.db
    cp ./etc/cfg/shortcut.db /etc/cfg/shortcut.db
    cp ./etc/cfg/wireless.db /etc/cfg/wireless.db  
    cp ./etc/cfg/global.db /etc/cfg/global.db
    cp ./etc/cfg/stackable.db /etc/cfg/stackable.db
    cp ./etc/cfg/crond.conf /etc/cfg/crond.conf  
    cp ./etc/passwd /etc/passwd
    cp ./etc/group /etc/group
    cp ./etc/cfg/samba/passdb.tdb /etc/cfg/samba/passdb.tdb
    cp ./etc/cfg/samba/secrets.tdb /etc/cfg/samba/secrets.tdb
    cd -
    echo "$thread_time - restore - db -end" >> /tmp/ha_sync.log

      /usr/bin/killall -9 crond;sleep 1;/usr/sbin/crond
      /usr/bin/crontab /etc/cfg/crond.conf -u root

      #cp ./etc/cfg/conf.db /etc/cfg/conf.db
      echo "$thread_time - restore - ha_key" >> /tmp/ha_sync.log
      ha_conf=/tmp/ha_restore/etc/cfg/conf.db
      sqlite $ha_conf "select k from conf" > /tmp/ha_key

      cat /tmp/ha_key | grep -v '^ha_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^nic' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^notif_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^snmp_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^ups_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^wol_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^wireless_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      #sync the online register
#      cat /tmp/ha_key | grep -v '^online_' > /tmp/ha_key.tmp
#      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^disks_spin_down' > /tmp/ha_key.tmp
      cat /tmp/ha_key.tmp | sort -u > /tmp/ha_key
     
      #no sync with syslogd
      cat /tmp/ha_key | grep -v '^syslogd_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^stond_enable' | grep -v 'sshd_port' | grep -v 'sftp_enable' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key | grep -v '^geth[0-9]*_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key
      
      cat /tmp/ha_key | grep -v '^eth[0-9]*_' > /tmp/ha_key.tmp
      cp /tmp/ha_key.tmp /tmp/ha_key

      cat /tmp/ha_key >> /tmp/ha_sync.log
      
      for key in `cat /tmp/ha_key`
      do
        #echo $key
        value=''
        value=`sqlite $ha_conf "select v from conf where k='$key'"|head -1`
        #echo $value
        echo "$thread_time - restore - $key,$value" >> /tmp/ha_sync.log
        check=`sqlite $conf "select count(*) from conf where k='$key'"`
        if [ ${check} -eq 0 ] || [ ${check} -gt 1 ];then
          if [ ${check} -gt 1 ];then
             sqlite $conf "delete from conf where k='$key'"
             echo "$thread_time - restore - delete from conf where k='$key' ret=$?" >> /tmp/ha_sync.log
          fi
          sqlite $conf "insert into conf (k,v) values ('$key','$value')"
          echo "$thread_time - restore - insert into conf (k,v) values ('$key','$value') ret=$?" >> /tmp/ha_sync.log
        elif [ ${check} -eq 1 ];then
          sqlite $conf "update conf set v='$value' where k='$key'"
          echo "$thread_time - restore - update conf set v='$value' where k='$key' ret=$?" >> /tmp/ha_sync.log
        fi
        
        #modify the mac address for tftpd_ip
        if [ "${key}" == "tftpd_ip" ];then
            new_interface=""
            interface_count=`echo "$value" | awk -F'|' '{print NF}'`
            for ((i=1;i<=$interface_count;i++))
            do
                strExec="echo '$value' | awk -F'|' '{print \$$i}'| awk -F'-' '{print \$1}'"
                intf=`eval $strExec`
                mac=`/img/bin/function/get_interface_info.sh get_mac $intf`
            
                if [ "${mac}" == "" ];then
                    strExec="echo '$value' | awk -F'|' '{print \$$i}'| awk -F'-' '{print \$2}'"
                    mac=`eval $strExec`
                fi

                if [ "${new_interface}" == "" ];then
                    new_interface="${intf}-${mac}"
                else
                    new_interface="${new_interface}|${intf}-${mac}"
                fi
            done
            
            sqlite $conf "update conf set v='$new_interface' where k='$key'"       
        fi
      done

      for tb in hot_spare mount nfs nsync rsyncbackup
      do
        ret=1
	while [ "${ret}" = "1" ];do
          sqlite $ha_conf "select * from ${tb}" > /tmp/ha_db
          sqlite $conf "delete from ${tb}"
          sqlite $conf ".import /tmp/ha_db ${tb}"
          sqlite $conf "select * from ${tb}" > /tmp/ha_db_check
          diff /tmp/ha_db /tmp/ha_db_check >/dev/null 2>&1
          ret=$?
        done
      done
      cp -f $conf /etc/cfg/ha.db
      /img/bin/rc/rc.treemenu hd_tree
      return 0
  fi
  return 1
}

if [ "$act" = "restore" ];then
  /usr/bin/lockfile /var/lock/ha_sync.lock
  if [ -f /tmp/ha_norestore ];then
    rm -f /tmp/ha_norestore
    result=0
  else
    restore_cfg
    result=$?
  fi
  rm -f /var/lock/ha_sync.lock
  exit $result
else
  get_md5
  backup_cfg
fi
