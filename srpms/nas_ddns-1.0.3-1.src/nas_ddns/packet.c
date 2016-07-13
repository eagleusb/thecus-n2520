#include <strings.h>
#include <string.h>
#include <stdio.h>
#include <openssl/rc4.h>

#include "packet.h"
#include "md5.h"
#include "common.h"
/*
 *	Calculate checksum
 */
void checksum(u8 * buf, u32 len, u8 * md5sum)
{
	md5_context ctx;

	md5_starts(&ctx);
	md5_update(&ctx, buf, len);
	md5_finish(&ctx, md5sum);
}

/*
 *	Data encryption and decryption 
 */
const u8 key_data[] = "asdfghjkl;";

void enc_buf(u8 * buf, u32 len)
{
	u32 i = 0;
	u8 tmp[MAX_PACKET_LEN];
	bzero(tmp, sizeof(tmp));
	memcpy(tmp, buf, len);

	RC4_KEY key;
	RC4_set_key(&key, sizeof(key_data), key_data);
	RC4(&key, len, buf, tmp);

	for (i = 0; i < len; i++) {
		tmp[i] += 0x33;
	}

	memcpy(buf, tmp, len);
}

void dec_buf(u8 * buf, u32 len)
{
	u32 i = 0;
	u8 tmp[MAX_PACKET_LEN];
	bzero(tmp, sizeof(tmp));
	memcpy(tmp, buf, len);

	for (i = 0; i < len; i++) {
		buf[i] -= 0x33;
	}

	RC4_KEY key;
	RC4_set_key(&key, sizeof(key_data), key_data);
	RC4(&key, len, buf, tmp);

	memcpy(buf, tmp, len);
}

void print_register_request(t_register_request * p_register_request)
{
	printf("register_request:\n");
	//printf("MAC Address: %s\n", p_register_request->mac);
	printf("Email Address: %s\n", p_register_request->email);
	printf("Password: %s\n", p_register_request->passwd);
	//printf("Serial Number: %s\n", p_register_request->sn);
	//printf("Model Name: %s\n", p_register_request->model);
}

void print_register_reply(t_register_reply * p_register_reply)
{
	printf("register_reply:\n");
	printf("ret: %d\n", p_register_reply->ret);
}

void print_update_ddns_request(t_update_ddns_request *
				   p_update_ddns_request)
{
	printf("update_ddns_request:\n");
	printf("Email Address: %s\n", p_update_ddns_request->email);
	printf("Password: %s\n", p_update_ddns_request->passwd);
	//printf("FQDN: %s\n", p_update_ddns_request->fqdn);
}

void print_update_ddns_reply(t_update_ddns_reply * p_update_ddns_reply)
{
	printf("update_ddns_reply:\n");
	printf("result: %d\n", p_update_ddns_reply->ret);
	printf("FQDN: %s\n", p_update_ddns_reply->fqdn);
	printf("IP Address: %s\n", p_update_ddns_reply->ip);
}

void print_reset_passwd_request(t_reset_passwd_request *
				p_reset_passwd_request)
{
	printf("reset_passwd_request:\n");
	printf("Email Address: %s\n", p_reset_passwd_request->email);
}

void print_reset_passwd_reply(t_reset_passwd_reply * p_reset_passwd_reply)
{
	printf("reset_passwd_reply:\n");
	printf("result: %d\n", p_reset_passwd_reply->ret);
}

void print_modify_passwd_request(t_modify_passwd_request *
				 p_modify_passwd_request)
{
	printf("modify_passwd_request:\n");
	printf("Email Address: %s\n", p_modify_passwd_request->email);
	printf("Password: %s\n", p_modify_passwd_request->passwd);
	printf("New Password: %s\n", p_modify_passwd_request->new_passwd);
}

void print_modify_passwd_reply(t_modify_passwd_reply *
				   p_modify_passwd_reply)
{
	printf("modify_passwd_reply:\n");
	printf("result: %d\n", p_modify_passwd_reply->ret);
}

/*
 *	Create send packet, stone it in buf. return packet length.
 *	The buf will send on network
 */
u32 create_packet(u8 * buf, t_cmd_packet * p_cmd_packet)
{
	u32 cmd_id = p_cmd_packet->cmd_id;
	u32 len = p_cmd_packet->len;
	u8 md5sum[16];
	u8 *buf2 = buf;

	p_cmd_packet->len = Endian32(p_cmd_packet->len);
	cmd_id = Endian32(cmd_id);
	memcpy(buf2, &cmd_id, sizeof(u32));
	buf2 += sizeof(u32);

	memcpy(buf2, &(p_cmd_packet->len), sizeof(u32));
	buf2 += sizeof(u32);

	memcpy(buf2, p_cmd_packet->packet, len);
	checksum(buf2, len, md5sum);
	buf2 += len;

	memcpy(buf2, md5sum, sizeof(md5sum));
	buf2 += sizeof(md5sum);

	len = buf2 - buf;
	enc_buf(buf, len);

	return len;
}


/*
 *	Get cmd_packet form buf.
 *	@buf: reveive from network.
 *	@length: length of buf
 */
