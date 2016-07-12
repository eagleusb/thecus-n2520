/*
 *  Copyright (C) 2006-2013 Thecus Technology Corp. 
 *
 *    Maintainer: citizen <citizen_lee@thecus.com>
 *                Zeno Lai <zeno_lai@thecus.com>
 *
 *    porting from thecus N2100 by citizen Lee (citizen_lee@thecus.com)
 *
 *    Written by Y.T. Lee (yt_lee@thecus.com)
 *
 *    add support F75387S by citizen Lee (citizen_lee@thecus.com)
 *
 *    Merge f75387sg1 and f75387sg2 as one driver, revise to add full
 *    support to F75387SG by Zeno Lai <zeno_lai@thecus.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * Driver for Fintek F75387SG chip on Thecus 1U4800R/S FAN1/FAN2
 *                                           N2560/N4560
 */
#include <linux/kcompat.h>

#define F75375_CHIP_ID	0x0306
#define F75387_CHIP_ID	0x0410

/* Fintek F75375 registers  */
#define F75375_REG_CONFIG0              0x0
#define F75375_REG_CONFIG1              0x1
#define F75375_REG_CONFIG2              0x2
#define F75375_REG_CONFIG3              0x3
#define F75375_REG_ADDR                 0x4
#define F75375_REG_INTR                 0x31
#define F75375_REG_CHIP_ID              0x5A
#define F75375_REG_VERSION              0x5C
#define F75375_REG_VENDOR               0x5D
#define F75375_REG_FAN_TIMER            0x60
#define F75375_REG_FAN_FAULT            0x61

#define F75375_REG_VOLT(nr)             (0x10 + (nr))
#define F75375_REG_VOLT_HIGH(nr)        (0x20 + (nr) * 2)
#define F75375_REG_VOLT_LOW(nr)         (0x21 + (nr) * 2)

#define F75375_REG_TEMP(nr)             (0x14 + (nr))
#define F75375_REG_LOTEMP               0x1C
#define F75387_REG_TEMP11_LSB(nr)       (0x1a + (nr))
#define F75387_REG_LOTEMP11_LSB         0x1D
#define F75375_REG_TEMP_HIGH(nr)        (0x28 + (nr) * 2)
#define F75375_REG_TEMP_HYST(nr)        (0x29 + (nr) * 2)

#define F75375_REG_FAN(nr)              (0x16 + (nr) * 2)
#define F75375_REG_FAN_MIN(nr)          (0x2C + (nr) * 2)
#define F75375_REG_FAN_FULL(nr)         (0x70 + (nr) * 0x10)
#define F75375_REG_FAN_PWM_DUTY(nr)     (0x76 + (nr) * 0x10)
#define F75375_REG_FAN_PWM_CLOCK(nr)    (0x7D + (nr) * 0x10)

#define F75375_REG_FAN_EXP(nr)          (0x74 + (nr) * 0x10)
#define F75375_REG_FAN_B_TEMP(nr, step) ((0xA0 + (nr) * 0x10) + (step))
#define F75375_REG_FAN_B_SPEED(nr, step) \
        ((0xA5 + (nr) * 0x10) + (step) * 2)
#define F75387_REG_FAN_B_SPEED(nr, step) \
        ((0xA4 + (nr) * 0x10) + (step))

#define F75375_REG_PWM1_RAISE_DUTY      0x69
#define F75375_REG_PWM2_RAISE_DUTY      0x6A
#define F75375_REG_PWM1_DROP_DUTY       0x6B
#define F75375_REG_PWM2_DROP_DUTY       0x6C


#define F75375_FAN_CTRL_LINEAR(nr)      (4 + nr)
#define F75387_FAN_CTRL_LINEAR(nr)      (1 + ((nr) * 4))
#define FAN_CTRL_MODE(nr)               (4 + ((nr) * 2))
//#define F75387_FAN_DUTY_MODE(nr)        (2 + ((nr) * 4))
//#define F75387_FAN_MANU_MODE(nr)        ((nr) * 4)

/* Pin assignment*/
#define F75387_FAN_MANU_MODE(nr)        (0x1 << ((nr) * 4))
#define F75387_FAN_DAC_MODE(nr)         (0x2 << ((nr) * 4))
#define F75387_FAN_DUTY_MODE(nr)        (0x4 << ((nr) * 4))
#define F75387_PWM_PAD_TYPE(nr)         (0x8 << ((nr) * 4))


#define T_UNIT                          256

