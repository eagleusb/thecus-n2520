/* Optimized implementation of the Serpent AES candidate algorithm
 * Designed by Anderson, Biham and Knudsen and Implemented by 
 * Gisle Sælensminde 2000. 
 *
 * The implementation is based on the pentium optimised sboxes of
 * Dag Arne Osvik. Even these sboxes are designed to be optimal for x86 
 * processors they are efficient on other processors as well, but the speedup 
 * isn't so impressive compared to other implementations.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public License
 * as published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version. 
 *
 * Adapted to normal loop device transfer interface.
 * Jari Ruusu, March 5 2002
 *
 * Fixed endianness bug.
 * Jari Ruusu, December 26 2002
 *
 * Added support for MD5 IV computation and multi-key operation.
 * Jari Ruusu, October 22 2003
 */

#include <linux/version.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/sched.h>
#include <linux/fs.h>
#include <linux/string.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/mm.h>
#include <linux/slab.h>
#if LINUX_VERSION_CODE >= 0x20600
# include <linux/bio.h>
# include <linux/blkdev.h>
#endif
#include <linux/loop.h>
#include <asm/uaccess.h>
#include <asm/byteorder.h>

#define rotl(reg, val) ((reg << val) | (reg >> (32 - val)))
#define rotr(reg, val) ((reg >> val) | (reg << (32 - val)))

#define io_swap_be(x)  __cpu_to_be32(x)     /* incorrect byte order */
#define io_swap_le(x)  __cpu_to_le32(x)     /* correct byte order */

/* The sbox functions. The first four parameters is the input bits, and 
 * the last is a tempoary. These parameters are also used for output, but
 * the bit order is permuted. The output bit order from S0 is
 * (1 4 2 0 3), where 3 is the (now useless) tempoary. 
 */

#define S0(r0,r1,r2,r3,r4) \
      r3 = r3 ^ r0; \
      r4 = r1; \
      r1 = r1 & r3; \
      r4 = r4 ^ r2; \
      r1 = r1 ^ r0; \
      r0 = r0 | r3; \
      r0 = r0 ^ r4; \
      r4 = r4 ^ r3; \
      r3 = r3 ^ r2; \
      r2 = r2 | r1; \
      r2 = r2 ^ r4; \
      r4 = -1 ^ r4; \
      r4 = r4 | r1; \
      r1 = r1 ^ r3; \
      r1 = r1 ^ r4; \
      r3 = r3 | r0; \
      r1 = r1 ^ r3; \
      r4 = r4 ^ r3; 

#define S1(r0,r1,r2,r3,r4) \
      r1 = -1 ^ r1; \
      r4 = r0; \
      r0 = r0 ^ r1; \
      r4 = r4 | r1; \
      r4 = r4 ^ r3; \
      r3 = r3 & r0; \
      r2 = r2 ^ r4; \
      r3 = r3 ^ r1; \
      r3 = r3 | r2; \
      r0 = r0 ^ r4; \
      r3 = r3 ^ r0; \
      r1 = r1 & r2; \
      r0 = r0 | r1; \
      r1 = r1 ^ r4; \
      r0 = r0 ^ r2; \
      r4 = r4 | r3; \
      r0 = r0 ^ r4; \
      r4 = -1 ^ r4; \
      r1 = r1 ^ r3; \
      r4 = r4 & r2; \
      r1 = -1 ^ r1; \
      r4 = r4 ^ r0; \
      r1 = r1 ^ r4; 

#define S2(r0,r1,r2,r3,r4) \
      r4 = r0; \
      r0 = r0 & r2; \
      r0 = r0 ^ r3; \
      r2 = r2 ^ r1; \
      r2 = r2 ^ r0; \
      r3 = r3 | r4; \
      r3 = r3 ^ r1; \
      r4 = r4 ^ r2; \
      r1 = r3; \
      r3 = r3 | r4; \
      r3 = r3 ^ r0; \
      r0 = r0 & r1; \
      r4 = r4 ^ r0; \
      r1 = r1 ^ r3; \
      r1 = r1 ^ r4; \
      r4 = -1 ^ r4; 

#define S3(r0,r1,r2,r3,r4) \
      r4 = r0 ; \
      r0 = r0 | r3; \
      r3 = r3 ^ r1; \
      r1 = r1 & r4; \
      r4 = r4 ^ r2; \
      r2 = r2 ^ r3; \
      r3 = r3 & r0; \
      r4 = r4 | r1; \
      r3 = r3 ^ r4; \
      r0 = r0 ^ r1; \
      r4 = r4 & r0; \
      r1 = r1 ^ r3; \
      r4 = r4 ^ r2; \
      r1 = r1 | r0; \
      r1 = r1 ^ r2; \
      r0 = r0 ^ r3; \
      r2 = r1; \
      r1 = r1 | r3; \
      r1 = r1 ^ r0; 

#define S4(r0,r1,r2,r3,r4) \
      r1 = r1 ^ r3; \
      r3 = -1 ^ r3; \
      r2 = r2 ^ r3; \
      r3 = r3 ^ r0; \
      r4 = r1; \
      r1 = r1 & r3; \
      r1 = r1 ^ r2; \
      r4 = r4 ^ r3; \
      r0 = r0 ^ r4; \
      r2 = r2 & r4; \
      r2 = r2 ^ r0; \
      r0 = r0 & r1; \
      r3 = r3 ^ r0; \
      r4 = r4 | r1; \
      r4 = r4 ^ r0; \
      r0 = r0 | r3; \
      r0 = r0 ^ r2; \
      r2 = r2 & r3; \
      r0 = -1 ^ r0; \
      r4 = r4 ^ r2; 

#define S5(r0,r1,r2,r3,r4) \
      r0 = r0 ^ r1; \
      r1 = r1 ^ r3; \
      r3 = -1 ^ r3; \
      r4 = r1; \
      r1 = r1 & r0; \
      r2 = r2 ^ r3; \
      r1 = r1 ^ r2; \
      r2 = r2 | r4; \
      r4 = r4 ^ r3; \
      r3 = r3 & r1; \
      r3 = r3 ^ r0; \
      r4 = r4 ^ r1; \
      r4 = r4 ^ r2; \
      r2 = r2 ^ r0; \
      r0 = r0 & r3; \
      r2 = -1 ^ r2; \
      r0 = r0 ^ r4; \
      r4 = r4 | r3; \
      r2 = r2 ^ r4; 

