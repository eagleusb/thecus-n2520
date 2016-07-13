/* 
 * File:   timer.h
 * Author: dorianko
 *
 * Created on 2009年10月6日, 下午 2:13
 */

#ifndef _TIMER_H
#define	_TIMER_H

#ifdef	__cplusplus
extern "C" {
#endif

    typedef int32_t (*TimeOutCBFuncPtr_t)(uint32_t event, void *pData);

    enum
    {
        TIMER_ID_MENU,
        TIMER_ID_MENU_POP_ROTATE,
        TIMER_ID_MENU_SYSINFO,
        TIMER_ID_MENU_SCREENSAVER,
        TIMER_ID_MENU_MAX, 
        TIMER_ID_MAX=TIMER_ID_MENU_MAX,
    };

    void *timer_main(void *ptr);
    void general_set_timer(uint8_t timer_id, uint32_t timeout, TimeOutCBFuncPtr_t cb, void * pData);

#ifdef	__cplusplus
}
#endif

#endif	/* _TIMER_H */