#define DEBUG 1
#define I2C_RETRY 2

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (debug>=x) printk("%s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

MODULE_AUTHOR("Y.T. Lee <yt_lee@thecus.com>");
MODULE_DESCRIPTION("Fintek F75387SG Driver");
MODULE_LICENSE("GPL");
static int debug;
module_param(debug, int, S_IRUGO | S_IWUSR);
static int hwm = 0;
module_param(hwm, int, S_IRUGO);

#define HWM_PROC                   "hwm"
char *proc_name = "";

static u8 btemp[2][4] = {
	{55, 40, 35, 25},
	{55, 40, 35, 25}
};

static int duty[2][5] = {
	{100, 50, 30, 22, 0},
	{100, 50, 30, 22, 0}
};

struct f75387sg_data {
	struct i2c_client *client;
	struct mutex update_lock;
	u8 ctrl;
	u16 chipid;
	int kind;
};

static struct i2c_client *f75387sg1_client = NULL;
static struct i2c_client *f75387sg2_client = NULL;

/* Addresses to scan */
#define SG1	   0x2d
#define SG2	   0x2e
static const unsigned short normal_i2c[] = { SG1, SG2, I2C_CLIENT_END };

enum chips {
	f75387sg1 = 0,
	f75387sg2,
	f75375s
};

static const struct i2c_device_id f75387sg_id[] = {
	{ "f75387sg1", f75387sg1 },
	{ "f75387sg2", f75387sg2 },
	{ "F75375S",   f75375s },
	{}
};
MODULE_DEVICE_TABLE(i2c, f75387sg_id);

static int pulse = 1;

static struct i2c_client* f75387sg_get_client(u8 addr)
{
	struct i2c_client *client = NULL;
	switch(addr){
	case SG1:
		client = f75387sg1_client;
		break;
	case SG2:
		client = f75387sg2_client;
		break;
	}

	return client;
}

/* return 0 for no error */
static int f75387sg_rw(u8 addr, u8 reg_num, u8 * val, int wr)
{
	struct i2c_client *client = f75387sg_get_client(addr);
	int ret = 0;
	int i, try_time = I2C_RETRY;

	if (client == NULL) {
		printk(KERN_INFO "f75387sg_rw: i2c_client is NULL\n");
		return 1;
	}

	for (i = 0; i < try_time; i++) {
		if (wr) {		//Write
			ret = i2c_smbus_write_byte_data(client, reg_num, *val);
		} else {		//Read
			*val = 0;
			ret = i2c_smbus_read_byte_data(client, reg_num);
			if (ret > 0) {
				*val = ret;
			}
		}
		if (ret >= 0)
			break;
		udelay(50);
	}
	if (wr) {			//Write
		if (ret < 0) {
			dev_info(&client->dev, "write Reg#%#04x value=%d error (%d)\n",
				reg_num, *val, ret);
			return 1;
		}
	} else {			//Read
		if (ret < 0) {
			dev_info(&client->dev, "read Reg#%#04x error (%d)\n",
				reg_num, ret);
			return 1;
		}
	}
	return 0;
}
EXPORT_SYMBOL(f75387sg_rw);

static int f75387sg_rw16(u8 addr, u8 reg_num, u16 * val, int wr)
{
	int ret;
	u8 hb =0, lb =0;

	// write command, set val to hb and lb.
	if (wr){
		hb = *val >> 8;
		lb = *val & 0x00FF;
	}

	ret = f75387sg_rw(addr, reg_num, &hb, wr);
	if (ret)
		goto out;
	ret = f75387sg_rw(addr, reg_num + 1, &lb, wr);
	if (ret)
		goto out;

	// read command, set val by hd and lb.
	if (!wr)
		*val = (hb << 8) | lb;

out:
	return ret;
}

static void set_auto_pwm_duty(u8 addr, int no)
{
	int i;
	u8 val;
	for ( i = 0; i < 5; i++ ){
		val = 0xFF * duty[no][i] / 100;
		f75387sg_rw(addr, F75387_REG_FAN_B_SPEED(no, i), &val, 1);
		if (i < 4) // there are only 4 BT for each VT
			f75387sg_rw(addr, F75375_REG_FAN_B_TEMP(no, i), &btemp[no][i], 1);
	}
}

static void f75387sg_reset(struct i2c_client *client)
{
	struct f75387sg_data *data = i2c_get_clientdata(client);
	u8 val1, val2;

	val2 = 0x80;
	_DBG(1, "Write reg 0x%X=0x%02X\n", F75375_REG_CONFIG0, val2);
	f75387sg_rw(client->addr, F75375_REG_CONFIG0, &val2, 1);
	val2 = 0x01;
	_DBG(1, "Write reg 0x%X=0x%02X\n", F75375_REG_CONFIG0, val2);
	f75387sg_rw(client->addr, F75375_REG_CONFIG0, &val2, 1);

	if (data->chipid == F75375_CHIP_ID) {
		//Set reg 0xF0 bit2 to enabled
		val1 = 0xF0;
		f75387sg_rw(client->addr, val1, &val2, 0);
		val2 = 0x2;
		_DBG(1, "Set F75387SG register 0x%02X value to 0x%02X\n", val1, val2);
		f75387sg_rw(client->addr, val1, &val2, 1);
	}
	f75387sg_rw(client->addr, F75375_REG_CONFIG1, &val1, 0);
	// Set fan full duty (bit6) and 
	// VT1, VT2 (bit[3:2]) to 0 as thermistor mode
	val1 = 0x43;
	//val1 &= ~(0x0C);	// VT1,VT2 is connected to a thermistor
	f75387sg_rw(client->addr, F75375_REG_CONFIG1, &val1, 1);
	// set de-bounce circuit, FAN1_DEB, FAN2_DEB
	// 0:1.28ms; 1:640us. We set both fans as 640us mode.
	f75387sg_rw(client->addr, F75375_REG_FAN_FAULT, &val1, 0);
	val1 |= 0xC0;
	f75387sg_rw(client->addr, F75375_REG_FAN_FAULT, &val1, 1);
}

/*
 * RPM = 1.5 x 1000000 / Count
 * Count = Speed count stored in FAN registers.
 *
 * Usage:
 *
 *     fan[N] speed <rpm>                  : set fanN RPM manually
 *     fan[N] duty  <duty>                 : set fanN PWM duty manually
 *             duty value - 0~255
 *     fan[N] [pwm|auto]                   : set fanN as auto mode
 *             N:[1|2]
 *     fan1 pulse                          : set pulse value
 *     reset                               : reset chip to default
 *     fix                                 : (F75375 only)
 *     BT  [B] <temp>                      : set VT1 boundary temperature
 *     BT2 [B] <temp>                      : set VT2 boundary temperature
 *             B:[0|1|2|3]
 *     FAN_BS [N] [S] <duty>               : set fanN's S segment duty
 *             N:[1|2]
 *             S:[0|1|2|3|4]
 *             duty value - 0~255
 *     REG [R/W] <addr> <val>              : set register directly
 *             [R/W]:[0/1]
 */
static ssize_t
f75387sg_proc_write(struct i2c_client *client, struct file *file,
                    const char __user * buf, size_t length, loff_t * ppos)
{
	struct f75387sg_data *data = i2c_get_clientdata(client);
	char *buffer;
	int i, err, v1, v2, v0;
	u8 val1, val2;
	u16 val16;

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

	if (!strncmp(buffer, "fan1 speed", strlen("fan1 speed"))) {
		i = sscanf(buffer + strlen("fan1 speed"), "%d", &v2);
		if (i == 1) {
			if (data->chipid == F75375_CHIP_ID) {
				f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
				// speed mode
				val1 &= ~(0x11 << 4);
				f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
			} else if (data->chipid == F75387_CHIP_ID) {
				f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
				// set mode to manu|pwm|exp_rpm
				val1 |= (F75387_FAN_MANU_MODE(0));
				val1 &= ~(F75387_FAN_DAC_MODE(0));
				val1 &= ~(F75387_FAN_DUTY_MODE(0));
				f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
			}
			// set expected RPM
			val16 = (u16)(1500000 / v2);
			_DBG(1, "Write reg 0x%02X=0x%04X\n", F75375_REG_FAN_EXP(0), val16);
			f75387sg_rw16(client->addr, F75375_REG_FAN_EXP(0), &val16, 1);
		}
	} else if (!strncmp(buffer, "fan2 speed", strlen("fan2 speed"))) {
		i = sscanf(buffer + strlen("fan2 speed"), "%d", &v2);
		if ((i == 1) && (data->chipid == F75387_CHIP_ID)) {
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
			// set mode to manu|pwm|exp_rpm
			val1 |= (F75387_FAN_MANU_MODE(1));
			val1 &= ~(F75387_FAN_DAC_MODE(1));
			val1 &= ~(F75387_FAN_DUTY_MODE(1));
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
			// set expected RPM
			val16 = (u16)(1500000 / v2);
			_DBG(1, "Write reg 0x%02X=0x%04X\n", F75375_REG_FAN_EXP(1), val16);
			f75387sg_rw16(client->addr, F75375_REG_FAN_EXP(1), &val16, 1);
		}
	} else if (!strncmp(buffer, "fan1 duty", strlen("fan1 duty"))) {
		if (data->chipid == F75375_CHIP_ID) {
			i = sscanf(buffer + strlen("fan1 duty"), "%x", &v2);
			if (i == 1) {
				val2 = v2;
				_DBG(1, "Write reg 0x%X=0x%02X\n", F75375_REG_FAN_PWM_DUTY(0),
					val2);
				f75387sg_rw(client->addr, F75375_REG_FAN_PWM_DUTY(0), &val2, 1);
			}
		} else if (data->chipid == F75387_CHIP_ID) {
			i = sscanf(buffer + strlen("fan1 duty"), "%d", &v2);
			if (i == 1) {
				f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
				// set mode to manu|pwm|exp_duty
				val1 |= (F75387_FAN_MANU_MODE(0));
				val1 &= ~(F75387_FAN_DAC_MODE(0));
				val1 |= (F75387_FAN_DUTY_MODE(0));
				f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
				// set expected PWM duty
				val16 = (u16) v2;
				_DBG(1, "Write reg 0x%02X=0x%04X\n",
					F75375_REG_FAN_EXP(0), val16);
				f75387sg_rw16(client->addr, F75375_REG_FAN_EXP(0), &val16, 1);
			}
		}
	} else if (!strncmp(buffer, "fan2 duty", strlen("fan2 duty"))) {
		i = sscanf(buffer + strlen("fan2 duty"), "%d", &v2);
		if ((i == 1) && (data->chipid == F75387_CHIP_ID)) {
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
			// set mode to manu|pwm|exp_duty
			val1 |= (F75387_FAN_MANU_MODE(1));
			val1 &= ~(F75387_FAN_DAC_MODE(1));
			val1 |= (F75387_FAN_DUTY_MODE(1));
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
			// set expected PWM duty
			val16 = (u16) v2;
			_DBG(1, "Write reg 0x%02X=0x%04X\n", F75375_REG_FAN_EXP(1), val16);
			f75387sg_rw16(client->addr, F75375_REG_FAN_EXP(1), &val16, 1);
		}
	} else if ((!strncmp(buffer, "fan1 pwm", strlen("fan1 pwm")))
	       || (!strncmp(buffer, "fan1 auto", strlen("fan1 auto")))) {
		if (data->chipid == F75375_CHIP_ID) {
			f75387sg_rw(client->addr, F75375_REG_CONFIG1, &val1, 0);
			val1 &= ~(0x1 << 4);	// pwm
			f75387sg_rw(client->addr, F75375_REG_CONFIG1, &val1, 1);

			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
			_DBG(1, "1 VAL1=%X\n", val1);
			val1 &= ~(0x11 << 4);
			val1 |= (0x1F);
			_DBG(1, "1 VAL1=%X\n", val1);
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
		} else if (data->chipid == F75387_CHIP_ID) {
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
			// set mode to auto|pwm|duty
			val1 &= ~(F75387_FAN_MANU_MODE(0));
			val1 &= ~(F75387_FAN_DAC_MODE(0));
			val1 |= (F75387_FAN_DUTY_MODE(0));
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
			// Set FAN1 PWM DUTY[1~5]
			set_auto_pwm_duty(client->addr, 0);
		}
	} else if ((!strncmp(buffer, "fan2 pwm", strlen("fan2 pwm")))
	       || (!strncmp(buffer, "fan2 auto", strlen("fan2 auto")))) {
		if (data->chipid == F75387_CHIP_ID) {
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0);
			// set mode to auto|pwm|duty
			val1 &= ~(F75387_FAN_MANU_MODE(1));
			val1 &= ~(F75387_FAN_DAC_MODE(1));
			val1 |= (F75387_FAN_DUTY_MODE(1));
			f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 1);
			// Set FAN2 PWM DUTY[1~5]
			set_auto_pwm_duty(client->addr, 1);
		}
	} else if (!strncmp(buffer, "fan1 pulse", strlen("fan1 pulse"))) {
		i = sscanf(buffer + strlen("fan1 pulse"), "%d\n", &v2);
		pulse = v2;
	} else if (!strncmp(buffer, "reset", strlen("reset"))) {
		f75387sg_reset(client);
	} else if (!strncmp(buffer, "fix", strlen("fix"))) {
		if (data->chipid == F75375_CHIP_ID) {
			val1 = 0x11;
			f75387sg_rw(client->addr, 0x6D, &val1, 1);
		}
	} else if (!strncmp(buffer, "BT ", strlen("BT "))) {
		i = sscanf(buffer + strlen("BT "), "%d %d\n", &v1, &v2);
		//two input and 4 boundaries
		if ((i == 2) && (v1 >= 0) && (v1 < 4))
		{
			val1 = F75375_REG_FAN_B_TEMP(0, v1);
			btemp[0][v1] = v2;
			_DBG(1, "Write reg 0x%X=0x%X\n", val1, btemp[0][v1]);
			f75387sg_rw(client->addr, val1, &btemp[0][v1], 1);
		}
	} else if (!strncmp(buffer, "BT2", strlen("BT2"))) {
		i = sscanf(buffer + strlen("BT2"), "%d %d\n", &v1, &v2);
		//two input and 4 boundaries
		if ((i == 2) && (v1 >= 0) && (v1 < 4))
		{
			val1 = F75375_REG_FAN_B_TEMP(1, v1);
			btemp[1][v1] = v2;
			_DBG(1, "Write reg 0x%X=0x%X\n", val1, btemp[1][v1]);
			f75387sg_rw(client->addr, val1, &btemp[1][v1], 1);
		}
	} else if (!strncmp(buffer, "FAN_BS", strlen("FAN_BS"))) {
		// set FAN segment speed: <fan no> <seg N> <duty>
		if (data->chipid != F75387_CHIP_ID)
			goto out;

		i = sscanf(buffer + strlen("FAN_BS"), "%d %d %d\n", &v0, &v1, &v2);
		// F75387 only has 2 fans and 5 speed segments.
		v0--;
		if ((i == 3) && (v0 >= 0) && (v0 < 2) && (v1 >= 0) && (v1 < 5))
		{
			val1 = F75387_REG_FAN_B_SPEED(v0, v1);
			val2 = v2;
			// update duty settings
			duty[v0][v1] = v2;
			f75387sg_rw(client->addr, F75387_REG_FAN_B_SPEED(v0, v1), &val2, 1);
		}
	} else if (!strncmp(buffer, "REG", strlen("REG"))) {
		i = sscanf(buffer + strlen("REG"), "%d %x %x\n", &v0, &v1, &v2);
		// set register: REG <R/W> <Reg addr> [value]
		//     [R/W]:[0/1]
		val1 = v1;
		val2 = v2;
		if ((v0 == 0) && (i == 2)){
			// read register, two input
			f75387sg_rw(client->addr, val1, &val2, 0);
			printk(KERN_INFO "f75387sg: Read reg 0x%02X=0x%02X(%d)\n",
				val1, val2, val2);
		} else if ((v0 == 1) && (i == 3)) {
			// write register, three input
			_DBG(1, "Write reg 0x%02X=0x%02X(%d)\n", val1, val2, val2);
			f75387sg_rw(client->addr, val1, &val2, 1);
		}
	}

	err = length;
