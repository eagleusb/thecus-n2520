/**
 * @file	clean_garbage.c
 * @brief	Clean garbage account in thecus_ddns.db
 * @author	Michelle Zhang <michelle_zhang@thecus.com>
 * @data	2012/11/7 created
 **/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mysql/mysql.h>
#include <time.h>
#include <sys/sem.h>
#include "sem.h"
#include "common.h"
#include "db.h"
#include "ddns.h"

static int clean_garbage_account(void)
{
    int ret = 0, sid;
    char sql[256];
    time_t t, deadline;
    MYSQL *db = NULL;

    db = (MYSQL *)malloc(sizeof(MYSQL));
    mysql_init(db);

    if (!mysql_real_connect(db, "localhost", ROOT, PASSWORD, DBNAME, 0, SOCK_FILE, 0)) {
	ret = E_DB_OPEN;
	SAFE_FREE(db);
	return ret;
    }

    sid = sem_init();
    if (sid == -1) {
	perror("sem_init");
	ret = E_SEMAPHORE;
	goto error_handler;
    }

    time(&t);
    deadline = t - 86400;
    bzero(sql, sizeof(sql));
    sprintf(sql, "delete from %s where verify='no' AND time<%ld",
	    TABLE_ACCOUNT, deadline);
    /* P operate */
    if (sem_request(sid) == -1) {
	perror("P operate fail");
	ret = E_SEMAPHORE;
	goto error_handler;
    }

    if (mysql_query(db, sql) != 0) {
	ret = E_DB_EXEC;
    }

    /* V operate */
    if (sem_release(sid) == -1) {
	perror("V operate fail");
	ret = E_SEMAPHORE;
	goto error_handler;
    }

  error_handler:
    mysql_close(db);
//    sem_delete(sid);
    SAFE_FREE(db);
    return ret;
}

int main(void)
{
    int ret = 0;
    struct error_message emess;

    ret = clean_garbage_account();

    if (ret == 0) {
	printf("Clean garbage account OK.\n");
    } else {
	bzero(&emess, sizeof(struct error_message));
	emess.err_code = ret;
	if (nas_parse_err_msg(&emess) != 0) {
	    sprintf(emess.err_msg, "Unknown error.");
	}

	printf("Clean garbage account failed: %s\n", emess.err_msg);
    }

    return ret;
}
