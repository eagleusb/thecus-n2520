/*
 *  glue.c
 *
 *  Written by Jari Ruusu, April 16 2010
 *
 *  Copyright 2001-2010 by Jari Ruusu.
 *  Redistribution of this file is permitted under the GNU Public License.
 */

#include <linux/version.h>
#include <linux/sched.h>
#include <linux/fs.h>
#include <linux/string.h>
#include <linux/types.h>
#include <linux/errno.h>
#if LINUX_VERSION_CODE >= 0x20600
# include <linux/bio.h>
# include <linux/blkdev.h>
#endif
#if LINUX_VERSION_CODE >= 0x20200
# include <linux/slab.h>
# include <linux/loop.h>
# include <asm/uaccess.h>
#else
# include <linux/malloc.h>
# include <asm/segment.h>
# include "patched-loop.h"
#endif
#if LINUX_VERSION_CODE >= 0x20400
# include <linux/spinlock.h>
#endif
#include <asm/byteorder.h>
#if (defined(CONFIG_BLK_DEV_LOOP_PADLOCK) || defined(CONFIG_BLK_DEV_LOOP_INTELAES)) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
# include <asm/processor.h>
#endif
#if defined(CONFIG_BLK_DEV_LOOP_INTELAES) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
# include <asm/i387.h>
#endif
#include "aes.h"
#include "md5.h"

#if LINUX_VERSION_CODE >= 0x20600
typedef sector_t TransferSector_t;
# define LoopInfo_t struct loop_info64
#else
typedef int TransferSector_t;
# define LoopInfo_t struct loop_info
#endif

#if !defined(cpu_to_le32)
# if defined(__BIG_ENDIAN)
#  define cpu_to_le32(x) ({u_int32_t __x=(x);((u_int32_t)((((u_int32_t)(__x)&(u_int32_t)0x000000ffUL)<<24)|(((u_int32_t)(__x)&(u_int32_t)0x0000ff00UL)<<8)|(((u_int32_t)(__x)&(u_int32_t)0x00ff0000UL)>>8)|(((u_int32_t)(__x)&(u_int32_t)0xff000000UL)>>24)));})
# else
#  define cpu_to_le32(x) ((u_int32_t)(x))
# endif
#endif

#if LINUX_VERSION_CODE < 0x20200
# define copy_from_user(t,f,s) (verify_area(VERIFY_READ,f,s)?(s):(memcpy_fromfs(t,f,s),0))
#endif

#if !defined(LOOP_MULTI_KEY_SETUP)
# define LOOP_MULTI_KEY_SETUP 0x4C4D
#endif
#if !defined(LOOP_MULTI_KEY_SETUP_V3)
# define LOOP_MULTI_KEY_SETUP_V3 0x4C4E
#endif

#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
# define KEY_ALLOC_COUNT  128
#else
# define KEY_ALLOC_COUNT  64
#endif

typedef struct {
    aes_context *keyPtr[KEY_ALLOC_COUNT];
    unsigned    keyMask;
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    u_int32_t   *partialMD5;
    u_int32_t   partialMD5buf[8];
    rwlock_t    rwlock;
    unsigned    reversed;
    unsigned    blocked;
    struct timer_list timer;
#else
    u_int32_t   partialMD5[4];
#endif
#if defined(CONFIG_BLK_DEV_LOOP_PADLOCK) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
    u_int32_t   padlock_cw_e;
    u_int32_t   padlock_cw_d;
#endif
} AESmultiKey;

#if (defined(CONFIG_BLK_DEV_LOOP_PADLOCK) || defined(CONFIG_BLK_DEV_LOOP_INTELAES)) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
/* This function allocates AES context structures at special address such */
/* that returned address % 16 == 8 . That way expanded encryption and */
/* decryption keys in AES context structure are always 16 byte aligned */
static void *specialAligned_kmalloc(size_t size, unsigned int flags)
{
    void *pn, **ps;
    pn = kmalloc(size + (16 + 8), flags);
    if(!pn) return (void *)0;
    ps = (void **)((((unsigned long)pn + 15) & ~((unsigned long)15)) + 8);
    *(ps - 1) = pn;
    return (void *)ps;
}
static void specialAligned_kfree(void *ps)
{
    if(ps) kfree(*((void **)ps - 1));
}
# define specialAligned_ctxSize     ((sizeof(aes_context) + 15) & ~15)
#else
# define specialAligned_kmalloc     kmalloc
# define specialAligned_kfree       kfree
# define specialAligned_ctxSize     sizeof(aes_context)
#endif

#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
static void keyScrubWork(AESmultiKey *m)
{
    aes_context *a0, *a1;
    u_int32_t *p;
    int x, y, z;

    z = m->keyMask + 1;
    for(x = 0; x < z; x++) {
        a0 = m->keyPtr[x];
        a1 = m->keyPtr[x + z];
        memcpy(a1, a0, sizeof(aes_context));
        m->keyPtr[x] = a1;
        m->keyPtr[x + z] = a0;
        p = (u_int32_t *) a0;
        y = sizeof(aes_context) / sizeof(u_int32_t);
        while(y > 0) {
            *p ^= 0xFFFFFFFF;
            p++;
            y--;
        }
    }

    x = m->reversed;    /* x is 0 or 4 */
    m->reversed ^= 4;
    y = m->reversed;    /* y is 4 or 0 */
    p = &m->partialMD5buf[x];
    memcpy(&m->partialMD5buf[y], p, 16);
    m->partialMD5 = &m->partialMD5buf[y];
    p[0] ^= 0xFFFFFFFF;
    p[1] ^= 0xFFFFFFFF;
    p[2] ^= 0xFFFFFFFF;
    p[3] ^= 0xFFFFFFFF;

    /* try to flush dirty cache data to RAM */
#if !defined(CONFIG_XEN) && (defined(CONFIG_X86_64) || (defined(CONFIG_X86) && !defined(CONFIG_M386) && !defined(CONFIG_CPU_386)))
    __asm__ __volatile__ ("wbinvd": : :"memory");
#else
    mb();
#endif
}

/* called only from loop thread process context */
static void keyScrubThreadFn(AESmultiKey *m)
{
    write_lock(&m->rwlock);
    if(!m->blocked) keyScrubWork(m);
    write_unlock(&m->rwlock);
}

