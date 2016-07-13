#include <stdio.h>

void print_buf(u8 * buf, u32 len)
{
    u32 i = 0;

    for (i = 0; i < len; i++) {
	printf("%02x ", buf[i]);
	if (i % 15 == 0) {
	    printf("\n");
	}
    }
    printf("\n");

    for (i = 0; i < len; i++) {
	printf("%c ", buf[i]);
	if (i % 15 == 0) {
	    printf("\n");
	}
    }
    printf("\n");
}
