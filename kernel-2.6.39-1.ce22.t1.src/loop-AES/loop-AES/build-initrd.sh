#!/bin/bash
#
#  build-initrd.sh
#
#  Written by Jari Ruusu, November 12 2012
#
#  Copyright 2001-2012 by Jari Ruusu.
#  Redistribution of this file is permitted under the GNU Public License.
#
#  Changes by Hauke Johannknecht 2001, 2009
#     - added Pivot mode
#     - added conffile-loading
#     - added initrdonly-mode
#     - added device 0 nodes
#     - added init-md mode 
#
#
#  Initrd can use three different methods to switch to encrypted root
#  device: change_root (USEPIVOT=0), pivot_root (USEPIVOT=1) and
#  initramfs/switch_root (USEPIVOT=2). change_root method is available on at
#  least 2.2, 2.4 and 2.6 kernels, and it works ok. pivot_root method is
#  available on 2.4 and later kernels, and offers much nicer wrong
#  passphrase case handling because initrd code can properly shutdown the
#  kernel. initramfs/switch_root method is available on 2.6.13 and later
#  kernels, and is similar to pivot_root. Proper shutdown is important for
#  software RAID devices and such. change_root, pivot_root, and
#  initramfs/switch_root require slightly different kernel and bootloader
#  configurations.
#
#  kernel .config :  CONFIG_BLK_DEV_RAM=y
#  (USEPIVOT=0)      CONFIG_BLK_DEV_RAM_SIZE=4096
#                    CONFIG_BLK_DEV_INITRD=y
#                    CONFIG_MINIX_FS=y
#                    CONFIG_PROC_FS=y
#                    CONFIG_CRAMFS=n  (or CONFIG_CRAMFS=m)
#
#  kernel .config :  CONFIG_BLK_DEV_RAM=y
#  (USEPIVOT=1)      CONFIG_BLK_DEV_RAM_SIZE=4096
#                    CONFIG_BLK_DEV_INITRD=y
#                    CONFIG_MINIX_FS=y
#
#  kernel .config :  CONFIG_BLK_DEV_INITRD=y
#  (USEPIVOT=2)
#
#  /etc/lilo.conf :  initrd=/boot/initrd.gz
#  (USEPIVOT=0)      root=/dev/ram1
#                                 ^
#  /etc/lilo.conf :  append="init=/linuxrc rootfstype=minix"
#  (USEPIVOT=1)      initrd=/boot/initrd.gz
#                    root=/dev/ram0
#                                 ^
#  /etc/lilo.conf :  initrd=/boot/initrd.gz
#  (USEPIVOT=2)
#
#  /boot/grub/menu.lst :  root (hd0,0)
#  (USEPIVOT=0)           kernel /vmlinuz root=101
#                         initrd /initrd.gz      ^
#
#  /boot/grub/menu.lst :  root (hd0,0)
#  (USEPIVOT=1)           kernel /vmlinuz root=100 init=/linuxrc rootfstype=minix
#                         initrd /initrd.gz      ^
#
#  /boot/grub/menu.lst :  root (hd0,0)
#  (USEPIVOT=2)           kernel /vmlinuz
#                         initrd /initrd.gz
#
#  usage :  ./build-initrd.sh [configfile]
#           lilo
#           mkdir /boot/modules-`uname -r`
#           cp -p /lib/modules/`uname -r`/block/loop.*o /boot/modules-`uname -r`/
#  or                                     ^^^^^
#           cp -p /lib/modules/`uname -r`/extra/loop.*o /boot/modules-`uname -r`/
#                                         ^^^^^
#  2.4 and older kernels always install to block/ directory
#  2.6 kernels with loop-AES-v3.2a and later install to extra/ directory
#

### All default-values can be altered via the configfile

# 1 = use devfs, 0 = use classic disk-based device names. If this is
# enabled (USEDEVFS=1) then setting USEPIVOT=1 is also required and kernel
# must be configured with CONFIG_DEVFS_FS=y CONFIG_DEVFS_MOUNT=y
USEDEVFS=0

# 0 = use old change_root, 1 = use pivot_root, 2 = use initramfs/switch_root
# See above header for root= and append= lilo.conf definitions.
# pivot_root is not available on 2.2 and older kernels.
# initramfs/switch_root is not available on kernels older than 2.6.13
USEPIVOT=1

# Unencrypted /boot partition. If devfs is enabled (USEDEVFS=1), this must
# be specified as genuine devfs name.
BOOTDEV=/dev/hda1

# /boot partition file system type
BOOTTYPE=ext2

# Encrypted root partition. If devfs is enabled (USEDEVFS=1), this must
# be specified as genuine devfs name.
CRYPTROOT=/dev/hda2

# root partition file system type
ROOTTYPE=ext2

# Encryption type (AES128 / AES192 / AES256) of root partition
CIPHERTYPE=AES128

# Optional password seed for root partition
# (this option is obsolete when gpg encrypted key file is used)
#PSEED="-S XXXXXX"