#define S6(r0,r1,r2,r3,r4) \
      r2 = -1 ^ r2; \
      r4 = r3; \
      r3 = r3 & r0; \
      r0 = r0 ^ r4; \
      r3 = r3 ^ r2; \
      r2 = r2 | r4; \
      r1 = r1 ^ r3; \
      r2 = r2 ^ r0; \
      r0 = r0 | r1; \
      r2 = r2 ^ r1; \
      r4 = r4 ^ r0; \
      r0 = r0 | r3; \
      r0 = r0 ^ r2; \
      r4 = r4 ^ r3; \
      r4 = r4 ^ r0; \
      r3 = -1 ^ r3; \
      r2 = r2 & r4; \
      r2 = r2 ^ r3; 

#define S7(r0,r1,r2,r3,r4) \
      r4 = r2; \
      r2 = r2 & r1; \
      r2 = r2 ^ r3; \
      r3 = r3 & r1; \
      r4 = r4 ^ r2; \
      r2 = r2 ^ r1; \
      r1 = r1 ^ r0; \
      r0 = r0 | r4; \
      r0 = r0 ^ r2; \
      r3 = r3 ^ r1; \
      r2 = r2 ^ r3; \
      r3 = r3 & r0; \
      r3 = r3 ^ r4; \
      r4 = r4 ^ r2; \
      r2 = r2 & r0; \
      r4 = -1 ^ r4; \
      r2 = r2 ^ r4; \
      r4 = r4 & r0; \
      r1 = r1 ^ r3; \
      r4 = r4 ^ r1; 

/* The inverse sboxes */

#define I0(r0,r1,r2,r3,r4) \
      r2 = r2 ^ -1; \
      r4 = r1; \
      r1 = r1 | r0; \
      r4 = r4 ^ -1; \
      r1 = r1 ^ r2; \
      r2 = r2 | r4; \
      r1 = r1 ^ r3; \
      r0 = r0 ^ r4; \
      r2 = r2 ^ r0; \
      r0 = r0 & r3; \
      r4 = r4 ^ r0; \
      r0 = r0 | r1; \
      r0 = r0 ^ r2; \
      r3 = r3 ^ r4; \
      r2 = r2 ^ r1; \
      r3 = r3 ^ r0; \
      r3 = r3 ^ r1; \
      r2 = r2 & r3; \
      r4 = r4 ^ r2; 
 
#define I1(r0,r1,r2,r3,r4) \
      r4 = r1; \
      r1 = r1 ^ r3; \
      r3 = r3 & r1; \
      r4 = r4 ^ r2; \
      r3 = r3 ^ r0; \
      r0 = r0 | r1; \
      r2 = r2 ^ r3; \
      r0 = r0 ^ r4; \
      r0 = r0 | r2; \
      r1 = r1 ^ r3; \
      r0 = r0 ^ r1; \
      r1 = r1 | r3; \
      r1 = r1 ^ r0; \
      r4 = r4 ^ -1; \
      r4 = r4 ^ r1; \
      r1 = r1 | r0; \
      r1 = r1 ^ r0; \
      r1 = r1 | r4; \
      r3 = r3 ^ r1; 

#define I2(r0,r1,r2,r3,r4) \
      r2 = r2 ^ r3; \
      r3 = r3 ^ r0; \
      r4 =  r3; \
      r3 = r3 & r2; \
      r3 = r3 ^ r1; \
      r1 = r1 | r2; \
      r1 = r1 ^ r4; \
      r4 = r4 & r3; \
      r2 = r2 ^ r3; \
      r4 = r4 & r0; \
      r4 = r4 ^ r2; \
      r2 = r2 & r1; \
      r2 = r2 | r0; \
      r3 = r3 ^ -1; \
      r2 = r2 ^ r3; \
      r0 = r0 ^ r3; \
      r0 = r0 & r1; \
      r3 = r3 ^ r4; \
      r3 = r3 ^ r0; 

#define I3(r0,r1,r2,r3,r4) \
      r4 =  r2; \
      r2 = r2 ^ r1; \
      r0 = r0 ^ r2; \
      r4 = r4 & r2; \
      r4 = r4 ^ r0; \
      r0 = r0 & r1; \
      r1 = r1 ^ r3; \
      r3 = r3 | r4; \
      r2 = r2 ^ r3; \
      r0 = r0 ^ r3; \
      r1 = r1 ^ r4; \
      r3 = r3 & r2; \
      r3 = r3 ^ r1; \
      r1 = r1 ^ r0; \
      r1 = r1 | r2; \
      r0 = r0 ^ r3; \
      r1 = r1 ^ r4; \
      r0 = r0 ^ r1; 

#define I4(r0,r1,r2,r3,r4) \
      r4 =  r2; \
      r2 = r2 & r3; \
      r2 = r2 ^ r1; \
      r1 = r1 | r3; \
      r1 = r1 & r0; \
      r4 = r4 ^ r2; \
      r4 = r4 ^ r1; \
      r1 = r1 & r2; \
      r0 = r0 ^ -1; \
      r3 = r3 ^ r4; \
      r1 = r1 ^ r3; \
      r3 = r3 & r0; \
      r3 = r3 ^ r2; \
      r0 = r0 ^ r1; \
      r2 = r2 & r0; \
      r3 = r3 ^ r0; \
      r2 = r2 ^ r4; \
      r2 = r2 | r3; \
      r3 = r3 ^ r0; \
      r2 = r2 ^ r1; 

#define I5(r0,r1,r2,r3,r4) \
      r1 = r1 ^ -1; \
      r4 = r3; \
      r2 = r2 ^ r1; \
      r3 = r3 | r0; \
      r3 = r3 ^ r2; \
      r2 = r2 | r1; \
      r2 = r2 & r0; \
      r4 = r4 ^ r3; \
      r2 = r2 ^ r4; \
      r4 = r4 | r0; \
      r4 = r4 ^ r1; \
      r1 = r1 & r2; \
      r1 = r1 ^ r3; \
      r4 = r4 ^ r2; \
      r3 = r3 & r4; \
      r4 = r4 ^ r1; \
      r3 = r3 ^ r0; \
      r3 = r3 ^ r4; \
      r4 = r4 ^ -1; 

#define I6(r0,r1,r2,r3,r4) \
      r0 = r0 ^ r2; \
      r4 = r2; \
      r2 = r2 & r0; \
      r4 = r4 ^ r3; \
      r2 = r2 ^ -1; \
      r3 = r3 ^ r1; \
      r2 = r2 ^ r3; \
      r4 = r4 | r0; \
      r0 = r0 ^ r2; \
      r3 = r3 ^ r4; \
      r4 = r4 ^ r1; \
      r1 = r1 & r3; \
      r1 = r1 ^ r0; \
      r0 = r0 ^ r3; \
      r0 = r0 | r2; \
      r3 = r3 ^ r1; \
      r4 = r4 ^ r0; 

