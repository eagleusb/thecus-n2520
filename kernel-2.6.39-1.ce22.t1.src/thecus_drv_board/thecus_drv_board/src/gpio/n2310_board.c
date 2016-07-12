/*
 *  Copyright (C) 2013 Thecus Technology Corp. 
 *
 *      Maintainer: Zeno Lai <zeno_lai@thecus.com>
 *
 *      Driver for Thecus N2310 board's I/O
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

// GPIO pin assignment
#define APM_GPIO(i)                (204+(i))
#define APM_GPIO_DS(i)             (178+(i))

// 4 bits ID GPIO[3:0]
#define GPIO_MBID(i)               (APM_GPIO(0)+(i))

#define GPIO_SYS_STATUS             APM_GPIO(8)
#define GPIO_SYS_ERR                APM_GPIO(9)
#define GPIO_PWR                    APM_GPIO(10)
#define GPIO_PWR_ERR                APM_GPIO(11)
#define GPIO_USB_ACT                APM_GPIO(12)
#define GPIO_USB_ERR                APM_GPIO(13)
#define GPIO_BEEP                   APM_GPIO(15)
#define GPIO_PWR_CTRL               APM_GPIO(17)
#define N2310_SATA_ERR(i)          (APM_GPIO(30)+((i)*2))
#define N2310_SATA_ACT(i)          (APM_GPIO(31)+((i)*2))
#define GPIO_USB_COPY_BTN           APM_GPIO(34)
#define GPIO_SOFT_RST               APM_GPIO(35)
#define GPIO_SATA_PWR(i)           (APM_GPIO(37)+(i))
#define GPIO_USB1_PWR               APM_GPIO(42)
#define GPIO_USB1_OC                APM_GPIO(43)    // USB1 over-current
// GPIO_DS
#define GPIO_SATA_INS(i)           (APM_GPIO_DS(0)+((i)*2)) // HDD insert
#define GPIO_SATA_PULL(i)          (APM_GPIO_DS(1)+((i)*2)) // HDD pull
#define GPIO_PWR_BTN                APM_GPIO_DS(5)
#define GPIO_USB0_PWR               APM_GPIO_DS(10)
#define GPIO_USB0_OC                APM_GPIO_DS(11) // USB0 over-current
#define GPIO_FAN                    APM_GPIO_DS(12)

// not used in N2310
#define GPIO_PIC_GPO_0              4
#define GPIO_PIC_GPO_1              5
#define GPIO_LCD_A_EN               12
#define GPIO_SD_ACT                 13
#define GPIO_PIC_GPI_0              13
#define GPIO_SD_ERR                 14
#define GPIO_AVR_RST                15 //for RESET PIC

//------------------------------------------------------------------------
/*
 * led_blink function only supports HDD white/red leds and USB copy white led
 * 0: SATA_ERR 0; 1: SATA_ACT 0
 * 2: SATA_ERR 1; 3: SATA_ACT 1
 * 5: USB_ACT
 */
extern int start_led_blink(unsigned int led);
extern int stop_led_blink(unsigned int led, unsigned int state);
int sata_err_sts[2] = {0};
extern struct pwm_channel *buzzer_request(int chan, const char *requester);
struct pwm_channel *buzzer = NULL;
const char *BREQUESTER = "sysfs";
#define BUZZER_CH  0
#define BPERIOD    1000000
#define BDUTY      500000

/*
 * apm gpio get callback function will return 'reg & bit_mask' value
 * directly, not the specified bit value, therefore we convert it to
 * single bit value here.
 */
