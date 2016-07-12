
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <time.h>
#include "utility.h"
#include "memory.h"
#include "cmd.h"
#include "cmd_queue.h"
#include "i2c.h"
#include "timer.h"
#include "menu.h"
#include "stringtable.h"
#include "scr_template.h"
#include "sysinfo.h"

#define PIPE_DIR    "/var/tmp/oled"
#define PIPE        "/var/tmp/oled/pipecmd"
#define PIC_UPGRADE_FLAG "/var/tmp/oled/pic_upgrade"
#define FIFO_MODE       (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
#define PIPE_BUFFER_SIZE 256
#ifdef STATUS_LED
#define STATUS_LED_FILE "/var/tmp/oled/STATUS_LED"
#endif
#ifdef PUBLIC_GPIO
#define GPIO_DIR    "/var/tmp/gpio"
#define GPIO_FILE  "/var/tmp/gpio/gpio"
#endif
#define Flag_RC_NET "/img/bin/rc/rc.net"

static int32_t upgrade_pic(int8_t *pSleep, int8_t *pIn_argv);
static int32_t set_pic_bootloader(void);

extern uint8_t *_gpVersion;
extern uint8_t _gPicVersion;
extern uint8_t _gNewLANCheck;
//uint8_t _gPoll_Flag=0;
uint8_t _gUpgrade_Flag=0;
util_list_head *_gCmd_Queue=NULL;
uint32_t _gKeyPressCount[4]={0};
uint32_t _gKeyPress[4]={0};
FILE *_gPipe_fp = NULL;
#ifdef STATUS_LED
uint8_t _gStatusLEDFlag;
#endif

cmd_table _gHost_Cmd_Table[]=
{
    {CMD_SETBTO             , "SETBTO"},
    {CMD_BTMSG              , "BTMSG"},
    {CMD_STARTWD            , "STARTWD"},
    {CMD_GETAVRVN           , "GETAVRVN"},
    {CMD_USB_COPY           , "USBCP"},
    {CMD_USB_COPY           , "usbcp"},
    {CMD_SYS_UPGRADE        , "Upgrade"},
    {CMD_SYS_UPGRADE        , "UPGRADE"},
    {CMD_POWER_ON_OFF_ERROR , "BOOT_ERROR"},
//    {CMD_LED                , "LED"},
    {CMD_OLED_DISPLAY       , "OLED"},
    {CMD_POWER_STATUS       , "POWER_STATUS"},
//    {CMD_FACTORY            , "FACTORY"},
    {CMD_BOOT_LOADER        , "BOOT_LOADER"},
    {CMD_DUAL_DOM           , "DUAL_DOM"},
    {CMD_BUTTON_OPERATION   , "BUTTON"},
    {CMD_OBJECT_CONTROL     , "OBJECT"},
//    {CMD_OBJECT_SELECT      , "OBJECT_SELECT"},
//    {CMD_SCREEN_SAVER       , "SCREEN_SAVER"},
    {CMD_AC_POWER           , "ACPWR"},
    {CMD_POWER_OFF          , "POWER_OFF"},
    {CMD_DEBUG_ENABLE       , "DEBUG_ENABLE"},
    {CMD_DEBUG_MASK         , "DEBUG_MASK"},
    {CMD_UPGRADE_PIC        , "UPGRADE_PIC"},
    {CMD_RESET_PIC          , "RESET_PIC"},
    {CMD_UPGRADE_PIC_START  , "UPGRADE_PIC_START"},
    {CMD_UPGRADE_PIC_END    , "UPGRADE_PIC_END"},
#ifdef STATUS_LED
    {CMD_SLED    , "SLED"},
#endif
#ifdef PUBLIC_GPIO   
    {CMD_PUBLIC_GPIO    ,"GPIO"},
#endif    
    {-1, ""},
};

#ifdef STATUS_LED
uint32_t LED_init(void)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    //uint8_t vRetry_Count=0;
    uint8_t vCmd[64]={0};
    int32_t vRet=0;
    char value[PIPE_CMD_BUF] = {0};
    char vPipeCmd[PIPE_CMD_BUF]={0};
    char *vCheckServiceCmd="/img/bin/check_service.sh %s";	
    sprintf(vPipeCmd, vCheckServiceCmd, "warning_led");
    shell_pipe_cmd(vPipeCmd,value,sizeof(value));
    if( value[0] == '1' )
    {

	    //detect Status LED GPIO 
	    vRet = i2c_read_block(CMD_SLED, (uint8_t *)vI2C_Data);//0: Have Status LED /1:no Status LED
	    Mdump(DEBUG_MODEL_CMD, "SLED Status : ", vI2C_Data, vRet);
	    _gStatusLEDFlag = vI2C_Data[0];
	    debug_print(DEBUG_MODEL_CMD, "===> Get SLED GPIO : %d\n", _gStatusLEDFlag);
	    memset(vCmd, 0, sizeof(vCmd));
	    if(_gStatusLEDFlag == 0)
	        sprintf(vCmd, "echo OK > %s",STATUS_LED_FILE);
	    else
	        sprintf(vCmd, "echo FAIL > %s",STATUS_LED_FILE);
    }else
    {
            sprintf(vCmd, "echo FAIL > %s",STATUS_LED_FILE);
    }
    system(vCmd);
}