#define I7(r0,r1,r2,r3,r4) \
      r4 = r2; \
      r2 = r2 ^ r0; \
      r0 = r0 & r3; \
      r4 = r4 | r3; \
      r2 = r2 ^ -1; \
      r3 = r3 ^ r1; \
      r1 = r1 | r0; \
      r0 = r0 ^ r2; \
      r2 = r2 & r4; \
      r3 = r3 & r4; \
      r1 = r1 ^ r2; \
      r2 = r2 ^ r0; \
      r0 = r0 | r2; \
      r4 = r4 ^ r1; \
      r0 = r0 ^ r3; \
      r3 = r3 ^ r4; \
      r4 = r4 | r0; \
      r3 = r3 ^ r2; \
      r4 = r4 ^ r2; 

/* forward and inverse linear transformations */

#define LINTRANS(r0,r1,r2,r3,r4) \
      r0 = rotl(r0, 13); \
      r2 = rotl(r2, 3); \
      r3 = r3 ^ r2; \
      r4 = r0 << 3; \
      r1 = r1 ^ r0; \
      r3 = r3 ^ r4; \
      r1 = r1 ^ r2; \
      r3 = rotl(r3, 7); \
      r1 = rotl(r1, 1); \
      r2 = r2 ^ r3; \
      r4 = r1 << 7; \
      r0 = r0 ^ r1; \
      r2 = r2 ^ r4; \
      r0 = r0 ^ r3; \
      r2 = rotl(r2, 22); \
      r0 = rotl(r0, 5);
     
#define ILINTRANS(r0,r1,r2,r3,r4) \
      r2 = rotr(r2, 22); \
      r0 = rotr(r0, 5); \
      r2 = r2 ^ r3; \
      r4 = r1 << 7; \
      r0 = r0 ^ r1; \
      r2 = r2 ^ r4; \
      r0 = r0 ^ r3; \
      r3 = rotr(r3, 7); \
      r1 = rotr(r1, 1); \
      r3 = r3 ^ r2; \
      r4 = r0 << 3; \
      r1 = r1 ^ r0; \
      r3 = r3 ^ r4; \
      r1 = r1 ^ r2; \
      r2 = rotr(r2, 3); \
      r0 = rotr(r0, 13); 


#define KEYMIX(r0,r1,r2,r3,r4,IN) \
      r0  = r0 ^ l_key[IN+8]; \
      r1  = r1 ^ l_key[IN+9]; \
      r2  = r2 ^ l_key[IN+10]; \
      r3  = r3 ^ l_key[IN+11]; 

#define GETKEY(r0, r1, r2, r3, IN) \
      r0 = l_key[IN+8]; \
      r1 = l_key[IN+9]; \
      r2 = l_key[IN+10]; \
      r3 = l_key[IN+11]; 

#define SETKEY(r0, r1, r2, r3, IN) \
      l_key[IN+8] = r0; \
      l_key[IN+9] = r1; \
      l_key[IN+10] = r2; \
      l_key[IN+11] = r3;

/* initialise the key schedule from the user supplied key   */

static void serpent_set_key(u32 *l_key, unsigned char *key, int key_len, int wrongByteOrder)
{
    u32 *in_key = (u32 *)key;
    u32  i,lk,r0,r1,r2,r3,r4;

    if (key_len != 16 && key_len != 24 && key_len != 32)
      key_len = 16;
    
    key_len *= 8;

    i = 0; lk = (key_len + 31) / 32;
    
    while(i < lk)
    {
        if (wrongByteOrder) {
            /* incorrect byte order */
            l_key[i] = io_swap_be(in_key[lk - i - 1]);
        } else {
            /* correct byte order */
            l_key[i] = io_swap_le(in_key[i]);
        }
        i++;
    }

    if (key_len < 256)
    {
        while(i < 8)

            l_key[i++] = 0;

        i = key_len / 32; lk = 1 << key_len % 32; 

        l_key[i] &= lk - 1;
        l_key[i] |= lk;
    }

    for(i = 0; i < 132; ++i)
    {
        lk = l_key[i] ^ l_key[i + 3] ^ l_key[i + 5] 
                                ^ l_key[i + 7] ^ 0x9e3779b9 ^ i;

        l_key[i + 8] = (lk << 11) | (lk >> 21); 
    }

      GETKEY(r0, r1, r2, r3, 0);
      S3(r0,r1,r2,r3,r4);
      SETKEY(r1, r2, r3, r4, 0) 

      GETKEY(r0, r1, r2, r3, 4);
      S2(r0,r1,r2,r3,r4);
      SETKEY(r2, r3, r1, r4, 4) 

      GETKEY(r0, r1, r2, r3, 8);
      S1(r0,r1,r2,r3,r4);
      SETKEY(r3, r1, r2, r0, 8) 

      GETKEY(r0, r1, r2, r3, 12);
      S0(r0,r1,r2,r3,r4);
      SETKEY(r1, r4, r2, r0, 12) 

      GETKEY(r0, r1, r2, r3, 16);
      S7(r0,r1,r2,r3,r4);
      SETKEY(r2, r4, r3, r0, 16) 

      GETKEY(r0, r1, r2, r3, 20);
      S6(r0,r1,r2,r3,r4) 
      SETKEY(r0, r1, r4, r2, 20) 

      GETKEY(r0, r1, r2, r3, 24);
      S5(r0,r1,r2,r3,r4);
      SETKEY(r1, r3, r0, r2, 24) 

      GETKEY(r0, r1, r2, r3, 28);
      S4(r0,r1,r2,r3,r4) 
      SETKEY(r1, r4, r0, r3, 28) 

      GETKEY(r0, r1, r2, r3, 32);
      S3(r0,r1,r2,r3,r4);
      SETKEY(r1, r2, r3, r4, 32) 

      GETKEY(r0, r1, r2, r3, 36);
      S2(r0,r1,r2,r3,r4);
      SETKEY(r2, r3, r1, r4, 36) 

      GETKEY(r0, r1, r2, r3, 40);
      S1(r0,r1,r2,r3,r4);
      SETKEY(r3, r1, r2, r0, 40) 

      GETKEY(r0, r1, r2, r3, 44);
      S0(r0,r1,r2,r3,r4);
      SETKEY(r1, r4, r2, r0, 44) 

      GETKEY(r0, r1, r2, r3, 48);
      S7(r0,r1,r2,r3,r4);
      SETKEY(r2, r4, r3, r0, 48) 

      GETKEY(r0, r1, r2, r3, 52);
      S6(r0,r1,r2,r3,r4) 
      SETKEY(r0, r1, r4, r2, 52) 

      GETKEY(r0, r1, r2, r3, 56);
      S5(r0,r1,r2,r3,r4);
      SETKEY(r1, r3, r0, r2, 56) 

      GETKEY(r0, r1, r2, r3, 60);
      S4(r0,r1,r2,r3,r4) 
      SETKEY(r1, r4, r0, r3, 60) 

      GETKEY(r0, r1, r2, r3, 64);
      S3(r0,r1,r2,r3,r4);
      SETKEY(r1, r2, r3, r4, 64) 

      GETKEY(r0, r1, r2, r3, 68);
      S2(r0,r1,r2,r3,r4);
      SETKEY(r2, r3, r1, r4, 68) 

      GETKEY(r0, r1, r2, r3, 72);
      S1(r0,r1,r2,r3,r4);
      SETKEY(r3, r1, r2, r0, 72) 

      GETKEY(r0, r1, r2, r3, 76);
      S0(r0,r1,r2,r3,r4);
      SETKEY(r1, r4, r2, r0, 76) 

      GETKEY(r0, r1, r2, r3, 80);
      S7(r0,r1,r2,r3,r4);
      SETKEY(r2, r4, r3, r0, 80) 

      GETKEY(r0, r1, r2, r3, 84);
      S6(r0,r1,r2,r3,r4) 
      SETKEY(r0, r1, r4, r2, 84) 

      GETKEY(r0, r1, r2, r3, 88);
      S5(r0,r1,r2,r3,r4);
      SETKEY(r1, r3, r0, r2, 88) 

      GETKEY(r0, r1, r2, r3, 92);
      S4(r0,r1,r2,r3,r4) 
      SETKEY(r1, r4, r0, r3, 92) 

      GETKEY(r0, r1, r2, r3, 96);
      S3(r0,r1,r2,r3,r4);
      SETKEY(r1, r2, r3, r4, 96) 

      GETKEY(r0, r1, r2, r3, 100);
      S2(r0,r1,r2,r3,r4);
      SETKEY(r2, r3, r1, r4, 100) 

      GETKEY(r0, r1, r2, r3, 104);
      S1(r0,r1,r2,r3,r4);
      SETKEY(r3, r1, r2, r0, 104) 

      GETKEY(r0, r1, r2, r3, 108);
      S0(r0,r1,r2,r3,r4);
      SETKEY(r1, r4, r2, r0, 108) 

      GETKEY(r0, r1, r2, r3, 112);
      S7(r0,r1,r2,r3,r4);
      SETKEY(r2, r4, r3, r0, 112) 

      GETKEY(r0, r1, r2, r3, 116);
      S6(r0,r1,r2,r3,r4) 
      SETKEY(r0, r1, r4, r2, 116) 

      GETKEY(r0, r1, r2, r3, 120);
      S5(r0,r1,r2,r3,r4);
      SETKEY(r1, r3, r0, r2, 120) 

      GETKEY(r0, r1, r2, r3, 124);
      S4(r0,r1,r2,r3,r4) 
      SETKEY(r1, r4, r0, r3, 124) 

      GETKEY(r0, r1, r2, r3, 128);
      S3(r0,r1,r2,r3,r4);
      SETKEY(r1, r2, r3, r4, 128) 
};

