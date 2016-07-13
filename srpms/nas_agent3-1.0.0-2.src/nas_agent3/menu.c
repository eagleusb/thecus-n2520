
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "utility.h"
#include "i2c.h"
#include "timer.h"
#include "cmd.h"
#include "menu.h"
#include "sysinfo.h"
#include "scr_template.h"
#include "stringtable.h"

#if 1
    #define SCREEN_SAVER_TIME_OUT 1200
    #define OLED_OFF_TIME_OUT 1800
    #define ROTATE_MENU_TIME_OUT 600   //luke
    #define PIC_WARNING_TIME_OUT 300   //luke
#else
    #define SCREEN_SAVER_TIME_OUT 300
    #define OLED_OFF_TIME_OUT 300
#endif

enum
{
    ROTATE_INFO_SCR_STATE_ROTATE,
    ROTATE_INFO_SCR_STATE_STATIC,
    ROTATE_INFO_SCR_STATE_MAX,
};

/////////////////////   extern    //////////////////////////////////
extern sigset_t _gSigMask;
extern sys_info _gSys_Info;
extern uint8_t _gSys_Info_Show_Idx;
extern uint8_t _gSys_Info_Raid_Idx;
extern uint8_t _gCurrentState;
//extern uint8_t _gPoll_Flag;
extern uint8_t _gPanel_state;
extern uint8_t _gUpgrade_Flag;
extern uint8_t _gPicVersion;
extern uint8_t _gNewLANCheck;
util_list_head *_gMenu_List=NULL;
util_list_head *_gAlert_List=NULL;
util_list_head *_gMenu_Queue=NULL;
uint32_t _gAlert_Show_Idx=0;
uint8_t _gMenu_Init_Flag=0;
uint8_t _gUsb_Copy_State=0;
uint8_t _gSys_Info_Scr_State=ROTATE_INFO_SCR_STATE_ROTATE;
template_09 _gWarning_Src_Data={0};
uint8_t _gMenu_Cmd_Run_Flag=0;
uint8_t _gPic_Version_Flag=0;

/////////////////////   static prototype    //////////////////////////////////
static int32_t home_scr(uint32_t event, void *pMenu);
static int32_t info_rotate_scr(uint32_t event, void *pMenu);
static int32_t power_off_scr(uint32_t event, void *pMenu);
static int32_t power_off_start_scr(uint32_t event, void *pMenu);
static int32_t wan_setting_scr(uint32_t event, void *pMenu);
static int32_t wan_set_ip_scr(uint32_t event, void *pMenu);
static int32_t wan_set_netmask_scr(uint32_t event, void *pMenu);
static int32_t wan_success_scr(uint32_t event, void *pMenu);
static int32_t wan_display_ip_scr(uint32_t event, void *pMenu);
static int32_t lan_set_ip_scr(uint32_t event, void *pMenu);
static int32_t lan_set_netmask_scr(uint32_t event, void *pMenu);
static int32_t lan_success_scr(uint32_t event, void *pMenu);
static int32_t link_setting_scr(uint32_t event, void *pMenu);
static int32_t link_success_scr(uint32_t event, void *pMenu);
static int32_t usb_copy_scr(uint32_t event, void *pMenu);
static int32_t usb_copy_progress_scr(uint32_t event, void *pMenu);
static int32_t usb_copy_finish_scr(uint32_t event, void *pMenu);
static int32_t verify_scr(uint32_t event, void *pMenu);
static int32_t verify_fail_scr(uint32_t event, void *pMenu);
static int32_t password_scr(uint32_t event, void *pMenu);
static int32_t password_success_scr(uint32_t event, void *pMenu);
static int32_t language_scr(uint32_t event, void *pMenu);
static int32_t language_success_scr(uint32_t event, void *pMenu);
static int32_t reset_default_scr(uint32_t event, void *pMenu);
static int32_t reset_default_success_scr(uint32_t event, void *pMenu);
static int32_t alarm_mute_scr(uint32_t event, void *pMenu);
static int32_t alarm_mute_success_scr(uint32_t event, void *pMenu);
static int32_t exit_home_scr(uint32_t event, void *pMenu);
static int32_t screen_saver_scr(uint32_t event, void *pMenu);
static int32_t screen_power_off_scr(uint32_t event, void *pMenu);
static int32_t alert_scr(uint32_t event, void *pMenu);
static int32_t warning_scr(uint32_t event, void *pMenu);
static int32_t pie_chart_scr(uint32_t event, void *pMenu);
static int32_t update_alert_page(alert_data *vpAlert);
static int32_t menu_pop_rotate_timeout_cb(uint32_t event, void *pData);
static int32_t general_menu_warning_scr(uint32_t event, void *pMenu);
static int32_t pic_version_warning_scr(uint32_t event, void *pMenu);
#ifdef STATUS_LED
static int32_t status_led_scr(uint32_t event, void *pMenu);
static int32_t status_led_success_scr(uint32_t event, void *pMenu);
#endif

static ScrFuncPtr_t scr_list[]=
{
    info_rotate_scr,
    home_scr,
    power_off_scr,
    power_off_start_scr,
    wan_setting_scr,
    wan_set_ip_scr,
    wan_set_netmask_scr,
    wan_success_scr,
    wan_display_ip_scr,
    lan_set_ip_scr,
    lan_set_netmask_scr,
    lan_success_scr,
    link_setting_scr,
    link_success_scr,
    usb_copy_scr,
    usb_copy_progress_scr,
    usb_copy_finish_scr,
    verify_scr,
    verify_fail_scr,
    password_scr,
    password_success_scr,
    language_scr,
    language_success_scr,
    reset_default_scr,
    reset_default_success_scr,
    alarm_mute_scr,
    alarm_mute_success_scr,
    exit_home_scr,
    alert_scr,
    warning_scr,
    screen_saver_scr,
    screen_power_off_scr,
    pie_chart_scr,
    general_menu_warning_scr,
    pic_version_warning_scr,
#ifdef STATUS_LED    
    status_led_scr,//35
    status_led_success_scr, 
#endif       
//    underconstructure_scr,
};

/////////////////////   normal implement    //////////////////////////////////
int32_t menu_queue_add(menu_queue *pMenuQueue)
{
    void *vpMenu=NULL;
    int32_t vRet=0;

    IN(DEBUG_MODEL_MENU,"");

    if( NULL == _gMenu_Queue )
        _gMenu_Queue = util_list_init();

    if( NULL == _gMenu_Queue)
        return -1;

    switch(pMenuQueue->action)
    {
        case MENU_QUEUE_PUSH:
        {
            menu_push_t *vpMenuPush=NULL;

            vpMenuPush= (menu_push_t*) malloc(sizeof(menu_push_t));  /// create a new menu queue

            if( NULL == vpMenuPush)
                return -1;

            memset(vpMenuPush, 0, sizeof(menu_push_t));
            memcpy(vpMenuPush, pMenuQueue, sizeof(menu_push_t));
            vpMenu=(void *)vpMenuPush;
        }
        break;
        case MENU_QUEUE_POP:
        {
            menu_pop_t *vpMenuPop=NULL;

            vpMenuPop= (menu_pop_t*) malloc(sizeof(menu_pop_t));  /// create a new menu queue

            if( NULL == vpMenuPop)
                return -1;

            memset(vpMenuPop, 0, sizeof(menu_pop_t));
            memcpy(vpMenuPop, pMenuQueue, sizeof(menu_pop_t));
            vpMenu=(void *)vpMenuPop;
        }
        break;
        case MENU_QUEUE_POP_TO_LEVEL:
        {
            menu_pop_t *vpMenuPop=NULL;

            vpMenuPop= (menu_pop_t*) malloc(sizeof(menu_pop_t));  /// create a new menu queue

            if( NULL == vpMenuPop)
                return -1;

            memset(vpMenuPop, 0, sizeof(menu_pop_t));
            memcpy(vpMenuPop, pMenuQueue, sizeof(menu_pop_t));
            vpMenu=(void *)vpMenuPop;
        }
        break;
        case MENU_QUEUE_ACTION:
        {
            menu_action_t *vpMenuAction=NULL;

            vpMenuAction= (menu_action_t*) malloc(sizeof(menu_action_t));  /// create a new menu queue

            if( NULL == vpMenuAction)
                return -1;

            memset(vpMenuAction, 0, sizeof(menu_action_t));
            memcpy(vpMenuAction, pMenuQueue, sizeof(menu_action_t));
            vpMenu=(void *)vpMenuAction;
        }
        break;
        case MENU_QUEUE_TIMEOUT:
        {
            menu_timeout_t *vpMenuTimeOut=NULL;

            vpMenuTimeOut= (menu_timeout_t*) malloc(sizeof(menu_timeout_t));  /// create a new menu queue

            if( NULL == vpMenuTimeOut)
                return -1;

            memset(vpMenuTimeOut, 0, sizeof(menu_timeout_t));
            memcpy(vpMenuTimeOut, pMenuQueue, sizeof(menu_timeout_t));
            vpMenu=(void *)vpMenuTimeOut;
        }
        break;
        case MENU_QUEUE_SHOW_SCREEN:
        {
            menu_show_screen_t *vpMenuShowScreen=NULL;

            vpMenuShowScreen= (menu_show_screen_t*) malloc(sizeof(menu_show_screen_t));  /// create a new menu queue

            if( NULL == vpMenuShowScreen)
                return -1;

            memset(vpMenuShowScreen, 0, sizeof(menu_show_screen_t));
            memcpy(vpMenuShowScreen, pMenuQueue, sizeof(menu_show_screen_t));
            vpMenu=(void *)vpMenuShowScreen;
        }
        break;
        default:
        break;
    }
    vRet=util_add_to_end((void *)vpMenu, &_gMenu_Queue);
    OUT(DEBUG_MODEL_MENU, "count %d",  _gMenu_Queue->count);

    raise(SIG_PROC_MENU);
    return vRet;
}

