#!/bin/sh
CHROOT=$1
ACTION=$2
if [ $# -lt 2 ];then
	echo "Usage: `basename $0` <chroot path> <create/clean>"
	exit 2
fi

create_chroot(){
	local SYS_TAR=/dev/shm/sys.tar
	mkdir ${CHROOT}
	pushd ${CHROOT}
	mkdir -p proc dev bin sbin usr/bin usr/sbin
	tar cvf ${SYS_TAR} /bin/sh /bin/bash /sbin/busybox /lib
	tar xvf ${SYS_TAR} -C ${CHROOT}
	rm -rf ${SYS_TAR}
	mount -t proc none proc
	mount --bind /dev dev
	chroot ${CHROOT} /sbin/busybox --install -s
	popd
}

clean_chroot(){
	umount ${CHROOT}/proc ${CHROOT}/dev
	if [ -z "`grep "${CHROOT}/proc\|${CHROOT}/dev" /proc/mounts`" ];then
		rm -rf ${CHROOT}
	fi
}

case ${ACTION} in
	'create')
		create_chroot
		;;
	'clean')
		clean_chroot
		;;
esac