#if defined(NEW_TIMER_VOID_PTR_PARAM)
# define KeyScrubTimerFnParamType void *
#else
# define KeyScrubTimerFnParamType unsigned long
#endif

static void keyScrubTimerFn(KeyScrubTimerFnParamType);

static void keyScrubTimerInit(struct loop_device *lo)
{
    AESmultiKey     *m;
    unsigned long   expire;

    m = (AESmultiKey *)lo->key_data;
    expire = jiffies + HZ;
    init_timer(&m->timer);
    m->timer.expires = expire;
    m->timer.data = (KeyScrubTimerFnParamType)lo;
    m->timer.function = keyScrubTimerFn;
    add_timer(&m->timer);
}

/* called only from timer handler context */
static void keyScrubTimerFn(KeyScrubTimerFnParamType d)
{
    struct loop_device *lo = (struct loop_device *)d;
    extern void loop_add_keyscrub_fn(struct loop_device *, void (*)(void *), void *);

    /* rw lock needs process context, so make loop thread do scrubbing */
    loop_add_keyscrub_fn(lo, (void (*)(void*))keyScrubThreadFn, lo->key_data);
    /* start timer again */
    keyScrubTimerInit(lo);
}
#endif

static AESmultiKey *allocMultiKey(void)
{
    AESmultiKey *m;
    aes_context *a;
    int x = 0, n;

    m = (AESmultiKey *) kmalloc(sizeof(AESmultiKey), GFP_KERNEL);
    if(!m) return 0;
    memset(m, 0, sizeof(AESmultiKey));
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    m->partialMD5 = &m->partialMD5buf[0];
    rwlock_init(&m->rwlock);
    init_timer(&m->timer);
    again:
#endif

    n = PAGE_SIZE / specialAligned_ctxSize;
    if(!n) n = 1;

    a = (aes_context *) specialAligned_kmalloc(specialAligned_ctxSize * n, GFP_KERNEL);
    if(!a) {
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
        if(x) specialAligned_kfree(m->keyPtr[0]);
#endif
        kfree(m);
        return 0;
    }

    while((x < KEY_ALLOC_COUNT) && n) {
        m->keyPtr[x] = a;
        a = (aes_context *)((unsigned char *)a + specialAligned_ctxSize);
        x++;
        n--;
    }
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    if(x < 2) goto again;
#endif
    return m;
}

static void clearAndFreeMultiKey(AESmultiKey *m)
{
    aes_context *a;
    int x, n;

#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    /* stop scrub timer. loop thread was killed earlier */
    del_timer_sync(&m->timer);
    /* make sure allocated keys are in original order */
    if(m->reversed) keyScrubWork(m);
#endif
    n = PAGE_SIZE / specialAligned_ctxSize;
    if(!n) n = 1;

    x = 0;
    while(x < KEY_ALLOC_COUNT) {
        a = m->keyPtr[x];
        if(!a) break;
        memset(a, 0, specialAligned_ctxSize * n);
        specialAligned_kfree(a);
        x += n;
    }

    memset(m, 0, sizeof(AESmultiKey));
    kfree(m);
}

static int multiKeySetup(struct loop_device *lo, unsigned char *k, int version3)
{
    AESmultiKey *m;
    aes_context *a;
    int x, y, n, err = 0;
    union {
        u_int32_t     w[16];
        unsigned char b[64];
    } un;

#if LINUX_VERSION_CODE >= 0x20200
#if LINUX_VERSION_CODE >= 0x30600
    if(!uid_eq(lo->lo_key_owner, current_uid()) && !capable(CAP_SYS_ADMIN))
        return -EPERM;
#elif LINUX_VERSION_CODE >= 0x2061c
    if(lo->lo_key_owner != current_uid() && !capable(CAP_SYS_ADMIN))
        return -EPERM;
#else
    if(lo->lo_key_owner != current->uid && !capable(CAP_SYS_ADMIN))
        return -EPERM;
#endif
#endif

    m = (AESmultiKey *)lo->key_data;
    if(!m) return -ENXIO;

#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    /* temporarily prevent loop thread from messing with keys */
    write_lock(&m->rwlock);
    m->blocked = 1;
    /* make sure allocated keys are in original order */
    if(m->reversed) keyScrubWork(m);
    write_unlock(&m->rwlock);
#endif
    n = PAGE_SIZE / specialAligned_ctxSize;
    if(!n) n = 1;

    x = 0;
    while(x < KEY_ALLOC_COUNT) {
        if(!m->keyPtr[x]) {
            a = (aes_context *) specialAligned_kmalloc(specialAligned_ctxSize * n, GFP_KERNEL);
            if(!a) {
                err = -ENOMEM;
                goto error_out;
            }
            y = x;
            while((y < (x + n)) && (y < KEY_ALLOC_COUNT)) {
                m->keyPtr[y] = a;
                a = (aes_context *)((unsigned char *)a + specialAligned_ctxSize);
                y++;
            }
        }
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
        if(x >= 64) {
            x++;
            continue;
        }
#endif
        if(copy_from_user(&un.b[0], k, 32)) {
            err = -EFAULT;
            goto error_out;
        }
        aes_set_key(m->keyPtr[x], &un.b[0], lo->lo_encrypt_key_size, 0);
        k += 32;
        x++;
    }

    m->partialMD5[0] = 0x67452301;
    m->partialMD5[1] = 0xefcdab89;
    m->partialMD5[2] = 0x98badcfe;
    m->partialMD5[3] = 0x10325476;
    if(version3) {
        /* only first 128 bits of iv-key is used */
        if(copy_from_user(&un.b[0], k, 16)) {
            err = -EFAULT;
            goto error_out;
        }
#if defined(__BIG_ENDIAN)
        un.w[0] = cpu_to_le32(un.w[0]);
        un.w[1] = cpu_to_le32(un.w[1]);
        un.w[2] = cpu_to_le32(un.w[2]);
        un.w[3] = cpu_to_le32(un.w[3]);
#endif
        memset(&un.b[16], 0, 48);
        md5_transform_CPUbyteorder(&m->partialMD5[0], &un.w[0]);
        lo->lo_flags |= 0x080000;  /* multi-key-v3 (info exported to user space) */
    }

    m->keyMask = 0x3F;          /* range 0...63 */
    lo->lo_flags |= 0x100000;   /* multi-key (info exported to user space) */
    memset(&un.b[0], 0, 32);
error_out:
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    /* re-enable loop thread key scrubbing */
    write_lock(&m->rwlock);
    m->blocked = 0;
    write_unlock(&m->rwlock);
#endif
    return err;
}