int32_t menu_queue_release(void)
{
    int32_t vRet=0;
    menu_queue *vpMenuQueue=NULL;

    if( NULL == _gMenu_Queue )
        return -1;

    while(_gMenu_Queue->count > 0)
    {
        util_get_from_start((void **)&vpMenuQueue, &_gMenu_Queue);

        if(vpMenuQueue)
        {
            free(vpMenuQueue);
            vpMenuQueue=NULL;
        }
    }

    if( NULL != _gMenu_Queue )
    {
        util_list_release(_gMenu_Queue);
        _gMenu_Queue=NULL;
    }

    return 0;
}


void menu_queue_handler(int32_t signum)
{
    void *vpMenu=NULL;

    IN(DEBUG_MODEL_MENU, "");

    if(_gUpgrade_Flag)
        return;

    if( NULL == _gMenu_Queue || 0 == _gMenu_Queue->count)
        return;

    if(util_get_from_start((void **)&vpMenu, &_gMenu_Queue) != 0)
        return;

    if(NULL == vpMenu)
        return;
    sigaddset(&_gSigMask,SIG_PROC_MENU);
    sigprocmask(SIG_BLOCK,&_gSigMask,NULL);
//    _gPoll_Flag++;
    BLOCK_INTERRUPT;

    if(_gCurrentState >= STATE_BOOTING && MENU_QUEUE_TIMEOUT != ((menu_queue *)vpMenu)->action)
    {
        if(MIN_PIC_VERSION <= _gPicVersion && 0 == _gPic_Version_Flag)//luke add 20100720
	{
 	    general_set_timer(TIMER_ID_MENU_POP_ROTATE, ROTATE_MENU_TIME_OUT, menu_pop_rotate_timeout_cb, NULL); //luke add 20100720: only show warning message with 30 sec.
	}else{
 	    general_set_timer(TIMER_ID_MENU_POP_ROTATE, PIC_WARNING_TIME_OUT, menu_pop_rotate_timeout_cb, NULL); //put here in case application need to over write timout setting
	}
    }
    switch(((menu_queue *)vpMenu)->action)
    {
        case MENU_QUEUE_PUSH:
        {
            menu_push_t *vpMenuPush=vpMenu;

            menu_do_push(vpMenuPush->scr_id, vpMenuPush->scr_type, vpMenuPush->pMenuData);
        }
        break;
        case MENU_QUEUE_POP:
        {
            menu_pop_t *vpMenuPop=vpMenu;

            menu_do_pop2((void **)vpMenuPop->pMenuData, vpMenuPop->show_prev);
        }
        break;
        case MENU_QUEUE_POP_TO_LEVEL:
        {
            menu_pop_t *vpMenuPop=vpMenu;

            menu_do_pop_to_level(vpMenuPop->pop_level, vpMenuPop->show_prev);
        }
        break;
        case MENU_QUEUE_ACTION:
        {
            menu_action_t *vpMenuAction=vpMenu;

            menu_do_i2c_cmd(vpMenuAction->event, vpMenuAction->value);
        }
        break;
        case MENU_QUEUE_TIMEOUT:
        {
            menu_timeout_t *vpMenuTimeout=vpMenu;
            scr_data *vpCurrMenu=NULL;
            scr_data *vpTimeoutMenu=NULL;

            if(_gMenu_List && _gMenu_List->end)
                vpCurrMenu = (scr_data *)_gMenu_List->end->pData;
            vpTimeoutMenu = (scr_data *)vpMenuTimeout->pData;

            if(vpCurrMenu && vpTimeoutMenu)
                debug_print(DEBUG_MODEL_MENU,"*** curr id %d, timeout id %d ***\n", vpCurrMenu->id, vpTimeoutMenu->id);

            if((vpMenuTimeout->cb == menu_pop_rotate_timeout_cb) || (vpCurrMenu && vpTimeoutMenu && vpCurrMenu->id == vpTimeoutMenu->id))
                menu_do_timeout(vpMenuTimeout->event, vpMenuTimeout->cb, vpMenuTimeout->pData);
        }
        break;
        case MENU_QUEUE_SHOW_SCREEN:
        {
            menu_show_screen_t *vpMenuShowScreen=vpMenu;

            show_screen(vpMenuShowScreen->scr_Id, vpMenuShowScreen->pScr_Data);

            switch (vpMenuShowScreen->scr_Id)
            {
                case SCR_TEMPLATE_09:
                {
                    template_09 *vpSrc_Data=vpMenuShowScreen->pScr_Data;

                    if(vpSrc_Data && vpSrc_Data->mid_str)
                    {
                        free(vpSrc_Data->mid_str);
                        vpSrc_Data->mid_str=NULL;
                    }

                    if(vpSrc_Data)
                    {
                        free(vpSrc_Data);
                        vpSrc_Data=NULL;
                    }
                }
                break;
                case SCR_TEMPLATE_11:
                {
                    template_11 *vpSrc_Data=vpMenuShowScreen->pScr_Data;

                    if(vpSrc_Data && vpSrc_Data->mid_str)
                    {
                        free(vpSrc_Data->mid_str);
                        vpSrc_Data->mid_str=NULL;
                    }

                    if(vpSrc_Data)
                    {
                        free(vpSrc_Data);
                        vpSrc_Data=NULL;
                    }
                }
                break;
                case SCR_TEMPLATE_06:
                {
                    template_06 *vpSrc_Data=vpMenuShowScreen->pScr_Data;

                    if(vpSrc_Data && vpSrc_Data->bottom_str)
                    {
                        free(vpSrc_Data->bottom_str);
                        vpSrc_Data->bottom_str=NULL;
                    }

                    if(vpSrc_Data)
                    {
                        free(vpSrc_Data);
                        vpSrc_Data=NULL;
                    }
                }
                break;
            }
        }
        break;
        default:
        break;
    }


    if(vpMenu)
    {
        free(vpMenu);
        vpMenu=NULL;
    }
//    _gPoll_Flag--;
    RELEASE_INTERRUPT;
    sigprocmask(SIG_UNBLOCK,&_gSigMask,NULL);
    OUT(DEBUG_MODEL_MENU, "");
}

int32_t menu_do_push(uint32_t scr_id, uint8_t scr_type, void *pMenuData)
{
    int32_t vRet=0;
    scr_data *vpCurrMenu=NULL;
    scr_data *vpNewMenu=NULL;

    IN(DEBUG_MODEL_MENU, "scr_id %d", scr_id);
    if( NULL == _gMenu_List )
    {
        _gMenu_List = util_list_init();
    }

    if( NULL == _gMenu_List || _gMenu_List->count > MAX_MENU_NUM)
        return -1;

    if(_gMenu_List->end)
    {
        if(_gMenu_List->end->pData)
            vpCurrMenu=(scr_data *)_gMenu_List->end->pData;
    }

    if(vpCurrMenu && vpCurrMenu->type > scr_type)
        return -1;
    else if(vpCurrMenu)
        scr_list[vpCurrMenu->id](EVENT_OPERATION_LEAVE, vpCurrMenu);

    vpNewMenu= (scr_data*) malloc(sizeof(scr_data));  /* create a new menu data */
    memset(vpNewMenu, 0, sizeof(scr_data));

    if(vpNewMenu)
    {
        if(vpCurrMenu && (vpCurrMenu->type < scr_type || _gCurrentState < STATE_BOOTING))
            scr_list[vpCurrMenu->id](EVENT_OPERATION_EXIT_BY_INTERRUPT, vpCurrMenu);

        if(!vpCurrMenu || scr_type >= vpCurrMenu->type || _gCurrentState < STATE_BOOTING)
        {
            vpNewMenu->id=scr_id;
            vpNewMenu->pData=pMenuData;
            vpNewMenu->type=scr_type;

            vRet=util_add_to_end((void *)vpNewMenu, &_gMenu_List);
            scr_list[vpNewMenu->id](EVENT_OPERATION_ENTER, vpNewMenu);
        }
    }
    else
        return -2;

    OUT(DEBUG_MODEL_MENU, "");
    return vRet;
}

int32_t menu_push(uint32_t scr_id, uint8_t scr_type, void *pMenuData)
{
    menu_push_t vMenuPush={0};

    IN(DEBUG_MODEL_MENU,"scr_id %d", scr_id);
    vMenuPush.action=MENU_QUEUE_PUSH;
    vMenuPush.scr_id=scr_id;
    vMenuPush.scr_type=scr_type;
    vMenuPush.pMenuData=pMenuData;

    menu_queue_add((menu_queue *)&vMenuPush);
    OUT(DEBUG_MODEL_MENU,"");
    return 0;
}

