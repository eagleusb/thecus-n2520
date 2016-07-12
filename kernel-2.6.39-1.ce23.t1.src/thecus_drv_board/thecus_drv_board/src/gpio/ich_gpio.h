/*
 *  Copyright (C) 2006 Thecus Technology Corp. 
 *
 *      Written by Y.T. Lee (yt_lee@thecus.com)
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * Driver for ICH10R GPIO 
 */
/* PCI registers */

#define GPIOBASE 0x48
#define GPIO_CNTL 0x4c
#define GPIO_CNTL_EN 4

#define PMBASE 0x40
#define ACPI_CNTL 0x44
#define GPI_ROUT 0xb8

#define BIOS_CNTL 0xDC

#define GPIO_PMCON_2 0xa2
#define GPIO_PMCON_3 0xa4

/* IO registers */
#define GPIO_USE_SEL 0x0
#define GP_IO_SEL 0x4
#define GP_LVL 0xc

#define GPO_BLINK 0x18
#define GP_SER_BLINK 0x1c
#define GP_SB_CMDSTS 0x20
#define GP_SB_DATA 0x24

#define GPI_INV 0x2c

#define GPIO_USE_SEL2 0x30
#define GP_IO_SEL2 0x34
#define GP_LVL2 0x38

#define GPIO_USE_SEL3 0x40
#define GP_IO_SEL3 0x44
#define GP_LVL3 0x48

#define GP_RST_SEL 0x60

#define GPIO_IO_PORTS 64

#define GP0 0
#define GP2 2
#define GP3 3
#define GP4 4
#define GP5 5
#define GP8 8
#define GP9 9
#define GP14 14
#define GP15 15
#define GP24 24
#define GP25 25
#define GP26 26
#define GP27 27
#define GP28 28
#define GP33 33
#define GP34 34
#define GP35 35
#define GP38 38
#define GP39 39

#define PM1_STS 0x0
#define PM1_EN 0x2
#define PM1_CNT 0x4
#define PWR_BTN_BIT 8
#define GPE0_STS 0x28
#define GPE0_EN 0x2c

