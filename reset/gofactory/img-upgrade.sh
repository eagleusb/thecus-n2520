#! /bin/sh
##########################################################################
# For OS6 bin file upgarding
##########################################################################

PATH=/usr/local/sbin:$PATH

echo -e "Image-upgrading USB tool: 1.2.7\n"

# Setup environment
init_env(){
	export MODELNAME=`awk '/^MODELNAME/{print $2}' /proc/thecus_io`

	# make sure we mount USB disk on the specified mount point
	export USB_MNT="/usb"
	mkdir -p $USB_MNT

   	USBDISK="`awk '/Intf:USB/ {print $3}' /proc/scsi/scsi | cut -d":" -f2`"
	umount $USB_MNT
   	if [ -n "`grep "${USBDISK}1$" /proc/partitions`" ];then
		mount "/dev/${USBDISK}1" $USB_MNT
	else
		mount "/dev/${USBDISK}" $USB_MNT
	fi

	# install the newest img-tools
	IMGTOOLS="`readlink -f ${USB_MNT}/nas_img-tools-*.$(uname -m).rpm`"
	if [ -f "$IMGTOOLS" ];then
		pushd /
		rpm2cpio $IMGTOOLS | cpio -div
		popd
	else
		/img/bin/pic.sh LCM_MSG "FAIL due to" "lack of tool"
		while true; do
			echo "Buzzer 1" > /proc/thecus_io
			sleep 1
			echo "Buzzer 0" > /proc/thecus_io
			sleep 1
		done 
		exit
	fi
}

main(){
    MAC="`cat /sys/class/net/eth0/address | sed 's/://g'`"
	DATE="`date +"%Y%m%d%H%M"`"
	case $MODELNAME in
	N2520|N2560|N4520|N4560)
		sh -x /tmp/N2520-series.sh > /usb/upd_${MAC}_${DATE}.log 2>&1
		;;
	N2310)
		sh -x /tmp/N2310-series.sh > /usb/upd_${MAC}_${DATE}.log 2>&1
		;;
	esac
}

clean_up(){
	sync
	umount ${USB_MNT}
	poweroff -f
}

init_env
main
clean_up