out:
	free_page((unsigned long) buffer);
	*ppos = 0;

	return err;
}


static int
f75387sg_proc_show(struct i2c_client *client, struct seq_file *m, void *v)
{
	struct f75387sg_data *data = i2c_get_clientdata(client);
	int i, j;
	u8 val1, val2;
	u8 temp1 = 0, temp2 = 0, temp3 = 0;
	int fan1 = 0, fan2 = 0;
	u16 val16;

	if (client == NULL) {
		seq_printf(m, "F75387SG device not found\n");
		return 0;
	}

	if (!f75387sg_rw(client->addr, F75375_REG_ADDR, &val1, 0)) {
		seq_printf(m, "Address: %02X\n", val1);
	}

	if (!f75387sg_rw(client->addr, F75375_REG_VERSION, &val1, 0)) {
		seq_printf(m, "Version: %02X\n", val1);
	}

	if (data->chipid == F75375_CHIP_ID)
		seq_printf(m, "Chip: F75375\n");
	else if (data->chipid == F75387_CHIP_ID)
		seq_printf(m, "Chip: F75387\n");

	if (!f75387sg_rw(client->addr, F75375_REG_TEMP(0), &temp1, 0)) {
		seq_printf(m, "Temp 1: %d", temp1);
		if (data->chipid == F75387_CHIP_ID){
			f75387sg_rw(client->addr, F75387_REG_TEMP11_LSB(0), &val1, 0);
			seq_printf(m, ".%03d", (val1 * 1000)/T_UNIT);
		}
		seq_printf(m, "\n");
	}
	if (!f75387sg_rw(client->addr, F75375_REG_TEMP(1), &temp2, 0)) {
		seq_printf(m, "Temp 2: %d", temp2);
		if (data->chipid == F75387_CHIP_ID){
			f75387sg_rw(client->addr, F75387_REG_TEMP11_LSB(1), &val1, 0);
			seq_printf(m, ".%03d", (val1 * 1000)/T_UNIT);
		}
		seq_printf(m, "\n");
	}
	if (data->chipid == F75387_CHIP_ID) {
		if (!f75387sg_rw(client->addr, F75375_REG_LOTEMP, &temp3, 0)) {
			f75387sg_rw(client->addr, F75387_REG_LOTEMP11_LSB, &val2, 0);
			seq_printf(m, "Temp 3: %d.%03d\n", temp3, (val2 * 1000)/T_UNIT);
		}
	}

	if (!f75387sg_rw16(client->addr, F75375_REG_FAN_EXP(0), &val16, 0)) {
		seq_printf(m, "FAN 1 Expected counter: %04X\n", val16);
	}

	if (!f75387sg_rw16(client->addr, F75375_REG_FAN_EXP(1), &val16, 0)) {
		seq_printf(m, "FAN 2 Expected counter: %04X\n", val16);
	}

	if (data->chipid == F75375_CHIP_ID) {
		if (!f75387sg_rw(client->addr, F75375_REG_PWM1_RAISE_DUTY, &val1, 0)) {
			seq_printf(m, "PWM 1 Raise duty: %02X\n", val1);
		}
		if (!f75387sg_rw(client->addr, F75375_REG_PWM1_DROP_DUTY, &val1, 0)) {
			seq_printf(m, "PWM 1 Drop duty: %02X\n", val1);
		}
		if (!f75387sg_rw(client->addr, F75375_REG_FAN_PWM_DUTY(0), &val1, 0)) {
			seq_printf(m, "PWM 1 duty: %02X\n", val1);
		}
		if (!f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0)) {
			seq_printf(m, "Reset timer control: %02X\n", val1);
		}
		if (!f75387sg_rw(client->addr, F75375_REG_CONFIG1, &val1, 0)) {
			if (val1 & 0x10)
				seq_printf(m, "FAN 1 in Linear mode(%02X)\n", val1);
			else
				seq_printf(m, "FAN 1 in PWM mode(%02X)\n", val1);
		}
	} else if (data->chipid == F75387_CHIP_ID) {
		//seq_printf(m, "PWM 1 Min duty: 0x%02X\n", val1 & 0x0F);
		if (!f75387sg_rw(client->addr, F75375_REG_FAN_PWM_DUTY(0), &val1, 0)) {
			seq_printf(m, "PWM 1 duty: 0x%02X\n", val1);
		}
		if (!f75387sg_rw(client->addr, F75375_REG_FAN_PWM_DUTY(1), &val1, 0)) {
			seq_printf(m, "PWM 2 duty: 0x%02X\n", val1);
		}

		if (!f75387sg_rw(client->addr, F75375_REG_FAN_TIMER, &val1, 0)) {
			for (i = 0; i < 2; i++){
				seq_printf(m, "FAN%d mode Register: 0x%02X ", i+1, val1);
				if (val1 & F75387_FAN_MANU_MODE(i))
					seq_printf(m, " MANU");
				else
					seq_printf(m, " AUTO");

				if (val1 & F75387_FAN_DAC_MODE(i))
					seq_printf(m, " DAC");
				else
					seq_printf(m, " PWM");

				if (val1 & F75387_FAN_DUTY_MODE(i))
					seq_printf(m, " DUTY");
				else
					seq_printf(m, " RPM");

				if (val1 & F75387_PWM_PAD_TYPE(i))
					seq_printf(m, " OPEN\n");
				else
					seq_printf(m, " PUSH\n");
			}
		}
	}
	if (!f75387sg_rw16(client->addr, F75375_REG_FAN(0), &val16, 0)){
		i = val16;
		i *= pulse;
		if (i == 0)
			i = 1;		// avoid divide by zero
		if (((data->chipid == F75375_CHIP_ID) && (i == 0xFFFF))
			|| ((data->chipid == F75387_CHIP_ID)
			&& (i == 0x0FFF || i == 0x0FFE)))
			fan1 = 0;
		else
			fan1 = 1500000 / i;

		seq_printf(m, "FAN 1 RPM: %d (0x%04X,%d,0x%04X)\n", fan1, i, i, val16);
	}
	if (!f75387sg_rw16(client->addr, F75375_REG_FAN(1), &val16, 0)){
		i = val16;
		i *= pulse;
		if (i == 0)
			i = 1;		// avoid divide by zero
		if (((data->chipid == F75375_CHIP_ID) && (i == 0xFFFF))
			|| ((data->chipid == F75387_CHIP_ID)
			&& (i == 0x0FFF || i == 0x0FFE)))
			fan2 = 0;
		else
			fan2 = 1500000 / i;

		seq_printf(m, "FAN 2 RPM: %d (0x%04X,%d,0x%04X)\n", fan2, i, i, val16);
	}
	if (!f75387sg_rw16(client->addr, F75375_REG_FAN_FULL(0), &val16, 0)){
		i = val16;
		if (i == 0)
			i = 1;		// avoid divide by zero
		if (((data->chipid == F75375_CHIP_ID) && (i == 0xFFFF))
			|| ((data->chipid == F75387_CHIP_ID) && (i == 0x0FFF)))
			seq_printf(m, "FAN 1 top RPM: %d (0x%02X,%d)\n", 0, i, i);
		else
			seq_printf(m, "FAN 1 top RPM: %d (0x%02X,%d)\n", 1500000 / i,
				i, i);
	}
	if (!f75387sg_rw16(client->addr, F75375_REG_FAN_FULL(1), &val16, 0)){
		i = val16;
		if (i == 0)
			i = 1;		// avoid divide by zero
		if (((data->chipid == F75375_CHIP_ID) && (i == 0xFFFF))
			|| ((data->chipid == F75387_CHIP_ID) && (i == 0x0FFF)))
			seq_printf(m, "FAN 2 top RPM: %d (0x%02X,%d)\n", 0, i, i);
		else
			seq_printf(m, "FAN 2 top RPM: %d (0x%02X,%d)\n", 1500000 / i,
				i, i);
	}
	/* Registers for 'FAN control v.s. Temperature' */
	for (i = 0; i < 2; i++){
		seq_printf(m, "FAN%d control v.s. Temperature%d\n", i+1, i+1);
		for (j = 0; j < 9; j++) {
			if (!f75387sg_rw(client->addr, F75375_REG_FAN_B_TEMP(i,j),
				&val1, 0))
				seq_printf(m, "Reg 0x%2X: 0x%02X(%3d)",
					F75375_REG_FAN_B_TEMP(i,j), val1, val1);
			seq_printf(m, "\n");
		}
	}

	/*
	 *  This is by HW design, we can't fix these definitions unless
	 *  HW provides a fixed configuration.
	 */
	/*
	 *  The HDD_FANx represents system fan x.
	 *  i.e. HDD_FAN1 --> system fan 1
	 *       HDD_FAN2 --> system fan 2
	 */
	seq_printf(m, "CPU_TEMP: %d\n", temp2);
	seq_printf(m, "SYS_TEMP: %d\n", temp1);
	seq_printf(m, "CPU_FAN RPM: %d\n", fan1);
	seq_printf(m, "HDD_FAN1 RPM: %d\n", fan2);

	return 0;
}

