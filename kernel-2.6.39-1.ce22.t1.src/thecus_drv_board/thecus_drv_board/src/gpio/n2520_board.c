/*
 *  Copyright (C) 2013 Thecus Technology Corp. 
 *
 *      Maintainer: Zeno Lai <zeno_lai@thecus.com>
 *
 *      Driver for Thecus N2520 board's I/O
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */
#include <linux/kcompat.h>
//#include "../gpio/intelce_gpio.h"
#include "thecus_board.h"
#include "pic24.h"

/*
 * Since power LED (SYS_BUSY) and logo LED need to be turned on at power on
 * when SW has not involved, HW reverse the pins level to make them able to 
 * be ON as default.
 * Therefore these LEDs' ON/OFF commands need to reverse, too, to unify
 * SW control interface.
 */
#define PWR_LED_ON                     LED_OFF
#define PWR_LED_OFF                    LED_ON
// IntelCE PM GPIO (8051)
#define PM_LED_ON                      0x0
#define PM_LED_OFF                     0x1
#define PM_LED_BLINK                   0x2

// PM GPIO pin assignment
#define N2520_PM_SATA_ACT(i)           ((i)+13)
#define PM_DIAG_BTN                    16
#define PM_PWR_BTN                     17
#define PM_PHY_RST                     20
// SCH GPIO pin assignment
#define SCH_USB_EN                     43
// PCA9532 GPIO pin assignment
#define PCA9532_SATA_ERR(i)            ((i)-1)
#define PCA9532_TEST_0                  8
#define PCA9532_TEST_1                  9
#define PCA9532_BEEP                   10
#define PCA9532_BZ_LED                 11
#define PCA9532_LCD_A_EN               12
#define PCA9532_SD_ACT                 13
#define PCA9532_TLOGO_1                14
#define PCA9532_TLOGO_2                15
#define PCA9532_N4520_SATA_ACT(i)      ((i)+4)
// PCA9532_ID GPIO pin assignment
#define PCA9532_ID_PIC_GPO_0            4
#define PCA9532_ID_PIC_GPO_1            5
#define PCA9532_ID_USB_COPY_BTN         6
#define PCA9532_ID_SOFT_RST             7
#define PCA9532_ID_SYS_STATUS           8
#define PCA9532_ID_SYS_BUSY             9 
#define PCA9532_ID_USB_ACT             10
#define PCA9532_ID_USB_ERR             11
#define PCA9532_ID_SYS_ERR             12
#define PCA9532_ID_PIC_GPI_0           13
#define PCA9532_ID_SD_ERR              14
#define PCA9532_ID_AVR_RST             15 //for RESET PIC

// MBID bits mask [3:0]
#define PCA9532_ID_MBID                0xF

#define N2520_MAX_DISK                 2
#define N4520_MAX_DISK                 4

#define THECUS_MAS_DISK                16