/* Encryption and decryption functions. The rounds are fully inlined. 
 * The sboxes alters the bit order of the output, and the altered
 * bit ordrer is used progressivly. */

/* encrypt a block of text */

static void serpent_encrypt(u32 *l_key, const u8 *in, u8 *out, int wrongByteOrder)
{
     const u32 *in_blk = (u32 *) in;
     u32 *out_blk = (u32 *) out;
     u32  r0,r1,r2,r3,r4;
    
      if (wrongByteOrder) {
          /* incorrect byte order */
          r0 = io_swap_be(in_blk[3]);
          r1 = io_swap_be(in_blk[2]);
          r2 = io_swap_be(in_blk[1]);
          r3 = io_swap_be(in_blk[0]);
      } else {
          /* correct byte order */
          r0 = io_swap_le(in_blk[0]);
          r1 = io_swap_le(in_blk[1]);
          r2 = io_swap_le(in_blk[2]);
          r3 = io_swap_le(in_blk[3]);
      }

      /* round 1  */
      KEYMIX(r0,r1,r2,r3,r4,0);
      S0(r0,r1,r2,r3,r4);
      LINTRANS(r1,r4,r2,r0,r3);

      /* round 2  */
      KEYMIX(r1,r4,r2,r0,r3,4);
      S1(r1,r4,r2,r0,r3);
      LINTRANS(r0,r4,r2,r1,r3);

      /* round 3  */
      KEYMIX(r0,r4,r2,r1,r3,8);
      S2(r0,r4,r2,r1,r3);
      LINTRANS(r2,r1,r4,r3,r0);

      /* round 4  */
      KEYMIX(r2,r1,r4,r3,r0,12);
      S3(r2,r1,r4,r3,r0);
      LINTRANS(r1,r4,r3,r0,r2);

      /* round 5  */
      KEYMIX(r1,r4,r3,r0,r2,16);
      S4(r1,r4,r3,r0,r2) 
      LINTRANS(r4,r2,r1,r0,r3);

      /* round 6  */
      KEYMIX(r4,r2,r1,r0,r3,20);
      S5(r4,r2,r1,r0,r3);
      LINTRANS(r2,r0,r4,r1,r3);

      /* round 7  */
      KEYMIX(r2,r0,r4,r1,r3,24);
      S6(r2,r0,r4,r1,r3) 
      LINTRANS(r2,r0,r3,r4,r1);

      /* round 8  */
      KEYMIX(r2,r0,r3,r4,r1,28);
      S7(r2,r0,r3,r4,r1);
      LINTRANS(r3,r1,r4,r2,r0);

      /* round 9  */
      KEYMIX(r3,r1,r4,r2,r0,32);
      S0(r3,r1,r4,r2,r0);
      LINTRANS(r1,r0,r4,r3,r2);

      /* round 10  */
      KEYMIX(r1,r0,r4,r3,r2,36);
      S1(r1,r0,r4,r3,r2);
      LINTRANS(r3,r0,r4,r1,r2);

      /* round 11  */
      KEYMIX(r3,r0,r4,r1,r2,40);
      S2(r3,r0,r4,r1,r2);
      LINTRANS(r4,r1,r0,r2,r3);

      /* round 12  */
      KEYMIX(r4,r1,r0,r2,r3,44);
      S3(r4,r1,r0,r2,r3);
      LINTRANS(r1,r0,r2,r3,r4);

      /* round 13  */
      KEYMIX(r1,r0,r2,r3,r4,48);
      S4(r1,r0,r2,r3,r4) 
      LINTRANS(r0,r4,r1,r3,r2);

      /* round 14  */
      KEYMIX(r0,r4,r1,r3,r2,52);
      S5(r0,r4,r1,r3,r2);
      LINTRANS(r4,r3,r0,r1,r2);

      /* round 15  */
      KEYMIX(r4,r3,r0,r1,r2,56);
      S6(r4,r3,r0,r1,r2) 
      LINTRANS(r4,r3,r2,r0,r1);

      /* round 16  */
      KEYMIX(r4,r3,r2,r0,r1,60);
      S7(r4,r3,r2,r0,r1);
      LINTRANS(r2,r1,r0,r4,r3);

      /* round 17  */
      KEYMIX(r2,r1,r0,r4,r3,64);
      S0(r2,r1,r0,r4,r3);
      LINTRANS(r1,r3,r0,r2,r4);

      /* round 18  */
      KEYMIX(r1,r3,r0,r2,r4,68);
      S1(r1,r3,r0,r2,r4);
      LINTRANS(r2,r3,r0,r1,r4);

      /* round 19  */
      KEYMIX(r2,r3,r0,r1,r4,72);
      S2(r2,r3,r0,r1,r4);
      LINTRANS(r0,r1,r3,r4,r2);

      /* round 20  */
      KEYMIX(r0,r1,r3,r4,r2,76);
      S3(r0,r1,r3,r4,r2);
      LINTRANS(r1,r3,r4,r2,r0);

      /* round 21  */
      KEYMIX(r1,r3,r4,r2,r0,80);
      S4(r1,r3,r4,r2,r0) 
      LINTRANS(r3,r0,r1,r2,r4);

      /* round 22  */
      KEYMIX(r3,r0,r1,r2,r4,84);
      S5(r3,r0,r1,r2,r4);
      LINTRANS(r0,r2,r3,r1,r4);

      /* round 23  */
      KEYMIX(r0,r2,r3,r1,r4,88);
      S6(r0,r2,r3,r1,r4) 
      LINTRANS(r0,r2,r4,r3,r1);

      /* round 24  */
      KEYMIX(r0,r2,r4,r3,r1,92);
      S7(r0,r2,r4,r3,r1);
      LINTRANS(r4,r1,r3,r0,r2);

      /* round 25  */
      KEYMIX(r4,r1,r3,r0,r2,96);
      S0(r4,r1,r3,r0,r2);
      LINTRANS(r1,r2,r3,r4,r0);

      /* round 26  */
      KEYMIX(r1,r2,r3,r4,r0,100);
      S1(r1,r2,r3,r4,r0);
      LINTRANS(r4,r2,r3,r1,r0);

      /* round 27  */
      KEYMIX(r4,r2,r3,r1,r0,104);
      S2(r4,r2,r3,r1,r0);
      LINTRANS(r3,r1,r2,r0,r4);

      /* round 28  */
      KEYMIX(r3,r1,r2,r0,r4,108);
      S3(r3,r1,r2,r0,r4);
      LINTRANS(r1,r2,r0,r4,r3);

      /* round 29  */
      KEYMIX(r1,r2,r0,r4,r3,112);
      S4(r1,r2,r0,r4,r3) 
      LINTRANS(r2,r3,r1,r4,r0);

      /* round 30  */
      KEYMIX(r2,r3,r1,r4,r0,116);
      S5(r2,r3,r1,r4,r0);
      LINTRANS(r3,r4,r2,r1,r0);

      /* round 31  */
      KEYMIX(r3,r4,r2,r1,r0,120);
      S6(r3,r4,r2,r1,r0) 
      LINTRANS(r3,r4,r0,r2,r1);

      /* round 32  */
      KEYMIX(r3,r4,r0,r2,r1,124);
      S7(r3,r4,r0,r2,r1);
      KEYMIX(r0,r1,r2,r3,r4,128);

      if (wrongByteOrder) {
          /* incorrect byte order */
          out_blk[3] = io_swap_be(r0);
          out_blk[2] = io_swap_be(r1); 
          out_blk[1] = io_swap_be(r2);
          out_blk[0] = io_swap_be(r3);
      } else {
          /* correct byte order */
          out_blk[0] = io_swap_le(r0);
          out_blk[1] = io_swap_le(r1); 
          out_blk[2] = io_swap_le(r2);
          out_blk[3] = io_swap_le(r3);
      }
};

