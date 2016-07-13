#!/bin/sh
###################################
### For OS6 bin file upgrade
###################################
## Must use folder gofactory
cp -a /etc/gofactory/* /tmp

rm -f /etc/gofactory
rm -rf /mnt2/gofactory
sync

sh /tmp/img-upgrade.sh  &

exit
