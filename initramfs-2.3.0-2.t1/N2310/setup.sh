#!/bin/sh

SETUP_DIR="$1/setup"
NEWROOT="/sysroot"

# Setup workaround environment
echo "Post installing for N2310/N4310..."

# I) copy additional setup files
#cp ${SETUP_DIR}/init2df.sh $NEWROOT/img/bin/
# II) replace systemctl by busybox
ln -sf /sbin/busybox $NEWROOT/sbin/init
ln -sf /sbin/busybox $NEWROOT/sbin/runlevel
ln -sf /sbin/busybox $NEWROOT/sbin/reboot
ln -sf /sbin/busybox $NEWROOT/sbin/poweroff
ln -sf /sbin/busybox $NEWROOT/sbin/halt
# III) install kernel modules if the tarball is found.
MOD_TARBALL="`ls /rpm/os6*mods.tgz 2> /dev/null`"
[ -f "$MOD_TARBALL" ] && tar xvf $MOD_TARBALL -C $NEWROOT

