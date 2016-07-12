#
#  Makefile
#
#  Written by Jari Ruusu, November 9 2012
#
#  Copyright 2001-2011 by Jari Ruusu.
#  Redistribution of this file is permitted under the GNU Public License.
#
#  To compile and install, use commands:  make clean; make
#  This Makefile tries to locate running kernel source directory and
#  steal definitions from kernel Makefile. Note: kernel must be properly
#  configured and compiled in order for this to work.
#  You can override the kernel source directory by defining LINUX_SOURCE
#  like this:  make LINUX_SOURCE=/usr/src/linux-2.2.20aa1
#
#  Both LINUX_SOURCE and KBUILD_OUTPUT must be defined when
#  compiling for 2.6.x kernel with separate object directory.
#
#  Other useful overrides are:
#   KEYSCRUB=y                  # enable encryption key scrubbing
#   PADLOCK=y                   # enable VIA padlock hardware AES
#   INTELAES=y                  # enable Intel hardware AES
#   BUILD_LOOP=n                # don't build loop module
#   EXTRA_CIPHERS=y             # build twofish, serpent and blowfish modules
#   CC=gcc-3.3                  # use this C compiler
#   INSTALL_MOD_PATH=/tmp/foo   # install modules to /tmp/foo/lib/modules/*
#

KR:=$(shell uname -r)
ifdef LINUX_SOURCE
	LS:=$(LINUX_SOURCE)
else
	LS:=$(shell  if [ -f /lib/modules/$(KR)/source/Makefile ]; then cd /lib/modules/$(KR)/source && /bin/pwd; \
		else if [ -f /lib/modules/$(KR)/build/include/linux/version.h ]; then cd /lib/modules/$(KR)/build && /bin/pwd; \
		else if [ -f /usr/src/linux/include/linux/version.h ]; then cd /usr/src/linux && /bin/pwd; \
		else if [ -f /usr/src/linux-$(KR)/include/linux/version.h ]; then cd /usr/src/linux-$(KR) && /bin/pwd; \
		else if [ -f /usr/src/kernel-source-$(KR)/include/linux/version.h ]; then cd /usr/src/kernel-source-$(KR) && /bin/pwd; \
		else echo unable-to-guess-source-dir; fi; fi; fi; fi; fi)
endif
ifdef KBUILD_OUTPUT
	OD1:=$(KBUILD_OUTPUT)
else
ifdef LINUX_SOURCE
	OD1:=$(LS)
else
	OD1:=$(shell if [ -f /lib/modules/$(KR)/build/include/linux/version.h ]; then cd /lib/modules/$(KR)/build && /bin/pwd; else echo $(LS); fi)
endif
endif
OD2:=
ifneq ($(LS),$(OD1))
	OD2:= O=$(OD1)
endif
TD:=$(shell /bin/pwd)

MODINST:=y
KEYSCRUB:=n
PADLOCK:=n
INTELAES:=n
BUILD_LOOP:=y
EXTRA_CIPHERS:=n

VERSION:=$(shell if test -r $(LS)/Makefile; then grep '^VERSION' $(LS)/Makefile | head -n 1 | sed -e 's/[^0-9]//g'; fi)
PATCHLEVEL:=$(shell if test -r $(LS)/Makefile; then grep '^PATCHLEVEL' $(LS)/Makefile | head -n 1 | sed -e 's/[^0-9]//g'; fi)
SUBLEVEL:=$(shell if test -r $(LS)/Makefile; then grep '^SUBLEVEL' $(LS)/Makefile | head -n 1 | sed -e 's/[^0-9]//g'; fi)

PATCHNAME:=loop.c-$(VERSION).$(PATCHLEVEL).diff
ORIGNAME:=loop.c-$(VERSION).$(PATCHLEVEL).original
PREPATCHED:=loop.c-$(VERSION).$(PATCHLEVEL).patched

EF:=
LF:=-r
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -lt 260 ]; then echo y; fi),y)
	OD1:=$(LS)
endif