#define apm867xx_read_gpio(a)        ((gpio_get_value((a))) ? 1 : 0)
void apm867xx_write_gpio(uint8_t pin, uint8_t val){
	switch (val){
	case LED_ON:
	case LED_OFF:
		if (pin >= N2310_SATA_ERR(0) && pin <= N2310_SATA_ACT(1))
			stop_led_blink((pin - N2310_SATA_ERR(0)), val);
		else if (pin == GPIO_USB_ACT)
			stop_led_blink(5, val);
		gpio_set_value(pin, val);
		break;
	case LED_BLINK1:
		// by HW design, PWR_LED will blink while level is low.
		if (pin == GPIO_PWR)
			gpio_set_value(pin, LED_OFF);
		else if (pin >= N2310_SATA_ERR(0) && pin <= N2310_SATA_ACT(1))
			start_led_blink(pin - N2310_SATA_ERR(0));
		else if (pin == GPIO_USB_ACT)
			start_led_blink(5);
		break;
	}
}

// N2310's buzzer is controlled by pwm driver:gpio_pwm;
// channel id is 0.
void buzzer_init(void)
{
	if (buzzer == NULL){
		buzzer = buzzer_request(BUZZER_CH, BREQUESTER);
		pwm_set_period_ns(buzzer, BPERIOD);
		pwm_set_duty_ns(buzzer, BDUTY);
	}
}

int buzzer_run(int cmd)
{
	int ret = -ENODEV;
	if (buzzer != NULL){
		if (cmd == 1)
			ret = pwm_start(buzzer);
		else if (cmd == 0)
			ret = pwm_stop(buzzer);
	}

	return ret;
}

//------------------------------------------------------------------------
// Model configuration
#define N2310_MAX_DISK                 2
#define N4310_MAX_DISK                 4

#define THECUS_MAX_DISK                16

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (x>=DEBUG) printk("%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
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
	{ 0x0, "N2310", N2310_MAX_DISK, 17, 0, "900", "BOARD_N2310", &n2310_func},
	{ 0x1, "N4310", N4310_MAX_DISK, 17, 0, "901", "BOARD_N4310", &n4310_func},
	{ }
};

static int debug;;
module_param(debug, int, S_IRUGO | S_IWUSR);

static u32 keep_BUZZER = BUZZER_OFF;
static u32 usb_access_led = LED_OFF;
static u32 sys_status_led = LED_OFF;
static int sleepon_flag=0;

// SATA LED control array 
static u32 access_led[THECUS_MAX_DISK]={LED_OFF};

/* TODO: model has LCM
static char keep_LCM_RAID[16];
static char keep_LCM_DATE[16];
*/

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
			apm867xx_write_gpio(N2310_SATA_ACT(index), LED_ON);
		access_led[index] = LED_ON;
		break;
	case LED_DISABLE:
		apm867xx_write_gpio(N2310_SATA_ACT(index), LED_OFF);
		access_led[index] = LED_OFF;
		break;
	}

	// if LED is disabled, do nothing
	if (access_led[index] == LED_OFF)
		goto out;

	_DBG(1, "APM_GPIO_%d\n", N2310_SATA_ACT(index));

	switch(act){
	case LED_ON:
		/* qc free; turn LED back to ON */
		// white led shall only light while red led is off.
		if (sata_err_sts[index] == LED_OFF)
			apm867xx_write_gpio(N2310_SATA_ACT(index), LED_ON);
		break;
	case LED_OFF:
		/* qc comes; turn LED OFF */
		apm867xx_write_gpio(N2310_SATA_ACT(index), LED_OFF);
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
			apm867xx_write_gpio(N2310_SATA_ACT(index), LED_ON);
		access_led[index] = LED_ON;
		break;
	case LED_DISABLE:
		apm867xx_write_gpio(N2310_SATA_ACT(index), LED_OFF);
		access_led[index] = LED_OFF;
		break;
	}

	// if LED is disabled, do nothing
	if (access_led[index] == LED_OFF)
		goto out;

	_DBG(1, "APM_GPIO_%d\n", N2310_SATA_ACT(index));

	switch(act){
	case LED_ON:
		/* qc free; turn LED back to ON */
		// white led shall only light while red led is off.
		if (sata_err_sts[index] == LED_OFF)
			apm867xx_write_gpio(N2310_SATA_ACT(index), LED_ON);
		break;
	case LED_OFF:
		/* qc comes; turn LED OFF */
		apm867xx_write_gpio(N2310_SATA_ACT(index), LED_OFF);
		break;
	}

