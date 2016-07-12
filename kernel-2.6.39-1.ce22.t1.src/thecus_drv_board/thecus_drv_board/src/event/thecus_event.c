/*
 *  Copyright (C) 2009 Thecus Technology Corp. 
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */

#include <linux/kcompat.h>
#include "../../md/md.h"
#include <linux/thecus_event.h>

#define MESSAGE_LENGTH 80
#define MAX_BUFFER 100
static char Critical_Message[MAX_BUFFER][MESSAGE_LENGTH];
static int Critical_PT = 0, Critical_SPT = 0;

// log md0 ~ md19 boot raid last status for boot raid autorun used
#define MAX_MD	20
static char last_mdx_Message[MAX_MD][MESSAGE_LENGTH];

#define BUFSIZE 256
char lastmsg[BUFSIZE];
char lastparm1[BUFSIZE];

//#define DEBUG 1
#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (x>=DEBUG) printk(KERN_DEBUG "%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

static DEFINE_SEMAPHORE(critical_sem);

static void clear_critical_buffer(void);

DECLARE_WAIT_QUEUE_HEAD(thecus_critical_event_queue);

struct status_map {
    int status;
    char status_key[50];
};

static struct status_map the_statusmap[] = {
    {RAID_STATUS_NA, RAID_NA},
    {RAID_STATUS_HEALTHY, RAID_HEALTHY},
    {RAID_STATUS_CREATE, RAID_CREATE},
    {RAID_STATUS_RECOVERY, RAID_RECOVERY},
    {RAID_STATUS_DEGRADE, RAID_DEGRADE},
    {RAID_STATUS_DAMAGE, RAID_DAMAGE},
    {RAID_STATUS_IO_FAIL, RAID_IO_FAIL},
    {RAID_STATUS_DISK_FAIL, RAID_DISK_FAIL},
    {RAID_STATUS_AUTO_RUN, RAID_AUTO_RUN},
    {0, "\0"}
};


void criticalevent_user(char *message, const char *parm1)
{
    char curmsg[BUFSIZE];
    char curparm1[BUFSIZE];
    int out_pt;

    if (message) {
	memset(curmsg, 0, sizeof(curmsg));
	memset(curparm1, 0, sizeof(curparm1));
	strcpy(curmsg, message);
	strcpy(curparm1, parm1);

	//compare with last one 
	if ((strncmp(curmsg, lastmsg, BUFSIZE) != 0)
	    || (strncmp(curparm1, lastparm1, BUFSIZE) != 0)) {
	    color_print_red_begin();
	    printk(KERN_ALERT "criticalevent_user: %s %s \n", message,
		   parm1);
	    color_print_end();

//	    down(&critical_sem);
	    out_pt = Critical_PT++;
	    Critical_PT %= MAX_BUFFER;
	    snprintf(Critical_Message[out_pt], MESSAGE_LENGTH, "%s %s",
		     message, parm1);
//	    up(&critical_sem);

	    memset(lastmsg, 0, sizeof(lastmsg));
	    memset(lastparm1, 0, sizeof(lastparm1));
	    strcpy(lastmsg, message);
	    strcpy(lastparm1, parm1);

	    wake_up_interruptible(&thecus_critical_event_queue);
	} else {
	    printk(KERN_ALERT "[No Event Out]criticalevent_user: %s %s \n",
		   message, parm1);
	}
    }
}

EXPORT_SYMBOL(criticalevent_user);

void check_raid_status(mddev_t * mddev, int status)
{
    int i;
    if (mddev->raid_status != status) {
	//printk("check_raid_status:mddev->raid_status=%d  status=%d....\n",mddev->raid_status,status);
	for (i = 0; the_statusmap[i].status != 0; i++) {
	    int md_idx = 0;
	    if (the_statusmap[i].status == status) {
		criticalevent_user(the_statusmap[i].status_key,
				   mdname(mddev));
		mddev->raid_status = status;
		if (sscanf(mdname(mddev), "md%d", &md_idx) == 1) {
		    if (md_idx >= 0 && md_idx < MAX_MD) {	// log mdx last raid status
			snprintf(last_mdx_Message[md_idx], MESSAGE_LENGTH,
				 "%s %s", the_statusmap[i].status_key,
				 mdname(mddev));
		    }
		}
	    }
	}
    }
}