# Optional password iteration count for root partition
# (this option is obsolete when gpg encrypted key file is used)
#ITERCOUNTK="-C 100"

# This code is passed to cipher transfer function.
LOINIT="-I 0"

# 1 = use gpg key file to mount root partition, 0 = use normal key.
# If this is enabled (USEGPGKEY=1), file named rootkey.gpg or whatever
# GPGKEYFILE is set to must be manually copied to /boot (or to
# EXTERNALGPGDEV device if EXTERNALGPGFILES=1). If rootkey.gpg is not
# encrypted with symmetric cipher, pubring.gpg and secring.gpg must be
# manually copied to /boot (or to EXTERNALGPGDEV device if
# EXTERNALGPGFILES=1).
USEGPGKEY=1

# gpg key filename. Only used if USEGPGKEY=1
GPGKEYFILE=rootkey.gpg

# 1 = mount removable device EXTERNALGPGDEV that contains gpg key files
# 0 = don't mount
EXTERNALGPGFILES=0

# Device name that contains gpg key files. If devfs is
# enabled (USEDEVFS=1), this must be specified as genuine devfs name.
# Only used if EXTERNALGPGFILES=1
EXTERNALGPGDEV=/dev/fd0

# Removable device EXTERNALGPGDEV file system type
# Only used if EXTERNALGPGFILES=1
EXTERNALGPGTYPE=ext2

# 1 = use loop module, 0 = loop driver linked to kernel
USEMODULE=1

# 1 = stop after creating and copying initrd, 0 = also copy tools/libs
INITRDONLY=0

# Source root directory where files are copied from
SOURCEROOT=

# Destination root directory where files are written to.
# Normally this is empty, but if you run this script on some other root
# (i.e. Knoppix live CD), this must be configured to point to directory
# where your about-to-be-encrypted root partition is mounted. This script
# checks that an initrd directory exists there.
DESTINATIONROOT=

# dest-dir below dest-root
DESTINATIONPREFIX=/boot

# Name of created init ram-disk
INITRDGZNAME=initrd.gz

# Encrypted root loop device index (0 ... 7), 5 == /dev/loop5
# Device index must be one character even if max_loop is greater than 8
# _must_ match /etc/fstab entry:   /dev/loop5  /  ext2  defaults,xxxx  0  1
ROOTLOOPINDEX=5

# Temporary loop device index used in this script, 7 == /dev/loop7
TEMPLOOPINDEX=7

# Additional loop module parameters.
# Example: LOOPMODPARAMS="max_loop=8 lo_prealloc=125,5,200"
LOOPMODPARAMS=""

# 1 = set keyboard to UTF-8 mode, 0 = don't set
UTF8KEYBMODE=0

# 1 = load national keyboard layout, 0 = don't load
# You _must_ manually copy correct keyboard layout to /boot/default.kmap
# which must be in uncompressed form. (can not be .gz file)
LOADNATIONALKEYB=0

# Try to auto-assemble linux software raid md devices. This is only
# needed and used on USEPIVOT=2 (initramfs/switch_root) type build.
# This gets automatically disabled if none of needed devices (BOOTDEV,
# CRYPTROOT, or EXTERNALGPGDEV) is a /dev/md* device.
# 1 = auto-assemble, 0 = no
INITMD=1

# Delay in seconds before /linuxrc attempts to auto-assemble
# linux software raid md devices. This is only needed and used
# on USEPIVOT=2 (initramfs/switch_root) type build.
INITMDDELAY=1

# Initial delay in seconds before /linuxrc attempts to mount /boot
# partition. Slow devices (USB-sticks) may need some delay.
INITIALDELAY=0

# Delay in seconds before /linuxrc attempts to mount partition containing
# external gpg key files. Slow devices (USB-sticks) may need some delay.
MOUNTDELAY=0

# 1 = prompt for BOOT-TOOLS media and ENTER press before mounting /boot
# 0 = normal case, don't prompt
TOOLSPROMPT=0

# 1 = use "rootsetup" program that executes losetup to initialize loop
# 0 = use normal "losetup" program directly to initialize loop
# If enabled, rootsetup program (+libs) _must_ be manually copied to /boot.
USEROOTSETUP=0

# 1 = use dietlibc to build /linuxrc. This permits passing parameters to init.
# 0 = use glibc to build /linuxrc. This prevents passing parameters to init
# and includes hacks that may be incompatible with some versions of glibc.
# The dietlibc can be found at http://www.fefe.de/dietlibc/
USEDIETLIBC=1

# C compiler used to compile /linuxrc program.
# 32bit x86 ubuntu-7.04 gcc-4.1.2 is known to miscompile /linuxrc. Affected
# users should install gcc-3.3 package, and change this to GCC=gcc-3.3
GCC=gcc

