/*
 *  Copyright (C) 2013 Thecus Technology Corp.
 *
 *      Maintainer: Oswin Lin <oswin_lin@thecus.com>
 *
 *      Driver for Thecus PIC24 micro controller
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
#include <linux/delay.h>

#include "pic24.h"

static struct i2c_client *save_client = NULL;

#define QUEUE_MAX	25
struct rec thecus_i2c_queue[QUEUE_MAX];
u8 i2c_queue_s = 0;
u8 i2c_queue_e = 0;
u8 i2c_queue_full = 0;

u8 pic_ver = 0;

/* Addresses to scan */
static const unsigned short pic24fj128_addr[] = { PIC24FJ128_I2C_ID, I2C_CLIENT_END };

struct pic24fj128_data {
    struct i2c_client *client;
    struct mutex update_lock;
    int kind;
};

u8 addQ(u8 reg_num, u8 * val, int size)
{
  u8 ret = 0;
  if (i2c_queue_full) {
    printk("THECUS I2C QUEUE Full, discard message\n");
    ret = 1;
  } else {
    i2c_queue_s++;
    i2c_queue_s %= QUEUE_MAX;
    thecus_i2c_queue[i2c_queue_s].reg_num = reg_num;
    strncpy(thecus_i2c_queue[i2c_queue_s].val, val, 20);
    thecus_i2c_queue[i2c_queue_s].size = size;
  }

  if (i2c_queue_s == i2c_queue_e)
  i2c_queue_full = 1;
  return ret;
}

int isFullQ(void)
{
    return i2c_queue_full;
}

int isEmptyQ(void)
{
    return ((i2c_queue_s == i2c_queue_e) && !i2c_queue_full);
}

struct rec *removeQ(void)
{
  if (i2c_queue_full)
    i2c_queue_full = 0;
  else if (isEmptyQ())
    return NULL;

  i2c_queue_e++;
  i2c_queue_e %= QUEUE_MAX;
  return &thecus_i2c_queue[i2c_queue_e];
}



// size <= 16
// THECUS_PIC24FJ128_LCM_MSG size is 33
int pic24fj128_write_regs(u8 reg_num, u8 * val, int size)
{
  int ret = 0, i, j=0;
  u16 val1;
  struct pic24fj128_data *data = NULL;
  _PIC24_DBG(1, "pic24fj128_write_regs Reg#0x%02X\n", reg_num);

  if (NULL == save_client) {
    _PIC24_DBG(1, "i2c_client is NULL");
    return 1;
  }

  data = i2c_get_clientdata(save_client);
  mutex_lock(&data->update_lock);
  for (i = 0; i < I2C_RETRY; i++) {

    if (size > 1)
#ifdef CONFIG_GEN3_I2C
      i2c_smbus_write_word_data(save_client, reg_num, 255);
#else
      i2c_smbus_write_byte_data(save_client, reg_num, 255);
#endif

    for (j = 0; j<size ;j++){
#ifdef CONFIG_GEN3_I2C
      val1 = *(val+j);
      ret = i2c_smbus_write_word_data(save_client, reg_num, val1);
#else
      ret = i2c_smbus_write_byte_data(save_client, reg_num, *(val+j));
#endif
      _PIC24_DBG(1, "pic24fj128_write_regs %d = %d ", val1, ret);
    }
    //if(reg_num == THECUS_PIC24FJ128_BTN_OP)
      msleep(40);
    if (ret >= 0)
      break;
  }
  mutex_unlock(&data->update_lock);


  if (ret < 0) {
    //addQ(reg_num, val, size);
    printk(KERN_ERR "PIC24FJ128: write PIC24FJ128 Reg#0x%02X error (%d)\n", reg_num, ret);
    return 1;
  }

  return 0;
}
EXPORT_SYMBOL(pic24fj128_write_regs);