extern int pic24fj128_write_regs(u8 reg_num, u8 * val, int size);
extern int pic24fj128_get_regs(u8 reg_num, u8 * val, int size);
extern int picuart_write_gpio(uint8_t pin, uint8_t val);
extern int picuart_read_gpio(uint8_t pin, uint8_t *val);
extern int picuart_read_version(char* version);

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (x>=DEBUG) printk("%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

int rst_btn_count = 0;
int pwr_btn_count = 0;
int avr_btn_count = 0;
int lcm_off_count = 0;

u32 n2520_disk_access(int index, int act);
u32 n2520_disk_index(int index, struct scsi_device *sdp);
u32 n4520_disk_access(int index, int act);
u32 n4520_disk_index(int index, struct scsi_device *sdp);

static const struct thecus_function n2520_func = {
	.disk_access = n2520_disk_access,
	.disk_index  = n2520_disk_index,
};

static const struct thecus_function n4520_func = {
	.disk_access = n4520_disk_access,
	.disk_index  = n4520_disk_index,
};

#define BOARD_N2520	0
#define BOARD_N4520	1

static int board_idx = 0;
static struct thecus_board board_info [] = {
	{ 0xf, "N2520", N2520_MAX_DISK, 17, 0, "800", "BOARD_N2520", &n2520_func, BOARD_N2520},
	{ 0xe, "N4520", N4520_MAX_DISK, 17, 0, "801", "BOARD_N4520", &n4520_func, BOARD_N4520},
	{ 0xd, "N2560", N2520_MAX_DISK, 17, 0, "802", "BOARD_N2520", &n2520_func, BOARD_N2520},
	{ 0xc, "N4560", N4520_MAX_DISK, 17, 0, "803", "BOARD_N4520", &n4520_func, BOARD_N4520},
	{ 0xb, "N2560", N2520_MAX_DISK, 17, 0, "804", "BOARD_N2520", &n2520_func, BOARD_N2520}, // N2560 v1.1 (with CPU fan)
	{ 0xa, "N4560", N4520_MAX_DISK, 17, 0, "805", "BOARD_N4520", &n4520_func, BOARD_N4520}, // N4560 v1.2 (with CPU fan)
	{ }
};

static int debug;;
module_param(debug, int, S_IRUGO | S_IWUSR);

static u32 keep_BUZZER = BUZZER_OFF;
static int sleepon_flag=0;

// SATA LED control array 
static u32 access_led[THECUS_MAS_DISK]={LED_OFF};
static u8 qc_cur[THECUS_MAS_DISK];          // record current qc state
static atomic_t qc_new[THECUS_MAS_DISK];    // record qc_cmd coming

static char keep_LCM_RAID[16];
static char keep_LCM_DATE[16];

// Note: Be careful the disk index since we don' have DOM on evansport
//	   platoform. Therefore the tray_id is in range 1~2 but port id is 0~1.
u32 n2520_disk_access(int index, int act)
{
	_DBG(1, "index %d: %d\n", index, act);

	// Map tray_id to port index;
	if (act >= LED_ENABLE)
		index--;

	//only handle N2520 MAX disk
	if ( (index < 0)||(index >= N2520_MAX_DISK) )
		return 1;

	// set enable or disable by tray_id
	switch(act){
	case LED_ENABLE:
		atomic_set(&qc_new[index], PM_LED_ON);
		access_led[index] = LED_ON;
		goto out;
		break;
	case LED_DISABLE:
		access_led[index] = LED_OFF;
		goto out;
		break;
	}

	// if LED is disabled, do nothing
	if (access_led[index] == LED_OFF)
		goto out;

	_DBG(1, "PM_GPIO_%d\n", N2520_PM_SATA_ACT(index));

	switch(act){
	case LED_ON:
		/*
		 * qc free; 
		 * since we use sata_led_routine() for qc coming blinking,
		 * do nothing here.
		 */
		break;
	case LED_OFF:
		// qc comes; set blink
		atomic_set(&qc_new[index], PM_LED_BLINK);
		break;
	}

out:
	return 0;
}

// tray_id = tindex + 1
u32 n2520_disk_index(int index, struct scsi_device *sdp)
{
	u32 tindex = index;

	if(strncmp(sdp->host->hostt->name,"ahci",strlen("ahci")) == 0){
		tindex = sdp->host->host_no;
		switch (tindex) {
		case 0: // disk 1
		case 1: // disk 2
			break;
		}
	}
	return tindex;
}

u32 n4520_disk_access(int index, int act)
{
	_DBG(1, "index %d: %d\n", index, act);
	// Map tray_id to port index;
	if (act >= LED_ENABLE)
		index--;

	//only handle N4520 MAX disk
	if ( (index < 0)||(index >= N4520_MAX_DISK) )
		return 1;

	// set enable or disable by tray_id
	switch(act){
	case LED_ENABLE:
		atomic_set(&qc_new[index], LED_ON);
		access_led[index] = LED_ON;
		goto out;
		break;
	case LED_DISABLE:
		access_led[index] = LED_OFF;
		goto out;
		break;
	}

	// if LED is disabled, do nothing
	if (access_led[index] == LED_OFF)
		goto out;

	_DBG(1, "GPIO_%d\n", PCA9532_N4520_SATA_ACT(index));

	switch(act){
	case LED_ON:
		/*
		 * qc free;
		 * since we use sata_led_routine() for qc coming blinking,
		 * do nothing here.
		 */
		break;
	case LED_OFF:
		// qc comes; set blink
		atomic_set(&qc_new[index], LED_BLINK1);
		break;
	}

out:
	return 0;
}

u32 n4520_disk_index(int index, struct scsi_device *sdp)
{
	u32 tindex = index;

	if((strncmp(sdp->host->hostt->name,"sata",strlen("sata")) == 0)||(strncmp(sdp->host->hostt->name,"ahci",strlen("ahci")) == 0)){
		tindex = sdp->host->host_no;
		switch (tindex) {
		case 0: // disk 1
		case 1: // disk 2
		case 2: // disk 3
		case 3: // disk 4
			break;
		}
	}
	return tindex;
}


static void reset_pic(void)
{
	u8 val;

	printk(KERN_INFO "RESET_PIC\n");
	pca9532_id_set_led(PCA9532_ID_AVR_RST, 0x1);
	udelay(60);
	pca9532_id_set_led(PCA9532_ID_AVR_RST, 0x0);

	val = 1;
	pic24fj128_write_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);
	msleep(1000);
	val = 2;
	pic24fj128_write_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);

	// restore previos value
	pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_DATE, keep_LCM_DATE, 16);
	msleep(100);
	pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_RAID, keep_LCM_RAID, 16);

}

