#!/bin/sh
ntpdate="/usr/sbin/ntpdate"

timesrv="$1"
if [ "${timesrv}" = "" ]; then
  timesrv="time.stdtime.gov.tw"
fi

x=`${ntpdate} -u -o 1 ${timesrv} 2>&1`
z=$?
y=`echo $x | grep "Can't adjust the time of day"`
if [ "$y" != "" -o $z != 0 ] ; then
  ${ntpdate} -b -o 1 ${timesrv}
  if [ $? = 0 ]; then
    /sbin/hwclock --localtime --systohc
  fi
  ${ntpdate} -o 1 ${timesrv}
  if [ $? = 0 ]; then
    /sbin/hwclock --localtime --systohc
  else
    echo "NTP server connected fail."
  fi
else
  /sbin/hwclock --localtime --systohc
fi

