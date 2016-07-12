/* 
 * File:   scr_template.h
 * Author: dorianko
 *
 * Created on 2009年10月22日, 下午 5:15
 */

#ifndef _SCR_TEMPLATE_H
#define	_SCR_TEMPLATE_H

#define TEMPLATE_05_HEADER_SIZE 7


#ifdef	__cplusplus
extern "C" {
#endif

    #define __WISH_LIST_ROTATE_NEW_INFO__

    enum
    {
        SCR_TEMPLATE_00,
        SCR_TEMPLATE_01,
        SCR_TEMPLATE_02,
        SCR_TEMPLATE_03,
        SCR_TEMPLATE_04,
        SCR_TEMPLATE_05,
        SCR_TEMPLATE_06,
        SCR_TEMPLATE_07,
        SCR_TEMPLATE_08,
        SCR_TEMPLATE_09,
        SCR_TEMPLATE_10,
        SCR_TEMPLATE_11,
        SCR_TEMPLATE_MAX,
    };

    enum
    {
        OBJECT_ACTION_REMOVE,
        OBJECT_ACTION_ADD,
        OBJECT_ACTION_UPDATE,
        OBJECT_ACTION_CLEAR_OLED_WITH_COLOR,
        OBJECT_ACTION_SHOW,
        OBJECT_ACTION_MAX,
    };

    enum
    {
        OBJECT_TYPE_PAGE,
        OBJECT_TYPE_COLOR,
        OBJECT_TYPE_STYLE,
        OBJECT_TYPE_FONT,
        OBJECT_TYPE_TEXT,
        OBJECT_TYPE_INPUT,
        OBJECT_TYPE_BMP,
        OBJECT_TYPE_LINE,
        OBJECT_TYPE_BLOCK,
        OBJECT_TYPE_VARIABLE_STR,
        OBJECT_TYPE_VARIABLE_ID,
        OBJECT_TYPE_VARIABLE_IP,
        OBJECT_TYPE_VARIABLE_PROCESS,
        OBJECT_TYPE_CAPACITY,
        OBJECT_TYPE_MAX,
    };

    enum
    {
        INPUT_TYPE_LIST_HOME_BMP,
        INPUT_TYPE_LIST_HOME,
        INPUT_TYPE_LIST_WAN_MODE,
        INPUT_TYPE_LIST_WAN_SET,
        INPUT_TYPE_LIST_LAN_SET,
        INPUT_TYPE_LIST_LINK_AGGR,
        INPUT_TYPE_LIST_YES_NO,
        INPUT_TYPE_IP,
        INPUT_TYPE_PASSWORD,
        INPUT_TYPE_LIST_LANGUAGE,
        INPUT_TYPE_MAX,
    };

    enum
    {
        SCREEN_POWER_OFF,
        SCREEN_POWER_ON,
        SCREEN_SAVER,
        SCREEN_MAX
    };

    typedef struct
    {
        uint8_t type;
        uint8_t title_id;
        uint8_t *mid_str;
        uint8_t mid_id;
    } template_05;

    typedef struct
    {
        uint8_t title_id;
        uint8_t *mid_str;
        uint8_t mid_id;
        uint8_t *bottom_str;

    } template_06;

    typedef struct
    {
        uint8_t title_id;
        uint8_t mid_bmp_id;
        uint8_t mid_str_id;
        uint8_t *bottom_str;

    } template_07;

    typedef struct
    {
        uint8_t title_id;
        uint8_t mid_id;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
        uint8_t mid_bmp;
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
        uint8_t *mid_str;
        uint8_t bottom_id;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
        uint8_t bottom_bmp;
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
        uint8_t *bottom_str;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
        uint8_t usage;
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
    } template_08;

    typedef struct
    {
        uint8_t type;
        uint8_t title_id;
        uint8_t *mid_str;
        uint8_t mid_id;
        uint8_t have_timeout;
    } template_09;

    typedef struct
    {
        uint8_t type;
        uint8_t title_id;
        uint8_t *mid_str;
        uint8_t mid_id;
        uint8_t process;
        uint8_t color;
    } template_11;

    int32_t show_screen(uint8_t Scr_Id, void *pScr_Data);
    int32_t update_screen_02(void *pScr_Data);
    int32_t update_screen_03(void *pScr_Data);
    int32_t update_screen_04(void *pScr_Data);
    int32_t update_screen_05(void *pScr_Data);
    int32_t update_screen_06(void *pScr_Data);
    int32_t update_screen_07(void *pScr_Data);
    int32_t update_screen_08(void *pScr_Data);
    int32_t update_screen_09(void *pScr_Data);
    int32_t update_screen_10(void *pScr_Data);
    int32_t update_screen_11(void *pScr_Data);
    int32_t screen_state(uint8_t state);
    int32_t stop_motion_screen(uint8_t screen_id);

#ifdef	__cplusplus
}
#endif

#endif	/* _SCR_TEMPLATE_H */

