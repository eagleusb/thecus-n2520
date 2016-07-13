#!/bin/sh
##############################################
# Format : mksys_md.sh $sysdisk_count $sysdisks
# Used for create or assemble sys raid
##############################################
mdadm="/sbin/mdadm"
sysmd="/dev/md70"
sysdisk_count=$1
sysdisks=$2
###check sys

echo "1" > /var/tmp/raidlock

${mdadm} -D ${sysmd}
if [ "$?" = "0" ];then
  #sys exist...add to sys
  
  inraid_list=`${mdadm} -D $sysmd | awk '/active sync/{print $7}'`
  inraid_list="$inraid_list missing"
  for new_hdd in $sysdisks
  do
    match_pos=` echo $inraid_list |   awk '{match ($0, "'$new_hdd'" ); print RSTART}' `
    if [ "$match_pos" = "0" ];
    then
      addin_hdd="$addin_hdd $new_hdd"
    fi
  done
  if [ "${addin_hdd}" != "" ];then
    sysraid="${mdadm} -a ${sysmd} $addin_hdd;"
    eval "${sysraid}"
  fi
  
fi

sync

echo "0" > /var/tmp/raidlock