# 1 = load extra module, 0 = don't load
# If this is enabled, module must be manually copied to
# /boot/modules-KERNELRELEASE/ directory under name like foomatic.o
EXTRAMODULELOAD1=0
EXTRAMODULENAME1="foomatic"
EXTRAMODULEPARAMS1="frobnicator=123 fubar=abc"
# 1 = load extra module, 0 = don't load
EXTRAMODULELOAD2=0
EXTRAMODULENAME2=""
EXTRAMODULEPARAMS2=""
# 1 = load extra module, 0 = don't load
EXTRAMODULELOAD3=0
EXTRAMODULENAME3=""
EXTRAMODULEPARAMS3=""
# 1 = load extra module, 0 = don't load
EXTRAMODULELOAD4=0
EXTRAMODULENAME4=""
EXTRAMODULEPARAMS4=""
# 1 = load extra module, 0 = don't load
EXTRAMODULELOAD5=0
EXTRAMODULENAME5=""
EXTRAMODULEPARAMS5=""

# 1 = run extra command on encrypted root before starting init,
# 2 = run + show command, 0 = don't run
# If you set up loop devices, static loop and backing device nodes must
# exist on /dev directory on read-only mounted encrypted root file system.
# If needed, you can create them manually by booting to rescue
# floppy/CD-ROM, mounting the file system, and using mknod program to create
# static device nodes. Like this:
# mknod -m 660 /mnt/dev/loop6 b 7 6
# mknod -m 660 /mnt/dev/md3 b 9 3
EXTRACOMMANDRUN1=0
EXTRACOMMANDSTR1="/sbin/losetup -e AES128 -P /etc/cleartextkey-loop6.txt /dev/loop6 /dev/md3"
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN2=0
EXTRACOMMANDSTR2=""
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN3=0
EXTRACOMMANDSTR3=""
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN4=0
EXTRACOMMANDSTR4=""
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN5=0
EXTRACOMMANDSTR5=""
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN6=0
EXTRACOMMANDSTR6=""
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN7=0
EXTRACOMMANDSTR7=""
# 1 = run extra command, 2 = run + show command, 0 = don't run
EXTRACOMMANDRUN8=0
EXTRACOMMANDSTR8=""

### End of options


if [ $# = 1 ] ; then
    if [ ! -f $1 ] ; then
        echo "ERROR: Can't find configfile '$1'"
        echo "Usage: $0 [configfile]"
        exit 1
    fi
    echo "Loading config from '$1'"
    . $1
fi

DEVFSSLASH1=
DEVFSRAMDSK=/dev/ram
if [ ${USEDEVFS} == 1 ] ; then
    DEVFSSLASH1=/
    DEVFSRAMDSK=/dev/rd/
fi
DEVFSSLASH2=
if [ -c /dev/.devfsd ] ; then
    DEVFSSLASH2=/
fi
LOSETUPPROG=losetup
if [ ${USEROOTSETUP} == 1 ] ; then
    LOSETUPPROG=rootsetup
fi
if [ ${USEGPGKEY} == 0 ] ; then
    EXTERNALGPGFILES=0
fi
GPGMOUNTDEV=
GPGMNTPATH=lib
if [ ${EXTERNALGPGFILES} == 1 ] ; then
    GPGMOUNTDEV=${EXTERNALGPGDEV}
    GPGMNTPATH=mnt
fi

INITMD_ENABLED=0
if [ ${INITMD} == 1 ] ; then
    for x in ${BOOTDEV} ${CRYPTROOT} ${GPGMOUNTDEV} ; do
        case ${x} in
            /dev/md[0-9]|/dev/md[0-9][0-9])
                INITMD_ENABLED=1
                INITMD_NAME=${x}
                break
                ;;
        esac
    done
fi

if [ ${USEDIETLIBC} == 1 ] ; then
    x=`which diet`
    if [ x${x} == x ] ; then
        echo "*****************************************************************"
        echo "***  This script was configured to build linuxrc using        ***"
        echo "***  dietlibc, but it appears that dietlibc is unavailable.   ***"
        echo "***  Script aborted.                                          ***"
        echo "*****************************************************************"
        exit 1
    fi
fi

set -e
umask 077
cat - <<EOF >tmp-c-$$.c

/* Note: this program does not initialize C library, so all level 3    */
/* library calls are forbidden. Only level 2 system calls are allowed. */

#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mount.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <fcntl.h>
#include <time.h>

#if ${INITMD_ENABLED} && ${USEPIVOT} == 2
#include <sys/ioctl.h>
#include <linux/major.h>
#include <linux/raid/md_u.h>
#endif

#ifndef MS_MOVE
# define MS_MOVE 8192
#endif

#if ${USEPIVOT} == 1
# if ${USEDIETLIBC}
   extern int pivot_root(const char *, const char *);
# else
#  include <sys/syscall.h>
#  include <errno.h>
#  include <linux/unistd.h>
#  if !defined(__NR_pivot_root) && !defined(SYS_pivot_root) && defined(__i386__)
#   define __NR_pivot_root 217
    static _syscall2(int,pivot_root,const char *,new_root,const char *,put_old)
#  else
#   define pivot_root(new_root,put_old) syscall(SYS_pivot_root,new_root,put_old)
#  endif
# endif
#endif