static ssize_t proc_thecus_io_write(struct file *file,
                    const char __user * buf, size_t length, loff_t * ppos)
{
	char *buffer, buf1[20], item[20];
	int i, err, num, val1, val2;
	u8 status = 0;
	u8 val;

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
     * Usage: echo "<item> [<index>] <value>" > /proc/thecus_io
     *        value    0:Off; 1:On; 2:Blink;
     *        "S_LED 1-N 0|1|2"               * LED SATA 1-N ERROR led
     *        "A_LED 1-N 0|1|2"               * LED SATA 1-N ACTIVE led
     *        "U_LED 0|1|2"                   * USB BUSY led
     *        "UF_LED 0|1|2"                  * USB ERROR led
     *        "LOGO1_LED 0|1|2"               * LOGO1 led
     *        "LOGO2_LED 0|1|2"               * LOGO2 led
     *        "PWR_LED 0|1|2"                 * LED System Status
     *        "Fail 0|1"                      * LED System Fail
     *        "Busy 0|1"                      * LED System Busy
     *        "Buzzer 0|1"                    * Buzzer
     */
    /*
     * Usage: echo "PWR_S 2|3" >/proc/thecus_io                 * in linux/ in u-boot
     * Usage: echo "SYS 0|1|2" >/proc/thecus_io                 * Do power off/HReset/PCI reset
     * Usage: echo "LCM_DISPLAY 0|1" > /proc/thecus_io
     * Usage: echo "LCM_AUTO_OFF 0|1" > /proc/thecus_io              * 0:off,1:on
     * Usage: echo "LCM_HOSTNAME 16 bytes ascii string" > /proc/thecus_io
     * Usage: echo "LCM_WANIP 192.168.1.100" > /proc/thecus_io
     * Usage: echo "LCM_LANIP 192.168.2.254" > /proc/thecus_io
     * Usage: echo "LCM_RAID Healthy|Degrade|Damage|N/A" > /proc/thecus_io
     * Usage: echo "LCM_FAN 5000 RPM" > /proc/thecus_io
     * Usage: echo "LCM_TEMP 30" > /proc/thecus_io
     * Usage: echo "LCM_DATE 2006/12/23 23:14" > /proc/thecus_io
     * Usage: echo "LCM_UPTIME 12 min" > /proc/thecus_io
     * Usage: echo "LCM_MSG -Uupper -Llower -Ssec" > /proc/thecus_io
     * Usage: echo "LCM_USB 1|2|3|4|5" > /proc/thecus_io          * usb copy, Nothing|Coping|Success|Fail|No Device
     * Usage: echo "RESET_PIC" > /proc/thecus_io                *
     * Usage: echo "BTN_OP 1|2|3|4" > /proc/thecus_io           * 1:UP,2:DOWN,3:ENTER,4:ESC
     * Usage: echo "PIC_FAC 0|1" > /proc/thecus_io              * 0:normal,1:factory
     * Usage: echo "LCM_BANNER 11111111" > /proc/thecus_io              * 8bits represent: Hostname, WAN, LAN, RAID, FAN, TEMP, DATE, UPTime
     */

	i = sscanf(buffer, "%s %d %d\n", item, &val1, &val2);
	if (i == 3){
		num = val1;
		status = val2;
	} else if(i == 2){
		status = val1;
	}

	switch(status){
	case 0: status = LED_OFF;
		break;
	case 1: status = LED_ON;
		break;
	case 2: status = LED_BLINK1;
		break;
	}

	if (i > 1)
		_DBG(3, "input %s %d\n", item, status);

	if (!strncmp(item, "S_LED", strlen("S_LED"))){
		if (i != 3) goto parse_done;
		if (num > 0 && num <= board_info[board_idx].max_tray)
			pca9532_set_led(PCA9532_SATA_ERR(num), status);

	} else if (!strncmp(item, "A_LED", strlen("A_LED"))){
		if (i != 3) goto parse_done;
		board_info[board_idx].func->disk_access(num, status);

	} else if (!strncmp(item, "U_LED", strlen("U_LED"))){
		if (i != 2) goto parse_done;
		pca9532_id_set_led(PCA9532_ID_USB_ACT, status);

	} else if (!strncmp(item, "UF_LED", strlen("UF_LED"))){
		if (i != 2) goto parse_done;
		pca9532_id_set_led(PCA9532_ID_USB_ERR, status);

	} else if (!strncmp(item, "LOGO1_LED", strlen("LOGO1_LED"))){
		if (i != 2) goto parse_done;
		// revise ON/OFF level
		if (status == LED_ON)
			status = PWR_LED_ON;
		else if (status == LED_OFF)
			status = PWR_LED_OFF;
		pca9532_set_led(PCA9532_TLOGO_1, status);

	} else if (!strncmp(item, "LOGO2_LED", strlen("LOGO2_LED"))){
		if (i != 2) goto parse_done;
		// revise ON/OFF level
		if (status == LED_ON)
			status = PWR_LED_ON;
		else if (status == LED_OFF)
			status = PWR_LED_OFF;
		pca9532_set_led(PCA9532_TLOGO_2, status);

	} else if (!strncmp(item, "PWR_LED", strlen("PWR_LED"))){
		if (i != 2) goto parse_done;

		// revise ON/OFF level
		if (status == LED_ON)
			status = PWR_LED_ON;
		else if (status == LED_OFF)
			status = PWR_LED_OFF;

		/*
		 * For N2520, SYS_BUSY is PWR_LED;
		 * For N4520, power LED controlling actually is no use.
		 */
		switch (board_info[board_idx].board){
		case BOARD_N2520:
			pca9532_id_set_led(PCA9532_ID_SYS_BUSY, status);
			break;
		case BOARD_N4520:
			pca9532_id_set_led(PCA9532_ID_SYS_STATUS, status);
			break;
		}

	} else if (!strncmp(item, "Busy", strlen("Busy"))){
		if (i != 2) goto parse_done;
		/*
		 * Busy is information LED only for diagnostic mode.
		 * For N2520, it is SYS_STATUS.
		 * For N4520, it is SYS_BUSY.
		 */
		switch (board_info[board_idx].board){
		case BOARD_N2520:
			pca9532_id_set_led(PCA9532_ID_SYS_STATUS, status);
			break;
		case BOARD_N4520:
			pca9532_id_set_led(PCA9532_ID_SYS_BUSY, status);
			break;
		}

	} else if (!strncmp(item, "Fail", strlen("Fail"))){
		if (i != 2) goto parse_done;
		pca9532_id_set_led(PCA9532_ID_SYS_ERR, status);

	} else if (!strncmp(item, "Buzzer", strlen("Buzzer"))){
		if (i != 2) goto parse_done;
		if (val1 == 0)	//input 0: want to turn off
			val = 0;
		else
			val = 1;

		keep_BUZZER = val;
		pca9532_set_led(PCA9532_BEEP, val);
 
	} else if (board_info[board_idx].board == BOARD_N4520){
		 if (!strncmp(buffer, "LCM_DISPLAY", strlen("LCM_DISPLAY"))) {
			if (i != 2) goto parse_done;
			val = val1;
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_DISPLAY, &val, 1);

		}else if (!strncmp(buffer, "LCM_AUTO_OFF", strlen("LCM_AUTO_OFF"))) {
			if (i != 2) goto parse_done;
			if (val1 == 0)	//input 0: want to turn off
				lcm_off_count = -1;
			else
				lcm_off_count = 0;

		} else if (!strncmp(buffer, "LCM_HOSTNAME", strlen("LCM_HOSTNAME"))) {
			strncpy(buf1, buffer + strlen("LCM_HOSTNAME") + 1, 16);
			_DBG(3, "LCM_HOSTNAME %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_HOSTNAME, buf1, 16);

		} else if (!strncmp(buffer, "LCM_WANIP", strlen("LCM_WANIP"))) {
			strncpy(buf1, buffer + strlen("LCM_WANIP") + 1, 16);
			_DBG(3, "LCM_WANIP %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_WAN_IP, buf1, 16);

		} else if (!strncmp(buffer, "LCM_LANIP", strlen("LCM_LANIP"))) {
			strncpy(buf1, buffer + strlen("LCM_LANIP") + 1, 16);
			_DBG(3, "LCM_LANIP %s\n", buf1);
			if (0 == strlen(buf1))
				strncpy(buf1, "N/A", 3);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_LAN_IP, buf1, 16);

		} else if (!strncmp(buffer, "LCM_RAID", strlen("LCM_RAID"))) {
			strncpy(buf1, buffer + strlen("LCM_RAID") + 1, 16);
			_DBG(3, "LCM_RAID %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			strncpy(keep_LCM_RAID, buf1, 16);
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_RAID, buf1, 16);

		} else if (!strncmp(buffer, "LCM_FAN", strlen("LCM_FAN"))) {
			strncpy(buf1, buffer + strlen("LCM_FAN") + 1, 16);
			_DBG(3, "LCM_FAN %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_FAN, buf1, 16);

		} else if (!strncmp(buffer, "LCM_TEMP", strlen("LCM_TEMP"))) {
			if (i != 2) goto parse_done;
			_DBG(3, "LCM_TEMP %d\n", val1);
			sprintf(buf1, "%d %cC / %d %cF", val1, 0xDF, val1 * 9 / 5 + 32, 0xDF);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_TEMP, buf1, 16);

		} else if (!strncmp(buffer, "LCM_DATE", strlen("LCM_DATE"))) {
			strncpy(buf1, buffer + strlen("LCM_DATE") + 1, 16);
			_DBG(3, "LCM_DATE %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			strncpy(keep_LCM_DATE, buf1, 16);
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_DATE, buf1, 16);

		} else if (!strncmp(buffer, "LCM_MSG", strlen("LCM_MSG"))) {
			char *p_upper = NULL, *p_lower = NULL, *p_sec = NULL;
			char buf2[20];
			u8 sec = 0;
			_DBG(3, "%s\n", buffer);
			memset(buf2, 0, sizeof(buf2));
			p_upper = strstr(buffer + strlen("LCM_MSG") + 1, "-U");
			if (p_upper != NULL) {
				p_upper += 2;
				p_lower = strstr(p_upper, "-L");
				if (p_lower != NULL) {
					p_sec = strstr(p_lower, "-S");
					if ((p_upper != NULL) && (p_lower != NULL)&& (p_sec != NULL)) {
						*p_lower = '\0';
						p_lower += 2;
						*p_sec = '\0';
						p_sec += 2;
						strncpy(buf1, p_upper, 16);
						for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
							if (buf1[i] == 0)
								buf1[i] = ' ';
						}
						pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_MSG_UPPER, buf1, 16);
						strncpy(buf2, p_lower, 16);
						for (i = strlen(buf2); i < sizeof(buf2) - 1; i++) {
							if (buf2[i] == 0)
								buf2[i] = ' ';
						}
						mdelay(300);
						pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_MSG_LOWER, buf2, 16);
						val1 = 0;
						i = sscanf(p_sec, "%d\n", &val1);
						sec = (u8) val1;
						mdelay(300);
						pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_MSG_TIME, &sec, 1);
						mdelay(300);
					}
				}
			}

		} else if (!strncmp(buffer, "LCM_UPTIME", strlen("LCM_UPTIME"))) {
			strncpy(buf1, buffer + strlen("LCM_UPTIME") + 1, 16);
			_DBG(3, "LCM_UPTIME %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_UPTIME, buf1, 16);

		} else if (!strncmp(buffer, "LCM_USB", strlen("LCM_USB"))) {
			if (i != 2) goto parse_done;
			val = val1+100;
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_USB, &val, 1);

		} else if (!strncmp(buffer, "PWR_S", strlen("PWR_S"))) {
			if (i != 2) goto parse_done;
			val = val1;
			pic24fj128_write_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);

		} else if (!strncmp(buffer, "SYS", strlen("SYS"))) {
			if (i != 2) goto parse_done;
			val = val1;
			pic24fj128_write_regs(THECUS_PIC24FJ128_SYS, &val, 1);

		} else if (!strncmp(buffer, "BTN_OP", strlen("BTN_OP"))) {
			if (i != 2) goto parse_done;
			val = val1;
			pic24fj128_write_regs(THECUS_PIC24FJ128_BTN_OP, &val, 1);

		} else if (!strncmp(item, "RESET_PIC", strlen("RESET_PIC"))){
			reset_pic();
		} else if (!strncmp(buffer, "LCM_BANNER", strlen("LCM_BANNER"))) {
			strncpy(buf1, buffer + strlen("LCM_BANNER") + 1, 16);
			_DBG(3, "LCM_BANNER %s\n", buf1);
			for (i = strlen(buf1); i < sizeof(buf1) - 1; i++) {
				if (buf1[i] == 0)
					buf1[i] = ' ';
			}
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_BANNER, buf1, 16);
		}
	}

