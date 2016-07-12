/*
 *  Copyright (C) 2013 Thecus Technology Corp. 
 *
 *      Maintainer: Zeno Lai <zeno_lai@thecus.com>
 *
 *      Driver for Thecus iCE series (Evansport) 8051 picuart IO
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */
#include <linux/module.h>
#include <linux/kernel.h>
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
#include <linux/pci.h>

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (x>=DEBUG) printk("%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

/* polling 8051 FW I/O Module version */
/* Assumption: VUart I/O port is 0x3E8 */
#define VUART_BASE                   0x3e8
#define VUART_LSR                    (VUART_BASE + 5)

// PIC commands
#define CMD_NONE                     0
#define CMD_IR                       1
#define CMD_CEC                      2
#define CMD_ADDRESS                  3
#define CMD_POWER                    4
#define CMD_CEC_ACK                  5
#define CMD_ACK                      6
#define CMD_NAK                      7
#define CMD_START                    8
#define CMD_VERSION                  9
#define CMD_PROGRAM                 10
#define CMD_RS232                   11
#define CMD_IR_REPEAT_START         12
#define CMD_IR_REPEAT_STOP          13
#define CMD_IR_REPEAT_MODE          14
#define CMD_IO_EVENT                15
#define CMD_IO_TIMER_VALUE          16
#define CMD_IR_PLUS                 17
#define CMD_CHECKSUM                18
#define CMD_PWM_PANEL               19
#define CMD_PWM_FAN                 20
#define CMD_CT                      21
#define CMD_GPIO                    22
#define CMD_POWERUPKEYS             23
#define CMD_LTDC                    24
#define CMD_WDT_SET                 25
#define CMD_WDT_HEARTBEAT           26
#define CMD_IR_PLUS_REPEAT_START    27
#define CMD_IR_PLUS_REPEAT_STOP     28
#define CMD_GPIO_READ               29
//#define CMD_PWM_LOGO                29
#define CMD_FACMODE                 30
#define CMD_SNIFFER                 31

// Communications Control bytes
#define SYNC                        0xaa
#define MAX_MSG_LENGTH              255 // max buffer size 
#define MIN_MSG_LENGTH              2   // min message size is 2 chars for
                                        // single-byte ACK/NAK message

#define LR_PIC_GPIO                 22  // PIC GPIOs

#define BAUDRATE_9600               1041

// IntelCE PM GPIO (8051)
#define PM_LED_ON                   0x0
#define PM_LED_OFF                  0x1
#define PM_LED_BLINK                0x2

#define SATA_LED(i)                 (13+i)
#define PCA9532_RST                 10
#define PWR_BTN                     17
#define LAN_PHY_RST                 20

static DEFINE_MUTEX(uart_lock);

// return valid hex digit or 16 to indicate erroneous input value
static uint8_t charToHex( uint8_t currentChar )
{
	uint8_t val;
	if ( currentChar >= '0' && currentChar <= '9' )
	{
		val = currentChar - '0';
	}
	else if ( currentChar >= 'A' && currentChar <= 'F' )
	{
		val = currentChar - 'A' + 10;
	}
	else if ( currentChar >= 'a' && currentChar <= 'f' )
	{
		val = currentChar - 'a' + 10;
	}
	else
	{
		val = 16;
	}

	return val;
}

static unsigned char byteToChar(unsigned char val)
{
	unsigned char ret;

	if (val < 10)
		ret = '0' + val;
	else
		ret = 'A' + val - 10;

	return ret;
}

static int encodeCMD( unsigned char* inBuffer, int inLength, unsigned char* outputBuffer, int* outputLength )
{
	unsigned char* ptr = outputBuffer;
	char checkSum = 0;
	int length = 2 * inLength + 4;  // total length of output buffer if all goes well
	unsigned char val;
	int i;

	if ( inLength <= 0 )
		return -1;

	if ( inBuffer == NULL || outputBuffer == NULL || outputLength == NULL )
		return -1;

	// now convert data to ASCII and assemble output buffer
	*outputLength = length;

	*ptr++ = SYNC;			  // sync byte
	*ptr++ = 2 * inLength;	  // length of message characters in buffer (excludes checksum chars)
	for( i = 0; i < inLength; i++ )
	{
		val = *(inBuffer + i);
		checkSum = checkSum + val;
		*ptr = byteToChar((val >> 4) & 0x0F);
		ptr++;
		*ptr = byteToChar(val & 0x0F);
		ptr++;
	}

	// put checksum into buffer
	//checkSum = -checkSum & 0xFF;  // don't bother inverting checksum -- just use it as is
	_DBG(1, "output checksum %x\n", checkSum );

	*ptr = byteToChar((checkSum >> 4) & 0x0F);
	ptr++;
	*ptr = byteToChar(checkSum & 0x0F);
	//sprintf( (char*)ptr++, "%0X", (checkSum >> 4) & 0x0F );
	//sprintf( (char*)ptr, "%0X", checkSum & 0x0F );

	_DBG(1, "encodeOutputBuffer: " );
	for( i = 0; i < length; i++ )
		_DBG(1, "%0x ", outputBuffer[i] );
	_DBG(1, "\n\n" );

	return 0;
}

static int picuart_rw(uint8_t sendCmd[], int send_len, char* recvbuffer)
{
	int i, j, ret;
	uint8_t len;
	uint8_t bh,bl;
	uint8_t lsr;
	uint8_t spin;

	mutex_lock(&uart_lock);
/*	ret = mutex_trylock(&uart_lock);
	if (ret)
		return ret;
*/
	_DBG(2, "start\n");

	// Clear recvbuffer
	for (i=0; i<sizeof(recvbuffer); i++)
		recvbuffer[i] = 0;

	// Clear the vuart
	spin = 1;
	do {
		inb(VUART_BASE);
		lsr = inb(VUART_LSR);
	} while((lsr & 0x1) && (spin++ != 0));

	// Enter connected state with 8051 by sending sendCmd

	// Send encoded start command
	for(i=0; i < send_len; i++)
	{
		outb(sendCmd[i], VUART_BASE);
		usleep_range(BAUDRATE_9600, BAUDRATE_9600+100);
	}

	// Decode protocol stream from 8051 FW
	// First reply will be ack then will be the version answer...

	// Wait for data ready
	spin=1;
	do {
		lsr = inb(VUART_LSR);
	} while(((lsr & 0x1) == 0) && (spin++ != 0));

	len = inb(VUART_BASE); // SYNC
	if(len != SYNC)
	{
		printk(KERN_ERR "8051 FW I/O Module does not exist\n");
		ret = -ENODEV;
		goto out;
	}

	ret = -EPERM;
	// The first set of bytes is the protocol ACK so lets read bytes until
	// we get the next sync = SYNC
	spin=1;
	do {
	   len = inb(VUART_BASE);
	   usleep_range(BAUDRATE_9600, BAUDRATE_9600+100);
	} while((len != SYNC) && (spin++ != 0));

	// Check for spinout  
	if(len != SYNC)
	{
		printk(KERN_ERR "8051 Target parameter does not exist (1)\n");
		goto out;
	}

	// Now the remaining protocol with encoded version info
	// SYNC (already read above),LEN (of Encoded bytes),
	// Encoded bytes = CMD_VERSION,Len (of version data),Version data
	len = inb(VUART_BASE);
	if (len == 0)
		printk(KERN_ERR "8051 Target parameter does not exist (2)\n");
	else
		_DBG(1, "8051 Target parameter length: %d", len);

	j = 0;
	for (i=0; i < len/2; i++) {
		bh = charToHex(inb(VUART_BASE));
		usleep_range(BAUDRATE_9600, BAUDRATE_9600+100);
		bl = charToHex(inb(VUART_BASE));
		usleep_range(BAUDRATE_9600, BAUDRATE_9600+100);

		//First four bytes are the encoded CMD enum and the length which is redundant, which is redundant.
		if(i != 0 && i != 1){
			recvbuffer[j++] = (bh << 4) | bl;
			_DBG(1, "%c %d", recvbuffer[j-1], recvbuffer[j-1]);
		}
	}

	_DBG(1, "\n");

	// Clear the vuart
	spin = 1;
	do {
		inb(VUART_BASE);
		lsr = inb(VUART_LSR);
	} while((lsr & 0x1) && (spin++ != 0));

	ret = 0;
out:
	_DBG(2, "end\n");
	mutex_unlock(&uart_lock);
	return ret;
}

int picuart_write_gpio(uint8_t pin, uint8_t val)
{
	int ret = 0;
	uint8_t cmd[3] = {CMD_GPIO, pin, val};
	uint8_t sendCmd[MAX_MSG_LENGTH] = {0};
	int send_len = 0;
	char recvbuffer[MAX_MSG_LENGTH] = {0};

	_DBG(3, "%d, %d\n", pin, val);

	ret = encodeCMD(cmd, sizeof(cmd), sendCmd, &send_len);
	if (ret != 0){
		printk(KERN_ERR "coding buffer problem\n");
		goto out;
	}
	ret = picuart_rw(sendCmd, send_len, recvbuffer);
out:
	return ret;
}
EXPORT_SYMBOL(picuart_write_gpio);

int picuart_read_gpio(uint8_t pin, uint8_t *val)
{
	int ret = 0;
	uint8_t cmd[2] = {CMD_GPIO_READ, pin};
	uint8_t sendCmd[MAX_MSG_LENGTH] = {0};
	int send_len = 0;
	char recvbuffer[MAX_MSG_LENGTH] = {0};

	_DBG(2, "%d\n", pin);

	ret = encodeCMD(cmd, sizeof(cmd), sendCmd, &send_len);
	if (ret != 0){
		printk(KERN_ERR "coding buffer problem\n");
		goto out;
	}
	ret = picuart_rw(sendCmd, send_len, recvbuffer);
	if (ret == 0)
		*val = recvbuffer[0];
	_DBG(2, "value %d\n", *val);

out:
	return ret;
}
EXPORT_SYMBOL(picuart_read_gpio);

int picuart_read_version(char* version)
{
	int ret = 0;
	uint8_t cmd[1] = {CMD_VERSION};
	uint8_t sendCmd[MAX_MSG_LENGTH] = {0};
	int send_len = 0;

	_DBG(2, "\n");

	ret = encodeCMD(cmd, sizeof(cmd), sendCmd, &send_len);
	if (ret != 0){
		printk(KERN_ERR "coding buffer problem\n");
		goto out;
	}

	ret = picuart_rw(sendCmd, send_len, version);
	_DBG(2, "value %s\n", version);
out:
	return ret;
}
EXPORT_SYMBOL(picuart_read_version);

static ssize_t
picuart_proc_write(struct file *file, const char __user * buf,
                   size_t length, loff_t * ppos)
{
	char *buffer;
	int i, err, val, v1, v2;

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

	/*
     * Usage: echo "<item> [<index>] <value>" > /proc/picuart
     *        value    0:Off; 1:On; 2:Blink;
     *        "A_LED 1-N 0|1|2"               * SATA 1-N Active LED
     *        "GPIO N 0|1                     * Set GPIO[N] pin"
	 *        "Freq 1-152"                    * Blink frequency
	 * 
	 */
	if (!strncmp(buffer, "A_LED", strlen("A_LED"))) {
		i = sscanf(buffer + strlen("A_LED"), "%d %d\n", &v1, &v2);
		if (i == 2)		//two input
		{
			switch(v2){
			case 0: val = PM_LED_OFF;
				break;
			case 1: val = PM_LED_ON;
				break;
			case 2: val = PM_LED_BLINK;
				break;
			default: goto out;
				break;
			}

			if (v1 >= 1 && v1 <= 2) {
				v1 = v1 + 12;
				picuart_write_gpio(v1, val);
			}
		}
	} else if (!strncmp(buffer, "Freq", strlen("Freq"))) {
		i = sscanf(buffer + strlen("Freq"), "%d\n", &v1);
		if (i == 1)
		{
			val = (152 / v1) - 1;
			_DBG(1, "val=0x%02X\n", val);
			//picuart_rw(val2);
		}
	}else if (!strncmp(buffer, "GPIO", strlen("GPIO"))) {
		i = sscanf(buffer + strlen("GPIO"), "%d %d\n", &v1, &v2);
		if (i == 2)		//two input
		{
			switch(v2){
			case 0:
			case 1:
				val = v2;
				break;
			default: goto out;
				break;
			}

			picuart_write_gpio(v1, val);
		}
	}

	err = length;
out:
	free_page((unsigned long) buffer);
	*ppos = 0;

	return err;
}

static int picuart_proc_show(struct seq_file *m, void *v)
{
	int ret = 0;
	int i;
	char version[MAX_MSG_LENGTH];
	char val;
	char LED_STATUS[3][8];

	sprintf(LED_STATUS[PM_LED_ON], "ON");
	sprintf(LED_STATUS[PM_LED_OFF], "OFF");
	sprintf(LED_STATUS[PM_LED_BLINK], "BLINK");

	seq_printf(m, "8051 F/W Version: ");
	ret = picuart_read_version(version);
	if (ret)
		seq_printf(m, "read fails!\n");
	else
		seq_printf(m, "%s\n", version);

	for (i = 0; i < 2; i++) {
		seq_printf(m, "A_LED#%d: ", i+1);
		ret = picuart_read_gpio(SATA_LED(i), &val);
		if (ret)
			seq_printf(m, "read fails!\n");
		else
			seq_printf(m, "%s\n", LED_STATUS[val]);
	}

	seq_printf(m, "PWR_BTN: ");
	ret = picuart_read_gpio(PWR_BTN, &val);
	if (ret)
		seq_printf(m, "read fails!\n");
	else
		seq_printf(m, "%s\n", LED_STATUS[val]);

	seq_printf(m, "Lan PHY Reset: ");
	ret = picuart_read_gpio(LAN_PHY_RST, &val);
	if (ret)
		seq_printf(m, "read fails!\n");
	else
		seq_printf(m, "%d\n", val);

	seq_printf(m, "PCA9532 Reset: ");
	ret = picuart_read_gpio(PCA9532_RST, &val);
	if (ret)
		seq_printf(m, "read fails!\n");
	else
		seq_printf(m, "%d\n", val);

	return ret;
}

static int picuart_proc_open(struct inode *inode, struct file *file)
{
	return single_open(file, picuart_proc_show, NULL);
}

static struct file_operations proc_picuart_operations = {
	.open = picuart_proc_open,
	.read = seq_read,
	.write = picuart_proc_write,
	.llseek = seq_lseek,
	.release = single_release,
};

int picuart_init_procfs(void)
{
	struct proc_dir_entry *pde;

	pde = create_proc_entry("picuart", 0, NULL);
	if (!pde)
		return -ENOMEM;
	pde->proc_fops = &proc_picuart_operations;

	return 0;
}

void picuart_exit_procfs(void)
{
	remove_proc_entry("picuart", NULL);
}

static int __init picuart_gpio_init(void)
{
	int err = 0;
	char version[MAX_MSG_LENGTH];

	printk(KERN_INFO "picuart_gpio init\n");

	err = picuart_read_version(version);
	if (err)
		printk(KERN_ERR "Version read fails!\n");
	else
		printk(KERN_INFO "8051 F/W Version: %s\n", version);


	err = picuart_init_procfs();

	return err;
}

static void __exit picuart_gpio_exit(void)
{
	picuart_exit_procfs();
	printk(KERN_INFO "picuart_gpio exit\n");
}

MODULE_AUTHOR("Zeno Lai <zeno_lai@thecus.com>");
MODULE_DESCRIPTION("PIC UART GPIO Driver");
MODULE_LICENSE("GPL");
module_init(picuart_gpio_init);
module_exit(picuart_gpio_exit);
