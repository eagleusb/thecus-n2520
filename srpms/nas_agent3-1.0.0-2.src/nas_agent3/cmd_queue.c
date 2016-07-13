
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/time.h>
#include "utility.h"
#include "memory.h"
#include "cmd.h"
#include "cmd_queue.h"

extern util_list_head *_gCmd_Queue;

extern sigset_t _gSigMask;


int32_t cmd_queue_add(uint8_t in_out, void *pData)
{
    queue_cmd *vCmd=NULL;

    if( NULL == _gCmd_Queue )
        _gCmd_Queue = util_list_init();

    vCmd= (queue_cmd*) malloc(sizeof(queue_cmd));  /* create a new command */
    memset(vCmd, 0, sizeof(queue_cmd));

    if( NULL == _gCmd_Queue || NULL == vCmd )
        return -1;

    vCmd->in_out=in_out;
    vCmd->pData=pData;
    return util_add_to_end((void *)vCmd, &_gCmd_Queue);
}

int32_t cmd_queue_get(uint8_t *pin_out, void **ppData)
{
    int32_t vRet=0;
    queue_cmd *vCmd=NULL;

    if( NULL == pin_out || NULL == ppData)
        return -1;

    if( NULL == _gCmd_Queue )
        return -1;

    if((vRet = util_get_from_start((void **)&vCmd, &_gCmd_Queue)) != 0)
        return vRet;

    if(vCmd)
    {
        *pin_out=vCmd->in_out;
        *ppData=vCmd->pData;
        free(vCmd);
        vCmd=NULL;
    }
    
    return 0;
}

int32_t cmd_queue_release(void)
{
    int32_t vRet=0;
    queue_cmd *vCmd=NULL;

    if( NULL == _gCmd_Queue )
        return -1;

    while(_gCmd_Queue->count > 0)
    {
        util_get_from_start((void **)&vCmd, &_gCmd_Queue);

        if(vCmd)
        {
            if(vCmd->pData)
            {
                free(vCmd->pData);
                vCmd->pData=NULL;
            }
            free(vCmd);
            vCmd=NULL;
        }
    }

    if( NULL != _gCmd_Queue )
    {
        util_list_release(_gCmd_Queue);
        _gCmd_Queue=NULL;
    }

    return 0;
}

void cmd_queue_handler(int32_t signum)
{
    uint8_t vIn_Out=0;
    uint8_t vCmd=0;
    uint8_t vAction=0;
    i2c_cmd *vI2C_Cmd=NULL;
    
    sigaddset(&_gSigMask,SIG_PROC_CMD);
    sigprocmask(SIG_BLOCK,&_gSigMask,NULL);
    cmd_queue_get(&vIn_Out, (void **)&vI2C_Cmd);

    vCmd=vI2C_Cmd->cmd;
    vAction=vI2C_Cmd->action;
    debug_print(DEBUG_MODEL_CMD, "in_out %d, id %d, action %d\n", vIn_Out, vI2C_Cmd->cmd, vI2C_Cmd->action);

    free(vI2C_Cmd);
    vI2C_Cmd=NULL;
    sigprocmask(SIG_UNBLOCK,&_gSigMask,NULL);

}


