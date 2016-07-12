#include <linux/module.h>
#include <linux/init.h>

#include <linux/thecus_drv.h>
#include "thecus_board.h"

MODULE_LICENSE("GPL"); 

//#define DEBUG 1

#ifdef DEBUG
# define _DBG(x, fmt, args...) do{ if (DEBUG>=x) printk(NAME ": %s: " fmt "\n", __FUNCTION__, ##args); } while(0);
#else
# define _DBG(x, fmt, args...) do { } while(0);
#endif

static int __init thecus_board_init(void); 
static void __exit thecus_board_exit(void);

u32 default_disk_access(int index, int act);
u32 default_disk_index(int index, struct scsi_device *sdp);

static const struct thecus_function default_func = {
        .disk_access = default_disk_access,
        .disk_index  = default_disk_index,
};

static struct thecus_board *current_board = NULL;
static struct thecus_board default_board[] = {{ 0, "default", 0, 0, 0, "000", "BOARD_DEFAULT", &default_func}};

u32 default_disk_access(int index, int act){
    return 0;
}

u32 default_disk_index(int index, struct scsi_device *sdp){
    return 0;
}

int __init thecus_board_init(void){ 
	printk(KERN_INFO "thecus_board: %s - version %s\n", thecus_board_string,
		DRV_VERSION);
	printk(KERN_INFO "%s\n", thecus_copyright);
    current_board = default_board;
    return 0;
}

u32 thecus_board_register(struct thecus_board *board){ 
    current_board = board;
    printk(KERN_INFO "thecus_board = %s, thecus_mbtype = %s!\n",current_board->name, current_board->mb_type); 
    return 0;
}
EXPORT_SYMBOL(thecus_board_register);

u32 thecus_board_unregister(struct thecus_board *board){ 
    current_board = default_board;
    printk(KERN_INFO "thecus_board = %s, thecus_mbtype = %s!\n",current_board->name, current_board->mb_type); 
    return 0;
}
EXPORT_SYMBOL(thecus_board_unregister);

u32 thecus_disk_access(int index, int act){
    u32 ret=1;
    if (current_board->func->disk_access) {
        ret = current_board->func->disk_access(index, act);
    }
    return ret;
}
EXPORT_SYMBOL(thecus_disk_access);

u32 thecus_disk_index(int index, struct scsi_device *sdp){
    u32 tindex=0;
    u32 tmp_idx=0;
    
    if(tmp_idx <= MAX_HOST_NO) {
        tmp_idx = index + MAX_HOST_NO;
    }else{
        tmp_idx = index;
    }

    if (current_board->func->disk_index) {
        tindex = current_board->func->disk_index(tmp_idx, sdp);
    }

    return tindex;
}
EXPORT_SYMBOL(thecus_disk_index);

//Check for bit , return false when low
int check_bit(u32 val, int bn)
{
    if ((val >> bn) & 0x1) {
        return 1;
    } else {
        return 0;
    }
}
EXPORT_SYMBOL(check_bit);

void print_gpio(u32 gpio_val, char *zero_str, char *one_str, u32 offset)
{
#ifdef DEBUG
    u32 i = 0;
    for (i = 0; i < 32; i++) {
        printk(KERN_INFO NAME ": GPIO %02d %s\n", i + offset,
               check_bit(gpio_val, i) > 0 ? one_str : zero_str);
    }
#endif
}
EXPORT_SYMBOL(print_gpio);

void __exit thecus_board_exit(void){ 
    printk(KERN_INFO "thecus_board exit ok!\n"); 
}

module_init(thecus_board_init); 
module_exit(thecus_board_exit);