/* decrypt a block of text  */

static void serpent_decrypt(u32 *l_key, const u8 *in, u8 *out, int wrongByteOrder)
{
    const u32 *in_blk = (const u32 *)in;
    u32 *out_blk = (u32 *)out;
    u32  r0,r1,r2,r3,r4;
    
      if (wrongByteOrder) {
          /* incorrect byte order */
          r0 = io_swap_be(in_blk[3]);
          r1 = io_swap_be(in_blk[2]);
          r2 = io_swap_be(in_blk[1]);
          r3 = io_swap_be(in_blk[0]);
      } else {
          /* correct byte order */
          r0 = io_swap_le(in_blk[0]);
          r1 = io_swap_le(in_blk[1]); 
          r2 = io_swap_le(in_blk[2]);
          r3 = io_swap_le(in_blk[3]);
      }

      /* round 1 */
      KEYMIX(r0,r1,r2,r3,r4,128);
      I7(r0,r1,r2,r3,r4);
      KEYMIX(r3,r0,r1,r4,r2,124);

      /* round 2  */
      ILINTRANS(r3,r0,r1,r4,r2);
      I6(r3,r0,r1,r4,r2);
      KEYMIX(r0,r1,r2,r4,r3,120);

      /* round 3  */
      ILINTRANS(r0,r1,r2,r4,r3);
      I5(r0,r1,r2,r4,r3);
      KEYMIX(r1,r3,r4,r2,r0,116);

      /* round 4  */
      ILINTRANS(r1,r3,r4,r2,r0);
      I4(r1,r3,r4,r2,r0);
      KEYMIX(r1,r2,r4,r0,r3,112);

      /* round 5  */
      ILINTRANS(r1,r2,r4,r0,r3);
      I3(r1,r2,r4,r0,r3);
      KEYMIX(r4,r2,r0,r1,r3,108);

      /* round 6  */
      ILINTRANS(r4,r2,r0,r1,r3);
      I2(r4,r2,r0,r1,r3);
      KEYMIX(r2,r3,r0,r1,r4,104);

      /* round 7  */
      ILINTRANS(r2,r3,r0,r1,r4);
      I1(r2,r3,r0,r1,r4);
      KEYMIX(r4,r2,r1,r0,r3,100);

      /* round 8  */
      ILINTRANS(r4,r2,r1,r0,r3);
      I0(r4,r2,r1,r0,r3);
      KEYMIX(r4,r3,r2,r0,r1,96);

      /* round 9  */
      ILINTRANS(r4,r3,r2,r0,r1);
      I7(r4,r3,r2,r0,r1);
      KEYMIX(r0,r4,r3,r1,r2,92);

      /* round 10  */
      ILINTRANS(r0,r4,r3,r1,r2);
      I6(r0,r4,r3,r1,r2);
      KEYMIX(r4,r3,r2,r1,r0,88);

      /* round 11  */
      ILINTRANS(r4,r3,r2,r1,r0);
      I5(r4,r3,r2,r1,r0);
      KEYMIX(r3,r0,r1,r2,r4,84);

      /* round 12  */
      ILINTRANS(r3,r0,r1,r2,r4);
      I4(r3,r0,r1,r2,r4);
      KEYMIX(r3,r2,r1,r4,r0,80);

      /* round 13  */
      ILINTRANS(r3,r2,r1,r4,r0);
      I3(r3,r2,r1,r4,r0);
      KEYMIX(r1,r2,r4,r3,r0,76);

      /* round 14  */
      ILINTRANS(r1,r2,r4,r3,r0);
      I2(r1,r2,r4,r3,r0);
      KEYMIX(r2,r0,r4,r3,r1,72);

      /* round 15  */
      ILINTRANS(r2,r0,r4,r3,r1);
      I1(r2,r0,r4,r3,r1);
      KEYMIX(r1,r2,r3,r4,r0,68);

      /* round 16  */
      ILINTRANS(r1,r2,r3,r4,r0);
      I0(r1,r2,r3,r4,r0);
      KEYMIX(r1,r0,r2,r4,r3,64);

      /* round 17  */
      ILINTRANS(r1,r0,r2,r4,r3);
      I7(r1,r0,r2,r4,r3);
      KEYMIX(r4,r1,r0,r3,r2,60);

      /* round 18  */
      ILINTRANS(r4,r1,r0,r3,r2);
      I6(r4,r1,r0,r3,r2);
      KEYMIX(r1,r0,r2,r3,r4,56);

      /* round 19  */
      ILINTRANS(r1,r0,r2,r3,r4);
      I5(r1,r0,r2,r3,r4);
      KEYMIX(r0,r4,r3,r2,r1,52);

      /* round 20  */
      ILINTRANS(r0,r4,r3,r2,r1);
      I4(r0,r4,r3,r2,r1);
      KEYMIX(r0,r2,r3,r1,r4,48);

      /* round 21  */
      ILINTRANS(r0,r2,r3,r1,r4);
      I3(r0,r2,r3,r1,r4);
      KEYMIX(r3,r2,r1,r0,r4,44);

      /* round 22  */
      ILINTRANS(r3,r2,r1,r0,r4);
      I2(r3,r2,r1,r0,r4);
      KEYMIX(r2,r4,r1,r0,r3,40);

      /* round 23  */
      ILINTRANS(r2,r4,r1,r0,r3);
      I1(r2,r4,r1,r0,r3);
      KEYMIX(r3,r2,r0,r1,r4,36);

      /* round 24  */
      ILINTRANS(r3,r2,r0,r1,r4);
      I0(r3,r2,r0,r1,r4);
      KEYMIX(r3,r4,r2,r1,r0,32);

      /* round 25  */
      ILINTRANS(r3,r4,r2,r1,r0);
      I7(r3,r4,r2,r1,r0);
      KEYMIX(r1,r3,r4,r0,r2,28);

      /* round 26  */
      ILINTRANS(r1,r3,r4,r0,r2);
      I6(r1,r3,r4,r0,r2);
      KEYMIX(r3,r4,r2,r0,r1,24);

      /* round 27  */
      ILINTRANS(r3,r4,r2,r0,r1);
      I5(r3,r4,r2,r0,r1);
      KEYMIX(r4,r1,r0,r2,r3,20);

      /* round 28  */
      ILINTRANS(r4,r1,r0,r2,r3);
      I4(r4,r1,r0,r2,r3);
      KEYMIX(r4,r2,r0,r3,r1,16);

      /* round 29  */
      ILINTRANS(r4,r2,r0,r3,r1);
      I3(r4,r2,r0,r3,r1);
      KEYMIX(r0,r2,r3,r4,r1,12);

      /* round 30  */
      ILINTRANS(r0,r2,r3,r4,r1);
      I2(r0,r2,r3,r4,r1);
      KEYMIX(r2,r1,r3,r4,r0,8);

      /* round 31  */
      ILINTRANS(r2,r1,r3,r4,r0);
      I1(r2,r1,r3,r4,r0);
      KEYMIX(r0,r2,r4,r3,r1,4);

      /* round 32  */
      ILINTRANS(r0,r2,r4,r3,r1);
      I0(r0,r2,r4,r3,r1);
      KEYMIX(r0,r1,r2,r3,r4,0);
    
      if (wrongByteOrder) {
          /* incorrect byte order */
          out_blk[3] = io_swap_be(r0);
          out_blk[2] = io_swap_be(r1);
          out_blk[1] = io_swap_be(r2);
          out_blk[0] = io_swap_be(r3);
      } else {
          /* correct byte order */
          out_blk[0] = io_swap_le(r0);
          out_blk[1] = io_swap_le(r1);
          out_blk[2] = io_swap_le(r2);
          out_blk[3] = io_swap_le(r3);
      }
};


