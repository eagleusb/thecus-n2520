#ifndef I2C_H_
#define I2C_H_

#ifdef	__cplusplus
extern "C" {
#endif
#include "i2c-dev.h"
    
void i2c_pec_enable( void );
void i2c_pec_disable( void );
int32_t i2c_init(void);
int32_t i2c_release(void);
int32_t i2c_read_block(uint8_t reg_num, uint8_t *pData);
int32_t i2c_write_block(uint8_t reg_num, uint8_t len, uint8_t *pData);
#ifdef	__cplusplus
}
#endif

#endif /*I2C_H_*/

