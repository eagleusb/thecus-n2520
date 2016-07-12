/*
 *  Copyright (C) 2010-2013 Thecus Technology Corp. 
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * Driver for pca9532 chip on Thecus NAS
 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/i2c.h>
#include <linux/miscdevice.h>
#include <linux/proc_fs.h>
#include <linux/delay.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <linux/seq_file.h>

#include "pca9532.h"

// PCA9532 registers
#define PCA9532_REG_INPUT(i)  (0x0+(i))
#define PCA9532_REG_PSC(i)    (0x2+(i)*2)
#define PCA9532_REG_PWM(i)    (0x3+(i)*2)
#define PCA9532_REG_LS(i)     (0x6+(i))
// led: 0 ~ 15
#define LED_REG(led)          PCA9532_REG_LS(((led) & 0xF) >> 2)
#define LED_NUM(led)          ((led) & 0x3)

#define LED_OFF               0x0
#define LED_ON                0x1
#define LED_BLINK1            0x2
#define LED_BLINK2            0x3

//#define DEBUG
#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (debug>=x) printk(KERN_DEBUG"%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

static int debug = 2;
module_param(debug, int, S_IRUGO | S_IWUSR);

/* Addresses to scan */
static const unsigned short normal_i2c[] = { PCA_LED1, PCA_LED2, I2C_CLIENT_END };

struct pca9532_data {
    struct i2c_client *client;
    struct mutex update_lock;
	int kind;
};

enum chips {
	pca9532 = 0,
	pca9532_id
};

static const struct i2c_device_id pca9532_did[] = {
    { "pca9532",    pca9532 },
    { "pca9532_id", pca9532_id },
    {}
};
MODULE_DEVICE_TABLE(i2c, pca9532_did);

static struct i2c_client *pca9532_client = NULL;
static struct i2c_client *pca9532_id_client = NULL;

struct i2c_client* pca9532_get_client(u8 addr)
{
	struct i2c_client *client = NULL;
	switch(addr){
	case PCA_LED1: client = pca9532_client;
		break;
	case PCA_LED2: client = pca9532_id_client;
		break;
	}
	return client;
}

// led_num: 0 ~ 15, led_state: 0, 1, 2
void pca9532_set_ls(u8 addr, int led_num, int led_state)
{
    int reg;
    struct i2c_client *client = pca9532_get_client(addr);
    struct pca9532_data *data = NULL;

	if (client == NULL) {
		printk(KERN_INFO "pca9532_set_ls: i2c_client %x is NULL\n", addr);
		return;
	}

    data = i2c_get_clientdata(client);
    mutex_lock(&data->update_lock);
    reg = i2c_smbus_read_byte_data(client, LED_REG(led_num));
    /* zero led bits */
    reg = reg & ~(0x3 << (LED_NUM(led_num) * 2));
    /* set the new value */
    reg = reg | (led_state << (LED_NUM(led_num) * 2));
    i2c_smbus_write_byte_data(client, LED_REG(led_num), reg);
    mutex_unlock(&data->update_lock);
}
EXPORT_SYMBOL(pca9532_set_ls);

// led_num: 0 ~ 15, return: 0, 1, 2
int pca9532_get_ls(u8 addr, int led_num)
{
    int reg;
    struct i2c_client *client = pca9532_get_client(addr);
    struct pca9532_data *data = NULL;

	if (client == NULL) {
		printk(KERN_INFO "pca9532_get_ls: i2c_client %x is NULL\n", addr);
		return 0;
	}

    data = i2c_get_clientdata(client);
    mutex_lock(&data->update_lock);
    reg = i2c_smbus_read_byte_data(client, LED_REG(led_num));
    mutex_unlock(&data->update_lock);
    reg = 0x3 & (reg >> (LED_NUM(led_num) * 2));
    return reg;
}
EXPORT_SYMBOL(pca9532_get_ls);

// led_num: 0 ~ 15, return: 0, 1
int pca9532_get_inp(u8 addr, int led_num)
{
    int reg;
    struct i2c_client *client = pca9532_get_client(addr);
    struct pca9532_data *data = NULL;
    led_num = led_num & 0xF;

	if (client == NULL) {
		printk(KERN_INFO "pca9532_get_inp: i2c_client %x is NULL\n", addr);
		return 0;
	}

    data = i2c_get_clientdata(client);
    mutex_lock(&data->update_lock);
    reg = i2c_smbus_read_byte_data(client, PCA9532_REG_INPUT(led_num >> 3));
    mutex_unlock(&data->update_lock);
    reg = reg & (1 << (led_num & 0x7 ));

    return reg > 0 ? 1 : 0;
}
EXPORT_SYMBOL(pca9532_get_inp);

