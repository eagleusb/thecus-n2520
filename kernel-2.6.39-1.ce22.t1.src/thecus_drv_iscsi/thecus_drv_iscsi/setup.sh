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
	THECUS_DRV="${WORK_DIR}/src/target/iscsi"
	THECUS_CFG="\nsource \"drivers/target/iscsi/Kconfig\""
	THECUS_OBJ="obj-\$(CONFIG_ISCSI_TARGET) += iscsi/"

	KDDRV="${KSRC}/drivers/target"
	KDDRV_CFG="${KDDRV}/Kconfig"
	KDDRV_MAKE="${KDDRV}/Makefile"
}

cleanup_des()
{
if [ -d ${KDDRV}/iscsi ];then
	rm -rf ${KDDRV}/iscsi
	patch -R -d ${KSRC} -p2 < ${WORK_DIR}/iscsi.patch > ${WORK_DIR}/iscsi_R_patch.log 2>&1
	sed -i '/iscsi/d' $KDDRV_CFG
	sed -i '/iscsi/d' $KDDRV_MAKE
fi
}

prep_ksrc()
{
	# copy our drivers to be a part of kernel drivers
	cp -a $THECUS_DRV ${KDDRV}/iscsi
	patch -p2 -d ${KSRC} < ${WORK_DIR}/iscsi.patch > ${WORK_DIR}/iscsi_patch.log 2>&1
	sed -i '/loopback/a\'"$THECUS_CFG" $KDDRV_CFG
	sed -i '/loopback/a\'"$THECUS_OBJ" $KDDRV_MAKE
}


KSRC=$1
[ -z "$KSRC" ] && usage
[ ! -f "${KSRC}/drivers/Kconfig" -o ! -f "${KSRC}/drivers/Makefile" ] && \
	err_handler "nokern"

init_env
cleanup_des
prep_ksrc

exit 0