ifeq ($(VERSION).$(PATCHLEVEL),2.0)
	# Use optimized assembler implementation if target is x86 processor
	X86_ASM:=$(shell if grep -q -s "define CONFIG_M[3456]86" $(LS)/include/linux/autoconf.h; then echo y; fi)
	# kernel v2.0 doesn't have u_int32_t and u_int64_t
	EF += -Du_int32_t=__u32 -Du_int64_t=__u64
ifndef KERNELRELEASE
	# some older 2.0 kernels don't define KERNELRELEASE
	KERNELRELEASE:=$(VERSION).$(PATCHLEVEL).$(SUBLEVEL)
endif
endif
ifeq ($(VERSION).$(PATCHLEVEL),2.2)
	# Use optimized assembler implementation if target is x86 processor
	X86_ASM:=$(shell if grep -q -s "define CONFIG_M[3456]86" $(LS)/include/linux/autoconf.h; then echo y; fi)
endif
ifeq ($(VERSION).$(PATCHLEVEL),2.4)
	EF += $(kbuild_2_4_nostdinc)
	# Use optimized assembler implementation if target is x86 processor
	X86_ASM:=$(shell if grep -q -s "define CONFIG_X86 1" $(LS)/include/linux/autoconf.h; then if ! grep -q -s "define CONFIG_X86_64" $(LS)/include/linux/autoconf.h; then echo y; fi; fi)
	# Use optimized assembler implementation if target is AMD64 or compatible processor
	AMD64_ASM:=$(shell if grep -q -s "define CONFIG_X86_64" $(LS)/include/linux/autoconf.h; then echo y; fi)
	# some older 2.4 kernels don't have struct block_device_operations.owner
	EF += $(shell if test -r $(LS)/include/linux/fs.h; then if ! sed -e '1,/^struct block_device_operations {$$/ d' $(LS)/include/linux/fs.h | sed -e '/^};$$/,$$ d' | grep -q -s 'struct module.*owner;'; then echo "-DNO_BLOCK_DEVICE_OPERATIONS_OWNER"; fi; fi)
	# some older 2.4 kernels don't have reparent_to_init()
	EF += $(shell if ! grep -q -s "extern void reparent_to_init" $(LS)/include/linux/sched.h; then echo "-DNO_REPARENT_TO_INIT"; fi)
	# some 2.4 kernels don't have struct task_struct.sigmask_lock
	EF += $(shell if ! grep -q -s "spinlock_t sigmask_lock" $(LS)/include/linux/sched.h; then if grep -q -s 'struct sighand_struct \*sighand;' $(LS)/include/linux/sched.h; then echo '-DNO_TASK_STRUCT_SIGMASK_LOCK=1'; else echo '-DNO_TASK_STRUCT_SIGMASK_LOCK=2'; fi; fi)
endif
ifeq ($(VERSION).$(PATCHLEVEL),2.6)
	# Use optimized assembler implementation if target is x86 processor
	X86_ASM:=$(shell if grep -q -s "define CONFIG_X86 1" $(OD1)/include/generated/autoconf.h $(OD1)/include/linux/autoconf.h; then if ! grep -q -s "define CONFIG_X86_64" $(OD1)/include/generated/autoconf.h $(OD1)/include/linux/autoconf.h; then echo y; fi; fi)
	# Use optimized assembler implementation if target is AMD64 or compatible processor
	AMD64_ASM:=$(shell if grep -q -s "define CONFIG_X86_64" $(OD1)/include/generated/autoconf.h $(OD1)/include/linux/autoconf.h; then echo y; fi)
	# some older 2.6 kernels have different request_module interface
	EF += $(shell if test -r $(LS)/drivers/block/genhd.c; then if ! grep -q -s "request_module.*block-major-.*MAJOR.*MINOR" $(LS)/drivers/block/genhd.c; then echo "-DOLD_REQUEST_MODULE_INTERFACE"; fi; fi)
	# some older 2.6 kernels have per thread resource limits
	EF += $(shell if test -r $(LS)/include/linux/sched.h; then if sed -e '1,/^struct task_struct {$$/ d' $(LS)/include/linux/sched.h | sed -e '/^};$$/,$$ d' | grep -q -s 'struct rlimit rlim.RLIM_NLIMITS.;'; then echo "-DOLD_PER_THREAD_RLIMITS"; fi; fi)
	# some 2.6 kernels may have void* timer callback parameter
	EF += $(shell if test -r $(LS)/include/linux/timer.h; then if ! sed -e '1,/^struct timer_list {$$/ d' $(LS)/include/linux/timer.h | sed -e '/^};$$/,$$ d' | grep -q -s 'unsigned long data;'; then echo "-DNEW_TIMER_VOID_PTR_PARAM"; fi; fi)
	# some older 2.6 kernels may have two invalidate_bdev() parameters
	EF += $(shell if test -r $(LS)/include/linux/buffer_head.h; then if grep -q -s '^void invalidate_bdev.*struct block_device.*int' $(LS)/include/linux/buffer_head.h; then echo "-DOLD_INVALIDATE_BDEV_INTERFACE"; fi; fi)
