#ifndef	_DB_H_
#define	_DB_H_

#include "packet.h"

#define	DBPATH		"/var/lib/mysql"
#define	SOCK_FILE	DBPATH"/mysql.sock"

#define TABLE_ACCOUNT   "account"
#define TABLE_FQDN		"fqdn"
#define	DEFAULT_PASSWD	"123456"

struct thecus_id {
	u8 email[LEN_EMAIL];	// Email Address
	u8 passwd[LEN_PW];		// Password
	u8 fname[LEN_NAME];		// First Name
	u8 mname[LEN_NAME];		// Middle Name
	u8 lname[LEN_NAME];		// Last Name
	u8 mac[LEN_MAC];		// MAC address
	u8 fqdn[LEN_FQDN];		// FQDN
};

int open_db();
int close_db();
int create_thecus_id(t_register_request * p_register_request);
int auth_thecus_id(struct thecus_id * p_thecus_id);
int thecus_id_exist(char *id);
//int auth_db(t_auth_request *p_auth_request);
//int have_registered(t_update_ddns_request *p_update_ddns_request);
int reset_passwd(char *id);
int modify_passwd(char *id, char *new_passwd);
int verify_thecus_id(char *id, char *passwd);

int auth(struct thecus_id *p_thecus_id);
int get_fqdn(struct thecus_id *p_thecus_id);
int get_passwd(char *email, char *passwd);
#endif				// _DB_H
