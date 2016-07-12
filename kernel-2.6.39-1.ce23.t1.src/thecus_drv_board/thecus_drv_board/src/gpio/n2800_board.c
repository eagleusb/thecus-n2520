/*
 *  Copyright (C) 2009 Thecus Technology Corp. 
 *
 *      Maintainer: joey <joey_wang@thecus.com>
 *
 *      Driver for Thecus N2800 board's I/O
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

u32 n2800_disk_access(int index, int act);
u32 n2800_disk_index(int index, struct scsi_device *sdp);
u32 n5550_disk_access(int index, int act);
u32 n5550_disk_index(int index, struct scsi_device *sdp);
u32 n7550_disk_index(int index, struct scsi_device *sdp);

static const struct thecus_function n2800_func = {
        .disk_access = n2800_disk_access,
        .disk_index  = n2800_disk_index,
};

static const struct thecus_function n5550_func = {
        .disk_access = n5550_disk_access,
        .disk_index  = n5550_disk_index,
};

static const struct thecus_function n7550_func = {
        .disk_access = n5550_disk_access,
        .disk_index  = n7550_disk_index,
};

static int board_idx = 0;
static struct thecus_board board_info [] = {
	{ 0, "N2800"  , 2, 17, 1, "700", "BOARD_N2800", &n2800_func},
	{ 1, "N4800"  , 4, 17, 1, "701", "BOARD_N2800", &n2800_func},
	{ 2, "N5550"  , 5, 17, 1, "702", "BOARD_N5550", &n5550_func},
	{ 3, "NHK4550", 4, 17, 1, "703", "BOARD_N5550", &n5550_func},
	{ 4, "N4510U-R", 4, 17, 1, "704", "BOARD_N5550", &n5550_func},
	{ 5, "N4510U-S", 4, 17, 1, "705", "BOARD_N5550", &n5550_func},
	{ 6, "N7510"  , 7, 17, 1, "706", "BOARD_N7550", &n7550_func},
	{ 7, "N8800"  , 8, 17, 1, "707", "BOARD_N7550", &n7550_func},
	{ 8, "N2550"  , 2, 17, 1, "708", "BOARD_N2800", &n2800_func},
	{ 9, "N4550"  , 4, 17, 1, "709", "BOARD_N2800", &n2800_func},
	{ }
};

extern int ICH_GPIO_init(void);
extern void ICH_GPIO_exit(void);
extern int ICH_gpio_read_bit(u32 bit_n);
extern int ICH_gpio_write_bit(u32 bit_n, int val);
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
    ("Thecus N2800 MB Driver and board depend io operation");
MODULE_LICENSE("GPL");
static int debug;;
module_param(debug, int, S_IRUGO | S_IWUSR);

static u32 keep_BUZZER = BUZZER_OFF;
static u32 led_usb_busy = LED_OFF;
static u32 led_usb_err = LED_OFF;
static u32 led_sd_busy = LED_OFF;
static u32 led_sd_err = LED_OFF;
static u32 led_logo1 = LED_OFF;
static u32 led_logo2 = LED_OFF;
static u32 led_sys_power = LED_OFF;
static u32 led_sys_busy = LED_OFF;
static u32 led_sys_err = LED_OFF;
static int sleepon_flag=0;
int bat_flag=0;

static u32 access_led[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

u32 n2800_disk_access(int index,int act){
    if (index <= 0) return 1;

    //only handle 1~5 disk access
    if (index > 5) return 1;

    if (act==LED_ENABLE){
        access_led[index-1]=1;
        act=LED_ON;
    }

    if (access_led[index-1]==0) return 1;

    if (act==LED_DISABLE){
        access_led[index-1]=0;
        act=LED_OFF;
    }

    if (index==1) index=0;
    if (act==LED_ON)
        ICH_gpio_write_bit(index,0);
    else if (act==LED_OFF)
        ICH_gpio_write_bit(index,1);

    return 0;
}

u32 n2800_disk_index(int index, struct scsi_device *sdp){
    u32 tindex=index;
    if(0==strncmp(sdp->host->hostt->name,"ahci",strlen("ahci"))){
        tindex = sdp->host->host_no;
        switch (tindex) {
            case 0: // DOMA
                tindex = 702;
                break;
            case 1: // disk 1
            case 2: // disk 2
            case 3: // disk 3
            case 4: // disk 4
                tindex = tindex - 1;
                break;
            case 5: // eSATA1
                tindex = tindex + 11;
                break;
        }
    }
    return tindex;
}

u32 n5550_disk_access(int index,int act){
    if (index <= 0) return 1;

    //only handle 1~5 disk access
    if (index > 5) return 1;

    if (act==LED_DISABLE){
        act=LED_OFF;
    }

    if (index==1) index=0;
    if (act==LED_ON)
        ICH_gpio_write_bit(index,1);
    else if (act==LED_OFF)
        ICH_gpio_write_bit(index,0);

    return 0;
}

u32 n5550_disk_index(int index, struct scsi_device *sdp){
    u32 tindex=index;
    if(0==strncmp(sdp->host->hostt->name,"ahci",strlen("ahci"))){
        tindex = sdp->host->host_no;
        switch (tindex) {
            case 0: // DOMA
                tindex = 702;
                break;
            case 1: // disk 1
            case 2: // disk 2
            case 3: // disk 3
            case 4: // disk 4
            case 5: // disk 5
                tindex = tindex - 1;
                break;
        }
    } else if(0==strncmp(sdp->host->hostt->name,"sata_sil24",strlen("sata_sil24"))){
        tindex = sdp->host->host_no;
        switch (tindex) {
            case 6: // disk 6
                tindex = tindex + 10; //eSATA
                break;
       }
    }
    return tindex;
}

u32 n7550_disk_index(int index, struct scsi_device *sdp){
    u32 tindex=index;
    if(0==strncmp(sdp->host->hostt->name,"ahci",strlen("ahci"))){
        tindex = sdp->host->host_no;
        switch (tindex) {
            case 0: // DOMA
                tindex = 702;
                break;
            case 1: // disk 1
            case 2: // disk 2
            case 3: // disk 3
            case 4: // disk 4
            case 5: // disk 5
                tindex = tindex - 1;
                break;
        }
    } else if(0==strncmp(sdp->host->hostt->name,"sata_sil24",strlen("sata_sil24"))){
        tindex = sdp->host->host_no;
        switch (tindex) {
            case 6: // disk 6
            case 7: // disk 7
            case 8: // disk 8
                tindex = tindex - 1;
                break;
            case 9: // eSATA 1
                tindex = tindex + 7;
                break;
       }
    }
    return tindex;
}

static void reset_pic(void)
{
    u8 val;
    printk("RESET_PIC\n");
    val = 1;
    pca9532_id_set_led(15, val);
    udelay(60);
    val = 0;
    pca9532_id_set_led(15, val);
}

static void init_hotek(void)
{
    u8 val=LED_OFF;
    ICH_gpio_write_bit(0, val+1);
    ICH_gpio_write_bit(2, val+1);
    ICH_gpio_write_bit(3, val+1);
    ICH_gpio_write_bit(4, val+1);
    pca9532_set_led(0, val);
    pca9532_set_led(1, val);
    pca9532_set_led(2, val);
    pca9532_set_led(3, val);
    pca9532_id_set_led(10, val);
    pca9532_id_set_led(11, val);
    ssleep(1);
    val=LED_ON;
    ICH_gpio_write_bit(0, val-1);
    ICH_gpio_write_bit(2, val-1);
    ICH_gpio_write_bit(3, val-1);
    ICH_gpio_write_bit(4, val-1);
    pca9532_set_led(0, val);
    pca9532_set_led(1, val);
    pca9532_set_led(2, val);
    pca9532_set_led(3, val);
    pca9532_id_set_led(10, val);
    pca9532_id_set_led(11, val);
    ssleep(1);
    val=LED_OFF;
    ICH_gpio_write_bit(0, val+1);
    ICH_gpio_write_bit(2, val+1);
    ICH_gpio_write_bit(3, val+1);
    ICH_gpio_write_bit(4, val+1);
    pca9532_set_led(0, val);
    pca9532_set_led(1, val);
    pca9532_set_led(2, val);
    pca9532_set_led(3, val);
    pca9532_id_set_led(10, val);
    pca9532_id_set_led(11, val);
    ssleep(1);
    val=LED_ON;
    ICH_gpio_write_bit(0, val-1);
    ICH_gpio_write_bit(2, val-1);
    ICH_gpio_write_bit(3, val-1);
    ICH_gpio_write_bit(4, val-1);
    pca9532_set_led(0, val);
    pca9532_set_led(1, val);
    pca9532_set_led(2, val);
    pca9532_set_led(3, val);
    pca9532_id_set_led(10, val);
    pca9532_id_set_led(11, val);
    ssleep(1);
    val=LED_OFF;
    ICH_gpio_write_bit(0, val+1);
    ICH_gpio_write_bit(2, val+1);
    ICH_gpio_write_bit(3, val+1);
    ICH_gpio_write_bit(4, val+1);
    pca9532_set_led(0, val);
    pca9532_set_led(1, val);
    pca9532_set_led(2, val);
    pca9532_set_led(3, val);
    pca9532_id_set_led(10, val);
    pca9532_id_set_led(11, val);
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
     * Usage: echo "A_LED 1-12 0|1|2" >/proc/thecus_io //2:Blink * LED SATA 1-5 ACTIVE led
     * Usage: echo "U_LED 0|1|2" >/proc/thecus_io //2:Blink * USB BUSY led
     * Usage: echo "UF_LED 0|1|2" >/proc/thecus_io //2:Blink * USB ERROR led
     * Usage: echo "SD_LED 0|1|2" >/proc/thecus_io //2:Blink * SD BUSY led
     * Usage: echo "SDF_LED 0|1|2" >/proc/thecus_io //2:Blink * SD ERROR led
     * Usage: echo "LOGO1_LED 0|1|2" >/proc/thecus_io //2:Blink * LOGO1 led
     * Usage: echo "LOGO2_LED 0|1|2" >/proc/thecus_io //2:Blink * LOGO2 led
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

	    if (v1 >= 1 && v1 <= 12) {
		v1 = v1 - 1;
		pca9532_set_led(v1, val);
	    } else {
		pca9532_set_led(v1, val);
	    }
	}
    } else if (!strncmp(buffer, "A_LED", strlen("A_LED"))) {
	i = sscanf(buffer + strlen("A_LED"), "%d %d\n", &v1, &v2);
	if (i == 2)		//two input
	{
	    if (v2 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v2 == 1)	//turn on
		val = LED_ON;

   	    n2800_disk_access(v1, val);
	}
    } else if (!strncmp(buffer, "U_LED", strlen("U_LED"))) {
	i = sscanf(buffer + strlen("U_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "U_LED %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_usb_busy = val;
	    pca9532_id_set_led(10, val);
	}
    } else if (!strncmp(buffer, "UF_LED", strlen("UF_LED"))) {
	i = sscanf(buffer + strlen("UF_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "UF_LED %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_usb_err = val;
	    pca9532_id_set_led(11, val);
	}
    } else if (!strncmp(buffer, "PWR_LED", strlen("PWR_LED"))) {
	i = sscanf(buffer + strlen("PWR_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "PWR_LED %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_sys_power = val;
	    pca9532_id_set_led(8, val);
	}
    } else if (!strncmp(buffer, "Busy", strlen("Busy"))) {
	i = sscanf(buffer + strlen("Busy"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "Busy %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_sys_busy = val;
	    pca9532_id_set_led(9, val);
	}
    } else if (!strncmp(buffer, "Fail", strlen("Fail"))) {
	i = sscanf(buffer + strlen("Fail"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "Fail %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_sys_err = val;
	    pca9532_id_set_led(12, val);
	}
    } else if (!strncmp(buffer, "SD_LED", strlen("SD_LED"))) {
	i = sscanf(buffer + strlen("SD_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "SD %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_sd_busy = val;
	    pca9532_set_led(13, val);
	}
    } else if (!strncmp(buffer, "SDF_LED", strlen("SDF_LED"))) {
	i = sscanf(buffer + strlen("SDF_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "SD Fail %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_sd_err = val;
	    pca9532_id_set_led(14, val);
	}
    } else if (!strncmp(buffer, "LOGO1_LED", strlen("LOGO1_LED"))) {
	i = sscanf(buffer + strlen("LOGO1_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "LOGO1 %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_logo1 = val;
	    pca9532_set_led(14, val);
	}
    } else if (!strncmp(buffer, "LOGO2_LED", strlen("LOGO2_LED"))) {
	i = sscanf(buffer + strlen("LOGO2_LED"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "LOGO2 %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = LED_OFF;
	    else if (v1 == 1)	//turn on
		val = LED_ON;
	    else
		val = LED_BLINK1;

	    led_logo2 = val;
	    pca9532_set_led(15, val);
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
    } else if(!strncmp (buffer, "BAT_CHARG", strlen ("BAT_CHARG"))){
        i = sscanf (buffer + strlen ("BAT_CHARG"), "%d\n",&v1);
        if (i==1){ //only one input
            if(v1==0)//input 0: want to turn off
                val = 0;   
            else
                val = 1;   

   	    ICH_gpio_write_bit(28, val);
        }
    } else if (!strncmp(buffer, "LCD_EN", strlen("LCD_EN"))) {
	i = sscanf(buffer + strlen("LCD_EN"), "%d\n", &v1);
	if (i == 1)		//only one input
	{
	    _DBG(1, "LCD_EN %d\n", v1);
	    if (v1 == 0)	//input 0: want to turn off
		val = 1;
	    else
		val = 0;

   	    ICH_gpio_write_bit(34, val);
	}
    } else if (!strncmp(buffer, "RESET_PIC", strlen("RESET_PIC"))) {
        reset_pic();
    } else if (!strncmp(buffer, "INIT_HOTEK", strlen("INIT_HOTEK"))) {
        init_hotek();
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

    if((board_idx == 0)||(board_idx == 8)){
	val = pca9532_id_get_input(6);
        if(val>=0) seq_printf(m,"Copy button: %s\n", val?"OFF":"ON");
    }
    if (board_idx == 4) {
        val = pca9532_id_get_input(4);
        if(val>=0) seq_printf(m,"PSU1_FAIL: %s\n", val?"OFF":"ON");
        val = pca9532_id_get_input(5);
        if(val>=0) seq_printf(m,"PSU2_FAIL: %s\n", val?"OFF":"ON");
	val = pca9532_id_get_input(6);
        if(val>=0) seq_printf(m,"Mute button: %s\n", val?"OFF":"ON");
    }

    seq_printf(m, "U_LED: %s\n", LED_STATUS[led_usb_busy]);
    seq_printf(m, "UF_LED: %s\n", LED_STATUS[led_usb_err]);
    seq_printf(m, "SD_LED: %s\n", LED_STATUS[led_sd_busy]);
    seq_printf(m, "SDF_LED: %s\n", LED_STATUS[led_sd_err]);
    seq_printf(m, "LOGO1_LED: %s\n", LED_STATUS[led_logo1]);
    seq_printf(m, "LOGO2_LED: %s\n", LED_STATUS[led_logo2]);
    seq_printf(m, "LED_Power: %s\n", LED_STATUS[led_sys_power]);
    seq_printf(m, "LED_Busy: %s\n", LED_STATUS[led_sys_busy]);
    seq_printf(m, "LED_Fail: %s\n", LED_STATUS[led_sys_err]);

    if((board_idx == 1)||(board_idx == 9)){
        val = ICH_gpio_read_bit(34);
        seq_printf(m, "LCD_EN: %s\n", val ? "OFF" : "ON");

        val = pca9532_id_get_input(8);
        if(val>=0) seq_printf(m,"HAS_BAT: %s\n", val?"HIGH":"LOW");

        val = ICH_gpio_read_bit(28);
        if(val>=0) seq_printf(m,"BAT_CHARG: %s\n", val?"HIGH":"LOW");

        val = ICH_gpio_read_bit(9);
        if(val>=0) seq_printf(m,"AC_RDY: %s\n", val?"HIGH":"LOW");
    }

    val = ICH_gpio_read_bit(0);
    seq_printf(m, "GPIO0: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(2);
    seq_printf(m, "GPIO2: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(3);
    seq_printf(m, "GPIO3: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(4);
    seq_printf(m, "GPIO4: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(5);
    seq_printf(m, "GPIO5: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(9);
    seq_printf(m, "GPIO9: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(28);
    seq_printf(m, "GPIO28: %s\n", val ? "HIGH" : "LOW");

    val = ICH_gpio_read_bit(34);
    seq_printf(m, "GPIO34: %s\n", val ? "HIGH" : "LOW");

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
    u8 val = 0;
    static u32 psu1_status = 1;
    static u32 psu2_status = 1;

    if((board_idx == 0)||(board_idx == 8)){
	val = pca9532_id_get_input(6);
        if(val == 0) {
            sprintf(Message, "Copy ON\n");
            wake_up_interruptible(&thecus_event_queue);
        }
    }else if ((board_idx == 1)||(board_idx == 9)){
        val = pca9532_id_get_input(8);
        if(val == 0){
            val = ICH_gpio_read_bit(9);
            if(sleepon_flag){
                if(val == 0){
                    if(bat_flag == 1){
                        sprintf(Message, "AC Ready\n");
                        wake_up_interruptible(&thecus_event_queue);
                    }
                    bat_flag=0;
                }else if (val == 1){
                    if(bat_flag == 0){
                        sprintf(Message, "AC Fail\n");
                        wake_up_interruptible(&thecus_event_queue);
                    }
                    bat_flag=1;
                }
            }
        }
    }else if (board_idx == 4) {
	val = pca9532_id_get_input(4);
        if(psu1_status != val) {
            if(val == 1) {
                sprintf(Message, "PSU1_FAIL OFF\n");
            } else {
                sprintf(Message, "PSU1_FAIL ON\n");
            }
            psu1_status = val;
            wake_up_interruptible(&thecus_event_queue);
        }

	val = pca9532_id_get_input(5);
        if(psu2_status != val) {
            if(val == 1) {
                sprintf(Message, "PSU2_FAIL OFF\n");
            } else {
                sprintf(Message, "PSU2_FAIL ON\n");
            }
            psu2_status = val;
            wake_up_interruptible(&thecus_event_queue);
        }

	val = pca9532_id_get_input(6);
        if(val == 0) {
            sprintf(Message, "Mute ON\n");
            wake_up_interruptible(&thecus_event_queue);
        }
    }else if (board_idx == 5) {
	val = pca9532_id_get_input(6);
        if(val == 0) {
            sprintf(Message, "Mute ON\n");
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
        pca9532_set_led(13, LED_OFF);
        pca9532_set_led(14, LED_OFF);
        pca9532_id_set_led(9, LED_OFF);
        pca9532_id_set_led(10, LED_OFF);
        pca9532_id_set_led(11, LED_OFF);
        pca9532_id_set_led(12, LED_OFF);
        pca9532_id_set_led(14, LED_OFF);
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

    ret = ICH_GPIO_init();
    if (ret < 0) {
//        printk(KERN_ERR "ICH_GPIO_init failed\n");
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

    val = pca9532_id_get_input(0);
    board_num |= val;
    val = pca9532_id_get_input(1);
    board_num |= (val<<1);
    val = pca9532_id_get_input(2);
    board_num |= (val<<2);
    val = pca9532_id_get_input(3);
    board_num |= (val<<3);

    printk(KERN_INFO "thecus_io: board_num: %Xh\n", board_num);
    for (n = 0; board_info[n].board_string; n++)
        if (board_num == board_info[n].gpio_num) {
            board_idx = n;
            break;
        }

    // initial hotek 
    if ((board_idx == 1)||(board_idx == 9))
        init_hotek();

    thecus_board_register(&board_info[board_idx]);

    pca9532_id_set_led(15, 0);

    // turn off busy/err led
    pca9532_id_set_led(9, LED_OFF);
    pca9532_id_set_led(10, LED_OFF);
    pca9532_id_set_led(11, LED_OFF);
    pca9532_id_set_led(12, LED_OFF);
    pca9532_id_set_led(14, LED_OFF);
    pca9532_set_led(13, LED_OFF);
    pca9532_set_led(14, LED_ON);

    // load driver, initial blink busy led
    pca9532_id_set_led(9, LED_BLINK1);

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

    ICH_GPIO_exit();

    unregister_reboot_notifier(&sys_notifier_reboot);

    thecus_board_unregister(&board_info[board_idx]);
}

module_init(thecus_io_init);
module_exit(thecus_io_exit);
