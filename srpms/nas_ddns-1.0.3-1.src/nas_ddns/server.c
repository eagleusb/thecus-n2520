#include <stdio.h>		// printf
#include <stdlib.h>		// exit
#include <strings.h>		// bzero, strcpy
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/types.h>		// socket
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>		// pid

#include "ddns.h"
#include "wrap.h"
#include "helper.h"
#include "db.h"
#include "packet.h"
#include "common.h"
#include "md5.h"
#include "cmd.h"


void server(int sockfd);
int send_verify_email(char *email);

void sig_chld(int signo)
{
	pid_t pid;
	int stat;

	while ((pid = waitpid(-1, &stat, WNOHANG)) > 0)
	//debug("child %d terminated", pid);
	;
	return;
}

void sig_term(int signo)
{
	close_db();
	exit(1);
}

int main(int argc, char **argv)
{
	int listenfd, connfd;
	const int on = 1;
	pid_t childpid;
	socklen_t clilen;
	struct sockaddr_in cliaddr, servaddr;

	signal(SIGTERM, sig_term);
	signal(SIGKILL, sig_term);
	signal(SIGSTOP, sig_term);

	if ((listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
	err_sys("socket error");

	if (setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on)) <
	0)
	err_sys("setsockopt of SO_REUSEPORT error");

	bzero(&servaddr, sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_port = htons(PORT);
	servaddr.sin_addr.s_addr = htonl(INADDR_ANY);

	if (bind(listenfd, (struct sockaddr *) &servaddr, sizeof(servaddr)) <
	0)
	err_sys("bind error");

	if (listen(listenfd, SOMAXCONN) < 0)
	err_sys("listen error");

	Signal(SIGCHLD, sig_chld);

	for (;;) {
	clilen = sizeof(cliaddr);
	if ((connfd =
		 accept(listenfd, (struct sockaddr *) &cliaddr,
			&clilen)) < 0) {
		if (errno == EINTR)
		continue;	/* back to for() */
		else
		err_sys("accept error");
	}

	if ((childpid = Fork()) == 0) {	/* child process */
		Close(listenfd);	/* close listening socket */
		server(connfd);	/* process the request */
		exit(0);
	}
	Close(connfd);		/* parent closes connected socket */
	}
}

void handle_register(int sockfd, t_register_request * p_register_request)
{
	//printf("handle_register\n");
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	t_register_reply s_register_reply;

	//print_register_request(p_register_request);
	bzero(&s_register_reply, sizeof(t_register_reply));
	s_register_reply.ret = create_thecus_id(p_register_request);
	len = create_register_reply_packet(buf, &s_register_reply);
	Write(sockfd, buf, len);

	// send email
	if (s_register_reply.ret == 0)
		send_verify_email((char *) (p_register_request->email));
}

void handle_auth(int sockfd, t_auth_request * p_auth_request)
{
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	t_auth_reply s_auth_reply;
	struct thecus_id s_thecus_id;

	bzero(&s_auth_reply, sizeof(t_auth_reply));
	bzero(&s_thecus_id, sizeof(struct thecus_id));
	strncpy((char *)s_thecus_id.email, (char *)p_auth_request->email, LEN_EMAIL-1);
	strncpy((char *)s_thecus_id.passwd, (char *)p_auth_request->passwd, LEN_PW-1);
	strncpy((char *)s_thecus_id.fqdn, (char *)p_auth_request->fqdn, LEN_FQDN-1);
	strncpy((char *)s_thecus_id.mac, (char *)p_auth_request->mac, LEN_MAC-1);

	s_auth_reply.ret = auth_thecus_id(&s_thecus_id);
	strncpy((char *)s_auth_reply.fqdn, (char *)s_thecus_id.fqdn, LEN_FQDN-1);
	strncpy((char *)s_auth_reply.fname, (char *)s_thecus_id.fname, LEN_NAME-1);
	strncpy((char *)s_auth_reply.mname, (char *)s_thecus_id.mname, LEN_NAME-1);
	strncpy((char *)s_auth_reply.lname, (char *)s_thecus_id.lname, LEN_NAME-1);

	len = create_auth_reply_packet(buf, &s_auth_reply);
	Write(sockfd, buf, len);
}

int nsupdate(t_update_ddns_reply * p_update_ddns_reply)
{
	char buf[512];
	bzero(buf, sizeof(buf));

	//print_update_ddns_reply(p_update_ddns_reply);
	sprintf(buf, "cd /root/nsupdate/; ./nsupdate.sh %s %s",
		p_update_ddns_reply->fqdn, p_update_ddns_reply->ip);

	return system(buf);
}

void handle_update_ddns(int sockfd, t_update_ddns_request * p_update_ddns_request)
{
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	int ret;
	t_update_ddns_reply s_update_ddns_reply;
	struct thecus_id s_thecus_id;
	struct sockaddr_in addr;
	socklen_t addr_len;

	//print_update_ddns_request(p_update_ddns_request);
	bzero(&s_update_ddns_reply, sizeof(t_update_ddns_reply));
	bzero(&s_thecus_id, sizeof(struct thecus_id));
	strncpy((char *)s_thecus_id.email, (char *)p_update_ddns_request->email, LEN_EMAIL-1);
	strncpy((char *)s_thecus_id.passwd, (char *)p_update_ddns_request->passwd, LEN_PW-1);
	strncpy((char *)s_thecus_id.mac, (char *)p_update_ddns_request->mac, LEN_MAC-1);

	ret = auth(&s_thecus_id);
	if (ret == 0) {
		ret = get_fqdn(&s_thecus_id);
		if (ret == 0) {
			addr_len = sizeof(addr);
			bzero(&addr, addr_len);
			getpeername(sockfd, (struct sockaddr *) &addr, &addr_len);
			strncpy((char *) s_update_ddns_reply.ip, inet_ntoa(addr.sin_addr), LEN_IP-1);
			strncpy((char *) s_update_ddns_reply.fqdn, (char *) s_thecus_id.fqdn, LEN_FQDN-1);
			if (nsupdate(&s_update_ddns_reply) == 0)
				s_update_ddns_reply.ret = 0;
			else
				s_update_ddns_reply.ret = E_UPDATE_DDNS;
		} else
			s_update_ddns_reply.ret = ret;
	} else {
		s_update_ddns_reply.ret = ret;
	}

	len = create_update_ddns_reply_packet(buf, &s_update_ddns_reply);
	Write(sockfd, buf, len);
}

int send_verify_email(char *email)
{
	int ret = 0;
	char buf[4096];
	char name[LEN_EMAIL];
	char passwd[LEN_PW];
	char pw_md5_str[33];
	char *chr;

	ret = get_passwd(email, passwd);
	if (ret != 0)
		return ret;

	bzero(pw_md5_str, sizeof(pw_md5_str));
	get_md5_string(passwd, pw_md5_str);

	bzero(name, sizeof(name));
	strncpy(name, email, LEN_EMAIL - 1);
	chr = strchr(name, '@');
	if (chr != NULL)
	*chr = '\0';
	bzero(buf, sizeof(buf));
	snprintf(buf, 4096,
		 "echo 'From: support@thecus.com\nTo: %s\nSubject: Please activate your Thecus ID!\nHi %s, \n\nThank you for registering with Thecus ID!\n\nYour Thecus ID is %s\nTo activate your account please click the link below:\nhttp://ns1.thecuslink.com/cgi-bin/verify.cgi?email=%s&passwd=%s\n' | /usr/bin/msmtp -a gmail %s",
		 email, name, email, email, pw_md5_str, email);
	//printf("%s\n", buf);
	return system(buf);
}

void handle_send_verify_email(int sockfd, t_send_verify_email_request *p_send_verify_email_request)
{
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	int ret;
	t_send_verify_email_reply s_send_verify_email_reply;

	bzero(&s_send_verify_email_reply, sizeof(t_send_verify_email_reply));

	ret = thecus_id_exist((char *) (p_send_verify_email_request->email));

	if (ret != E_ID_EXIST) {
		s_send_verify_email_reply.ret = ret;
	} else {
		//printf("send verify email:%s\n", p_send_verify_email_request->email);
		ret = send_verify_email((char *) (p_send_verify_email_request->email));

	if (ret != 0)
		s_send_verify_email_reply.ret = E_SEND_VERIFY_EMAIL;
	else
		s_send_verify_email_reply.ret = 0;
	}

	len = create_send_verify_email_reply_packet(buf, &s_send_verify_email_reply);
	Write(sockfd, buf, len);
}

void handle_reset_passwd(int sockfd,
			 t_reset_passwd_request * p_reset_passwd_request)
{
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	t_reset_passwd_reply s_reset_passwd_reply;

	//print_reset_passwd_request(p_reset_passwd_request);

	bzero(&s_reset_passwd_reply, sizeof(t_reset_passwd_reply));

	s_reset_passwd_reply.ret =
	reset_passwd((char *) (p_reset_passwd_request->email));

	len = create_reset_passwd_reply_packet(buf, &s_reset_passwd_reply);
	Write(sockfd, buf, len);
}

void handle_modify_passwd(int sockfd, t_modify_passwd_request *p_modify_passwd_request)
{
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	int ret;
	t_modify_passwd_reply s_modify_passwd_reply;
	struct thecus_id s_thecus_id;

	//print_modify_passwd_request(p_modify_passwd_request);
	bzero(&s_modify_passwd_reply, sizeof(t_modify_passwd_reply));
	bzero(&s_thecus_id, sizeof(struct thecus_id));
	strncpy((char *)s_thecus_id.email, (char *)p_modify_passwd_request->email, LEN_EMAIL-1);
	strncpy((char *)s_thecus_id.passwd, (char *)p_modify_passwd_request->passwd, LEN_PW-1);

	s_modify_passwd_reply.ret = 1;

	ret = auth(&s_thecus_id);
	if (ret == 0) {
		s_modify_passwd_reply.ret = modify_passwd((char *) (p_modify_passwd_request->email), (char *) (p_modify_passwd_request->new_passwd));
	} else {
		s_modify_passwd_reply.ret = ret;
	}

	len = create_modify_passwd_reply_packet(buf, &s_modify_passwd_reply);
	Write(sockfd, buf, len);
}

void handle_verify(int sockfd, t_verify_request * p_verify_request)
{
	u8 buf[MAX_PACKET_LEN];
	u32 len;
	t_verify_reply s_verify_reply;

	bzero(&s_verify_reply, sizeof(t_verify_reply));
	s_verify_reply.ret = verify_thecus_id((char *)(p_verify_request->email), (char *)(p_verify_request->passwd));
	len = create_verify_reply_packet(buf, &s_verify_reply);
	Write(sockfd, buf, len);
}

void handle_shell(int sockfd, char *cmd)
{
	//printf("handle_shell\n");
	char buf[MAX_PACKET_LEN];
	pid_t pid;
	char ret_path[64], out_path[64], err_path[64];

	pid = getpid();
	//printf("pid=%d\n", pid);
	bzero(buf, sizeof(buf));
	sprintf(buf, "/var/www/ddns.sh %d %s >/dev/shm/%d.tmp 2>&1", pid, cmd, pid);
	system(buf);

	bzero(ret_path, sizeof(ret_path));
	sprintf(ret_path, "/dev/shm/%d.ret", pid);
	//file_to_sock(sockfd, ret_path);

	bzero(out_path, sizeof(out_path));
	sprintf(out_path, "/dev/shm/%d.out", pid);
	file_to_sock(sockfd, out_path);

	bzero(err_path, sizeof(err_path));
	sprintf(err_path, "/dev/shm/%d.err", pid);
	//file_to_sock(sockfd, err_path);
}

void server(int sockfd)
{
	ssize_t n;
	u8 buf[512];		// Now support max 512B packet
	struct cmd_packet s_cmd_packet;

	while (1) {
		bzero(buf, sizeof(buf));
		n = read(sockfd, buf, sizeof(buf));
		if (n == -1)
			err_sys("read error");
		else if (n == 0)
			exit(0);		// client close
		else if (n == 1)
			continue;		// receive data not complete

		if (n <= LEN_CHECKSUM) {
			exit(1);		// receive data not correct
		}

		bzero(&s_cmd_packet, sizeof(t_cmd_packet));
		if (get_packet(buf, n, &s_cmd_packet) != 0) {
			exit(1);
		}

		//printf("%d\n", s_cmd_packet.cmd_id);
		switch (s_cmd_packet.cmd_id) {
		case CMD_REGISTER:
			handle_register(sockfd, (t_register_request *)s_cmd_packet.packet);
			break;
		case CMD_AUTH:
			handle_auth(sockfd, (t_auth_request *)s_cmd_packet.packet);
			break;
		case CMD_UPDATE_DDNS:
			handle_update_ddns(sockfd, (t_update_ddns_request *)s_cmd_packet.packet);
			break;
		case CMD_SEND_VERIFY_EMAIL:
			handle_send_verify_email(sockfd, (t_send_verify_email_request *)s_cmd_packet.packet);
			break;
		case CMD_RESET_PASSWD:
			handle_reset_passwd(sockfd, (t_reset_passwd_request *)s_cmd_packet.packet);
			break;
		case CMD_MODIFY_PASSWD:
			handle_modify_passwd(sockfd, (t_modify_passwd_request *)s_cmd_packet.packet);
			break;
		case CMD_VERIFY:
			handle_verify(sockfd, (t_verify_request *) s_cmd_packet.packet);
			break;
		case CMD_SHELL:
			handle_shell(sockfd, (char *) s_cmd_packet.packet);
			break;
		default:
			err_sys("cmd id error");
			break;
		}

		close(sockfd);
		exit(0);
	}
}
