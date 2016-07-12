#ifndef _PCA9532_H_
#define _PCA9532_H_

#define PCA_LED1                     0x64
#define PCA_LED2                     0x62

void pca9532_set_ls(u8 addr, int led_num, int led_state);
int  pca9532_get_ls(u8 addr, int led_num);
int  pca9532_get_inp(u8 addr, int led_num);
int  pca9532_get_reg(u8 addr, int reg);

#define pca9532_set_led(a, b)        pca9532_set_ls(PCA_LED1, (a), (b))
#define pca9532_get_led(a)           pca9532_get_ls(PCA_LED1, (a))
#define pca9532_get_input(a)         pca9532_get_inp(PCA_LED1, (a))
#define pca9532_get_register(a)      pca9532_get_reg(PCA_LED1, (a))
#define pca9532_id_set_led(a, b)     pca9532_set_ls(PCA_LED2, (a), (b))
#define pca9532_id_get_led(a)        pca9532_get_ls(PCA_LED2, (a))
#define pca9532_id_get_input(a)      pca9532_get_inp(PCA_LED2, (a))
#define pca9532_id_get_register(a)   pca9532_get_reg(PCA_LED2, (a))

#endif
