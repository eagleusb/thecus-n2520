#!/bin/sh

if [ "$1" = "stop" ]; then
  #stop
  if [ `cat /proc/swaps | grep -e 'md1' | wc -l` -eq 1 ]; then
    /sbin/swapoff /dev/md1
    mdadm --stop /dev/md1
  fi
else
  building=`cat /proc/mdstat | sed -n '/^md1/,/^md[0-9]/p'|grep "recovery\|resync"`
  while [ "${building}" != "" ]
  do
    sleep 10
    building=`cat /proc/mdstat | sed -n '/^md1/,/^md[0-9]/p'|grep "recovery\|resync"`
  done
  if [ `cat /proc/swaps | grep -e 'md1' | wc -l` -eq 1 ]; then
    sleep 3
    exit 0
  fi
  sleep 3
  if [ `cat /proc/mdstat | grep md1 | wc -l` -eq 1 ]; then
    /sbin/swapon /dev/md1
    if [ $? -ne 0 ]; then
      /sbin/mkswap /dev/md1
      /sbin/swapon /dev/md1
    fi
    sleep 3
  fi
fi
