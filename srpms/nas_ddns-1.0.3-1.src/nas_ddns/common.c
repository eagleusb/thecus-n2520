#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include "common.h"
#include "db.h"

/* debug */
void debug(const char *msg, ...)
{
    FILE *fp = fopen("/tmp/debug", "a+");

    va_list ap;

    va_start(ap, msg);
    vfprintf(fp, msg, ap);
    va_end(ap);
    fprintf(fp, "\n");

    fclose(fp);
}

struct error_message em[] = {
    {E_DB_OPEN, "Unable to open database file."},
    {E_DB_EXEC, "Execute SQL command failed."},
    {E_EMAIL_EMPTY, "The email is empty."},
    {E_PASSWD_EMPTY, "The password is empty."},
    {E_NO_ACCOUNT, "The account doesn't exist."},
    {E_PASSWD_INCORRECT, "The password is incorrect."},
    {E_SEMAPHORE, "Semaphore error."}
};

int nas_parse_err_msg(struct error_message *emess)
{
    int i;
    int ret = -1;
    unsigned long total;

    total = sizeof(em) / sizeof(struct error_message);
    for (i = 0; i < total; i++) {
	if (em[i].err_code == emess->err_code) {
	    strcpy(emess->err_msg, em[i].err_msg);
	    ret = 0;
	    break;
	}
    }

    return ret;
}