EXPORT_SYMBOL(check_raid_status);


static ssize_t thecus_read_critical_event(struct file *file,
					  char __user * buffer,
					  size_t length, loff_t * ppos)
{
    static int finished = 0;
    int i, show_pt;

    if (finished) {
	finished = 0;
	return 0;
    }

    down(&critical_sem);
    if (Critical_PT == Critical_SPT) {
	up(&critical_sem);
	interruptible_sleep_on(&thecus_critical_event_queue);
	if (signal_pending(current))
	    return -ERESTARTSYS;
	down(&critical_sem);
    }

    show_pt = Critical_SPT;
    Critical_SPT++;
    Critical_SPT %= MAX_BUFFER;
    up(&critical_sem);
    printk("Read Pointer: current: %d, next: %d\n", show_pt, Critical_SPT);

    for (i = 0; i < length && Critical_Message[show_pt][i]; i++) {
	put_user(Critical_Message[show_pt][i], buffer + i);
    }
    memset(Critical_Message[show_pt], 0, MESSAGE_LENGTH);
    finished = 1;

    return i;
}

static void clear_critical_buffer()
{
    int i;

    down(&critical_sem);
    memset(Critical_Message, 0, sizeof(Critical_Message));
    Critical_PT = 0;
    Critical_SPT = 0;

    for (i = 0; i < MAX_MD; i++) {
	if (last_mdx_Message[i][0] != 0) {
	    strcpy(Critical_Message[Critical_PT++], last_mdx_Message[i]);
	}
    }
    up(&critical_sem);
}

static ssize_t thecus_write_critical_event(struct file *file,
					   const char __user * buf,
					   size_t length, loff_t * ppos)
{
    char *buffer;
    int i, err;

    if (!buf || length > PAGE_SIZE)
	return -EINVAL;

    buffer = (char *) __get_free_page(GFP_KERNEL);
    if (!buffer)
	return -ENOMEM;

    err = -EFAULT;
    if (copy_from_user(buffer, buf, length))
	goto out;

    err = -EINVAL;
    if (length < PAGE_SIZE)
	buffer[length] = '\0';
    else if (buffer[PAGE_SIZE - 1])
	goto out;

    if (!strncmp(buffer, "clear queue", strlen("clear queue"))) {
	printk(KERN_ALERT "Clear Critical Queue. \n");
	clear_critical_buffer();
    } else if (!strncmp(buffer, "show queue", strlen("show queue"))) {
	printk(KERN_ALERT "dump critical queue . \n");
	printk(KERN_ALERT "=============================\n");
	for (i = 0; i < MAX_BUFFER; i++) {
	    if (Critical_Message[i])
		printk(KERN_ALERT "%d:%s \n", i, Critical_Message[i]);
	}
    } else if (!strncmp(buffer, "stop queue", strlen("stop queue"))) {
	printk(KERN_ALERT "stop queue . \n");
	printk(KERN_ALERT "=============================\n");
    } else {
	if (buffer) {
	    printk("Error: Unabled Command %s \n", buffer);
	} else {
	    printk("Error: NO Command %s \n", buffer);
	}
    }

    err = length;

  out:
    free_page((unsigned long) buffer);
    *ppos = 0;

    return err;
}

static struct file_operations proc_thecus_event_critical_operations = {
    .write = thecus_write_critical_event,
    .read = thecus_read_critical_event,
};

static __init int thecus_event_init(void)
{
    int ret = 0;
    struct proc_dir_entry *cpde;

    //Clear last record
    memset(lastmsg, 0, sizeof(lastmsg));
    memset(lastparm1, 0, sizeof(lastparm1));
    memset(last_mdx_Message, 0, sizeof(last_mdx_Message));
    clear_critical_buffer();

    cpde = create_proc_entry("thecus_eventc", S_IRUSR, NULL);
    if (!cpde) {
	printk(KERN_ERR "Thecus : cannot create proc entry . \n");
	return -ENOENT;
    }
    cpde->proc_fops = &proc_thecus_event_critical_operations;

    init_waitqueue_head(&thecus_critical_event_queue);
    printk(KERN_INFO "thecus_event : started\n");

    return ret;
}

static __exit void thecus_event_exit(void)
{
    remove_proc_entry("thecus_eventc", NULL);
}

module_init(thecus_event_init);
module_exit(thecus_event_exit);
