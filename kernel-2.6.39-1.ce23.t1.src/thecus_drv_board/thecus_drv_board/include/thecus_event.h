#ifndef __THECUS_EVENT_H__
#define __THECUS_EVENT_H__


#define DISK_ADD "disk_add"
#define DISK_REMOVE "disk_remove"
#define DISK_FAIL "disk_fail"
#define DISK_RETRY "disk_retry"
#define DISK_IO_FAIL "disk_io_fail"
#define DEVICE_RESET "device_reset"
#define SMART_ERROR "smart_error"

#define RAID_HEALTHY "raid_healthy"
#define RAID_DEGRADE "raid_degrade"
#define RAID_DAMAGE "raid_damage"
#define RAID_RECOVERY "raid_recovery"
#define RAID_IO_FAIL "raid_io_fail"
#define RAID_NA "raid_na"
#define RAID_CREATE "raid_create"
#define RAID_DISK_FAIL "raid_disk_fail"
#define RAID_AUTO_RUN "raid_auto_run"

#define RAID_STATUS_NA 		1
#define RAID_STATUS_HEALTHY 	2
#define RAID_STATUS_CREATE 	3
#define RAID_STATUS_RECOVERY 	4
#define RAID_STATUS_DEGRADE 	5
#define RAID_STATUS_DAMAGE 	6
#define RAID_STATUS_IO_FAIL 	7
#define RAID_STATUS_DISK_FAIL 	8
#define RAID_STATUS_AUTO_RUN 	9

#define EXPANDER_ADD "expander_add"
#define EXPANDER_REMOVE "expander_remove"

#define color_print_red_begin(args...) printk("%c[%d;%d;%dm", 0x1B,1,31,40)
#define color_print_green_begin(args...) printk("%c[%d;%d;%dm", 0x1B,1,32,40)
#define color_print_yellow_begin(args...) printk("%c[%d;%d;%dm", 0x1B,1,33,40)
#define color_print_blue_begin(args...) printk("%c[%d;%d;%dm", 0x1B,1,34,40)
#define color_print_end(args...) printk("%c[%dm", 0x1B, 0)


#define BUF_MAX_RETRY 100

void criticalevent_user(char *message,const char *parm1);

#endif