#if LINUX_VERSION_CODE >= 0x20600
typedef sector_t TransferSector_t;
# define LoopInfo_t struct loop_info64
#else
typedef int TransferSector_t;
# define LoopInfo_t struct loop_info
#endif

#if !defined(LOOP_MULTI_KEY_SETUP)
# define LOOP_MULTI_KEY_SETUP 0x4C4D
#endif
#if !defined(LOOP_MULTI_KEY_SETUP_V3)
# define LOOP_MULTI_KEY_SETUP_V3 0x4C4E
#endif

extern void loop_compute_sector_iv(TransferSector_t, u_int32_t *);
extern void loop_compute_md5_iv_v3(TransferSector_t, u_int32_t *, u_int32_t *);

typedef struct {
    u32 k[140];
} serpent_context;

typedef struct {
    serpent_context *keyPtr[64];
    unsigned        keyMask;
    u_int32_t       partialMD5[4];
} SerpentMultiKey;

static SerpentMultiKey *allocMultiKey(void)
{
    SerpentMultiKey *m;
    serpent_context *a;
    int x, n;

    m = (SerpentMultiKey *) kmalloc(sizeof(SerpentMultiKey), GFP_KERNEL);
    if(!m) return 0;
    memset(m, 0, sizeof(SerpentMultiKey));

    n = PAGE_SIZE / sizeof(serpent_context);
    if(!n) n = 1;

    a = (serpent_context *) kmalloc(sizeof(serpent_context) * n, GFP_KERNEL);
    if(!a) {
        kfree(m);
        return 0;    
    }

    x = 0;
    while((x < 64) && n) {
        m->keyPtr[x] = a;
        a++;
        x++;
        n--;
    }
    return m;
}