#endif
#ifdef PUBLIC_GPIO
uint32_t GPIO_init(void)
{
    if(access(GPIO_DIR, F_OK) == -1)
    {
        if( 0 != mkdir(GPIO_DIR, S_IRUSR |S_IWUSR | S_IRGRP |S_IWGRP | S_IROTH) )
        {
            printf("Can't open GPIO dir --> %s\n",GPIO_DIR);
            
        }
    }
}
#endif

uint32_t Flags_init(void)
{
    if (access(Flag_RC_NET, F_OK) == -1)
	_gNewLANCheck =0;
    else
	_gNewLANCheck =1;	

}

uint32_t pipe_init(void)
{
    uint8_t vpBuff[32] = {0};

    if(access(PIPE_DIR, F_OK) == -1)
    {
        if( 0 != mkdir(PIPE_DIR,FIFO_MODE) )
        {
            printf("1. Can't open pipe dir --> %s\n",PIPE);
            exit(0);
        }
    }
    // create PIPE
    if (access(PIPE, F_OK) == -1)
    {
        if( 0 != mkfifo(PIPE,FIFO_MODE) )
        {
            printf("1. Can't open pipe file --> %s\n",PIPE);
            exit(0);
        }
    }
    else
    {
        sprintf(vpBuff, "rm -rf %s", PIPE);
        system(vpBuff);

        if( 0 != mkfifo(PIPE,FIFO_MODE) )
        {
            printf("1. Can't open pipe file --> %s\n",PIPE);
            exit(0);
        }
    }

}

uint32_t pipe_uninit(void)
{
    uint8_t vpBuff[32] = {0};

    IN(DEBUG_MODEL_CMD, "");

    if( _gPipe_fp != NULL )
    {
        debug_print(DEBUG_MODEL_CMD, "Close Pipe file");
        fclose(_gPipe_fp);
        _gPipe_fp = NULL;
    }

    sprintf(vpBuff, "rm -rf %s", PIPE);
    system(vpBuff);
    return 0;
}

void *pipecmd(void *ptr)
{
    int8_t buff[PIPE_BUFFER_SIZE] = {0};

    while(1)
    {
        if( (_gPipe_fp = fopen(PIPE,"r")) == NULL )
        {
            printf("2. Can't open pipe file --> %s\n",PIPE);
            exit(0);
        }
        memset(buff, 0, sizeof(buff));

        while(fgets((char *)buff, (int32_t)PIPE_BUFFER_SIZE, (FILE *)_gPipe_fp) != NULL)
        {
            debug_print(DEBUG_MODEL_CMD, "get cmd 001\n" );
            debug_print(DEBUG_MODEL_CMD, "get cmd 002\n" );
            str_trim(buff, strlen(buff));
            BLOCK_INTERRUPT;
            parser_host_cmd(buff);
            RELEASE_INTERRUPT;
        }
        debug_print(DEBUG_MODEL_CMD, "get cmd 003\n" );

        if( _gPipe_fp != NULL )
        {
            fclose(_gPipe_fp);
            _gPipe_fp = NULL;
        }
    }

    printf("pipcmd end\n");
    
    return (void *)0;
}

uint8_t _gPic_Reset_Flag=0;

void poll_cmd_handler(void)
{
    uint8_t i=0;
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vRetData[4]={0};

    if(_gUpgrade_Flag)
        return;
//    if(0 != _gPoll_Flag)
//        return;
//    _gPoll_Flag++;

    if(INTERRUPT_IS_BLOCK)
        return;
    BLOCK_INTERRUPT;

    if(-1 == i2c_read_block(1, (uint8_t *)vI2C_Data))
    {
        RELEASE_INTERRUPT;
        return;
    }

    memcpy(vRetData, &vI2C_Data[I2C_RETURN_VALUE_0], 4);

    for(i=I2C_RETURN_BTN_UP; i<=I2C_RETURN_BTN_ESC; i++)
    {
        if (0 == vI2C_Data[i])
        {
            _gKeyPressCount[i-I2C_RETURN_BTN_UP]++;

            if(0xff == _gKeyPressCount[i-I2C_RETURN_BTN_UP])
                _gKeyPressCount[i-I2C_RETURN_BTN_UP]=1;
        }
        else
        {
            if(0 != _gKeyPress[i-I2C_RETURN_BTN_UP])
            {
                _gKeyPress[i-I2C_RETURN_BTN_UP]=0;
            }

            if(0 != _gKeyPressCount[i-I2C_RETURN_BTN_UP])
            {
                _gKeyPress[i-I2C_RETURN_BTN_UP]=1;
            }

            _gKeyPressCount[i-I2C_RETURN_BTN_UP]=0;
        }
    }

    if(1 == _gKeyPress[BTN_ENTER])
    {
        debug_print(DEBUG_MODEL_CMD, "ENTER Key press\n" );
        Mdump(DEBUG_MODEL_CMD, "** command ** ", vRetData, sizeof(vRetData));
        menu_i2c_cmd(EVENT_BTN_ENTER, vRetData);
    }
    else if(1 == _gKeyPress[BTN_ESC])
    {
        debug_print(DEBUG_MODEL_CMD, "ESC Key press\n" );
        Mdump(DEBUG_MODEL_CMD, "** command ** ", vRetData, sizeof(vRetData));
        menu_i2c_cmd(EVENT_BTN_ESC, vRetData);
    }
    else if(1 == _gKeyPress[BTN_UP])
    {
        debug_print(DEBUG_MODEL_CMD, "UP Key press\n" );
        Mdump(DEBUG_MODEL_CMD, "** command ** ", vRetData, sizeof(vRetData));
        menu_i2c_cmd(EVENT_BTN_UP, vRetData);
    }
    else if(1 == _gKeyPress[BTN_DOWN])
    {
        debug_print(DEBUG_MODEL_CMD, "DOWN Key press\n" );
        Mdump(DEBUG_MODEL_CMD, "** command ** ", vRetData, sizeof(vRetData));
        menu_i2c_cmd(EVENT_BTN_DOWN, vRetData);
    }

    if(OBJECT_STATUS_FINISH == vI2C_Data[I2C_RETURN_INPUT_STATUS])
    {
        debug_print(DEBUG_MODEL_CMD, "Input complete!!\n" );
        Mdump(DEBUG_MODEL_CMD, "** command ** ", vRetData, sizeof(vRetData));
        menu_i2c_cmd(EVENT_INPUT_COMPLETE, vRetData);
    }
    RELEASE_INTERRUPT;
//    _gPoll_Flag--;

}


