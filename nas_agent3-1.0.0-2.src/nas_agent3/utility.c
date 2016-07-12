/*
 *      utility.c
 *      
 *      Copyright 2009 DorianKo <dorianko@dorianko-desktop>
 *      
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *      
 *      This program is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *      
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *      MA 02110-1301, USA.
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <signal.h>
#include <unistd.h>
#include <ctype.h>
#include "utility.h"
#include <fcntl.h>
#define ispnt(c)	(isprint(c) ? c : '.')
#define is_blank(c) 	((c == ' ' || c == '\t') ? 1 : 0 )

uint8_t _gBlockInterruptCount=0;
uint8_t _gTmpDebugFlag=0;
uint8_t _gDebugFlag=1;
uint32_t _gDebugFlagMask=0xFF;
#if(_DEBUG_ == 1 && _DEBUG_TO_FILE_ == 1)
uint8_t gDebugToFile=1;

#define AG3DBFILE "/tmp/agent3_debug.log"
FILE *_gDebug_fp=NULL;

util_debug_file_init(void)
{
        
#if 1
	if( (_gDebug_fp = fopen(AG3DBFILE,"w")) == NULL )
        {
            printf("Can't open debug file --> %s\n",AG3DBFILE);
            exit(0);
        }
	gDebugToFile=1;
#else
    _gDebug_fp = fopen(AG3DBFILE,"r");
    if(_gDebug_fp != NULL) 
    {
	fclose(_gDebug_fp);
  	_gDebug_fp = NULL;
	printf("Debug message print to /etc/agent3_debug.log\n");
        if( (_gDebug_fp = fopen(AG3DBFILE,"w")) == NULL )
        {
            printf("Can't open debug file --> %s\n",AG3DBFILE);
            exit(0);
        }
	gDebugToFile=1;
    }else
    {
	printf("No debug file! \n");
    } 	
#endif
}

util_debug_file_uninit(void)
{
    fclose(_gDebug_fp);
    _gDebug_fp=NULL;
}

#endif

util_list_head *util_list_init(void)
{
    util_list_head *vHead=NULL;

    IN(DEBUG_MODEL_MISC, "", "");
    vHead = (util_list_head *) malloc(sizeof(util_list_head));  /* create a new list */
    memset(vHead, 0, sizeof(util_list_head));
    debug_print(DEBUG_MODEL_CMD, "%lx\n", (unsigned long int)vHead);
    memdump((uint8_t *)vHead, sizeof(util_list_head));

    return vHead;
}

int32_t util_add_to_end(void *pData, util_list_head **Head)
{
    util_list_head *vHead=NULL;
    util_list_node *vNode=NULL;

    IN(DEBUG_MODEL_MISC, "");

    if(Head == NULL || *Head ==NULL)
        return -1;
    vHead=*Head;

    vNode= (util_list_node*) malloc(sizeof(util_list_node));  /* create a new node */
    memset(vNode, 0, sizeof(util_list_node));
    
    if(NULL == vNode)
        return -2;

    if(0 == vHead->count)
    {
        vHead->start=vNode;
        vHead->end=vNode;
        vNode->prev=NULL;
        vNode->next=NULL;
        vNode->pData=pData;
    }
    else
    {
        vNode->prev=vHead->end;
        vNode->next=NULL;
        vHead->end->next=vNode;
        vHead->end=vNode;
        vNode->pData=pData;
    }
    vHead->count++;
    OUT(DEBUG_MODEL_MISC, "");
    return 0;
}

int32_t util_add_to_start(void *pData, util_list_head **Head)
{
    util_list_head *vHead=NULL;
    util_list_node *vNode=NULL;

    if(Head == NULL || *Head ==NULL)
        return -1;
    vHead=*Head;

    vNode= (util_list_node*) malloc(sizeof(util_list_node));  /* create a new node */
    memset(vNode, 0, sizeof(util_list_node));
    
    if(NULL == vNode)
        return -2;

    if(0 == vHead->count)
    {
        vHead->start=vNode;
        vHead->end=vNode;
        vNode->prev=NULL;
        vNode->next=NULL;
        vNode->pData=pData;
    }
    else
    {
        vNode->prev=NULL;
        vNode->next=vHead->start;
        vHead->start->prev=vNode;
        vHead->start=vNode;
        vNode->pData=pData;
    }
    vHead->count++;
    return 0;
}