static void clearAndFreeMultiKey(SerpentMultiKey *m)
{
    serpent_context *a;
    int x, n;

    n = PAGE_SIZE / sizeof(serpent_context);
    if(!n) n = 1;

    x = 0;
    while(x < 64) {
        a = m->keyPtr[x];
        if(!a) break;
        memset(a, 0, sizeof(serpent_context) * n);
        kfree(a);
        x += n;
    }

    memset(m, 0, sizeof(SerpentMultiKey));
    kfree(m);
}

static int multiKeySetup(struct loop_device *lo, unsigned char *k, int version3)
{
    SerpentMultiKey *m;
    serpent_context *a;
    int x, y, n;
    union {
        u_int32_t     w[16];
        unsigned char b[64];
    } un;
    /* lo->lo_init[0] == 0 or 1 means correct byte order serpent */
    /* lo->lo_init[0] == 2 means inverted byte order serpent */
    int wrongByteOrder = (lo->lo_init[0] == 2);
    extern void md5_transform_CPUbyteorder_C(u_int32_t *, u_int32_t const *);

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

    m = (SerpentMultiKey *)lo->key_data;
    if(!m) return -ENXIO;

    n = PAGE_SIZE / sizeof(serpent_context);
    if(!n) n = 1;

    x = 0;
    while(x < 64) {
        if(!m->keyPtr[x]) {
            a = (serpent_context *) kmalloc(sizeof(serpent_context) * n, GFP_KERNEL);
            if(!a) return -ENOMEM;
            y = x;
            while((y < (x + n)) && (y < 64)) {
                m->keyPtr[y] = a;
                a++;
                y++;
            }
        }
        if(copy_from_user(&un.b[0], k, 32)) return -EFAULT;
        serpent_set_key(&m->keyPtr[x]->k[0], &un.b[0], lo->lo_encrypt_key_size, wrongByteOrder);
        k += 32;
        x++;
    }

    m->partialMD5[0] = 0x67452301;
    m->partialMD5[1] = 0xefcdab89;
    m->partialMD5[2] = 0x98badcfe;
    m->partialMD5[3] = 0x10325476;
    if(version3) {
        /* only first 128 bits of iv-key is used */
        if(copy_from_user(&un.b[0], k, 16)) return -EFAULT;
#if defined(__BIG_ENDIAN)
        un.w[0] = cpu_to_le32(un.w[0]);
        un.w[1] = cpu_to_le32(un.w[1]);
        un.w[2] = cpu_to_le32(un.w[2]);
        un.w[3] = cpu_to_le32(un.w[3]);
#endif
        memset(&un.b[16], 0, 48);
        md5_transform_CPUbyteorder_C(&m->partialMD5[0], &un.w[0]);
        lo->lo_flags |= 0x080000;  /* multi-key-v3 (info exported to user space) */
    }

    m->keyMask = 0x3F;          /* range 0...63 */
    lo->lo_flags |= 0x100000;   /* multi-key (info exported to user space) */
    memset(&un.b[0], 0, 32);
    return 0;
}