int32_t get_host_cmd(int8_t * in_arg, int8_t **cmd, int8_t **out_arg)
{
    uint8_t vCmd_Found=0;
    int32_t i = 0;
    int8_t *vCmd=NULL;

    vCmd=in_arg;
    *cmd=NULL;
    *out_arg=NULL;

    if(NULL == cmd)
        return -1;

    for(i=0; i<MAX_CMD_LENGTH; i++)
    {
        if(CMD_IS_EOS(vCmd[0]))
        {
            vCmd[0]='\0';
            return 0;
        }

        if(0 == vCmd_Found && !CMD_IS_BLANK(vCmd[0]))
        {
            *cmd = vCmd;
            vCmd_Found=1;
        }
        else if(1 == vCmd_Found && (CMD_IS_BLANK(vCmd[0]) || CMD_IS_EOS(vCmd[0])))
        {
            vCmd[0]='\0';
            vCmd_Found=2;
        }
        else if(2 == vCmd_Found && !CMD_IS_BLANK(vCmd[0]))
        {
            if(NULL != out_arg)
                *out_arg=vCmd;
            return 0;
        }

        vCmd++;
    }
    return 0;
}

int32_t do_host_cmd(int32_t argc, int8_t **argv)
{
    uint8_t vId=0;
    int32_t vRet=0;

    IN(DEBUG_MODEL_CMD, "argc = %d", argc);
    vRet=search_tab((cmd_table *)_gHost_Cmd_Table, argv[0], &vId);
    debug_print(DEBUG_MODEL_CMD, "vRet %d, vId %d\n", vRet, vId);

    if(0 == vRet)
    {
        switch(vId)
        {
            case CMD_POWER_ON_OFF_ERROR:
            case CMD_SYS_UPGRADE:
            {
                uint8_t vId2=0;
                int32_t vRet2=0;

                if(_gUpgrade_Flag)
                    break;

                vRet2=search_tab((cmd_table *)_gHost_Cmd_Table, argv[2], &vId2);

                if(CMD_GETAVRVN == vId2)
                    get_version();
                else
                {
                    menu_pop_to_level(1, TRUE);
                    warning_show(argv[2], argv[1], _gCurrentState);
                }
            }
            break;
            default:
            {
                vRet=-1;
            }
            break;
        }
    }
    else
        vRet=-1;

    if(0 == vRet)
        return vRet;

    vId=0;
    vRet=0;
    vRet=search_tab((cmd_table *)_gHost_Cmd_Table, argv[2], &vId);
    debug_print(DEBUG_MODEL_CMD, "vRet %d, vId %d\n", vRet, vId);
    
    if(0 == vRet && !(1 == _gUpgrade_Flag && (vRet >= CMD_UPGRADE_PIC_START && vRet <= CMD_UPGRADE_PIC_END)))
    {
        switch(vId)
        {
            case CMD_OLED_DISPLAY:
            {
                if(argv[3] && argv[3][0] >= '0' && argv[3][0] <= '2')
                {
                    uint8_t vData[2]={0};

                    vData[0] = argv[3][0] - '0';
                    i2c_write_block(CMD_OLED_DISPLAY, 1, vData);
                }
            }
            break;
            case CMD_AC_POWER:
            {

                if (argv[3] && 0 == atoi((const char *)argv[3]))
                    alert_add(ALERT_AC_POWER_LOST, NULL);
                else if (argv[3] && 1 == atoi((const char *)argv[3]))
                    alert_add(ALERT_AC_POWER_RECORVER, NULL);
            }
            break;
            case CMD_POWER_OFF:
            {
                if(STATE_BOOT_OK == _gCurrentState)
                    power_off_show();
            }
            break;
            case CMD_DEBUG_ENABLE:
            {

                if (argv[3] && 1 == atoi((const char *)argv[3]))
                    _gDebugFlag=1;
                else
                    _gDebugFlag=0;
            }
            break;
            case CMD_DEBUG_MASK:
            {
                if(argv[3])
                {
                    _gDebugFlagMask = strtol(argv[3], NULL, 0);
                }
            }
            break;
            case CMD_SETBTO:
            {
                _gCurrentState=STATE_BOOTING;
            }
            break;
            case CMD_BTMSG:
            {
                if(argc < 4)
                    return -1;

                if(argv[0] &&  argv[0][0] >= '0' &&  argv[0][0] <= '9')
                    pie_char_show(argv[3], 0xFF & atoi(argv[0]) ,_gCurrentState);
                else
                    warning_show(argv[3], argv[1],_gCurrentState);
            }
            break;
            case CMD_STARTWD:
            {
                menu_release();
                menu_start();
                _gCurrentState=STATE_BOOT_OK;
            }
            break;
            case CMD_USB_COPY:
            {
                usb_copy_show(argv[3][0] - '0');
            }
            break;
            case CMD_GETAVRVN:
            {
                get_version();
            }
            break;
            case CMD_RESET_PIC:
            {
                _gUpgrade_Flag=1;
                menu_release();
                system("echo RESET_PIC > /proc/hwm\n");
                sleep(5);
                RESET_INTERRUPT_BLOCK;
                stop_motion_screen(0);
                sysinfo_update_init();
                menu_start();
                _gCurrentState=STATE_BOOT_OK;
                _gUpgrade_Flag=0;

            }
            break;
            case CMD_UPGRADE_PIC:
            {
                vRet=upgrade_pic(argv[0], argv[3]);

                if(0 == vRet)
                    get_version();
            }
            break;
            case CMD_BOOT_LOADER:
            {
                set_pic_bootloader();
            }
            break;
            case CMD_UPGRADE_PIC_START:
            {
                system("touch /var/tmp/oled/pic_upgrade");
                sleep(1);
                get_version();
                _gUpgrade_Flag=1;
            }
            break;
            case CMD_UPGRADE_PIC_END:
            {
                _gUpgrade_Flag=0;
                RESET_INTERRUPT_BLOCK;
                get_version();
                menu_release();
                menu_queue_release();
                stop_motion_screen(0);
                sysinfo_update_init();
                menu_start();
                _gCurrentState=STATE_BOOT_OK;
                
                if (0 == access("/var/tmp/oled/pic_upgrade", F_OK))
                    system("rm -rf /var/tmp/oled/pic_upgrade");
            }
            break;


#ifdef STATUS_LED			
	    case CMD_SLED:	
	    {
			if(_gStatusLEDFlag != 0)
			{
				debug_print(DEBUG_MODEL_CMD, "===> NO SLED !!!\n");
				break;
			}	
			
			uint8_t vData[2]={0,0};
			if(argc < HOST_CMD_SLED-1)
			{
				debug_print(DEBUG_MODEL_CMD, "Too few arguments !!!\n");
		              return -1;
		       }		
			if(argv[3] && argv[3][0] != '0' && argv[3][0] != '1')	//0: enable 1:disable
			{
				debug_print(DEBUG_MODEL_CMD, "Wrong Mode !!!\n");
				break;
			}
			uint8_t argv3=atoi((const char *)argv[3]);
			vData[0] = argv3;

			if(argc == HOST_CMD_SLED)
			{
				uint8_t argv4=atoi((const char *)argv[4]);
				if(argv4<0 || argv4 >2)
				{
					debug_print(DEBUG_MODEL_CMD, "Wrong LED Index --> %d\n",argv4);
					break;
				}
				vData[1] = argv4;		
			}
			i2c_write_block(CMD_SLED, 2, vData);
			break;
				
#if 0 //for demo			
                if(argv[3] &&  argv[3][0] >= '0' && argv[3][0] <= '2')
		   {
		   	uint16_t cmd_tmp1=atoi((const char *)argv[4]);
			
		   	if(cmd_tmp1 > 1)
		   	{
		   		vRet=-1;
				break;
		   	}
			
                }else if(argv[3] && argv[3][0] == '3')
                {
                	uint16_t cmd_tmp2=atoi((const char *)argv[4]);
					
			if(cmd_tmp2 > 255)
			{
				vRet=-1;
				break;
			}
		    }else if(argv[3] && argv[3][0] == '4')
                {
                	uint16_t cmd_tmp2=atoi((const char *)argv[4]);
					
			if(cmd_tmp2 > 1)
			{
				vRet=-1;
				break;
			}			
                }else
				break;
				
                uint8_t vData[2]={0};              
		   uint8_t argv3=atoi((const char *)argv[3]);
		   uint8_t argv4=atoi((const char *)argv[4]);

		   vData[0] = argv3;	
		   vData[1] = argv4;	
                i2c_write_block(CMD_SLED, 2, vData);
#endif
	    }
	    break;
#endif
#ifdef PUBLIC_GPIO
		case CMD_PUBLIC_GPIO:
		{
/*
			if(_gStatusLEDFlag != 0)
			{
				debug_print(DEBUG_MODEL_CMD, "===> NO GPIO !!!\n");
				break;
			}			
*/
			if(argv[3] && argv[3][0] == '0')//Read
			{
		                if(argc < HOST_CMD_GPIO)
		                {
					debug_print(DEBUG_MODEL_CMD, "Too few arguments !!!\n");
		                    return -1;
		                }			
				uint8_t vData[2]={0};  
				uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
				
	               	if(argv[4] &&  argv[4][0] >= '1' && argv[4][0] <= '8') //GPIO 1~8
			   	{	
			   		 
			   		uint8_t argv4=atoi((const char *)argv[4]);
					vData[0] = 0;//Read	
					vData[1] = argv4;
	                		i2c_write_block(CMD_PUBLIC_GPIO, 2, vData);
	                	}else
	                	{
	                		debug_print(DEBUG_MODEL_CMD,"Wrong GPIO Index Input!");
	                		vRet=-1;
					break;
	                	}
						
				vRet = i2c_read_block(CMD_PUBLIC_GPIO, (uint8_t *)vI2C_Data);
				Mdump(DEBUG_MODEL_CMD, "GPIO Read: ", vI2C_Data, vRet);
				debug_print(DEBUG_MODEL_CMD, "===> Get GPIO %d = %d\n", vData[1], vI2C_Data[0]);
   				uint8_t vCmd[64]={0};
				sprintf(vCmd,"echo R %d > %s%d", vI2C_Data[0], GPIO_FILE, vData[1]);
				system(vCmd);
			}else if(argv[3] && argv[3][0] == '1')//Write
			{
	               	if(argv[4] &&  argv[4][0] >= '1' && argv[4][0] <= '8') //GPIO 1~8
			   	{
			                if(argc < 6)
			                {
						debug_print(DEBUG_MODEL_CMD, "Too few arguments !!!\n");
			                    return -1;
			                }				   	
			   		uint16_t cmd_tmp1=atoi((const char *)argv[5]);
				
			   		if((cmd_tmp1 == 0)||(cmd_tmp1 == 1))
			   		{
			   		 	uint8_t vData[3]={0};       
						uint8_t argv3=atoi((const char *)argv[3]);
			   			uint8_t argv4=atoi((const char *)argv[4]);
			   			uint8_t argv5=atoi((const char *)argv[5]);

			   			vData[0] = 1;	//Write
			   			vData[1] = argv4;	//GPIO Index
						vData[2] = argv5;	//Value
	                			i2c_write_block(CMD_PUBLIC_GPIO, 3, vData);
						uint8_t vCmd[64]={0};
						sprintf(vCmd,"echo W %d > %s%d", vData[2], GPIO_FILE, vData[1]);
						system(vCmd);
			  	 	}else
		  	 		{
						debug_print(DEBUG_MODEL_CMD,"Wrong GPIO Value Input!");
						vRet=-1;
						break;
		  	 		}
				
	                	}else
	                	{
	                		debug_print(DEBUG_MODEL_CMD,"Wrong GPIO Index Input!");
	                		vRet=-1;
					break;
	                	}
			}else
			{
	                	debug_print(DEBUG_MODEL_CMD,"Wrong GPIO Command Input!");
	                	vRet=-1;
				break;
			}
			
		}
		break;
#endif
#if 0 //def PUBLIC_GPIO
		case CMD_PUBLIC_GPIO_R_addr:
		{
			
			uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
		   	uint8_t vData[2]={0};              
		   	uint8_t argv3=atoi((const char *)argv[3]);			
               	if(argv[3] &&  argv[3][0] >= '1' && argv[3][0] <= '8') //GPIO 1~8
		   	{	
		   		vData[0] = argv3;	
                		i2c_write_block(CMD_PUBLIC_GPIO_R_addr, 1, vData);
                	}else
                		vRet=-1;
					
			vRet = i2c_read_block(CMD_PUBLIC_GPIO_R_data, (uint8_t *)vI2C_Data);
			debug_print(DEBUG_MODEL_CMD, "===> Get GPIO %d = %d\n", argv3, vI2C_Data[0]);
			break;
		}
		case CMD_PUBLIC_GPIO_W:
		{
               	if(argv[3] &&  argv[3][0] >= '1' && argv[3][0] <= '8') //GPIO 1~8
		   	{
		   		uint16_t cmd_tmp1=atoi((const char *)argv[4]);
			
		   		if((cmd_tmp1 == 0)||(cmd_tmp1 == 1))
		   		{
		   		 	uint8_t vData[2]={0};              
		   			uint8_t argv3=atoi((const char *)argv[3]);
		   			uint8_t argv4=atoi((const char *)argv[4]);

		   			vData[0] = argv3;	
		   			vData[1] = argv4;	
                			i2c_write_block(CMD_PUBLIC_GPIO_W, 2, vData);
		  	 	}
			
                	}else
                		vRet=-1;

			break;
		}		
#endif
			
            default:
            {
                vRet=-1;
            }
            break;
        }
    }
    else
        vRet=-1;

    return vRet;
}

