#!/bin/sh
/usr/bin/lockfile /var/lock/convert.lock

cd /var/spool/convert
for i in *
do
  sh "$i"
  rm -f "$i"
done
cd -

rm -f /var/lock/convert.lock