// Get register value
int pca9532_get_reg(u8 addr, int reg)
{
	int value;
    struct i2c_client *client = pca9532_get_client(addr);
	struct pca9532_data *data = NULL;

	if (client == NULL) {
		printk(KERN_INFO "pca9532_get_reg: i2c_client %x is NULL\n", addr);
		return -1;
	}

	data = i2c_get_clientdata(client);
	mutex_lock(&data->update_lock);
	value = i2c_smbus_read_byte_data(client, reg);
    mutex_unlock(&data->update_lock);

    return value;
}
EXPORT_SYMBOL(pca9532_get_reg);

/* return 0 for no error */
static int
pca9532_rw(struct i2c_client *client, u8 reg_num, u8 * val, int wr)
{
    int ret;
    struct pca9532_data *data = i2c_get_clientdata(client);

    if (client == NULL) {
	printk(KERN_INFO "pca9532_rw: i2c_client is NULL\n");
	return 1;
    }
    //_DBG(1, "pca9532_rw reg: %d, value: %d, %s\n", reg_num, *val,
    // (wr > 0) ? "write" : "read");
    if (wr) {			//Write
	mutex_lock(&data->update_lock);
	ret = i2c_smbus_write_byte_data(client, reg_num, *val);
	mutex_unlock(&data->update_lock);
	if (ret != 0) {
	    printk(KERN_INFO "pca9532_rw: cant write PCA9532 Reg#%02X\n",
		   reg_num);
	    return ret;
	}
    } else {			//Read
	mutex_lock(&data->update_lock);
	ret = i2c_smbus_read_byte_data(client, reg_num);
	mutex_unlock(&data->update_lock);
	if (ret < 0) {
	    printk(KERN_INFO "pca9532_rw: cant read PCA9532 Reg#%02X\n",
		   reg_num);
	    return ret;
	}
	*val = ret;
    }
    return 0;
}

static ssize_t
pca9532_proc_write(struct i2c_client *client, struct file *file,
                   const char __user * buf, size_t length, loff_t * ppos)
{
    char *buffer;
    int i, err, val, v1, v2;
    u8 val1, val2;

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
     * Usage: echo "S_LED 1-16 0|1|2" >/proc/pca9532 //2:Blink
     * Usage: echo "Freq 1-2 1-152" > /proc/pca9532
     * Usage: echo "Duty 1-2 1-256" > /proc/pca9532
     * 
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

	    if (v1 >= 1 && v1 <= 16) {
		v1 = v1 - 1;
		pca9532_set_ls(client->addr, v1, val);
	    }
	}
    } else if (!strncmp(buffer, "Freq", strlen("Freq"))) {
	i = sscanf(buffer + strlen("Freq"), "%d %d\n", &v1, &v2);
	if (i == 2)		//two input
	{
	    if (v1 == 1)	//input 1: PSC0
		val = PCA9532_REG_PSC(0);
	    else
		val = PCA9532_REG_PSC(1);

	    val2 = (152 / v2) - 1;
	    _DBG(1, "port=0x%02X,val=0x%02X\n", val, val2);
	    pca9532_rw(client, val, &val2, 1);
	}
    } else if (!strncmp(buffer, "Duty", strlen("Duty"))) {
	i = sscanf(buffer + strlen("Duty"), "%d %d\n", &v1, &v2);
	if (i == 2)		//two input
	{
	    if (v1 == 1)	//input 1: PWM0
		val1 = PCA9532_REG_PWM(0);
	    else
		val1 = PCA9532_REG_PWM(1);

	    val2 = (v2 * 256) / 100;
	    pca9532_rw(client, val1, &val2, 1);
	}
    } else;

    err = length;
  out:
    free_page((unsigned long) buffer);
    *ppos = 0;

    return err;
}

static int 
pca9532_proc_show(struct i2c_client *client, struct seq_file *m, void *v)
{
    int i, val3;
    u8 val1, val2;
    char LED_STATUS[4][8];

    sprintf(LED_STATUS[LED_ON], "ON");
    sprintf(LED_STATUS[LED_OFF], "OFF");
    sprintf(LED_STATUS[LED_BLINK1], "BLINK");
    sprintf(LED_STATUS[LED_BLINK2], "-");

    if (client) {
	int j = 0;

        val3 = i2c_smbus_read_byte_data(client, 0);	// val3 may < 0 when error
	val1 = val3;
        seq_printf(m, "INPUT0: %02X\n", val1);

//        val1 = i2c_smbus_read_byte_data(pca9532_client, 1);
//        seq_printf(m, "INPUT1: %02X\n", val1);

	for (j = 0; j < 4; j++) {
	    if (!pca9532_rw(client, PCA9532_REG_LS(j), &val1, 0)) {
		for (i = 0; i < 4; i++) {
		    val2 = (val1 >> (i * 2)) & 0x3;
		    seq_printf(m, "S_LED#%d: %s\n", j * 4 + (i + 1),
			       LED_STATUS[val2]);
		}
	    }
	}
    }
    return 0;
}

static ssize_t
proc_pca9532_write(struct file *file, const char __user * buf,
		   size_t length, loff_t * ppos)
{
	return pca9532_proc_write(pca9532_client, file, buf, length, ppos);
}