int32_t menu_do_pop2(void **ppData, uint8_t show_prev)
{
    int32_t vRet=0;
    scr_data *vpMenu=NULL;

    IN(DEBUG_MODEL_MENU, "count - %ld", _gMenu_List->count);
    if( NULL == _gMenu_List)
        return -1;

    if(_gMenu_List->count < 1)
        return -1;

    vRet = util_get_from_end((void **)&vpMenu, &_gMenu_List);

    if(vRet != 0)
        return vRet;

    if(vpMenu)
    {
        if(ppData)
            *ppData=vpMenu->pData;

        scr_list[vpMenu->id](EVENT_OPERATION_EXIT, vpMenu);

        free(vpMenu);
        vpMenu=NULL;
    }

    if(_gMenu_List->end)
    {
        if(_gMenu_List->end->pData)
            vpMenu=(scr_data *)_gMenu_List->end->pData;
    }
    else
    {
        vpMenu=NULL;
    }

    if(vpMenu && show_prev)
    {
        debug_print(DEBUG_MODEL_MENU, "menu type %d\n", vpMenu->type);

        if(_gAlert_List)
            debug_print(DEBUG_MODEL_MENU, ", _gAlert_List count %d\n", _gAlert_List->count);
        else
            debug_print(DEBUG_MODEL_MENU, "\n");

        if(vpMenu->type < SCR_TYPE_ALERT && _gAlert_List && _gAlert_List->count > 0)
            menu_push(SCR_ALERT, SCR_TYPE_ALERT, (alert_data *)_gAlert_List->end->pData);
        else
            scr_list[vpMenu->id](EVENT_OPERATION_BACK, vpMenu);
    }
    else if(show_prev && 0 == _gMenu_List->count && _gAlert_List && _gAlert_List->count > 0)
        menu_push(SCR_ALERT, SCR_TYPE_ALERT, (alert_data *)_gAlert_List->end->pData);
    OUT(DEBUG_MODEL_MENU, "count - %ld", _gMenu_List->count);

    return 0;

}

int32_t menu_pop2(void **ppData, uint8_t show_prev)
{
    menu_pop_t vMenuPop={0};

    vMenuPop.action=MENU_QUEUE_POP;
    vMenuPop.show_prev=show_prev;
    vMenuPop.pMenuData=(void *)ppData;

    menu_queue_add((menu_queue *)&vMenuPop);
    return 0;
}

int32_t menu_pop(void **ppData)
{
    return menu_pop2(ppData, TRUE);
}

int32_t menu_do_pop_to_level(uint8_t level, uint8_t show_prev)
{
    int32_t vRet=0;
    scr_data *vpMenu=NULL;

    IN(DEBUG_MODEL_MENU, "count - %ld", _gMenu_List->count);

    if( NULL == _gMenu_List)
        return -1;

    while(_gMenu_List->count > level)
    {
        vRet = util_get_from_end((void **)&vpMenu, &_gMenu_List);

        if(vRet != 0)
            return vRet;

        if(vpMenu)
        {
            scr_list[vpMenu->id](EVENT_OPERATION_EXIT, vpMenu);

            free(vpMenu);
            vpMenu=NULL;
        }

        if(_gMenu_List->end && _gMenu_List->end->pData)
            vpMenu=(scr_data *)_gMenu_List->end->pData;
    }

    if(vpMenu && level == _gMenu_List->count && show_prev)
    {
        debug_print(DEBUG_MODEL_MENU, "menu type %d\n", vpMenu->type);

        if(_gAlert_List)
            debug_print(DEBUG_MODEL_MENU, ", _gAlert_List count %d\n", _gAlert_List->count);
        else
            debug_print(DEBUG_MODEL_MENU, "\n");


        if(vpMenu->type < SCR_TYPE_ALERT && _gAlert_List && _gAlert_List->count > 0)
            menu_push(SCR_ALERT, SCR_TYPE_ALERT, (alert_data *)_gAlert_List->end->pData);
        else
            scr_list[vpMenu->id](EVENT_OPERATION_BACK, vpMenu);
    }
    else if(show_prev && 0 == _gMenu_List->count && _gAlert_List && _gAlert_List->count > 0)
        menu_push(SCR_ALERT, SCR_TYPE_ALERT, (alert_data *)_gAlert_List->end->pData);
    OUT(DEBUG_MODEL_MENU, "count - %ld", _gMenu_List->count);

    return 0;

}

int32_t menu_pop_to_level(uint8_t level, uint8_t show_prev)
{
    menu_pop_t vMenuPop={0};

    IN(DEBUG_MODEL_MENU,"");
    vMenuPop.action=MENU_QUEUE_POP_TO_LEVEL;
    vMenuPop.show_prev=show_prev;
    vMenuPop.pop_level=level;

    menu_queue_add((menu_queue *)&vMenuPop);
    OUT(DEBUG_MODEL_MENU,"");
    return 0;
}

int32_t menu_pop_to_home(void)
{
    menu_pop_to_level(2, TRUE);
    return 0;
}

int32_t menu_init(void)
{
    IN(DEBUG_MODEL_MENU, "", "");

    if( NULL == _gMenu_List )
    {
        _gMenu_List = util_list_init();
    }
    //stop_motion_screen(0);

    return 0;
}

int32_t menu_start(void)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};

    IN(DEBUG_MODEL_MENU, "", "");

    if(!_gAlert_List || 0 == _gAlert_List->count)
    {
        if(0 == _gMenu_Init_Flag)
            _gMenu_Init_Flag=1;
        menu_push(SCR_INFO_ROTATE, SCR_TYPE_MENU_NORMAL, NULL);
    }

/*
    if(0 == _gMenu_Init_Flag)
    {
        if(!_gAlert_List || 0 == _gAlert_List->count)
        {
            menu_push(SCR_INFO_ROTATE, SCR_TYPE_MENU_NORMAL, NULL);
            _gMenu_Init_Flag=1;
        }
    }
    else
    {
        menu_pop_to_level(1, TRUE);
    }
*/

    return 0;
}

int32_t menu_release(void)
{
    int32_t vRet=0;
    scr_data *vpMenu=NULL;

    if( NULL == _gMenu_List)
        return -1;
    IN(DEBUG_MODEL_MENU, "count - %ld", _gMenu_List->count);

    while(_gMenu_List->count > 0)
    {
        vRet = util_get_from_end((void **)&vpMenu, &_gMenu_List);

        if(vRet != 0)
            return vRet;

        if(vpMenu)
        {
            scr_list[vpMenu->id](EVENT_OPERATION_EXIT, vpMenu);

            free(vpMenu);
            vpMenu=NULL;
        }

    }

    if( NULL != _gMenu_List )
    {
        util_list_release(_gMenu_List);
        _gMenu_List=NULL;
    }

    if( NULL != _gAlert_List )
    {
         util_list_release(_gAlert_List);
         _gAlert_List=NULL;
    }

    return 0;
}



int32_t menu_do_i2c_cmd(uint32_t event, uint8_t *pRetVal)
{
    scr_data *vpMenu=NULL;

    IN(DEBUG_MODEL_MENU, "===== event %d, sel_idx %d_%d_%d_%d =====", event, pRetVal[0], pRetVal[1], pRetVal[2], pRetVal[3] );
    if( NULL == _gMenu_List)
        return -1;

    if(NULL == _gMenu_List->end)
        return -1;

    if(_gMenu_Cmd_Run_Flag)
        return -2;
    _gMenu_Cmd_Run_Flag=1;

    vpMenu=(scr_data *)_gMenu_List->end->pData;

    memdump((uint8_t *)vpMenu, sizeof(scr_data));

    if(vpMenu)
    {
        if( NULL != pRetVal && (EVENT_BTN_ENTER == event || EVENT_INPUT_COMPLETE == event))
        {
            memcpy(vpMenu->value, pRetVal, sizeof(vpMenu->value));
        }
        debug_print(DEBUG_MODEL_MENU, "Menu->id %d\n", vpMenu->id);
        scr_list[vpMenu->id](event, vpMenu);
    }

    _gMenu_Cmd_Run_Flag=0;
    return 0;
}

int32_t menu_i2c_cmd(uint32_t event, uint8_t *pRetVal)
{
    menu_action_t vMenuAction={0};

    IN(DEBUG_MODEL_MENU, "===== event %d, sel_idx %d_%d_%d_%d =====", event, pRetVal[0], pRetVal[1], pRetVal[2], pRetVal[3] );
    vMenuAction.action=MENU_QUEUE_ACTION;
    vMenuAction.event=event;
    memcpy(vMenuAction.value, pRetVal, sizeof(vMenuAction.value));

    menu_queue_add((menu_queue *)&vMenuAction);
    return 0;
}

int32_t menu_do_timeout(uint32_t event, TimeOutCBFuncPtr_t cb, void *pData)
{
    cb(event, pData);

    return 0;
}

int32_t menu_timeout(uint32_t event, TimeOutCBFuncPtr_t cb, void *pData)
{
    menu_timeout_t vMenuTimeOut={0};
    vMenuTimeOut.action=MENU_QUEUE_TIMEOUT;
    vMenuTimeOut.event=event;
    vMenuTimeOut.cb=cb;
    vMenuTimeOut.pData=pData;

    menu_queue_add((menu_queue *)&vMenuTimeOut);
    return 0;
}

