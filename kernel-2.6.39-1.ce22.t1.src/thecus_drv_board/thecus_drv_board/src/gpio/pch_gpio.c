/*
 *  Copyright (C) 2009 Thecus Technology Corp.
 *
 *      Maintainer: citizen <citizen_lee@thecus.com>
 *
 *      Driver for PCH GPIO on Thecus N16000
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

#include "pch_gpio.h"

#define NAME	"pch_gpio"

MODULE_AUTHOR("Citizen Lee");
MODULE_DESCRIPTION("Intel PCH GPIO Driver for Thecus N16000");
MODULE_LICENSE("GPL");

/* Module and version information */
#define GPIO_VERSION "20100730"
#define GPIO_MODULE_NAME "Intel PCH GPIO driver"
#define GPIO_DRIVER_NAME   GPIO_MODULE_NAME ", v" GPIO_VERSION

//#define DEBUG 1

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (DEBUG>=x) printk(NAME ": %s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

/* internal variables */
static u32 GPIO_ADDR = 0, PM_ADDR = 0, LPC_ADDR = 0;

static struct pci_dev *pch_gpio_pci = NULL;

//Check for bit , return false when low
inline int check_bit(u32 val, int bn)
{
    if ((val >> bn) & 0x1) {
	return 1;
    } else {
	return 0;
    }
}

/*
Parameters:
bit_n: bit# to read 
Return value:
1: High
0: Low
-1: Error
*/
int PCH_gpio_read_bit(u32 bit_n)
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
    } else
	ret = -1;

    //if(ret>=0)
    //printk("Read=0x%08X, bit[%d]=%d\n",gval,bit_n,ret);

    return ret;
}

EXPORT_SYMBOL(PCH_gpio_read_bit);


/*
Parameters:
bit_n: bit# to update
val: [0/1] values to update 
Return value:(after set)
1: High 
0: Low
-1: Error
*/
int PCH_gpio_write_bit(u32 bit_n, int val)
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
    } else if ((bit_n >= 32) && (bit_n <= 44)) {	//check GP_LVL2
	gval = inl(GPIO_ADDR + GP_LVL2);
	mask_val = mask_val << (bit_n - 32);
	sval = sval << (bit_n - 32);
	gval = (gval & ~mask_val) | sval;
	outl(gval, GPIO_ADDR + GP_LVL2);
    } else
	ret = -1;

/*  why ?
    if (ret >= 0) {
	ret = PCH_gpio_read_bit(bit_n);
	//printk("Read after write, bit[%d]=%d\n",bit_n,ret);
    }
*/

    return ret;
}

EXPORT_SYMBOL(PCH_gpio_write_bit);

/*
 * Data for PCI driver interface
 *
 * This data only exists for exporting the supported
 * PCI ids via MODULE_DEVICE_TABLE.  We do not actually
 * register a pci_driver, because someone else might one day
 * want to register another driver on the same PCI id.
 */
static struct pci_device_id pch_gpio_pci_tbl[] = {
    {PCI_DEVICE(PCI_VENDOR_ID_INTEL, 0x3b02)}, /* P55 */
    {PCI_DEVICE(PCI_VENDOR_ID_INTEL, 0x3b16)}, /* 3450 */
    {0,},			/* End of list */
};

MODULE_DEVICE_TABLE(pci, pch_gpio_pci_tbl);

static int __devinit pch_gpio_probe(struct pci_dev *, const struct pci_device_id *);

static struct pci_driver pch_gpio_pci_driver = {
        .name = "pch_gpio",
        .id_table = pch_gpio_pci_tbl,
        .probe = pch_gpio_probe,
};

void print_gpio(u32 gpio_val, char *zero_str, char *one_str)
{
#ifdef DEBUG
    u32 i = 0;
    for (i = 0; i < 32; i++) {
	printk(KERN_INFO NAME ": GPIO %02d %s\n", i,
	       check_bit(gpio_val, i) > 0 ? one_str : zero_str);
    }
#endif
}

void print_gpio2(u32 gpio_val, char *zero_str, char *one_str)
{
#ifdef DEBUG
    u32 i = 0;
    for (i = 0; i < 32; i++) {
	printk(KERN_INFO NAME ": GPIO %02d %s\n", i + 32,
	       check_bit(gpio_val, i) > 0 ? one_str : zero_str);
    }
#endif
}

/*
 *	Init & exit routines
 */