out:
	return 0;
}

/* TODO: N4310 project has not kicked off, this function won't be correct. */
u32 n4310_disk_index(int index, struct scsi_device *sdp)
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

/* TODO: for N4310 if has PIC
static void reset_pic(void)
{
	u8 val;

	printk(KERN_INFO "RESET_PIC\n");
	apm867xx_write_gpio(GPIO_AVR_RST, 0x1);
	udelay(60);
	apm867xx_write_gpio(GPIO_AVR_RST, 0x0);

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
*/

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
     *
     * Options for PIC24 LCM
     *        "PWR_S 2|3"                     * in linux/ in u-boot
     *        "SYS 0|1|2"                     * Do power off/HReset/PCI reset
     *        "LCM_DISPLAY 0|1"
     *        "LCM_AUTO_OFF 0|1"              * 0:off,1:on
     *        "LCM_HOSTNAME <16 bytes ascii string>"
     *        "LCM_WANIP 192.168.1.100"
     *        "LCM_LANIP 192.168.2.254"
     *        "LCM_RAID Healthy|Degrade|Damage|N/A"
     *        "LCM_FAN 5000 RPM"
     *        "LCM_TEMP 30"
     *        "LCM_DATE 2006/12/23 23:14"
     *        "LCM_UPTIME 12 min"
     *        "LCM_MSG -Uupper -Llower -Ssec"
     *        "LCM_USB 1|2|3|4|5"
     *                   * usb copy, Nothing|Coping|Success|Fail|No Device
     *        "RESET_PIC"
     *        "BTN_OP 1|2|3|4"  * 1:UP,2:DOWN,3:ENTER,4:ESC
     *        "PIC_FAC 0|1"     * 0:normal,1:factory
     *        "LCM_BANNER 11111111"  
     *                   * 8bits represent: Hostname, WAN, LAN, RAID, FAN,
     *                                      TEMP, DATE, UPTime
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

	// make sure buzzer device has been initialized before any access.
	buzzer_init();

	if (!strncmp(item, "S_LED", strlen("S_LED"))){
		if (i != 3) goto parse_done;
		if (num > 0 && num <= board_info[board_idx].max_tray){
			num--;
			if (status != LED_OFF)
				apm867xx_write_gpio(N2310_SATA_ACT(num), LED_OFF);
			else
				apm867xx_write_gpio(N2310_SATA_ACT(num), access_led[num]);
			sata_err_sts[num] = status;
			apm867xx_write_gpio(N2310_SATA_ERR(num), status);
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
		apm867xx_write_gpio(GPIO_PWR, status);

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
		if (buzzer == NULL){
			// initial buzzer device
			buzzer = buzzer_request(BUZZER_CH, BREQUESTER);
			pwm_set_period_ns(buzzer, BPERIOD);
			pwm_set_duty_ns(buzzer, BDUTY);
		}
		buzzer_run(status);
		keep_BUZZER = status;
    
	} else if (!strncmp(item, "BZperiod", strlen("BZperiod"))){
		if (i != 2) goto parse_done;
		pwm_set_period_ns(buzzer, val1);

	} else if (!strncmp(item, "BZduty", strlen("BZduty"))){
		if (i != 2) goto parse_done;
		pwm_set_duty_ns(buzzer, val1);

/* TODO: for N4310
  } else if (board_idx == 1){
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
*/
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
	seq_printf(m, "WOL_FN: %d\n", 0);
	seq_printf(m, "FAN_FN: %d\n", 1);
	seq_printf(m, "BEEP_FN: %d\n", 1);
	seq_printf(m, "eSATA_FN: %d\n", 0);

	val = apm867xx_read_gpio(GPIO_USB_COPY_BTN);
	seq_printf(m,"Copy button: %s\n", LED_STATUS[val]);

	val = apm867xx_read_gpio(GPIO_USB_ACT);
	seq_printf(m, "U_LED: %s\n", LED_STATUS[val]);

	val = apm867xx_read_gpio(GPIO_USB_ERR);
	seq_printf(m, "UF_LED: %s\n", LED_STATUS[val]);

	val = apm867xx_read_gpio(GPIO_PWR);
	seq_printf(m, "LED_Power: %s\n", LED_STATUS[val]);

	/*
	 * Busy is information LED only for diagnostic mode.
	 * For N2310, it is SYS_STATUS.
	 */
	val = apm867xx_read_gpio(GPIO_SYS_STATUS);
	seq_printf(m, "LED_Busy: %s\n", LED_STATUS[val]);

	// make sure buzzer device has been initialized before any access.
	buzzer_init();
	seq_printf(m, "Buzzer: %s\n", keep_BUZZER ? "ON" : "OFF");
	seq_printf(m, "BZperiod: %lu\n", pwm_get_period_ns(buzzer));
	seq_printf(m, "BZduty: %lu\n", pwm_get_duty_ns(buzzer));
  
/* TODO: for N4310 if if has PIC24
  if (board_idx == 1){
	
    pic24fj128_get_regs(THECUS_PIC24FJ128_VERSION, &val, 1);//0x6
    seq_printf(m, "PIC_VER: %d\n", val);

    pic24fj128_get_regs(THECUS_PIC24FJ128_PWR_STATUS, &val, 1);//0x5
    seq_printf(m, "PWR_S: %d\n", val);

    pic24fj128_get_regs(THECUS_PIC24FJ128_LCM_DISPLAY, &val, 1);//0x7
    seq_printf(m, "LCM_DISPLAY: %d\n", val);
    seq_printf(m, "LCM_AUTO_OFF: %s\n", lcm_off_count>=0 ? "ON" : "OFF");

#ifdef DEBUG
    val = apm867xx_read_gpio(GPIO_PIC_GPO_0);
    seq_printf(m, "PIC_GPO_0: %s\n", LED_STATUS[val]);
    pic24fj128_get_regs(THECUS_PIC24FJ128_INT_STATUS, &val, 1);//0x19
    seq_printf(m, "INT_S: %d\n", val);
#endif
  }
*/

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
static DECLARE_DELAYED_WORK(btn_sched, intrpt_routine);

static void intrpt_routine(struct work_struct *unused)
{
	u8 val = 0;

	// send event while button is pressed. 'ON' means 'pressed'.
	if (board_idx == 0){
		val = apm867xx_read_gpio(GPIO_USB_COPY_BTN);
		if(val == 0) {
			sprintf(Message, "Copy ON\n");
			_DBG(2, "Copy ON\n");
			wake_up_interruptible(&thecus_event_queue);
		}
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

	val = apm867xx_read_gpio(GPIO_PWR_BTN);
	if (val == 0) {
		if (board_idx == 0){
			if (pwr_btn_count == 15){            // press 3 sec
				sprintf(Message, "PWR ON\n");
				_DBG(2, "PWR ON\n");
				wake_up_interruptible(&thecus_event_queue);
				pwr_btn_count = 0;
			} else
				pwr_btn_count++;
/* TODO:N4310
		}else{
			_DBG(2, "GPIO_PWR_BTN ON\n");
			val = 5;
			pic24fj128_write_regs(THECUS_PIC24FJ128_BTN_OP, &val, 1);
*/
		}
	} else
		pwr_btn_count = 0;


/* TODO:N4310
	if (0 == apm867xx_read_gpio(GPIO_AVR_RST)) {
		if (avr_btn_count == 10){
			sprintf(Message, "RESET_PIC ON\n");
			_DBG(2, "RESET_PIC ON\n");
			wake_up_interruptible(&thecus_event_queue);
			avr_btn_count = 0;
		} else
			avr_btn_count++;
	} else
		avr_btn_count = 0;
	
	
  if (0 == apm867xx_read_gpio(GPIO_PIC_GPO_0)) {
    _DBG(2, "PIC_GPO_0 ON\n");
  }

  if (board_idx == 1){
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
        apm867xx_write_gpio(GPIO_AVR_RST, 0x1);
        udelay(60);
        apm867xx_write_gpio(GPIO_AVR_RST, 0x0);
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
*/

	// keep intrp_routine queueing itself
	if (module_die == 0)
		queue_delayed_work(my_workqueue, &btn_sched, dyn_work_queue_timer);

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
	//u8 val;
	/*
	 * Power off behavior
	 * Power LED    N2310 -->PWR:                           BLINK.
	 * Info LED     N2310 -->SYS_STATUS                     OFF.
	 * ERR LED                                              OFF.
	 * Other BUSY/ERR LEDs (N2310):                         OFF.
	 */
	if (board_idx == 0){
		apm867xx_write_gpio(GPIO_PWR, LED_BLINK1);
		apm867xx_write_gpio(GPIO_SYS_STATUS, LED_OFF);
		apm867xx_write_gpio(GPIO_SYS_ERR, LED_OFF);
		apm867xx_write_gpio(GPIO_USB_ACT, LED_OFF);
		apm867xx_write_gpio(GPIO_USB_ERR, LED_OFF);
/* TODO:N4310
	}else if (board_idx == 1){
		apm867xx_write_gpio(GPIO_SYS_STATUS, LED_BLINK1);
		apm867xx_write_gpio(GPIO_SYS_BUSY, LED_OFF);
		apm867xx_write_gpio(GPIO_SYS_ERR, LED_OFF);
		
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
*/
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

	// check if this platform is N2310 family
	if (!is_apm864xx() && !is_apm867xx()) 
		return -ENODEV;

	// get MBID from APM GPIO
	for (n=0; n<4; n++)
		board_num |= (apm867xx_read_gpio(GPIO_MBID(n)) << n);

	printk(KERN_INFO "thecus_io: board_num: %Xh\n", board_num);
	for (n = 0; board_info[n].board_string; n++)
		if (board_num == board_info[n].gpio_num) {
			board_idx = n;
			printk(KERN_INFO "board_idx %d\n", board_idx);
			break;
		}

	thecus_board_register(&board_info[board_idx]);

	/*
	 * Booting behavior
	 * Power LED    N2310 only -->SYS_BUSY:                 BLINK.
	 * Info LED     N2310-->SYS_STATUS N4310-->SYS_BUSY:    OFF.
	 * ERR LED      (N4310 only):                           OFF.
	 * TLOGO        (N520 only):                            BLINK.
	 * Other BUSY/ERR LEDs (N2310 only):                    OFF.
	 */ 
	switch(board_idx){
	case 0:
		// set LEDs
		apm867xx_write_gpio(GPIO_PWR, LED_BLINK1);
		apm867xx_write_gpio(GPIO_SYS_STATUS, LED_OFF);
		apm867xx_write_gpio(GPIO_SYS_ERR, LED_OFF);
		apm867xx_write_gpio(GPIO_USB_ACT, LED_OFF);
		apm867xx_write_gpio(GPIO_USB_ERR, LED_OFF);
		break;
/*
	case 1:
		// N4310: initialize PIC24
		apm867xx_write_gpio(GPIO_AVR_RST, 0);
		// set LEDs
		apm867xx_write_gpio(GPIO_SYS_STATUS, LED_BLINK1);
		apm867xx_write_gpio(GPIO_SYS_BUSY, LED_OFF);
		apm867xx_write_gpio(GPIO_SYS_ERR, LED_OFF);
		break;
*/
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
MODULE_DESCRIPTION("Thecus N2310 MB Driver and board depend io operation");
MODULE_LICENSE("GPL");
module_init(thecus_io_init);
module_exit(thecus_io_exit);
