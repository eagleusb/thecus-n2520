/*
 * File:   menu.h
 * Author: dorianko
 *
 */

#ifndef _MENU_H
#define	_MENU_H

#include "timer.h"

#ifdef	__cplusplus
extern "C" {
#endif
    #define MAX_ALERT_NUM   10
    #define MAX_MENU_NUM    20
    #define SIG_PROC_MENU   63

    enum
    {
        MENU_QUEUE_PUSH,
        MENU_QUEUE_POP,
        MENU_QUEUE_POP_TO_LEVEL,
        MENU_QUEUE_ACTION,
        MENU_QUEUE_TIMEOUT,
        MENU_QUEUE_SHOW_SCREEN,
        MENU_QUEUE_MAX,
    };

    enum
    {
        MENU_POP_NORMAL,
        MENU_POP_TO_LEVEL,
        MENU_POP_MAX,
    };

    enum
    {
        SCR_TYPE_MENU_NORMAL,
        SCR_TYPE_POWER_SAVE,
        SCR_TYPE_ALERT,
        SCR_TYPE_MENU_MSG,
        SCR_TYPE_WARNNING_MSG,
        SCR_TYPE_POWER_OFF,
        SCR_TYPE_MAX,
    };

    enum
    {
        SCR_INFO_ROTATE,
        SCR_HOME,
        SCR_POWER_OFF,
        SCR_POWER_OFF_START,
        SCR_WAN_SETTING,
        SCR_WAN_SET_IP,
        SCR_WAN_SET_NETMASK,
        SCR_WAN_SUCCESS,
        SCR_WAN_DISPLAY_IP,
        SCR_LAN_SET_IP,
        SCR_LAN_SET_NETMASK,
        SCR_LAN_SUCCESS,
        SCR_LINK_SETTING,
        SCR_LINK_SUCCESS,
        SCR_USB_COPY,
        SCR_USB_COPY_PROGRESS,
        SCR_USB_COPY_FINISH,
        SCR_VERIFY,
        SCR_VERIFY_FAIL,
        SCR_PASSWORD,
        SCR_PASSWORD_SUCCESS,
        SCR_LANGUAGE,
        SCR_LANGUAGE_SUCCESS,
        SCR_RESET_DEFAULT,
        SCR_RESET_DEFAULT_SUCCESS,
        SCR_ALARM_MUTE,
        SCR_ALARM_MUTE_SUCCESS,
        SCR_EXIT_HOME,
        SCR_ALERT,
        SCR_WARNING,
        SCR_SCREEN_SAVER,
        SCR_OLED_OFF,
        SCR_PIE_CHAR,
        SCR_GENERAL_MENU_WARNING,
        SCR_PIC_VERSION_WARNING,
//        SCR_UNDER_CONSTRUCTURE,
#ifdef STATUS_LED
	  SCR_STATUS_LED,
	  SCR_STATUS_LED_SUCCESS,
#endif
        SCR_MAX
    };

    enum
    {
        HOME_WAN_SETTING,
        HOME_LAN_SETTING,
        HOME_LINK_AGGREGATION,
        HOME_USB_COPY,
        HOME_ADMIN_PASSWORD,
        HOME_LANGUAGE,
        HOME_RESET_DEFAULT,
        HOME_ALARM_MUTE,
#ifdef STATUS_LED        
	  HOME_STATUS_LED,
#endif
        HOME_EXIT,
        HOME_MAX
    };

    enum
    {
        WAN_STATIC,
        WAN_DHCP,
        WAN_MAX
    };

    enum
    {
        LINK_302_3AD,
        LINK_FAILOVER,
        LINK_LOAD_BALANCE,
        LINK_DISABLE,
        LINK_MAX

    };

    enum
    {
        EVENT_POWER_OFF=1,
        EVENT_BTN_POWER,
        EVENT_BTN_RESET,
        EVENT_BTN_UP,
        EVENT_BTN_DOWN,
        EVENT_BTN_ENTER,
        EVENT_BTN_ESC,
        EVENT_CMD_STATUS,
        EVENT_INPUT_COMPLETE,
        EVENT_I2C_END,
        EVENT_OPERATION_START=100,
        EVENT_OPERATION_TIMEOUT=EVENT_OPERATION_START,
        EVENT_OPERATION_ENTER,
        EVENT_OPERATION_BACK,
        EVENT_OPERATION_LEAVE,
        EVENT_OPERATION_EXIT,
        EVENT_OPERATION_EXIT_BY_INTERRUPT,
        EVENT_OPERATION_END=EVENT_OPERATION_EXIT_BY_INTERRUPT,
        EVENT_OPERATION_MAX,
        EVENT_SYSINFO_INIT,
        EVENT_SYSINFO_TIMEOUT,
        EVENT_MAX,
    };

    enum
    {
        ALERT_AC_POWER_LOST,
        ALERT_AC_POWER_RECORVER,
        ALERT_MAX
    };

    enum
    {
        USB_COPY_DONE,
        USB_COPY_FAIL,
        USB_COPY_PROGRESS,
        USB_COPY_MAX
    };

    typedef struct menu_queue_struct
    {
        uint8_t action;
    } menu_queue;

    typedef struct menu_push_struct
    {
        uint8_t action;
        uint8_t scr_type;
        uint32_t scr_id;
        void *pMenuData;
    } menu_push_t;

    typedef struct menu_pop_struct
    {
        uint8_t action;
        uint8_t show_prev;
        uint8_t pop_level;
        void *pMenuData;
    } menu_pop_t;

    typedef struct menu_action_struct
    {
        uint8_t action;
        uint8_t event;
        uint8_t value[4];
    } menu_action_t;

    typedef struct menu_timeout_struct
    {
        uint8_t action;
        uint8_t event;
        TimeOutCBFuncPtr_t cb;
        void * pData;
    } menu_timeout_t;

    typedef struct menu_show_screen_struct
    {
        uint8_t action;
        uint8_t scr_Id;
        void *pScr_Data;
        void * pData;
    } menu_show_screen_t;

    typedef struct
    {
        uint32_t id;
        uint8_t value[4];
        uint8_t sel_idx;
        uint8_t type;
        void *pData;
    } scr_data;

    typedef struct
    {
        uint32_t type;
        uint8_t time[24];
        void *pData;
    } alert_data;

    typedef int32_t (*ScrFuncPtr_t)(uint32_t event, void *pMenu);

    void menu_queue_handler(int32_t signum);
    int32_t menu_queue_release(void);
    int32_t menu_do_push(uint32_t scr_id, uint8_t scr_type, void *pMenuData);
    int32_t menu_push(uint32_t scr_id, uint8_t scr_type, void *pMenuData);
    int32_t menu_do_pop2(void **ppData, uint8_t show_prev);
    int32_t menu_pop2(void **ppData, uint8_t show_prev);
    int32_t menu_pop(void **ppData);
    int32_t menu_do_pop_to_level(uint8_t level, uint8_t show_prev);
    int32_t menu_pop_to_level(uint8_t level, uint8_t show_prev);
    int32_t menu_pop_to_home(void);
    int32_t menu_init(void);
    int32_t menu_start(void);
    int32_t menu_release(void);
    int32_t menu_do_i2c_cmd(uint32_t event, uint8_t *pRetVal);
    int32_t menu_i2c_cmd(uint32_t event, uint8_t *pRetVal);
    int32_t menu_do_timeout(uint32_t event, TimeOutCBFuncPtr_t cb, void *pData);
    int32_t menu_timeout(uint32_t event, TimeOutCBFuncPtr_t cb, void *pData);
    int32_t alert_add(uint32_t type, void *pAlertData);
    int32_t alert_delete(void *pAlertData);
    int32_t warning_show(int8_t *pStr, int8_t *level, uint8_t state);
    int32_t pie_char_show(int8_t *pStr, uint8_t process, uint8_t state);
    int32_t power_off_show(void);
    int32_t usb_copy_show(uint8_t state);

#ifdef	__cplusplus
}
#endif

#endif	/* _MENU_H */