int32_t util_get_from_start(void **ppData, util_list_head **Head)
{
    util_list_head *vHead=NULL;
    util_list_node *vNode=NULL;

    if(Head == NULL || *Head ==NULL)
        return -1;
    vHead=*Head;

    if(NULL != ppData)
        *ppData=NULL;

    if(0 == vHead->count)
        return 1;
    vNode=vHead->start;

    if(vNode->next)
        vNode->next->prev=NULL;
    else
        vHead->end=NULL;
    vHead->start=vNode->next;

    if(NULL != ppData)
        *ppData=vNode->pData;
    free(vNode);
    vNode=NULL;
    vHead->count--;

    return 0;
}

int32_t util_get_from_end(void **ppData, util_list_head **Head)
{
    util_list_head *vHead=NULL;
    util_list_node *vNode=NULL;

    if(Head == NULL || *Head ==NULL)
        return -1;
    vHead=*Head;

    if(NULL != ppData)
        *ppData=NULL;
    IN(DEBUG_MODEL_MISC, "%ld", vHead->count);

    if(0 == vHead->count)
        return 1;
    vNode=vHead->end;

    if(vNode->prev)
        vNode->prev->next=NULL;
    else
        vHead->start=NULL;
    vHead->end=vNode->prev;

    if(NULL != ppData)
        *ppData=vNode->pData;
    free(vNode);
    vNode=NULL;    
    vHead->count--;

    return 0;
}

int32_t util_query_by_index(unsigned long idx, void **ppData, util_list_head **Head)
{
    util_list_head *vHead=NULL;
    util_list_node *vNode=NULL;
    unsigned long i = idx;

    if(Head == NULL || *Head ==NULL)
        return -1;
    vHead=*Head;

    if(NULL != ppData)
        *ppData=NULL;

    if(idx < 0 || idx >= vHead->count)
        return -1;

    vNode=vHead->start;

    if(NULL == vNode)
        return -1;

    while(i > 0 && NULL != vNode->next)
    {
        vNode = vNode->next;
        i--;
    }

    if(NULL != ppData)
        *ppData=vNode->pData;
    return 0;
}

int32_t util_delete_by_index(unsigned long idx, void **ppData, util_list_head **Head)
{
    util_list_head *vHead=NULL;
    util_list_node *vNode=NULL;
    unsigned long i = idx;

    if(Head == NULL || *Head ==NULL)
        return -1;
    vHead=*Head;

    if(NULL != ppData)
        *ppData=NULL;

    if(idx < 0 || idx >= vHead->count)
        return -1;

    vNode=vHead->start;

    if(NULL == vNode)
        return -1;

    while(i > 0 && NULL != vNode->next)
    {
        vNode = vNode->next;
        i--;
    }

    if(NULL != ppData)
        *ppData=vNode->pData;

    if(NULL != vNode->prev)
        vNode->prev->next = vNode->next;

    if(NULL != vNode->next)
        vNode->next->prev = vNode->prev;

    free(vNode);
    vNode=NULL;
    vHead->count--;
    return 0;
}

int32_t util_list_release(util_list_head *pHead)
{
    if( NULL == pHead )
        return -1;

    free(pHead);
    pHead=NULL;

    return 0;
}

