#ifndef _THECUS_BOARD_H_
#define _THECUS_BOARD_H_

#include <scsi/scsi.h>
#include <scsi/scsi_cmnd.h>
#include <scsi/scsi_dbg.h>
#include <scsi/scsi_device.h>
#include <scsi/scsi_driver.h>
#include <scsi/scsi_eh.h>
#include <scsi/scsi_host.h>
#include <scsi/scsi_ioctl.h>
#include <scsi/scsicam.h>

#include "pca9532.h"

#define MAX_HOST_NO	20

#define GPIO_BTN_OFF    0x0
#define GPIO_BTN_ON     0x1

#define BUZZER_OFF      0x0
#define BUZZER_ON       0x1

#define LED_OFF         0x0
#define LED_ON          0x1
#define LED_BLINK1      0x2
#define LED_BLINK2      0x3
#define LED_ENABLE      0x4
#define LED_DISABLE     0x5

#define LED_ICH_OFF     0x1
#define LED_ICH_ON      0x0
#define LED_ICH_BLINK   0x2

#define LED_PCH_OFF     0x1
#define LED_PCH_ON      0x0
#define LED_PCH_BLINK   0x2

#define BOARD_N16000    0x0
#define BOARD_N8900     0x1
#define BOARD_N6850     0x2
#define BOARD_N2800     0x3
#define BOARD_N5800     0x4
#define BOARD_N2310     0x5
#define BOARD_N4310     0x6

struct thecus_function;
struct thecus_board;

struct thecus_function {
    u32 (*disk_access) (int index, int act);
    u32 (*disk_index)  (int index, struct scsi_device *sdp);
};

struct thecus_board {
    u32 gpio_num;
    const char *board_string;
    u32 max_tray;
    u32 eSATA_tray;
    u32 eSATA_count;
    const char *mb_type;
    const char *name;
    const struct thecus_function *func;
    const u32 board;
};

u32 thecus_board_register(struct thecus_board *board);
u32 thecus_board_unregister(struct thecus_board *board);

#endif