int keySetup_aes(struct loop_device *lo, LoopInfo_t *info)
{
    AESmultiKey     *m;
    union {
        u_int32_t     w[8]; /* needed for 4 byte alignment for b[] */
        unsigned char b[32];
    } un;

    lo->key_data = m = allocMultiKey();
    if(!m) return(-ENOMEM);
    memcpy(&un.b[0], &info->lo_encrypt_key[0], 32);
    aes_set_key(m->keyPtr[0], &un.b[0], info->lo_encrypt_key_size, 0);
    memset(&info->lo_encrypt_key[0], 0, sizeof(info->lo_encrypt_key));
    memset(&un.b[0], 0, 32);
#if defined(CONFIG_BLK_DEV_LOOP_PADLOCK) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
    switch(info->lo_encrypt_key_size) {
    case 256:   /* bits */
    case 32:    /* bytes */
        /* 14 rounds, AES, software key gen, normal oper, encrypt, 256-bit key */
        m->padlock_cw_e = 14 | (1<<7) | (2<<10);
        /* 14 rounds, AES, software key gen, normal oper, decrypt, 256-bit key */
        m->padlock_cw_d = 14 | (1<<7) | (1<<9) | (2<<10);
        break;
    case 192:   /* bits */
    case 24:    /* bytes */
        /* 12 rounds, AES, software key gen, normal oper, encrypt, 192-bit key */
        m->padlock_cw_e = 12 | (1<<7) | (1<<10);
        /* 12 rounds, AES, software key gen, normal oper, decrypt, 192-bit key */
        m->padlock_cw_d = 12 | (1<<7) | (1<<9) | (1<<10);
        break;
    default:
        /* 10 rounds, AES, software key gen, normal oper, encrypt, 128-bit key */
        m->padlock_cw_e = 10 | (1<<7);
        /* 10 rounds, AES, software key gen, normal oper, decrypt, 128-bit key */
        m->padlock_cw_d = 10 | (1<<7) | (1<<9);
        break;
    }
#endif
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    keyScrubTimerInit(lo);
#endif
    return(0);
}

int keyClean_aes(struct loop_device *lo)
{
    if(lo->key_data) {
        clearAndFreeMultiKey((AESmultiKey *)lo->key_data);
        lo->key_data = 0;
    }
    return(0);
}

int handleIoctl_aes(struct loop_device *lo, int cmd, unsigned long arg)
{
    int err;

    switch (cmd) {
    case LOOP_MULTI_KEY_SETUP:
        err = multiKeySetup(lo, (unsigned char *)arg, 0);
        break;
    case LOOP_MULTI_KEY_SETUP_V3:
        err = multiKeySetup(lo, (unsigned char *)arg, 1);
        break;
    default:
        err = -EINVAL;
    }
    return err;
}

void loop_compute_sector_iv(TransferSector_t devSect, u_int32_t *ivout)
{
    if(sizeof(TransferSector_t) == 8) {
        ivout[0] = cpu_to_le32(devSect);
        ivout[1] = cpu_to_le32((u_int64_t)devSect>>32);
        ivout[3] = ivout[2] = 0;
    } else {
        ivout[0] = cpu_to_le32(devSect);
        ivout[3] = ivout[2] = ivout[1] = 0;
    }
}

void loop_compute_md5_iv_v3(TransferSector_t devSect, u_int32_t *ivout, u_int32_t *data)
{
    int         x;
#if defined(__BIG_ENDIAN)
    int         y, e;
#endif
    u_int32_t   buf[16];

#if defined(__BIG_ENDIAN)
    y = 7;
    e = 16;
    do {
        if (!y) {
            e = 12;
            /* md5_transform_CPUbyteorder wants data in CPU byte order */
            /* devSect is already in CPU byte order -- no need to convert */
            if(sizeof(TransferSector_t) == 8) {
                /* use only 56 bits of sector number */
                buf[12] = devSect;
                buf[13] = (((u_int64_t)devSect >> 32) & 0xFFFFFF) | 0x80000000;
            } else {
                /* 32 bits of sector number + 24 zero bits */
                buf[12] = devSect;
                buf[13] = 0x80000000;
            }
            /* 4024 bits == 31 * 128 bit plaintext blocks + 56 bits of sector number */
            /* For version 3 on-disk format this really should be 4536 bits, but can't be */
            /* changed without breaking compatibility. V3 uses MD5-with-wrong-length IV */
            buf[14] = 4024;
            buf[15] = 0;
        }
        x = 0;
        do {
            buf[x    ] = cpu_to_le32(data[0]);
            buf[x + 1] = cpu_to_le32(data[1]);
            buf[x + 2] = cpu_to_le32(data[2]);
            buf[x + 3] = cpu_to_le32(data[3]);
            x += 4;
            data += 4;
        } while (x < e);
        md5_transform_CPUbyteorder(&ivout[0], &buf[0]);
    } while (--y >= 0);
    ivout[0] = cpu_to_le32(ivout[0]);
    ivout[1] = cpu_to_le32(ivout[1]);
    ivout[2] = cpu_to_le32(ivout[2]);
    ivout[3] = cpu_to_le32(ivout[3]);
#else
    x = 6;
    do {
        md5_transform_CPUbyteorder(&ivout[0], data);
        data += 16;
    } while (--x >= 0);
    memcpy(buf, data, 48);
    /* md5_transform_CPUbyteorder wants data in CPU byte order */
    /* devSect is already in CPU byte order -- no need to convert */
    if(sizeof(TransferSector_t) == 8) {
        /* use only 56 bits of sector number */
        buf[12] = devSect;
        buf[13] = (((u_int64_t)devSect >> 32) & 0xFFFFFF) | 0x80000000;
    } else {
        /* 32 bits of sector number + 24 zero bits */
        buf[12] = devSect;
        buf[13] = 0x80000000;
    }
    /* 4024 bits == 31 * 128 bit plaintext blocks + 56 bits of sector number */
    /* For version 3 on-disk format this really should be 4536 bits, but can't be */
    /* changed without breaking compatibility. V3 uses MD5-with-wrong-length IV */
    buf[14] = 4024;
    buf[15] = 0;
    md5_transform_CPUbyteorder(&ivout[0], &buf[0]);
#endif
}