static ssize_t
proc_f75387sg1_write(struct file *file, const char __user * buf,
                     size_t length, loff_t * ppos)
{
	return f75387sg_proc_write(f75387sg1_client, file, buf, length, ppos);
}

static ssize_t
proc_f75387sg2_write(struct file *file, const char __user * buf,
                     size_t length, loff_t * ppos)
{
	return f75387sg_proc_write(f75387sg2_client, file, buf, length, ppos);
}

static int proc_f75387sg1_show(struct seq_file *m, void *v)
{
	return f75387sg_proc_show(f75387sg1_client, m, v);
}

static int proc_f75387sg2_show(struct seq_file *m, void *v)
{
	return f75387sg_proc_show(f75387sg2_client, m, v);
}

static int proc_f75387sg1_open(struct inode *inode, struct file *file)
{
	return single_open(file, proc_f75387sg1_show, NULL);
}

static int proc_f75387sg2_open(struct inode *inode, struct file *file)
{
	return single_open(file, proc_f75387sg2_show, NULL);
}

static struct file_operations proc_f75387sg_operations[2] = {
	{
		.open = proc_f75387sg1_open,
		.read = seq_read,
		.write = proc_f75387sg1_write,
		.llseek = seq_lseek,
		.release = single_release,
	},{
		.open = proc_f75387sg2_open,
		.read = seq_read,
		.write = proc_f75387sg2_write,
		.llseek = seq_lseek,
		.release = single_release,
	}
};