#if (defined(__GLIBC__) && __GLIBC__ >= 2) || defined(__dietlibc__)
# include <sys/reboot.h>
# define HaltKernel() reboot(0xCDEF0123)  /* LINUX_REBOOT_CMD_HALT */
#else
extern int reboot(int, int, int);
# define HaltKernel() reboot(0xfee1dead, 672274793, 0xCDEF0123)
#endif

#if ${USEDIETLIBC}
static char ** argv_init;
static char ** envp_init;
extern char ** environ;
#else
static char * argv_init[] = { "init", 0, };
static char * envp_init[] = { "HOME=/", "TERM=linux", 0, };
#endif

void strCat(char *d, char *s)
{
    while(*d) d++;
    while(*s) *d++ = *s++;
    *d = 0;
}

void wrStr(char *s)
{
    char *p = s;
    int x = 0;

    while(*p) p++, x++;
    write(1, s, x);
}

int exeWait(char *p)
{
    int x, y;
    char *a[50], *e[1];

    if(!(x = fork())) {
        while(*p && (x < ((sizeof(a) / sizeof(char *)) - 1))) {
            a[x++] = p;
            while(*p && (*p != ' ') && (*p != '\t')) p++;
            while((*p == ' ') || (*p == '\t')) *p++ = 0;
        }
        e[0] = a[x] = 0;
        if(x) execve(a[0], &a[0], &e[0]);
        _exit(1);
    }
    if(x == -1) {
        wrStr("linuxrc: fork failed\n");
        return(1);
    }
    waitpid(x, &y, 0);
    if(!WIFEXITED(y) || (WEXITSTATUS(y) != 0)) {
        wrStr("Command \""); wrStr(p); wrStr("\" returned error\n");
        return(1);
    }
    return(0);
}

void doHalt()
{
    int x, y;
    struct timespec req;

    sync();
    if(!(x = fork())) HaltKernel();
    waitpid(x, &y, 0);
    for(;;) {
        req.tv_sec = 5;
        req.tv_nsec = 0;
        nanosleep(&req, 0);
    }
}

void runInit()
{
#if ${USEDIETLIBC}
    if(argv_init[0]) argv_init[0] = "init";
    envp_init = environ;
#endif
    execve("/sbin/init", argv_init, envp_init);
    execve("/etc/init", argv_init, envp_init);
    execve("/bin/init", argv_init, envp_init);
    wrStr("Bummer! Launching init failed\n");
    doHalt();
}

#if ${USEPIVOT} == 2
void removeInitramfsFiles()
{
    int x;
    x =  unlink("${BOOTDEV}");
    x |= unlink("${CRYPTROOT}");
#if ${EXTERNALGPGFILES}
    x |= unlink("${GPGMOUNTDEV}");
#endif
    x |= unlink("/dev/console");
    x |= unlink("/dev/tty");
    x |= unlink("/dev/tty1");
    x |= unlink("/dev/null");
    x |= unlink("/dev/zero");
    x |= unlink("/dev/ram0");
    x |= unlink("/dev/ram1");
    x |= unlink("/dev/loop${ROOTLOOPINDEX}");
    x |= rmdir("/dev");
    x |= rmdir("/lib");
    x |= unlink("/lib64");
#if ${EXTERNALGPGFILES}
    x |= rmdir("/mnt");
#endif
#if ${USEGPGKEY}
    x |= unlink("/bin");
#endif
    x |= unlink("/init");
    if(x) wrStr("removing initramfs files failed. (not fatal)\n");
}
#endif

