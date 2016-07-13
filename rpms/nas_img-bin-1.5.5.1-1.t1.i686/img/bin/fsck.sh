#!/bin/sh
/bin/rm -rf /tmp/lns_*
/bin/rm -rf /tmp/fsck.log
if [ ! -f /tmp/lns.lock ];
then
  /bin/touch /tmp/lns.lock
  /img/bin/fsck_start.sh > /dev/null 2>&1 &
fi
