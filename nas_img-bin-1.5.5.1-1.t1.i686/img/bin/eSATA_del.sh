#!/bin/sh
### eSATA hot del
diskname=$1
esata_path="/raid/data/eSATAHDD"
strExec="mount|awk '/^\/dev\/${diskname} /{FS=\" \";print \$3}'"
mount_esatas=`eval ${strExec}` 
for mount_esata in ${mount_esatas}
do
  umount -f ${mount_esata}
  if [ "$?" != "0" ];
  then
    hold_pid=`/sbin/fuser -m ${mount_esata}`
    for pid in $hold_pid
    do
      kill -9 $pid
    done
    umount -f ${mount_esata}
  fi
done

/bin/rmdir ${esata_path}/*