int f75387sg_init_procfs(struct i2c_client *client)
{
	struct f75387sg_data *data = i2c_get_clientdata(client);
	struct proc_dir_entry *pde;

	pde = create_proc_entry(proc_name, 0, NULL);
	if (!pde)
		return -ENOMEM;
	pde->proc_fops = &proc_f75387sg_operations[data->kind];

	return 0;
}

void f75387sg_exit_procfs(struct i2c_client *client)
{
	remove_proc_entry(proc_name, NULL);
}

/* Return 0 if detection is successful, -ENODEV otherwise */
static int f75387sg_detect(struct i2c_client *client,
                           struct i2c_board_info *info)
{
	struct i2c_adapter *adapter = client->adapter;
	const char *chip_name;
	u16 vend_id, chip_id;

	printk("f75387sg_detect\n");

	f75387sg_rw16(client->addr, F75375_REG_VENDOR, &vend_id, 0);
	if (vend_id != 0x1934)
		return -ENODEV;

	f75387sg_rw16(client->addr, F75375_REG_CHIP_ID, &chip_id, 0);
	switch (chip_id){
	case F75375_CHIP_ID:
		chip_name = "F75375S";
		break;
	case F75387_CHIP_ID:
		switch(client->addr){
		case SG1:
			chip_name = "f75387sg1";
			break;
		case SG2:
			chip_name = "f75387sg2";
			break;
		}
		break;
	default:
		return -ENODEV;
		break;
	}