endif
ifeq ($(shell if [ "$(VERSION)0" -ge 30 ]; then echo y; fi),y)
	PREPATCHED:=loop.c-$(VERSION).x.patched
	# Use optimized assembler implementation if target is x86 processor
	X86_ASM:=$(shell if grep -q -s "define CONFIG_X86 1" $(OD1)/include/generated/autoconf.h; then if ! grep -q -s "define CONFIG_X86_64" $(OD1)/include/generated/autoconf.h; then echo y; fi; fi)
	# Use optimized assembler implementation if target is AMD64 or compatible processor
	AMD64_ASM:=$(shell if grep -q -s "define CONFIG_X86_64" $(OD1)/include/generated/autoconf.h; then echo y; fi)
endif

ifeq ($(KEYSCRUB),y)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 240 ]; then echo y; fi),y)
	EF += -DCONFIG_BLK_DEV_LOOP_KEYSCRUB=1
endif
endif

ifeq ($(PADLOCK),y)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 240 ]; then echo y; fi),y)
	EF += -DCONFIG_BLK_DEV_LOOP_PADLOCK=1
endif
endif

# Some distros include "" characters in KERNELRELEASE string
KERNELRELEASE_clean:=$(shell echo $(KERNELRELEASE))

AES_OBJ_CODE:=aes.o
MD5_OBJ_CODE:=md5.o
INTELAES_OBJ_CODE:=
ifeq ($(X86_ASM),y)
	AES_OBJ_CODE:=aes-x86.o
	MD5_OBJ_CODE:=md5-x86.o
	EF += -DX86_ASM
ifeq ($(INTELAES),y)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 240 ]; then echo y; fi),y)
	INTELAES_OBJ_CODE:=aes-intel32.o
	EF += -DCONFIG_BLK_DEV_LOOP_INTELAES=1
endif
endif
endif
ifeq ($(AMD64_ASM),y)
	AES_OBJ_CODE:=aes-amd64.o
	MD5_OBJ_CODE:=md5-amd64.o md5-2x-amd64.o
	EF += -DAMD64_ASM
ifeq ($(INTELAES),y)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 240 ]; then echo y; fi),y)
	INTELAES_OBJ_CODE:=aes-intel64.o
	EF += -DCONFIG_BLK_DEV_LOOP_INTELAES=1
endif
endif
endif

# check if depmod supports -F and -b options
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 260 ]; then echo y; fi),y)
	DMOK:=y
else
	DMOK:=$(shell if [ `/sbin/insmod -V 2>&1 | head -n 1 | awk '/^insmod version /{split($$3, a, /\./); printf "%d%03d%03d\n", a[1], a[2], a[3];}'`0 -ge 20020020 ]; then echo y; fi)
endif
ifndef DEPMOD
	DEPMOD:=/sbin/depmod
endif

# check if kernel source has System.map
SYSM:=$(shell if [ -r $(OD1)/System.map ]; then echo y; fi)

RUNDM:=
DMOPTS:=
ifeq ($(DMOK),y)
ifneq "$(strip $(INSTALL_MOD_PATH))" ""
	DMOPTS += -b $(INSTALL_MOD_PATH)
endif
ifeq ($(SYSM),y)
	RUNDM:=y
	DMOPTS += -F $(OD1)/System.map $(KERNELRELEASE_clean)
endif
endif
ifeq ($(KERNELRELEASE_clean),$(KR))
ifeq "$(strip $(INSTALL_MOD_PATH))" ""
	RUNDM:=y