/* this function exists for compatibility with old external cipher modules */
void loop_compute_md5_iv(TransferSector_t devSect, u_int32_t *ivout, u_int32_t *data)
{
    ivout[0] = 0x67452301;
    ivout[1] = 0xefcdab89;
    ivout[2] = 0x98badcfe;
    ivout[3] = 0x10325476;
    loop_compute_md5_iv_v3(devSect, ivout, data);
}

/* Some external modules do not know if md5_transform_CPUbyteorder() */
/* is asmlinkage or not, so here is C language wrapper for them. */
void md5_transform_CPUbyteorder_C(u_int32_t *hash, u_int32_t const *in)
{
    md5_transform_CPUbyteorder(hash, in);
}

#if defined(CONFIG_X86_64) && defined(AMD64_ASM)
# define HAVE_MD5_2X_IMPLEMENTATION  1
#endif
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
/*
 * This 2x code is currently only available on little endian AMD64
 * This 2x code assumes little endian byte order
 * Context A input data is at zero offset, context B at data + 512 bytes
 * Context A ivout at zero offset, context B at ivout + 16 bytes
 */
void loop_compute_md5_iv_v3_2x(TransferSector_t devSect, u_int32_t *ivout, u_int32_t *data)
{
    int         x;
    u_int32_t   buf[2*16];

    x = 6;
    do {
        md5_transform_CPUbyteorder_2x(&ivout[0], data, data + (512/4));
        data += 16;
    } while (--x >= 0);
    memcpy(&buf[0], data, 48);
    memcpy(&buf[16], data + (512/4), 48);
    /* md5_transform_CPUbyteorder wants data in CPU byte order */
    /* devSect is already in CPU byte order -- no need to convert */
    if(sizeof(TransferSector_t) == 8) {
        /* use only 56 bits of sector number */
        buf[12] = devSect;
        buf[13] = (((u_int64_t)devSect >> 32) & 0xFFFFFF) | 0x80000000;
        buf[16 + 12] = ++devSect;
        buf[16 + 13] = (((u_int64_t)devSect >> 32) & 0xFFFFFF) | 0x80000000;
    } else {
        /* 32 bits of sector number + 24 zero bits */
        buf[12] = devSect;
        buf[16 + 13] = buf[13] = 0x80000000;
        buf[16 + 12] = ++devSect;
    }
    /* 4024 bits == 31 * 128 bit plaintext blocks + 56 bits of sector number */
    /* For version 3 on-disk format this really should be 4536 bits, but can't be */
    /* changed without breaking compatibility. V3 uses MD5-with-wrong-length IV */
    buf[16 + 14] = buf[14] = 4024;
    buf[16 + 15] = buf[15] = 0;
    md5_transform_CPUbyteorder_2x(&ivout[0], &buf[0], &buf[16]);
}
#endif /* defined(HAVE_MD5_2X_IMPLEMENTATION) */

/*
 * Special requirements for transfer functions:
 * (1) Plaintext data (loop_buf) may change while it is being read.
 * (2) On 2.2 and older kernels ciphertext buffer (raw_buf) may be doing
 *     writes to disk at any time, so it can't be used as temporary buffer.
 */
