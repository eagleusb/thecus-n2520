
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include "memory.h"
#include "utility.h"
#include "i2c.h"
#include "cmd.h"
#include "menu.h"
#include "timer.h"
#include "sysinfo.h"

static uint32_t             _gTimerCount[TIMER_ID_MAX]={0};
static TimeOutCBFuncPtr_t   _gTimeOutCB[TIMER_ID_MAX]={NULL};
static void                 *_gpTimeOutData[TIMER_ID_MAX]={NULL};

void general_set_timer(uint8_t timer_id, uint32_t timeout, TimeOutCBFuncPtr_t cb, void * pData)
{
    IN(DEBUG_MODEL_MISC, "set_timer %d, timeout %d", timer_id, timeout);
    _gTimerCount[timer_id]=timeout;
    _gTimeOutCB[timer_id]=cb;
    _gpTimeOutData[timer_id]=pData;
}

static void timer_handler(int32_t signum)
{
    uint8_t i=0;
    TimeOutCBFuncPtr_t _vTimeOutCB = NULL;
    void *vpData = NULL;

    if(INTERRUPT_IS_BLOCK)
        return;

    poll_cmd_handler();

    for(i = 0; i < TIMER_ID_MAX; i++)
    {
        if(NULL != _gTimeOutCB[i] && 0 == --_gTimerCount[i])
        {
            debug_print(DEBUG_MODEL_MISC, "%d Timeout\n", i);
            _vTimeOutCB = _gTimeOutCB[i];
            vpData = _gpTimeOutData[i];
            _gTimeOutCB[i]=NULL;
            _gpTimeOutData[i]=NULL;
            menu_timeout(EVENT_OPERATION_TIMEOUT, _vTimeOutCB, vpData);
        }
    }

//    raise(SIG_PROC_CMD);
}

void *timer_main(void *ptr)
{
    struct itimerval t;
    IN(DEBUG_MODEL_MISC, "", "");
#if 1
    t.it_interval.tv_usec = 100000;
    t.it_interval.tv_sec = 0;
    t.it_value.tv_usec = 100000;
    t.it_value.tv_sec = 0;
#else
    t.it_interval.tv_usec = 0;
    t.it_interval.tv_sec = 1;
    t.it_value.tv_usec = 0;
    t.it_value.tv_sec = 1;
#endif
    if(_gTestMode)
        menu_start();

    if( setitimer( ITIMER_REAL, &t, NULL) < 0 )
    {
        debug_print(DEBUG_MODEL_MISC, "settimer error.\n");
        return (void *)-1;
    }
    signal( SIGALRM, timer_handler );

    while(1){
        pause();
    }

    return (void *)0;
}