int32_t search_tab(cmd_table *tab, int8_t *cmd, uint8_t *pid)
{
    int8_t i=0;

    //IN(DEBUG_MODEL_MISC, "cmd \"%s\"", cmd);
    if(NULL == cmd)
        return -2;

    while((tab+i)->id != -1)
    {
        //debug_print(DEBUG_MODEL_MISC, "%s_%d - %s_%d \n", (tab+i)->cmd, strlen((tab+i)->cmd), cmd, strlen(cmd));

        if( strcasecmp((const char *)((tab+i)->cmd), (const char *)cmd) == 0 )//luke modify 20100721: Ignore case of the characters.
        {
            if(pid)
                *pid=(uint8_t)(tab+i)->id;
            return 0;
        }
        i++;
    }
    return -1;
}

int32_t search_tabbyid(cmd_table *tab, int32_t id, uint8_t **pcmd)
{
    int8_t i=0;

    while((tab+i)->id != -1)
    {
//        debug_print(DEBUG_MODEL_MISC, "%s_%d - %s_%d \n", (tab+i)->cmd, strlen((tab+i)->cmd), cmd, strlen(cmd));

        if( (tab+i)->id == id)
        {
            *pcmd=(uint8_t *)(tab+i)->cmd;
            return 0;
        }
        i++;
    }
    return -1;
}
#if (_DEBUG_ == 1 && _DEBUG_TO_FILE_ == 1)
void memdump(uint8_t *mem,int32_t m)
{
    int32_t cnt,n;

    if(m>1024)
        m = 1024;

    for(cnt=0;cnt<m;cnt += 16)
    {
	if (gDebugToFile==1)
            fprintf(_gDebug_fp," %04d | ",cnt);
	else
            printf(" %04d | ",cnt);

        for(n=0;n<16 ;n++)
        {
            if( (n+cnt) < m )
	    {
	        if (gDebugToFile==1)
                    fprintf(_gDebug_fp,"%02x ",*(mem+n+cnt));
                else
                    printf("%02x ",*(mem+n+cnt));
            }else
	    {
	        if (gDebugToFile==1)
                    fprintf(_gDebug_fp,"-- ");
		else
                    printf("-- ");
            }
	}
 	if (gDebugToFile==1)
            fprintf(_gDebug_fp," |");
	else
            printf(" |");

        for(n=0;n<16 ;n++)
        {
            if( (n+cnt) < m )
	    {
 		if (gDebugToFile==1)
                    fprintf(_gDebug_fp,"%c",ispnt(*(mem+n+cnt)));
		else
                    printf("%c",ispnt(*(mem+n+cnt)));

            }else
	    {
 		if (gDebugToFile==1)
                    fprintf(_gDebug_fp,"-");
		else
                    printf("-");
	    }
        }
 	if (gDebugToFile==1)
            fprintf(_gDebug_fp,"\r\n");
	else
            printf("\r\n");

    }
    if (gDebugToFile==1)
        fprintf(_gDebug_fp,"\r\n");
    else
        printf("\r\n");
}
#else
void memdump(uint8_t *mem,int32_t m)
{
    int32_t cnt,n;

    if(m>1024)
        m = 1024;

    for(cnt=0;cnt<m;cnt += 16)
    {
        printf(" %04d | ",cnt);

        for(n=0;n<16 ;n++)
        {
            if( (n+cnt) < m )
                printf("%02x ",*(mem+n+cnt));
            else
                printf("-- ");
        }
        printf(" |");

        for(n=0;n<16 ;n++)
        {
            if( (n+cnt) < m )
                printf("%c",ispnt(*(mem+n+cnt)));
            else
                printf("-");
        }
        printf("\r\n");
    }
    printf("\r\n");
}
#endif
int32_t shell_pipe_cmd(int8_t *cmd, int8_t *ret_msg, int32_t msglen)
{
    FILE *in;
    int8_t *pt;
    int32_t vMsgLen=0;

//    IN("cmd - %s, cmdlen - %d, strlen - %d", cmd, msglen, strlen(cmd));

    if( cmd == NULL || strlen(cmd) == 0 )
    {
        printf("Err: Invalid command!!\n");
        return -1;
    }

    if((in=popen(cmd,"r")) == NULL )
    {
        printf("Err: Can popen cmd : %s\n",cmd);
        return -1;
    }
    fgets( ret_msg, msglen, in );
    pt = ret_msg;
    vMsgLen=msglen;

    while( *pt != '\0' && *pt != '\n' && *pt != 0x0a && --vMsgLen > 0)
        pt++;
    *pt = '\0';
    pclose(in);
//    OUT();
    return 0;
}