int transfer_aes(struct loop_device *lo, int cmd, char *raw_buf,
          char *loop_buf, int size, TransferSector_t devSect)
{
    aes_context     *a;
    AESmultiKey     *m;
    int             x;
    unsigned        y;
    u_int64_t       iv[4], *dip;
#if LINUX_VERSION_CODE < 0x20400
    /* on 2.2 and older kernels, real raw_buf may be doing */
    /* writes at any time, so this needs to be stack buffer */
    u_int64_t       tmp_raw_buf[64];
    char            *tmp_raw_b_ptr;
#endif

    if(!size || (size & 511)) {
        return -EINVAL;
    }
    m = (AESmultiKey *)lo->key_data;
    y = m->keyMask;
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    read_lock(&m->rwlock);
#endif
    if(cmd == READ) {
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
        /* if possible, use faster 2x MD5 implementation, currently AMD64 only (#6) */
        while((size >= (2*512)) && y) {
            /* multi-key mode, decrypt 2 sectors at a time */
            a = m->keyPtr[((unsigned)devSect    ) & y];
            /* decrypt using fake all-zero IV, first sector */
            memset(iv, 0, 16);
            x = 15;
            do {
                memcpy(&iv[2], raw_buf, 16);
                aes_decrypt(a, raw_buf, loop_buf);
                *((u_int64_t *)(&loop_buf[0])) ^= iv[0];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[1];
                raw_buf += 16;
                loop_buf += 16;
                memcpy(iv, raw_buf, 16);
                aes_decrypt(a, raw_buf, loop_buf);
                *((u_int64_t *)(&loop_buf[0])) ^= iv[2];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[3];
                raw_buf += 16;
                loop_buf += 16;
            } while(--x >= 0);
            a = m->keyPtr[((unsigned)devSect + 1) & y];
            /* decrypt using fake all-zero IV, second sector */
            memset(iv, 0, 16);
            x = 15;
            do {
                memcpy(&iv[2], raw_buf, 16);
                aes_decrypt(a, raw_buf, loop_buf);
                *((u_int64_t *)(&loop_buf[0])) ^= iv[0];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[1];
                raw_buf += 16;
                loop_buf += 16;
                memcpy(iv, raw_buf, 16);
                aes_decrypt(a, raw_buf, loop_buf);
                *((u_int64_t *)(&loop_buf[0])) ^= iv[2];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[3];
                raw_buf += 16;
                loop_buf += 16;
            } while(--x >= 0);
            /* compute correct IV */
            memcpy(&iv[0], &m->partialMD5[0], 16);
            memcpy(&iv[2], &m->partialMD5[0], 16);
            loop_compute_md5_iv_v3_2x(devSect, (u_int32_t *)iv, (u_int32_t *)(loop_buf - 1008));
            /* XOR with correct IV now */
            *((u_int64_t *)(loop_buf - 1024)) ^= iv[0];
            *((u_int64_t *)(loop_buf - 1016)) ^= iv[1];
            *((u_int64_t *)(loop_buf - 512)) ^= iv[2];
            *((u_int64_t *)(loop_buf - 504)) ^= iv[3];
            size -= 2*512;
            devSect += 2;
        }
#endif /* defined(HAVE_MD5_2X_IMPLEMENTATION) */
        while(size) {
            /* decrypt one sector at a time */
            a = m->keyPtr[((unsigned)devSect) & y];
            /* decrypt using fake all-zero IV */
            memset(iv, 0, 16);
            x = 15;
            do {
                memcpy(&iv[2], raw_buf, 16);
                aes_decrypt(a, raw_buf, loop_buf);
                *((u_int64_t *)(&loop_buf[0])) ^= iv[0];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[1];
                raw_buf += 16;
                loop_buf += 16;
                memcpy(iv, raw_buf, 16);
                aes_decrypt(a, raw_buf, loop_buf);
                *((u_int64_t *)(&loop_buf[0])) ^= iv[2];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[3];
                raw_buf += 16;
                loop_buf += 16;
            } while(--x >= 0);
            if(y) {
                /* multi-key mode, compute correct IV */
                memcpy(iv, &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)iv, (u_int32_t *)(loop_buf - 496));
            } else {
                /* single-key mode, compute correct IV  */
                loop_compute_sector_iv(devSect, (u_int32_t *)iv);
            }
            /* XOR with correct IV now */
            *((u_int64_t *)(loop_buf - 512)) ^= iv[0];
            *((u_int64_t *)(loop_buf - 504)) ^= iv[1];
            size -= 512;
            devSect++;
        }
    } else {
#if defined(HAVE_MD5_2X_IMPLEMENTATION) && (LINUX_VERSION_CODE >= 0x20400)
        /* if possible, use faster 2x MD5 implementation, currently AMD64 only (#5) */
        while((size >= (2*512)) && y) {
            /* multi-key mode, encrypt 2 sectors at a time */
            memcpy(raw_buf, loop_buf, 2*512);
            memcpy(&iv[0], &m->partialMD5[0], 16);
            memcpy(&iv[2], &m->partialMD5[0], 16);
            loop_compute_md5_iv_v3_2x(devSect, (u_int32_t *)iv, (u_int32_t *)(&raw_buf[16]));
            /* first sector */
            a = m->keyPtr[((unsigned)devSect    ) & y];
            dip = &iv[0];
            x = 15;
            do {
                *((u_int64_t *)(&raw_buf[0])) ^= dip[0];
                *((u_int64_t *)(&raw_buf[8])) ^= dip[1];
                aes_encrypt(a, raw_buf, raw_buf);
                dip = (u_int64_t *)raw_buf;
                raw_buf += 16;
                *((u_int64_t *)(&raw_buf[0])) ^= dip[0];
                *((u_int64_t *)(&raw_buf[8])) ^= dip[1];
                aes_encrypt(a, raw_buf, raw_buf);
                dip = (u_int64_t *)raw_buf;
                raw_buf += 16;
            } while(--x >= 0);
            /* second sector */
            a = m->keyPtr[((unsigned)devSect + 1) & y];
            dip = &iv[2];
            x = 15;
            do {
                *((u_int64_t *)(&raw_buf[0])) ^= dip[0];
                *((u_int64_t *)(&raw_buf[8])) ^= dip[1];
                aes_encrypt(a, raw_buf, raw_buf);
                dip = (u_int64_t *)raw_buf;
                raw_buf += 16;
                *((u_int64_t *)(&raw_buf[0])) ^= dip[0];
                *((u_int64_t *)(&raw_buf[8])) ^= dip[1];
                aes_encrypt(a, raw_buf, raw_buf);
                dip = (u_int64_t *)raw_buf;
                raw_buf += 16;
            } while(--x >= 0);
            loop_buf += 2*512;
            size -= 2*512;
            devSect += 2;
        }
#endif /* defined(HAVE_MD5_2X_IMPLEMENTATION) && (LINUX_VERSION_CODE >= 0x20400) */
        while(size) {
            /* encrypt one sector at a time */
            a = m->keyPtr[((unsigned)devSect) & y];
            if(y) {
#if LINUX_VERSION_CODE < 0x20400
                /* multi-key mode encrypt, linux 2.2 and older */
                tmp_raw_b_ptr = (char *)(&tmp_raw_buf[0]);
                memcpy(tmp_raw_b_ptr, loop_buf, 512);
                memcpy(iv, &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)iv, (u_int32_t *)(&tmp_raw_b_ptr[16]));
                dip = iv;
                x = 15;
                do {
                    *((u_int64_t *)(&tmp_raw_b_ptr[0])) ^= dip[0];
                    *((u_int64_t *)(&tmp_raw_b_ptr[8])) ^= dip[1];
                    aes_encrypt(a, tmp_raw_b_ptr, raw_buf);
                    dip = (u_int64_t *)raw_buf;
                    tmp_raw_b_ptr += 16;
                    raw_buf += 16;
                    *((u_int64_t *)(&tmp_raw_b_ptr[0])) ^= dip[0];
                    *((u_int64_t *)(&tmp_raw_b_ptr[8])) ^= dip[1];
                    aes_encrypt(a, tmp_raw_b_ptr, raw_buf);
                    dip = (u_int64_t *)raw_buf;
                    tmp_raw_b_ptr += 16;
                    raw_buf += 16;
                } while(--x >= 0);
                loop_buf += 512;
#else /* LINUX_VERSION_CODE >= 0x20400 */
                /* multi-key mode encrypt, linux 2.4 and newer */
                memcpy(raw_buf, loop_buf, 512);
                memcpy(iv, &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)iv, (u_int32_t *)(&raw_buf[16]));
                dip = iv;
                x = 15;
                do {
                    *((u_int64_t *)(&raw_buf[0])) ^= dip[0];
                    *((u_int64_t *)(&raw_buf[8])) ^= dip[1];
                    aes_encrypt(a, raw_buf, raw_buf);
                    dip = (u_int64_t *)raw_buf;
                    raw_buf += 16;
                    *((u_int64_t *)(&raw_buf[0])) ^= dip[0];
                    *((u_int64_t *)(&raw_buf[8])) ^= dip[1];
                    aes_encrypt(a, raw_buf, raw_buf);
                    dip = (u_int64_t *)raw_buf;
                    raw_buf += 16;
                } while(--x >= 0);
                loop_buf += 512;
#endif
            } else {
                /* single-key mode encrypt */
                loop_compute_sector_iv(devSect, (u_int32_t *)iv);
                dip = iv;
                x = 15;
                do {
                    iv[2] = *((u_int64_t *)(&loop_buf[0])) ^ dip[0];
                    iv[3] = *((u_int64_t *)(&loop_buf[8])) ^ dip[1];
                    aes_encrypt(a, (unsigned char *)(&iv[2]), raw_buf);
                    dip = (u_int64_t *)raw_buf;
                    loop_buf += 16;
                    raw_buf += 16;
                    iv[2] = *((u_int64_t *)(&loop_buf[0])) ^ dip[0];
                    iv[3] = *((u_int64_t *)(&loop_buf[8])) ^ dip[1];
                    aes_encrypt(a, (unsigned char *)(&iv[2]), raw_buf);
                    dip = (u_int64_t *)raw_buf;
                    loop_buf += 16;
                    raw_buf += 16;
                } while(--x >= 0);
            }
            size -= 512;
            devSect++;
        }
    }
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    read_unlock(&m->rwlock);
#endif
#if LINUX_VERSION_CODE >= 0x20600
    cond_resched();
