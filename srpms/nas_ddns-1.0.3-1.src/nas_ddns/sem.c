#include <stdio.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <errno.h>
#include "sem.h"
#include "common.h"
#include "db.h"

int sem_init(void)
{
    int id;
    key_t key;

    key = ftok(DBPATH, 'a');
    if (key == -1) {
	//perror("ftok");
	return -1;
    }

    id = semget(key, 1, IPC_CREAT | IPC_EXCL | 0666);
    if (id == -1) {
	if (errno == EEXIST) {	/* the semaphores exists */
	    id = semget(key, 1, SHM_R | SHM_W);
	} else {		/* create semaphores failed */
	    //perror("semget");
	}
    } else {			/* create semaphores OK */
	/* initial semaphore */
	if (semctl(id, 0, SETVAL, 1) == -1) {
	    //perror("SETVAL");
	    id = -1;
	}
    }

    return id;
}

/* P operate */
int sem_request(int sid)
{
    struct sembuf sops;
    sops.sem_num = 0;
    sops.sem_op = -1;
    sops.sem_flg = SEM_UNDO;
    return semop(sid, &sops, 1);
}

/* V operate */
int sem_release(int sid)
{
    struct sembuf sops;
    sops.sem_num = 0;
    sops.sem_op = 1;
    sops.sem_flg = SEM_UNDO;
    return semop(sid, &sops, 1);
}

void sem_delete(int sid)
{
    semctl(sid, 0, IPC_RMID, 0);
    return;
}