endif
endif

all:
ifeq ($(LS),unable-to-guess-source-dir)
	@echo "Unable to guess linux kernel source directory. Please specify"
	@echo "directory like this:  make LINUX_SOURCE=/usr/src/linux-2.2.20aa1"
	@exit 1
endif
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 260 ]; then echo y; fi),y)
	rm -r -f *.ko tmp-d-kbuild 
	mkdir tmp-d-kbuild
	echo 'obj-m:=' >>tmp-d-kbuild/Makefile
ifeq ($(BUILD_LOOP),y)
	cd tmp-d-kbuild && ln -s ../$(PREPATCHED) patched-loop.c && ln -s ../glue.c ../aes.h ../md5.h .
	echo 'obj-m += loop.o' >>tmp-d-kbuild/Makefile
ifeq ($(X86_ASM),y)
	cd tmp-d-kbuild && ln -s ../aes-x86.S ../md5-x86.S .
	echo 'loop-y:=patched-loop.o glue.o aes-x86.o md5-x86.o' >>tmp-d-kbuild/Makefile
ifeq ($(INTELAES),y)
	cd tmp-d-kbuild && ln -s ../aes-intel32.S .
	echo 'loop-y += aes-intel32.o' >>tmp-d-kbuild/Makefile
endif
else
ifeq ($(AMD64_ASM),y)
	cd tmp-d-kbuild && ln -s ../aes-amd64.S ../md5-amd64.S ../md5-2x-amd64.S .
	echo 'loop-y:=patched-loop.o glue.o aes-amd64.o md5-amd64.o md5-2x-amd64.o' >>tmp-d-kbuild/Makefile
ifeq ($(INTELAES),y)
	cd tmp-d-kbuild && ln -s ../aes-intel64.S .
	echo 'loop-y += aes-intel64.o' >>tmp-d-kbuild/Makefile
endif
else
	cd tmp-d-kbuild && ln -s ../aes.c ../md5.c .
	echo 'loop-y:=patched-loop.o glue.o aes.o md5.o' >>tmp-d-kbuild/Makefile
	echo 'CFLAGS_aes.o := -DDATA_ALWAYS_ALIGNED=1' >>tmp-d-kbuild/Makefile
endif
endif
endif
ifeq ($(EXTRA_CIPHERS),y)
	cd tmp-d-kbuild && ln -s ../loop_twofish.c ../loop_serpent.c ../loop_blowfish.c .
	echo 'obj-m += loop_twofish.o loop_serpent.o loop_blowfish.o' >>tmp-d-kbuild/Makefile
endif
ifeq ($(shell if [ "$(SUBLEVEL)0" -ge 390 -o "$(VERSION)$(PATCHLEVEL)0" -gt 260 ]; then echo y; fi),y)
	echo 'ccflags-y:= $(EF)' >>tmp-d-kbuild/Makefile
	echo 'ccflags-m:= $(EF)' >>tmp-d-kbuild/Makefile
else
	echo 'EXTRA_CFLAGS:= $(EF)' >>tmp-d-kbuild/Makefile
endif
	cd $(LS) && make SUBDIRS=$(TD)/tmp-d-kbuild modules $(OD2)
ifeq ($(MODINST),y)
	cd $(LS) && make SUBDIRS=$(TD)/tmp-d-kbuild modules_install $(OD2)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -eq 260 -a "$(SUBLEVEL)0" -lt 170 ]; then echo y; fi),y)
	cd $(LS) && make SUBDIRS=$(TD) modules Q='@cd $(TD) && if [ "$$@" = "modules" ]; then make old-k26-depmod; fi; exit; # ' $(OD2)
endif
endif
ifeq ($(BUILD_LOOP),y)
	ln -s tmp-d-kbuild/loop.ko .
endif
ifeq ($(EXTRA_CIPHERS),y)
	ln -s tmp-d-kbuild/loop_twofish.ko tmp-d-kbuild/loop_serpent.ko tmp-d-kbuild/loop_blowfish.ko .
endif
	sync
else
	cd $(LS) && make SUBDIRS=$(TD) modules
	sync
endif