parse_done:

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
	seq_printf(m, "MBTYPE: %s\n", board_info[board_idx].mb_type);

	seq_printf(m, "MAX_TRAY: %d\n", board_info[board_idx].max_tray);
	seq_printf(m, "eSATA_TRAY: %d\n", board_info[board_idx].eSATA_tray);
	seq_printf(m, "eSATA_COUNT: %d\n", board_info[board_idx].eSATA_count);
	
	seq_printf(m, "FAC_MODE: OFF\n");
	seq_printf(m, "WOL_FN: %d\n", 1);
	seq_printf(m, "FAN_FN: %d\n", 1);
	seq_printf(m, "BEEP_FN: %d\n", 1);
	seq_printf(m, "eSATA_FN: %d\n", 1);

	val = pca9532_id_get_input(PCA9532_ID_USB_COPY_BTN);
	if(val >= 0) seq_printf(m,"Copy button: %s\n", val?"OFF":"ON");

	val = pca9532_id_get_led(PCA9532_ID_USB_ACT);
	seq_printf(m, "U_LED: %s\n", LED_STATUS[val]);

	val = pca9532_id_get_led(PCA9532_ID_USB_ERR);
	seq_printf(m, "UF_LED: %s\n", LED_STATUS[val]);

	/*
	 * For N2520, SYS_BUSY is PWR_LED;
	 * For N4520, power LED is always ON. (can't be controlled by SW)
	 */
	switch(board_info[board_idx].board){
	case BOARD_N2520:
		val = pca9532_id_get_led(PCA9532_ID_SYS_BUSY);
		if (val == PWR_LED_ON) val = LED_ON;
		else if (val == PWR_LED_OFF) val = LED_OFF;
		break;
	case BOARD_N4520:
		val = LED_ON;
		break;
	}
	seq_printf(m, "LED_Power: %s\n", LED_STATUS[val]);

	/*
	 * Busy is information LED only for diagnostic mode.
	 * For N2520, it is SYS_STATUS.
	 * For N4520, it is SYS_BUSY.
	 */
	switch(board_info[board_idx].board){
	case BOARD_N2520:
		val = pca9532_id_get_led(PCA9532_ID_SYS_STATUS);
		break;
	case BOARD_N4520:
		val = pca9532_id_get_led(PCA9532_ID_SYS_BUSY);
		break;
	}
	seq_printf(m, "LED_Busy: %s\n", LED_STATUS[val]);

	seq_printf(m, "Buzzer: %s\n", keep_BUZZER ? "ON" : "OFF");

	switch(board_info[board_idx].board){
	case BOARD_N2520:
		picuart_read_gpio(13, &val);
		seq_printf(m, "PM_GPIO13: %s\n", val ? "HIGH" : "LOW");

		picuart_read_gpio(14, &val);
		seq_printf(m, "PM_GPIO14: %s\n", val ? "HIGH" : "LOW");

		picuart_read_gpio(17, &val);
		seq_printf(m, "PM_GPIO17: %s\n", val ? "HIGH" : "LOW");
		break;
	case BOARD_N4520:
		pic24fj128_get_regs(THECUS_PIC24FJ128_VERSION, &val, 1);//0x6
		seq_printf(m, "PIC_VER: %d\n", val);

		pic24fj128_get_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);//0x5
		seq_printf(m, "PWR_S: %d\n", val);

		pic24fj128_get_regs(THECUS_PIC24FJ128_LCM_DISPLAY, &val, 1);//0x7
		seq_printf(m, "LCM_DISPLAY: %d\n", val);
		seq_printf(m, "LCM_AUTO_OFF: %s\n", lcm_off_count>=0 ? "ON" : "OFF");