int32_t alert_add(uint32_t type, void *pAlertData)
{
    int32_t vRet=0;

    alert_data *vpNewAlert=NULL;

    IN(DEBUG_MODEL_MENU, "", "");
    if( NULL == _gAlert_List )
        _gAlert_List = util_list_init();

    if( NULL == _gAlert_List )
        return -1;

    if( _gAlert_List->count >= MAX_ALERT_NUM)
    {
        while(_gAlert_List->count >= MAX_ALERT_NUM)
            util_get_from_start(NULL, &_gAlert_List);
    }        

    vpNewAlert= (alert_data*) malloc(sizeof(alert_data));  /* create a new menu data */
    memset(vpNewAlert, 0, sizeof(alert_data));

    if(vpNewAlert)
    {
        time_t vTime;

        vTime = time(NULL);
        strftime(vpNewAlert->time, sizeof(vpNewAlert->time), "%H:%M:%S %Y/%m/%d", localtime(&vTime));
        vpNewAlert->type = type;
        vpNewAlert->pData = pAlertData;
        _gAlert_Show_Idx=(uint32_t)_gAlert_List->count;
        vRet=util_add_to_end((void *)vpNewAlert, &_gAlert_List);

#if 1
        if(_gAlert_List->count == 1 && (!_gMenu_List || !(_gMenu_List->end) || !(_gMenu_List->end->pData) || (SCR_TYPE_ALERT >= ((scr_data *)_gMenu_List->end->pData)->type)))
            menu_push(SCR_ALERT, SCR_TYPE_ALERT, vpNewAlert);
        else if(_gAlert_List && _gAlert_List->count > 1 && _gMenu_List && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_ALERT == ((scr_data *)_gMenu_List->end->pData)->type)
            update_alert_page(vpNewAlert);
#else
        if(_gMenu_List && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_ALERT >= ((scr_data *)_gMenu_List->end->pData)->type)
        {
            if(_gAlert_List->count == 1)
                menu_push(SCR_ALERT, SCR_TYPE_ALERT, vpNewAlert);
            else
                update_alert_page(vpNewAlert);
        }
        else if(!_gMenu_List && 1 != _gMenu_Init_Flag)
        {
            if(_gAlert_List->count == 1)
                menu_push(SCR_ALERT, SCR_TYPE_ALERT, vpNewAlert);
            else
                update_alert_page(vpNewAlert);
        }
#endif
    }
    else
        return -2;

    return vRet;
}

int32_t alert_delete(void *pAlertData)
{
    IN(DEBUG_MODEL_MENU, "", "");
    while(_gAlert_List->count > 0)
    {
        alert_data *vpAlert=NULL;

        util_get_from_end((void **)&vpAlert, &_gAlert_List);
        free(vpAlert);
        vpAlert=NULL;
    }
    OUT(DEBUG_MODEL_MENU, "", "");
    return 0;
}