#if ${USEDIETLIBC}
int main(int argc, char **argv)
#else
void _start()
#endif
{
    int x = 0;
    char buf[1000];
#if ${USEMODULE} || ${EXTRAMODULELOAD1} || ${EXTRAMODULELOAD2} || ${EXTRAMODULELOAD3} || ${EXTRAMODULELOAD4} || ${EXTRAMODULELOAD5}
    struct utsname un;
    char *modext;
#endif

#if ${USEDIETLIBC}
    argv_init = argv;
#endif

#if ${USEPIVOT}
    if(getpid() != 1) {
        /* pivot_root was configured, but kernel has */
        /* wandered off to change_root code path!    */
        wrStr("ERROR: initrd config says USEPIVOT>0, but bootloader acts like USEPIVOT=0\n");
        _exit(0);
    }
#else
    if(getpid() == 1) {
        /* change_root was configured, but kernel    */
        /* has wandered off to pivot_root code path! */
        wrStr("ERROR: initrd config says USEPIVOT=0, but bootloader acts like USEPIVOT>0\n");
        runInit();
    }
#endif

#if ${INITMD_ENABLED} && ${USEPIVOT} == 2
#if ${INITMDDELAY}
    {
        struct timespec req;
        wrStr("Delaying md autoassemble for ${INITMDDELAY} seconds...\n");
        req.tv_sec = ${INITMDDELAY};
        req.tv_nsec = 0;
        nanosleep(&req, 0);
        wrStr("...delay complete, continuing\n");
    }
#endif
    {
        int y;
        if((y = open("${INITMD_NAME}", O_RDONLY|O_DIRECT, 0)) == -1) {
            wrStr("Unable to open ${INITMD_NAME} for triggering autoassemble\n");
            goto fail4;
        }
        if(ioctl(y, RAID_AUTORUN, 0)) {
            wrStr("Unable to trigger md autoassemble\n");
            close(y);
            goto fail4;
        }
        close(y);
    }
#endif

#if ${INITIALDELAY}
    {
        struct timespec req;
        wrStr("Delaying ${BOOTDEV} mount for ${INITIALDELAY} seconds...\n");
        req.tv_sec = ${INITIALDELAY};
        req.tv_nsec = 0;
        nanosleep(&req, 0);
        wrStr("...delay complete, continuing\n");
    }
#endif

#if ${TOOLSPROMPT}
    wrStr("Please insert BOOT-TOOLS media, and press ENTER  ");
    read(0, buf, sizeof(buf));
#endif

    /* this intentionally mounts /boot partition as /lib */
    if(mount("${BOOTDEV}", "/lib", "${BOOTTYPE}", MS_MGC_VAL | MS_RDONLY, 0)) {
        wrStr("Mounting ${BOOTDEV} as /lib failed\n");
        goto fail4;
    }

#if ${UTF8KEYBMODE}
    buf[0] = 0;
    strCat(buf, "/lib/kbd_mode -u");
    exeWait(buf);
#endif
#if ${LOADNATIONALKEYB}
    buf[0] = 0;
    strCat(buf, "/lib/loadkeys");
#if ${UTF8KEYBMODE}
    strCat(buf, " -u");
#endif
    strCat(buf, " /lib/default.kmap");
    exeWait(buf);
#endif

#if ${USEMODULE} || ${EXTRAMODULELOAD1} || ${EXTRAMODULELOAD2} || ${EXTRAMODULELOAD3} || ${EXTRAMODULELOAD4} || ${EXTRAMODULELOAD5}
    uname(&un);
    if((un.release[0] > '2') || (un.release[1] != '.') || (un.release[2] >= '6') || (un.release[3] != '.')) {
        modext = ".ko";
    } else {
        modext = ".o";
    }
#endif

#if ${USEMODULE}
    buf[0] = 0;
    strCat(buf, "/lib/insmod /lib/modules-");
    strCat(buf, &un.release[0]);
    strCat(buf, "/loop");
    strCat(buf, modext);
    strCat(buf, " ${LOOPMODPARAMS}");
    if(exeWait(buf)) goto fail5;
#endif

#if ${EXTRAMODULELOAD1}
    buf[0] = 0;
    strCat(buf, "/lib/insmod /lib/modules-");
    strCat(buf, &un.release[0]);
    strCat(buf, "/${EXTRAMODULENAME1}");
    strCat(buf, modext);
    strCat(buf, " ${EXTRAMODULEPARAMS1}");
    if(exeWait(buf)) goto fail5;
#endif
#if ${EXTRAMODULELOAD2}
    buf[0] = 0;
    strCat(buf, "/lib/insmod /lib/modules-");
    strCat(buf, &un.release[0]);
    strCat(buf, "/${EXTRAMODULENAME2}");
    strCat(buf, modext);
    strCat(buf, " ${EXTRAMODULEPARAMS2}");
    if(exeWait(buf)) goto fail5;
#endif
#if ${EXTRAMODULELOAD3}
    buf[0] = 0;
    strCat(buf, "/lib/insmod /lib/modules-");
    strCat(buf, &un.release[0]);
    strCat(buf, "/${EXTRAMODULENAME3}");
    strCat(buf, modext);
    strCat(buf, " ${EXTRAMODULEPARAMS3}");
    if(exeWait(buf)) goto fail5;
#endif
#if ${EXTRAMODULELOAD4}
    buf[0] = 0;
    strCat(buf, "/lib/insmod /lib/modules-");
    strCat(buf, &un.release[0]);
    strCat(buf, "/${EXTRAMODULENAME4}");
    strCat(buf, modext);
    strCat(buf, " ${EXTRAMODULEPARAMS4}");
    if(exeWait(buf)) goto fail5;
#endif
#if ${EXTRAMODULELOAD5}
    buf[0] = 0;
    strCat(buf, "/lib/insmod /lib/modules-");
    strCat(buf, &un.release[0]);
    strCat(buf, "/${EXTRAMODULENAME5}");
    strCat(buf, modext);
    strCat(buf, " ${EXTRAMODULEPARAMS5}");
    if(exeWait(buf)) goto fail5;
#endif

#if ${EXTERNALGPGFILES}
#if ${MOUNTDELAY}
    {
        struct timespec req;
        wrStr("Delaying ${EXTERNALGPGDEV} mount for ${MOUNTDELAY} seconds...\n");
        req.tv_sec = ${MOUNTDELAY};
        req.tv_nsec = 0;
        nanosleep(&req, 0);
        wrStr("...delay complete, continuing\n");
    }
#endif
    if(mount("${EXTERNALGPGDEV}", "/mnt", "${EXTERNALGPGTYPE}", MS_MGC_VAL | MS_RDONLY, 0)) {
        wrStr("Mounting ${EXTERNALGPGDEV} containing gpg key files failed.\n");
        goto fail5;
    }
#endif

    tryAgain:
#if !(${USEROOTSETUP})
    wrStr("\nEncrypted file system, please supply correct password to continue\n\n");
#endif

    buf[0] = 0;
    strCat(buf, "/lib/${LOSETUPPROG} -e ${CIPHERTYPE} ${PSEED} ${ITERCOUNTK} ${LOINIT}");
#if ${USEGPGKEY}
    strCat(buf, " -K /${GPGMNTPATH}/${GPGKEYFILE} -G /${GPGMNTPATH}");
#endif
    strCat(buf, " /dev/loop${DEVFSSLASH1}${ROOTLOOPINDEX} ${CRYPTROOT}");

    if(exeWait(buf)) {
        if(++x >= 5) goto fail3;
        goto tryAgain;
    }

#if !(${USEROOTSETUP})
    wrStr("\n");
#endif

#if ${USEPIVOT}
    if(mount("/dev/loop${DEVFSSLASH1}${ROOTLOOPINDEX}", "/new-root", "${ROOTTYPE}", MS_MGC_VAL | MS_RDONLY, 0)) {
        wrStr("Mounting /dev/loop${DEVFSSLASH1}${ROOTLOOPINDEX} failed\n");
        buf[0] = 0;
        strCat(buf, "/lib/${LOSETUPPROG} -d /dev/loop${DEVFSSLASH1}${ROOTLOOPINDEX}");
        if(exeWait(buf)) goto fail3;
        if(++x >= 5) goto fail3;
        goto tryAgain;
    }
#if ${EXTERNALGPGFILES}
    umount("/mnt");
#endif
    umount("/lib");
    if(chdir("/new-root")) {
        wrStr("chdir() to /new-root failed\n");
        goto fail1;
    }

#if ${USEPIVOT} == 2
    removeInitramfsFiles();
    if(mount(".", "/", 0, MS_MGC_VAL | MS_MOVE, 0)) {
        wrStr("Overmounting root failed\n");
        fail1:
        chdir("/");
        umount("/new-root");
        goto fail4;
    }
    /* initramfs/switch_root type setup wants chroot() immediately after mount() */
    if(chroot(".")) {
        wrStr("chroot() to new root failed\n");
        goto fail1;
    }
#else
    if(pivot_root(".", "initrd")) {
        wrStr("pivot_root() to new root failed.\n Either 'initrd' directory is missing from your encrypted root partition\n or your kernel doesn't have pivot_root system call.\n");
        fail1:
        chdir("/");
        umount("/new-root");
        goto fail4;
    }
    /* pivot_root type setup wants chdir("/") immediately after pivot_root() */
#endif
    chdir("/");

#if ${USEDEVFS}
    if(mount("none", "dev", "devfs", MS_MGC_VAL, 0)) {
        wrStr("Mounting /dev failed\n");
        goto fail1;
    }
#endif

    x = open("dev/console", O_RDWR, 0);
    if(x == -1) {
        wrStr("Opening /dev/console on encrypted root failed\n");
        goto fail1;
    }
    dup2(x, 0);
    dup2(x, 1);
    dup2(x, 2);
    close(x);

#if ${USEPIVOT} == 1
    /* pivot_root type setup wants chroot() after chdir("/") */
    if(chroot(".")) {
        wrStr("chroot() to new root failed\n");
        goto fail1;
    }
    wrStr("Pivoting to encrypted root completed successfully\n");
#else
    wrStr("Switching to encrypted root completed successfully\n");
#endif

#if ${EXTRACOMMANDRUN1}
#if ${EXTRACOMMANDRUN1} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR1}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR1}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN2}
#if ${EXTRACOMMANDRUN2} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR2}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR2}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN3}
#if ${EXTRACOMMANDRUN3} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR3}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR3}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN4}
#if ${EXTRACOMMANDRUN4} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR4}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR4}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN5}
#if ${EXTRACOMMANDRUN5} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR5}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR5}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN6}
#if ${EXTRACOMMANDRUN6} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR6}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR6}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN7}
#if ${EXTRACOMMANDRUN7} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR7}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR7}"); exeWait(buf);
#endif
#if ${EXTRACOMMANDRUN8}
#if ${EXTRACOMMANDRUN8} == 2
    wrStr("Running command: ${EXTRACOMMANDSTR8}\n");
#endif
    buf[0] = 0; strCat(buf, "${EXTRACOMMANDSTR8}"); exeWait(buf);
#endif
    runInit();

#else
    /* USEPIVOT=0 configured, write new device number to real-root-dev */
    if(mount("none", "/proc", "proc", MS_MGC_VAL, 0)) {
        wrStr("Mounting /proc failed\n");
        goto fail3;
    }
    if((x = open("/proc/sys/kernel/real-root-dev", O_WRONLY, 0)) == -1) {
        wrStr("Unable to open real-root-dev\n");
        goto fail2;
    }
    write(x, "0x70${ROOTLOOPINDEX}\n", 6);
    close(x);
    fail2:
    umount("/proc");
#endif

    fail3:
#if ${EXTERNALGPGFILES}
    umount("/mnt");
#endif
#if ${USEMODULE} || ${EXTERNALGPGFILES} || ${EXTRAMODULELOAD1} || ${EXTRAMODULELOAD2} || ${EXTRAMODULELOAD3} || ${EXTRAMODULELOAD4} || ${EXTRAMODULELOAD5}
    fail5:
#endif
    umount("/lib");
    fail4:
#if ${USEPIVOT}
    doHalt();
#endif
    _exit(0);
}
EOF

