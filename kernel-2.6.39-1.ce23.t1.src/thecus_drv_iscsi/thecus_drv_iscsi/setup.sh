#!/bin/sh

usage()
{
	echo "Usage: `basename $0` <kernel source>"
	echo "       This utility is used for patching iSCSI driver"
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
	noversion)
		echo "Invalid kernel version"
		exit 4
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
	# determine if the target kernel is 2.6.32 or 2.6.39
	KVER="`awk -F'=' '/^VERSION/ || /^PATCHLEVEL/ || /^SUBLEVEL/ {print $2}' ${LINUX_MK} |\
	       sed '{N;N;s/\t\|\n/./g;s/ //g}'`"
	case $KVER in
	2.6.32)
		KPATCH_NAME="iscsi-2.6.32.patch"
		SRC="src-2.6.32.2"
		THECUS_DRV="${WORK_DIR}/${SRC}/drivers/target"
		THECUS_INC="${WORK_DIR}/${SRC}/include/target"

		KDDRV="${KSRC}/drivers/target"
		KDINC="${KSRC}/include/target"
		;;
	2.6.39)
		KPATCH_NAME="iscsi.patch"
		SRC="src"
		THECUS_DRV="${WORK_DIR}/${SRC}/target/iscsi"
		THECUS_CFG="\nsource \"drivers/target/iscsi/Kconfig\""
		THECUS_OBJ="obj-\$(CONFIG_ISCSI_TARGET) += iscsi/"

		KDDRV="${KSRC}/drivers/target"
		KDDRV_CFG="${KDDRV}/Kconfig"
		KDDRV_MAKE="${KDDRV}/Makefile"
		;;
	*)
		err_handler "noversion"
		;;
	esac
	KPATCH="`readlink -f ${WORK_DIR}/${KPATCH_NAME}`"
	[ ! -f "${KPATCH}" ] && echo "No patch file for $KVER" && exit 1
}

cleanup_des()
{
	if [ -d ${KDDRV}/iscsi ]; then
		pushd ${KSRC}
		patch -R -p2 < ${KPATCH}
		RET=$?
		popd

		case $KVER in
		2.6.32)
			rm -rf ${KDDRV}
			[ -d ${KDINC} ] && rm -rf ${KDINC}
			;;
		2.6.39)
			rm -rf ${KDDRV}/iscsi
			sed -i '/iscsi/d' $KDDRV_CFG
			sed -i '/iscsi/d' $KDDRV_MAKE
			;;
		esac
	fi
}

prep_ksrc()
{
	# copy our drivers to be a part of kernel drivers
	[ -d "${THECUS_DRV}" ] && cp -a ${THECUS_DRV} ${KDDRV}
	[ -d "${THECUS_INC}" ] && cp -a ${THECUS_INC} ${KDINC}
	pushd ${KSRC}
	patch -p2 < ${KPATCH}
	RET=$?
	popd
	[ "${THECUS_CFG}" != "" ] && sed -i '/loopback/a\'"$THECUS_CFG" $KDDRV_CFG
	[ "${THECUS_OBJ}" != "" ] && sed -i '/loopback/a\'"$THECUS_OBJ" $KDDRV_MAKE
}

KSRC=$1
[ -z "$KSRC" ] && usage
[ ! -f "${KSRC}/drivers/Kconfig" -o ! -f "${KSRC}/drivers/Makefile" ] && \
	err_handler "nokern"

init_env
cleanup_des
prep_ksrc

exit ${RET}