#elif LINUX_VERSION_CODE >= 0x20400
    if(current->need_resched) {set_current_state(TASK_RUNNING);schedule();}
#elif LINUX_VERSION_CODE >= 0x20200
    if(current->need_resched) {current->state=TASK_RUNNING;schedule();}
#else
    if(need_resched) schedule();
#endif
    return(0);
}

#if defined(CONFIG_BLK_DEV_LOOP_PADLOCK) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
#if LINUX_VERSION_CODE < 0x20400
#error "this code does not support padlock crypto instructions on 2.2 or older kernels"
#endif

static __inline__ void padlock_flush_key_context(void)
{
    __asm__ __volatile__("pushf; popf" : : : "cc");
}

static __inline__ void padlock_rep_xcryptcbc(void *cw, void *k, void *s, void *d, void *iv, unsigned long cnt)
{
    __asm__ __volatile__(".byte 0xF3,0x0F,0xA7,0xD0"
                         : "+a" (iv), "+c" (cnt), "+S" (s), "+D" (d) /*output*/
                         : "b" (k), "d" (cw) /*input*/
                         : "cc", "memory" /*modified*/ );
}

typedef struct {
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
    u_int64_t   iv[2*2];
#else
    u_int64_t   iv[2];
#endif
    u_int32_t   cw[4];
    u_int32_t   dummy1[4];
} Padlock_IV_CW;

static int transfer_padlock_aes(struct loop_device *lo, int cmd, char *raw_buf,
          char *loop_buf, int size, TransferSector_t devSect)
{
    aes_context     *a;
    AESmultiKey     *m;
    unsigned        y;
    Padlock_IV_CW   ivcwua;
    Padlock_IV_CW   *ivcw;

    /* ivcw->iv and ivcw->cw must have 16 byte alignment */
    ivcw = (Padlock_IV_CW *)(((unsigned long)&ivcwua + 15) & ~((unsigned long)15));
    ivcw->cw[3] = ivcw->cw[2] = ivcw->cw[1] = 0;

    if(!size || (size & 511) || (((unsigned long)raw_buf | (unsigned long)loop_buf) & 15)) {
        return -EINVAL;
    }
    m = (AESmultiKey *)lo->key_data;
    y = m->keyMask;
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    read_lock(&m->rwlock);
#endif
    if(cmd == READ) {
        ivcw->cw[0] = m->padlock_cw_d;
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
        /* if possible, use faster 2x MD5 implementation, currently AMD64 only (#4) */
        while((size >= (2*512)) && y) {
            /* decrypt using fake all-zero IV */
            memset(&ivcw->iv[0], 0, 2*16);
            a = m->keyPtr[((unsigned)devSect    ) & y];
            padlock_flush_key_context();
            padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_d_key[0], raw_buf, loop_buf, &ivcw->iv[0], 32);
            a = m->keyPtr[((unsigned)devSect + 1) & y];
            padlock_flush_key_context();
            padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_d_key[0], raw_buf + 512, loop_buf + 512, &ivcw->iv[2], 32);
            /* compute correct IV */
            memcpy(&ivcw->iv[0], &m->partialMD5[0], 16);
            memcpy(&ivcw->iv[2], &m->partialMD5[0], 16);
            loop_compute_md5_iv_v3_2x(devSect, (u_int32_t *)(&ivcw->iv[0]), (u_int32_t *)(&loop_buf[16]));
            /* XOR with correct IV now */
            *((u_int64_t *)(&loop_buf[0])) ^= ivcw->iv[0];
            *((u_int64_t *)(&loop_buf[8])) ^= ivcw->iv[1];
            *((u_int64_t *)(&loop_buf[512 + 0])) ^= ivcw->iv[2];
            *((u_int64_t *)(&loop_buf[512 + 8])) ^= ivcw->iv[3];
            size -= 2*512;
            raw_buf += 2*512;
            loop_buf += 2*512;
            devSect += 2;
        }
#endif /* defined(HAVE_MD5_2X_IMPLEMENTATION) */
        while(size) {
            a = m->keyPtr[((unsigned)devSect) & y];
            padlock_flush_key_context();
            if(y) {
                /* decrypt using fake all-zero IV */
                memset(&ivcw->iv[0], 0, 16);
                padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_d_key[0], raw_buf, loop_buf, &ivcw->iv[0], 32);
                /* compute correct IV */
                memcpy(&ivcw->iv[0], &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)(&ivcw->iv[0]), (u_int32_t *)(&loop_buf[16]));
                /* XOR with correct IV now */
                *((u_int64_t *)(&loop_buf[ 0])) ^= ivcw->iv[0];
                *((u_int64_t *)(&loop_buf[ 8])) ^= ivcw->iv[1];
            } else {
                loop_compute_sector_iv(devSect, (u_int32_t *)(&ivcw->iv[0]));
                padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_d_key[0], raw_buf, loop_buf, &ivcw->iv[0], 32);
            }
            size -= 512;
            raw_buf += 512;
            loop_buf += 512;
            devSect++;
        }
    } else {
        ivcw->cw[0] = m->padlock_cw_e;
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
        /* if possible, use faster 2x MD5 implementation, currently AMD64 only (#3) */
        while((size >= (2*512)) && y) {
            memcpy(raw_buf, loop_buf, 2*512);
            memcpy(&ivcw->iv[0], &m->partialMD5[0], 16);
            memcpy(&ivcw->iv[2], &m->partialMD5[0], 16);
            loop_compute_md5_iv_v3_2x(devSect, (u_int32_t *)(&ivcw->iv[0]), (u_int32_t *)(&raw_buf[16]));
            a = m->keyPtr[((unsigned)devSect    ) & y];
            padlock_flush_key_context();
            padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_e_key[0], raw_buf, raw_buf, &ivcw->iv[0], 32);
            a = m->keyPtr[((unsigned)devSect + 1) & y];
            padlock_flush_key_context();
            padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_e_key[0], raw_buf + 512, raw_buf + 512, &ivcw->iv[2], 32);
            size -= 2*512;
            raw_buf += 2*512;
            loop_buf += 2*512;
            devSect += 2;
        }