if [ ${USEDIETLIBC} == 1 ] ; then
    diet ${GCC} -Wall -O2 -s -static -pipe tmp-c-$$.c -o tmp-c-$$
else
    ${GCC} -Wall -O2 -s -static -nostartfiles -pipe tmp-c-$$.c -o tmp-c-$$
fi
rm -f tmp-c-$$.[co]

mkdir tmp-d-$$
if [ ${USEPIVOT} != 2 ] ; then
    x=`cat tmp-c-$$ | wc -c`
    y=`expr ${x} + 1023`
    x=`expr ${y} / 1024`
    y=`expr ${x} + 11`
    if [ ${x} -gt 7 ] ; then
        y=`expr ${y} + 1`
    fi
    if [ ${x} -gt 519 ] ; then
        y=`expr ${y} + 3`
    fi
    if [ ${USEGPGKEY} == 1 ] ; then
        y=`expr ${y} + 1`
    fi
    if [ ${EXTERNALGPGFILES} == 1 ] ; then
        y=`expr ${y} + 1`
    fi

    dd if=/dev/zero of=tmp-i-$$ bs=1024 count=${y}
    /sbin/mkfs -t minix -i 32 tmp-i-$$ ${y}
    mount -t minix tmp-i-$$ tmp-d-$$ -o loop=/dev/loop${DEVFSSLASH2}${TEMPLOOPINDEX}