int32_t parser_host_cmd(int8_t * in_arg)
{
    int32_t i=0;
    uint8_t vCmd_Count=0;
    uint8_t vPara_Num=3;
    int8_t ** vCmd_List=NULL;
    int8_t * vCmd=(int8_t *)in_arg;

    IN(DEBUG_MODEL_CMD, "", "");
//    _gPoll_Flag++;

    vCmd_List = (int8_t **)malloc(sizeof(int8_t *)*16);
    memset(vCmd_List, 0, sizeof(int8_t *)*16);
    debug_print(DEBUG_MODEL_CMD, "\n%s\n", in_arg);
    
    do
    {
        int8_t * vGetCmd=NULL;

        if(vCmd_Count < vPara_Num)
            get_host_cmd(vCmd, &vGetCmd, &vCmd);
        else
            vGetCmd = vCmd;

        if(NULL != vGetCmd)
        {
            int32_t vLen=strlen((const char *)vGetCmd);
            if (vLen > I2C_SMBUS_BLOCK_MAX){
                *(vGetCmd + I2C_SMBUS_BLOCK_MAX)=0;
		vLen=strlen((const char *)vGetCmd);
            }

            if(0 == vCmd_Count && (0 == strcmp(vGetCmd, "Upgrade") || 0 == strcmp(vGetCmd, "UPGRADE")))
                vPara_Num=2;	  	
#ifdef STATUS_LED			
	     else if(strcasecmp(vGetCmd, "SLED") == 0)
		   vPara_Num=HOST_CMD_SLED; //SLED command has 5 parameters
#endif
#ifdef PUBLIC_GPIO			
	     else if(strcasecmp(vGetCmd, "GPIO") == 0)
		   vPara_Num=HOST_CMD_GPIO; //WGPIO command has 5 parameters
#endif
			
            vCmd_List[vCmd_Count]=(int8_t *)malloc(sizeof(int8_t)*vLen +1);
            memset(vCmd_List[vCmd_Count], 0, sizeof(int8_t)*vLen +1);
            memcpy(vCmd_List[vCmd_Count], vGetCmd, sizeof(int8_t)*vLen);
            debug_print(DEBUG_MODEL_CMD, "%d\t\"%s\"\n", vCmd_Count, vCmd_List[vCmd_Count]);
            vCmd_Count++;
        }
    }while(NULL != vCmd && vCmd_Count < vPara_Num + 1);

    do_host_cmd(vCmd_Count, vCmd_List);
    
    for(i=0; i<vCmd_Count; i++)
    {
        if(vCmd_List[i])
        {
            free(vCmd_List[i]);
            vCmd_List[i]=NULL;
        }
    }

    if(vCmd_List)
    {
        free(vCmd_List);
        vCmd_List=NULL;
    }
//    _gPoll_Flag--;
    OUT(DEBUG_MODEL_CMD, "", "");

    return 0;
}