int32_t warning_show(int8_t *pStr, int8_t *level, uint8_t state)
{
    uint8_t vStrId=0;
    int32_t vStrIdRet=0;
    template_09 *pSrc_Data=NULL;

    IN(DEBUG_MODEL_MENU, "%s", pStr);

    pSrc_Data = (template_09 *)malloc(sizeof(template_09));

    if(NULL == pSrc_Data)
    return -1;
    memset(pSrc_Data, 0, sizeof(template_09));

    pSrc_Data->title_id=99;
    vStrIdRet=search_tab((cmd_table *)_gStrTable, pStr, &vStrId);

    if( -1 == vStrIdRet)
    {
        int32_t vLen=strlen((const char *)pStr);

        pSrc_Data->type=OBJECT_TYPE_VARIABLE_STR;
        pSrc_Data->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*vLen +1);
        memset(pSrc_Data->mid_str, 0, sizeof(uint8_t)*vLen +1);
        memcpy(pSrc_Data->mid_str, pStr, sizeof(uint8_t)*vLen);
        debug_print(DEBUG_MODEL_MENU, "%s \n", pSrc_Data->mid_str);
    }
    else
    {
        pSrc_Data->type=OBJECT_TYPE_VARIABLE_ID;
        pSrc_Data->mid_id=vStrId;
    }

    if(state <= STATE_BOOTING)
    {
        if(_gMenu_List || 0 == _gMenu_List->count)
            menu_push(SCR_WARNING, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
        else
        {
#if 1
            menu_show_screen_t vMenuShowScreen={0};

            vMenuShowScreen.action=MENU_QUEUE_SHOW_SCREEN;
            vMenuShowScreen.scr_Id=SCR_TEMPLATE_09;
            vMenuShowScreen.pScr_Data=pSrc_Data;

            menu_queue_add((menu_queue *)&vMenuShowScreen);
#else
            show_screen(SCR_TEMPLATE_09, pSrc_Data);

            if(pSrc_Data && pSrc_Data->mid_str)
            {
                free(pSrc_Data->mid_str);
                pSrc_Data->mid_str=NULL;
            }

            if(pSrc_Data)
            {
                free(pSrc_Data);
                pSrc_Data=NULL;
            }
#endif
        }
    }
    else
    {
        if((_gMenu_List && 1 == _gMenu_List->count) || (_gMenu_List && 1 < _gMenu_List->count && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_WARNNING_MSG == ((scr_data *)_gMenu_List->end->pData)->type))  //  Only in rotate screen can push warrning message
        {
            if(1 < _gMenu_List->count)
                menu_pop2(NULL, FALSE);

            if(atoi(level) > 10)
            {
                pSrc_Data->have_timeout = 1;
                menu_push(SCR_WARNING, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
            }
            else
            {
                menu_push(SCR_WARNING, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
            }
        }
        else if(_gMenu_List && 1 < _gMenu_List->count && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_POWER_SAVE == ((scr_data *)_gMenu_List->end->pData)->type)
        {
            menu_push(SCR_WARNING, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
        }
    }
    OUT(DEBUG_MODEL_MENU, "", "");

    return 0;
}

int32_t pie_char_show(int8_t *pStr, uint8_t process, uint8_t state)
{
    uint8_t vStrId=0;
    int32_t vStrIdRet=0;
    template_11 *pSrc_Data=NULL;

    IN(DEBUG_MODEL_MENU, "%d, %d, \"%s\"", process & 0x0F, (process >> 4) & 0x0F, pStr);

    pSrc_Data = (template_11 *)malloc(sizeof(template_11));

    if(NULL == pSrc_Data)
        return -1;
    memset(pSrc_Data, 0, sizeof(template_11));

    pSrc_Data->title_id=99;
    vStrIdRet=search_tab((cmd_table *)_gStrTable, pStr, &vStrId);

    if( -1 == vStrIdRet)
    {
        int32_t vLen=strlen((const char *)pStr);

        pSrc_Data->type=OBJECT_TYPE_VARIABLE_STR;
        pSrc_Data->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*vLen +1);
        memset(pSrc_Data->mid_str, 0, sizeof(uint8_t)*vLen +1);
        memcpy(pSrc_Data->mid_str, pStr, sizeof(uint8_t)*vLen);
        debug_print(DEBUG_MODEL_MENU, "String not found: %s \n", pSrc_Data->mid_str);
    }
    else
    {
        pSrc_Data->type=OBJECT_TYPE_VARIABLE_ID;
        pSrc_Data->mid_id=vStrId;
    }
    pSrc_Data->process=process & 0x0F;
    pSrc_Data->color=(process >> 4) & 0x0F;

    if(state <= STATE_BOOTING)
    {
        if(!_gAlert_List || 0 == _gAlert_List->count)
        {
            if(_gMenu_List && 0 == _gMenu_List->count)
                menu_push(SCR_PIE_CHAR, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
            else
            {
#if 1
                menu_show_screen_t vMenuShowScreen={0};

                vMenuShowScreen.action=MENU_QUEUE_SHOW_SCREEN;
                vMenuShowScreen.scr_Id=SCR_TEMPLATE_11;
                vMenuShowScreen.pScr_Data=pSrc_Data;

                menu_queue_add((menu_queue *)&vMenuShowScreen);
#else
                show_screen(SCR_TEMPLATE_11, pSrc_Data);

                if(pSrc_Data && pSrc_Data->mid_str)
                {
                    free(pSrc_Data->mid_str);
                    pSrc_Data->mid_str=NULL;
                }

                if(pSrc_Data)
                {
                    free(pSrc_Data);
                    pSrc_Data=NULL;
                }
#endif
            }
        }
    }
    else
    {
        if((_gMenu_List && 1 == _gMenu_List->count) || (_gMenu_List && 1 < _gMenu_List->count && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_WARNNING_MSG == ((scr_data *)_gMenu_List->end->pData)->type))  //  Only in rotate screen can push warrning message
        {
            if(1 < _gMenu_List->count)
                menu_pop2(NULL, FALSE);
            menu_push(SCR_PIE_CHAR, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
        }
        else if(_gMenu_List && 1 < _gMenu_List->count && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_POWER_SAVE == ((scr_data *)_gMenu_List->end->pData)->type)
        {
            menu_push(SCR_PIE_CHAR, SCR_TYPE_WARNNING_MSG, (void *)pSrc_Data);
        }
    }
    OUT(DEBUG_MODEL_MENU, "", "");

    return 0;
}

int32_t power_off_show(void)
{
    IN(DEBUG_MODEL_MENU, "");

    if(_gMenu_List && (1 == _gMenu_List->count || _gPanel_state != SCREEN_POWER_ON))  //  Only in rotate screen can push warrning message
        menu_push(SCR_POWER_OFF, SCR_TYPE_WARNNING_MSG, NULL);
    else
    {
        template_05 *vpMenu_Data=NULL;
        uint8_t *vpString="ESC menu before power off.";

        vpMenu_Data = (template_05 *)malloc(sizeof(template_05));

        if(NULL == vpMenu_Data)
            return -1;
        vpMenu_Data->type=OBJECT_TYPE_VARIABLE_STR;
        vpMenu_Data->title_id=99;
        vpMenu_Data->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
        memset(vpMenu_Data->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
        memcpy(vpMenu_Data->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

        menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data);
    }

    return 0;
}

int32_t usb_copy_show(uint8_t state)
{
    IN(DEBUG_MODEL_MENU, "state %d", state);

    switch(state)
    {
        case USB_COPY_FAIL:
        case USB_COPY_DONE:
        {
            _gUsb_Copy_State=state;
            menu_push(SCR_USB_COPY_FINISH, SCR_TYPE_WARNNING_MSG, (void *)state);
        }
        break;
        case USB_COPY_PROGRESS:
        {
            if(state != _gUsb_Copy_State)
            {
                _gUsb_Copy_State=state;
                menu_push(SCR_USB_COPY_PROGRESS, SCR_TYPE_WARNNING_MSG, NULL);
            }
            else
                general_set_timer(TIMER_ID_MENU_POP_ROTATE, ROTATE_MENU_TIME_OUT, menu_pop_rotate_timeout_cb, NULL);
        }
        break;
        default:
        break;            
    }

    return 0;
}
/////////////////////   static implement    //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//
//      Screen Event Handler
//
///////////////////////////////////////////////////////////////////////////////
static int32_t menu_pop_rotate_timeout_cb(uint32_t event, void *pData)
{
    IN(DEBUG_MODEL_MENU,"");
    
    if(_gMenu_List && _gMenu_List->end && _gMenu_List->end->pData && SCR_TYPE_MENU_NORMAL == ((scr_data *)_gMenu_List->end->pData)->type)
        menu_pop_to_level(1, TRUE);
}

static int32_t home_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;
    int lanstatus;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d, select_indx %d", event, vpMenu->value[0]);

    switch(event)
    {
        case EVENT_BTN_ENTER:
        {
            switch((vpMenu->sel_idx = vpMenu->value[0]))
            {
                case HOME_WAN_SETTING:
                { 
                    if(_gNewLANCheck == 1)
                    {
                        int32_t ha;

                        ha=system("/img/bin/rc/rc.net check_ha_vip eth0 > /dev/null 2 >&1");
                        if(ha!=0){
                            template_05 *vpMenu_Data1=NULL;
                            uint8_t *vpString="It is HA interface.";
                            vpMenu_Data1 = (template_05 *)malloc(sizeof(template_05));

                            if(NULL == vpMenu_Data1)
                                return -1;
                            vpMenu_Data1->type=OBJECT_TYPE_VARIABLE_STR;
                            vpMenu_Data1->title_id=99;
                            vpMenu_Data1->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
                            memset(vpMenu_Data1->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
                            memcpy(vpMenu_Data1->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

                            menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data1);
                            return 0;
                        }
                    }
                    menu_push(SCR_WAN_SETTING, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case HOME_LAN_SETTING:
                {
                     if(_gNewLANCheck == 1)
                     {
                         int32_t ha;

                          ha=system("/img/bin/rc/rc.net check_ha_vip eth1 > /dev/null 2 >&1");
                          if(ha!=0){
                              template_05 *vpMenu_Data1=NULL;
                              uint8_t *vpString="It is HA interface.";
                              vpMenu_Data1 = (template_05 *)malloc(sizeof(template_05));

                              if(NULL == vpMenu_Data1)
                                  return -1;
                              vpMenu_Data1->type=OBJECT_TYPE_VARIABLE_STR;
                              vpMenu_Data1->title_id=99;
                              vpMenu_Data1->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
                              memset(vpMenu_Data1->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
                              memcpy(vpMenu_Data1->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

                              menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data1);
                              return 0;
                         }

                         lanstatus=system("/img/bin/function/get_interface_info.sh check_eth_bond eth1 > /dev/null 2 >&1");
                     }else
                     {
			     if ((_gSys_Info.nic_1_dhcp_enable == TRUE) || ( _gSys_Info.link_mode == LINK_MODE_NONE))
				  lanstatus =0;
			    else
				  lanstatus =1;	
                     }			
                     if (lanstatus == 0)
                            menu_push(SCR_LAN_SET_IP, SCR_TYPE_MENU_NORMAL, NULL);
 			else
                     {
	                        template_05 *vpMenu_Data=NULL;
	                        uint8_t *vpString="Link aggr. is enabled.";

	                        vpMenu_Data = (template_05 *)malloc(sizeof(template_05));

	                        if(NULL == vpMenu_Data)
	                            return -1;
	                        vpMenu_Data->type=OBJECT_TYPE_VARIABLE_STR;
	                        vpMenu_Data->title_id=99;
	                        vpMenu_Data->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
	                        memset(vpMenu_Data->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
	                        memcpy(vpMenu_Data->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

	                        menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data);
                      }			

                }
                break;
                case HOME_LINK_AGGREGATION:
                {
                    if(_gNewLANCheck == 1)
                    {
                        int32_t ha;

                        ha=system("/img/bin/rc/rc.net check_ha_vip eth0 > /dev/null 2 >&1");
                        if(ha!=0){
                            template_05 *vpMenu_Data1=NULL;
                            uint8_t *vpString="It is HA interface.";
                            vpMenu_Data1 = (template_05 *)malloc(sizeof(template_05));

                            if(NULL == vpMenu_Data1)
                                return -1;
                            vpMenu_Data1->type=OBJECT_TYPE_VARIABLE_STR;
                            vpMenu_Data1->title_id=99;
                            vpMenu_Data1->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
                            memset(vpMenu_Data1->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
                            memcpy(vpMenu_Data1->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

                            menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data1);
                            return 0;
                        }
                    }

                    if (_gSys_Info.nic_1_dhcp_enable == TRUE)
                    {
                        template_05 *vpMenu_Data=NULL;
                        uint8_t *vpString="Please disable WAN DHCP.";
                        //uint8_t vpString[24]="Please disable WAN DHCP.";

                        vpMenu_Data = (template_05 *)malloc(sizeof(template_05));

                        if(NULL == vpMenu_Data)
                            return -1;
                        vpMenu_Data->type=OBJECT_TYPE_VARIABLE_STR;
                        vpMenu_Data->title_id=99;
                        vpMenu_Data->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
                        memset(vpMenu_Data->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
                        memcpy(vpMenu_Data->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

                        menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data);
                    }
                    else
                        menu_push(SCR_LINK_SETTING, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case HOME_USB_COPY:
                {
                    menu_push(SCR_USB_COPY, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case HOME_ADMIN_PASSWORD:
                {
                    menu_push(SCR_PASSWORD, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case HOME_LANGUAGE:
                {
                    menu_push(SCR_LANGUAGE, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case HOME_RESET_DEFAULT:
                {
                    menu_push(SCR_RESET_DEFAULT, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case HOME_ALARM_MUTE:
                {
                    menu_push(SCR_ALARM_MUTE, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
#ifdef STATUS_LED				
		   case HOME_STATUS_LED:
		   {
                    menu_push(SCR_STATUS_LED, SCR_TYPE_MENU_NORMAL, NULL);
		   }	
		   break;
#endif		   
                case HOME_EXIT:
                {
                    menu_push(SCR_EXIT_HOME, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
            }
        }
        break;
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        {
            sysinfo_update_all();
        }
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=vpMenu->sel_idx;

            show_screen(SCR_TEMPLATE_01, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t info_rotate_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_BTN_UP:
        {
            general_set_timer(TIMER_ID_MENU, 100, info_rotate_scr, vpMenu);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, SCREEN_SAVER_TIME_OUT, info_rotate_scr, vpMenu);

            if(ROTATE_INFO_SCR_STATE_ROTATE == _gSys_Info_Scr_State)
            {
                general_set_timer(TIMER_ID_MENU_SYSINFO, 0, NULL, NULL);
                _gSys_Info_Scr_State = ROTATE_INFO_SCR_STATE_STATIC;
            }
            else
                sysinfo_update_screen(-1);
        }
        break;
        case EVENT_BTN_DOWN:
        {
            if(ROTATE_INFO_SCR_STATE_ROTATE == _gSys_Info_Scr_State)
                menu_push(SCR_USB_COPY, SCR_TYPE_MENU_NORMAL, NULL);
            else
            {
                general_set_timer(TIMER_ID_MENU, 100, info_rotate_scr, vpMenu);
                general_set_timer(TIMER_ID_MENU_SCREENSAVER, SCREEN_SAVER_TIME_OUT, info_rotate_scr, vpMenu);
                sysinfo_update_screen(1);
            }
        }
        break;
        case EVENT_BTN_ENTER:
        {
            if(ROTATE_INFO_SCR_STATE_ROTATE == _gSys_Info_Scr_State)
            {
                if(_gTestMode)
                    menu_push(SCR_HOME, SCR_TYPE_MENU_NORMAL, NULL);
                else
                    menu_push(SCR_VERIFY, SCR_TYPE_MENU_NORMAL, NULL);
            }
        }
        break;
        case EVENT_BTN_ESC:
        {
            if(ROTATE_INFO_SCR_STATE_STATIC == _gSys_Info_Scr_State)
            {
                general_set_timer(TIMER_ID_MENU_SYSINFO, SYS_INFO_TIMEOUT, sysinfo_timeout_cb, vpMenu);
                general_set_timer(TIMER_ID_MENU_SCREENSAVER, SCREEN_SAVER_TIME_OUT, info_rotate_scr, vpMenu);
                general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
                _gSys_Info_Scr_State = ROTATE_INFO_SCR_STATE_ROTATE;
            }
        }
        break;
        case EVENT_OPERATION_TIMEOUT:
        {
            if(ROTATE_INFO_SCR_STATE_ROTATE == _gSys_Info_Scr_State)
            {
                general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
                menu_push(SCR_SCREEN_SAVER, SCR_TYPE_POWER_SAVE, NULL);
            }
            else
            {
                general_set_timer(TIMER_ID_MENU_SYSINFO, SYS_INFO_TIMEOUT, sysinfo_timeout_cb, vpMenu);
                general_set_timer(TIMER_ID_MENU_SCREENSAVER, SCREEN_SAVER_TIME_OUT, info_rotate_scr, vpMenu);
                general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
                _gSys_Info_Scr_State = ROTATE_INFO_SCR_STATE_ROTATE;
            }
        }
        break;
        case EVENT_OPERATION_LEAVE:
        case EVENT_OPERATION_EXIT:
        {
            _gSys_Info_Show_Idx=0;
            _gSys_Info_Raid_Idx=0;
            general_set_timer(TIMER_ID_MENU_SYSINFO, 0, NULL, NULL);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            if(MIN_PIC_VERSION > _gPicVersion && 0 == _gPic_Version_Flag)//luke modify 20100720:don't show warning message after agent3 boot up
            {
                menu_push(SCR_PIC_VERSION_WARNING, SCR_TYPE_MENU_NORMAL, NULL);
	    }else{
                sysinfo_update_all();
                _gSys_Info_Show_Idx=0;
                _gSys_Info_Raid_Idx=0;
                //_gPic_Version_Flag=0;
                _gPic_Version_Flag=1;//luke modify 20100720:don't show warning message after agent3 boot up
                _gSys_Info_Scr_State=ROTATE_INFO_SCR_STATE_ROTATE;
                general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
                general_set_timer(TIMER_ID_MENU_SCREENSAVER, SCREEN_SAVER_TIME_OUT, info_rotate_scr, vpMenu);
//              sysinfo_timeout_cb(EVENT_SYSINFO_INIT, vpMenu);
                sysinfo_update_screen(0);
                general_set_timer(TIMER_ID_MENU_SYSINFO, SYS_INFO_TIMEOUT, sysinfo_timeout_cb, vpMenu);
            }
        }
        break;

    }
    return 0;
}

static int32_t power_off_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
            uint8_t vPowerOff=vpMenu->value[0];

            if(vPowerOff)
                menu_pop(NULL);
            else
                menu_push(SCR_POWER_OFF_START, SCR_TYPE_WARNNING_MSG, NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=52;
            vMenu_Data[1]=6;
            vMenu_Data[2]=1;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t power_off_start_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_09 vMenu_Data={0};

            vMenu_Data.title_id=99;
            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.mid_id=52;
            show_screen(SCR_TEMPLATE_09, &vMenu_Data);
            system("/img/bin/sys_halt &");
        }
        break;
    }
    return 0;
}

static int32_t wan_setting_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ENTER:
        {
            switch(vpMenu->value[0])
            {
                case WAN_STATIC:
                {
                    menu_push(SCR_WAN_SET_IP, SCR_TYPE_MENU_NORMAL, NULL);
                }
                break;
                case WAN_DHCP:
                {
                    if ((_gSys_Info.link_mode == LINK_MODE_NONE) || (_gSys_Info.nic_1_dhcp_enable == TRUE))
                    {
                        menu_push(SCR_WAN_SUCCESS, SCR_TYPE_MENU_MSG, (void *)0);
                        sysinfo_set_nic1_dhcp(TRUE, TRUE);
                    }
                    else
                    {
                        template_05 *vpMenu_Data=NULL;
                        uint8_t *vpString="Link aggr. is enabled.";

                        vpMenu_Data = (template_05 *)malloc(sizeof(template_05));

                        if(NULL == vpMenu_Data)
                            return -1;
                        vpMenu_Data->type=OBJECT_TYPE_VARIABLE_STR;
                        vpMenu_Data->title_id=99;
                        vpMenu_Data->mid_str=(uint8_t *)malloc(sizeof(uint8_t)*(strlen(vpString)+1));
                        memset(vpMenu_Data->mid_str, 0, sizeof(uint8_t)*(strlen(vpString)+1));
                        memcpy(vpMenu_Data->mid_str, vpString, sizeof(uint8_t)*(strlen(vpString)+1));

                        menu_push(SCR_GENERAL_MENU_WARNING, SCR_TYPE_MENU_MSG, vpMenu_Data);
                    }
                }
                break;
            }
        }
        break;
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=86;
            vMenu_Data[1]=2;

            if(1 == _gSys_Info.nic_1_dhcp_enable && LINK_MODE_NONE == _gSys_Info.link_mode)
                vMenu_Data[2]=1;
            else
                vMenu_Data[2]=0;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t wan_set_ip_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_INPUT_COMPLETE:
        {
            uint8_t vIp[4]={0};

            debug_print(DEBUG_MODEL_MENU, "nic1 ip_%d.%d.%d.%d\n", vpMenu->value[0], vpMenu->value[1], vpMenu->value[2], vpMenu->value[3]);
            vIp[0]=vpMenu->value[0];
            vIp[1]=vpMenu->value[1];
            vIp[2]=vpMenu->value[2];
            vIp[3]=vpMenu->value[3];
            menu_push(SCR_WAN_SET_NETMASK, SCR_TYPE_MENU_NORMAL, NULL);
            sysinfo_set_nic1_ip(vIp);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};
            uint8_t vInt_Ip[4]={0};

            ip_strtoint(_gSys_Info.nic_1_ip, vInt_Ip);
            vMenu_Data[0]=86;
            vMenu_Data[1]=84;
            vMenu_Data[2]=INPUT_TYPE_IP;
            vMenu_Data[3]=vInt_Ip[0];
            vMenu_Data[4]=vInt_Ip[1];
            vMenu_Data[5]=vInt_Ip[2];
            vMenu_Data[6]=vInt_Ip[3];

            show_screen(SCR_TEMPLATE_04, vMenu_Data);
        }
    }
    return 0;
}

static int32_t wan_set_netmask_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_INPUT_COMPLETE:
        {
            uint8_t vNetmask[4]={0};

            debug_print(DEBUG_MODEL_MENU, "nic1 netmask_%d.%d.%d.%d\n", vpMenu->value[0], vpMenu->value[1], vpMenu->value[2], vpMenu->value[3]);
            menu_push(SCR_WAN_SUCCESS, SCR_TYPE_MENU_MSG, (void *)1);
            vNetmask[0]=vpMenu->value[0];
            vNetmask[1]=vpMenu->value[1];
            vNetmask[2]=vpMenu->value[2];
            vNetmask[3]=vpMenu->value[3];
            sysinfo_set_nic1_netmask(vNetmask);
            sysinfo_apply_nic1_to_system();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};
            uint8_t vInt_Netmask[4]={0};

            ip_strtoint(_gSys_Info.nic_1_netmask, vInt_Netmask);
            vMenu_Data[0]=86;
            vMenu_Data[1]=85;
            vMenu_Data[2]=INPUT_TYPE_IP;
            vMenu_Data[3]=vInt_Netmask[0];
            vMenu_Data[4]=vInt_Netmask[1];
            vMenu_Data[5]=vInt_Netmask[2];
            vMenu_Data[6]=vInt_Netmask[3];

            show_screen(SCR_TEMPLATE_04, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t wan_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_push(SCR_WAN_DISPLAY_IP, SCR_TYPE_MENU_MSG, vpMenu->pData);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=86;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, wan_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t wan_display_ip_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_STR;
            vMenu_Data.title_id=86;
            vMenu_Data.mid_str=_gSys_Info.nic_1_ip;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, wan_display_ip_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t lan_set_ip_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_INPUT_COMPLETE:
        {
            uint8_t vIp[4]={0};

            debug_print(DEBUG_MODEL_MENU, "nic2 ip_%d.%d.%d.%d\n", vpMenu->value[0], vpMenu->value[1], vpMenu->value[2], vpMenu->value[3]);
            vIp[0]=vpMenu->value[0];
            vIp[1]=vpMenu->value[1];
            vIp[2]=vpMenu->value[2];
            vIp[3]=vpMenu->value[3];
            menu_push(SCR_LAN_SET_NETMASK, SCR_TYPE_MENU_NORMAL, NULL);
            sysinfo_set_nic2_ip(vIp);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};
            uint8_t vInt_Ip[4]={0};

            ip_strtoint(_gSys_Info.nic_2_ip, vInt_Ip);
            vMenu_Data[0]=38;
            vMenu_Data[1]=36;
            vMenu_Data[2]=INPUT_TYPE_IP;
            vMenu_Data[3]=vInt_Ip[0];
            vMenu_Data[4]=vInt_Ip[1];
            vMenu_Data[5]=vInt_Ip[2];
            vMenu_Data[6]=vInt_Ip[3];

            show_screen(SCR_TEMPLATE_04, vMenu_Data);
        }
    }
    return 0;
}

static int32_t lan_set_netmask_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_INPUT_COMPLETE:
        {
            uint8_t vNetmask[4]={0};

            debug_print(DEBUG_MODEL_MENU, "nic2 netmask_%d.%d.%d.%d\n", vpMenu->value[0], vpMenu->value[1], vpMenu->value[2], vpMenu->value[3]);
            vNetmask[0]=vpMenu->value[0];
            vNetmask[1]=vpMenu->value[1];
            vNetmask[2]=vpMenu->value[2];
            vNetmask[3]=vpMenu->value[3];
            menu_push(SCR_LAN_SUCCESS, SCR_TYPE_MENU_MSG, NULL);
            sysinfo_set_nic2_netmask(vNetmask);
            sysinfo_apply_nic2_to_system();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};
            uint8_t vInt_Netmask[4]={0};

            ip_strtoint(_gSys_Info.nic_2_netmask, vInt_Netmask);
            vMenu_Data[0]=38;
            vMenu_Data[1]=37;
            vMenu_Data[2]=INPUT_TYPE_IP;
            vMenu_Data[3]=vInt_Netmask[0];
            vMenu_Data[4]=vInt_Netmask[1];
            vMenu_Data[5]=vInt_Netmask[2];
            vMenu_Data[6]=vInt_Netmask[3];

            show_screen(SCR_TEMPLATE_04, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t lan_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=38;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, lan_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t link_setting_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d",event);
    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
            if(1 == _gSys_Info.nic_1_dhcp_enable)
                return -1;

            if(0 == sysinfo_set_linkaggr(vpMenu->value[0], TRUE))
                menu_push(SCR_LINK_SUCCESS, SCR_TYPE_MENU_MSG, NULL);
            else
                menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=43;

            if(6 <= _gPicVersion)
                vMenu_Data[1]=10;
            else
                vMenu_Data[1]=5;

            if(TRUE == _gSys_Info.nic_1_dhcp_enable)
                vMenu_Data[2]=LINK_MODE_NONE;
            else
                vMenu_Data[2]=_gSys_Info.link_mode-LINK_MODE_8023AD;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t link_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=43;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, link_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t usb_copy_scr(uint32_t event, void *pMenu)
{
    IN(DEBUG_MODEL_MENU, "event %d",event);

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
            if(access("/var/lock/btn_copy.lock", F_OK) == -1)
                system("/img/bin/btn_copy &");
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_STR;
            vMenu_Data.title_id=81;
            vMenu_Data.mid_str="USB COPY?";

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t usb_copy_progress_scr(uint32_t event, void *pMenu)
{
    switch(event)
    {
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=81;
            vMenu_Data.mid_id=83;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
        }
    }
    return 0;
}

static int32_t usb_copy_finish_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=81;

            if(1 == (uint8_t)vpMenu->pData)
                vMenu_Data.mid_id=82;
            else
                vMenu_Data.mid_id=23;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, usb_copy_finish_scr, vpMenu);
        }
    }
    return 0;
}

static int32_t verify_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "%d,%d,%d,%d", vpMenu->value[0], vpMenu->value[1], vpMenu->value[2], vpMenu->value[3]);
    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_INPUT_COMPLETE:
        {
            uint8_t i;
            uint8_t vpRetVal[4+1]={0};
            int8_t vpPassword[8+1]={0};

            for(i = 0; i < 4; i++)
                vpRetVal[i] =  (vpMenu->value[i] <= 9) ? vpMenu->value[i] + '0' : '0';

            if( conf_db_select(KEY_PASSWORD, "conf", vpPassword) >= 0 )
            {
//                para_parser(vpPassword, NULL, strlen(vpPassword));
                debug_print(DEBUG_MODEL_MENU, "pass \"%s\"\n", vpPassword);
            }

            if(0 == strncmp(vpPassword, vpRetVal, 4))
            {
                menu_pop2(NULL, FALSE);
                menu_push(SCR_HOME, SCR_TYPE_MENU_NORMAL, NULL);
            }
            else
            {
                menu_pop2(NULL, FALSE);
                menu_push(SCR_VERIFY_FAIL, SCR_TYPE_MENU_MSG, NULL);
            }
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=20;
            vMenu_Data[1]=0;
            vMenu_Data[2]=INPUT_TYPE_PASSWORD;
            vMenu_Data[3]=8;

            show_screen(SCR_TEMPLATE_04, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t verify_fail_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d",event);
    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop2(NULL, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=20;
            vMenu_Data.mid_id=50;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, verify_fail_scr, vpMenu);
        }
        break;
    }
    return 0;
}
static int32_t password_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "%d,%d,%d,%d", vpMenu->value[0], vpMenu->value[1], vpMenu->value[2], vpMenu->value[3]);
    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_INPUT_COMPLETE:
        {
            uint8_t i;
            uint8_t vpRetVal[5]={0};

            for(i = 0; i < 4; i++)
                vpRetVal[i] =  (vpMenu->value[i] <= 9) ? vpMenu->value[i] + '0' : '0';

            debug_print(DEBUG_MODEL_MENU, "%d,%d,%d,%d\n", vpRetVal[0], vpRetVal[1], vpRetVal[2], vpRetVal[3]);
            menu_push(SCR_PASSWORD_SUCCESS, SCR_TYPE_MENU_MSG, NULL);
            sysinfo_set_lcm_password(vpRetVal);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=19;
            vMenu_Data[1]=0;
            vMenu_Data[2]=INPUT_TYPE_PASSWORD;
            vMenu_Data[3]=8;

            show_screen(SCR_TEMPLATE_04, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t password_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d",event);
    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=19;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, password_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t language_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
            uint8_t vLang=vpMenu->value[0] + 1;

            menu_push(SCR_LANGUAGE_SUCCESS, SCR_TYPE_MENU_MSG, NULL);
            sysinfo_set_language(vLang, 1);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=40;
            vMenu_Data[1]=9;
            vMenu_Data[2]=_gSys_Info.lang - 1;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t language_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d", event);
    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=39;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, language_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t reset_default_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
            if(0 == vpMenu->value[0])
            {
                menu_push(SCR_RESET_DEFAULT_SUCCESS, SCR_TYPE_MENU_MSG, NULL);
                system("/img/bin/resetDefault.sh &");
            }
            else
                menu_pop(NULL);

        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=77;
            vMenu_Data[1]=6;
            vMenu_Data[2]=1;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t reset_default_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=77;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, reset_default_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t alarm_mute_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
            uint8_t vAlarm=vpMenu->value[0];

            menu_push(SCR_ALARM_MUTE_SUCCESS, SCR_TYPE_MENU_MSG, NULL);

            if( vAlarm == 1 )
                sysinfo_set_alarm(1, 1);
            else
                sysinfo_set_alarm(0, 1);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            int8_t value[16+1] = {0};
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=1;
            vMenu_Data[1]=6;

            if( conf_db_select(KEY_BEEP, "conf", (int8_t *)value) >= 0 )
            {

                if( value[0] == '1' )
                    sysinfo_set_alarm(1, 0);
                else
                    sysinfo_set_alarm(0, 0);
            }

            if(1 == _gSys_Info.alarm_mute)
                vMenu_Data[2]=1;
            else
                vMenu_Data[2]=0;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t alarm_mute_success_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=1;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, alarm_mute_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t exit_home_scr(uint32_t event, void *pMenu)
{
    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
    }
    return 0;
}

static int32_t screen_saver_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    IN(DEBUG_MODEL_MENU, "event %d", event);


    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            menu_do_pop2(NULL, FALSE);
            stop_motion_screen(0);
            screen_state(SCREEN_POWER_ON);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
        }
        break;
        case EVENT_BTN_UP:
        case EVENT_BTN_DOWN:
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        {
            stop_motion_screen(0);
            screen_state(SCREEN_POWER_ON);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_TIMEOUT:
        {
            menu_do_pop2(NULL, FALSE);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            menu_push(SCR_OLED_OFF, SCR_TYPE_POWER_SAVE, NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            screen_state(SCREEN_SAVER);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, OLED_OFF_TIME_OUT, screen_saver_scr, vpMenu);
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
        }
        break;
    }
    return 0;
}

static int32_t screen_power_off_scr(uint32_t event, void *pMenu)
{
    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            menu_do_pop2(NULL, FALSE);
            screen_state(SCREEN_POWER_ON);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
        }
        break;
        case EVENT_BTN_UP:
        case EVENT_BTN_DOWN:
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        {
            screen_state(SCREEN_POWER_ON);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
            menu_pop(NULL);
        }
        break;
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            stop_motion_screen(0);
            screen_state(SCREEN_POWER_OFF);
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            general_set_timer(TIMER_ID_MENU_SCREENSAVER, 0, NULL, NULL);
        }
        break;
    }
    return 0;
}

static int32_t alert_scr(uint32_t event, void *pMenu)
{
    scr_data *vpMenu = pMenu;
    alert_data *vpAlert = NULL;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            if(_gCurrentState >= STATE_BOOT_OK)
            {
                if(0 == _gMenu_Init_Flag)
                {
                    alert_delete(vpMenu->pData);
                    menu_do_pop2(NULL, FALSE);
                    menu_start();
                }
                else
                {
                    menu_pop(NULL);
                }
            }
        }
        break;
        case EVENT_BTN_UP:
        {
            if(_gAlert_Show_Idx >= _gAlert_List->count - 1)
                return -1;
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            _gAlert_Show_Idx++;
            util_query_by_index(_gAlert_Show_Idx, (void **)&vpAlert, &_gAlert_List);
            update_alert_page(vpAlert);
        }
        break;
        case EVENT_BTN_DOWN:
        {
            if(0 == _gAlert_Show_Idx)
                return -1;
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            _gAlert_Show_Idx--;
            util_query_by_index(_gAlert_Show_Idx,  (void **)&vpAlert, &_gAlert_List);
            update_alert_page(vpAlert);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            update_alert_page((alert_data *)vpMenu->pData);
        }
        break;
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        case EVENT_OPERATION_EXIT:
        {
            if(_gCurrentState >= STATE_BOOTING)
                alert_delete(vpMenu->pData);
        }
        break;
    }
    return 0;
}

static int32_t warning_scr(uint32_t event, void *pMenu)
{
    scr_data *vpMenu = pMenu;
    template_09 *pSrc_Data=NULL;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    pSrc_Data = vpMenu->pData;

    if(NULL == pSrc_Data)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            if(_gCurrentState < STATE_BOOT_OK)
                menu_do_pop2(NULL, FALSE);
        }
        break;
        case EVENT_OPERATION_EXIT:
        {
            if(pSrc_Data->mid_str)
            {
                free(pSrc_Data->mid_str);
                pSrc_Data->mid_str=NULL;
            }

            if(pSrc_Data)
            {
                free(pSrc_Data);
                pSrc_Data=NULL;
            }
        }
        break;
        case EVENT_OPERATION_TIMEOUT:
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            show_screen(SCR_TEMPLATE_09, (void *)pSrc_Data);

            if(pSrc_Data->have_timeout)
                general_set_timer(TIMER_ID_MENU, 30, warning_scr, vpMenu);
            else
                general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
        }
        break;
    }
    return 0;
}

static int32_t pie_chart_scr(uint32_t event, void *pMenu)
{
    scr_data *vpMenu = pMenu;
    template_11 *pSrc_Data=NULL;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    if(NULL == vpMenu)
        return -1;

    pSrc_Data = vpMenu->pData;

    if(NULL == pSrc_Data)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            if(_gCurrentState < STATE_BOOT_OK)
                menu_do_pop2(NULL, FALSE);
        }
        break;
        case EVENT_OPERATION_EXIT:
        {
            if(pSrc_Data->mid_str)
            {
                free(pSrc_Data->mid_str);
                pSrc_Data->mid_str=NULL;
            }

            if(pSrc_Data)
            {
                free(pSrc_Data);
                pSrc_Data=NULL;
            }
        }
        break;
        case EVENT_OPERATION_TIMEOUT:
        case EVENT_BTN_ESC:
        {
            if(_gCurrentState >= STATE_BOOT_OK)
                menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            general_set_timer(TIMER_ID_MENU_POP_ROTATE, 0, NULL, NULL);
            show_screen(SCR_TEMPLATE_11, (void *)pSrc_Data);
        }
        break;
    }
    return 0;
}

static int32_t general_menu_warning_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;
    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_OPERATION_EXIT:
        {
            template_05 *vpMenu_Data=(template_05 *)vpMenu->pData;

            if(vpMenu_Data)
            {
                if(vpMenu_Data->mid_str)
                    free(vpMenu_Data->mid_str);
                free(vpMenu_Data);
            }
        }
        break;
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            template_05 *vpMenu_Data=(template_05 *)vpMenu->pData;

            if(vpMenu_Data)
            {
                if(vpMenu_Data->mid_str)
                    free(vpMenu_Data->mid_str);
                free(vpMenu_Data);
            }
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            show_screen(SCR_TEMPLATE_05, (template_05 *)(vpMenu->pData));
            general_set_timer(TIMER_ID_MENU, 30, general_menu_warning_scr, vpMenu);
        }
        break;
    }
    return 0;
}

