/*
 *  Copyright (C) 2009 Thecus Technology Corp. 
 *
 *      Maintainer: joey <joey_wang@thecus.com>
 *
 *      Driver for Thecus N7700PRO board's I/O
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/i2c.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/rtc.h>		/* get the user-level API */
#include <linux/init.h>
#include <linux/types.h>
#include <linux/miscdevice.h>
#include <linux/poll.h>
#include <linux/proc_fs.h>
#include <linux/notifier.h>
#include <linux/delay.h>
#include <asm/io.h>
#include <linux/vt_kern.h>
#include <linux/reboot.h>

#include "thecus_board.h"

u32 n7700pro_disk_access(int index, int act);
u32 n7700pro_disk_index(int index, struct scsi_device *sdp);

static const struct thecus_function n7700pro_func = {
        .disk_access = n7700pro_disk_access,
        .disk_index  = n7700pro_disk_index,
};

static int board_idx = 0;
static struct thecus_board board_info [] = {
	{ 4, "N7700PRO", 7, 17, 1, "102", "BOARD_N7700PRO", &n7700pro_func},
	{ 5, "N8800PRO", 8, 17, 1, "103", "BOARD_N7700PRO", &n7700pro_func},
	{ }
};

extern int ICH7_GPIO_init(void);
extern void ICH7_GPIO_exit(void);
extern int ICH7_gpio_read_bit(u32 bit_n);
extern int ICH7_gpio_write_bit(u32 bit_n, int val);
extern u32 thecus_board_register(struct thecus_board *board);
extern u32 thecus_board_unregister(struct thecus_board *board);

