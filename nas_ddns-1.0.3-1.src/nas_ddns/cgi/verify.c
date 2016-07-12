/**
 * @file	verify.c
 * @brief	Verify email and password in thecus_ddns.db
 * @author	Michelle Zhang <michelle_zhang@thecus.com>
 * @data	2012/11/5 created
 **/
#include <stdio.h>
#include <string.h>
#include <mysql/mysql.h>
#include <sys/sem.h>
#include "lib.h"
#include "../sem.h"
#include "../common.h"
#include "../db.h"
#include "../ddns.h"
#include "../md5.h"

static int nas_verify_email(char *email, char *password)
{
    int ret = 0, sid, email_exist = 0, verify = 0;
    char sql[256], data[128];
    MYSQL *db = NULL;
    MYSQL_RES *result;
    MYSQL_ROW rows;
	char pw_md5_str[33];

    if (email == NULL || strlen(email) < 1) {
	ret = E_EMAIL_EMPTY;
	return ret;
    }

    if (password == NULL || strlen(password) < 1) {
	ret = E_PASSWD_EMPTY;
	return ret;
    }

    db = (MYSQL *)malloc(sizeof(MYSQL));
    mysql_init(db);

    if (!mysql_real_connect(db, "localhost", ROOT, PASSWORD, DBNAME, 0, SOCK_FILE, 0)) {
	ret = E_DB_OPEN;
	SAFE_FREE(db);
	return ret;
    }

    /* sem_init */
    sid = sem_init();
    if (sid == -1) {
	ret = E_SEMAPHORE;
	goto error_handler;
    }

    bzero(sql, sizeof(sql));
    bzero(data, sizeof(data));
    sprintf(sql, "select email from %s where email='%s'", TABLE_ACCOUNT,
	    email);
    /* P operate */
    if (sem_request(sid) == -1) {
	ret = E_SEMAPHORE;
	goto error_handler;
    }

    if (mysql_query(db, sql) != 0) {
	ret = E_DB_EXEC;
    } else {
	result = mysql_store_result(db);
	if (result == NULL) {
	    ret = E_DB_EXEC;
	} else {
	    if(mysql_fetch_row(result)) {
		email_exist = 1;
	    } else {
		ret = E_NO_ACCOUNT;
	    }
	    mysql_free_result(result);
	}
    } 

    /* V operate */
    if (sem_release(sid) == -1) {
	ret = E_SEMAPHORE;
	goto error_handler;
    }
    if (email_exist == 1) {
	bzero(sql, sizeof(sql));
	bzero(data, sizeof(data));
	sprintf(sql, "select passwd from %s where email='%s'",
		TABLE_ACCOUNT, email);
	/* P operate */
	if (sem_request(sid) == -1) {
	    ret = E_SEMAPHORE;
	    goto error_handler;
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
			bzero(pw_md5_str, sizeof(pw_md5_str));
			get_md5_string(rows[0], pw_md5_str);

		    if (strcmp(pw_md5_str, password) == 0) {
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
	    ret = E_SEMAPHORE;
	    goto error_handler;
	}
	if (verify == 1) {	/* The email is verified OK */
	    bzero(sql, sizeof(sql));
	    sprintf(sql, "update %s set verify='yes' where email='%s'",
		    TABLE_ACCOUNT, email);
	    /* P operate */
	    if (sem_request(sid) == -1) {
		ret = E_SEMAPHORE;
		goto error_handler;
	    }

	    if (mysql_query(db, sql) != 0) {
		ret = E_DB_EXEC;
	    }

	    /* V operate */
	    if (sem_release(sid) == -1) {
		ret = E_SEMAPHORE;
		goto error_handler;
	    }
	}
    }

  error_handler:
    mysql_close(db);
    SAFE_FREE(db);
    return ret;
}

int main(void)
{
    char *DataStr = NULL;
    int ValSecData, ret = 0;
    char *email, *passwd;
    struct error_message emess;

    GUIFreeQryData(Value);
    //DataStr = GUIGetPostString(DataStr);
    DataStr = GUIGetQueryString(DataStr);
    ValSecData = GUIValSecNo(DataStr, '&');
    Value = (QryData *) malloc(ValSecData * sizeof(QryData));
    GUIChopQryData(DataStr, ValSecData);
    SAFE_FREE(DataStr);

    email = GUIGetValue("email", 1);
    passwd = GUIGetValue("passwd", 1);

    cgiHeaderContentType("text/html");
    HTML("<html>\n");
    HTML("<body>\n");
    HTML("<center>\n");
    ret = nas_verify_email(email, passwd);
    if (ret != 0) {
	bzero(&emess, sizeof(struct error_message));
	emess.err_code = ret;
	nas_parse_err_msg(&emess);
	HTML("<h1>Verify error: %s</h1>\n",
	     emess.err_msg[0] != 0 ? emess.err_msg : "Unknown error.");
    } else {
	HTML("<h1>Verify successfully!</h1>\n");
    }
    HTML("</body>\n");
    HTML("</html>\n");

    return 0;
}
