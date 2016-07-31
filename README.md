# Introduction

The goal of this is to understand the mechanics of Linux implementation by Thecus (which is bad), in order to do something less ugly.

# Hardware details

## Model

Thecus N2520

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

Main repositories validated (yum upgrade +x kernel*,httpd*,mod_* && /img/bin/sys_reboot)

      baseurl=http://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$releasever/Everything/$basearch/os/
      baseurl=http://archives.fedoraproject.org/pub/archive/fedora/linux/updates/$releasever/$basearch/

# Kernel

## Compilation

    yum install ncurses-devel
    rpmdev-setuptree
    yumdownloader --source kernel
    yum-builddep kernel-2.6.39-1.ce24.t1.src.rpm
    rpm -ivh kernel-2.6.39-1.ce24.t1.src.rpm
    rpmbuild -bp --target=$(uname -m) ~/rpmbuild/SPECS/linux-2.6.39.spec
    cd ~/rpmbuild/BUILD/kernel-2.6.39.fc16/linux-2.6.39.i686 && cp /boot/config-$(uname -r) ./.config && make menuconfig
    rpmbuild -bb --with baseonly --without debuginfo --target=`uname -m` ~/rpmbuild/SPECS/linux-2.6.39.spec

## Patches (.SPECS)

### Thecus

    %define buildid .grumpycat01

    %define SubPackage0 driver/thecus_drv_board 1.3.3
    %define SubPackage1 driver/thecus_drv_iscsi 1.1.2
    %define SubPackage2 driver/etron_drv_etxhci 1.0.1
    %define SubPackage3 driver/loop-AES v3.6i.2

    Source0: linux-%{kversion}.tar.gz
    Source1: kernel.config
    Source2: thecus_drv_board.tar.gz
    Source3: thecus_drv_iscsi.tar.gz
    Source4: etron_drv_etxhci.tar.gz
    Source5: loop-AES.tar.gz

    Requires: nas_img-tools >= 1.1.1-1

    # patch Thecus drivers to kernel source
    tar xfz %{SOURCE2}
    sh thecus_drv_board/setup.sh linux-%{kversion}.%{_target_cpu}
    tar xfz %{SOURCE3}
    sh thecus_drv_iscsi/setup.sh linux-%{kversion}.%{_target_cpu}
    tar xfz %{SOURCE4}
    sh etron_drv_etxhci/setup.sh linux-%{kversion}.%{_target_cpu}
    tar xfz %{SOURCE5}
    sh loop-AES/setup.sh linux-%{kversion}.%{_target_cpu}

### SOURCE/config

    CONFIG_BLK_DEV_LOOP=y
    CONFIG_BLK_DEV_LOOP_AES=y
    # CONFIG_BLK_DEV_LOOP_KEYSCRUB is not set
    # CONFIG_BLK_DEV_LOOP_PADLOCK is not set
    CONFIG_BLK_DEV_LOOP_INTELAES=y

    # Thecus Event support
    #
    CONFIG_THECUS=y
    # CONFIG_THECUS_EVENT is not set
    #
    # Miscellaneous Thecus Chip support
    #
    CONFIG_THECUS_BOARD=y
    # CONFIG_THECUS_PCA9532 is not set
    # CONFIG_THECUS_N16000_IO is not set
    # CONFIG_THECUS_N8900_IO is not set
    # CONFIG_THECUS_N2800_IO is not set
    # CONFIG_THECUS_N7700PRO_IO is not set
    CONFIG_THECUS_N2520_IO=y
    CONFIG_THECUS_PICUART_GPIO=y
    CONFIG_THECUS_PIC24=y
    # CONFIG_THECUS_N2310_IO is not set
    #
    # Miscellaneous Thecus Hardware Monitor support
    #
    # CONFIG_THECUS_SENSORS_F71882FG is not set
    # CONFIG_THECUS_SENSORS_F75375S is not set
    # CONFIG_THECUS_SENSORS_IT87 is not set
    # CONFIG_THECUS_SENSORS_W83795 is not set
    # CONFIG_THECUS_SENSORS_W83627EHF is not set
    # CONFIG_THECUS_SENSORS_TMP401 is not set

### Post macro
    %{expand:\
    if [ -e /proc/thecus_io ];then\
      # Intel SDK SW1.2 had modified kernel.
      # If NAS hasn't no XBMC or has new XBMC(>= 12.2.2.1-1), thecus's kernel can upgrade emmc.
      Ver="`rpm -q XBMC`"\
      if [ "$?" == "1" ] || ! [[ "$Ver" < "XBMC-12.2.2.1-1[.]" ]]; then\
        if [ "`/sbin/blockdev --getsize64 /dev/mmcblk0`" -lt 2000000000 ]; then\
          /usr/local/sbin/imgtool emmc "/dev/mmcblk0" -k /%{image_install_path}/%{?-k:%{-k*}}%{!?-k:vmlinuz}-%{KVERREL}%{?-v:.%{-v*}} || exit $?\
        else\
          /usr/local/sbin/imgtool emmc4 "/dev/mmcblk0" -k /%{image_install_path}/%{?-k:%{-k*}}%{!?-k:vmlinuz}-%{KVERREL}%{?-v:.%{-v*}} || exit $?\
        fi\
      fi\
    fi}\

# Cleanup

## Development

/img/bin/rc/rc.local
/img/bin/rc/rc.ntp
/img/bin/ntp_cfg
/img/bin/service
/img/bin/sys_reboot

Installation via new RPM or cp -Ruvf img/bin/* /img/bin/

## Delete

/etc/sysconfig/network-scripts/ifcfg-eth1

# Links

* [Debian on Thecus](http://thecus.nas-central.org/wiki/Debian)
* [Thecus BIOS](http://www.thecus.com/Downloads/BIOS/)
* [Thecus pkgs repository](http://download.thecuslink.com/release/)
* [Reset Thecus OS via USB](http://thecus.kayako.com/Knowledgebase/Article/View/633/0/n2520-n2560-n4520-n4560-os61-build-latest-usb-upgrad)e
* [Thecus 2520 official forum](http://forum.thecus.com/viewforum.php?f=74)
* [Fedora 16 to 17 upgrade](http://forums.fedoraforum.org/showthread.php?t=279057)
* [Fedora custom Kernel](https://fedoraproject.org/wiki/Building_a_custom_kernel)
* [CentOS rebuild SRPM](https://wiki.centos.org/HowTos/RebuildSRPM)
* [loop-AES](http://loop-aes.sourceforge.net/)
