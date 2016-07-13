#!/bin/sh
# not service stop state
if [ `/bin/ps | grep smb[d] | wc -l` -ne 0 ]; then
  is_fail=`/usr/bin/nmblookup -s /etc/samba/smb.conf \`hostname\` 2>&1|grep 'name_query failed'|wc -l`
  if [ $is_fail -ne 0 ]; then
    kill -15 `cat /var/lock/samba/nmbd.pid`
    sleep 5
    nmbd_alive=`/bin/ps|grep "[n]mbd "|wc -l`
    if [ $nmbd_alive -ne 0 ]; then
      kill -9 `cat /var/lock/samba/nmbd.pid`
    fi
    sleep 3
    /usr/sbin/nmbd &
  fi
fi
