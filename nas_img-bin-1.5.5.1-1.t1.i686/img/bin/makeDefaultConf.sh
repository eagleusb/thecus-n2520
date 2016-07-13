#!/bin/sh
#
# 2005/02/18 by Leon
# Config file make to tar file

cd /
tar cpf /tmp/confdownload.tar `cat /img/bin/default.list` 
if [ -f /etc/cfg/logfile ]; then
  /usr/bin/savelog /etc/cfg/logfile > /tmp/logfile
  tar -rf /tmp/confdownload.tar /tmp/logfile
fi

if [ -f /etc/cfg/logfile.002 ]; then
  /usr/bin/savelog /etc/cfg/logfile.002 > /tmp/logfile.002
  tar -rf /tmp/confdownload.tar /tmp/logfile.002
fi

tar -rf /tmp/confdownload.tar /etc/version
tar -rf /tmp/confdownload.tar /etc/manifest.txt

## for FAE debug
DEBUG_PATH="/tmp/debug"
rm -rf ${DEBUG_PATH}
mkdir -p ${DEBUG_PATH}

syslog="/etc/cfg"
#if [ `/bin/mount | /bin/grep sdaaa4 | /bin/grep -c rw` -eq 1 ];then
  syslog="/syslog"
  tar -rf /tmp/confdownload.tar /syslog
#fi

cp -rfd /raidsys ${DEBUG_PATH}/
find ${DEBUG_PATH}/ -name songs3.db -exec rm {} \;

for logfile in error information warning
do
  if [ -f ${syslog}/${logfile} ]; then
    cp ${syslog}/${logfile} ${DEBUG_PATH}
  fi
done

if [ -f /syslog/sys_log.db ]; then
    /usr/bin/sqlite /syslog/sys_log.db "select * from sysinfo where level = 'Info' order by Date_Time" > ${DEBUG_PATH}/system.info
    /usr/bin/sqlite /syslog/sys_log.db "select * from sysinfo where level = 'Warning' order by Date_Time" > ${DEBUG_PATH}/system.warning
    /usr/bin/sqlite /syslog/sys_log.db "select * from sysinfo where level = 'Error' order by Date_Time" > ${DEBUG_PATH}/system.error
fi

if [ -f /var/run/smb.conf ]; then
        cp /var/run/smb.conf ${DEBUG_PATH}
fi
if [ -f /etc/cfg/crond.conf ]; then
        cp /etc/cfg/crond.conf ${DEBUG_PATH}
fi

if [ -f /etc/nsswitch.conf ]; then
        cp /etc/nsswitch.conf ${DEBUG_PATH}
fi

if [ -f /etc/resolv.conf ]; then
        cp /etc/resolv.conf ${DEBUG_PATH}
fi

## Add backup /syslog/disk_check
[ -d "${syslog}/disk_check" ] && cp -a ${syslog}/disk_check ${DEBUG_PATH}