# 2.6 kernels older than 2.6.17 do not run depmod in "modules_install" stage,
# but above "make modules Q=..." hack calls this target so we can run depmod here.
old-k26-depmod:
ifeq ($(RUNDM),y)
	$(DEPMOD) -a $(DMOPTS)
endif

# build stuff after this line is for 2.4 and older kernels only
MLIST:=
ifeq ($(BUILD_LOOP),y)
	MLIST += loop.o
endif
ifeq ($(EXTRA_CIPHERS),y)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 220 ]; then echo y; fi),y)
	MLIST += loop_twofish.o loop_serpent.o loop_blowfish.o
endif
endif

modules: clean $(MLIST)
ifeq ($(MODINST),y)
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 240 ]; then echo y; fi),y)
	rm -f $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE_clean)/kernel/drivers/block/loop.o
endif
	mkdir -p $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE_clean)/block
ifneq "$(strip $(MLIST))" ""
	cp -p $(MLIST) $(INSTALL_MOD_PATH)/lib/modules/$(KERNELRELEASE_clean)/block
endif
ifeq ($(RUNDM),y)
	$(DEPMOD) -a $(DMOPTS)
endif
endif

loop.o: patched-loop.o glue.o $(AES_OBJ_CODE) $(INTELAES_OBJ_CODE) $(MD5_OBJ_CODE)
	$(LD) $(LF) patched-loop.o glue.o $(AES_OBJ_CODE) $(INTELAES_OBJ_CODE) $(MD5_OBJ_CODE) -o loop.o
patched-loop.o:
	rm -f patched-loop.[ch]
ifeq ($(shell if [ "$(VERSION)$(PATCHLEVEL)0" -ge 240 ]; then echo y; fi),y)
	cp $(PREPATCHED) patched-loop.c
else
	cp $(LS)/drivers/block/loop.c patched-loop.c
	@echo "*** BEGINNING OF SECTION TO IGNORE PATCH ERRORS ***"
	patch -p0 -l -f --dry-run < $(PATCHNAME) || cp $(ORIGNAME) patched-loop.c
	@echo "*** END OF SECTION TO IGNORE PATCH ERRORS ***"
	patch -p0 -l -f < $(PATCHNAME)
endif
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=patched_loop -DEXPORT_SYMTAB -c patched-loop.c -o patched-loop.o
glue.o: glue.c aes.h md5.h
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=glue -c glue.c -o glue.o
aes.o: aes.c aes.h
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=aes -DDATA_ALWAYS_ALIGNED=1 -c aes.c -o aes.o
aes-x86.o: aes-x86.S
	$(CC) $(AFLAGS) -c aes-x86.S -o aes-x86.o
aes-amd64.o: aes-amd64.S
	$(CC) $(AFLAGS) -c aes-amd64.S -o aes-amd64.o
aes-intel32.o: aes-intel32.S
	$(CC) $(AFLAGS) -c aes-intel32.S -o aes-intel32.o
aes-intel64.o: aes-intel64.S
	$(CC) $(AFLAGS) -c aes-intel64.S -o aes-intel64.o
md5.o: md5.c md5.h
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=md5 -c md5.c -o md5.o
md5-x86.o: md5-x86.S
	$(CC) $(AFLAGS) -c md5-x86.S -o md5-x86.o
md5-amd64.o: md5-amd64.S
	$(CC) $(AFLAGS) -c md5-amd64.S -o md5-amd64.o
md5-2x-amd64.o: md5-2x-amd64.S
	$(CC) $(AFLAGS) -c md5-2x-amd64.S -o md5-2x-amd64.o

loop_twofish.o: loop_twofish.c
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=loop_twofish -c loop_twofish.c -o loop_twofish.o
loop_serpent.o: loop_serpent.c
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=loop_serpent -c loop_serpent.c -o loop_serpent.o
loop_blowfish.o: loop_blowfish.c
	$(CC) $(CFLAGS) $(EF) -DKBUILD_BASENAME=loop_blowfish -c loop_blowfish.c -o loop_blowfish.o

clean:
	rm -f *.o *.ko *.orig *.rej patched-loop.[ch] test-file[1234]
	rm -f -r test-dir1 tmp-d-kbuild

