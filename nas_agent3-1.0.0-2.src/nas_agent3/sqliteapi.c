/*
 * File:   main.c
 * Author: dorianko
 *
 * Created on 2009年10月7日, 下午 5:30
 */

#include <stdio.h>
#include <sqlite3.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include "utility.h"

#ifdef STANDALONE
#define CONF_DB	"./conf.db"
#else
#define CONF_DB	"/app/cfg/conf.db"
#endif

//#define sqlite_errmsg(i)                sqlite_error_string(i)

static int callback(void *value, int argc, char **argv, char **azColName)
{
    azColName = 0;
    int32_t i;

    for(i=0; i<argc; i++)
    {
        sprintf((char *)value,"%s ",argv[i] ? argv[i]: "NULL");
    }
    printf("%s\n", (int8_t *)value);
    return 0;
}

int32_t conf_db_delete(int8_t *key,int8_t *tab)
{
    char sqlcmd[256];
    sqlite3 *db;
    char *zErrMsg = 0;
    int32_t rc;

    rc = sqlite3_open(CONF_DB, &db);
    if( rc )
    {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        goto err;
    }

    sprintf(sqlcmd,"delete from %s  where k='%s'",tab,key);
    rc = sqlite3_exec(db, sqlcmd, NULL,NULL , &zErrMsg);
    if( rc!=SQLITE_OK )
    {
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        /* This will free zErrMsg if assigned */
        if (zErrMsg)
            free(zErrMsg);
        sqlite3_close(db);
        goto err;
    }

    sqlite3_close(db);
    return 0;

    err:
    return -1;
}

int32_t conf_db_insert(int8_t *key, int8_t *tab, int8_t *value)
{
    int8_t sqlcmd[256];
    sqlite3 *db;
    char *zErrMsg = 0;
    int8_t rc;

    rc = sqlite3_open(CONF_DB, &db);
    if( rc )
    {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        goto err;
    }

    sprintf(sqlcmd,"insert into %s (k,v) values ('%s','%s')",tab,key,value);
    printf("sqlcmd : %s\n",sqlcmd);

    rc = sqlite3_exec(db, sqlcmd, NULL,NULL, &zErrMsg);

    if( rc!=SQLITE_OK )
    {
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        /* This will free zErrMsg if assigned */
        if (zErrMsg)
            free(zErrMsg);
        sqlite3_close(db);
        goto err;
    }

    sqlite3_close(db);
    return 0;

    err:
    return -1;
}

int32_t conf_db_select(int8_t *key, int8_t *tab, char *value)
{
    char sqlcmd[256];
    sqlite3 *db;
    char *zErrMsg = 0;
    int8_t *pt;
    int32_t rc;

    rc = sqlite3_open(CONF_DB, &db);
    if( rc )
    {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        goto err;
    }
    sprintf(sqlcmd,"select v from %s where k='%s'",tab,key);
    rc = sqlite3_exec(db, sqlcmd, callback, value , &zErrMsg);

    if( rc!=SQLITE_OK )
    {
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        /* This will free zErrMsg if assigned */
        if (zErrMsg)
            free(zErrMsg);
        sqlite3_close(db);
        goto err;
    }
    sqlite3_close(db);
    str_trim(value, strlen(value));
    return 0;

    err:
    return -1;
}

int32_t general_db_select(int8_t *in_db, int8_t *key, int8_t *tab, char *value)
{
    char sqlcmd[256];
    sqlite3 *db;
    char *zErrMsg = 0;
    int8_t *pt;
    int32_t rc;

    rc = sqlite3_open(CONF_DB, &db);
    if( rc )
    {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        goto err;
    }
    sprintf(sqlcmd,"select v from %s where k='%s'",tab,key);
    rc = sqlite3_exec(db, sqlcmd, callback, value , &zErrMsg);

    if( rc!=SQLITE_OK )
    {
        fprintf(stderr, "SQL error: %s\n", zErrMsg);
        /* This will free zErrMsg if assigned */
        if (zErrMsg)
            free(zErrMsg);
        sqlite3_close(db);
        goto err;
    }
    sqlite3_close(db);
    str_trim(value, strlen(value));
    return 0;

    err:
    return -1;
}

int32_t conf_db_update(int8_t *key, int8_t *tab, int8_t *value)
{
    int8_t sqlcmd[256];
    sqlite3 *db;
    char *zErrMsg = 0;
    int32_t rc;

//    IN(DEBUG_MODEL_SQL, "key %s, tab %s, value %s\n", key, tab, value);
    rc = sqlite3_open(CONF_DB, &db);
    if( rc )
    {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        return -1;
    }
    sprintf(sqlcmd,"update '%s' set v='%s' where k='%s'",tab, value, key);
    debug_print(DEBUG_MODEL_SQL, "%s\n", sqlcmd);
    rc = sqlite3_exec(db, sqlcmd, NULL,NULL, &zErrMsg);

    if( rc!=SQLITE_OK )
    {
        fprintf(stderr, "SQL error: %s\n", zErrMsg);

        if (zErrMsg)
            free(zErrMsg);
    }
    sqlite3_close(db);
    return EXIT_SUCCESS;
}

#ifdef STANDALONE
int main(int argc, char** argv)
{
    char value[32+1]={0};
    int err;

    if(argc < 3)
    {
        printf("too few argement %d\n", argc);
        return -1;
    }

    if(0 == strcmp(argv[1],"get"))
    {
        err = db_select(argv[3],argv[2],value);

        if( err < 0 || strlen(value) == 0 )
        {
            printf("db_select failed\n");
            return -1;
        }
        else
            printf("value %s\n", value);
    }
    else if(0 == strcmp(argv[1],"set"))
    {
        err = db_update(argv[3],argv[2],argv[4]);

        if( err < 0)
        {
            printf("db_update failed\n");
            return -1;
        }
    }

    return (EXIT_SUCCESS);
}
#endif /*   STANDALONE    */