static int32_t upgrade_pic(int8_t *pSleep, int8_t *pIn_argv)
{
    FILE *fpFw;
    uint8_t pBuff[I2C_SMBUS_BLOCK_MAX]; // Contains one line of the HEX file.
    uint8_t vpSpi_Addr[4] = {0};
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vTimeStr[32]={0};
    uint8_t i=0;
    int8_t *vpAddressStr=NULL;
    int8_t *vpFileName=NULL;
    uint32_t vRetryCount=0;
    int32_t vReadLen = 0;
    int32_t vRet = 0;
    uint64_t vTmpAddress = 0;
    uint64_t vAddress = 0xE0000;
    time_t vTime;

    if(!pIn_argv)
        return -1;
    vTime = time(NULL);
    memset(vTimeStr, 0, sizeof(vTimeStr));
    strftime(vTimeStr, sizeof(vTimeStr), "%H:%M:%S", localtime(&vTime));

    get_host_cmd(pIn_argv, &vpFileName, &vpAddressStr);

    debug_print(DEBUG_MODEL_CMD, "Upgrade Pic \"%s\", Start Flash \"%s\"\n", vpFileName, vTimeStr);
    _gUpgrade_Flag=1;
    sleep(2);

    if(vpAddressStr)
    {
        vAddress = strtoul(vpAddressStr, 0, 16);
        debug_print(DEBUG_MODEL_CMD, "Address \"%d\"\n", vAddress);
    }

    if( (fpFw = fopen(vpFileName,"r") ) == NULL )
    {
        _gUpgrade_Flag=0;
        return -1;
    }
    debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 001\n");

    do
    {
        debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 002\n");
        memset(pBuff, 0, sizeof(pBuff));
        memset(vpSpi_Addr, 0, sizeof(vpSpi_Addr));
        vReadLen=0;
        vTmpAddress=vAddress % 0x8000;

#if 1
        if((vTmpAddress + 30) > 0x8000)
            vReadLen = fread(pBuff, 1, (0x8000 - vTmpAddress), fpFw);
        else
            vReadLen = fread(pBuff, 1, 30, fpFw);
#else
        if(vAddress < 0xE8000 && (vAddress + 30) > 0xE8000)
            vReadLen = fread(pBuff, 1, (0xE8000 - vAddress), fpFw);
        else if(vAddress < 0xF0000 && (vAddress + 30) > 0xF0000)
            vReadLen = fread(pBuff, 1, (0xF0000 - vAddress), fpFw);
        else
            vReadLen = fread(pBuff, 1, 30, fpFw);
#endif
        for(i = 0; i < vReadLen; i++)
            pBuff[vReadLen] = (pBuff[vReadLen] + pBuff[i]) & 0xFF;
        vpSpi_Addr[2] = (uint8_t)(vAddress & 0xff);
        vpSpi_Addr[1] = (uint8_t)((vAddress >> 8) & 0xff);
        vpSpi_Addr[0] = (uint8_t)((vAddress >> 16) & 0xff);

        for(i = 0; i < 3; i++)
            vpSpi_Addr[3] = (vpSpi_Addr[3] + vpSpi_Addr[i]) & 0xFF;

        if(vReadLen > 0)
        {
            debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 003\n");
            vRetryCount=0;
            vRet=0;

            do
            {
                debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 004 - wait address response, Retry %d, vRet %d\n", vRetryCount, vRet);

                if(vRetryCount == 0 || (I2C_RETURN_STATUS_SUCCESS == vI2C_Data[0] && vI2C_Data[1] != vpSpi_Addr[3]))
                    i2c_write_block(CMD_SPI_ADDRESS, 4, vpSpi_Addr);

                memset(vI2C_Data, 0, sizeof(vI2C_Data));

                if(vRetryCount != 0)
                    usleep(100000);
                vRet = i2c_read_block(CMD_SPI_STATUS, (uint8_t *)vI2C_Data);
                Mdump(DEBUG_MODEL_CMD, "Address SPI_STATUS ", vI2C_Data, sizeof(vI2C_Data));
            }while(vRetryCount++ < 20 && (-1 == vRet || I2C_RETURN_STATUS_SUCCESS != vI2C_Data[0] || vI2C_Data[1] != vpSpi_Addr[3]));

            if(vRetryCount >= 20 && (-1 == vRet || I2C_RETURN_STATUS_SUCCESS != vI2C_Data[0] || vI2C_Data[1] != vpSpi_Addr[3]))
            {
                if(fpFw)
                    fclose(fpFw);
                debug_print(DEBUG_MODEL_CMD, "Upgrade PIC wait address response fail, retry count %d, vRet %d\n", vRetryCount-1, vRet);
                Mdump(DEBUG_MODEL_CMD, "SPI_ADDRESS ", vpSpi_Addr, sizeof(vpSpi_Addr));
                Mdump(DEBUG_MODEL_CMD, "SPI_DATA ", pBuff, sizeof(pBuff));
                Mdump(DEBUG_MODEL_CMD, "Address SPI_STATUS ", vI2C_Data, sizeof(vI2C_Data));
                _gUpgrade_Flag=0;
                return -1;
            }

            if(pSleep[0] > '0')
                usleep(500000*(pSleep[0]-'0'));
            vRetryCount=0;
            vRet=0;

            do
            {
                debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 005 - wait data response, Retry %d, vRet %d\n", vRetryCount, vRet);

                if(vRetryCount == 0 || (I2C_RETURN_STATUS_SUCCESS == vI2C_Data[0] && vI2C_Data[1] != pBuff[vReadLen]))
                    i2c_write_block(CMD_SPI_DATA, vReadLen + 1, pBuff);

                memset(vI2C_Data, 0, sizeof(vI2C_Data));

                if(vRetryCount != 0)
                    usleep(100000);
                vRet = i2c_read_block(CMD_SPI_STATUS, (uint8_t *)vI2C_Data);
                Mdump(DEBUG_MODEL_CMD, "Data SPI_STATUS ", vI2C_Data, sizeof(vI2C_Data));
            }while(vRetryCount++ < 40 && (-1 == vRet || I2C_RETURN_STATUS_SUCCESS != vI2C_Data[0] || vI2C_Data[1] != pBuff[vReadLen]));

            if(vRetryCount >= 40 && (-1 == vRet || I2C_RETURN_STATUS_SUCCESS != vI2C_Data[0] || vI2C_Data[1] != pBuff[vReadLen]))
            {
                if(fpFw)
                    fclose(fpFw);
                debug_print(DEBUG_MODEL_CMD, "Upgrade PIC wait data response fail, retry count %d, vRet %d\n", vRetryCount-1, vRet);
                Mdump(DEBUG_MODEL_CMD, "SPI_ADDRESS ", vpSpi_Addr, sizeof(vpSpi_Addr));
                Mdump(DEBUG_MODEL_CMD, "SPI_DATA ", pBuff, sizeof(pBuff));
                Mdump(DEBUG_MODEL_CMD, "Data SPI_STATUS ", vI2C_Data, sizeof(vI2C_Data));
                _gUpgrade_Flag=0;
                return -1;
            }

        }
        vAddress += vReadLen;
    }while(vReadLen > 0);

    if(fpFw)
        fclose(fpFw);
    sleep(5);
    vTime = time(NULL);
    memset(vTimeStr, 0, sizeof(vTimeStr));
    strftime(vTimeStr, sizeof(vTimeStr), "%H:%M:%S", localtime(&vTime));

    debug_print(DEBUG_MODEL_CMD, "Upgrade Pic, End Flash \"%s\"\n", vTimeStr);
//    _gUpgrade_Flag=0;
    return 0;
}

