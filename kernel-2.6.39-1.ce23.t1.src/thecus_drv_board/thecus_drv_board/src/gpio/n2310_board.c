/*
 *  Copyright (C) 2013 Thecus Technology Corp. 
 *
 *      Maintainer: Zeno Lai <zeno_lai@thecus.com>
 *                  Cobalt Chang <cobalt_chang@thecus.com>
 *
 *      Driver for Thecus N2310/N4310 board's I/O
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */

#include <linux/kcompat.h>
#include "thecus_board.h"

#include <asm/ipp.h>
#include <linux/gpio.h>
#include <linux/pwm/pwm.h>
#include <linux/libata.h>

// GPIO pin assignment
#define APM_GPIO(i)                (204+(i))
#define APM_GPIO_DS(i)             (178+(i))

// 4 bits ID GPIO[3:0]
#define GPIO_MBID(i)               (APM_GPIO(0)+(i))

#define GPIO_SYS_STATUS             APM_GPIO(8)
#define GPIO_SYS_ERR                APM_GPIO(9)
#define N2310_GPIO_PWR              APM_GPIO(10)
#define N2310_GPIO_PWR_ERR          APM_GPIO(11)	// unused
#define GPIO_USB_ACT                APM_GPIO(12)
#define GPIO_USB_ERR                APM_GPIO(13)
#define N2310_GPIO_PWR_CTRL         APM_GPIO(17)	// unused
/*
 * SATA Error       GPIO
 *    HDD0           30
 *    HDD1           32
 *    HDD2           28
 *    HDD3           37
 */
/*
 * if ( i==2 )
 *     echo APM_GPIO(28)
 * elseif ( i==3 )
 *     echo APM_GPIO(37)
 * else
 *     echo APM_GPIO(30)+i*2
 */
#define SATA_ERR(i)                (((i)==2)?(APM_GPIO(28)):(((i)==3)?(APM_GPIO(37)):(APM_GPIO(30)+((i)*2))))
/*
 * SATA Act         GPIO
 *    HDD0           31
 *    HDD1           33
 *    HDD2           29
 *    HDD3           38
 */
#define SATA_ACT(i)                (((i)==2)?(APM_GPIO(29)):(((i)==3)?(APM_GPIO(38)):(APM_GPIO(31)+((i)*2))))
#define GPIO_USB_COPY_BTN(i)       (((i)==(BOARD_N4310))?(APM_GPIO(23)):(APM_GPIO(34)))
#define GPIO_SOFT_RST               APM_GPIO(35)
#define N2310_GPIO_SATA_PWR(i)     (APM_GPIO(37)+(i))	// unused
/* if ( i==1 )
 *     echo APM_GPIO(41)
 * else if ( i==0 )
 *     echo APM_GPIO(42) */

// GPIO_DS
#define N2310_GPIO_PWR_BTN          APM_GPIO_DS(5)
#define N4310_PWR_ADAPTER_A         APM_GPIO_DS(16)
#define N4310_PWR_ADAPTER_B         APM_GPIO_DS(17)

//------------------------------------------------------------------------
/*
 * led_blink function only supports HDD white/red leds and USB copy white led
 * 0: SATA_ERR 2;	1: SATA_ACT 2
 * 2: SATA_ERR 0;	3: SATA_ACT 0
 * 4: SATA_ERR 1;	5: SATA_ACT 1
 * 6: SATA_ERR 3;	7: SATA_ACT 3
 * 9: USB_ACT
 */
extern int start_led_blink(unsigned int led);
extern int stop_led_blink(unsigned int led, unsigned int state);
extern struct pwm_channel *buzzer_request(int chan, const char *requester);
struct pwm_channel *buzzer = NULL;
const char *BREQUESTER = "sysfs";
#define BUZZER_CH  0
#define BPERIOD    1000000
#define BDUTY      500000

enum buzzer_opts {
	_status,
	_period,
	_duty
};

extern int mcu_poweroff_command(u8 option);
extern int mcu_set_power_status(u8 status);
extern int mcu_set_buzzer(u16 period, u16 duty);
#define BPERIOD_N4310 5000
#define BDUTY_N4310   2500

