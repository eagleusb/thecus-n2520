#!/bin/sh
basepath=$1
lifetime=$2
nowtime=`date "+%s"`
if [ -d "${basepath}" ]; then
  cd ${basepath}
  for i in * 
  do
    tmp_accesstime=`stat -c "%X" "${basepath}${i}"`
    tmp_lifetime=$((nowtime - tmp_accesstime))
    if [ $tmp_lifetime -ge $lifetime ]; then
      rm -f "${i}"
    fi
  done
  cd -
fi