static int32_t set_pic_bootloader(void)
{
    uint32_t vRetryCount=0;
    int32_t vRet = 0;
    uint8_t pBuff[I2C_SMBUS_BLOCK_MAX]; // Contains one line of the HEX file.
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vTimeStr[32]={0};
    time_t vTime;

    vTime = time(NULL);
    memset(vTimeStr, 0, sizeof(vTimeStr));
    strftime(vTimeStr, sizeof(vTimeStr), "%H:%M:%S", localtime(&vTime));
    debug_print(DEBUG_MODEL_CMD, "Upgrade Pic , Start BootLoader \"%s\"\n", vTimeStr);

    _gUpgrade_Flag=1;

    do
    {
        debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 006 -  Set Boot Loader\n");

        if(vRetryCount == 0 || 1 != vI2C_Data[0])
        {
            memset(pBuff, 0, sizeof(pBuff));
            pBuff[0]=1;
            i2c_write_block(CMD_BOOT_LOADER, 1, pBuff);
        }
        memset(vI2C_Data, 0, sizeof(vI2C_Data));

        if(vRetryCount != 0)
            usleep(100000);
    }while(vRetryCount++ < 20 && (-1 == i2c_read_block(CMD_BOOT_LOADER, (uint8_t *)vI2C_Data) || 2 != vI2C_Data[0]));

    if(vRetryCount >= 20)
    {
        debug_print(DEBUG_MODEL_CMD, "Upgrade PIC Set Boot Loader Fail, retry count %d\n", vRetryCount-1);
        _gUpgrade_Flag=0;
        return -1;
    }

    vRetryCount=0;
    vRet=0;

    do
    {
        debug_print(DEBUG_MODEL_CMD, "Upgrade Pic step 007 - Wait Finish\n");
        memset(vI2C_Data, 0, sizeof(vI2C_Data));

        if(vRetryCount != 0)
            sleep(1);
        vRet = i2c_read_block(CMD_SPI_STATUS, (uint8_t *)vI2C_Data);
        Mdump(DEBUG_MODEL_CMD, "Data SPI_STATUS ", vI2C_Data, sizeof(vI2C_Data));
    }while(vRetryCount++ < 600 && (-1 == vRet || I2C_RETURN_STATUS_FINISH != vI2C_Data[0]));

    if(vRetryCount >= 600)
    {
        debug_print(DEBUG_MODEL_CMD, "Upgrade PIC Wait Finish Fail, retry count %d\n", vRetryCount-1);
        _gUpgrade_Flag=0;
        return -1;
    }

    _gUpgrade_Flag=0;

    return 0;
}