int32_t shell_pipe_cmd_multiline(int8_t *cmd, int8_t *ret_msg, int32_t msglen)
{
    FILE *in;
    int8_t *pt;
    int32_t vMsgLen=0;

    if( cmd == NULL || strlen(cmd) == 0 )
    {
        printf("Err: Invalid command!!\n");
        return -1;
    }

    if((in=popen(cmd,"r")) == NULL )
    {
        printf("Err: Can popen cmd : %s\n",cmd);
        return -1;
    }

    vMsgLen = fread( ret_msg, 1, msglen, in );
    pt = ret_msg;

    while( *pt != '\0' && --vMsgLen > 0)
        pt++;
    *pt = '\0';
    pclose(in);
    return 0;
}

int32_t para_parser(int8_t *in_para, int8_t **next_para, int32_t para_len)
{
    int vStrLen = para_len;
    int8_t *vTmpStrP = in_para;

    if(vStrLen > 0)
    {
        while( *vTmpStrP != '\0' && *vTmpStrP != '\n' && *vTmpStrP != '\t' && *vTmpStrP != ' ' && *vTmpStrP != 0x0a && vStrLen > 0)
        {
            vTmpStrP++;
            vStrLen--;
        }
        *vTmpStrP='\0';


        while( (*vTmpStrP == '\0' || *vTmpStrP == '\n' || *vTmpStrP == '\t' && *vTmpStrP != ' ' || *vTmpStrP == 0x0a) && vStrLen > 0)
        {
            vTmpStrP++;
            vStrLen--;
        }

        if(next_para)
            *next_para = vTmpStrP;
    }

    return 0;
}

int32_t str_trim(int8_t *pStr, int32_t str_len)
{
    int vStrLen = str_len;
    int8_t *vTmpStrP = pStr;

    IN(DEBUG_MODEL_MISC, "\"%s\"", vTmpStrP);

    if(str_len < 1)
        return -1;

    while(vStrLen-- > 0 && (pStr[vStrLen] == '\n' || pStr[vStrLen] == '\t' || pStr[vStrLen] == ' ' || pStr[vStrLen] == 0x0a))
        pStr[vStrLen]='\0';

    OUT(DEBUG_MODEL_MISC, "\"%s\"", vTmpStrP);
    return 0;
}

int32_t ip_strtoint(uint8_t *pStr_Ip, uint8_t *pInt_Ip)
{
    uint8_t i=0;
    uint32_t vStrLen=0;
    uint8_t *vpIpStart=NULL;
    uint8_t *vpIpEnd=NULL;
    uint8_t vpTmpStr[4]={0};

    if(NULL == pStr_Ip || NULL == pInt_Ip)
        return -1;
    vStrLen=strlen(pStr_Ip);

    if(0 == vStrLen)
        return -2;
    vpIpStart = pStr_Ip;

    do
    {
        vpIpEnd = strchr(vpIpStart, '.');

        Mdump(DEBUG_MODEL_MISC, "IP:", vpIpStart, vpIpEnd-vpIpStart);

        memset(vpTmpStr, 0, sizeof(vpTmpStr));

        if(vpIpEnd - vpIpStart < 4)
        {
            memcpy(vpTmpStr, vpIpStart, vpIpEnd - vpIpStart);
            pInt_Ip[i]=(uint8_t)(atoi(vpTmpStr) & 0xFF);
        }
        vpIpStart = vpIpEnd + 1;
    } while (++i < 3);

    if(strlen(vpIpStart) < 4)
        pInt_Ip[i]=(uint8_t)(atoi(vpIpStart) & 0xFF);

    return 0;
}