/* return 0 for no error */
// size <= 16
int pic24fj128_get_regs(u8 reg_num, u8 * val, int size)
{
  int ret = 0, i;
  struct pic24fj128_data *data = NULL;
  //_PIC24_DBG(1, "pic24fj128_get_regs Reg#0x%02X\n", reg_num);

  if (NULL == save_client) {
    _PIC24_DBG(1, "i2c_client is NULL");
    return 1;
  }

  data = i2c_get_clientdata(save_client);
  mutex_lock(&data->update_lock);
  for (i = 0; i < I2C_RETRY; i++) {
    memset(val, 0, size);
    ret = i2c_smbus_read_i2c_block_data(save_client, reg_num, size, val);
    if (ret >= 0)
      break;
    udelay(50);
  }
  mutex_unlock(&data->update_lock);

  if (ret < 0) {
    printk(KERN_ERR "PIC24FJ128: cant read PIC24FJ128 Reg#0x%02X error (%d)\n", reg_num, ret);
    return 1;
  }
  return 0;
}
EXPORT_SYMBOL(pic24fj128_get_regs);

void pic24fj128_poweroff(void)
{
  u8 val;
  val = THECUS_PIC24FJ128_SYS_PWR_OFF;
  pic24fj128_write_regs(THECUS_PIC24FJ128_SYS, &val, 1);
}

static int pic24fj128_probe(struct i2c_client *client, const struct i2c_device_id *id)
{
  struct pic24fj128_data *data;

  if (!i2c_check_functionality(client->adapter, I2C_FUNC_SMBUS_BYTE_DATA))
    return -EIO;

  data = kzalloc(sizeof(struct pic24fj128_data), GFP_KERNEL);
  if (!data) {
    return -ENOMEM;
  }

  dev_info(&client->dev, "setting platform data\n");
  i2c_set_clientdata(client, data);
  data->client = client;
  data->kind = id->driver_data;

  printk("Probeing PIC24FJ128\n");

  save_client = client;
  strlcpy(save_client->name, "PIC24FJ128", I2C_NAME_SIZE);
  _PIC24_DBG(1, "client=%p ", save_client);
  mutex_init(&data->update_lock);


  pic24fj128_get_regs(THECUS_PIC24FJ128_VERSION, &pic_ver, 1);
  printk("PIC_VER: %d\n", pic_ver);
  return 0;
}

static int pic24fj128_remove(struct i2c_client *client)
{
  kfree(i2c_get_clientdata(client));
  i2c_set_clientdata(client, NULL);

  return 0;

}

static int pic24fj128_detect(struct i2c_client *client, struct i2c_board_info *info)
{
    struct i2c_adapter *adapter = client->adapter;
    unsigned short address = client->addr;
    const char *chip_name;

		chip_name = "PIC24FJ128";
    _PIC24_DBG(1, "=============pic24fj128_detect %s==============\n", chip_name);
    strlcpy(info->type, chip_name, I2C_NAME_SIZE);
    dev_info(&adapter->dev, "Found %s at 0x%02hx\n", chip_name, address);

    return 0;
}

static int pic24fj128_command(struct i2c_client *client, unsigned int cmd, void *arg)
{

  _PIC24_DBG(1, "cmd=%d", cmd);

  switch (cmd) {
  default:
    return -EINVAL;
  }
}

static const struct i2c_device_id pic24fj128_id[] = {
    { "PIC24FJ128", 0 },
    { }
};
MODULE_DEVICE_TABLE(i2c, pic_id);


static struct i2c_driver pic24fj128_driver = {
  .driver = {
    .name = "PIC24FJ128",
  },
  .class = I2C_CLASS_HWMON,
  .probe = pic24fj128_probe,
  .remove = pic24fj128_remove,
  .detect = pic24fj128_detect,
  .command = pic24fj128_command,
  .id_table = pic24fj128_id,
  .address_list = pic24fj128_addr
};

static int __init PIC24_init(void)
{
    return i2c_add_driver(&pic24fj128_driver);
}

static void __exit PIC24_exit(void)
{
    i2c_del_driver(&pic24fj128_driver);
}

MODULE_AUTHOR("Oswin Lin <oswin_lin@thecus.com>");
MODULE_DESCRIPTION("PIC24 Driver");
MODULE_LICENSE("GPL");
module_init(PIC24_init);
module_exit(PIC24_exit);