static ssize_t
proc_pca9532_id_write(struct file *file, const char __user * buf,
		   size_t length, loff_t * ppos)
{
	return pca9532_proc_write(pca9532_id_client, file, buf, length, ppos);
}

static int proc_pca9532_show(struct seq_file *m, void *v)
{
	return pca9532_proc_show(pca9532_client, m, v);
}

static int proc_pca9532_id_show(struct seq_file *m, void *v)
{
	return pca9532_proc_show(pca9532_id_client, m, v);
}

static int proc_pca9532_open(struct inode *inode, struct file *file)
{
    return single_open(file, proc_pca9532_show, NULL);
}

static int proc_pca9532_id_open(struct inode *inode, struct file *file)
{
    return single_open(file, proc_pca9532_id_show, NULL);
}

static struct file_operations proc_pca9532_operations[2] = {
	{
		.open = proc_pca9532_open,
		.read = seq_read,
		.write = proc_pca9532_write,
		.llseek = seq_lseek,
		.release = single_release,
	},{
		.open = proc_pca9532_id_open,
		.read = seq_read,
		.write = proc_pca9532_id_write,
		.llseek = seq_lseek,
		.release = single_release,
	}
};

int pca9532_init_procfs(struct i2c_client *client)
{
	struct pca9532_data *data = i2c_get_clientdata(client);
    struct proc_dir_entry *pde;

	pde = create_proc_entry(client->name, 0, NULL);
	if (!pde)
		return -ENOMEM;
	pde->proc_fops = &proc_pca9532_operations[data->kind];

	return 0;
}

void pca9532_exit_procfs(struct i2c_client *client)
{
	remove_proc_entry(client->name, NULL);
}

/* Return 0 if detection is successful, -ENODEV otherwise */
static int pca9532_detect(struct i2c_client *client,
			  struct i2c_board_info *info)
{
    struct i2c_adapter *adapter = client->adapter;
    unsigned short address = client->addr;
    const char *chip_name;

	switch(client->addr){
	case PCA_LED1:
		chip_name = "pca9532";
		break;
	case PCA_LED2:
		chip_name = "pca9532_id";
		break;
	}

    strlcpy(info->type, chip_name, I2C_NAME_SIZE);
    dev_info(&adapter->dev, "Found %s at 0x%02hx\n", chip_name, address);

    return 0;
}

static int pca9532_probe(struct i2c_client *client,
			 const struct i2c_device_id *id)
{
    struct pca9532_data *data;
    int err = 0;
    u8 val2;
    int i;

    if (!i2c_check_functionality(client->adapter,
				 I2C_FUNC_SMBUS_BYTE_DATA))
	return -EIO;

    data = kzalloc(sizeof(*data), GFP_KERNEL);
    if (!data)
	return -ENOMEM;

    dev_info(&client->dev, "setting platform data\n");
    data->client = client;
    i2c_set_clientdata(client, data);
    mutex_init(&data->update_lock);
	data->kind = id->driver_data;

	switch(client->addr){
	case PCA_LED1:
    	pca9532_client = client;
		break;
	case PCA_LED2:
		pca9532_id_client = client;
		break;
	}

    // initial value, led blink frequency
    // echo "Freq 1 3" > /proc/thecus_io
    val2 = (152 / 3) - 1;
    pca9532_rw(client, PCA9532_REG_PSC(0), &val2, 1);

    // turn off all led
    for (i = 0; i < 16; i++)
       pca9532_set_ls(client->addr, i, LED_OFF);

	if (pca9532_init_procfs(client)) {
		printk(KERN_ERR "pca9532: cannot create /proc/%s.\n", client->name);
		return -ENOENT;
	}

    return err;
}

static int pca9532_remove(struct i2c_client *client)
{
    struct pca9532_data *data = i2c_get_clientdata(client);
    kfree(data);
    pca9532_exit_procfs(client);
    i2c_set_clientdata(client, NULL);
    return 0;
}

static struct i2c_driver pca9532_driver = {
    .driver = {
	       .name = "pca9532",
	       },
    .probe = pca9532_probe,
    .remove = pca9532_remove,
    .id_table = pca9532_did,

    .class = I2C_CLASS_HWMON,
    .detect = pca9532_detect,
    .address_list = normal_i2c,
};

static int __init pca9532_init(void)
{
    printk("pca9532_init\n");
    return (i2c_add_driver(&pca9532_driver));
}

static void __exit pca9532_exit(void)
{
    i2c_del_driver(&pca9532_driver);
	pca9532_client = NULL;
	pca9532_id_client = NULL;
}
MODULE_AUTHOR("Maintainer: Citizen Lee <citizen_lee@thecus.com>");
MODULE_DESCRIPTION("Thecus GPIO (pca9532) Driver");
MODULE_LICENSE("GPL");

module_init(pca9532_init);
module_exit(pca9532_exit);