# tests can be run after loop.o and losetup are compiled and installed
TLD:=/dev/loop7
TEST_GPG_TYPES:=y
TEST_UNHASHED_AES_TYPES:=y
TEST_PARTITION_TO_TRASH:=none
TEST_LE_BLOWFISH_TYPES:=n
tests:
	@if /sbin/losetup $(TLD) >/dev/null 2>&1; then echo "ERROR: Loop device $(TLD) appears to be in use. You can override"; echo "default test device by adding TLD=/dev/loop0 parameter to make command."; exit 1; fi
	rm -f -r test-file[1234] test-dir1
	dd if=/dev/zero of=test-file1 bs=1024 count=33
	cp test-file1 test-file3
	echo 09876543210987654321 | /sbin/losetup -p 0 -e AES128 $(TLD) test-file3
	dd if=/dev/zero of=$(TLD) bs=1024 count=33 conv=notrunc
	sync && /sbin/losetup -d $(TLD)
	make test-part2 PAR="-e XOR" MD=d28220a1737763260f6e0109f141814a TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR= MD=0b08ceeb8b609b0885471ba25a23f5a5 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES128" MD=7c1cfd4fdd0d7cc847dd0942a2d48e48 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES192" MD=51c91bcc04ee2a4ca00310b519b3228c TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES256" MD=1bf92ee337b653cdb32838047dec00fc TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES256 -H rmd160" MD=c85eb59da18876ae71ebd838675c6ef4 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES256 -C 10" MD=dadad48a6d3d9b9914199626ed7b710c TF=test-file1 PSW=12345678901234567890
ifeq ($(TEST_GPG_TYPES),y)
	mkdir test-dir1
	make test-part2 PAR="-e AES128 -K gpgkey1.asc -G test-dir1" MD=fa5c9a84bc8f6257830c3cbe60294c69 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES192 -K gpgkey1.asc -G test-dir1" MD=ddec9544a36100156aef353ec2bf9740 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES256 -K gpgkey1.asc -G test-dir1" MD=cb38b603f96f0deac1891d423983d69c TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES128 -K gpgkey2.asc -G test-dir1" MD=f9825b79873f5c439ae9371c1a929a6c TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES192 -K gpgkey2.asc -G test-dir1" MD=489991b779213f60219f09c575c08247 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES256 -K gpgkey2.asc -G test-dir1" MD=2a1d0d3fce83fbe5f3edcca95fbab3b7 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES128 -K gpgkey3.asc -G test-dir1" MD=fabe7422f534820838dfd4571ba14ade TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES192 -K gpgkey3.asc -G test-dir1" MD=3eadc976525f9df7e18d56676ec730c8 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e AES256 -K gpgkey3.asc -G test-dir1" MD=3be488a60dd77bcab9fbeba4a428c3d5 TF=test-file1 PSW=12345678901234567890
endif
ifeq ($(TEST_UNHASHED_AES_TYPES),y)
	make test-part2 PAR="-e AES -H unhashed1" MD=293b09053055af7ca5235dc6a5bc0b74 TF=test-file1 PSW=1234567890123456789012345678901
	make test-part2 PAR="-e AES -H unhashed1" MD=6b157917570250ef4370bf9acae49279 TF=test-file1 PSW=12345678901234567890123456789012
	make test-part2 PAR="-e AES -H unhashed1" MD=6b157917570250ef4370bf9acae49279 TF=test-file1 PSW=123456789012345678901234567890123456789012
	make test-part2 PAR="-e AES -H unhashed1" MD=e12fd55fbae9fc0e03517593e253e239 TF=test-file1 PSW=1234567890123456789012345678901234567890123
endif
ifneq ($(TEST_PARTITION_TO_TRASH),none)
	make test-part2 PAR="-e AES128" MD=7c1cfd4fdd0d7cc847dd0942a2d48e48 TF=$(TEST_PARTITION_TO_TRASH) PSW=12345678901234567890
	make test-part2 PAR= MD=0b08ceeb8b609b0885471ba25a23f5a5 TF=$(TEST_PARTITION_TO_TRASH) PSW=12345678901234567890
