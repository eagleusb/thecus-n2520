#ifndef _PACKET_H_
#define	_PACKET_H_

#include "ddns.h"

#define MAX_PACKET_LEN				4096

#define CMD_REGISTER				0x1
#define CMD_REGISTER_REPLY			0x81
#define CMD_AUTH					0x2
#define CMD_AUTH_REPLY				0x82
#define CMD_UPDATE_DDNS				0x3
#define CMD_UPDATE_DDNS_REPLY		0x83
#define CMD_SEND_VERIFY_EMAIL		0x4
#define CMD_SEND_VERIFY_EMAIL_REPLY 0x84
#define	CMD_RESET_PASSWD			0x5
#define	CMD_RESET_PASSWD_REPLY		0x85
#define CMD_MODIFY_PASSWD			0x6
#define	CMD_MODIFY_PASSWD_REPLY		0x86
#define CMD_VERIFY					0x7
#define CMD_VERIFY_REPLY			0x87
#define CMD_SHELL					0x08
#define CMD_SHELL_REPLY				0x88

#define LEN_MAC			20
#define LEN_EMAIL		64
#define LEN_PW			64
#define LEN_SN			32
#define LEN_MODEL		16
#define LEN_IP			16
#define LEN_CHECKSUM	16
#define LEN_NAME		64
#define LEN_FQDN		128

typedef struct cmd_packet {
	u32 cmd_id;
	u32 len;
	u8 *packet;
} t_cmd_packet;

typedef struct register_request {
	u8 email[LEN_EMAIL];	// Email Address
	u8 passwd[LEN_PW];		// Password
	//u8 sn[LEN_SN];		// Serial Number
	//u8 model[LEN_MODEL];	// NAS Model Name
	u8 fname[LEN_NAME];		// First Name
	u8 mname[LEN_NAME];		// Middle Name
	u8 lname[LEN_NAME];		// Last Name
	//u8 mac[LEN_MAC];		// MAC address
	//u8 fqdn[LEN_FQDN];		// FQDN
} t_register_request;

typedef struct register_reply {
	u8 ret;			// 0: success, 1: fail
} t_register_reply;

typedef struct auth_request {
	u8 email[LEN_EMAIL];	// Email Address
	u8 passwd[LEN_PW];		// Password
	u8 mac[LEN_MAC];		// MAC address
	u8 fqdn[LEN_FQDN];		// FQDN
} t_auth_request;

typedef struct auth_reply {
	u32 ret;			// 0: success, 1: fail
	u8 fname[LEN_NAME];
	u8 mname[LEN_NAME];
	u8 lname[LEN_NAME];
	u8 fqdn[LEN_FQDN];
} t_auth_reply;

typedef struct update_ddns_request {
	u8 email[LEN_EMAIL];
	u8 passwd[LEN_PW];
	//u8 fqdn[LEN_FQDN];
	u8 mac[LEN_MAC];
} t_update_ddns_request;

typedef struct update_ddns_reply {
	u8 ret;			// 0: success, 1: fail
	u8 fqdn[LEN_FQDN];
	u8 ip[LEN_IP];
} t_update_ddns_reply;

typedef struct send_verify_email_request {
	u8 email[LEN_EMAIL];
} t_send_verify_email_request;

typedef struct send_verify_email_reply {
	u8 ret;
} t_send_verify_email_reply;

typedef struct reset_passwd_request {
	u8 email[LEN_EMAIL];
} t_reset_passwd_request;

typedef struct reset_passwd_reply {
	u8 ret;			// 0: success, 1: fail
} t_reset_passwd_reply;

typedef struct modify_passwd_request {
	u8 email[LEN_EMAIL];
	u8 passwd[LEN_PW];
	u8 new_passwd[LEN_PW];
} t_modify_passwd_request;

typedef struct modify_passwd_reply {
	u8 ret;			// 0: success, 1: fail
} t_modify_passwd_reply;

typedef struct verify_request {
	u8 email[LEN_EMAIL];	// Email Address
	u8 passwd[LEN_PW];		// Password
} t_verify_request;

typedef struct verify_reply {
	u8 ret;			// 0: success, 1: fail
} t_verify_reply;

void checksum(u8 * buf, u32 len, u8 * md5sum);
void enc_buf(u8 * buf, u32 len);
void dec_buf(u8 * buf, u32 len);

void print_register_request(t_register_request * p_register_request);
void print_register_reply(t_register_reply * p_register_reply);
void print_update_ddns_request(t_update_ddns_request * p_update_ddns_request);
void print_update_ddns_reply(t_update_ddns_reply * p_update_ddns_reply);
void print_reset_passwd_request(t_reset_passwd_request * p_reset_passwd_request);
void print_reset_passwd_reply(t_reset_passwd_reply * p_reset_passwd_reply);
void print_modify_passwd_request(t_modify_passwd_request * p_modify_passwd_request);
void print_modify_passwd_reply(t_modify_passwd_reply * p_modify_passwd_reply);

u32 create_packet(u8 * buf, t_cmd_packet * p_cmd_packet);
u32 get_packet(u8 * buf, u32 length, t_cmd_packet * p_cmd_packet);

u32 create_register_request_packet(u8 * buf, t_register_request * p_register_request);
u32 create_register_reply_packet(u8 * buf, t_register_reply * p_register_reply);

u32 create_auth_request_packet(u8 * buf, t_auth_request * p_auth_request);
u32 create_auth_reply_packet(u8 * buf, t_auth_reply * p_auth_reply);

u32 create_update_ddns_request_packet(u8 * buf, t_update_ddns_request * p_update_ddns_request);
u32 create_update_ddns_reply_packet(u8 * buf, t_update_ddns_reply * p_update_ddns_reply);

u32 create_send_verify_email_request_packet(u8 * buf, t_send_verify_email_request * p_send_verify_email_request);
u32 create_send_verify_email_reply_packet(u8 * buf, t_send_verify_email_reply * p_send_verify_email_reply);

u32 create_reset_passwd_request_packet(u8 * buf, t_reset_passwd_request * p_reset_passwd_request);
u32 create_reset_passwd_reply_packet(u8 * buf, t_reset_passwd_reply * p_reset_passwd_reply);

u32 create_modify_passwd_request_packet(u8 * buf, t_modify_passwd_request * p_modify_passwd_request);
u32 create_modify_passwd_reply_packet(u8 * buf, t_modify_passwd_reply * p_modify_passwd_reply);

u32 create_verify_request_packet(u8 * buf, t_verify_request * p_verify_request);
u32 create_verify_reply_packet(u8 * buf, t_verify_reply * p_verify_reply);

u32 create_shell_request_packet(u8 *buf, char *cmd);
u32 create_shell_reply_packet(u8 *buf, char *cmd);

#endif		// _PACKET_H_
