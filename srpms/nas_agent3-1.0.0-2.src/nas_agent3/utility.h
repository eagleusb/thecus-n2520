#ifndef UTILITY_H_
#define UTILITY_H_

#ifdef	__cplusplus
extern "C" {
#endif

#include <stdint.h>

    #define TRUE    1
    #define FALSE   0
    #define _DEBUG_ 1
    #define _DEBUG_TO_FILE_ 0

    #define DEBUG_MODEL_CMD     0x01
    #define DEBUG_MODEL_I2C     0x02
    #define DEBUG_MODEL_MENU    0x04
    #define DEBUG_MODEL_SQL     0x08
    #define DEBUG_MODEL_SYSINFO 0x10
    #define DEBUG_MODEL_MISC    0x20
    #define STATUS_LED	//for Status LED support
    #define PUBLIC_GPIO	//for Pbulic GPIO support
    //#define NEW_LAN_STATUS_CHECK

    enum
    {
        STATE_INIT,
        STATE_SET_LOGO,
        STATE_BOOTING,
        STATE_BOOT_OK,
    };

    extern uint8_t _gCurrentState;
    extern uint8_t _gTestMode;
    extern uint8_t _gBlockInterruptCount;
#ifdef _DEBUG_
    extern void memdump(uint8_t *mem,int32_t m);
    extern uint8_t _gDebugFlag;
    extern uint32_t _gDebugFlagMask;
    extern uint8_t _gTmpDebugFlag;
#if (_DEBUG_TO_FILE_ == 1)
    extern util_debug_file_init(void);
    extern util_debug_file_uninit(void);
    extern FILE *_gDebug_fp;
    extern uint8_t gDebugToFile;
    #define IN(mask,fmt,arg...)             if(_gDebugFlag == 1 && mask&_gDebugFlagMask && gDebugToFile == 1) \
                                                fprintf(_gDebug_fp,"In %s("fmt")\n",__FUNCTION__,## arg); \
                                            else \
                                                printf("In %s("fmt")\n",__FUNCTION__,## arg);
    #define OUT(mask,fmt,arg...)            if (_gDebugFlag == 1 && mask&_gDebugFlagMask && gDebugToFile == 1) \
						fprintf(_gDebug_fp,"Out of %s("fmt")\n",__FUNCTION__,## arg); \
					    else \
						printf("Out of %s("fmt")\n",__FUNCTION__,## arg);
    #define debug_print(mask,fmt,arg...)    if (_gDebugFlag == 1 && mask&_gDebugFlagMask && gDebugToFile == 1) \
						fprintf(_gDebug_fp,"=> %s:%d ("fmt")",__FUNCTION__, __LINE__,## arg); \
					    else \
						printf("=> %s:%d "fmt ,__FUNCTION__, __LINE__,## arg)
    #define Mdump(mask,msg,buf,len)         if( _gDebugFlag == 1 && mask&_gDebugFlagMask && gDebugToFile == 1) \
                                            {\
                                                fprintf(_gDebug_fp,"%s---> %s\n",__FUNCTION__,msg); \
                                                memdump((uint8_t *)buf,len);\
                                            }\
					    else \
					    {\
                                                printf("%s---> %s\n",__FUNCTION__,msg); \
                                                memdump((uint8_t *)buf,len);\
					    }
#else
    #define IN(mask,fmt,arg...)             if (_gDebugFlag == 1 && mask&_gDebugFlagMask) printf("In %s("fmt")\n",__FUNCTION__,## arg)
    #define OUT(mask,fmt,arg...)            if (_gDebugFlag == 1 && mask&_gDebugFlagMask) printf("Out of %s("fmt")\n",__FUNCTION__,## arg)
    #define debug_print(mask,fmt,arg...)    if( _gDebugFlag == 1 && mask&_gDebugFlagMask) printf("=> %s:%d "fmt ,__FUNCTION__, __LINE__,## arg)
    #define Mdump(mask,msg,buf,len)         if( _gDebugFlag == 1 && mask&_gDebugFlagMask) \
                                            {\
                                                printf("%s---> %s\n",__FUNCTION__,msg); \
                                                memdump((uint8_t *)buf,len);\
                                            }
#endif
    #define DISABLE_DEBUG_MESSAGE() _gTmpDebugFlag = _gDebugFlag; _gDebugFlag = 0
    #define ENABLE_DEBUG_MESSAGE()  _gDebugFlag = _gTmpDebugFlag

#else

    #define Mdump(msg,buf,len) { }
    #define IN(fmt,arg...)
    #define Out(fmt,arg...)
    #define debug_print(fmt,arg...)
#endif
    #define BLOCK_INTERRUPT     _gBlockInterruptCount++
    #define RELEASE_INTERRUPT   if(_gBlockInterruptCount > 0) _gBlockInterruptCount--
    #define INTERRUPT_IS_BLOCK  _gBlockInterruptCount > 0
    #define RESET_INTERRUPT_BLOCK  _gBlockInterruptCount = 0


typedef struct util_list_node_struct
{
    struct util_list_node_struct *prev;
    struct util_list_node_struct *next;
    void * pData;
} util_list_node;

typedef struct util_list_head_struct
{
    unsigned long count;
    struct util_list_node_struct *start;
    struct util_list_node_struct *end;
} util_list_head;

typedef struct cmd_table_struct
{
    int32_t id;
    int8_t cmd[36];
} cmd_table;

util_list_head *util_list_init(void);
int32_t util_add_to_end(void *pData, util_list_head **Head);
int32_t util_add_to_start(void *pData, util_list_head **Head);
int32_t util_get_from_start(void **ppData, util_list_head **Head);
int32_t util_get_from_end(void **ppData, util_list_head **Head);
int32_t util_query_by_index(unsigned long idx, void **ppData, util_list_head **Head);
int32_t util_delete_by_index(unsigned long idx, void **ppData, util_list_head **Head);
int32_t util_list_release(util_list_head *pHead);
int32_t search_tab(cmd_table *tab, int8_t *cmd, uint8_t *pid);
int32_t search_tabbyid(cmd_table *tab, int32_t id, uint8_t **pcmd);
void memdump(uint8_t *mem,int32_t m);
int32_t shell_pipe_cmd(int8_t *cmd, int8_t *ret_msg, int32_t msglen);
int32_t shell_pipe_cmd_multiline(int8_t *cmd, int8_t *ret_msg, int32_t msglen);
int32_t para_parser(int8_t *in_para, int8_t **next_para, int32_t para_len);
int32_t str_trim(int8_t *pStr, int32_t str_len);
int32_t ip_strtoint(uint8_t *pStr_Ip, uint8_t *pInt_Ip);

#ifdef	__cplusplus
}
#endif

#endif /*UTILITY_H_*/