static int32_t pic_version_warning_scr(uint32_t event, void *pMenu)
{
    scr_data * vpMenu=pMenu;

    IN(DEBUG_MODEL_MENU, "event %d", event);

    switch(event)
    {
        case EVENT_OPERATION_EXIT:
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            _gPic_Version_Flag=1;
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};
            vMenu_Data.type=OBJECT_TYPE_VARIABLE_STR;
            vMenu_Data.title_id=99;
            vMenu_Data.mid_str="New OLED ver. available";

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, general_menu_warning_scr, vpMenu);
        }
        break;
    }
    return 0;
}

#ifdef STATUS_LED
static int32_t status_led_scr(uint32_t event, void *pMenu)
{
    IN(DEBUG_MODEL_MENU, "event %d", event);
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_BTN_ENTER:
        {
	      uint8_t vLED=vpMenu->value[0];

	      if( vLED == 0 ) //disable Status LED
	      {
	     	    menu_push(SCR_STATUS_LED_SUCCESS, SCR_TYPE_MENU_MSG, NULL); 
                 sysinfo_set_statusLED(1, 0);	  

		}else
		    menu_pop(NULL);
            
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            uint8_t vMenu_Data[32]={0};

            vMenu_Data[0]=111;
            vMenu_Data[1]=6;
            vMenu_Data[2]=1;

            show_screen(SCR_TEMPLATE_02, vMenu_Data);
        }
        break;
    }
    return 0;
}