//#define DEBUG 1

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (DEBUG>=x) printk("%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

MODULE_AUTHOR("Joey Wang <joey_wang@thecus.com>");
MODULE_DESCRIPTION
    ("Thecus N7700PRO MB Driver and board depend io operation");
MODULE_LICENSE("GPL");
static int debug;;
module_param(debug, int, S_IRUGO | S_IWUSR);

static u32 keep_BUZZER = BUZZER_OFF;
static u32 led_usb_busy = LED_OFF;
static u32 led_sys_fail = LED_OFF;
static u32 led_sys_busy = LED_OFF;
static int sleepon_flag=0;

//static u32 access_led[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

u32 n7700pro_disk_access(int index,int act){
    // disk access led by hw
    return 1;
}

u32 n7700pro_disk_index(int index, struct scsi_device *sdp){
    u32 tindex=index;
    if(0==strncmp(sdp->host->hostt->name,"ata_piix",strlen("ata_piix"))){
        tindex = sdp->host->host_no + sdp->channel + sdp->id + 702;
    }else if(0==strncmp(sdp->host->hostt->name,"ahci",strlen("ahci"))){
        tindex = sdp->host->host_no + 14;
    } else if(0==strncmp(sdp->host->hostt->name,"sata_sil24",strlen("sata_sil24"))){
        if ((sdp->host->host_no - 6) % 2 == 0){
            tindex = sdp->host->host_no - 5;
        }else{
            tindex = sdp->host->host_no - 7;
        }
    }
    return tindex;
}

static void reset_pic(void)
{
    u8 val;
    printk("RESET_PIC\n");
    val = 0;
    ICH7_gpio_write_bit(39, val);
    udelay(60);
    val = 1;
    ICH7_gpio_write_bit(39, val);
}

static ssize_t proc_thecus_io_write(struct file *file,
				    const char __user * buf, size_t length,
				    loff_t * ppos)
{
    char *buffer, buf1[20];
    int i, err, v1, v2;
    u8 val=0;

    if (!buf || length > PAGE_SIZE)
	return -EINVAL;

    err = -ENOMEM;
    buffer = (char *) __get_free_page(GFP_KERNEL);
    if (!buffer)
	goto out2;

    err = -EFAULT;
    if (copy_from_user(buffer, buf, length))
	goto out;

    err = -EINVAL;
    if (length < PAGE_SIZE) {
	buffer[length] = '\0';
#define LF	0xA
	if (length > 0 && buffer[length - 1] == LF)
	    buffer[length - 1] = '\0';
    } else if (buffer[PAGE_SIZE - 1])
	goto out;

    memset(buf1, 0, sizeof(buf1));

    /*
     * Usage: echo "S_LED 1-12 0|1|2" >/proc/thecus_io //2:Blink * LED SATA 1-12 ERROR led
     * Usage: echo "U_LED 0|1|2" >/proc/thecus_io //2:Blink * USB BUSY led
     * Usage: echo "Fail 0|1" >/proc/thecus_io                  * LED System Fail
     * Usage: echo "Busy 0|1" >/proc/thecus_io                  * LED System Busy
     * Usage: echo "Buzzer 0|1" >/proc/thecus_io                * Buzzer
     * Usage: echo "RESET_PIC" >/proc/thecus_io                * RESET_PIC
     */

    if (!strncmp(buffer, "S_LED", strlen("S_LED"))) {
	i = sscanf(buffer + strlen("S_LED"), "%d %d\n", &v1, &v2);
	if (i == 2)		//two input
	{
	    if (v2 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v2 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    if (v1 >= 1 && v1 <= 8) {
		v1 = v1 - 1;
		pca9532_set_led(v1, val);
	    } else {
		pca9532_set_led(v1, val);
	    }
	}
    } else if (!strncmp(buffer, "U_LED", strlen("U_LED"))) {
	i = sscanf(buffer + strlen("U_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "U_LED %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_ICH_OFF;
	    else //turn on
		val = LED_ICH_ON;

	    led_usb_busy = val;
   	    ICH7_gpio_write_bit(24, val);
	}
    } else if (!strncmp(buffer, "Fail", strlen("Fail"))) {
	i = sscanf(buffer + strlen("Fail"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "Fail %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_ICH_OFF;
	    else //turn on
		val = LED_ICH_ON;

	    led_sys_fail = val;
   	    ICH7_gpio_write_bit(25, val);
	}
    } else if (!strncmp(buffer, "Busy", strlen("Busy"))) {
	i = sscanf(buffer + strlen("Busy"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "Busy %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_ICH_OFF;
	    else //turn on
		val = LED_ICH_ON;

	    led_sys_busy = val;
   	    ICH7_gpio_write_bit(35, val);
	}
    } else if (!strncmp(buffer, "Buzzer", strlen("Buzzer"))) {
	i = sscanf(buffer + strlen("Buzzer"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "Buzzer %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = BUZZER_OFF;
	    else
		val = BUZZER_ON;

	    keep_BUZZER = val;
	    kd_mksound(val * 440, 0);
	}
    } else if (!strncmp(buffer, "RESET_PIC", strlen("RESET_PIC"))) {
        reset_pic();
    }

    err = length;
  out:
    free_page((unsigned long) buffer);
  out2:
    *ppos = 0;

    return err;
}


static int proc_thecus_io_show(struct seq_file *m, void *v)
{
    u8 val = 0;
    char LED_STATUS[4][8];

/*
    u16 gval;
    gval=inw(PMBASE+0x60+0x06);
    val=check_bit(gval,0);
    if(val>=0)
        seq_printf(m,"Case Cover: %s\n", val?"Opened":"Closed");
*/
    sprintf(LED_STATUS[LED_ON], "ON");
    sprintf(LED_STATUS[LED_OFF], "OFF");
    sprintf(LED_STATUS[LED_BLINK1], "BLINK");
    sprintf(LED_STATUS[LED_BLINK2], "-");

    seq_printf(m, "MODELNAME: %s\n", board_info[board_idx].board_string);

    seq_printf(m, "FAC_MODE: OFF\n");

    seq_printf(m, "Buzzer: %s\n", keep_BUZZER ? "ON" : "OFF");

    seq_printf(m, "MAX_TRAY: %d\n", board_info[board_idx].max_tray);
    seq_printf(m, "eSATA_TRAY: %d\n", board_info[board_idx].eSATA_tray);
    seq_printf(m, "eSATA_COUNT: %d\n", board_info[board_idx].eSATA_count);
    seq_printf(m, "WOL_FN: %d\n", 1);
    seq_printf(m, "FAN_FN: %d\n", 1);
    seq_printf(m, "BEEP_FN: %d\n", 1);
    seq_printf(m, "eSATA_FN: %d\n", 1);
    seq_printf(m, "MBTYPE: %s\n", board_info[board_idx].mb_type);

    seq_printf(m, "U_LED: %s\n", LED_STATUS[led_usb_busy]);
    seq_printf(m, "LED_Fail: %s\n", LED_STATUS[led_sys_fail]);
    seq_printf(m, "LED_Busy: %s\n", LED_STATUS[led_sys_busy]);

    val = ICH7_gpio_read_bit(9);
    seq_printf(m, "GPIO9: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(14);
    seq_printf(m, "GPIO14: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(15);
    seq_printf(m, "GPIO15: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(24);
    seq_printf(m, "GPIO24: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(25);
    seq_printf(m, "GPIO25: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(33);
    seq_printf(m, "GPIO33: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(34);
    seq_printf(m, "GPIO34: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(35);
    seq_printf(m, "GPIO35: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(38);
    seq_printf(m, "GPIO38: %s\n", val ? "HIGH" : "LOW");

    val = ICH7_gpio_read_bit(39);
    seq_printf(m, "GPIO39: %s\n", val ? "HIGH" : "LOW");

    return 0;
}

static int proc_thecus_io_open(struct inode *inode, struct file *file)
{
    return single_open(file, proc_thecus_io_show, NULL);
}

static struct file_operations proc_thecus_io_operations = {
    .open = proc_thecus_io_open,
    .read = seq_read,
    .write = proc_thecus_io_write,
    .llseek = seq_lseek,
    .release = single_release,
};

// ----------------------------------------------------------
static DECLARE_WAIT_QUEUE_HEAD(thecus_event_queue);
#define MESSAGE_LENGTH 80
static char Message[MESSAGE_LENGTH];
#define MY_WORK_QUEUE_NAME "btn_sched"	// length must < 10
#define WORK_QUEUE_TIMER_1 250
#define WORK_QUEUE_TIMER_2 50
static u32 dyn_work_queue_timer = WORK_QUEUE_TIMER_1;
static void intrpt_routine(struct work_struct *unused);
static int module_die = 0;	/* set this to 1 for shutdown */
static struct workqueue_struct *my_workqueue;
static struct delayed_work Task;
static DECLARE_DELAYED_WORK(Task, intrpt_routine);

static void intrpt_routine(struct work_struct *unused)
{
/*
    u8 val = 0;
    if(board_idx == 0){
	val = pca9532_id_get_input(6);
        if(val == 0) {
            sprintf(Message, "Copy ON\n");
            wake_up_interruptible(&thecus_event_queue);
        }
    }
*/
    static u32 psu_status = 1;  // default high, psu fail 時會 low
    u8 val = 0;

    val = ICH7_gpio_read_bit(14);        // check PSU
    if (val == 0){
        val = ICH7_gpio_read_bit(15);        // PSU_FAIL gpio
        if(psu_status != val) {
            // default high, psu fail 時會 low
            if(val == 1) {
                sprintf(Message, "PSU_FAIL OFF\n");
            } else {
                sprintf(Message, "PSU_FAIL ON\n");
            }
            psu_status = val;
            wake_up_interruptible(&thecus_event_queue);
        }
    }

    // If cleanup wants us to die
    if (module_die == 0)
	queue_delayed_work(my_workqueue, &Task, dyn_work_queue_timer);

}

static ssize_t thecus_event_read(struct file *file, char __user * buffer,
				 size_t length, loff_t * ppos)
{
    static int finished = 0;
    int i;
    if (finished) {
	finished = 0;
	return 0;
    }
//      printk(KERN_DEBUG "process %i (%s) going to sleep\n",
//           current->pid, current->comm);
    sleepon_flag=1;
    interruptible_sleep_on(&thecus_event_queue);
    sleepon_flag=0;
//      printk(KERN_DEBUG "awoken %i (%s)\n", current->pid, current->comm);
    for (i = 0; i < length && Message[i]; i++)
	put_user(Message[i], buffer + i);

    finished = 1;
    return i;
}

static struct file_operations proc_thecus_event_operations = {
    .read = thecus_event_read,
};


static int sys_notify_reboot(struct notifier_block *nb, unsigned long event, void *p)
{

    switch (event) {
    case SYS_RESTART:
    case SYS_HALT:
    case SYS_POWER_OFF:
        // turn off busy/err led
        ICH7_gpio_write_bit(24,LED_ICH_OFF);
        ICH7_gpio_write_bit(25,LED_ICH_OFF);
        ICH7_gpio_write_bit(35,LED_ICH_OFF);
        break;
    }
    return NOTIFY_DONE;
}

static struct notifier_block sys_notifier_reboot = {
    .notifier_call = sys_notify_reboot,
    .next = NULL,
    .priority = 0
};

static __init int thecus_io_init(void)
{
    struct proc_dir_entry *pde;
    u32 board_num = 0, n = 0;
    u8 val;
    int ret;

    ret = ICH7_GPIO_init();
    if (ret < 0) {
//        printk(KERN_ERR "ICH7_GPIO_init failed\n");
        return ret;
    }

    pde = create_proc_entry("thecus_io", 0, NULL);
    if (!pde) {
	printk(KERN_ERR "thecus_io: cannot create /proc/thecus_io.\n");
	return -ENOENT;
    }
    pde->proc_fops = &proc_thecus_io_operations;

    pde = create_proc_entry("thecus_event", S_IRUSR, NULL);
    if (!pde) {
	printk(KERN_ERR "thecus_io: cannot create /proc/thecus_event.\n");
	return -ENOENT;
    }
    pde->proc_fops = &proc_thecus_event_operations;

    my_workqueue = create_singlethread_workqueue(MY_WORK_QUEUE_NAME);
    if (my_workqueue) {
	queue_delayed_work(my_workqueue, &Task, dyn_work_queue_timer);
	init_waitqueue_head(&thecus_event_queue);
    } else {
	printk(KERN_ERR "thecus_io: error in thecus_io_init\n");
    }

    
    val = ICH7_gpio_read_bit(9);
    board_num |= (val<<2);
    val = ICH7_gpio_read_bit(33);
    board_num |= (val<<1);
    val = ICH7_gpio_read_bit(34);
    board_num |= val;

    printk(KERN_INFO "thecus_io: board_num: %Xh\n", board_num);
    for (n = 0; board_info[n].board_string; n++)
        if (board_num == board_info[n].gpio_num) {
            board_idx = n;
            break;
        }

    thecus_board_register(&board_info[board_idx]);

    ICH7_gpio_write_bit(24,LED_ICH_OFF);
    ICH7_gpio_write_bit(25,LED_ICH_OFF);
    ICH7_gpio_write_bit(35,LED_ICH_OFF);

    register_reboot_notifier(&sys_notifier_reboot);

    return 0;
}

static __exit void thecus_io_exit(void)
{
    module_die = 1;		// keep intrp_routine from queueing itself 
    remove_proc_entry("thecus_io", NULL);
    remove_proc_entry("thecus_event", NULL);

    cancel_delayed_work(&Task);	// no "new ones" 
    flush_workqueue(my_workqueue);	// wait till all "old ones" finished 
    destroy_workqueue(my_workqueue);

    ICH7_GPIO_exit();

    unregister_reboot_notifier(&sys_notifier_reboot);

    thecus_board_unregister(&board_info[board_idx]);
}

module_init(thecus_io_init);
module_exit(thecus_io_exit);