/*
 * apm gpio get callback function will return 'reg & bit_mask' value
 * directly, not the specified bit value, therefore we convert it to
 * single bit value here.
 */
#define apm867xx_read_gpio(a)        ((gpio_get_value((a))) ? 1 : 0)
void apm867xx_write_gpio(uint8_t pin, uint8_t val){
	/*
	 * GPIO - SATA_ERR(2)
	 * HDD0: 235 - 232 = 3
	 * HDD1: 237 - 232 = 5
	 * HDD2: 233 - 232 = 1
	 * HDD3: 242 - 235 = 7
	 */
	switch (val){
	case LED_ON:
	case LED_OFF:
		if (pin >= SATA_ERR(2) && pin <= SATA_ACT(1))
			stop_led_blink((pin - SATA_ERR(2)), val);
		else if (pin >= SATA_ERR(3) && pin <= SATA_ACT(3))
			stop_led_blink((pin - 235), val);
		else if (pin == GPIO_USB_ACT)
			stop_led_blink(9, val);
		gpio_set_value(pin, val);
		break;
	case LED_BLINK1:
		// by HW design, PWR_LED will blink while level is low.
		if (pin == N2310_GPIO_PWR)
			gpio_set_value(pin, LED_OFF);
		else if (pin >= SATA_ERR(2) && pin <= SATA_ACT(1))
			start_led_blink((pin - SATA_ERR(2)));
		else if (pin >= SATA_ERR(3) && pin <= SATA_ACT(3))
			start_led_blink((pin - 235));
		else if (pin == GPIO_USB_ACT)
			start_led_blink(9);
		break;
	}
}

//------------------------------------------------------------------------
// Model configuration
#define N2310_MAX_DISK                 2
#define N4310_MAX_DISK                 4

#define THECUS_MAX_DISK                16