fi
cd tmp-d-$$

mkdir dev lib
ln -s lib lib64

if [ ${USEPIVOT} != 2 ] ; then
    mv ../tmp-c-$$ linuxrc
else
    mv ../tmp-c-$$ init
fi

if [ ${EXTERNALGPGFILES} == 1 ] ; then
    mkdir mnt
fi

if [ ${USEGPGKEY} == 1 ] ; then
    ln -s lib bin
fi

if [ ${USEPIVOT} != 0 ] ; then
    mkdir new-root
else
    mkdir proc
fi

# <device name prefix> <major dev-id> <minor dev-id start> <device 0 suffix>
function maybeMakeDiskNode
{
    x=$3
    for i in "$4" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ; do
        for y in ${BOOTDEV} ${CRYPTROOT} ${GPGMOUNTDEV} ; do
            if [ ${y} == /dev/$1${i} ] ; then
                mknod dev/$1${i} b $2 ${x}
                mknodCount=`expr ${mknodCount} + 1`
            fi
        done
        x=`expr ${x} + 1`
    done
    return
}
if [ ${USEDEVFS} == 0 ] ; then
    mknodCount=0
    mknodRefCount=2
    if [ ${EXTERNALGPGFILES} == 1 ] ; then
        mknodRefCount=`expr ${mknodRefCount} + 1`
    fi

    maybeMakeDiskNode hda       3   0 ""
    maybeMakeDiskNode hdb       3  64 ""
    maybeMakeDiskNode hdc      22   0 ""
    maybeMakeDiskNode hdd      22  64 ""
    maybeMakeDiskNode hde      33   0 ""
    maybeMakeDiskNode hdf      33  64 ""
    maybeMakeDiskNode hdg      34   0 ""
    maybeMakeDiskNode hdh      34  64 ""
    maybeMakeDiskNode sda       8   0 ""
    maybeMakeDiskNode sdb       8  16 ""
    maybeMakeDiskNode sdc       8  32 ""
    maybeMakeDiskNode sdd       8  48 ""
    maybeMakeDiskNode sde       8  64 ""
    maybeMakeDiskNode sdf       8  80 ""
    maybeMakeDiskNode sdg       8  96 ""
    maybeMakeDiskNode sdh       8 112 ""
    maybeMakeDiskNode uba     180   0 ""
    maybeMakeDiskNode ubb     180   8 ""
    maybeMakeDiskNode ubc     180  16 ""
    maybeMakeDiskNode ubd     180  24 ""
    maybeMakeDiskNode ube     180  32 ""
    maybeMakeDiskNode ubf     180  40 ""
    maybeMakeDiskNode ubg     180  48 ""
    maybeMakeDiskNode ubh     180  56 ""
    maybeMakeDiskNode scd      11   0  0
    maybeMakeDiskNode sr       11   0  0
    maybeMakeDiskNode md        9   0  0
    maybeMakeDiskNode fd        2   0  0
    maybeMakeDiskNode idac0d0p 72   0  0
    maybeMakeDiskNode idac0d1p 72  16  0
    maybeMakeDiskNode idac0d2p 72  32  0
    maybeMakeDiskNode idac0d3p 72  48  0

    if [ ${mknodCount} != ${mknodRefCount} ] ; then
        echo "*****************************************************************"
        echo "***  Internal build-initrd.sh error condition detected. This  ***"
        echo "***  script was supposed to create block device nodes for     ***"
        echo "***  BOOTDEV=, CRYPTROOT= and possibly EXTERNALGPGDEV= but    ***"
        echo "***  lacked knowledge of how to create at least one of them.  ***"
        echo "***  Script aborted.                                          ***"
        echo "*****************************************************************"
        cd ..
        if [ ${USEPIVOT} != 2 ] ; then
            umount tmp-d-$$
            rmdir tmp-d-$$
            rm tmp-i-$$
        else
            rm -rf tmp-d-$$
        fi
        exit 1
    fi

    # NOTE: If you add/remove/change these device names, then also edit
    # removeInitramfsFiles() function so it can remove all device nodes

    mknod dev/console c 5 1
    mknod dev/tty c 5 0
    mknod dev/tty1 c 4 1
    mknod dev/null c 1 3
    mknod dev/zero c 1 5
    mknod dev/ram0 b 1 0
    mknod dev/ram1 b 1 1
    mknod dev/loop${ROOTLOOPINDEX} b 7 ${ROOTLOOPINDEX}