endif
ifeq ($(EXTRA_CIPHERS),y)
	/sbin/modprobe loop_twofish
	make test-part2 PAR="-e twofish128" MD=763ebf26964b3202e4740ced21018f19 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish192" MD=6d5868395e2bf9de5b5bc9e036646061 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish256" MD=65332bb73af9ae564d452a21e053f1c5 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish128 -I 1" MD=1a814ea93ec65bf0a321177c8f2afbb0 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish192 -I 1" MD=941c708664436917cfa2301aac900164 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish256 -I 1" MD=5c4ca27adacce34b22d4ffdad9086309 TF=test-file1 PSW=12345678901234567890
	/sbin/modprobe loop_serpent
	make test-part2 PAR="-e serpent128" MD=7d7bc9de37b30179a164e7f9e9361557 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent192" MD=5c7623e041530f6647ae0b72a78c41fd TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent256" MD=31851a69091fc7681bfb8bbea4663f3f TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent128 -I 2" MD=54bf141d4571bae5b954cd34df09e9a9 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent192 -I 2" MD=e48ce972d02749284ae018749821e425 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent256 -I 2" MD=260a96d831cfa4c89975327cea217e07 TF=test-file1 PSW=12345678901234567890
	/sbin/modprobe loop_blowfish
	make test-part2 PAR="-e blowfish128" MD=0decbfdab73dea75b7bf14afbc3181b9 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish192" MD=031669b257da3e6dc9cf4aba140ef1ad TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish256" MD=c7ed54673dedc02a1d30abe4ebec2753 TF=test-file1 PSW=12345678901234567890
ifeq ($(TEST_LE_BLOWFISH_TYPES),y)
	# these md5 sums can only be produced on little endian boxes
	make test-part2 PAR="-e blowfish128 -I 1" MD=22c8593065df1250306bfed05c0b486a TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish192 -I 1" MD=31c964f6e830f74a02a90905aa8efb2c TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish256 -I 1" MD=74ada888670d7278be00eb133feae2f5 TF=test-file1 PSW=12345678901234567890
endif
ifeq ($(TEST_GPG_TYPES),y)
	make test-part2 PAR="-e twofish128 -K gpgkey1.asc -G test-dir1" MD=ddf13c7d8e98e2e811c909521dc14509 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish192 -K gpgkey1.asc -G test-dir1" MD=b6903ab3c6edcfb7d4304536ede5a7eb TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish256 -K gpgkey1.asc -G test-dir1" MD=da58adcd6354578dfda581239a1e045f TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish128 -K gpgkey2.asc -G test-dir1" MD=9ade662b89929151f9addadb1c50c473 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish192 -K gpgkey2.asc -G test-dir1" MD=6282fcb36094212a88ca4e2f3b1d5df3 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish256 -K gpgkey2.asc -G test-dir1" MD=c9cfd9ede40efc7786c4d20ee64da245 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish128 -K gpgkey3.asc -G test-dir1" MD=318869c1f51d86912d5784a1dc717b08 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish192 -K gpgkey3.asc -G test-dir1" MD=ffe7e80743edc5120be7bbcb8076b368 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e twofish256 -K gpgkey3.asc -G test-dir1" MD=345b77d2e3d318ba27214bbc8313ae0f TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent128 -K gpgkey1.asc -G test-dir1" MD=ac78f204e993e7141baaa30cd1e24221 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent192 -K gpgkey1.asc -G test-dir1" MD=c2a724f1973694cb898996dba3182c55 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent256 -K gpgkey1.asc -G test-dir1" MD=7c2d2f438129e1084cb41a622fb77ca4 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent128 -K gpgkey2.asc -G test-dir1" MD=b3992dd60a999a3cba18fad15492b8aa TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent192 -K gpgkey2.asc -G test-dir1" MD=e6cfc39e113943db1d03797dbf5cd5cd TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent256 -K gpgkey2.asc -G test-dir1" MD=f111de9256b5adf0f12fe1c75c261feb TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent128 -K gpgkey3.asc -G test-dir1" MD=96f3d5321b00f5bf25852627dc2d48a8 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent192 -K gpgkey3.asc -G test-dir1" MD=cb9729cb56a8358198dc61995b3a3cd2 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e serpent256 -K gpgkey3.asc -G test-dir1" MD=b4d9758d5d387fce43a1d436a01d3d68 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish128 -K gpgkey1.asc -G test-dir1" MD=d1cca0dc44e7af8a628a0978ac0fe26d TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish192 -K gpgkey1.asc -G test-dir1" MD=e5bbb6648b893d1e1db08423e8806b53 TF=test-file1 PSW=12345678901234567890
	make test-part2 PAR="-e blowfish256 -K gpgkey1.asc -G test-dir1" MD=fdf78c384eb14215061f81e0c098b777 TF=test-file1 PSW=12345678901234567890
