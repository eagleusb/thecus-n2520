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
	THECUS_DRV="${WORK_DIR}/src"
	THECUS_INC="${WORK_DIR}/include"
	THECUS_CFG="\nsource \"drivers/thecus/Kconfig\""
	THECUS_OBJ="obj-y += thecus/"

	LINUX_INC="${KSRC}/include/linux"
	KDDRV="${KSRC}/drivers"
	KDDRV_CFG="${KDDRV}/Kconfig"
	KDDRV_MAKE="${KDDRV}/Makefile"
}

cleanup_des()
{
	rm -rf ${LINUX_INC}/thecus*
	rm -rf ${KDDRV}/thecus
	sed -i '/thecus/d' $KDDRV_CFG
	sed -i '/thecus/d' $KDDRV_MAKE
}

prep_ksrc()
{
	# copy our header files to linux includes
	cp -a $THECUS_INC/* ${LINUX_INC}/
	# copy our drivers to be a part of kernel drivers
	cp -a $THECUS_DRV ${KDDRV}/thecus
	sed -i '/i2c/a\'"$THECUS_CFG" $KDDRV_CFG
	sed -i '/i2c/a\'"$THECUS_OBJ" $KDDRV_MAKE
}


KSRC=$1
[ -z "$KSRC" ] && usage
[ ! -f "${KSRC}/drivers/Kconfig" -o ! -f "${KSRC}/drivers/Makefile" ] && \
	err_handler "nokern"

init_env
cleanup_des
prep_ksrc

exit 0