#ifdef DEBUG
		val = pca9532_id_get_input(PCA9532_ID_PIC_GPO_0);
		seq_printf(m, "PIC_GPO_0: %s\n", LED_STATUS[val]);
		pic24fj128_get_regs(THECUS_PIC24FJ128_INT_STATUS, &val, 1);//0x19
		seq_printf(m, "INT_S: %d\n", val);
#endif
		break;
	}

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
#define MESSAGE_LENGTH 80
#define MY_WORK_QUEUE_NAME "board_wq"    // length must < 10
#define WORK_QUEUE_TIMER_1 250
#define WORK_QUEUE_TIMER_2 50
static DECLARE_WAIT_QUEUE_HEAD(thecus_event_queue);
static char Message[MESSAGE_LENGTH];
static int module_die = 0;    /* set this to 1 for shutdown */
static u32 dyn_work_queue_timer = WORK_QUEUE_TIMER_2;
static struct workqueue_struct *my_workqueue;
static void intrpt_routine(struct work_struct *unused);
static void sata_led_routine(struct work_struct *ws);
static DECLARE_DELAYED_WORK(btn_sched, intrpt_routine);
static DECLARE_WORK(sata_work, sata_led_routine);

static void intrpt_routine(struct work_struct *unused)
{
	u8 val = 0;

	// send event while button is pressed. 'ON' means 'pressed'.
	if (board_info[board_idx].board == BOARD_N2520){
		val = pca9532_id_get_input(PCA9532_ID_USB_COPY_BTN);
		if(val == 0) {
			sprintf(Message, "Copy ON\n");
			_DBG(2, "Copy ON\n");
			wake_up_interruptible(&thecus_event_queue);
		}
	}

	val = pca9532_id_get_input(PCA9532_ID_SOFT_RST);
	if(val == 0) {
		if (rst_btn_count == 10){
			sprintf(Message, "RST2DF ON\n");
			_DBG(2, "RST2DF ON\n");
			wake_up_interruptible(&thecus_event_queue);
			rst_btn_count = 0;
		} else
			rst_btn_count++;
	} else
		rst_btn_count = 0;

	picuart_read_gpio(PM_PWR_BTN, &val);
	if (val == 0) {
		switch(board_info[board_idx].board){
		case BOARD_N4520:
			_DBG(2, "PM_PWR_BTN ON\n");
			val = 5;
			pic24fj128_write_regs(THECUS_PIC24FJ128_BTN_OP, &val, 1);
			break;
		case BOARD_N2520:
			if (pwr_btn_count == 10){
				sprintf(Message, "PWR ON\n");
				wake_up_interruptible(&thecus_event_queue);
				pwr_btn_count = 0;
			} else
				pwr_btn_count++;
			break;
		}
	} else
		pwr_btn_count = 0;


	if (0 == pca9532_id_get_input(PCA9532_ID_AVR_RST)) {
		if (avr_btn_count == 10){
			sprintf(Message, "RESET_PIC ON\n");
			_DBG(2, "RESET_PIC ON\n");
			wake_up_interruptible(&thecus_event_queue);
			avr_btn_count = 0;
		} else
			avr_btn_count++;
	} else
		avr_btn_count = 0;
	
	
	if (0 == pca9532_id_get_input(PCA9532_ID_PIC_GPO_0)) {
		_DBG(2, "PIC_GPO_0 ON\n");
	}

	if (board_info[board_idx].board == BOARD_N4520){
		if (lcm_off_count >= 720){//3 minutes
			val = 0;
			pic24fj128_write_regs(THECUS_PIC24FJ128_LCM_DISPLAY, &val, 1);
			_DBG(2, "LCM SCHED OFF\n");
			lcm_off_count = 0;
		} else {
			if (lcm_off_count >= 0)
				lcm_off_count++;
		}

		if(!pic24fj128_get_regs(THECUS_PIC24FJ128_INT_STATUS, &val, 1)){

			if(val == THECUS_PIC24FJ128_INT_POWER) {
				if (lcm_off_count >= 0)
					lcm_off_count = 0;
				sprintf(Message, "PWR ON\n");
				_DBG(2, "PWR ON\n");
				wake_up_interruptible(&thecus_event_queue);
			}
		
			if(val == THECUS_PIC24FJ128_INT_USB) {
				if (lcm_off_count >= 0)
					lcm_off_count = 0;
				sprintf(Message, "Copy ON\n");
				_DBG(2, "Copy ON\n");
				wake_up_interruptible(&thecus_event_queue);
			}

			if (val != 255) {
				_DBG(2, "INT_S: %d\n", val);
			}
		}

		if (!isEmptyQ()) {
			struct rec *tmp;
			if (isFullQ()) {	// reset pic
				printk(KERN_INFO "THECUS_QUEUE full do reset pic\n");
				pca9532_id_set_led(PCA9532_ID_AVR_RST, 0x1);
				udelay(60);
				pca9532_id_set_led(PCA9532_ID_AVR_RST, 0x0);
				val = 1;
				pic24fj128_write_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);
				msleep(1000);
				val = 2;
				pic24fj128_write_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);
			}

			tmp = removeQ();
			if (NULL != tmp) {
				if (1 == pic24fj128_write_regs(tmp->reg_num, tmp->val, tmp->size)) {
					dyn_work_queue_timer = WORK_QUEUE_TIMER_1 * 5;
					printk("pic24fj128_write_regs err set dyn_work_queue_timer to %d\n", dyn_work_queue_timer);
				}
			}
		}
	}


	// keep intrp_routine queueing itself
	if (module_die == 0)
		queue_delayed_work(my_workqueue, &btn_sched, dyn_work_queue_timer);

}