#endif /* defined(HAVE_MD5_2X_IMPLEMENTATION) */
        while(size) {
            a = m->keyPtr[((unsigned)devSect) & y];
            padlock_flush_key_context();
            if(y) {
                memcpy(raw_buf, loop_buf, 512);
                memcpy(&ivcw->iv[0], &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)(&ivcw->iv[0]), (u_int32_t *)(&raw_buf[16]));
                padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_e_key[0], raw_buf, raw_buf, &ivcw->iv[0], 32);
            } else {
                loop_compute_sector_iv(devSect, (u_int32_t *)(&ivcw->iv[0]));
                padlock_rep_xcryptcbc(&ivcw->cw[0], &a->aes_e_key[0], loop_buf, raw_buf, &ivcw->iv[0], 32);
            }
            size -= 512;
            raw_buf += 512;
            loop_buf += 512;
            devSect++;
        }
    }
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    read_unlock(&m->rwlock);
#endif
#if LINUX_VERSION_CODE >= 0x20600
    cond_resched();
#else
    if(current->need_resched) {set_current_state(TASK_RUNNING);schedule();}
#endif
    return(0);
}
#endif

#if defined(CONFIG_BLK_DEV_LOOP_INTELAES) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
#if LINUX_VERSION_CODE < 0x20400
#error "this code does not support Intel AES crypto instructions on 2.2 or older kernels"
#endif

asmlinkage extern void intel_aes_cbc_encrypt(const aes_context *, void *src, void *dst, size_t len, void *iv);
asmlinkage extern void intel_aes_cbc_decrypt(const aes_context *, void *src, void *dst, size_t len, void *iv);
asmlinkage extern void intel_aes_cbc_enc_4x512(aes_context **, void *src, void *dst, void *iv);

static int transfer_intel_aes(struct loop_device *lo, int cmd, char *raw_buf,
          char *loop_buf, int size, TransferSector_t devSect)
{
    aes_context     *acpa[4];
    AESmultiKey     *m;
    unsigned        y;
    u_int64_t       ivua[(4*2)+2];
    u_int64_t       *iv;

    /* make iv 16 byte aligned */
    iv = (u_int64_t *)(((unsigned long)&ivua + 15) & ~((unsigned long)15));

    if(!size || (size & 511) || (((unsigned long)raw_buf | (unsigned long)loop_buf) & 15)) {
        return -EINVAL;
    }
    m = (AESmultiKey *)lo->key_data;
    y = m->keyMask;
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    read_lock(&m->rwlock);
#endif
    kernel_fpu_begin(); /* intel_aes_* code uses xmm registers */
    if(cmd == READ) {
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
        /* if possible, use faster 2x MD5 implementation, currently AMD64 only (#2) */
        while((size >= (2*512)) && y) {
            acpa[0] = m->keyPtr[((unsigned)devSect    ) & y];
            acpa[1] = m->keyPtr[((unsigned)devSect + 1) & y];
            /* decrypt using fake all-zero IV */
            memset(iv, 0, 2*16);
            intel_aes_cbc_decrypt(acpa[0], raw_buf,       loop_buf,       512, &iv[0]);
            intel_aes_cbc_decrypt(acpa[1], raw_buf + 512, loop_buf + 512, 512, &iv[2]);
            /* compute correct IV, use 2x parallelized version */
            memcpy(&iv[0], &m->partialMD5[0], 16);
            memcpy(&iv[2], &m->partialMD5[0], 16);
            loop_compute_md5_iv_v3_2x(devSect, (u_int32_t *)iv, (u_int32_t *)(&loop_buf[16]));
            /* XOR with correct IV now */
            *((u_int64_t *)(&loop_buf[0])) ^= iv[0];
            *((u_int64_t *)(&loop_buf[8])) ^= iv[1];
            *((u_int64_t *)(&loop_buf[512 + 0])) ^= iv[2];
            *((u_int64_t *)(&loop_buf[512 + 8])) ^= iv[3];
            size -= 2*512;
            raw_buf += 2*512;
            loop_buf += 2*512;
            devSect += 2;
        }
#endif /* defined(HAVE_MD5_2X_IMPLEMENTATION) */
        while(size) {
            acpa[0] = m->keyPtr[((unsigned)devSect) & y];
            if(y) {
                /* decrypt using fake all-zero IV */
                memset(iv, 0, 16);
                intel_aes_cbc_decrypt(acpa[0], raw_buf, loop_buf, 512, iv);
                /* compute correct IV */
                memcpy(iv, &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)iv, (u_int32_t *)(&loop_buf[16]));
                /* XOR with correct IV now */
                *((u_int64_t *)(&loop_buf[0])) ^= iv[0];
                *((u_int64_t *)(&loop_buf[8])) ^= iv[1];
            } else {
                loop_compute_sector_iv(devSect, (u_int32_t *)iv);
                intel_aes_cbc_decrypt(acpa[0], raw_buf, loop_buf, 512, iv);
            }
            size -= 512;
            raw_buf += 512;
            loop_buf += 512;
            devSect++;
        }
    } else {
        /* if possible, use faster 4-chains at a time encrypt implementation (#1) */
        while(size >= (4*512)) {
            acpa[0] = m->keyPtr[((unsigned)devSect    ) & y];
            acpa[1] = m->keyPtr[((unsigned)devSect + 1) & y];
            acpa[2] = m->keyPtr[((unsigned)devSect + 2) & y];
            acpa[3] = m->keyPtr[((unsigned)devSect + 3) & y];
            if(y) {
                memcpy(raw_buf, loop_buf, 4*512);
                memcpy(&iv[0], &m->partialMD5[0], 16);
                memcpy(&iv[2], &m->partialMD5[0], 16);
                memcpy(&iv[4], &m->partialMD5[0], 16);
                memcpy(&iv[6], &m->partialMD5[0], 16);
#if defined(HAVE_MD5_2X_IMPLEMENTATION)
                /* use 2x parallelized version */
                loop_compute_md5_iv_v3_2x(devSect,     (u_int32_t *)(&iv[0]), (u_int32_t *)(&raw_buf[        16]));
                loop_compute_md5_iv_v3_2x(devSect + 2, (u_int32_t *)(&iv[4]), (u_int32_t *)(&raw_buf[0x400 + 16]));
#else
                loop_compute_md5_iv_v3(devSect,     (u_int32_t *)(&iv[0]), (u_int32_t *)(&raw_buf[        16]));
                loop_compute_md5_iv_v3(devSect + 1, (u_int32_t *)(&iv[2]), (u_int32_t *)(&raw_buf[0x200 + 16]));
                loop_compute_md5_iv_v3(devSect + 2, (u_int32_t *)(&iv[4]), (u_int32_t *)(&raw_buf[0x400 + 16]));
                loop_compute_md5_iv_v3(devSect + 3, (u_int32_t *)(&iv[6]), (u_int32_t *)(&raw_buf[0x600 + 16]));
#endif
                intel_aes_cbc_enc_4x512(&acpa[0], raw_buf, raw_buf, iv);
            } else {
                loop_compute_sector_iv(devSect,     (u_int32_t *)(&iv[0]));
                loop_compute_sector_iv(devSect + 1, (u_int32_t *)(&iv[2]));
                loop_compute_sector_iv(devSect + 2, (u_int32_t *)(&iv[4]));
                loop_compute_sector_iv(devSect + 3, (u_int32_t *)(&iv[6]));
                intel_aes_cbc_enc_4x512(&acpa[0], loop_buf, raw_buf, iv);
            }
            size -= 4*512;
            raw_buf += 4*512;
            loop_buf += 4*512;
            devSect += 4;
        }
        /* encrypt the rest (if any) using slower 1-chain at a time implementation */
        while(size) {
            acpa[0] = m->keyPtr[((unsigned)devSect) & y];
            if(y) {
                memcpy(raw_buf, loop_buf, 512);
                memcpy(iv, &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, (u_int32_t *)iv, (u_int32_t *)(&raw_buf[16]));
                intel_aes_cbc_encrypt(acpa[0], raw_buf, raw_buf, 512, iv);
            } else {
                loop_compute_sector_iv(devSect, (u_int32_t *)iv);
                intel_aes_cbc_encrypt(acpa[0], loop_buf, raw_buf, 512, iv);
            }
            size -= 512;
            raw_buf += 512;
            loop_buf += 512;
            devSect++;
        }
    }
    kernel_fpu_end(); /* intel_aes_* code uses xmm registers */
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    read_unlock(&m->rwlock);
#endif
#if LINUX_VERSION_CODE >= 0x20600
    cond_resched();
