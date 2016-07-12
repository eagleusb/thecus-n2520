#ifndef _SEM_H
#define _SEM_H

//#define	SEM_PATH	"/var/lib/mysql"

int sem_init(void);
int sem_request(int sid);	/* P operate */
int sem_release(int sid);	/* V operate */
void sem_delete(int sid);

#endif				/* _SEM_H */
