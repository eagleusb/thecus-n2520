
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "utility.h"
#include "i2c.h"
#include "cmd.h"
#include "timer.h"
#include "menu.h"
#include "scr_template.h"

extern uint8_t _gPicVersion;

uint8_t _gPanel_state=SCREEN_POWER_OFF;

int32_t show_screen(uint8_t Scr_Id, void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    IN(DEBUG_MODEL_MENU, "scr_id %d", Scr_Id);

    switch(Scr_Id)
    {
        case SCR_TEMPLATE_01:
        {
            update_screen_01(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_02:
        {
            update_screen_02(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_03:
        {
            update_screen_03(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_04:
        {
            update_screen_04(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_05:
        {
            update_screen_05(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_06:
        {
            update_screen_06(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_07:
        {
            update_screen_07(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_08:
        {
            update_screen_08(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_09:
        {
            update_screen_09(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_10:
        {
            update_screen_10(pScr_Data);
        }
        break;
        case SCR_TEMPLATE_11:
        {
            update_screen_11(pScr_Data);
        }
        break;
        default:
        break;
    }

    vI2C_Data[0]=OBJECT_ACTION_SHOW;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=Scr_Id;

    screen_state(SCREEN_POWER_ON);
    usleep(50000);
    i2c_write_block(CMD_OBJECT_CONTROL, 3, vI2C_Data);
    
    return 0;
}

int32_t update_screen_01(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t *vpData=pScr_Data;

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_01;
    vI2C_Data[3]=OBJECT_TYPE_INPUT;
    vI2C_Data[4]=0;
    vI2C_Data[5]=vpData[0]; //default value
    vI2C_Data[6]=OBJECT_TYPE_INPUT;
    vI2C_Data[7]=1;
    vI2C_Data[8]=vpData[0]; //default value

    i2c_write_block(CMD_OBJECT_CONTROL, 9, vI2C_Data);

    return 0;
}

int32_t update_screen_02(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t *vpData=pScr_Data;

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_02;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData[0];
    vI2C_Data[5]=OBJECT_TYPE_INPUT;
    vI2C_Data[6]=vpData[1];
    vI2C_Data[7]=vpData[2]; //default value

    i2c_write_block(CMD_OBJECT_CONTROL, 8, vI2C_Data);

    return 0;
}

int32_t update_screen_03(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t *vpData=pScr_Data;

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_03;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData[0];
    vI2C_Data[5]=OBJECT_TYPE_INPUT;
    vI2C_Data[6]=vpData[1];         //id
    vI2C_Data[7]=vpData[2];         //default value
    vI2C_Data[8]=OBJECT_TYPE_VARIABLE_IP;
    vI2C_Data[9]=vpData[3];
    vI2C_Data[10]=vpData[4];
    vI2C_Data[11]=vpData[5];
    vI2C_Data[12]=vpData[6];
    vI2C_Data[13]=OBJECT_TYPE_VARIABLE_IP;
    vI2C_Data[14]=vpData[7];
    vI2C_Data[15]=vpData[8];
    vI2C_Data[16]=vpData[9];
    vI2C_Data[17]=vpData[10];

    i2c_write_block(CMD_OBJECT_CONTROL, 18, vI2C_Data);

    return 0;
}

int32_t update_screen_04(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t *vpData=pScr_Data;
    uint8_t vStrLen=0;

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_04;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData[0];
    vI2C_Data[5]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[6]=vpData[1];
    vI2C_Data[7]=OBJECT_TYPE_INPUT;
    vI2C_Data[8]=vpData[2];

    if(INPUT_TYPE_IP == vpData[2])
    {
        vI2C_Data[9]=vpData[3];
        vI2C_Data[10]=vpData[4];
        vI2C_Data[11]=vpData[5];
        vI2C_Data[12]=vpData[6];
        vStrLen=13;
    }
    else
    {
        vI2C_Data[9]=vpData[3];
        vStrLen=10;
    }

    i2c_write_block(CMD_OBJECT_CONTROL, vStrLen, vI2C_Data);

    return 0;
}

int32_t update_screen_05(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    template_05 *vpData=pScr_Data;
    uint8_t *vpStr=NULL;
    uint8_t vStrLen=0,vi=0,vTemplate_Max_Size=0;
		
    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_05;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData->title_id;
    vTemplate_Max_Size = I2C_SMBUS_BLOCK_MAX - TEMPLATE_05_HEADER_SIZE;    

    if(OBJECT_TYPE_VARIABLE_ID == vpData->type)
    {
        vI2C_Data[5]=OBJECT_TYPE_VARIABLE_ID;
        vI2C_Data[6]=vpData->mid_id;
        vStrLen=7;
    }
    else
    {
        vI2C_Data[5]=OBJECT_TYPE_VARIABLE_STR;

        if(vpData->mid_str)
        {
	    vStrLen = strlen(vpData->mid_str);        		
	    IN(DEBUG_MODEL_MENU, "StrLen is %d", vStrLen);            

 	    if(vStrLen <= vTemplate_Max_Size)
	    { 
		vI2C_Data[6]=vStrLen;
                vpStr=&vI2C_Data[7];            
	    	sprintf(vpStr, "%s", vpData->mid_str);        		        		
		vStrLen += TEMPLATE_05_HEADER_SIZE;
	    }else
	    {        			  
		for(vi=0; vi<vTemplate_Max_Size; vi++)        			  	
	    	    vI2C_Data[vi+TEMPLATE_05_HEADER_SIZE]=vpData->mid_str[vi];   
						
		vI2C_Data[6]=vTemplate_Max_Size;	    
		vStrLen=I2C_SMBUS_BLOCK_MAX;  			  	            
	    }                                   
	    IN(DEBUG_MODEL_MENU, "vStrLen is %d", vI2C_Data[6]);            
   	    IN(DEBUG_MODEL_MENU, "vI2C_Data[7] is %s", &vI2C_Data[7]);            
        }
        else
        {
            vI2C_Data[6]=0;
            vpStr=&vI2C_Data[7];
        }
         
    }
    i2c_write_block(CMD_OBJECT_CONTROL, vStrLen, vI2C_Data);
    return 0;
}

int32_t update_screen_06(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vI2C_Data2[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vCmd_Len=0;
    uint8_t *vpStr=NULL;
    uint8_t *vpStr2=NULL;
    template_06 *vpData=pScr_Data;

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_06;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData->title_id;
    vI2C_Data[5]=OBJECT_TYPE_VARIABLE_STR;

    if(vpData->mid_str)
    {
        vI2C_Data[6]=strlen(vpData->mid_str);
        vpStr=&vI2C_Data[7];
        sprintf(vpStr, "%s", vpData->mid_str);
        vpStr=vpStr+strlen(vpData->mid_str);
    }
    else
    {
        vI2C_Data[6]=0;
        vpStr=&vI2C_Data[7];
    }
    vpStr[0]=OBJECT_TYPE_VARIABLE_ID;
    vpStr[1]=vpData->mid_id;
    vpStr[2]=OBJECT_TYPE_VARIABLE_STR;
    vpStr[3]=0;
    vpStr=&vpStr[4];
    i2c_write_block(CMD_OBJECT_CONTROL, vpStr - &vI2C_Data[0], vI2C_Data);

    if(vpData->bottom_str)
    {
        memset(vI2C_Data2, 0, sizeof(vI2C_Data2));

        vI2C_Data2[0]=OBJECT_ACTION_UPDATE;
        vI2C_Data2[1]=OBJECT_TYPE_VARIABLE_STR;
        vI2C_Data2[2]=16;
        vI2C_Data2[3]=strlen(vpData->bottom_str);
        vpStr2=&vI2C_Data2[4];
        sprintf(vpStr2, "%s", vpData->bottom_str);
        vpStr2=vpStr2+strlen(vpData->bottom_str);

        i2c_write_block(CMD_OBJECT_CONTROL, vpStr2 - &vI2C_Data2[0], vI2C_Data2);
    }


    return 0;
}

int32_t update_screen_07(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    template_07 *vpData=pScr_Data;
    uint8_t *vpStr=NULL;

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_07;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData->title_id;
    vI2C_Data[5]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[6]=vpData->mid_bmp_id;
    vI2C_Data[7]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[8]=vpData->mid_str_id;
    vI2C_Data[9]=OBJECT_TYPE_VARIABLE_STR;

    if(vpData->bottom_str)
    {
        vI2C_Data[10]=strlen(vpData->bottom_str);
        vpStr=&vI2C_Data[11];
        sprintf(vpStr, "%s", vpData->bottom_str);
        vpStr=vpStr+strlen(vpData->bottom_str);
    }
    else
    {
        vI2C_Data[10]=0;
        vpStr=&vI2C_Data[11];
    }

    i2c_write_block(CMD_OBJECT_CONTROL, vpStr - &vI2C_Data[0], vI2C_Data);

    return 0;
}

int32_t update_screen_08(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vI2C_Data2[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vI2C_Data3[I2C_SMBUS_BLOCK_MAX]={0x02,0x00,0x08,0x0a,0x63,0x0a,0x00,0x06,0x00,0x09,0x00,0x0a,0x00,0x06,0x00,0x09,0x00,0x0d,0x00};
    uint8_t vIdx=0;
    template_08 *vpData=pScr_Data;
    uint8_t *vpStr=NULL;
    uint8_t *vpStr2=NULL;
    IN(DEBUG_MODEL_MENU, "");

    if(NULL == vpData)
        return -1;

    vI2C_Data[vIdx++]=OBJECT_ACTION_UPDATE;
    vI2C_Data[vIdx++]=OBJECT_TYPE_PAGE;
    vI2C_Data[vIdx++]=SCR_TEMPLATE_08;
    vI2C_Data[vIdx++]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[vIdx++]=vpData->title_id;

    vI2C_Data[vIdx++]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[vIdx++]=vpData->mid_id;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
    if(6 <= _gPicVersion)
    {
        vI2C_Data[vIdx++]=OBJECT_TYPE_BMP;
        vI2C_Data[vIdx++]=vpData->mid_bmp;
    }
#endif  // __WISH_LIST_ROTATE_NEW_INFO__

    vI2C_Data[vIdx++]=OBJECT_TYPE_VARIABLE_STR;

    if(vpData->mid_str)
    {
        vI2C_Data[vIdx++]=strlen(vpData->mid_str);
        vpStr=&vI2C_Data[vIdx];
        sprintf(vpStr, "%s", vpData->mid_str);
        vpStr=vpStr+strlen(vpData->mid_str);
    }
    else
    {
        vI2C_Data[vIdx++]=0;
        vpStr=&vI2C_Data[vIdx];
    }

    vIdx=0;
    vpStr[vIdx++]=OBJECT_TYPE_VARIABLE_ID;
    vpStr[vIdx++]=vpData->bottom_id;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
    if(6 <= _gPicVersion)
    {
        vpStr[vIdx++]=OBJECT_TYPE_BMP;
        vpStr[vIdx++]=vpData->bottom_bmp;
    }
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
    vpStr[vIdx++]=OBJECT_TYPE_VARIABLE_STR;

    if(vpData->bottom_str)
    {
        i2c_write_block(CMD_OBJECT_CONTROL, 19, vI2C_Data3);
        debug_print(DEBUG_MODEL_MENU, "bottom_str %d\n", strlen(vpData->bottom_str));
        if((&vpStr[vIdx] - &vI2C_Data[0] + strlen(vpData->bottom_str)) < 30)
        {
            vpStr[vIdx++]=strlen(vpData->bottom_str);
            vpStr=&vpStr[vIdx];
            sprintf(vpStr, "%s", vpData->bottom_str);
            vpStr=vpStr+strlen(vpData->bottom_str);
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
            if(6 <= _gPicVersion)
            {
                vIdx=0;
                vpStr[vIdx++]=OBJECT_TYPE_CAPACITY;
                vpStr[vIdx++]=vpData->usage;
                i2c_write_block(CMD_OBJECT_CONTROL, &vpStr[vIdx] - &vI2C_Data[0], vI2C_Data);
            }
            else
                i2c_write_block(CMD_OBJECT_CONTROL, vpStr - &vI2C_Data[0], vI2C_Data);
#else
            i2c_write_block(CMD_OBJECT_CONTROL, vpStr - &vI2C_Data[0], vI2C_Data);
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
        }
        else
        {
            vpStr[vIdx++]=0;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
            if(6 <= _gPicVersion)
            {
                vpStr[vIdx++]=OBJECT_TYPE_CAPACITY;
                vpStr[vIdx++]=vpData->usage;
            }
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
            i2c_write_block(CMD_OBJECT_CONTROL, &vpStr[vIdx] - &vI2C_Data[0], vI2C_Data);

            memset(vI2C_Data2, 0, sizeof(vI2C_Data2));

            vIdx=0;
            vI2C_Data2[vIdx++]=OBJECT_ACTION_UPDATE;
            vI2C_Data2[vIdx++]=OBJECT_TYPE_VARIABLE_STR;
            vI2C_Data2[vIdx++]=22;
            vI2C_Data2[vIdx++]=strlen(vpData->bottom_str);
            vpStr2=&vI2C_Data2[vIdx];
            sprintf(vpStr2, "%s", vpData->bottom_str);
            vpStr2=vpStr2+strlen(vpData->bottom_str);
            i2c_write_block(CMD_OBJECT_CONTROL, vpStr2 - &vI2C_Data2[0], vI2C_Data2);


            return 0;
        }
    }
    else
    {
        vpStr[vIdx++]=0;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
        if(6 <= _gPicVersion)
        {
            vpStr[vIdx++]=OBJECT_TYPE_CAPACITY;
            vpStr[vIdx++]=vpData->usage;
        }
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
        vpStr=&vpStr[vIdx];
        i2c_write_block(CMD_OBJECT_CONTROL, vpStr - &vI2C_Data[0], vI2C_Data);
    }
    return 0;
}

int32_t update_screen_09(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    template_09 *vpData=pScr_Data;
    uint8_t *vpStr=NULL;
    uint8_t vStrLen=0;
    IN(DEBUG_MODEL_MENU, "");

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_09;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData->title_id;

    if(OBJECT_TYPE_VARIABLE_ID == vpData->type)
    {
        vI2C_Data[5]=OBJECT_TYPE_VARIABLE_ID;
        vI2C_Data[6]=vpData->mid_id;
        vStrLen=7;
    }
    else
    {
        vI2C_Data[5]=OBJECT_TYPE_VARIABLE_STR;
        vI2C_Data[6]=strlen(vpData->mid_str);
        vpStr=&vI2C_Data[7];
        sprintf(vpStr, "%s", vpData->mid_str);
        vpStr=vpStr+strlen(vpData->mid_str);
        vStrLen=vpStr - &vI2C_Data[0];
    }

    i2c_write_block(CMD_OBJECT_CONTROL, vStrLen, vI2C_Data);

    return 0;
}

int32_t update_screen_10(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t *vpData=pScr_Data;
    uint8_t vIdx=0;

    if(NULL == vpData)
        return -1;

    vI2C_Data[vIdx++]=OBJECT_ACTION_UPDATE;
    vI2C_Data[vIdx++]=OBJECT_TYPE_PAGE;
    vI2C_Data[vIdx++]=SCR_TEMPLATE_10;
    vI2C_Data[vIdx++]=OBJECT_TYPE_BMP;
    vI2C_Data[vIdx++]=vpData[0];

    i2c_write_block(CMD_OBJECT_CONTROL, vIdx, vI2C_Data);

    return 0;
}

int32_t update_screen_11(void *pScr_Data)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    template_11 *vpData=pScr_Data;
    uint8_t *vpStr=NULL;
    uint8_t vStrLen=0;
    IN(DEBUG_MODEL_MENU, "");

    if(NULL == vpData)
        return -1;

    vI2C_Data[0]=OBJECT_ACTION_UPDATE;
    vI2C_Data[1]=OBJECT_TYPE_PAGE;
    vI2C_Data[2]=SCR_TEMPLATE_11;
    vI2C_Data[3]=OBJECT_TYPE_VARIABLE_ID;
    vI2C_Data[4]=vpData->title_id;

    if(OBJECT_TYPE_VARIABLE_ID == vpData->type)
    {
        vI2C_Data[5]=OBJECT_TYPE_VARIABLE_ID;
        vI2C_Data[6]=vpData->mid_id;
        vI2C_Data[7]=OBJECT_TYPE_VARIABLE_PROCESS;
        vI2C_Data[8]=vpData->process;
        vI2C_Data[9]=vpData->color;
        vStrLen=10;
    }
    else
    {
        vI2C_Data[5]=OBJECT_TYPE_VARIABLE_STR;
        vI2C_Data[6]=strlen(vpData->mid_str);
        vpStr=&vI2C_Data[7];
        sprintf(vpStr, "%s", vpData->mid_str);
        vpStr=vpStr+strlen(vpData->mid_str);
        vpStr[1]=OBJECT_TYPE_VARIABLE_PROCESS;
        vpStr[2]=vpData->process;
        vpStr[3]=vpData->color;
        vStrLen=&vpStr[4] - &vI2C_Data[0];
    }

    i2c_write_block(CMD_OBJECT_CONTROL, vStrLen, vI2C_Data);

    return 0;
}

int32_t screen_state(uint8_t state)
{
    uint8_t vData[2]={0};
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vRetryCount=0;

    if(_gPanel_state == state)
        return 0;
    _gPanel_state=state;

    if(0 <= state && 2 >= state)
        vData[0] = state;
    else
        vData[0] = 1;
    i2c_write_block(CMD_OLED_DISPLAY, 1, vData);

    do
    {
        if(vRetryCount != 0)
            debug_print(DEBUG_MODEL_MENU, "set state %d, get state %d\n", state, vI2C_Data[0]);
        usleep(200000);
    }while(vRetryCount++ < 10 && (-1 != i2c_read_block(CMD_OLED_DISPLAY, (uint8_t *)vI2C_Data) && vI2C_Data[0] != state));

    return 0;
}

int32_t stop_motion_screen(uint8_t screen_id)
{
    uint8_t vData[3]={0};

    vData[0] = 5;
    vData[1] = screen_id;

    i2c_write_block(CMD_OBJECT_CONTROL, 2, vData);

    return 0;
}