#else
    if(current->need_resched) {set_current_state(TASK_RUNNING);schedule();}
#endif
    return(0);
}
#endif

#if LINUX_VERSION_CODE >= 0x20200

static struct loop_func_table funcs_aes = {
    number:     16,     /* 16 == AES */
    transfer:   (void *) transfer_aes,
    init:       (void *) keySetup_aes,
    release:    keyClean_aes,
    ioctl:      (void *) handleIoctl_aes
};

#if defined(CONFIG_BLK_DEV_LOOP_PADLOCK) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
static struct loop_func_table funcs_padlock_aes = {
    number:     16,     /* 16 == AES */
    transfer:   (void *) transfer_padlock_aes,
    init:       (void *) keySetup_aes,
    release:    keyClean_aes,
    ioctl:      (void *) handleIoctl_aes
};
#endif

#if defined(CONFIG_BLK_DEV_LOOP_INTELAES) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
static struct loop_func_table funcs_intel_aes = {
    number:     16,     /* 16 == AES */
    transfer:   (void *) transfer_intel_aes,
    init:       (void *) keySetup_aes,
    release:    keyClean_aes,
    ioctl:      (void *) handleIoctl_aes
};
#endif

#if defined(CONFIG_BLK_DEV_LOOP_PADLOCK) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
static int CentaurHauls_ID_and_enabled_ACE(void)
{
    unsigned int eax = 0, ebx = 0, ecx = 0, edx = 0;

    /* check for "CentaurHauls" ID string, and enabled ACE */
    cpuid(0x00000000, &eax, &ebx, &ecx, &edx);
    if((ebx == 0x746e6543) && (edx == 0x48727561) && (ecx == 0x736c7561)
      && (cpuid_eax(0xC0000000) >= 0xC0000001)
      && ((cpuid_edx(0xC0000001) & 0xC0) == 0xC0)) {
        return 1;   /* ACE enabled */
    }
    return 0;
}
#endif

int init_module_aes(void)
{
#if defined(CONFIG_BLK_DEV_LOOP_PADLOCK) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
    if((boot_cpu_data.x86 >= 6) && CentaurHauls_ID_and_enabled_ACE()) {
        if(loop_register_transfer(&funcs_padlock_aes)) {
            printk("loop: unable to register padlock AES transfer\n");
            return -EIO;
        }
        printk("loop: padlock hardware AES enabled\n");
    } else
#endif
#if defined(CONFIG_BLK_DEV_LOOP_INTELAES) && (defined(CONFIG_X86) || defined(CONFIG_X86_64))
    if((boot_cpu_data.x86 >= 6) && ((cpuid_ecx(1) & 0x02000000) == 0x02000000)) {
        if(loop_register_transfer(&funcs_intel_aes)) {
            printk("loop: unable to register Intel AES transfer\n");
            return -EIO;
        }
        printk("loop: Intel hardware AES enabled\n");
    } else
#endif
    if(loop_register_transfer(&funcs_aes)) {
        printk("loop: unable to register AES transfer\n");
        return -EIO;
    }
#ifdef CONFIG_BLK_DEV_LOOP_KEYSCRUB
    printk("loop: AES key scrubbing enabled\n");
#endif
    return 0;
}

void cleanup_module_aes(void)
{
    if(loop_unregister_transfer(funcs_aes.number)) {
        printk("loop: unable to unregister AES transfer\n");
    }
}

#endif
