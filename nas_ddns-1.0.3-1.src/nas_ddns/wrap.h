#ifndef __WRAP_H
#define __WRAP_H

#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<unistd.h>
#include	<errno.h>
#include	<stdarg.h>	/* ANSI C header file */
#include	<syslog.h>	/* for syslog() */

#define MAXLINE			4096	/* max text line length */
#define	HAVE_VSNPRINTF

int daemon_proc;		/* set nonzero by daemon_init() */

static void err_doit(int, int, const char *, va_list);

/* Nonfatal error related to system call
 * Print message and return */

void err_ret(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    err_doit(1, LOG_INFO, fmt, ap);
    va_end(ap);
    return;
}

/* Fatal error related to system call
 * Print message and terminate */

void err_sys(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    err_doit(1, LOG_ERR, fmt, ap);
    va_end(ap);
    exit(1);
}

/* Fatal error related to system call
 * Print message, dump core, and terminate */

void err_dump(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    err_doit(1, LOG_ERR, fmt, ap);
    va_end(ap);
    abort();			/* dump core and terminate */
    exit(1);			/* shouldn't get here */
}

/* Nonfatal error unrelated to system call
 * Print message and return */

void err_msg(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    err_doit(0, LOG_INFO, fmt, ap);
    va_end(ap);
    return;
}

/* Fatal error unrelated to system call
 * Print message and terminate */

void err_quit(const char *fmt, ...)
{
    va_list ap;

    va_start(ap, fmt);
    err_doit(0, LOG_ERR, fmt, ap);
    va_end(ap);
    exit(1);
}

/* Print message and return to caller
 * Caller specifies "errnoflag" and "level" */

static void err_doit(int errnoflag, int level, const char *fmt, va_list ap)
{
    int errno_save, n;
    char buf[MAXLINE + 1];

    errno_save = errno;		/* value caller might want printed */
#ifdef	HAVE_VSNPRINTF
    vsnprintf(buf, MAXLINE, fmt, ap);	/* safe */
#else
    vsprintf(buf, fmt, ap);	/* not safe */
#endif
    n = strlen(buf);
    if (errnoflag)
	snprintf(buf + n, MAXLINE - n, ": %s", strerror(errno_save));
    strcat(buf, "\n");

    if (daemon_proc) {
	syslog(level, buf);
    } else {
	fflush(stdout);		/* in case stdout and stderr are the same */
	fputs(buf, stderr);
	fflush(stderr);
    }
    return;
}


/*
 * unix wrap
 */
pid_t Fork(void)
{
    pid_t pid;

    if ((pid = fork()) == -1)
	err_sys("fork error");
    return (pid);
}

/*
int
Open(const char *pathname, int oflag)
{
    int		fd;

    if ( (fd = open(pathname, oflag, 0755)) == -1)
        err_sys("open error for %s", pathname);
    return(fd);
}
*/
void Close(int fd)
{
    if (close(fd) == -1)
	err_sys("close error");
}

ssize_t Read(int fd, void *ptr, size_t nbytes)
{
    ssize_t n;

    if ((n = read(fd, ptr, nbytes)) == -1)
	err_sys("read error");
    return (n);
}

void Write(int fd, void *ptr, size_t nbytes)
{
    if (write(fd, ptr, nbytes) != nbytes) {
	err_sys("write error");
    }
}

off_t Lseek(int fd, off_t offset, int whence)
{
    off_t off;
    if ((off = lseek(fd, offset, whence)) == -1)
	err_sys("lseek error");
    return (off);
}


/*
 * signal wrap
 */
#include	<signal.h>
#include	<sys/wait.h>

typedef void Sigfunc(int);

Sigfunc *signal(int signo, Sigfunc * func)
{
    struct sigaction act, oact;

    act.sa_handler = func;
    sigemptyset(&act.sa_mask);
    act.sa_flags = 0;
    if (signo == SIGALRM) {
#ifdef  SA_INTERRUPT
	act.sa_flags |= SA_INTERRUPT;	/* SunOS 4.x */
#endif
    } else {
#ifdef  SA_RESTART
	act.sa_flags |= SA_RESTART;	/* SVR4, 44BSD */
#endif
    }
    if (sigaction(signo, &act, &oact) < 0)
	return (SIG_ERR);
    return (oact.sa_handler);
}

/* end signal */

Sigfunc *Signal(int signo, Sigfunc * func)
{				/* for our signal() function */
    Sigfunc *sigfunc;

    if ((sigfunc = signal(signo, func)) == SIG_ERR)
	err_sys("signal error");
    return (sigfunc);
}

#endif				/* __WRAP_H */
