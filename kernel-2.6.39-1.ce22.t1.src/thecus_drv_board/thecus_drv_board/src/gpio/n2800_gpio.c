/*
 *  Copyright (C) 2009 Thecus Technology Corp.
 *
 *      Maintainer: citizen <joey_wang@thecus.com>
 *
 *      Driver for ICH10R GPIO on Thecus N2800 Board
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/types.h>
#include <linux/miscdevice.h>
#include <linux/init.h>
#include <linux/pci.h>
#include <linux/ioport.h>
#include <linux/delay.h>

#include "ich_gpio.h"

#define NAME	"ich_gpio"

MODULE_AUTHOR("Joey Wang");
MODULE_DESCRIPTION("Intel ICH10R GPIO Driver for Thecus N2800 Board");
MODULE_LICENSE("GPL");

/* Module and version information */
#define GPIO_VERSION "20111130"
#define GPIO_MODULE_NAME "Intel ICH10R GPIO driver"
#define GPIO_DRIVER_NAME   GPIO_MODULE_NAME ", v" GPIO_VERSION

//#define DEBUG 1

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (DEBUG>=x) printk(NAME ": %s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

/* internal variables */
static u32 GPIO_ADDR = 0, PM_ADDR = 0;//, LPC_ADDR = 0;

static struct pci_dev *ich_gpio_pci = NULL;

extern int check_bit(u32 val, int bn);
extern void print_gpio(u32 gpio_val, char *zero_str, char *one_str, u32 offset);
/*
Parameters:
bit_n: bit# to read 
Return value:
1: High
0: Low
-1: Error
*/
int ICH_gpio_read_bit(u32 bit_n)
{
    int ret = 0;
    u32 gval = 0;

    if (GPIO_ADDR == 0) {
	printk(KERN_ERR NAME ": GPIO_ADDR is NULL\n");
	return -1;
    }

    if (bit_n < 32) {		//check GP_LVL
	gval = inl(GPIO_ADDR + GP_LVL);
	ret = check_bit(gval, bit_n);
    } else if ((bit_n >= 32) && (bit_n <= 63)) {	//check GP_LVL2
	gval = inl(GPIO_ADDR + GP_LVL2);
	ret = check_bit(gval, bit_n - 32);
    } else if ((bit_n >= 64) && (bit_n <= 95)) {	//check GP_LVL3
	gval = inl(GPIO_ADDR + GP_LVL3);
	ret = check_bit(gval, bit_n - 64);
    } else
	ret = -1;

    //if(ret>=0)
    //printk("Read=0x%08X, bit[%d]=%d\n",gval,bit_n,ret);

    return ret;
}

/*
Parameters:
bit_n: bit# to update
val: [0/1] values to update 
Return value:(after set)
1: High 
0: Low
-1: Error
*/
int ICH_gpio_write_bit(u32 bit_n, int val)
{
    int ret = 0;
    u32 gval, sval, mask_val;
    mask_val = 1;
    sval = val;

    if (GPIO_ADDR == 0) {
	printk(KERN_ERR NAME ": GPIO_ADDR is NULL\n");
	return -1;
    }

    if (bit_n < 32) {		//check GP_LVL
	gval = inl(GPIO_ADDR + GP_LVL);
	mask_val = mask_val << bit_n;
	sval = sval << bit_n;
	gval = (gval & ~mask_val) | sval;
	outl(gval, GPIO_ADDR + GP_LVL);
    } else if ((bit_n >= 32) && (bit_n <= 63)) {	//check GP_LVL2
	gval = inl(GPIO_ADDR + GP_LVL2);
	mask_val = mask_val << (bit_n - 32);
	sval = sval << (bit_n - 32);
	gval = (gval & ~mask_val) | sval;
	outl(gval, GPIO_ADDR + GP_LVL2);
    } else if ((bit_n >= 64) && (bit_n <= 95)) {	//check GP_LVL3
	gval = inl(GPIO_ADDR + GP_LVL3);
	mask_val = mask_val << (bit_n - 64);
	sval = sval << (bit_n - 64);
	gval = (gval & ~mask_val) | sval;
	outl(gval, GPIO_ADDR + GP_LVL3);
    } else
	ret = -1;

/*  why ?
    if (ret >= 0) {
	ret = ICH_gpio_read_bit(bit_n);
	//printk("Read after write, bit[%d]=%d\n",bit_n,ret);
    }
*/

    return ret;
}

/*
 * Data for PCI driver interface
 *
 * This data only exists for exporting the supported
 * PCI ids via MODULE_DEVICE_TABLE.  We do not actually
 * register a pci_driver, because someone else might one day
 * want to register another driver on the same PCI id.
 */
static struct pci_device_id ich_gpio_pci_tbl[] = {
    {PCI_DEVICE(PCI_VENDOR_ID_INTEL, 0x3a16)}, /* ICH10R */
    {0,},			/* End of list */
};

MODULE_DEVICE_TABLE(pci, ich_gpio_pci_tbl);

static int __devinit ich_gpio_probe(struct pci_dev *, const struct pci_device_id *);

static struct pci_driver ich_gpio_pci_driver = {
        .name = "ich_gpio",
        .id_table = ich_gpio_pci_tbl,
        .probe = ich_gpio_probe,
};

/*
 *	Init & exit routines
 */
static unsigned char __init ich_gpio_getdevice(struct pci_dev *dev)
{
    u8 val1, val2;
    u32 badr;
    u32 gval, sval;


    printk(KERN_INFO NAME ": ICH PCI Vendor [%X] DEVICE [%X]\n", dev->subsystem_vendor,
	   dev->subsystem_device);

    if (ich_gpio_pci) {
	printk(KERN_INFO NAME ": ICH GPIO has already configured\n");
        return 0;
    } else {
        // get GPIO_ADDR
	pci_read_config_byte(dev, GPIOBASE, &val1);
	pci_read_config_byte(dev, GPIOBASE + 1, &val2);
	//badr = ((val2 << 2) | (val1 >> 6)) << 6; 	// 15:6
	badr = ((val2 << 1) | (val1 >> 7)) << 7;	// 15:7
	// printk("XXX=0x%04X\n", badr);
	// pci_read_config_dword(dev, GPIOBASE,&badr);
	GPIO_ADDR = badr;
	if (badr == 0x0001 || badr == 0x0000) {
	    printk(KERN_ERR NAME ": failed to get GPIO_ADDR address\n");
	    return 0;
	}
	printk(KERN_INFO NAME ": Found ICH GPIO at 0x%08X\n", GPIO_ADDR);

        ich_gpio_pci = dev;

	sval = 1;
	sval = ~sval;
	GPIO_ADDR &= sval;

	pci_read_config_byte(ich_gpio_pci, GPIO_CNTL, &val1);
	if (val1 == 0x10) {
	    //pci_write_config_byte (ich_gpio_pci, GPIO_CNTL, 0);
	    printk(KERN_INFO NAME ": GPIO already turned on\n");
	} else {
	    pci_write_config_byte(ich_gpio_pci, GPIO_CNTL, 0x10);
	    printk(KERN_INFO NAME ": Turn on the GPIO\n");
	}

        // get PM_ADDR
	pci_read_config_byte(ich_gpio_pci, PMBASE, &val1);
	pci_read_config_byte(ich_gpio_pci, PMBASE + 1, &val2);
	badr = ((val2 << 1) | (val1 >> 7)) << 7;	// 15:7

	PM_ADDR = badr;
	if (badr == 0x0001 || badr == 0x0000) {
	    printk(KERN_ERR NAME ": failed to get PM_ADDR address\n");
	    return 0;
	}
	printk(KERN_INFO NAME ": Found ICH PM at 0x%08X\n", PM_ADDR);

	/* GPIO SEL */
	// Used GPIO 0,2,3,4,5,9,28
	gval = inl(GPIO_ADDR + GPIO_USE_SEL);
	_DBG(1, "GPIO_USE_SEL=0x%08X", gval);

	sval = 1;
	sval = sval << GP0;
	gval |= sval;

	sval = 1;
	sval = sval << GP2;
	gval |= sval;

	sval = 1;
	sval = sval << GP3;
	gval |= sval;

	sval = 1;
	sval = sval << GP4;
	gval |= sval;

	sval = 1;
	sval = sval << GP5;
	gval |= sval;

	sval = 1;
	sval = sval << GP9;
	gval |= sval;

	sval = 1;
	sval = sval << GP28;
	gval |= sval;

	_DBG(1, "GPIO_USE_SEL set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GPIO_USE_SEL);
	gval = inl(GPIO_ADDR + GPIO_USE_SEL);
	_DBG(1, "GPIO_USE_SEL=0x%08X", gval);
	print_gpio(gval, "Native Mode", "GPIO   Mode", 0);

	/* GPIO SEL2 */
	gval = inl(GPIO_ADDR + GPIO_USE_SEL2);
	_DBG(1, "GPIO_USE_SEL2=0x%08X", gval);

	sval = 1;
	sval = sval << (GP34 - 32);
	gval |= sval;

	_DBG(1, "GPIO_USE_SEL2 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GPIO_USE_SEL2);
	gval = inl(GPIO_ADDR + GPIO_USE_SEL2);
	_DBG(1, "GPIO_USE_SEL2=0x%08X", gval);
	print_gpio(gval, "Native Mode", "GPIO   Mode", 32);

	/* GPIO SEL3 */
	gval = inl(GPIO_ADDR + GPIO_USE_SEL3);
	_DBG(1, "GPIO_USE_SEL3=0x%08X", gval);
/*
	sval = 1;
	sval = sval << (GP72 - 64);
	gval |= sval;
*/
	_DBG(1, "GPIO_USE_SEL3 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GPIO_USE_SEL3);
	gval = inl(GPIO_ADDR + GPIO_USE_SEL3);
	_DBG(1, "GPIO_USE_SEL3=0x%08X", gval);
	print_gpio(gval, "Native Mode", "GPIO   Mode", 64);


	// GPIO 0,2,3,4,5,28,34 Should be as output 
	// GPIO 9 Should be as Input = 1

	// set GP_IO_SEL1 default value
	gval = inl(GPIO_ADDR + GP_IO_SEL);
	_DBG(1, "GP_IO_SEL=0x%08X", gval);

	sval = 1;
	sval = sval << GP0;
	gval &= ~sval;

	sval = 1;
	sval = sval << GP2;
	gval &= ~sval;

	sval = 1;
	sval = sval << GP3;
	gval &= ~sval;

	sval = 1;
	sval = sval << GP4;
	gval &= ~sval;

	sval = 1;
	sval = sval << GP5;
	gval &= ~sval;

	sval = 1;
	sval = sval << GP9;
	gval |= sval;

	sval = 1;
	sval = sval << GP28;
	gval &= ~sval;

	_DBG(1, "OUTPUT GP_IO_SEL set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL);
	gval = inl(GPIO_ADDR + GP_IO_SEL);
	_DBG(1, "OUTPUT Check GP_IO_SEL=0x%08X", gval);
	print_gpio(gval, "Output Mode", "Input  Mode", 0);

	//set GP_IO_SEL2 default value
	gval = inl(GPIO_ADDR + GP_IO_SEL2);
	_DBG(1, "GP_IO_SEL2=0x%08X", gval);

	sval = 1;
	sval = sval << (GP34 - 32);
	gval &= ~sval;

	_DBG(1, "GP_IO_SEL2 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL2);
	gval = inl(GPIO_ADDR + GP_IO_SEL2);
	_DBG(1, "Check GP_IO_SEL2=0x%08X", gval);
	print_gpio(gval, "Output Mode", "Input  Mode", 32);

	//set GP_IO_SEL3 default value
	gval = inl(GPIO_ADDR + GP_IO_SEL3);
	_DBG(1, "GP_IO_SEL3=0x%08X", gval);
/*
	sval = 1;
	sval = sval << (GP72 - 64);
	gval |= sval;
*/
	_DBG(1, "GP_IO_SEL3 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL3);
	gval = inl(GPIO_ADDR + GP_IO_SEL3);
	_DBG(1, "Check GP_IO_SEL3=0x%08X", gval);
	print_gpio(gval, "Output Mode", "Input  Mode", 64);

	// debug info
	gval = inl(GPIO_ADDR + GP_LVL);
	print_gpio(gval, ": 0", ": 1", 0);
	gval = inl(GPIO_ADDR + GP_LVL2);
	print_gpio(gval, ": 0", ": 1", 32);
	gval = inl(GPIO_ADDR + GP_LVL3);
	print_gpio(gval, ": 0", ": 1", 64);

	gval = inw(PM_ADDR + PM1_STS);
	printk(KERN_INFO NAME ": PM1_STS=0x%02X\n", gval);

	ICH_gpio_write_bit(GP0,1);
	ICH_gpio_write_bit(GP2,1);
	ICH_gpio_write_bit(GP3,1);
	ICH_gpio_write_bit(GP4,1);
	ICH_gpio_write_bit(GP5,1);
	ICH_gpio_write_bit(GP28,1);

	return 1;
    }

}

static int __devinit ich_gpio_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
{
    int ret;

    /* Check whether or not the ICH LPC is there */
    if (!ich_gpio_getdevice(pdev) || ich_gpio_pci == NULL)
	return -ENODEV;

    if (!request_region(GPIO_ADDR, GPIO_IO_PORTS, "ICH GPIO")) {
	printk(KERN_ERR NAME ": I/O address 0x%04x already in use\n", GPIO_ADDR);
	ret = -EIO;
	goto out;
    }

    return 0;

  out:
    return ret;
}

int ICH_GPIO_init(void)
{
    struct pci_dev *pdev = NULL;
    const struct pci_device_id *ent = NULL;

    for_each_pci_dev(pdev) {
      ent = pci_match_id(ich_gpio_pci_tbl, pdev);
      if (ent) break;
    }

    if(ent == NULL) return -1;

    printk(KERN_INFO NAME ": %s\n", GPIO_DRIVER_NAME);

    return pci_register_driver(&ich_gpio_pci_driver);
}

void ICH_GPIO_exit(void)
{
    // Deregister
    pci_unregister_driver(&ich_gpio_pci_driver);
    if (GPIO_ADDR != 0) release_region(GPIO_ADDR, GPIO_IO_PORTS);
}

/*
static int __init ICH_GPIO_init(void)
{
    printk(KERN_INFO NAME ": %s\n", GPIO_DRIVER_NAME);

    return pci_register_driver(&ich_gpio_pci_driver);
}

static void __exit ICH_GPIO_exit(void)
{
    // Deregister
    pci_unregister_driver(&ich_gpio_pci_driver);
    if (GPIO_ADDR != 0) release_region(GPIO_ADDR, GPIO_IO_PORTS);
}

module_init(ICH_GPIO_init);
module_exit(ICH_GPIO_exit);
*/
