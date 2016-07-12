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
 * Driver for ICH7 GPIO 
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

#define GPI_INV 0x2c
#define GPO_BLINK 0x18

#define GPIO_USE_SEL2 0x30
#define GP_IO_SEL2 0x34
#define GP_LVL2 0x38

#define GPIO_USE_SEL3 0x40
#define GP_IO_SEL3 0x44
#define GP_LVL3 0x48

#define GPIO_IO_PORTS 64

#define GP2 2
#define GP3 3
#define GP8 8
#define GP9 9
#define GP10 10
#define GP12 12
#define GP13 13
#define GP14 14
#define GP15 15
#define GP20 20
#define GP21 21
#define GP22 22
#define GP24 24
#define GP25 25
#define GP27 27
#define GP28 28
#define GP31 31
#define GP33 33
#define GP34 34
#define GP35 35
#define GP36 36
#define GP37 37
#define GP38 38
#define GP39 39
#define GP48 48
#define GP49 49
#define GP56 56
#define GP57 57
#define GP72 72

#define PM1_STS 0x0
#define PM1_EN 0x2
#define PM1_CNT 0x4
#define PWR_BTN_BIT 8
#define GPE0_STS 0x28
#define GPE0_EN 0x2c

