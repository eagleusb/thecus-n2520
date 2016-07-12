#ifndef _KCOMPAT_H_
#define _KCOMPAT_H_

#ifndef LINUX_VERSION_CODE
#include <linux/version.h>
#else
#define KERNEL_VERSION(a,b,c) (((a) << 16) + ((b) << 8) + (c))
#endif

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/i2c.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/rtc.h>         /* get the user-level API */
#include <linux/init.h>
#include <linux/types.h>
#include <linux/miscdevice.h>
#include <linux/poll.h>
#include <linux/proc_fs.h>
#include <linux/notifier.h>
#include <linux/delay.h>
#include <asm/io.h>
#include <linux/vt_kern.h>
#include <linux/reboot.h>
#include <linux/pci.h>

#include <linux/fcntl.h>
#include <linux/spinlock.h>
//#include <linux/smp_lock.h>
#include <linux/wait.h>
#include <linux/mm.h>

/******************************************************************************/
#if ( LINUX_VERSION_CODE < KERNEL_VERSION(2,6,36) )
#undef DEFINE_SEMAPHORE
#define DEFINE_SEMAPHORE(name)   DECLARE_MUTEX(name)
#endif

#endif
