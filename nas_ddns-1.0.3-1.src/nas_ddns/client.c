#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include "packet.h"
#include "wrap.h"
#include "cmd.h"
#include "common.h"
int main(int argc, char *argv[])
{
	int sockfd;
	int cmd_id;
	int len = 0;
	int maxfd;
	int ret;
	fd_set fdsr;
	struct timeval tv;
	struct sockaddr_in serv_addr;
	struct hostent *server;
	t_cmd_packet s_cmd_packet;

	u8 buf[MAX_PACKET_LEN];

	if (argc < 2) {
		return E_PARA;
	}

	bzero(buf, sizeof(buf));

	// check cmd id and argc
	cmd_id = atoi(argv[1]);
	switch (cmd_id) {
		case CMD_REGISTER:
			if (argc != 7)
				return E_ARGC;

			t_register_request s_register_request;
			bzero(&s_register_request, sizeof(t_register_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_register_request.email, argv[2], len);

			len = strlen(argv[3]);
			if (len >= LEN_PW)
				return E_LEN_PW;
			memcpy(s_register_request.passwd, argv[3], len);

			len = strlen(argv[4]);
			if (len >= LEN_NAME)
				return E_LEN_NAME;
			memcpy(s_register_request.fname, argv[4], len);

			len = strlen(argv[5]);
			if (len >= LEN_NAME)
				return E_LEN_NAME;
			memcpy(s_register_request.mname, argv[5], len);

			len = strlen(argv[6]);
			if (len >= LEN_NAME)
				return E_LEN_NAME;
			memcpy(s_register_request.lname, argv[6], len);
/*
			len = strlen(argv[7]);
			if (len >= LEN_FQDN)
				return E_LEN_FQDN;
			memcpy(s_register_request.fqdn, argv[7], len);
*/
			len = create_register_request_packet(buf, &s_register_request);
			break;

		case CMD_AUTH:
			if (argc != 6)
				return E_ARGC;

			t_auth_request s_auth_request;
			bzero(&s_auth_request, sizeof(t_auth_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_auth_request.email, argv[2], len);

			len = strlen(argv[3]);
			if (len >= LEN_PW)
				return E_LEN_PW;
			memcpy(s_auth_request.passwd, argv[3], len);

			len = strlen(argv[4]);
			if (len >= LEN_MAC)
				return E_LEN_MAC;
			memcpy(s_auth_request.mac, argv[4], len);

			len = strlen(argv[5]);
			if (len >= LEN_FQDN)
				return E_LEN_FQDN;
			memcpy(s_auth_request.fqdn, argv[5], len);

			len = create_auth_request_packet(buf, &s_auth_request);
			break;

		case CMD_UPDATE_DDNS:
			if (argc != 5)
				return E_ARGC;

			t_update_ddns_request s_update_ddns_request;
			bzero(&s_update_ddns_request, sizeof(t_update_ddns_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_update_ddns_request.email, argv[2], len);

			len = strlen(argv[3]);
			if (len >= LEN_PW)
				return E_LEN_PW;
			memcpy(s_update_ddns_request.passwd, argv[3], len);

			len = strlen(argv[4]);
			if (len >= LEN_MAC)
				return E_LEN_MAC;
			memcpy(s_update_ddns_request.mac, argv[4], len);

			len = create_update_ddns_request_packet(buf, &s_update_ddns_request);
			break;

		case CMD_SEND_VERIFY_EMAIL:
			if (argc != 3)
				return E_ARGC;

			t_send_verify_email_request s_send_verify_email_request;
			bzero(&s_send_verify_email_request, sizeof(t_send_verify_email_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_send_verify_email_request.email, argv[2], len);

			len = create_send_verify_email_request_packet(buf, &s_send_verify_email_request);
			break;

		case CMD_RESET_PASSWD:
			if (argc != 3)
				return E_ARGC;

			t_reset_passwd_request s_reset_passwd_request;
			bzero(&s_reset_passwd_request, sizeof(t_reset_passwd_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_reset_passwd_request.email, argv[2], len);

			len = create_reset_passwd_request_packet(buf, &s_reset_passwd_request);
			break;

		case CMD_MODIFY_PASSWD:
			if (argc != 5)
				return E_ARGC;

			t_modify_passwd_request s_modify_passwd_request;
			bzero(&s_modify_passwd_request, sizeof(t_modify_passwd_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_modify_passwd_request.email, argv[2], len);

			len = strlen(argv[3]);
			if (len >= LEN_PW)
				return E_LEN_PW;
			memcpy(s_modify_passwd_request.passwd, argv[3], len);

			len = strlen(argv[4]);
			if (len >= LEN_PW)
				return E_LEN_PW;
			memcpy(s_modify_passwd_request.new_passwd, argv[4], len);

			len = create_modify_passwd_request_packet(buf, &s_modify_passwd_request);
			break;

		case CMD_VERIFY:
			if (argc != 4)
				return E_ARGC;

			t_verify_request s_verify_request;
			bzero(&s_verify_request, sizeof(t_verify_request));

			len = strlen(argv[2]);
			if (len >= LEN_EMAIL)
				return E_LEN_EMAIL;
			memcpy(s_verify_request.email, argv[2], len);

			len = strlen(argv[3]);
			if (len >= LEN_PW)
				return E_LEN_PW;
			memcpy(s_verify_request.passwd, argv[3], len);

			len = create_verify_request_packet(buf, &s_verify_request);
			break;

		case CMD_SHELL:
			if (argc != 3)
				return E_ARGC;

			len = strlen(argv[2]);
			if (len >= MAX_PACKET_LEN - 128)
				return E_LEN_SHELL;
			
			len = create_shell_request_packet(buf, argv[2]);
			break;

		default:
			return E_CMD;
	}

	/* Create a socket point */
	sockfd = socket(AF_INET, SOCK_STREAM, 0);
	if (sockfd < 0) {
		err_sys("create socket error");
	}

	server = gethostbyname(HOSTNAME);
	if (server == NULL) {
		return E_HOST_DNS;
	}

	bzero((char *) &serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	bcopy((char *) server->h_addr, (char *) &serv_addr.sin_addr.s_addr, server->h_length);
	serv_addr.sin_port = htons(PORT);

	/* Now connect to the server */
	if (connect(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) {
		return E_CONN_TIMEOUT;
		//err_sys("connect socket error");
	}

	/* Send message to the server */
	Write(sockfd, buf, len);

	maxfd = sockfd;
	FD_ZERO(&fdsr);
	FD_SET(maxfd, &fdsr);

	tv.tv_sec = 60;
	tv.tv_usec = 0;

	ret = select(maxfd + 1, &fdsr, NULL, NULL, &tv);
	if (ret < 0) {
		err_sys("select error");
	} else if (ret == 0) {
		err_sys("timeout");
	}

	// just for CMD_SHELL
	if (cmd_id == CMD_SHELL) {
		unlink("/dev/shm/ddns_ret");
		unlink("/dev/shm/ddns_out");
		unlink("/dev/shm/ddns_err");
		//sock_to_file(sockfd, "/dev/shm/ddns_ret");
		sock_to_file(sockfd, "/dev/shm/ddns_out");
		//sock_to_file(sockfd, "/dev/shm/ddns_err");
		return 0;	// always return 0, detail see /dev/shm/$$.{ret,out,err}
	}

	/* Now read server response */
	bzero(buf, sizeof(buf));
	len = 0;
	len = Read(sockfd, buf, MAX_PACKET_LEN - 1);
	if (len <= 0)
		exit(-1);

	get_packet(buf, len, &s_cmd_packet);

	switch (s_cmd_packet.cmd_id) {
		case CMD_REGISTER_REPLY:
			//print_register_reply((t_register_reply *)s_cmd_packet.packet);
			return Endian32(((t_register_reply *) s_cmd_packet.packet)->ret);

		case CMD_AUTH_REPLY:
		{
			t_auth_reply *p_auth_reply = (t_auth_reply *) s_cmd_packet.packet;
			printf("FQDN\t%s\nFirstName\t%s\nMiddleName\t%s\nLastName\t%s\n", p_auth_reply->fqdn, p_auth_reply->fname, p_auth_reply->mname, p_auth_reply->lname);
			return Endian32(((t_auth_reply *) s_cmd_packet.packet)->ret);
		}
		case CMD_UPDATE_DDNS_REPLY:
			//print_update_ddns_reply((t_update_ddns_reply *)s_cmd_packet.packet);
			return Endian32(((t_update_ddns_reply *) s_cmd_packet.packet)->ret);

		case CMD_SEND_VERIFY_EMAIL_REPLY:
			return Endian32(((t_send_verify_email_reply *) s_cmd_packet.packet)->ret);

		case CMD_RESET_PASSWD_REPLY:
			//print_reset_passwd_reply((t_reset_passwd_reply *) s_cmd_packet.packet);
			return Endian32(((t_reset_passwd_reply *) s_cmd_packet.packet)->ret);

		case CMD_MODIFY_PASSWD_REPLY:
			//print_modify_passwd_reply((t_modify_passwd_reply *)s_cmd_packet.packet);
			return Endian32(((t_modify_passwd_reply *) s_cmd_packet.packet)->ret);

		case CMD_VERIFY_REPLY:
			return Endian32(((t_verify_reply *) s_cmd_packet.packet)->ret);
	}
	return 0;
}