static int32_t status_led_success_scr(uint32_t event, void *pMenu)
{
    IN(DEBUG_MODEL_MENU, "event %d", event);
    scr_data * vpMenu=pMenu;

    if(NULL == vpMenu)
        return -1;

    switch(event)
    {
        case EVENT_OPERATION_EXIT_BY_INTERRUPT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_do_pop_to_level(2, FALSE);
        }
        break;
        case EVENT_BTN_ENTER:
        case EVENT_BTN_ESC:
        case EVENT_OPERATION_TIMEOUT:
        {
            general_set_timer(TIMER_ID_MENU, 0, NULL, NULL);
            menu_pop_to_home();
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            template_05 vMenu_Data={0};

            vMenu_Data.type=OBJECT_TYPE_VARIABLE_ID;
            vMenu_Data.title_id=111;
            vMenu_Data.mid_id=75;

            show_screen(SCR_TEMPLATE_05, &vMenu_Data);
            general_set_timer(TIMER_ID_MENU, 30, status_led_success_scr, vpMenu);
        }
        break;
    }
    return 0;
}
#endif


#if 0
static int32_t underconstructure_scr(uint32_t event, void *pMenu)
{
    IN(DEBUG_MODEL_MENU, "", "");
    switch(event)
    {
        case EVENT_BTN_ESC:
        {
            menu_pop(NULL);
        }
        break;
        case EVENT_OPERATION_ENTER:
        case EVENT_OPERATION_BACK:
        {
            show_page(1);
        }
        break;
        case EVENT_OPERATION_EXIT:
        {
        }
        break;
    }
    return 0;
}