#define DEBUG                          0

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (x<=DEBUG) printk("%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

int rst_btn_count = 0;
int pwr_btn_count = 0;
//int avr_btn_count = 0;
//int lcm_off_count = 0;

u32 n2310_disk_access(int index, int act);
u32 n2310_disk_index(int index, struct scsi_device *sdp);
u32 n4310_disk_access(int index, int act);
u32 n4310_disk_index(int index, struct scsi_device *sdp);
static int set_pwr_led_by_model(u8 board_model, u8 status);
static int get_pwr_led_by_model(u8 board_model);
static int set_buzzer_by_model(u8 board_model, u8 action, int value);
static int get_buzzer_by_model(u8 board_model, u8 action);

static const struct thecus_function n2310_func = {
	.disk_access = n2310_disk_access,
	.disk_index  = n2310_disk_index,
};

static const struct thecus_function n4310_func = {
	.disk_access = n4310_disk_access,
	.disk_index  = n4310_disk_index,
};

static int board_idx = 0;
static struct thecus_board board_info [] = {
	{ 0x0, "N2310", N2310_MAX_DISK, 17, 0, "900", "BOARD_N2310", &n2310_func, BOARD_N2310},
	{ 0x1, "N4310", N4310_MAX_DISK, 17, 0, "901", "BOARD_N4310", &n4310_func, BOARD_N4310},
	{ }
};

static int debug;;
module_param(debug, int, S_IRUGO | S_IWUSR);

static u8 power_status_n4310 = 0;
static u32 keep_BUZZER = BUZZER_OFF;
static u8 sys_alarm = 0;
static u16 buzzer_period_n4310 = BPERIOD_N4310;
static u16 buzzer_duty_n4310 = BDUTY_N4310;
static u32 usb_access_led = LED_OFF;
static u32 sys_status_led = LED_OFF;
static int sleepon_flag = 0;

/* Dual power detection flag
 * 1 : To raise the alarm when lost one of the power sources;
 * 0 : To do nothing, defualt is 0.
 */
static u8 dual_power_detection = 0;

/* To avoid access of bad area, the value is set to 0 */
static u8 max_disk = 0;

/* Exclusive between white and red LEDs */
static u32 sata_err_sts[THECUS_MAX_DISK] = {LED_OFF};
/* SATA LED control array */
static u32 access_led[THECUS_MAX_DISK] = {LED_OFF};

static u8 qc_cur[THECUS_MAX_DISK];
static atomic_t qc_new[THECUS_MAX_DISK];

u32 thecus_disk_led_control(struct ata_port *ap, struct ata_queued_cmd *qc, int act)
{
	if (!ap->scsi_host)
		goto out;
	if (!qc->dev || !qc->dev->sdev)
		goto out;

	switch(board_info[board_idx].board) {
	case BOARD_N2310:
		n2310_disk_access(ap->scsi_host->host_no, act);
		break;
	case BOARD_N4310:
		/*
		 * The variable channel is used for port mapping in N4310.
		 * The disk index of N4310 is the host_no in reverse order plus channel.
		 *     host_no: 1    +-- channel: 0    => disk index: 0
		 *                   |
		 *                   +-- channel: 1    => disk index: 1
		 *
		 *     host_no: 0    +-- channel: 0    => disk index: 2
		 *                   |
		 *                   +-- channel: 1    => disk index: 3
		 */
		switch(ap->scsi_host->host_no) {
		case 0:
			n4310_disk_access(2 + qc->dev->sdev->channel, act);
			break;
		case 1:
			n4310_disk_access(qc->dev->sdev->channel, act);
			break;
		}
		break;
	}

out:
	return 0;
}
EXPORT_SYMBOL(thecus_disk_led_control);

void thecus_poweroff(void)
{
	/*
	 * N4310 uses MCU to control poweroff.
	 * First, kernel passes MCU FW 0x4C (L) to prepare shutdown.
	 * Then, it passes 0x44 (D) to poweroff the system.
	 */
	if (board_info[board_idx].board == BOARD_N4310) {
		mcu_poweroff_command(0x4C);
		mcu_poweroff_command(0x44);
	}
}
EXPORT_SYMBOL(thecus_poweroff);

// Note: Be careful the disk index since we don' have DOM on APM867xx
//       platoform. Therefore the tray_id is in range 1~2 but port id is 0~1.
u32 n2310_disk_access(int index, int act)
{
	_DBG(1, "index %d: %d\n", index, act);

	// Map tray_id to port index;
	if (act >= LED_ENABLE)
		index--;

	//only handle N2310 MAX disk
	if ( (index < 0)||(index >= N2310_MAX_DISK) )
		return 1;

	// set enable or disable by tray_id
	switch(act){
	case LED_ENABLE:
		// white led shall only light while red led is off.
		if (sata_err_sts[index] == LED_OFF)
			apm867xx_write_gpio(SATA_ACT(index), LED_ON);
		atomic_set(&qc_new[index], LED_ON);
		access_led[index] = LED_ON;
		break;
	case LED_DISABLE:
		apm867xx_write_gpio(SATA_ACT(index), LED_OFF);
		access_led[index] = LED_OFF;
		break;
	}

	// if LED is disabled, do nothing
	if (access_led[index] == LED_OFF)
		goto out;

	_DBG(1, "APM_GPIO_%d\n", SATA_ACT(index));

	switch(act){
	case LED_ON:
		/*
		 * qc free;
		 * since we use sata_led_routine() for qc coming blinking,
		 * do nothing here.
		 */
		break;
	case LED_OFF:
		/* qc comes; set blink */
		atomic_set(&qc_new[index], LED_BLINK1);
		break;
	}

out:
	return 0;
}

// tray_id = tindex + 1
u32 n2310_disk_index(int index, struct scsi_device *sdp)
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

u32 n4310_disk_access(int index, int act)
{
	_DBG(1, "index %d: %d\n", index, act);
	// Map tray_id to port index;
	if (act >= LED_ENABLE)
		index--;

	//only handle N4310 MAX disk
	if ( (index < 0)||(index >= N4310_MAX_DISK) )
		return 1;

	// set enable or disable by tray_id
	switch(act){
	case LED_ENABLE:
		// white led shall only light while red led is off.
		if (sata_err_sts[index] == LED_OFF)
			apm867xx_write_gpio(SATA_ACT(index), LED_ON);
		atomic_set(&qc_new[index], LED_ON);
		access_led[index] = LED_ON;
		break;
	case LED_DISABLE:
		apm867xx_write_gpio(SATA_ACT(index), LED_OFF);
		access_led[index] = LED_OFF;
		break;
	}

	// if LED is disabled, do nothing
	if (access_led[index] == LED_OFF)
		goto out;

	_DBG(1, "APM_GPIO_%d\n", SATA_ACT(index));

	switch(act){
	case LED_ON:
		/*
		 * qc free;
		 * since we use sata_led_routine() for qc coming blinking,
		 * do nothing here.
		 */
		break;
	case LED_OFF:
		/* qc comes; set blink */
		atomic_set(&qc_new[index], LED_BLINK1);
		break;
	}

out:
	return 0;
}

u32 n4310_disk_index(int index, struct scsi_device *sdp)
{
	u32 tindex = index;

	if(strncmp(sdp->host->hostt->name,"ahci",strlen("ahci")) == 0){
		switch (sdp->host->host_no) {
		case 0:
			tindex = 2 + sdp->channel;
			break;
		case 1:
			tindex = sdp->channel;
			break;
		}
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

static int set_pwr_led_by_model(u8 board_model, u8 status)
{
	switch (board_model) {
	case BOARD_N2310:
		return (apm867xx_write_gpio(N2310_GPIO_PWR, status), 0);	/* return 0 or "error: void value not ignored as it ought to be" */
		break;
	case BOARD_N4310:
		power_status_n4310 = status;
		return mcu_set_power_status(power_status_n4310);	/* 1:solid    0,2:blinking */
		break;
	}

	return -ENODEV;
}

static int get_pwr_led_by_model(u8 board_model)
{
	switch (board_model) {
	case BOARD_N2310:
		return apm867xx_read_gpio(N2310_GPIO_PWR);
		break;
	case BOARD_N4310:
		return power_status_n4310;	/* 0:OFF    1:ON */
		break;
	}

	return -ENODEV;
}

static int set_buzzer_by_model(u8 board_model, u8 action, int value)
{
	switch(board_model) {
	case BOARD_N2310:
		// make sure buzzer device has been initialized before any access.
		if (buzzer == NULL){
			buzzer = buzzer_request(BUZZER_CH, BREQUESTER);
			pwm_set_period_ns(buzzer, BPERIOD);
			pwm_set_duty_ns(buzzer, BDUTY);
		}

		switch(action) {
		case _status:
			keep_BUZZER = (u8)value;
			// N2310's buzzer is controlled by pwm driver:gpio_pwm;
			// channel id is 0.
			return value ? pwm_start(buzzer) : pwm_stop(buzzer);
			break;
		case _period:
			return pwm_set_period_ns(buzzer, value);
			break;
		case _duty:
			return pwm_set_duty_ns(buzzer, value);
			break;
		}
		break;
	case BOARD_N4310:
		switch(action) {
		case _status:
			keep_BUZZER = (u8)value;
			return value ? mcu_set_buzzer(buzzer_period_n4310, buzzer_duty_n4310) : mcu_set_buzzer(0, 0);
			break;
		case _period:
			buzzer_period_n4310 = value;
			return keep_BUZZER ? mcu_set_buzzer(buzzer_period_n4310, buzzer_duty_n4310) : 0;
			break;
		case _duty:
			buzzer_duty_n4310 = value;
			return keep_BUZZER ? mcu_set_buzzer(buzzer_period_n4310, buzzer_duty_n4310) : 0;
			break;
		}
		break;
	}

	return -ENODEV;
}

static int get_buzzer_by_model(u8 board_model, u8 action)
{
	switch(board_model) {
	case BOARD_N2310:
		// make sure buzzer device has been initialized before any access.
		if (buzzer == NULL){
			buzzer = buzzer_request(BUZZER_CH, BREQUESTER);
			pwm_set_period_ns(buzzer, BPERIOD);
			pwm_set_duty_ns(buzzer, BDUTY);
		}

		switch(action) {
		case _status:
			return keep_BUZZER;
			break;
		case _period:
			return pwm_get_period_ns(buzzer);
			break;
		case _duty:
			return pwm_get_duty_ns(buzzer);
			break;
		}
		break;
	case BOARD_N4310:
		switch(action) {
		case _status:
			return keep_BUZZER;
			break;
		case _period:
			return buzzer_period_n4310;
			break;
		case _duty:
			return buzzer_duty_n4310;
			break;
		}
		break;
	}

	return -ENODEV;
}

static ssize_t proc_thecus_io_write(struct file *file,
                    const char __user * buf, size_t length, loff_t * ppos)
{
	char *buffer, buf1[20], item[20];
	int i, err, num = 0, val1, val2;
	u8 status = 0;
	//u8 val;

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
     *      x "LOGO1_LED 0|1|2"               * LOGO1 led
     *      x "LOGO2_LED 0|1|2"               * LOGO2 led
     *        "PWR_LED 0|1|2"                 * LED System Status
     *        "Fail 0|1"                      * LED System Fail
     *        "Busy 0|1"                      * LED System Busy
     *        "Buzzer 0|1"                    * Buzzer
     *        "BZperiod <num>"                * Buzzer period ns
     *        "BZduty <num>"                  * Buzzer duty ns
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

	/*
	 * All error signs need to turn off normal(white) LEDs, since
	 * N2310 double color LEDs are not exclusive.
	 */

	if (!strncmp(item, "S_LED", strlen("S_LED"))){
		if (i != 3) goto parse_done;
		if (num > 0 && num <= board_info[board_idx].max_tray){
			num--;
			if (status != LED_OFF)
				apm867xx_write_gpio(SATA_ACT(num), LED_OFF);
			else
				apm867xx_write_gpio(SATA_ACT(num), access_led[num]);
			sata_err_sts[num] = status;
			apm867xx_write_gpio(SATA_ERR(num), status);
		}

	} else if (!strncmp(item, "A_LED", strlen("A_LED"))){
		if (i != 3) goto parse_done;
		board_info[board_idx].func->disk_access(num, status);

	} else if (!strncmp(item, "U_LED", strlen("U_LED"))){
		if (i != 2) goto parse_done;
		apm867xx_write_gpio(GPIO_USB_ACT, status);
		usb_access_led = status;

	} else if (!strncmp(item, "UF_LED", strlen("UF_LED"))){
		if (i != 2) goto parse_done;
		if (status != LED_OFF)
			apm867xx_write_gpio(GPIO_USB_ACT, LED_OFF);
		else
			apm867xx_write_gpio(GPIO_USB_ACT, usb_access_led);
		apm867xx_write_gpio(GPIO_USB_ERR, status);

	} else if (!strncmp(item, "PWR_LED", strlen("PWR_LED"))){
		if (i != 2) goto parse_done;
		set_pwr_led_by_model(board_info[board_idx].board, status);

	} else if (!strncmp(item, "Busy", strlen("Busy"))){
		if (i != 2) goto parse_done;
		/* Busy is information LED only for diagnostic mode. */
		apm867xx_write_gpio(GPIO_SYS_STATUS, status);
		sys_status_led = status;

	} else if (!strncmp(item, "Fail", strlen("Fail"))){
		if (i != 2) goto parse_done;
		if (status != LED_OFF)
			apm867xx_write_gpio(GPIO_SYS_STATUS, LED_OFF);
		else
			apm867xx_write_gpio(GPIO_SYS_STATUS, sys_status_led);
		apm867xx_write_gpio(GPIO_SYS_ERR, status);

	} else if (!strncmp(item, "Buzzer", strlen("Buzzer"))){
		if (i != 2) goto parse_done;
		sys_alarm = val1;
		set_buzzer_by_model(board_info[board_idx].board, _status, val1);

	} else if (!strncmp(item, "BZperiod", strlen("BZperiod"))){
		if (i != 2) goto parse_done;
		set_buzzer_by_model(board_info[board_idx].board, _period, val1);

	} else if (!strncmp(item, "BZduty", strlen("BZduty"))){
		if (i != 2) goto parse_done;
		set_buzzer_by_model(board_info[board_idx].board, _duty, val1);

	}

parse_done:

	err = length;
out:
	free_page((unsigned long) buffer);
out2:
	*ppos = 0;

	return err;
}

#define wol_by_model(i)            (((i)==(BOARD_N2310))?(0):(((i)==(BOARD_N4310))?(1):(0)))
#define dual_power_by_model(i)     (((i)==(BOARD_N2310))?(0):(((i)==(BOARD_N4310))?(1):(0)))

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
	seq_printf(m, "WOL_FN: %d\n", wol_by_model(board_info[board_idx].board));
	seq_printf(m, "FAN_FN: %d\n", 1);
	seq_printf(m, "BEEP_FN: %d\n", 1);
	seq_printf(m, "eSATA_FN: %d\n", 0);
	seq_printf(m, "DUALPOWER_FN: %d\n", dual_power_by_model(board_info[board_idx].board));

	val = apm867xx_read_gpio(GPIO_USB_COPY_BTN(board_info[board_idx].board));
	seq_printf(m,"Copy button: %s\n", LED_STATUS[val]);

	val = apm867xx_read_gpio(GPIO_USB_ACT);
	seq_printf(m, "U_LED: %s\n", LED_STATUS[val]);

	val = apm867xx_read_gpio(GPIO_USB_ERR);
	seq_printf(m, "UF_LED: %s\n", LED_STATUS[val]);

	/*
	 * Busy is information LED only for diagnostic mode.
	 * For N2310, it is SYS_STATUS.
	 */
	val = apm867xx_read_gpio(GPIO_SYS_STATUS);
	seq_printf(m, "LED_Busy: %s\n", LED_STATUS[val]);

	seq_printf(m, "LED_Power: %s\n", LED_STATUS[get_pwr_led_by_model(board_info[board_idx].board)]);

	seq_printf(m, "Buzzer: %s\n", get_buzzer_by_model(board_info[board_idx].board, _status) ? "ON" : "OFF");
	seq_printf(m, "BZperiod: %u\n", get_buzzer_by_model(board_info[board_idx].board, _period));
	seq_printf(m, "BZduty: %u\n", get_buzzer_by_model(board_info[board_idx].board, _duty));

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
static void dual_power_detection_routine(struct work_struct *unused);
static void sata_led_routine(struct work_struct *ws);
static DECLARE_DELAYED_WORK(btn_sched, intrpt_routine);
static DECLARE_DELAYED_WORK(dual_power, dual_power_detection_routine);
static DECLARE_WORK(sata_work, sata_led_routine);

static void intrpt_routine(struct work_struct *unused)
{
	u8 val = 0;

	// send event while button is pressed. 'ON' means 'pressed'.
	val = apm867xx_read_gpio(GPIO_USB_COPY_BTN(board_info[board_idx].board));
	if(val == 0) {
		sprintf(Message, "Copy ON\n");
		_DBG(2, "Copy ON\n");
		wake_up_interruptible(&thecus_event_queue);
	}

	val = apm867xx_read_gpio(GPIO_SOFT_RST);
	if(val == 0) {
		if (rst_btn_count == 15){                // press 3 sec
			sprintf(Message, "RST2DF ON\n");
			_DBG(2, "RST2DF ON\n");
			wake_up_interruptible(&thecus_event_queue);
			rst_btn_count = 0;
		} else
			rst_btn_count++;
	} else
		rst_btn_count = 0;

	switch(board_info[board_idx].board){
	case BOARD_N2310:
		val = apm867xx_read_gpio(N2310_GPIO_PWR_BTN);
		if (val == 0) {
			if (pwr_btn_count == 15){            // press 3 sec
				sprintf(Message, "PWR ON\n");
				_DBG(2, "PWR ON\n");
				wake_up_interruptible(&thecus_event_queue);
				pwr_btn_count = 0;
			} else
				pwr_btn_count++;
		} else
			pwr_btn_count = 0;
		break;
	case BOARD_N4310:
		/* After power button presses over 4s, MCU will pull low the GPIO 4. */
		val = apm867xx_read_gpio(APM_GPIO(4));
		if( val == 0 ) {
			/* To flush the flag; MCU will reset the GPIO 4 */
			mcu_poweroff_command(0x4C);
			/* Ready to shut down */
			sprintf(Message, "PWR ON\n");
			_DBG(2, "PWR ON\n");
			wake_up_interruptible(&thecus_event_queue);
		}
		break;
	}

	// keep intrp_routine queueing itself
	if (module_die == 0)
		queue_delayed_work(my_workqueue, &btn_sched, dyn_work_queue_timer);
}

static void dual_power_detection_routine(struct work_struct *unused)
{
	u8 val1, val2;
	static u8 dual_power_alarm = 1;

	switch (board_info[board_idx].board) {
	case BOARD_N4310:
		if (dual_power_detection == 1) {
			val1 = apm867xx_read_gpio(N4310_PWR_ADAPTER_A);
			val2 = apm867xx_read_gpio(N4310_PWR_ADAPTER_B);

			/*
			 * When alarm is raising,
			 * we keep it beeping or turn off the buzzer once
			 * depending on the system is safe or error.
			 */
			if (! (val1 & val2)) {
				/*
				 * If the buzzer doesn't keep beeping,
				 * start the buzzer.
				 */
				if (keep_BUZZER == 0)
					set_buzzer_by_model(BOARD_N4310, _status, 1);

				dual_power_alarm = 1;
			} else {
				/*
				 * The status is back to safe from error
				 * and no other services raise the buzzer,
				 * the buzzer will be stopped.
				 */
				if (dual_power_alarm != 0 && sys_alarm == 0)
					set_buzzer_by_model(BOARD_N4310, _status, 0);

				dual_power_alarm = 0;
			}
		}
		break;
	}

	if (module_die == 0)
		queue_delayed_work(my_workqueue, &dual_power, dyn_work_queue_timer);
}

static void sata_led_routine(struct work_struct *ws)
{
	int i;
	u8 act = 0;

	for (i = 0; i < max_disk; i++) {
		switch(access_led[i]) {
		case LED_ON:
			act = atomic_read(&qc_new[i]);
			atomic_set(&qc_new[i], LED_ON);
			break;
		case LED_OFF:
			act = LED_OFF;
			break;
		}

		if (qc_cur[i] != act) {
			apm867xx_write_gpio(SATA_ACT(i), act);
			qc_cur[i] = act;
		}
	}

	msleep(50);

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

static int proc_dual_power_show(struct seq_file *m, void *v)
{
	seq_printf(m, "Alarm: %u\n", dual_power_detection);
	seq_printf(m, "PWR_A: %u\n", apm867xx_read_gpio(N4310_PWR_ADAPTER_A));
	seq_printf(m, "PWR_B: %u\n", apm867xx_read_gpio(N4310_PWR_ADAPTER_B));

	return 0;
}

static int proc_dual_power_open(struct inode *inode, struct file *file)
{
	return single_open(file, proc_dual_power_show, NULL);
}

static ssize_t proc_dual_power_write(struct file *file,
                    const char __user * buf, size_t length, loff_t * ppos)
{
	char *buffer, item[20];
	int i, err, val;

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

	i = sscanf(buffer, "%s %d\n", item, &val);

	if (!strncmp(item, "Alarm", strlen("Alarm"))){
		if (i != 2) goto parse_done;
		dual_power_detection = (u8)val;
		// turn off buzzer when disabling
		if (dual_power_detection == 0)
			set_buzzer_by_model(BOARD_N4310, _status, 0);
	}

parse_done:
	err = length;
out:
	free_page((unsigned long) buffer);
out2:
	*ppos = 0;

	return err;
}
static struct file_operations proc_dual_power_operations = {
	.open = proc_dual_power_open,
	.read = seq_read,
	.write = proc_dual_power_write,
	.llseek = seq_lseek,
	.release = single_release,
};

static int sys_notify_reboot(struct notifier_block *nb, unsigned long event,
                                void *p)
{
	/*
	 * Power off behavior
	 * Power LED    N2310 -->PWR:                           BLINK.
	 * Info LED     N2310 -->SYS_STATUS                     OFF.
	 * ERR LED                                              OFF.
	 * Other BUSY/ERR LEDs (N2310):                         OFF.
	 */
	set_pwr_led_by_model(board_info[board_idx].board, LED_BLINK1);
	apm867xx_write_gpio(GPIO_SYS_STATUS, LED_OFF);
	apm867xx_write_gpio(GPIO_SYS_ERR, LED_OFF);
	apm867xx_write_gpio(GPIO_USB_ACT, LED_OFF);
	apm867xx_write_gpio(GPIO_USB_ERR, LED_OFF);

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

	// check if this platform is N2310 family
	if (!is_apm864xx() && !is_apm867xx()) 
		return -ENODEV;

	// get MBID from APM GPIO
	for (n=0; n<4; n++)
		board_num |= (apm867xx_read_gpio(GPIO_MBID(n)) << (~n & 3));

	printk(KERN_INFO "thecus_io: board_num: %Xh\n", board_num);

	for (n = 0; board_info[n].board_string; n++)
		if (board_num == board_info[n].gpio_num) {
			board_idx = n;
			printk(KERN_INFO "board_idx %d\n", board_idx);
			break;
		}

	thecus_board_register(&board_info[board_idx]);

	switch (board_info[board_idx].board) {
	case BOARD_N2310:
		max_disk = N2310_MAX_DISK;
		break;
	case BOARD_N4310:
		max_disk = N4310_MAX_DISK;
		break;
	}

	/*
	 * Booting behavior
	 * Power LED    N2310 only -->SYS_BUSY:                 BLINK.
	 * Info LED     N2310-->SYS_STATUS N4310-->SYS_BUSY:    OFF.
	 * ERR LED      (N4310 only):                           OFF.
	 * TLOGO        (N520 only):                            BLINK.
	 * Other BUSY/ERR LEDs (N2310 only):                    OFF.
	 */ 
	// set LEDs
	set_pwr_led_by_model(board_info[board_idx].board, LED_BLINK1);
	apm867xx_write_gpio(GPIO_SYS_STATUS, LED_OFF);
	apm867xx_write_gpio(GPIO_SYS_ERR, LED_OFF);
	apm867xx_write_gpio(GPIO_USB_ACT, LED_OFF);
	apm867xx_write_gpio(GPIO_USB_ERR, LED_OFF);

	for (n = 0; n < max_disk; n++)
		qc_cur[n] = apm867xx_read_gpio(SATA_ACT(n));

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

	pde = create_proc_entry("dual_power", S_IRUSR, NULL);
	if (!pde) {
		printk(KERN_ERR "dual_power: cannot create /proc/dual_power.\n");
		ret = -ENOENT;
		goto io_out;
	}
	pde->proc_fops = &proc_dual_power_operations;

	// add our work queue
	my_workqueue = create_workqueue(MY_WORK_QUEUE_NAME);
	if (my_workqueue) {
		queue_delayed_work(my_workqueue, &btn_sched, dyn_work_queue_timer);
		queue_delayed_work(my_workqueue, &dual_power, dyn_work_queue_timer);
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
	cancel_delayed_work(&dual_power);
	flush_workqueue(my_workqueue);      // wait till all "old ones" finished 
	destroy_workqueue(my_workqueue);

	remove_proc_entry("thecus_io", NULL);
	remove_proc_entry("thecus_event", NULL);

	unregister_reboot_notifier(&sys_notifier_reboot);

	thecus_board_unregister(&board_info[board_idx]);

}

MODULE_AUTHOR("Zeno Lai <zeno_lai@thecus.com>");
MODULE_DESCRIPTION("Thecus N2310 MB Driver and board depend io operation");
MODULE_LICENSE("GPL");

module_init(thecus_io_init);
module_exit(thecus_io_exit);
