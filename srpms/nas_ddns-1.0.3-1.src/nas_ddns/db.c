#include <mysql/mysql.h>
#include <stdio.h>
#include <strings.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <sys/sem.h>
#include "db.h"
#include "sem.h"
#include "common.h"

static MYSQL *db = NULL;

// call by server.c
int open_db()
{
	if (db)
		return 0;

	db = (MYSQL *)malloc(sizeof(MYSQL));
	mysql_init(db);

	if (!mysql_real_connect(db, "localhost", ROOT, PASSWORD, DBNAME, 0, SOCK_FILE, 0)) {
		return E_DB_OPEN;
	}

	return 0;
}

int close_db()
{
	if (db) {
		mysql_close(db);
		SAFE_FREE(db);
		db = NULL;
	}

	return 0;
}

static int check_exist(char *sql)
{
	int ret = -1;
	int sid;
	MYSQL_RES *result;

	if (open_db() != 0)
		return E_DB_OPEN;

	sid = sem_init();
	if (sid == -1) {
		perror("sem_init");
		return E_SEMAPHORE;
	}
	/* P operate */
	if (sem_request(sid) == -1) {
		perror("P operate fail");
		return E_SEMAPHORE;
	}

	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	} else {
		result = mysql_store_result(db);
		if (result == NULL) {
			ret = E_DB_EXEC;
		} else {
			if(mysql_fetch_row(result)) {
				ret = 0;
			}
			mysql_free_result(result);
		}
	}

	/* V operate */
	if (sem_release(sid) == -1) {
		perror("V operate fail");
		ret = E_SEMAPHORE;
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

/*
 *	Return:
 *		0:	exist
 *		-1: not exist
 */
int thecus_id_exist(char *id)
{
	char sql[512];
	int ret;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select email from %s where email='%s'", TABLE_ACCOUNT, id);

	ret = check_exist(sql);
	if (ret == 0)
		ret = E_ID_EXIST;
	else if (ret == -1)
		ret = E_ID_NOT_EXIST;

	return ret;
}

int fqdn_exist(char *fqdn, char *email)
{
	char sql[512];
	int ret;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select email from %s where fqdn='%s' and email!='%s'", TABLE_FQDN, fqdn, email);
	
	ret = check_exist(sql);
	if (ret == 0)
		ret = E_FQDN_EXIST;
	else if (ret == -1)
		ret = E_FQDN_NOT_EXIST;

	return ret;
}


int auth(struct thecus_id *p_thecus_id)
{
	char sql[512];
	int ret;
	MYSQL_RES *result;
	MYSQL_ROW rows;

	if (open_db() != 0)
		return E_DB_OPEN;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select verify from %s where email='%s' and passwd='%s'", TABLE_ACCOUNT, p_thecus_id->email, p_thecus_id->passwd);

	ret = E_AUTH;
	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	} else {
		result = mysql_store_result(db);
		if (result == NULL) {
			ret = E_DB_EXEC;
		} else {
			rows = mysql_fetch_row(result);
			if (rows) {
				if (strcmp(rows[0], "yes") != 0) {
					ret = E_NOT_VERIFY;
				} else {
                    ret = 0;
				}
			}
		}
		mysql_free_result(result);
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

int get_fqdn(struct thecus_id *p_thecus_id)
{
	char sql[512];
	int ret;
	MYSQL_RES *result;
	MYSQL_ROW rows;

	if (open_db() != 0)
		return E_DB_OPEN;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select fqdn from %s where email='%s' and mac='%s'", TABLE_FQDN, p_thecus_id->email, p_thecus_id->mac);

	ret = E_FQDN_NOT_EXIST;
	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	} else {
		result = mysql_store_result(db);
		if (result == NULL) {
			ret = E_DB_EXEC;
		} else {
			rows = mysql_fetch_row(result);
			if (rows) {
				if (strlen(rows[0]) != 0) {
					strncpy((char *)p_thecus_id->fqdn, rows[0], LEN_FQDN-1);
					ret = 0;
				}
			}
		}
		mysql_free_result(result);
	}
	
	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

int get_passwd(char *email, char *passwd)
{
	char sql[512];
	int ret;
	MYSQL_RES *result;
	MYSQL_ROW rows;

	if (open_db() != 0)
		return E_DB_OPEN;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select passwd from %s where email='%s'", TABLE_ACCOUNT, email);

	ret = E_ID_NOT_EXIST;
	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	} else {
		result = mysql_store_result(db);
		if (result == NULL) {
			ret = E_DB_EXEC;
		} else {
			rows = mysql_fetch_row(result);
			if (rows) {
				if (strlen(rows[0]) != 0) {
					strncpy(passwd, rows[0], LEN_PW-1);
					ret = 0;
				}
			}
		}
		mysql_free_result(result);
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

/*
 * Auth Thecus ID
 */
int auth_thecus_id(struct thecus_id *p_thecus_id)
{
	char sql[512];
	int ret;
	int sid;
	MYSQL_RES *result;
	MYSQL_RES *result2;
	MYSQL_ROW rows;

	if (open_db() != 0)
		return E_DB_OPEN;

	bzero(sql, sizeof(sql));
	//sprintf(sql, "select t1.verify, t2.fqdn, t1.fname, t1.mname, t1.lname from %s as t1,%s as t2 where t1.email='%s' and t1.passwd='%s' and t1.email=t2.email", TABLE_ACCOUNT, TABLE_FQDN, p_thecus_id->email, p_thecus_id->passwd);
	sprintf(sql, "select verify, time, fname, mname, lname from %s where email='%s' and passwd='%s'", TABLE_ACCOUNT, p_thecus_id->email, p_thecus_id->passwd);

	ret = E_AUTH;

	sid = sem_init();
	if (sid == -1) {
		perror("sem_init");
		return E_SEMAPHORE;
	}
	/* P operate */
	if (sem_request(sid) == -1) {
		perror("P operate fail");
		return E_SEMAPHORE;
	}
   
	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	} else {
		result = mysql_store_result(db);
		if (result == NULL) {
			ret = E_DB_EXEC;
		} else {
			rows = mysql_fetch_row(result);
			if(rows) {
				if (strcmp(rows[0], "yes") != 0) { 
					ret = E_NOT_VERIFY;
				} else {
					ret = 0;
					//strncpy((char *)p_thecus_id->fqdn, rows[1], LEN_FQDN-1);
					strncpy((char *)p_thecus_id->fname, rows[2], LEN_NAME-1);
					strncpy((char *)p_thecus_id->mname, rows[3], LEN_NAME-1);
					strncpy((char *)p_thecus_id->lname, rows[4], LEN_NAME-1);
				}
			}
			mysql_free_result(result);
		}
	}

	if (ret == 0) {	// Auth success
		bzero(sql, sizeof(sql));
    	sprintf(sql, "select email, mac from %s where fqdn='%s'", TABLE_FQDN, p_thecus_id->fqdn);
		if (mysql_query(db, sql) != 0) {
			ret = E_DB_EXEC;
		} else {
			result = mysql_store_result(db);
			if (result == NULL) {
				ret = E_DB_EXEC;
			} else {
				rows = mysql_fetch_row(result);
				if(rows) {
					if (strcmp(rows[0], (char *)p_thecus_id->email) != 0) {
						ret = E_FQDN_EXIST;
					} else if (strcmp(rows[1], (char *)p_thecus_id->mac) != 0) {
						ret = E_FQDN_EXIST;
					} else {
						ret = 0;
					}
				} else {
					bzero(sql, sizeof(sql));
					sprintf(sql, "select fqdn from %s where email='%s' and mac='%s'", TABLE_FQDN, p_thecus_id->email, p_thecus_id->mac);
					if (mysql_query(db, sql) != 0) {
						ret = E_DB_EXEC;
					} else {
						result2 = mysql_store_result(db);
						if (result == NULL) {
							ret = E_DB_EXEC;
						} else {
							if ( mysql_fetch_row(result2) ) {
								bzero(sql, sizeof(sql));
								sprintf(sql, "UPDATE %s set fqdn='%s' where email='%s' and mac='%s'", TABLE_FQDN, p_thecus_id->fqdn, p_thecus_id->email, p_thecus_id->mac);
								if (mysql_query(db, sql) != 0) {
									ret = E_DB_EXEC;
								}
							} else {							
								bzero(sql, sizeof(sql));
								sprintf(sql, "INSERT INTO %s VALUES('%s', '%s', '%s')", TABLE_FQDN, p_thecus_id->email, p_thecus_id->mac, p_thecus_id->fqdn);
								if (mysql_query(db, sql) != 0) {
									ret = E_DB_EXEC;
								}
							}
						}
						mysql_free_result(result2);
					}
				}
			}
			mysql_free_result(result);
		}
	}

	/* V operate */
	if (sem_release(sid) == -1) {
		perror("V operate fail");
		ret = E_SEMAPHORE;
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

/*
int access_table_callback(void* data, int count, char** pvalue, char** pname)
{
	int i=0;

	for (i=0; i<count; i++) {
		printf("%s:%s\n", pname[i], pvalue[i]);
	}

	sprintf(data, "%s", pvalue[0]);
	return 0;
}

int access_table(sqlite3* db, char *name)
{
	int		ret;
	char	buf[256];
	char	data[256];
	//	char	*errmsg;

	bzero(buf, sizeof(buf));
	sprintf(buf, "select name from sqlite_master where type='table' and name='%s'", name);
	printf("buf=%s\n", buf);

	bzero(data, sizeof(data));
	ret = sqlite3_exec(db, buf, access_table_callback, data, NULL);
	if (ret != SQLITE_OK) {
		printf("error");
		return -1;
	}

	//	printf("data:%s\n", data);
	//	printf("name:%s\n", name);
	//	printf("data len:%d\n", sizeof(data));
	//	printf("name len:%d\n", sizeof(name));
	if (memcmp(data, name, sizeof(name)) != 0 ) {
		printf("not exist\n");
	} else {
		printf("exist\n");
	}

	return 0;
}
*/

int create_thecus_id(t_register_request * p_register_request)
{
	char sql[512];
	char sql2[512];
	time_t t = 0;
	int ret;
	int sid;

	bzero(sql, sizeof(sql));
	bzero(sql2, sizeof(sql2));
	time(&t);

	sprintf(sql, "INSERT INTO %s VALUES('%s', '%s', '%s', '%ld', '%s', '%s', '%s')",
		TABLE_ACCOUNT, p_register_request->email,
		p_register_request->passwd, "no", t,
		p_register_request->fname,
		p_register_request->mname,
		p_register_request->lname);

	ret = thecus_id_exist((char *) (p_register_request->email));
	if (ret != E_ID_NOT_EXIST)
		return ret;

    if (open_db() != 0)
        return E_DB_OPEN;

	ret = 0;

	sid = sem_init();
	if (sid == -1) {
		perror("sem_init");
		return E_SEMAPHORE;
	}

	/* P operate */
	if (sem_request(sid) == -1) {
		perror("P operate fail");
		return E_SEMAPHORE;
	}

	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	}

	/* V operate */
	if (sem_release(sid) == -1) {
		perror("V operate fail");
		ret = E_SEMAPHORE;
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

/*
int auth_db(t_auth_request *p_auth_request)
{
	char		sql[512];
	int			ret;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select * from '%s' where email='%s' and passwd='%s'", TABLE_ACCOUNT, p_auth_request->email, p_auth_request->passwd);

	ret = check_exist(sql);
	if (ret != 0)
		ret = E_AUTH;

	return ret;
}

int have_registered(t_update_ddns_request *p_update_ddns_request)
{
	char		sql[512];
	int			ret;

	bzero(sql, sizeof(sql));
	sprintf(sql, "select * from '%s' where email='%s' and passwd='%s'", TABLE_ACCOUNT, p_update_ddns_request->email, p_update_ddns_request->passwd);

	ret = check_exist(sql);
	if (ret != 0)
		ret = E_AUTH;

	return ret;
}
*/

int reset_passwd(char *id)
{
	char sql[512], buf[4096], name[LEN_EMAIL], *chr;
	int ret;
	int sid;

	ret = thecus_id_exist(id);
	if (ret == E_ID_NOT_EXIST)
		return ret;

    if (open_db() != 0)
        return E_DB_OPEN;

	ret = 0;

	sid = sem_init();
	if (sid == -1) {
		perror("sem_init");
		return E_SEMAPHORE;
	}

	bzero(sql, sizeof(sql));
	sprintf(sql, "update %s set passwd='%s' where email='%s'",
		TABLE_ACCOUNT, DEFAULT_PASSWD, id);
	/* P operate */
	if (sem_request(sid) == -1) {
		perror("P operate fail");
		return E_SEMAPHORE;
	}

	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	}

	/* V operate */
	if (sem_release(sid) == -1) {
		perror("V operate fail");
		ret = E_SEMAPHORE;
	}

	if (ret == 0) {
		bzero(name, sizeof(name));
		strncpy(name, id, LEN_EMAIL - 1);
		chr = strchr(name, '@');
		if (chr != NULL)
			*chr = '\0';
		bzero(buf, sizeof(buf));
		snprintf(buf, 4096,
			 "/usr/sbin/sendmail -t <<EOF\nFrom: drip_shui@thecus.com\nTo: %s\nSubject: Your Thecus ID password has been reset\nHi %s, \n\nThe password for your Thecus ID %s has been successfully reset to %s\nPlease modify your password immediately after you login in the system successfully.\nEOF",
			 id, name, id, DEFAULT_PASSWD);
		printf("%s\n", buf);
		ret = system(buf);
		if (ret != 0)
			ret = E_SEND_RESET_EMAIL;
		}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

int modify_passwd(char *id, char *new_passwd)
{
	char sql[512];
	int ret;
	int sid;

	bzero(sql, sizeof(sql));

	ret = thecus_id_exist(id);
	if (ret == E_ID_NOT_EXIST)
		return ret;

    if (open_db() != 0)
		return E_DB_OPEN;

	ret = 0;

	sid = sem_init();
	if (sid == -1) {
		perror("sem_init");
		return E_SEMAPHORE;
	}

	sprintf(sql, "update %s set passwd='%s' where email='%s'",
		TABLE_ACCOUNT, new_passwd, id);
	/* P operate */
	if (sem_request(sid) == -1) {
		perror("P operate fail");
		return E_SEMAPHORE;
	}

	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	}

	/* V operate */
	if (sem_release(sid) == -1) {
		perror("V operate fail");
		ret = E_SEMAPHORE;
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

/*
 * Verify Thecus ID -- for debug
 * Input:
 *	id now is email
 *	passwd is password
 * Output:
 *	0:	success
 */
int verify_thecus_id(char *id, char *passwd)
{
	int ret = 0, sid, id_exist = 0, verify = 0;
	char sql[256], data[128];
	MYSQL_RES *result;
	MYSQL_ROW rows;

    if (open_db() != 0)
		return E_DB_OPEN;

	/* sem_init */
	sid = sem_init();
	if (sid == -1) {
		return E_SEMAPHORE;
	}

	bzero(sql, sizeof(sql));
	bzero(data, sizeof(data));
	sprintf(sql, "select email from %s where email='%s'", TABLE_ACCOUNT,
		id);

	/* P operate */
	if (sem_request(sid) == -1) {
		return E_SEMAPHORE;
	}

	if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	} else {
		result = mysql_store_result(db);
		if (result == NULL) {
			ret = E_DB_EXEC;
		} else {
			if(mysql_fetch_row(result)) {
				id_exist = 1;
			} else {
				ret = E_NO_ACCOUNT;
			}
			mysql_free_result(result);
		}
	} 

	/* V operate */
	if (sem_release(sid) == -1) {
		return E_SEMAPHORE;
	}

	if (id_exist == 1) {
		bzero(sql, sizeof(sql));
		bzero(data, sizeof(data));
		sprintf(sql, "select passwd from %s where email='%s'",
			TABLE_ACCOUNT, id);
		/* P operate */
		if (sem_request(sid) == -1) {
			return E_SEMAPHORE;
		}
		if (mysql_query(db, sql) != 0) {
			ret = E_DB_EXEC;
		} else {
			result = mysql_store_result(db);
			if (result == NULL) {
				ret = E_DB_EXEC;
			} else {
				rows = mysql_fetch_row(result);
				if(rows) {
					if (strcmp(rows[0], passwd) == 0) {
						verify = 1;
					} else {
						ret = E_PASSWD_INCORRECT;
					}
				} else {
					ret = E_PASSWD_INCORRECT;
				}
				mysql_free_result(result);
			}
		}

		/* V operate */
		if (sem_release(sid) == -1) {
			return E_SEMAPHORE;
		}
		if (verify == 1) {	/* The email is verified OK */
			bzero(sql, sizeof(sql));
			sprintf(sql, "update %s set verify='yes' where email='%s'",
				TABLE_ACCOUNT, id);
			/* P operate */
			if (sem_request(sid) == -1) {
				return E_SEMAPHORE;
			}

			if (mysql_query(db, sql) != 0) {
				ret = E_DB_EXEC;
			}

			/* V operate */
			if (sem_release(sid) == -1) {
				return E_SEMAPHORE;
			}
		}
	}

	//if (ret == E_DB_EXEC)
		close_db();

	return ret;
}

//#define TEST
#ifdef	TEST
int main(void)
{
/*
	t_register_request s_register_request;
	bzero(&s_register_request, sizeof(t_register_request));

	memcpy(s_register_request.mac, "11:22:33:44:55:66", sizeof("11:22:33:44:55:66"));
	memcpy(s_register_request.model, "N2520", sizeof("N2520"));
	update_register_db(&s_register_request);
*/

	t_update_ddns_request s_update_ddns_request;
	bzero(&s_update_ddns_request, sizeof(t_update_ddns_request));

	memcpy(s_update_ddns_request.mac, "11:22:33:44:55:6",
	   sizeof("11:22:33:44:55:6"));
	memcpy(s_update_ddns_request.passwd, "123456", sizeof("123456"));

	have_registered(&s_update_ddns_request);
}
#endif