	dev_info(&adapter->dev, "Found %s at 0x%02x\n", chip_name, client->addr);
	strlcpy(info->type, chip_name, I2C_NAME_SIZE);

	return 0;
}

static int
f75387sg_probe(struct i2c_client *client,const struct i2c_device_id *id)
{
	struct f75387sg_data *data;
	int ret = 0;
	u8 val = 0;

	data = kzalloc(sizeof(struct f75387sg_data), GFP_KERNEL);
	if (!data) 
		return -ENOMEM;

	dev_info(&client->dev, "setting platform data\n");
	data->client = client;
	i2c_set_clientdata(client, data);
	mutex_init(&data->update_lock);
	data->kind = id->driver_data;

	switch(client->addr){
	case SG1:
		f75387sg1_client = client;
		break;
	case SG2:
		f75387sg2_client = client;
		break;
	}

	ret = f75387sg_rw(client->addr, F75375_REG_VENDOR, &val, 0);
	if (ret > 0) {
		printk(KERN_INFO "f75387sg_attach: cant read vendor ID\n");
		goto out;
	}
	data->ctrl = val;
	_DBG(1, "F75387SG Vendor ID=%02x\n", val);

	f75387sg_rw16(client->addr, F75375_REG_CHIP_ID, &data->chipid, 0);
	dev_info(&client->dev, "f753xx Chip id: %04X\n", data->chipid);

	f75387sg_reset(client);

	f75387sg_rw(client->addr, F75375_REG_CONFIG1, &val, 0);
	dev_info(&client->dev, "reg %#04x: %#04x\n", F75375_REG_CONFIG1, val);

/*
	// initial auto pwm settings.
	if (data->chipid == F75387_CHIP_ID){
		set_auto_pwm_duty(client->addr, 0);
		set_auto_pwm_duty(client->addr, 1);
	}
*/
	if (hwm == 1)
		strlcpy(proc_name, HWM_PROC, I2C_NAME_SIZE);
	else
		strlcpy(proc_name, client->name, I2C_NAME_SIZE);

	if (f75387sg_init_procfs(client)) {
		printk(KERN_ERR "f75387sg: cannot create /proc/%s.\n", proc_name);
		return -ENOENT;
	}

	return 0;

out:
	kfree(data);
	return -ENODEV;

}

static int f75387sg_remove(struct i2c_client *client)
{
	struct f75387sg_data *data = i2c_get_clientdata(client);
	kfree(data);
	f75387sg_exit_procfs(client);
	i2c_set_clientdata(client, NULL);
	return 0;
}

static struct i2c_driver f75387sg_driver = {
	.class = I2C_CLASS_HWMON,
	.driver = {
		.name = "f75387sg",
	},
	.probe = f75387sg_probe,
	.remove = f75387sg_remove,
	.id_table = f75387sg_id,
	.detect = f75387sg_detect,
	.address_list = normal_i2c,
};


static __init int f75387sg_init(void)
{
	printk(KERN_INFO "f75387sg_init\n");
	return i2c_add_driver(&f75387sg_driver);
}

static __exit void f75387sg_exit(void)
{
	i2c_del_driver(&f75387sg_driver);
	f75387sg1_client = NULL;
	f75387sg2_client = NULL;
}

module_init(f75387sg_init);
module_exit(f75387sg_exit);