/*
 * This routine is for picuart/pca9532 which are very low-speed devices to
 * control LED blink action when there is qc coming instead of pulling LED
 * on/off in disk_access() immediately.
 */
static void sata_led_routine(struct work_struct *ws)
{
	int i;
	u8 act;
	u8 max_disk = 0, sata_led_on = 1, sata_led_off = 0;

	switch(board_info[board_idx].board){
	case BOARD_N2520:
		max_disk = N2520_MAX_DISK;
		sata_led_on = PM_LED_ON;
		sata_led_off = PM_LED_OFF;
		break;
	case BOARD_N4520:
		max_disk = N4520_MAX_DISK;
		sata_led_on = LED_ON;
		sata_led_off = LED_OFF;
		break;
	}

	// only handle model MAX disk amount
	for (i = 0; i < max_disk; i++){
		switch(access_led[i]){
		case LED_ON:
			act = atomic_read(&qc_new[i]);
			/* reset to idle mode for qc_free */
			switch(board_info[board_idx].board){
			case BOARD_N2520:
				atomic_set(&qc_new[i], sata_led_on);
				break;
			case BOARD_N4520:
			/*
			 * Since N4520 has individual link LED, it doesn't
			 * need to bright the access LED while idling.
			 */
				atomic_set(&qc_new[i], sata_led_off);
				break;
			}

			break;
		case LED_OFF:
			act = sata_led_off;
			break;
		}

		// only set LED while status has changed
		if(qc_cur[i] != act){
			switch(board_info[board_idx].board){
			case BOARD_N2520:
				picuart_write_gpio(N2520_PM_SATA_ACT(i), act);
				break;
			case BOARD_N4520:
				pca9532_set_led(PCA9532_N4520_SATA_ACT(i), act);
				break;
			}
			qc_cur[i] = act;
		}
	}

	msleep(50);
	// keep work routine queueing itself
	if (!module_die)
		queue_work(my_workqueue, &sata_work);
}