static unsigned char __init pch_gpio_getdevice(struct pci_dev *dev)
{
    u8 val1, val2;
    u32 badr;
    u32 gval, sval;


    printk(KERN_INFO NAME ": PCH PCI Vendor [%X] DEVICE [%X]\n", dev->subsystem_vendor,
	   dev->subsystem_device);

    if (pch_gpio_pci) {
	printk(KERN_INFO NAME ": PCH GPIO has already configured\n");
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
	printk(KERN_INFO NAME ": Found PCH GPIO at 0x%08X\n", GPIO_ADDR);

        pch_gpio_pci = dev;

	sval = 1;
	sval = ~sval;
	GPIO_ADDR &= sval;

	pci_read_config_byte(pch_gpio_pci, GPIO_CNTL, &val1);
	if (val1 == 0x10) {
	    //pci_write_config_byte (pch_gpio_pci, GPIO_CNTL, 0);
	    printk(KERN_INFO NAME ": GPIO already turned on\n");
	} else {
	    pci_write_config_byte(pch_gpio_pci, GPIO_CNTL, 0x10);
	    printk(KERN_INFO NAME ": Turn on the GPIO\n");
	}

        // get PM_ADDR
	pci_read_config_byte(pch_gpio_pci, PMBASE, &val1);
	pci_read_config_byte(pch_gpio_pci, PMBASE + 1, &val2);
	badr = ((val2 << 1) | (val1 >> 7)) << 7;	// 15:7

	PM_ADDR = badr;
	if (badr == 0x0001 || badr == 0x0000) {
	    printk(KERN_ERR NAME ": failed to get PM_ADDR address\n");
	    return 0;
	}
	printk(KERN_INFO NAME ": Found PCH PM at 0x%08X\n", PM_ADDR);

	/* GPIO SEL */
	// Used GPIO 21,22,27,35,36,37,38,39,48,49,56,57,
	gval = inl(GPIO_ADDR + GPIO_USE_SEL);
	_DBG(1, "GPIO_USE_SEL=0x%08X", gval);

	sval = 1;
	sval = sval << GP21;
	gval |= sval;

	sval = 1;
	sval = sval << GP22;
	gval |= sval;

	sval = 1;
	sval = sval << GP27;
	gval |= sval;

	_DBG(1, "GPIO_USE_SEL set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GPIO_USE_SEL);
	gval = inl(GPIO_ADDR + GPIO_USE_SEL);
	_DBG(1, "GPIO_USE_SEL=0x%08X", gval);
	print_gpio(gval, "Native Mode", "GPIO   Mode");

	/* GPIO SEL2 */
	gval = inl(GPIO_ADDR + GPIO_USE_SEL2);
	_DBG(1, "GPIO_USE_SEL2=0x%08X", gval);
	sval = 1;
	sval = sval << (GP35 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP36 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP37 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP38 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP39 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP48 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP49 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP56 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP57 - 32);
	gval |= sval;
	_DBG(1, "GPIO_USE_SEL2 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GPIO_USE_SEL2);
	gval = inl(GPIO_ADDR + GPIO_USE_SEL2);
	_DBG(1, "GPIO_USE_SEL2=0x%08X", gval);
	print_gpio2(gval, "Native Mode", "GPIO   Mode");

	// GPIO 21,22,36,37,38,39,48,49,56,57, Should be as Input = 0
        // GPIO 27,35 Should be as Output =1, but must set input first, wait, then set output
	// set GP_IO_SEL1 default value
	gval = inl(GPIO_ADDR + GP_IO_SEL);
	_DBG(1, "GP_IO_SEL=0x%08X", gval);

	sval = 1;
	sval = sval << GP21;
	gval |= sval;

	sval = 1;
	sval = sval << GP22;
	gval |= sval;

	sval = 1;
	sval = sval << GP27;
	gval |= sval;

	_DBG(1, "INPUT GP_IO_SEL set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL);
	gval = inl(GPIO_ADDR + GP_IO_SEL);
	_DBG(1, "INPUT Check GP_IO_SEL=0x%08X", gval);

	ssleep(1);		// sleep 1 second, then set output GPIO

	sval = 1;
	sval = sval << GP27;
	gval &= ~sval;		// set output GPIO

	_DBG(1, "OUTPUT GP_IO_SEL set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL);
	gval = inl(GPIO_ADDR + GP_IO_SEL);
	_DBG(1, "OUTPUT Check GP_IO_SEL=0x%08X", gval);
	print_gpio(gval, "Output Mode", "Input  Mode");

	//set GP_IO_SEL2 default value
	gval = inl(GPIO_ADDR + GP_IO_SEL2);
	_DBG(1, "GP_IO_SEL2=0x%08X", gval);

	sval = 1;
	sval = sval << (GP35 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP36 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP37 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP38 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP39 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP48 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP49 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP56 - 32);
	gval |= sval;

	sval = 1;
	sval = sval << (GP57 - 32);
	gval |= sval;

	_DBG(1, "GP_IO_SEL2 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL2);
	gval = inl(GPIO_ADDR + GP_IO_SEL2);
	_DBG(1, "Check GP_IO_SEL2=0x%08X", gval);
	print_gpio2(gval, "Output Mode", "Input  Mode");

	ssleep(1);		// sleep 1 second, then set output GPIO

	sval = 1;
	sval = sval << (GP35 -32);
	gval &= ~sval;		// set output GPIO

	_DBG(1, "GP_IO_SEL2 set to =0x%08X", gval);
	outl(gval, GPIO_ADDR + GP_IO_SEL2);
	gval = inl(GPIO_ADDR + GP_IO_SEL2);
	_DBG(1, "Check GP_IO_SEL2=0x%08X", gval);
	print_gpio2(gval, "Output Mode", "Input  Mode");

	gval = inl(GPIO_ADDR + GP_LVL);
	print_gpio(gval, ": 0", ": 1");
	gval = inl(GPIO_ADDR + GP_LVL2);
	print_gpio2(gval, ": 0", ": 1");

	gval = inw(PM_ADDR + PM1_STS);
	printk(KERN_INFO NAME ": PM1_STS=0x%02X\n", gval);


	/// Disable THRM Function
/*
        gval=inl(PMBASE+GPE0_STS);
	printk(NAME ": THRM_STS set to =0x%08X\n",gval);
        sval=1;
        sval=sval<<0;
        gval|=sval;
        outl(0,PMBASE+GPE0_STS);
        gval=inl(PMBASE+GPE0_STS);
        printk("CHECK THRM_STS set to =0x%08X\n",gval);

        gval=inl(PMBASE+GPE0_EN);
        printk("THRM_EN set to =0x%08X\n",gval);
        sval=1;
        sval=sval<<0;
        gval&=~sval;
        outl(0,PMBASE+GPE0_EN);
        gval=inl(PMBASE+GPE0_EN);
        printk("CHECK THRM_EN set to =0x%08X\n",gval);

        val1=inb(PMBASE+0x42);
        printk("THRM_POL set to =0x%08X\n",val1);

        outl(0x01,PMBASE+0x42);
        val1=inb(PMBASE+0x42);
        printk("THRM_POL set to =0x%08X\n",val1);
*/

/*
	pci_read_config_byte(pch_gpio_pci, GPIO_PMCON_2, &val1);
	pci_read_config_byte(pch_gpio_pci, GPIO_PMCON_3, &val2);
	printk("(1)PMCON_2=0x%02X\n   PMCON_3=0x%02X\n", val1, val2);
	val2 = 0x0;
	pci_write_config_byte(pch_gpio_pci, GPIO_PMCON_3, val2);
	pci_read_config_byte(pch_gpio_pci, GPIO_PMCON_2, &val1);
	pci_read_config_byte(pch_gpio_pci, GPIO_PMCON_3, &val2);
	printk("(2)PMCON_2=0x%02X\n   PMCON_3=0x%02X\n", val1, val2);

	printk("Route power button to PCH driver\n");
	gval = inw(PM_ADDR + PM1_EN);
	printk("PM1_EN=0x%02X\n", gval);
	gval = 0x00;
	outw(gval, PM_ADDR + PM1_EN);
*/

	return 1;
    }

}

static int __devinit pch_gpio_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
{
    int ret;

    /* Check whether or not the PCH LPC is there */
    if (!pch_gpio_getdevice(pdev) || pch_gpio_pci == NULL)
	return -ENODEV;

    if (!request_region(GPIO_ADDR, GPIO_IO_PORTS, "PCH GPIO")) {
	printk(KERN_ERR NAME ": I/O address 0x%04x already in use\n", GPIO_ADDR);
	ret = -EIO;
	goto out;
    }

    return 0;

  out:
    return ret;
}

static int __init PCH_GPIO_init(void)
{
    printk(KERN_INFO NAME ": %s\n", GPIO_DRIVER_NAME);

    return pci_register_driver(&pch_gpio_pci_driver);
}

static void __exit PCH_GPIO_exit(void)
{
    /* Deregister */
    pci_unregister_driver(&pch_gpio_pci_driver);
    if (GPIO_ADDR != 0) release_region(GPIO_ADDR, GPIO_IO_PORTS);
}

module_init(PCH_GPIO_init);
module_exit(PCH_GPIO_exit);
