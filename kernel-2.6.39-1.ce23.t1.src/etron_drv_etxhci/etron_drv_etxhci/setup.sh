#!/bin/sh

usage()
{
	echo "Usage: `basename $0` <kernel source>"
	echo "       This utility is used for patching Thecus drivers"
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
	KVER="`grep '^VERSION\|^PATCHLEVEL\|^SUBLEVEL' $LINUX_MK |\
		awk '{print $3}' | sed '{N;N;s/\t\|\n/\./g}'`"
	KPATCH="`readlink -f ${WORK_DIR}/kernel-${KVER}.patch`"
	[ ! -f "${KPATCH}" ] && echo "No patch file for $KVER" && exit 1

	ETRON_DRV="${WORK_DIR}/drivers/usb"
	THECUS_INC="${WORK_DIR}/include/linux/usb"
	KDDRV="${KSRC}/drivers/usb"
	KDINC="${KSRC}/include/linux/usb"
}

cleanup_des()
{
	if [ -f ${KDDRV}/host/etxhci.c ];then
		rm -rf ${KDDRV}/host/etxhci*
		rm ${KDDRV}/core/ethub.c
		rm ${KDINC}/uas.h
		patch -R -d ${KSRC} -p2 < ${KPATCH} > ${WORK_DIR}/etxhci_R_patch.log 2>&1
	fi
}

prep_ksrc()
{
	# copy our drivers to be a part of kernel drivers
	cp -a $ETRON_DRV/host/etxhci* ${KDDRV}/host/
	cp -a $ETRON_DRV/core/ethub.c ${KDDRV}/core/
	cp -a $THECUS_INC/uas.h ${KDINC}
	patch -p2 -d ${KSRC} < ${KPATCH} > ${WORK_DIR}/etxhci_patch.log 2>&1
	RET=$?
}


KSRC=$1
[ -z "$KSRC" ] && usage
[ ! -f "${KSRC}/drivers/Kconfig" -o ! -f "${KSRC}/drivers/Makefile" ] && \
	err_handler "nokern"

init_env
cleanup_des
prep_ksrc

exit $RET