mkdir ${DEBUG_PATH}/tmp/
cp /tmp/*.log ${DEBUG_PATH}/tmp/
cp /tmp/*.tmp ${DEBUG_PATH}/tmp/
cp /tmp/raid_start_log ${DEBUG_PATH}/tmp/
cp /tmp/oled/PIC24F_OK ${DEBUG_PATH}/tmp/
cp /tmp/hwinfo ${DEBUG_PATH}/tmp/

dmesg > ${DEBUG_PATH}/dmesg.txt 2>&1

find /opt/ -maxdepth 2 > ${DEBUG_PATH}/opt.txt
rpm -qa | sort > ${DEBUG_PATH}/rpmlist.txt

mdlist=`awk -F ':' '/^md/&&!/^md10 /{print substr($1,3)}'  /proc/mdstat|sort -u`
for mdnum in $mdlist
do
  mdadm --detail /dev/md$mdnum > ${DEBUG_PATH}/mdadm_$mdnum.txt 2>&1

  if [ $mdnum -ge 0 -a $mdnum -le 4 ];then
    raidnum=raid${mdnum}
    echo "<<RAID Number [$raidnum] data list>>" > ${DEBUG_PATH}/raid_data_list_$raidnum.txt
    ls -la /$raidnum/data/* >> ${DEBUG_PATH}/raid_data_list_$raidnum.txt 2>&1
    echo "<<RAID Number [$raidnum] sys list>>" > ${DEBUG_PATH}/raid_sys_list_$raidnum.txt
    ls -la /$raidnum/sys/* >> ${DEBUG_PATH}/raid_sys_list_$raidnum.txt 2>&1
  fi
done

for i in `cat /proc/scsi/scsi | grep Thecus | cut -d: -f4 | cut -d" " -f1`
do
  intf=`cat /proc/scsi/scsi | awk -F: '/Disk:'${i}' /{print $7}'| awk '{print $1}'`
  tray=`cat /proc/scsi/scsi | awk -F: '/Disk:'${i}' /{print $3}'| awk '{print $1}'`
  [ "$tray" = "0" ] && continue
  [ "$intf" = "USB" ] && continue
  cp ${syslog}/sbdump.*${i}[123] ${DEBUG_PATH}/
  mdadm -E /dev/${i}1 > ${DEBUG_PATH}/mdadm_${i}1.txt 2>&1
  mdadm -E /dev/${i}2 > ${DEBUG_PATH}/mdadm_${i}2.txt 2>&1
  mdadm -E /dev/${i}3 > ${DEBUG_PATH}/mdadm_${i}3.txt 2>&1
  if [ "${intf}" == "SAS" ];then
    /usr/sbin/smartctl --all -d scsi /dev/${i} > ${DEBUG_PATH}/smart_${i}.txt 2>&1
  else
    /usr/sbin/smartctl --all -d sat /dev/${i} > ${DEBUG_PATH}/smart_${i}.txt 2>&1
  fi
  gdisk -l /dev/${i} >> ${DEBUG_PATH}/gdisk.txt 2>&1
done

cat /proc/interrupts > ${DEBUG_PATH}/interrupts.txt 2>&1
df > ${DEBUG_PATH}/df.txt 2>&1
free > ${DEBUG_PATH}/free.txt 2>&1
/bin/ps > ${DEBUG_PATH}/ps.txt 2>&1
if [ -f /proc/hwm ]; then
        cp /proc/hwm ${DEBUG_PATH}/hwm.txt
fi
crontab -l > ${DEBUG_PATH}/crontab.txt  2>&1
lsmod > ${DEBUG_PATH}/lsmod.txt 2>&1
lspci -v > ${DEBUG_PATH}/lspci.txt 2>&1

cat /proc/thecus_io > ${DEBUG_PATH}/thecus_io.txt 2>&1
cat /proc/scsi/scsi > ${DEBUG_PATH}/scsi.txt 2>&1
cat /proc/mdstat > ${DEBUG_PATH}/mdstat.txt 2>&1
cat /proc/partitions > ${DEBUG_PATH}/partitions.txt 2>&1
cat /proc/meminfo > ${DEBUG_PATH}/meminfo.txt 2>&1
cat /proc/cpuinfo > ${DEBUG_PATH}/cpuinfo.txt 2>&1

ls -la /raid/data/ > ${DEBUG_PATH}/raid.txt 2>&1
if [ -f /etc/cfg/logfile ]; then
	/usr/bin/savelog /etc/cfg/logfile > ${DEBUG_PATH}/logfile
fi
if [ -f /etc/cfg/logfile.002 ]; then
	/usr/bin/savelog /etc/cfg/logfile.002 > ${DEBUG_PATH}/logfile.002
fi

ifconfig -a > ${DEBUG_PATH}/ifconfig.txt 2>&1

route -n > ${DEBUG_PATH}/route.txt 2>&1
netstat -na > ${DEBUG_PATH}/netstat.txt 2>&1

if [ -f /syslog/.bash_history ]; then
        cp /syslog/.bash_history ${DEBUG_PATH}
fi

#=====
#iSCSI
#=====
 
ISCSI_STATE=`/img/bin/check_service.sh iscsi_limit`

if [ "$ISCSI_STATE" == "1" ]; then
    /sbin/iscsiadm -m discovery -tst --portal `ifconfig eth0`:3260 > ${DEBUG_PATH}/iscsiadm_discovery.txt 2>&1
fi
 
if [ -d /sys/kernel/config/target/core/fileio_0 ];then 
  cd /sys/kernel/config/target/core/fileio_0
  find > ${DEBUG_PATH}/iscsi_core_filelist.txt
  cat `find` > ${DEBUG_PATH}/iscsi_core_filelist_values.txt
 
  cd /sys/kernel/config/target/iscsi
  find > ${DEBUG_PATH}/iscsi_filelist.txt
  cat `find` > ${DEBUG_PATH}/iscsi_filelist_values.txt
fi
 
#===== 
#Quota
#===== 

/usr/sbin/repquota -a > ${DEBUG_PATH}/repquota.txt 2>&1

md_list=`cat /proc/mdstat | awk '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
if [ "${md_list}" == "" ];then
  md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
fi

for md in $md_list
do
  dd if=/dev/zero of=/raid${md}/tm0_quota bs=1M count=100
done
 
/usr/sbin/repquota -a >> ${DEBUG_PATH}/repquota.txt 2>&1
for md in $md_list
do
  rm /raid${md}/tm0_quota
done

echo "" > ${DEBUG_PATH}/system.txt
echo "==> Download Time <===" >> ${DEBUG_PATH}/system.txt
echo "Date Time : $(date)" >> ${DEBUG_PATH}/system.txt 2>&1
echo "==> UPTIME <===" >> ${DEBUG_PATH}/system.txt
echo "Uptime : $(uptime)" >> ${DEBUG_PATH}/system.txt 2>&1

cd /tmp
tar -rf /tmp/confdownload.tar /tmp/debug

## for FAE debug end

gzip /tmp/confdownload.tar
enckey=`/img/bin/check_service.sh key`
/usr/bin/des -k conf_${enckey} -E /tmp/confdownload.tar.gz /tmp/confdownload.bin
rm -rf /tmp/confdownload.tar.gz

rm -rf ${DEBUG_PATH}
