#ifndef _COMMON_H
#define _COMMON_H

#include <stdlib.h>

void debug(const char *msg, ...);

/**
 ** Free memory, check for NULL.
 **/
#ifndef SAFE_FREE
#define SAFE_FREE(x) do { if ((x) != NULL) {free((x)); (x)=NULL;} } while(0)
#endif

struct error_message {
    int err_code;
    char err_msg[512];
};

int nas_parse_err_msg(struct error_message *emess);


#ifdef BIGENDIAN
	#define Endian64(A)  ((((__uint64_t)(A) & 0xff00000000000000) >> 56)  | \
                      (((__uint64_t)(A) & 0x00ff000000000000) >> 40)  | \
                      (((__uint64_t)(A) & 0x0000ff0000000000) >> 24)  | \
                      (((__uint64_t)(A) & 0x000000ff00000000) >> 8)   | \
		      (((__uint64_t)(A) & 0x00000000ff000000) << 8)   | \
                      (((__uint64_t)(A) & 0x0000000000ff0000) << 24)  | \
                      (((__uint64_t)(A) & 0x000000000000ff00) << 40)  | \
                      (((__uint64_t)(A) & 0x00000000000000ff) << 56))

	#define Endian32(A)  ((((__uint32_t)(A) & 0xff000000) >> 24) | \
                      (((__uint32_t)(A) & 0x00ff0000) >> 8)  | \
                      (((__uint32_t)(A) & 0x0000ff00) << 8)  | \
                      (((__uint32_t)(A) & 0x000000ff) << 24))

	#define Endian16(A)  ((((__uint16_t)(A) & 0xff00) >> 8) | \
                      (((__uint16_t)(A) & 0x00ff) << 8))
#else
	#define Endian64(A) A
	#define Endian32(A) A
	#define Endian16(A) A
#endif //BIG_ENDIAN

#endif				/* _COMMON_H */
