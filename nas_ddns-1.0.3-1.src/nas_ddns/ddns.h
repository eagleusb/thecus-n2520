#ifndef _DDNS_H
#define _DDNS_H  1

typedef char s8;
typedef unsigned char u8;

typedef short s16;
typedef unsigned short u16;

typedef int s32;
typedef unsigned int u32;


#define HOSTNAME    "ns1.thecuslink.com"
#define PORT        62520
#define ROOT	    "root"
#define PASSWORD    "123456"
#define DBNAME	    "ddns"

#define E_PARA          0x01	// parameter error, unnormal
#define E_CMD           0x02
#define E_ARGC          0x03
#define E_LEN_EMAIL     0x04
#define E_LEN_PW        0x05
#define E_LEN_NAME		0x07
#define E_LEN_FQDN		0x08
#define E_LEN_MAC	0x09
#define E_LEN_SHELL		0x0A

#define E_CONN_TIMEOUT  0x11
#define E_HOST_DNS	0x12

#define E_DB_OPEN	0x21
#define E_DB_CLOSE      0x22
#define E_DB_EXEC       0x23

#define E_ID_EXIST      0x31
#define E_AUTH          0x32	// auth fail
#define E_NOT_VERIFY    0x33
#define E_UPDATE_DDNS   0x34
#define E_ID_NOT_EXIST  0x35
#define E_SEND_VERIFY_EMAIL     0x36
#define E_SEND_RESET_EMAIL     0x37
#define E_FQDN_EXIST	0x38
#define E_FQDN_NOT_EXIST	0x39

#define E_GET_MAC       0x41

#define	E_EMAIL_EMPTY		0x51
#define	E_PASSWD_EMPTY		0x52
#define E_NO_ACCOUNT		0x53
#define E_PASSWD_INCORRECT	0x54

#define	E_SEMAPHORE		0x61

#endif				// #ifndef _DDNS_H