static int32_t show_page(uint8_t page_id)
{
    uint8_t data[32]={0};

    data[0]=page_id;
    i2c_write_block(1, 1, data);
    return 0;
}
#endif

static int32_t update_alert_page(alert_data *pAlert)
{
    alert_data *vpAlert = pAlert;
    template_06 *vpMenu_Data=NULL;
    uint8_t vButtom_Str[32]={0};

    if(NULL == vpAlert)
        return -1;

    vpMenu_Data = (template_06 *)malloc(sizeof(template_06));

    if(NULL == vpMenu_Data)
        return -1;

    sprintf(vButtom_Str, "%s [%d/%ld]", vpAlert->time, _gAlert_Show_Idx+1, _gAlert_List->count);
    vpMenu_Data->bottom_str=(uint8_t *)malloc(strlen(vButtom_Str) +1);
    memset(vpMenu_Data->bottom_str, 0, strlen(vButtom_Str) +1);
    memcpy(vpMenu_Data->bottom_str, vButtom_Str, strlen(vButtom_Str));
    debug_print(DEBUG_MODEL_MENU, "%s \n", vpMenu_Data->bottom_str);

    switch(vpAlert->type)
    {
        case ALERT_AC_POWER_LOST:
        {
            vpMenu_Data->title_id=92;
            vpMenu_Data->mid_str=NULL;
            vpMenu_Data->mid_id=93;
        }
        break;
        case ALERT_AC_POWER_RECORVER:
        {
            vpMenu_Data->title_id=92;
            vpMenu_Data->mid_str=NULL;
            vpMenu_Data->mid_id=94;
        }
        break;
        default:
            return -1;
    }

#if 1
    menu_show_screen_t vMenuShowScreen={0};

    vMenuShowScreen.action=MENU_QUEUE_SHOW_SCREEN;
    vMenuShowScreen.scr_Id=SCR_TEMPLATE_06;
    vMenuShowScreen.pScr_Data=(void *)vpMenu_Data;

    menu_queue_add((menu_queue *)&vMenuShowScreen);
#else
    show_screen(SCR_TEMPLATE_06, &vMenu_Data);
#endif
    return 0;
}
