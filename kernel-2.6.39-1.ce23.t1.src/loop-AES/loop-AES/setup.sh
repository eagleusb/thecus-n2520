#!/bin/sh

usage()
{
	echo "Usage: `basename $0` <kernel source>"
	echo "       This utility is used for patching loop-AES drivers"
	echo "       to your specific Linux kernel source."
	exit 1
}

err_handler()
{
	case $1 in
	nokern)
		echo "Invalid kernel source"
		exit 3
	;;
	*)
	;;
	esac

	exit 2
}

init_env()
{
	WORK_DIR="`dirname $0`"
	LINUX_MK="${KSRC}/Makefile"
	# determine if the target kernel is 2.4, 2.6 or 3.x
	KVER="`grep '^VERSION\|^PATCHLEVEL' $LINUX_MK |\
		awk '{print $3}' | sed '{N;s/\t\|\n/\./g}'`"
	case $KVER in
	2.4)
		KPATCH_NAME="kernel-2.4.37.diff"
		;;
	2.6)
		KPATCH_NAME="kernel-2.6.39.diff"
		;;
	*)
		[ "`echo $KVER | awk -F'.' '{print $1}'`" = 3 ] && \
			KPATCH_NAME="kernel-3.10.diff"
		;;
	esac
	KPATCH="`readlink -f ${WORK_DIR}/${KPATCH_NAME}`"
	[ ! -f "${KPATCH}" ] && echo "No patch file for $KVER" && exit 1

	KDMISC="${KSRC}/drivers/misc"
	KLOOP_C="${KSRC}/drivers/block/loop.c"
	KLOOP_H="${KSRC}/include/linux/loop.h"
}

cleanup_des()
{
	rm -rf ${KDMISC}/aes* ${KDMISC}/md5* ${KDMISC}/crypto-ksym.c
}

prep_ksrc()
{
	# remove native loop.c and loop.h first
	rm -rf ${KLOOP_C} ${KLOOP_H}
	pushd $KSRC
	patch -p1 < ${KPATCH}
	RET=$?
	popd
}


KSRC=$1
[ -z "$KSRC" ] && usage
[ ! -f "${KSRC}/drivers/Kconfig" -o ! -f "${KSRC}/drivers/Makefile" ] && \
	err_handler "nokern"

init_env
cleanup_des
prep_ksrc

exit $RET