static int transfer_serpent(struct loop_device *lo, int cmd, char *raw_buf,
          char *loop_buf, int size, TransferSector_t devSect)
{
    serpent_context     *a;
    SerpentMultiKey     *m;
    int             x;
    unsigned        y;
    u_int32_t       iv[8];
    /* lo->lo_init[0] == 0 or 1 means correct byte order serpent */
    /* lo->lo_init[0] == 2 means inverted byte order serpent */
    int wrongByteOrder = (lo->lo_init[0] == 2);

    if(!size || (size & 511)) {
        return -EINVAL;
    }
    m = (SerpentMultiKey *)lo->key_data;
    y = m->keyMask;
    if(cmd == READ) {
        while(size) {
            a = m->keyPtr[((unsigned)devSect) & y];
            if(y) {
                memcpy(&iv[0], raw_buf, 16);
                raw_buf += 16;
                loop_buf += 16;
            } else {
                loop_compute_sector_iv(devSect, &iv[0]);
            }
            x = 15;
            do {
                memcpy(&iv[4], raw_buf, 16);
                serpent_decrypt(&a->k[0], raw_buf, loop_buf, wrongByteOrder);
                *((u_int32_t *)(&loop_buf[ 0])) ^= iv[0];
                *((u_int32_t *)(&loop_buf[ 4])) ^= iv[1];
                *((u_int32_t *)(&loop_buf[ 8])) ^= iv[2];
                *((u_int32_t *)(&loop_buf[12])) ^= iv[3];
                if(y && !x) {
                    raw_buf -= 496;
                    loop_buf -= 496;
                    memcpy(&iv[4], &m->partialMD5[0], 16);
                    loop_compute_md5_iv_v3(devSect, &iv[4], (u_int32_t *)(&loop_buf[16]));
                } else {
                    raw_buf += 16;
                    loop_buf += 16;
                    memcpy(&iv[0], raw_buf, 16);
                }
                serpent_decrypt(&a->k[0], raw_buf, loop_buf, wrongByteOrder);
                *((u_int32_t *)(&loop_buf[ 0])) ^= iv[4];
                *((u_int32_t *)(&loop_buf[ 4])) ^= iv[5];
                *((u_int32_t *)(&loop_buf[ 8])) ^= iv[6];
                *((u_int32_t *)(&loop_buf[12])) ^= iv[7];
                if(y && !x) {
                    raw_buf += 512;
                    loop_buf += 512;
                } else {
                    raw_buf += 16;
                    loop_buf += 16;
                }
            } while(--x >= 0);
#if LINUX_VERSION_CODE >= 0x20600
            cond_resched();
#elif LINUX_VERSION_CODE >= 0x20400
            if(current->need_resched) {set_current_state(TASK_RUNNING);schedule();}
#else
            if(current->need_resched) {current->state=TASK_RUNNING;schedule();}
#endif
            size -= 512;
            devSect++;
        }
    } else {
        while(size) {
            a = m->keyPtr[((unsigned)devSect) & y];
            if(y) {
#if LINUX_VERSION_CODE < 0x20400
                /* on 2.2 and older kernels, real raw_buf may be doing */
                /* writes at any time, so this needs to be stack buffer */
                u_int32_t tmp_raw_buf[128];
                char *TMP_RAW_BUF = (char *)(&tmp_raw_buf[0]);
#else
                /* on 2.4 and later kernels, real raw_buf is not doing */
                /* any writes now so it can be used as temp buffer */
# define TMP_RAW_BUF raw_buf
#endif
                memcpy(TMP_RAW_BUF, loop_buf, 512);
                memcpy(&iv[0], &m->partialMD5[0], 16);
                loop_compute_md5_iv_v3(devSect, &iv[0], (u_int32_t *)(&TMP_RAW_BUF[16]));
                x = 15;
                do {
                    iv[0] ^= *((u_int32_t *)(&TMP_RAW_BUF[ 0]));
                    iv[1] ^= *((u_int32_t *)(&TMP_RAW_BUF[ 4]));
                    iv[2] ^= *((u_int32_t *)(&TMP_RAW_BUF[ 8]));
                    iv[3] ^= *((u_int32_t *)(&TMP_RAW_BUF[12]));
                    serpent_encrypt(&a->k[0], (unsigned char *)(&iv[0]), raw_buf, wrongByteOrder);
                    memcpy(&iv[0], raw_buf, 16);
                    raw_buf += 16;
#if LINUX_VERSION_CODE < 0x20400
                    TMP_RAW_BUF += 16;
#endif
                    iv[0] ^= *((u_int32_t *)(&TMP_RAW_BUF[ 0]));
                    iv[1] ^= *((u_int32_t *)(&TMP_RAW_BUF[ 4]));
                    iv[2] ^= *((u_int32_t *)(&TMP_RAW_BUF[ 8]));
                    iv[3] ^= *((u_int32_t *)(&TMP_RAW_BUF[12]));
                    serpent_encrypt(&a->k[0], (unsigned char *)(&iv[0]), raw_buf, wrongByteOrder);
                    memcpy(&iv[0], raw_buf, 16);
                    raw_buf += 16;
#if LINUX_VERSION_CODE < 0x20400
                    TMP_RAW_BUF += 16;
#endif
                } while(--x >= 0);
                loop_buf += 512;
            } else {
                loop_compute_sector_iv(devSect, &iv[0]);
                x = 15;
                do {
                    iv[0] ^= *((u_int32_t *)(&loop_buf[ 0]));
                    iv[1] ^= *((u_int32_t *)(&loop_buf[ 4]));
                    iv[2] ^= *((u_int32_t *)(&loop_buf[ 8]));
                    iv[3] ^= *((u_int32_t *)(&loop_buf[12]));
                    serpent_encrypt(&a->k[0], (unsigned char *)(&iv[0]), raw_buf, wrongByteOrder);
                    memcpy(&iv[0], raw_buf, 16);
                    loop_buf += 16;
                    raw_buf += 16;
                    iv[0] ^= *((u_int32_t *)(&loop_buf[ 0]));
                    iv[1] ^= *((u_int32_t *)(&loop_buf[ 4]));
                    iv[2] ^= *((u_int32_t *)(&loop_buf[ 8]));
                    iv[3] ^= *((u_int32_t *)(&loop_buf[12]));
                    serpent_encrypt(&a->k[0], (unsigned char *)(&iv[0]), raw_buf, wrongByteOrder);
                    memcpy(&iv[0], raw_buf, 16);
                    loop_buf += 16;
                    raw_buf += 16;
                } while(--x >= 0);
            }
#if LINUX_VERSION_CODE >= 0x20600
            cond_resched();
#elif LINUX_VERSION_CODE >= 0x20400
            if(current->need_resched) {set_current_state(TASK_RUNNING);schedule();}
#else
            if(current->need_resched) {current->state=TASK_RUNNING;schedule();}
#endif
            size -= 512;
            devSect++;
        }
    }
    return(0);
}

static int keySetup_serpent(struct loop_device *lo, LoopInfo_t *info)
{
    SerpentMultiKey     *m;
    /* lo->lo_init[0] == 0 or 1 means correct byte order serpent */
    /* lo->lo_init[0] == 2 means inverted byte order serpent */
    int wrongByteOrder = (info->lo_init[0] == 2);

    lo->key_data = m = allocMultiKey();
    if(!m) return(-ENOMEM);
    serpent_set_key(&m->keyPtr[0]->k[0], &info->lo_encrypt_key[0],
            info->lo_encrypt_key_size, wrongByteOrder);
    memset(&info->lo_encrypt_key[0], 0, sizeof(info->lo_encrypt_key));
    return(0);
}

static int keyClean_serpent(struct loop_device *lo)
{
    if(lo->key_data) {
        clearAndFreeMultiKey((SerpentMultiKey *)lo->key_data);
        lo->key_data = 0;
    }
    return(0);
}

static int handleIoctl_serpent(struct loop_device *lo, int cmd, unsigned long arg)
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

#if LINUX_VERSION_CODE < 0x20600
static void lock_serpent(struct loop_device *lo)
{
    MOD_INC_USE_COUNT;
}
static void unlock_serpent(struct loop_device *lo)
{
    MOD_DEC_USE_COUNT;
}
#endif

static struct loop_func_table funcs_serpent = {
    number:     7,     /* 7 == LO_CRYPT_SERPENT */
    transfer:   (void *) transfer_serpent,
    init:       (void *) keySetup_serpent,
    release:    keyClean_serpent,
#if LINUX_VERSION_CODE >= 0x20600
    owner:      THIS_MODULE,
#else
    lock:       lock_serpent,
    unlock:     unlock_serpent,
#endif
    ioctl:      (void *) handleIoctl_serpent
};
    
#if LINUX_VERSION_CODE >= 0x20600
# define loop_serpent_init  __init loop_serpent_initfn
# define loop_serpent_exit  loop_serpent_exitfn
#else
# define loop_serpent_init  init_module
# define loop_serpent_exit  cleanup_module
#endif

int loop_serpent_init(void)
{
    if (loop_register_transfer(&funcs_serpent)) {
        printk(KERN_WARNING "loop: unable to register serpent transfer\n");
        return -EIO;
    }
    printk(KERN_INFO "loop: registered serpent encryption\n");
    return 0;
}

void loop_serpent_exit(void)
{   
    if (loop_unregister_transfer(funcs_serpent.number)) {
        printk(KERN_WARNING "loop: unable to unregister serpent transfer\n");
        return;
    }
    printk(KERN_INFO "loop: unregistered serpent encryption\n");
}

#if LINUX_VERSION_CODE >= 0x20600
module_init(loop_serpent_initfn);
module_exit(loop_serpent_exitfn);
#endif

#if defined(MODULE_LICENSE)
MODULE_LICENSE("GPL");
#endif