u32 get_packet(u8 * buf, u32 length, t_cmd_packet * p_cmd_packet)
{
	u32 cmd_id;
	u32 len;
	u8 *buf2 = buf;
	u8 md5sum[16];

	dec_buf(buf, length);

	cmd_id = ((t_cmd_packet *) buf)->cmd_id;
	cmd_id = Endian32(cmd_id);
	len = ((t_cmd_packet *) buf)->len;
	len = Endian32(len);
	if (length != len + 2 * sizeof(u32) + LEN_CHECKSUM) {
		return -1;
	}

	buf2 += 2 * sizeof(u32);
	checksum(buf2, len, md5sum);

	if (memcmp(buf2 + len, md5sum, LEN_CHECKSUM) != 0) {
		return -2;		// checksum error
	}

	p_cmd_packet->cmd_id = cmd_id;
	p_cmd_packet->len = len;
	p_cmd_packet->packet = buf2;
	buf2[len] = 0;
	
	return 0;
}


u32 create_register_request_packet(u8 * buf,
				   t_register_request * p_register_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_REGISTER;
	s_cmd_packet.len = sizeof(t_register_request);
	s_cmd_packet.packet = (u8 *) p_register_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_register_reply_packet(u8 * buf,
				 t_register_reply * p_register_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_REGISTER_REPLY;
	s_cmd_packet.len = sizeof(t_register_reply);
	s_cmd_packet.packet = (u8 *) p_register_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}


u32 create_auth_request_packet(u8 * buf, t_auth_request * p_auth_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_AUTH;
	s_cmd_packet.len = sizeof(t_auth_request);
	s_cmd_packet.packet = (u8 *) p_auth_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_auth_reply_packet(u8 * buf, t_auth_reply * p_auth_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_AUTH_REPLY;
	s_cmd_packet.len = sizeof(t_auth_reply);
	s_cmd_packet.packet = (u8 *) p_auth_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}


u32 create_update_ddns_request_packet(u8 * buf,
					  t_update_ddns_request *
					  p_update_ddns_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_UPDATE_DDNS;
	s_cmd_packet.len = sizeof(t_update_ddns_request);
	s_cmd_packet.packet = (u8 *) p_update_ddns_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_update_ddns_reply_packet(u8 * buf,
					t_update_ddns_reply *
					p_update_ddns_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_UPDATE_DDNS_REPLY;
	s_cmd_packet.len = sizeof(t_update_ddns_reply);
	s_cmd_packet.packet = (u8 *) p_update_ddns_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_send_verify_email_request_packet(u8 * buf,
						t_send_verify_email_request *
						p_send_verify_email_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_SEND_VERIFY_EMAIL;
	s_cmd_packet.len = sizeof(t_send_verify_email_request);
	s_cmd_packet.packet = (u8 *) p_send_verify_email_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;

}

u32 create_send_verify_email_reply_packet(u8 * buf,
					  t_send_verify_email_reply *
					  p_send_verify_email_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_SEND_VERIFY_EMAIL_REPLY;
	s_cmd_packet.len = sizeof(t_send_verify_email_reply);
	s_cmd_packet.packet = (u8 *) p_send_verify_email_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_reset_passwd_request_packet(u8 * buf,
					   t_reset_passwd_request *
					   p_reset_passwd_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_RESET_PASSWD;
	s_cmd_packet.len = sizeof(t_reset_passwd_request);
	s_cmd_packet.packet = (u8 *) p_reset_passwd_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;

}

u32 create_reset_passwd_reply_packet(u8 * buf,
					 t_reset_passwd_reply *
					 p_reset_passwd_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_RESET_PASSWD_REPLY;
	s_cmd_packet.len = sizeof(t_reset_passwd_reply);
	s_cmd_packet.packet = (u8 *) p_reset_passwd_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_modify_passwd_request_packet(u8 * buf,
					t_modify_passwd_request *
					p_modify_passwd_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_MODIFY_PASSWD;
	s_cmd_packet.len = sizeof(t_modify_passwd_request);
	s_cmd_packet.packet = (u8 *) p_modify_passwd_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;

}

u32 create_modify_passwd_reply_packet(u8 * buf,
					  t_modify_passwd_reply *
					  p_modify_passwd_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_MODIFY_PASSWD_REPLY;
	s_cmd_packet.len = sizeof(t_modify_passwd_reply);
	s_cmd_packet.packet = (u8 *) p_modify_passwd_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_verify_request_packet(u8 * buf, t_verify_request * p_verify_request)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_VERIFY;
	s_cmd_packet.len = sizeof(t_verify_request);
	s_cmd_packet.packet = (u8 *) p_verify_request;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_verify_reply_packet(u8 * buf, t_verify_reply * p_verify_reply)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_VERIFY_REPLY;
	s_cmd_packet.len = sizeof(t_verify_reply);
	s_cmd_packet.packet = (u8 *) p_verify_reply;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_shell_request_packet(u8 *buf, char *cmd)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_SHELL;
	s_cmd_packet.len = strlen(cmd);
	s_cmd_packet.packet = (u8 *)cmd;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}

u32 create_shell_reply_packet(u8 * buf, char *cmd)
{
	u32 len;
	t_cmd_packet s_cmd_packet;

	bzero(&s_cmd_packet, sizeof(t_cmd_packet));
	s_cmd_packet.cmd_id = CMD_SHELL_REPLY;
	s_cmd_packet.len = strlen(cmd);
	s_cmd_packet.packet = (u8 *)cmd;

	len = create_packet(buf, &s_cmd_packet);
	return len;
}
