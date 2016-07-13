#ifndef CMD_H_
#define CMD_H_

#ifdef	__cplusplus
extern "C" {
#endif

    #include <stdint.h>

    #define CMD_VERSION             		0
    #define CMD_INTERRUPT          	 	1
    #define CMD_OLED_DISPLAY        	2
    #define CMD_POWER_STATUS        	3
    #define CMD_LANGUAGE            		4
    #define CMD_MODEL_SELECT        	5
    #define CMD_BOOT_LOADER         	6
    #define CMD_DUAL_DOM            		7
    #define CMD_BUTTON_OPERATION    	8
    #define CMD_SPI_ADDRESS         	9
    #define CMD_SPI_DATA            		10
    #define CMD_FLASH_ADDRESS       	11
    #define CMD_FLASH_DATA          		12
    #define CMD_OBJECT_CONTROL      	13
    #define CMD_SPI_STATUS          		14
    #define CMD_FLASH_STATUS        	15
#ifdef STATUS_LED
    #define CMD_SLED					16
#endif
#ifdef PUBLIC_GPIO
    #define CMD_PUBLIC_GPIO 			17
#endif

    #define CMD_GETAVRVN            64
    #define CMD_SETLOGO             65
    #define CMD_SETBTO              66
    #define CMD_BTMSG               67
    #define CMD_STARTWD             68
    #define CMD_USB_COPY            69
    #define CMD_SYS_UPGRADE         70
    #define CMD_POWER_ON_OFF_ERROR  71
    #define CMD_UPGRADE_PIC_START   72
    #define CMD_UPGRADE_PIC         73
    #define CMD_UPGRADE_PIC_END     74
    #define CMD_RESET_PIC           75

    #define CMD_AC_POWER            128
    #define CMD_POWER_OFF           129
    #define CMD_DEBUG_ENABLE        130
    #define CMD_DEBUG_MASK          131

#ifdef STATUS_LED
    #define HOST_CMD_SLED		5
#endif
#ifdef PUBLIC_GPIO
    #define HOST_CMD_GPIO		5
#endif    
    enum
    {
        I2C_RETURN_POWER_OFF=0,
        I2C_RETURN_BTN_UP,
        I2C_RETURN_BTN_DOWN,
        I2C_RETURN_BTN_ENTER,
        I2C_RETURN_BTN_ESC,
        I2C_RETURN_CMD_RESULT,
        I2C_RETURN_CURR_PAGE,
        I2C_RETURN_CURR_INPUT,
        I2C_RETURN_INPUT_STATUS,
        I2C_RETURN_VALUE_0,
        I2C_RETURN_VALUE_1,
        I2C_RETURN_VALUE_2,
        I2C_RETURN_VALUE_3,
        I2C_RETURN_OBJECT_RESULT,
        I2C_RETURN_MAX,
        INPUT_COMPLETE=11,
    };

    enum
    {
        OBJECT_STATUS_DEFAULT,
        OBJECT_STATUS_PROCESSING,
        OBJECT_STATUS_FINISH,
        OBJECT_STATUS_MAX,
    };

    enum
    {
        I2C_RETURN_STATUS_DEFAULT,
        I2C_RETURN_STATUS_PROCESSING,
        I2C_RETURN_STATUS_SUCCESS,
        I2C_RETURN_STATUS_FAIL,
        I2C_RETURN_STATUS_FINISH,
        I2C_RETURN_STATUS_MAX,
    };

    enum
    {
        BTN_UP,
        BTN_DOWN,
        BTN_ENTER,
        BTN_ESC,
        BTN_MAX,
    };

    typedef struct queue_cmd_struct
    {
        uint8_t in_out;
        void *pData;
    } queue_cmd;

    typedef struct i2c_cmd_struct
    {
        uint8_t cmd;
        uint8_t action;
        int8_t data[30];
    } i2c_cmd;

    typedef struct oled_object_struct
    {
        uint8_t action;
        uint8_t object;
        uint8_t id;
        int8_t data[27];
    } oled_object;

    typedef struct oled_object_text_struct
    {
        uint8_t style;
        uint8_t lang;
        uint8_t length;
        int8_t data[24];
    } oled_text_object;

    typedef struct oled_object_input_struct
    {
        uint8_t style;
        int8_t data[26];
    } oled_input_object;

    typedef struct oled_object_var_struct
    {
        uint8_t length;
        int8_t data[26];
    } oled_var_object;

    #define MAX_CMD_LENGTH 64
    #define SIG_PROC_CMD 64
    #define CMD_OUT 1
    #define CMD_IN  2

    #define CMD_IS_BLANK(c) (((int8_t)c == ' ' || (int8_t)c == '\t' || (int8_t)c == '\n') ? 1 : 0 )
    #define CMD_IS_EOS(c) (((int8_t)c == '\0' || (int8_t)c == '\n' || (int8_t)c == '\a') ? 1 : 0 )
#ifdef STATUS_LED
    uint32_t LED_init(void);
#endif
#ifdef PUBLIC_GPIO
    uint32_t GPIO_init(void);
#endif
    uint32_t pipe_init(void);
    uint32_t pipe_uninit(void);
    void *pipecmd(void *ptr);
    void poll_cmd_handler(void);
    int32_t get_host_cmd(int8_t * in_arg, int8_t **cmd, int8_t **out_arg);
    int32_t parser_host_cmd(int8_t * in_arg);
    int32_t get_version(void);
    uint32_t Flags_init(void);
#ifdef	__cplusplus
}
#endif

#endif /*CMDPARSER_H_*/
