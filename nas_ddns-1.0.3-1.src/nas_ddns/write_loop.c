#include <mysql/mysql.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/sem.h>
#include "sem.h"
#include "common.h"
#include "db.h"
#include "ddns.h"

int main(int argc, char *argv[])
{
    char sql[512];
    int ret = 0, i = 0, times = 0;
    int sid;
    MYSQL *db = NULL;

    if (argc != 2) {
	printf("Usage: write_loop <loop_times>\n");
	return -1;
    }

    times = atoi(argv[1]);
    if (times < 0 || times > 20000) {
	printf("The loop times must between 0 to 20000\n");
	return -1;
    }

    db = (MYSQL *)malloc(sizeof(MYSQL));
    mysql_init(db);

    if (!mysql_real_connect(db, "localhost", ROOT, PASSWORD, DBNAME, 0, SOCK_FILE, 0)) {
	printf("error: open database failed.\n");
	SAFE_FREE(db);
	return E_DB_OPEN;
    }

    sid = sem_init();
    if (sid == -1) {
	perror("sem_init");
	ret = E_SEMAPHORE;
	goto error_handler;
    }

    for (i = 0; i < times; i++) {
	printf("-----times:%d-----\n", i);
	bzero(sql, sizeof(sql));
	sprintf(sql,
		"update account set passwd='%d' where email='michelle_zhang@thecus.com'",
		i);
	/* P operate */
	if (sem_request(sid) == -1) {
	    perror("P operate fail");
	    ret = E_SEMAPHORE;
	    goto error_handler;
	}
	ret = mysql_query(db, sql);
	if (ret != 0) {
	    printf("error: %s.\n", mysql_error(db));
	    //ret = E_DB_EXEC;
	}
	/* V operate */
	if (sem_release(sid) == -1) {
	    perror("V operate fail");
	    ret = E_SEMAPHORE;
	    goto error_handler;
	}
	usleep(100);
    }

  error_handler:
    mysql_close(db);
//    sem_delete(sid);
    SAFE_FREE(db);
    return ret;
}