fi

if [ ${USEPIVOT} != 2 ] ; then
    cd ..
    df tmp-d-$$
    umount tmp-d-$$
    rmdir tmp-d-$$
    sync ; sync ; sync
    gzip -9 tmp-i-$$
else
    find | cpio -o -H newc | gzip -9c >../tmp-i-$$.gz
    cd ..
    rm -rf tmp-d-$$
fi
mv tmp-i-$$.gz ${DESTINATIONROOT}${DESTINATIONPREFIX}/${INITRDGZNAME}
ls -l ${DESTINATIONROOT}${DESTINATIONPREFIX}/${INITRDGZNAME}

if [ ${INITRDONLY} == 1 ] ; then
    echo Done.
    sync
    exit 0
fi

z="/sbin/losetup"
if [ ${USEMODULE}${EXTRAMODULELOAD1}${EXTRAMODULELOAD2}${EXTRAMODULELOAD3}${EXTRAMODULELOAD4}${EXTRAMODULELOAD5} != 000000 ] ; then
    z="${z} /sbin/insmod"
    if [ -r ${SOURCEROOT}/sbin/insmod.modutils ] ; then
        z="${z} /sbin/insmod.modutils"
    fi
    if [ -r ${SOURCEROOT}/sbin/insmod.old ] ; then
        z="${z} /sbin/insmod.old"
    fi
fi
if [ ${UTF8KEYBMODE} == 1 ] ; then
    z="${z} "`which kbd_mode`
fi
if [ ${LOADNATIONALKEYB} == 1 ] ; then
    z="${z} "`which loadkeys`
fi
if [ ${USEGPGKEY} == 1 ] ; then
    z="${z} "`which gpg`
fi
for x in ${z} ; do
    OUTFILE=`echo ${x} | sed 's%.*/%%'`
    if [ -x ${SOURCEROOT}${x}.static ]; then
      SOURCEFILE=${SOURCEROOT}${x}.static
    else
      SOURCEFILE=${SOURCEROOT}${x}
    fi
    echo Copying ${SOURCEFILE} to ${DESTINATIONROOT}${DESTINATIONPREFIX}/${OUTFILE}
    cp -p ${SOURCEFILE} ${DESTINATIONROOT}${DESTINATIONPREFIX}/${OUTFILE} || echo "ERROR: cp command returned error status. Continuing anyway..."
    y=`ldd ${DESTINATIONROOT}${DESTINATIONPREFIX}/${OUTFILE} | perl -ne 'if(/([^ ]*) \(0x/){print "$1\n"}'`
    for a in ${y} ; do
        echo Copying ${SOURCEROOT}${a} to ${DESTINATIONROOT}${DESTINATIONPREFIX}
        cp -p ${SOURCEROOT}${a} ${DESTINATIONROOT}${DESTINATIONPREFIX} || echo "ERROR: cp command returned error status. Continuing anyway..."
    done
done

if [ ${USEPIVOT} != 2 ] ; then
    if [ ! -d ${DESTINATIONROOT}/initrd ] ; then
        mkdir ${DESTINATIONROOT}/initrd
    fi
fi

echo Done.
sync
exit 0