int32_t get_version(void)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t vRetry_Count=0;
    uint8_t vCmd[64]={0};
    int32_t vRet=0;

    while(-1 == (vRet = i2c_read_block(0, (uint8_t *)vI2C_Data)))
    {
        printf("Retry %d\n", vRetry_Count);
        if(vRetry_Count++ >= 10)
        {
            fprintf( stderr, "Failed to read data form oled: \"%m\"\n" );
            return -1;
        }
        usleep(100000);
    }
    Mdump(DEBUG_MODEL_CMD, "Pic Version : ", vI2C_Data, vRet);
    _gPicVersion=vI2C_Data[0];
    debug_print(DEBUG_MODEL_CMD, "Pic Version : %d\n", _gPicVersion);

    sprintf(vCmd, "echo Agent Revision:%s > /var/tmp/oled/PIC24F_OK", _gpVersion);
    system(vCmd);
    memset(vCmd, 0, sizeof(vCmd));
    sprintf(vCmd, "echo Pic Revision:%02d >> /var/tmp/oled/PIC24F_OK", vI2C_Data[0]);
    system(vCmd);
	
    return 0;
}

#if defined(__STAND_ALONG__)

int32_t main(int32_t argc, int8_t **argv)
{
    uint32_t i = 0;

    int8_t * vCmd=(int8_t *)*argv;

    for(i=0; i<argc; i++)
        printf("%d\t%s\n", i, argv[i]);

    i = 0;
    
    do
    {
        int8_t * vGetCmd=NULL;

        get_host_cmd(vCmd, &vGetCmd, &vCmd);

        if(NULL != vGetCmd)
            printf("%d\t%s\n", i++, vGetCmd);
    }while(NULL != vCmd);

    printf("HELLO WORLD!!!\n");
    return 0;
}

#endif /*   __STAND_ALONG__ */