endif
endif
	dd if=/dev/zero of=test-file1 bs=1024 count=32
	cp test-file1 test-file3
	echo 09876543210987654321 | /sbin/losetup -p 0 -e AES128 $(TLD) test-file3
	dd if=/dev/zero of=$(TLD) bs=1024 count=32 conv=notrunc
	sync && /sbin/losetup -d $(TLD)
ifeq ($(TEST_GPG_TYPES),y)
	make test-part3 PAR="-e AES128 -K gpgkey1.asc -G test-dir1" MD=905c8e6103876623e7867449598bc99b TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES192 -K gpgkey1.asc -G test-dir1" MD=2800a5e1aa1fea0352d211620b80b892 TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES256 -K gpgkey1.asc -G test-dir1" MD=583a1a3a06d1bbda5c93f73b00407163 TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES128 -K gpgkey2.asc -G test-dir1" MD=013eaf600a251496a5ab308b43056911 TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES192 -K gpgkey2.asc -G test-dir1" MD=72b2d0c0f82ea5478187af58d508d30c TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES256 -K gpgkey2.asc -G test-dir1" MD=34633e47fa7bc1af9a1cca2cdbaa913e TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES128 -K gpgkey3.asc -G test-dir1" MD=b5efe5efe87dc059066440c3bf938d74 TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES192 -K gpgkey3.asc -G test-dir1" MD=c33df5e00db182ff074f91dc6cd54138 TF=test-file1 PSW=12345678901234567890
	make test-part3 PAR="-e AES256 -K gpgkey3.asc -G test-dir1" MD=80b38e4bb6ac95d5f6078723555f1c32 TF=test-file1 PSW=12345678901234567890
endif
	rm -f -r test-file[1234] test-dir1
	@echo "*** Test results ok ***"

test-part2:
	echo $(PSW) | /sbin/losetup -p 0 $(PAR) $(TLD) $(TF)
	dd if=test-file3 of=$(TLD) bs=33792 count=1 conv=notrunc
	sync && /sbin/losetup -d $(TLD)
	echo $(PSW) | /sbin/losetup -p 0 $(PAR) $(TLD) $(TF)
	dd if=$(TLD) of=test-file4 bs=33792 count=1
	sync && /sbin/losetup -d $(TLD)
ifneq ($(TF),test-file1)
	dd if=$(TF) of=test-file1 bs=33792 count=1
endif
	md5sum test-file1 >test-file2
	echo "$(MD)  test-file1" | cmp test-file2 -
	cmp test-file3 test-file4

test-part3:
	echo $(PSW) | /sbin/losetup -p 0 $(PAR) $(TLD) $(TF)
	/sbin/blockdev --setbsz 4096 $(TLD) || true
	dd if=test-file3 of=$(TLD) bs=32768 count=1 conv=notrunc
	sync && /sbin/losetup -d $(TLD)
	echo $(PSW) | /sbin/losetup -p 0 $(PAR) $(TLD) $(TF)
	/sbin/blockdev --setbsz 4096 $(TLD) || true
	dd if=$(TLD) of=test-file4 bs=32768 count=1
	sync && /sbin/losetup -d $(TLD)
ifneq ($(TF),test-file1)
	dd if=$(TF) of=test-file1 bs=32768 count=1
endif
	md5sum test-file1 >test-file2
	echo "$(MD)  test-file1" | cmp test-file2 -
	cmp test-file3 test-file4

.PHONY: all old-k26-depmod clean tests test-part2 test-part3