// ----------------------------------------------------------
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


static int sys_notify_reboot(struct notifier_block *nb, unsigned long event,
                                void *p)
{
	u8 val;
	/*
	 * Power off behavior
	 * Power LED    N2520 only -->SYS_BUSY:                 BLINK.
	 * Info LED     N2520-->SYS_STATUS N4520-->SYS_BUSY:    OFF.
	 * ERR LED      (N4520 only):                           OFF.
	 * TLOGO        (N2520 only):                           BLINK.
	 * Other BUSY/ERR LEDs (N2520 only):                    OFF.
	 */
	switch(board_info[board_idx].board){
	case BOARD_N2520:
		pca9532_id_set_led(PCA9532_ID_SYS_STATUS, LED_OFF);
		pca9532_id_set_led(PCA9532_ID_SYS_BUSY, LED_BLINK1);
		pca9532_set_led(PCA9532_TLOGO_1, LED_BLINK1);
		pca9532_set_led(PCA9532_TLOGO_2, LED_BLINK1);
		pca9532_id_set_led(PCA9532_ID_USB_ACT, LED_OFF);
		pca9532_id_set_led(PCA9532_ID_USB_ERR, LED_OFF);
		break;
	case BOARD_N4520:
		pca9532_id_set_led(PCA9532_ID_SYS_STATUS, LED_BLINK1);
		pca9532_id_set_led(PCA9532_ID_SYS_BUSY, LED_OFF);
		pca9532_id_set_led(PCA9532_ID_SYS_ERR, LED_OFF);
		
		switch (event) {
		case SYS_RESTART:
			val = THECUS_PIC24FJ128_SYS_PWR_HRESET;
			pic24fj128_write_regs(THECUS_PIC24FJ128_SYS, &val, 1);
			break;
		case SYS_HALT:
		case SYS_POWER_OFF:
			val = THECUS_PIC24FJ128_SYS_PWR_OFF;
			pic24fj128_write_regs(THECUS_PIC24FJ128_SYS, &val, 1);
			break;
		}

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
	int ret;
	struct proc_dir_entry *pde;
	u32 board_num = 0, n = 0;
	unsigned int id;
	// TODO: initialize USB power enable
	/*
	 * struct pci_dev *pdev = pci_get_device(PCI_VENDOR_ID_INTEL, PCI_INTELCE_GPIO_DEVICE_ID, NULL);
	 * struct intelce_gpio_chip *c = pci_get_drvdata(pdev);
	 */

	// check if this platform is N2520 family (IntelCE series)
	intelce_get_soc_info(&id, NULL);
	if (id != CE5300_SOC_DEVICE_ID) 
		return -ENODEV;

	board_num = pca9532_id_get_register(0) & PCA9532_ID_MBID;

	printk(KERN_INFO "thecus_io: board_num: %Xh\n", board_num);
	for (n = 0; board_info[n].board_string; n++)
		if (board_num == board_info[n].gpio_num) {
			board_idx = n;
			printk(KERN_INFO "board_idx %d\n", board_idx);
			break;
		}

	thecus_board_register(&board_info[board_idx]);

	// Reset phy by PM_GPIO_20, for a complete PHY reset, this pin must
	// be asserted low for at least 10ms.
	picuart_write_gpio(PM_PHY_RST, 0);
	udelay(10000);
	picuart_write_gpio(PM_PHY_RST, 1);

	/*
	 * Booting behavior
	 * Power LED    N2520 only -->SYS_BUSY:                 BLINK.
	 * Info LED     N2520-->SYS_STATUS N4520-->SYS_BUSY:    OFF.
	 * ERR LED      (N4520 only):                           OFF.
	 * TLOGO        (N520 only):                            BLINK.
	 * Other BUSY/ERR LEDs (N2520 only):                    OFF.
	 */ 
	switch(board_info[board_idx].board){
	case BOARD_N2520:
		// set LEDs
		pca9532_id_set_led(PCA9532_ID_SYS_STATUS, LED_OFF);
		pca9532_id_set_led(PCA9532_ID_SYS_BUSY, LED_BLINK1);
		pca9532_set_led(PCA9532_TLOGO_1, LED_BLINK1);
		pca9532_set_led(PCA9532_TLOGO_2, LED_BLINK1);
		pca9532_id_set_led(PCA9532_ID_USB_ACT, LED_OFF);
		pca9532_id_set_led(PCA9532_ID_USB_ERR, LED_OFF);
		// get current SATA LED
		for (n = 0; n < N2520_MAX_DISK; n++)
			picuart_read_gpio(N2520_PM_SATA_ACT(n), &qc_cur[n]);
		break;
	case BOARD_N4520:
		// N4520: initialize PIC24
		pca9532_id_set_led(PCA9532_ID_AVR_RST, 0);
		// set LEDs
		pca9532_id_set_led(PCA9532_ID_SYS_STATUS, LED_BLINK1);
		pca9532_id_set_led(PCA9532_ID_SYS_BUSY, LED_OFF);
		pca9532_id_set_led(PCA9532_ID_SYS_ERR, LED_OFF);
		// get current SATA LED
		for (n = 0; n < N4520_MAX_DISK; n++)
			qc_cur[n] = pca9532_get_led(PCA9532_N4520_SATA_ACT(n));
		break;
	}

	// create thecus_io and theucs_event proc nodes
	pde = create_proc_entry("thecus_io", 0, NULL);
	if (!pde) {
		printk(KERN_ERR "thecus_io: cannot create /proc/thecus_io.\n");
		ret = -ENOENT;
		goto io_out;
	}
	pde->proc_fops = &proc_thecus_io_operations;

	pde = create_proc_entry("thecus_event", S_IRUSR, NULL);
	if (!pde) {
		printk(KERN_ERR "thecus_io: cannot create /proc/thecus_event.\n");
		ret = -ENOENT;
		goto event_out;
	}
	pde->proc_fops = &proc_thecus_event_operations;

	// add our work queue
	my_workqueue = create_workqueue(MY_WORK_QUEUE_NAME);
	if (my_workqueue) {
		queue_delayed_work(my_workqueue, &btn_sched, dyn_work_queue_timer);
		// need a routine thread for SATA ACT_LED
		queue_work(my_workqueue, &sata_work);
			
		init_waitqueue_head(&thecus_event_queue);
	} else {
		printk(KERN_ERR "thecus_io: error in thecus_io_init\n");
		ret = -ENOENT;
		goto wq_out;
	}

	register_reboot_notifier(&sys_notifier_reboot);

	return 0;

wq_out:
	remove_proc_entry("thecus_event", NULL);
event_out:
	remove_proc_entry("thecus_io", NULL);
io_out:
	thecus_board_unregister(&board_info[board_idx]);
	return ret;
}

static __exit void thecus_io_exit(void)
{
	module_die = 1;                     // If cleanup wants us to die 
	cancel_delayed_work(&btn_sched);    // no "new ones" 
	flush_workqueue(my_workqueue);      // wait till all "old ones" finished 
	destroy_workqueue(my_workqueue);

	remove_proc_entry("thecus_io", NULL);
	remove_proc_entry("thecus_event", NULL);

	unregister_reboot_notifier(&sys_notifier_reboot);

	thecus_board_unregister(&board_info[board_idx]);

}

MODULE_AUTHOR("Zeno Lai <zeno_lai@thecus.com>");
MODULE_DESCRIPTION("Thecus N2520 MB Driver and board depend io operation");
MODULE_LICENSE("GPL");
module_init(thecus_io_init);
module_exit(thecus_io_exit);
