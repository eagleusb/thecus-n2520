# Introduction

The goal of this is to understand the mechanics of Linux implementation by Thecus (which is bad), in order to do something less ugly.

# Hardware details

## CPU

    Model name             Intel(R) Atom(TM) CPU CE5315   @ 1.20GHz
    CPU MHz:               1200.018
    BogoMIPS:              2399.99
    Virtualization:        VT-x
    L1d cache:             24K
    L1i cache:             32K
    L2 cache:              512K

# Boot sequence

## Default initramfs (imgtool)

/boot/initramfs-2.2.0-1.t1 is provided by **nas_initramfs-2.2.0-1.fc16.i686.rpm**  

The default bootloader calls initramfs-2.2.0-1.t1/init, which launch the pivot and everything.  

It is installed via (rpm script)

    /usr/local/sbin/imgtool emmc /dev/mmcblk0 -i /boot/initramfs-2.2.0-1.fc16.i686  

## Boot cmdline creation (ceimggen)

To review the current kernel command line, type cat /proc/cmdline.  
The files are written to /boot/boots_$VAR.bin and are generated.  

For example the default boot cmdline generation **rpms/nas_img-bin-1.5.5.1-1.t1.i686/img/bin/resetDefault.sh**

    if [ -n "`grep nmyx25 /proc/mtd`" ];then
        TYPE="flash"
        DEVICE="/dev/mtdblock0"
        # check RAM size
        RAM_SIZE="`awk '/MemTotal/ {print $2}' /proc/meminfo`"
        [ "$RAM_SIZE" -lt 1048576 ] && MEM="1g" || MEM="2g"
        BOOTS="boots_${MEM}${XBMC_EN}.bin"
        [ -e "$DEVICE" ] && \
            /usr/local/sbin/ceimggen -u $TYPE $DEVICE SCRIPT /boot/$BOOTS
        RESULT=$?
        if [ "$RESULT" != "0" ];then
            set_log
        fi
    fi

At the end it contains the address of the ramdisk into the emmc memory and calls **nandbootkernel -id 0 "..."**

    ramdisk 0x8000000 0x8000000mfh list nandbootkernel -id 0 "biosdevname=0 console=ttyS0,115200 memmap=exactmap memmap=128K@128K memmap=1019M@1M vmalloc=586M max_loop=210 quiet"

MFH default table details

    /usr/local/sbin/imgtool emmc /dev/mmcblk0 -s
    img-tools Ver 1.1.3

    CEFDK S1            : 0x00080800 0x00010000
    CEFDK S2            : 0x00090800 0x0006f000
    CEFDK S1H           : 0x000ff800 0x00000800
    CEFDK S2H           : 0x00100000 0x00000800
    UC8051_FW           :
    Splash Screen       :
    Script              :
    CEFDK Parameters    :
    Platform Parameters :
    Kernel              : 0x00100800 0x003b5e60
    Ramdisk             : 0x00600800 0x01068c9f
    User Offset         : 0x03e00000

# Upstream Fedora compliance

## Fedora 16

Main repository validated (yum upgrade +x kernel* && reboot)

      baseurl=http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$releasever/Everything/$basearch/os/

# Links

* [Debian on Thecus](http://thecus.nas-central.org/wiki/Debian)
* [Thecus BIOS](http://www.thecus.com/Downloads/BIOS/)
* [Thecus pkgs repository](http://download.thecuslink.com/release/)
* [Reset Thecus OS via USB](http://thecus.kayako.com/Knowledgebase/Article/View/633/0/n2520-n2560-n4520-n4560-os61-build-latest-usb-upgrad)e
* [Thecus 2520 official forum](http://forum.thecus.com/viewforum.php?f=74)
* [CentOS rebuild SRPM](https://wiki.centos.org/HowTos/RebuildSRPM)
