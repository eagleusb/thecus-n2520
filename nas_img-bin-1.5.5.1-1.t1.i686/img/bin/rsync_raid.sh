#!/bin/sh
###################################################
#
# This is Rsync raid Script
# Usage : rsync_raid.sh $source_raid $target_raid
#
###################################################
src_mnt=$1
dst_mnt=$2

rsync="/usr/bin/rsync"
rsync_min=5
rsync_retry_max=20

sync_time=10
sync_retry=0

while [ $sync_time -gt $rsync_min ] 
do
  if [ $sync_retry -gt $rsync_retry_max ];then
    exit
  fi

  sync_start=`date +%s`
  ${rsync} -aA --delete $src_mnt/ $dst_mnt/
  sync_end=`date +%s`
  sync_time=$(($sync_end-$sync_start))
  sync_retry=`expr $sync_retry + 1` 
done
