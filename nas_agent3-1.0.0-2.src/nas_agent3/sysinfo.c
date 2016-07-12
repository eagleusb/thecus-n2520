#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>
#include <ctype.h>
#include "utility.h"
#include "memory.h"
#include "cmd.h"
#include "cmd_queue.h"
#include "i2c.h"
#include "timer.h"
#include "sqliteapi.h"
#include "sysinfo.h"
#include "menu.h"
#include "scr_template.h"

extern uint8_t _gPicVersion;
extern uint8_t _gNewLANCheck;
sys_info _gSys_Info={0};
uint8_t _gNic_1_Name[8]="eth0";
uint8_t _gNic_2_Name[8]="eth1";
int8_t _gSys_Info_Show_Idx=0;
uint8_t _gSys_Info_Raid_Idx=0;

cmd_table _gLanguage_Table[]=
{
//    {LANG_UNKNOW        , ""},
    {LANG_ENGLISH       , "en"},
    {LANG_T_CHINESE     , "tw"},
    {LANG_S_CHINESE     , "zh"},
    {LANG_FRANCH        , "fr"},
    {LANG_GERMAN        , "de"},
    {LANG_ITALIAN       , "it"},
    {LANG_JAPANESE      , "ja"},
    {LANG_KOREAN        , "ko"},
    {LANG_POLISH        , "pl"},
    {LANG_RUSSIAN       , "ru"},
    {LANG_SPANISH       , "es"},
    {-1, ""},
};

cmd_table _g8023ad_Table_old[]=
{
    {LINK_MODE_8023AD   , "8023ad"},
    {LINK_MODE_ACTBKP   , "actbkp"},
    {LINK_MODE_LBRR     , "lbrr"},
    {LINK_MODE_NONE     , "none"},
    {-1, ""},
};

cmd_table _g8023ad_Table[]=
{
    {LINK_MODE_8023AD   , "8023ad"},
    {LINK_MODE_ACTBKP   , "actbkp"},
    {LINK_MODE_LBRR     , "lbrr"},
#ifdef __WISHLIST_LINK_AGGREGAGTION_2009__
    {LINK_MODE_LBXOR     , "lbxor"},
    {LINK_MODE_LBTLB     , "bltlb"},
    {LINK_MODE_LBALB     , "blalb"},
#endif  //__WISHLIST_LINK_AGGREGAGTION_2009__
    {LINK_MODE_NONE     , "none"},
    {-1, ""},
};

cmd_table _g8023ad_Display_Table[]=
{
    {LINK_MODE_8023AD   , "802.3ad"},
    {LINK_MODE_ACTBKP   , "Failover"},
    {LINK_MODE_LBRR     , "Load Blance"},
#ifdef __WISHLIST_LINK_AGGREGAGTION_2009__
    {LINK_MODE_LBXOR     , "Blance-XOR"},
    {LINK_MODE_LBTLB     , "Blance-TLB"},
    {LINK_MODE_LBALB     , "Blance-ALB"},
#endif  //__WISHLIST_LINK_AGGREGAGTION_2009__
    {LINK_MODE_NONE     , "N/A"},
    {-1, ""},
};

int32_t sysinfo_timeout_cb(uint32_t event, void *pData)
{
    sysinfo_update_screen(1);
    general_set_timer(TIMER_ID_MENU_SYSINFO, SYS_INFO_TIMEOUT, sysinfo_timeout_cb, pData);
    return 0;
}

int32_t sysinfo_update_screen(int8_t offset)
{
  time_t      vTime;
  char        vBuff[300+1]={0};
  char        vBuff1[300+1]={0};
  char        vBuff2[300+1]={0};
  char        vBuff3[300+1]={0};
  uint8_t     *vLinkType=NULL;
  uint8_t     i=0;
  uint8_t     vNewItemIdx=0;
  uint8_t     vNewRaidIdx=0;
  int8_t     vOffSet=0;
  template_08 vMenu_Data={0};
  char value[PIPE_CMD_BUF] = {0};
  struct stat hast;

  IN(DEBUG_MODEL_SYSINFO, "Show_Index %d, Raid_index %d, Offset %d", _gSys_Info_Show_Idx, _gSys_Info_Raid_Idx, offset);

  uint8_t ha_enable;

  ha_enable = 0;
  if( conf_db_select(KEY_HA, "conf", value) >= 0 ){
    if( value[0] == '1' ){
      ha_enable = 1;
    }
  }
  memset(value, 0, sizeof(value));


#if 0
  if(0 == _gSys_Info_Show_Idx){
    sysinfo_update_all();
    debug_print(DEBUG_MODEL_SYSINFO, "\n==============================\n");
    debug_print(DEBUG_MODEL_SYSINFO, "\nHost Name:\n%s\n", _gSys_Info.host_name);

    if(_gSys_Info.nic_1_enable)
      debug_print(DEBUG_MODEL_SYSINFO, "\nWAN IP:\n%s\n", _gSys_Info.nic_1_ip);

    if(_gSys_Info.nic_2_enable)
      debug_print(DEBUG_MODEL_SYSINFO, "\nLAN IP:\n%s\n", _gSys_Info.nic_2_ip);

    switch(_gSys_Info.link_mode){
      case LINK_MODE_ACTBKP:
      case LINK_MODE_8023AD:
      case LINK_MODE_LBRR:
#ifdef __WISHLIST_LINK_AGGREGAGTION_2009__
      case LINK_MODE_LBXOR:
      case LINK_MODE_LBTLB:
      case LINK_MODE_LBALB:
#endif  //__WISHLIST_LINK_AGGREGAGTION_2009__
      case LINK_MODE_NONE:
        search_tabbyid(_g8023ad_Display_Table, _gSys_Info.link_mode, &vLinkType);
        debug_print(DEBUG_MODEL_SYSINFO, "\nLink Aggr:\n%s\n", vLinkType);
        break;
      default:
        debug_print(DEBUG_MODEL_SYSINFO, "\nLink Aggr:\n%s\n", "N/A");
        break;
    }

    if(_gSys_Info.cpu_fan_enable){
      if(FAN_STATE_OK == _gSys_Info.cpu_fan_state)
        debug_print(DEBUG_MODEL_SYSINFO, "\nCPU Fan:\n%s\n", "OK");
      else
        debug_print(DEBUG_MODEL_SYSINFO, "\nCPU Fan:\n%s\n", "Failed");
    }

    if(_gSys_Info.sys_fan_1_enable){
      if(FAN_STATE_OK == _gSys_Info.sys_fan_1_state)
        debug_print(DEBUG_MODEL_SYSINFO, "\nSYS Fan:\n%s\n", "OK");
      else
        debug_print(DEBUG_MODEL_SYSINFO, "\nSYS Fan:\n%s\n", "Failed");
    }

    if(_gSys_Info.sys_fan_2_enable){
      if(FAN_STATE_OK == _gSys_Info.sys_fan_2_state)
        debug_print(DEBUG_MODEL_SYSINFO, "\nSYS Fan 2:\n%s\n", "OK");
      else
        debug_print(DEBUG_MODEL_SYSINFO, "\nSYS Fan 2:\n%s\n", "Failed");
    }

    vTime = time(NULL);
    strftime(vBuff, sizeof(vBuff), "%H:%M:%S %Y/%m/%d", localtime(&vTime));
    debug_print(DEBUG_MODEL_SYSINFO, "\nThecus NAS\n%s\n", vBuff);
#ifdef SYSINFO_DISK_INFO_ENABLE
    debug_print(DEBUG_MODEL_SYSINFO, "\nDisk Info\n[%s]\n", _gSys_Info.disk_info);
#endif

    if(_gSys_Info.raid_num > 0){
      for(i = 0; i < _gSys_Info.raid_num; i++){
        debug_print(DEBUG_MODEL_SYSINFO, "\nRAID [%s]\n[%s]%s\n", _gSys_Info.raid_info[i].disk_tray, _gSys_Info.raid_info[i].disk_level, _gSys_Info.raid_info[i].disk_status);
      }
    }else{
      debug_print(DEBUG_MODEL_SYSINFO, "\nRAID\nNONE\n");
    }

    debug_print(DEBUG_MODEL_SYSINFO, "\n==============================\n");
  }
#endif

  //vNewItemIdx=(_gSys_Info_Show_Idx+offset+((_gSys_Info.raid_num == 0) ? 0 : _gSys_Info.raid_num - 1)+SYSINFO_MAX)%(((_gSys_Info.raid_num == 0) ? 0 : _gSys_Info.raid_num - 1)+SYSINFO_MAX);
  vNewItemIdx=(_gSys_Info_Show_Idx+offset+SYSINFO_MAX+1)%(SYSINFO_MAX+1);
  debug_print(DEBUG_MODEL_SYSINFO, "%d, %d, %d\n", _gSys_Info_Show_Idx, offset, vNewItemIdx);
  if(offset == 1){
    if(vNewItemIdx > SYSINFO_RAID_USAGE_INFO)
      if(_gSys_Info.raid_num > _gSys_Info_Raid_Idx+1){
        _gSys_Info_Raid_Idx ++;
        vNewItemIdx = SYSINFO_RAID_INFO;
      }else{
        vNewItemIdx = 0;
        _gSys_Info_Raid_Idx = 0;
      }
  }

  if(offset == -1){
    if(vNewItemIdx == SYSINFO_RAID_USAGE_INFO - 2)//from SYSINFO_RAID_INFO10
      if(_gSys_Info_Raid_Idx >= 1){
        vNewItemIdx = SYSINFO_RAID_USAGE_INFO;
        _gSys_Info_Raid_Idx --;
      }else
        vNewItemIdx = SYSINFO_RAID_INFO-1;

    if(vNewItemIdx == SYSINFO_RAID_USAGE_INFO - 1){//from SYSINFO_RAID_USAGE_INFO
      if(_gSys_Info.raid_num > 0)
        vNewItemIdx = SYSINFO_RAID_INFO;
      else
        vNewItemIdx = SYSINFO_RAID_INFO-1;
    }
    
    if(vNewItemIdx == SYSINFO_MAX){//from SYSINFO_HOST_NAME
      _gSys_Info_Raid_Idx = _gSys_Info.raid_num -1;
      if(_gSys_Info.raid_num > 0)
        vNewItemIdx = SYSINFO_RAID_USAGE_INFO;
      else
        vNewItemIdx = SYSINFO_RAID_INFO;
    }
  }

  debug_print(DEBUG_MODEL_SYSINFO, "%d, %d, %d, %d, %d\n", _gSys_Info.raid_num, _gSys_Info_Raid_Idx, SYSINFO_MAX, vNewItemIdx, offset);

  do{
    switch(vNewItemIdx){
      case SYSINFO_WAN_IP:
        vOffSet = (0 == _gSys_Info.nic_1_enable) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_LAN_IP:
        vOffSet = (0 == _gSys_Info.nic_2_enable || LINK_MODE_NONE != _gSys_Info.link_mode) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_CPU_FAN:
        vOffSet = (0 == _gSys_Info.cpu_fan_enable) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_SYS_FAN_1:
        vOffSet = (0 == _gSys_Info.sys_fan_1_enable) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_SYS_FAN_2:
        vOffSet = (0 == _gSys_Info.sys_fan_2_enable) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_SYS_FAN_3:
        vOffSet = (0 == _gSys_Info.sys_fan_3_enable) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_SYS_FAN_4:
        vOffSet = (0 == _gSys_Info.sys_fan_4_enable) ? (offset < 0) ? -1 : 1 : 0;
        break;
      case SYSINFO_BATTERY:
        sysinfo_update_battery();
        vOffSet = (0 == _gSys_Info.battery_state) ? (offset < 0) ? -1 : 1 : 0;
        break;
      default:
        vOffSet=0;
        break;
    }
    vNewItemIdx += vOffSet;
  }while(vOffSet !=0);
  debug_print(DEBUG_MODEL_SYSINFO, "%d\n", vNewItemIdx);


  switch(vNewItemIdx){
    case SYSINFO_HOST_NAME:
      sysinfo_update_hostname();
      sysinfo_update_language(FALSE);
      break;
    case SYSINFO_WAN_IP:
    case SYSINFO_LAN_IP:
    case SYSINFO_LINK_AGGR:
      if(_gSys_Info_Show_Idx != SYSINFO_WAN_IP && _gSys_Info_Show_Idx != SYSINFO_LAN_IP && _gSys_Info_Show_Idx != SYSINFO_LINK_AGGR)
      sysinfo_update_all_nic();
      break;
    case SYSINFO_CPU_FAN:
    case SYSINFO_SYS_FAN_1:
    case SYSINFO_SYS_FAN_2:
    case SYSINFO_SYS_FAN_3:
    case SYSINFO_SYS_FAN_4:
      if(_gSys_Info_Show_Idx != SYSINFO_CPU_FAN && _gSys_Info_Show_Idx != SYSINFO_SYS_FAN_1 && _gSys_Info_Show_Idx != SYSINFO_SYS_FAN_2 && _gSys_Info_Show_Idx != SYSINFO_SYS_FAN_3 && _gSys_Info_Show_Idx != SYSINFO_SYS_FAN_4 )
      sysinfo_update_fan();
      break;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
    case SYSINFO_BATTERY:
      sysinfo_update_battery();
      break;
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
#ifdef SYSINFO_DISK_INFO_ENABLE
    case SYSINFO_DISK_INFO:
      break;
#endif
    case SYSINFO_RAID_INFO:
    case SYSINFO_RAID_INFO2:
    case SYSINFO_RAID_INFO3:
    case SYSINFO_RAID_INFO4:
    case SYSINFO_RAID_INFO5:
    case SYSINFO_RAID_INFO6:
    case SYSINFO_RAID_INFO7:
    case SYSINFO_RAID_INFO8:
    case SYSINFO_RAID_INFO9:
    case SYSINFO_RAID_INF10:
    case SYSINFO_RAID_USAGE_INFO:
      if(_gSys_Info_Show_Idx < SYSINFO_RAID_INFO || _gSys_Info_Show_Idx > SYSINFO_RAID_USAGE_INFO - 1)
        sysinfo_update_raid_status();
      break;
    default:
      break;
  }

  _gSys_Info_Show_Idx = vNewItemIdx;
  vMenu_Data.title_id=99;

  switch(_gSys_Info_Show_Idx){
    case SYSINFO_HOST_NAME:
      vMenu_Data.mid_id=31;
      vMenu_Data.bottom_str=_gSys_Info.host_name;
      break;
    case SYSINFO_WAN_IP:
      if(strlen((const char *)_gSys_Info.nic_1_ip) == 0)
        vMenu_Data.bottom_str="No Link";
      else
        vMenu_Data.bottom_str=_gSys_Info.nic_1_ip;

      vMenu_Data.mid_id=84;
      break;
    case SYSINFO_LAN_IP:
      if(strlen((const char *)_gSys_Info.nic_2_ip) == 0)
        vMenu_Data.bottom_str="No Link";
      else
        vMenu_Data.bottom_str=_gSys_Info.nic_2_ip;

      vMenu_Data.mid_id=36;
      break;
    case SYSINFO_LINK_AGGR:
      vMenu_Data.mid_id=42;

      switch(_gSys_Info.link_mode){
        case LINK_MODE_ACTBKP:
        case LINK_MODE_8023AD:
        case LINK_MODE_LBRR:
#ifdef __WISHLIST_LINK_AGGREGAGTION_2009__
        case LINK_MODE_LBXOR:
        case LINK_MODE_LBTLB:
        case LINK_MODE_LBALB:
#endif  //__WISHLIST_LINK_AGGREGAGTION_2009__
        case LINK_MODE_NONE:
          search_tabbyid(_g8023ad_Display_Table, _gSys_Info.link_mode, &vLinkType);
          vMenu_Data.bottom_str=vLinkType;
          break;
        default:
          vMenu_Data.bottom_str="N/A";
          break;
      }
      break;
    case SYSINFO_CPU_FAN:
      vMenu_Data.mid_id=10;
      if(FAN_STATE_OK == _gSys_Info.cpu_fan_state)
        vMenu_Data.bottom_str="OK";
      else
        vMenu_Data.bottom_str="Failed";
      break;
    case SYSINFO_SYS_FAN_1:
      vMenu_Data.mid_id=76;
      vMenu_Data.mid_str=" 1";
      if(FAN_STATE_OK == _gSys_Info.sys_fan_1_state)
        vMenu_Data.bottom_str="OK";
      else
        vMenu_Data.bottom_str="Failed";
      break;
    case SYSINFO_SYS_FAN_2:
      vMenu_Data.mid_id=76;
      vMenu_Data.mid_str=" 2";
      if(FAN_STATE_OK == _gSys_Info.sys_fan_2_state)
        vMenu_Data.bottom_str="OK";
      else
        vMenu_Data.bottom_str="Failed";
      break;
    case SYSINFO_SYS_FAN_3:
      vMenu_Data.mid_id=76;
      vMenu_Data.mid_str=" 3";
      if(FAN_STATE_OK == _gSys_Info.sys_fan_3_state)
        vMenu_Data.bottom_str="OK";
      else
        vMenu_Data.bottom_str="Failed";
      break;
    case SYSINFO_SYS_FAN_4:
      vMenu_Data.mid_id=76;
      vMenu_Data.mid_str=" 4";
      if(FAN_STATE_OK == _gSys_Info.sys_fan_4_state)
        vMenu_Data.bottom_str="OK";
      else
        vMenu_Data.bottom_str="Failed";
      break;
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
    case SYSINFO_BATTERY:
      vMenu_Data.mid_id=101;
      switch(_gSys_Info.battery_state){
        case BATTERY_LOW:
          vMenu_Data.bottom_bmp=16;
          break;
        case BATTERY_CHARGING:
          vMenu_Data.bottom_bmp=14;
          break;
        default:
          vMenu_Data.bottom_bmp=15;
          break;
      }
      break;
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
    /*        case SYSINFO_SYS_FAN_2:
    {
    vMenu_Data.mid_id=76;

    if(FAN_STATE_OK == _gSys_Info.sys_fan_2_state)
    vMenu_Data.bottom_str="OK";
    else
    vMenu_Data.bottom_str="Failed";
    }
    break;
    */
    case SYSINFO_DATE:
      vMenu_Data.mid_str=_gSys_Info.host_name;
      memset(vBuff, 0, sizeof(vBuff));
      vTime = time(NULL);
      strftime(vBuff, sizeof(vBuff), "%H:%M:%S %Y/%m/%d", localtime(&vTime));
      vMenu_Data.bottom_str=vBuff;
      break;
#ifdef SYSINFO_DISK_INFO_ENABLE
    case SYSINFO_DISK_INFO:
      memset(vBuff, 0, sizeof(vBuff));
      vMenu_Data.mid_id=15;
      sprintf(vBuff, "[%s]", _gSys_Info.disk_info);
      vMenu_Data.bottom_str=vBuff;
      break;
#endif
    case SYSINFO_RAID_INFO:
    case SYSINFO_RAID_INFO2:
    case SYSINFO_RAID_INFO3:
    case SYSINFO_RAID_INFO4:
    case SYSINFO_RAID_INFO5:
    case SYSINFO_RAID_INFO6:
    case SYSINFO_RAID_INFO7:
    case SYSINFO_RAID_INFO8:
    case SYSINFO_RAID_INFO9:
    case SYSINFO_RAID_INF10:
      if(_gSys_Info.raid_num > 0){
        memset(vBuff, 0, sizeof(vBuff));
        memset(vBuff1, 0, sizeof(vBuff1));
        memset(vBuff2, 0, sizeof(vBuff2));
        debug_print(DEBUG_MODEL_SYSINFO, "_gSys_Info_Raid_Idx %d\n", _gSys_Info_Raid_Idx);
        if(_gSys_Info_Show_Idx == SYSINFO_RAID_INFO)
          sprintf(vBuff, "%s [%s]", _gSys_Info.raid_info[_gSys_Info_Raid_Idx].id, _gSys_Info.raid_info[_gSys_Info_Raid_Idx].disk_tray);
        else
          sprintf(vBuff, "-> %s [%s", _gSys_Info.raid_info[_gSys_Info_Raid_Idx].id, _gSys_Info.raid_info[_gSys_Info_Raid_Idx].disk_tray);
          
        strncpy(vBuff1,vBuff,21);
        vMenu_Data.mid_str=vBuff1;

        char * mid_str_next="\0";
        if (strlen(vBuff) > 21){
          mid_str_next=vBuff+21;
        }
        
        sprintf(vBuff2, "%s [%s]%s", mid_str_next, _gSys_Info.raid_info[_gSys_Info_Raid_Idx].disk_level, _gSys_Info.raid_info[_gSys_Info_Raid_Idx].disk_status);
        if (strlen(vBuff2) > 21){
          if (strlen(mid_str_next) > 21){
            strncpy(vBuff3,mid_str_next,17);
            sprintf(vBuff2, "%s] ->", vBuff3);
            mid_str_next+=17;
            sprintf(_gSys_Info.raid_info[_gSys_Info_Raid_Idx].disk_tray, "%s", mid_str_next);
          }else{
            sprintf(vBuff2, "%s", mid_str_next);
            sprintf(_gSys_Info.raid_info[_gSys_Info_Raid_Idx].disk_tray, "]");
          }
        }else
          _gSys_Info_Show_Idx = SYSINFO_RAID_USAGE_INFO - 1;

        vMenu_Data.bottom_str=vBuff2;
        debug_print(DEBUG_MODEL_SYSINFO, "%s -%d\n", vBuff1, strlen(vBuff1));
        debug_print(DEBUG_MODEL_SYSINFO, "%s -%d\n", vBuff2, strlen(vBuff2));
      }else{
        vMenu_Data.mid_str="RAID";
        vMenu_Data.bottom_str="NONE";
        _gSys_Info_Show_Idx = SYSINFO_RAID_USAGE_INFO;
      }
      break;
    case SYSINFO_RAID_USAGE_INFO:
#ifdef __WISH_LIST_ROTATE_NEW_INFO__
      sprintf(vBuff, "%s", _gSys_Info.raid_info[_gSys_Info_Raid_Idx].id);
      vMenu_Data.mid_str=vBuff;
      debug_print(DEBUG_MODEL_SYSINFO, "=====================RAID %d \n", _gSys_Info_Raid_Idx);

      sprintf(vBuff2, "/raidsys/%d/ha_raid", _gSys_Info_Raid_Idx);
      if(stat(vBuff2,&hast) == 0){
        vMenu_Data.bottom_str="Used for HA";
      }else{
        vMenu_Data.bottom_id=109;
        vMenu_Data.bottom_str=NULL;
        vMenu_Data.usage=_gSys_Info.raid_info[_gSys_Info_Raid_Idx].usage;
      }
#endif  // __WISH_LIST_ROTATE_NEW_INFO__
      break;
    default:
      break;
  }
  Mdump(DEBUG_MODEL_SYSINFO, "Menu_data : ", &vMenu_Data, sizeof(vMenu_Data));
  show_screen(SCR_TEMPLATE_08, &vMenu_Data);
  return 0;
}

static int32_t _sysinfo_get_mbtype()
{
    char vRetMsg[PIPE_CMD_BUF]={0};
    char *vPipCmd="awk '/^MBTYPE/{print $2}' /proc/thecus_io";

    shell_pipe_cmd(vPipCmd,vRetMsg,sizeof(vRetMsg));
    _gSys_Info.mb_type = atoi(vRetMsg);

    return 0;
}

int32_t sysinfo_update_init(void)
{
    char value[PIPE_CMD_BUF] = {0};
    char vPipeCmd[PIPE_CMD_BUF]={0};
    char *vCheckFanCmd="/img/bin/check_service.sh %s";
    uint8_t vId=0;
    int32_t vRet=0;
    int8_t db_Enable=0;
    _gSys_Info_Show_Idx=0;
    _gSys_Info_Raid_Idx=0;
    _sysinfo_get_mbtype();
    sysinfo_update_switchboard();

    //  get nic 1 enable
    if(_gNewLANCheck == 1)
    {
	    if( conf_db_select(KEY_WAN_ENABLE_IPV4, "conf", value) >= 0 )
		 db_Enable =1;
    }else
    {
	    if( conf_db_select(KEY_WAN_ENABLE, "conf", value) >= 0 )
	        db_Enable =1;
    }

    if(db_Enable ==1)
    {
        if( value[0] == '1' )
            _gSys_Info.nic_1_enable = 1;
        else
            _gSys_Info.nic_1_enable = 0;
    }
    memset(value, 0, sizeof(value));

    //  get nic 2 enable
    db_Enable =0;
    if(_gNewLANCheck == 1)
    {
	    if( conf_db_select(KEY_LAN_ENABLE_IPV4, "conf", value) >= 0 )
		 db_Enable =1;
    }else
    {
	    if( conf_db_select(KEY_LAN_ENABLE, "conf", value) >= 0 )
	        db_Enable =1;
    }    
    if( db_Enable == 1 )
    {
        if( value[0] == '1' )
            _gSys_Info.nic_2_enable = 1;
        else
            _gSys_Info.nic_2_enable = 0;
    }
    memset(value, 0, sizeof(value));

    //  get cpu fan enable
    sprintf(vPipeCmd, vCheckFanCmd, "cpu_fan1");
    shell_pipe_cmd(vPipeCmd,value,sizeof(value));

    if( value[0] == '1' )
        _gSys_Info.cpu_fan_enable = 1;
    else
        _gSys_Info.cpu_fan_enable = 0;
    memset(vPipeCmd, 0, sizeof(vPipeCmd));

    //  get sys fan 1 enable
    sprintf(vPipeCmd, vCheckFanCmd, "sys_fan1");
    shell_pipe_cmd(vPipeCmd,value,sizeof(value));

    if( value[0] == '0' ){
        _gSys_Info.sys_fan_1_enable = 0;
        _gSys_Info.sys_fan_2_enable = 0;
        _gSys_Info.sys_fan_3_enable = 0;
        _gSys_Info.sys_fan_4_enable = 0;
    }else{
	if (value[0] == '1'){
	    _gSys_Info.sys_fan_1_enable = 1;
            _gSys_Info.sys_fan_2_enable = 0;
            _gSys_Info.sys_fan_3_enable = 0;
            _gSys_Info.sys_fan_4_enable = 0;
	}else if(value[0] == '2'){
	    _gSys_Info.sys_fan_1_enable = 1;
	    _gSys_Info.sys_fan_2_enable = 1;
            _gSys_Info.sys_fan_3_enable = 0;
            _gSys_Info.sys_fan_4_enable = 0;
	}else if(value[0] == '3'){
	    _gSys_Info.sys_fan_1_enable = 1;
	    _gSys_Info.sys_fan_2_enable = 1;
	    _gSys_Info.sys_fan_3_enable = 1;
            _gSys_Info.sys_fan_4_enable = 0;
	}else if(value[0] == '4'){
	    _gSys_Info.sys_fan_1_enable = 1;
	    _gSys_Info.sys_fan_2_enable = 1;
	    _gSys_Info.sys_fan_3_enable = 1;
	    _gSys_Info.sys_fan_4_enable = 1;
	}
    }
    memset(vPipeCmd, 0, sizeof(vPipeCmd));

    //  get sys fan 2 enable
/*    sprintf(vPipeCmd, vCheckFanCmd, "sys_fan2");
    shell_pipe_cmd(vPipeCmd,value,sizeof(value));

    if( value[0] == '1' )
        _gSys_Info.sys_fan_2_enable = 1;
    else
        _gSys_Info.sys_fan_2_enable = 0;
*/
    //  get system language
    sysinfo_update_language(TRUE);

    if( conf_db_select(KEY_BEEP, "conf", value) >= 0 )
    {

        if( value[0] == '1' )
            sysinfo_set_alarm(1, 0);
        else
            sysinfo_set_alarm(0, 0);
    }
    memset(value, 0, sizeof(value));

    return 0;
}

int32_t sysinfo_update_hostname(void)
{
    IN(DEBUG_MODEL_SYSINFO, "");
    return conf_db_select("nic1_hostname", "conf", (int8_t *)_gSys_Info.host_name);
}

int32_t sysinfo_get_nic_info(char* nic_name, char *out_ip, char *out_netmask)
{
    char vPipeCmd[PIPE_CMD_BUF]={0};
    char vNicName[10]={0};
    char *vNicCmd="ifconfig %s | grep 'inet addr' | cut -d ':' -f %d | cut -d ' ' -f 1";
    
    IN(DEBUG_MODEL_SYSINFO, "");
    if(NULL == nic_name)
        return -1;

    if(_gNewLANCheck == 1)
    {
        sprintf(vPipeCmd, "/img/bin/function/get_interface_info.sh check_eth_bond %s", nic_name);
        shell_pipe_cmd(vPipeCmd, vNicName, 10);
        memset(vPipeCmd, 0, sizeof(vPipeCmd));
    }

    if(strlen(vNicName)<=0)
        memcpy(vNicName,nic_name,sizeof(nic_name));
    if(out_ip)
    {
        memset(out_ip, 0, sizeof(out_ip));
        sprintf(vPipeCmd, vNicCmd, vNicName, 2);
        shell_pipe_cmd(vPipeCmd, out_ip, 16);
        memset(vPipeCmd, 0, sizeof(vPipeCmd));
    }

    if(out_netmask)
    {
        sprintf(vPipeCmd, vNicCmd, vNicName, 4);
        shell_pipe_cmd(vPipeCmd, out_netmask, 16);
        memset(vPipeCmd, 0, sizeof(vPipeCmd));
    }
    OUT(DEBUG_MODEL_SYSINFO, "");
    return 0;
}

int32_t sysinfo_update_switchboard(void)
{
    char vRetMsg[PIPE_CMD_BUF]={0};
    char *switch_board_cmd = "cat /proc/thecus_io | grep \"Switch\" | cut -f2 -d':'";

    IN(DEBUG_MODEL_SYSINFO, "");
    shell_pipe_cmd(switch_board_cmd, vRetMsg, sizeof(vRetMsg));

    if( strncmp( " Yes" , vRetMsg , strlen(" Yes") ) == 0 )
    {
            _gSys_Info.have_swtich_board = 1;
    }
    else
    {
            _gSys_Info.have_swtich_board = 0;
    }

    OUT(DEBUG_MODEL_SYSINFO, "");
    return 0;
}

int32_t sysinfo_update_all_nic(void)
{
    char value[PIPE_CMD_BUF] = {0};
    int8_t db_Enable=0;
    IN(DEBUG_MODEL_SYSINFO, "");


    if(_gNewLANCheck == 1)
    {
	    if( conf_db_select(KEY_WAN_DHCP_IPV4, "conf", value) >= 0 )
		 db_Enable =1;
    }else
    {
	    if( conf_db_select(KEY_WAN_DHCP, "conf", value) >= 0 )
	        db_Enable =1;
    }
    if( db_Enable ==1 )
    {
        if( value[0] == '1' )
            sysinfo_set_nic1_dhcp(1, 0);
        else
            sysinfo_set_nic1_dhcp(0, 0);
    }
    memset(value, 0, sizeof(value));

    if( conf_db_select(KEY_8023AD, "conf", value) >= 0 )
    {
        uint8_t vMode=LINK_MODE_NONE;

        if(6 <= _gPicVersion)
            search_tab(_g8023ad_Table, value, &vMode);
        else
            search_tab(_g8023ad_Table_old, value, &vMode);
        sysinfo_set_linkaggr(vMode, 0);
    }
    memset(value, 0, sizeof(value));

    //sysinfo_update_switchboard();

    //  get wan ip and netmask
    if(1 == _gSys_Info.nic_1_enable)
    {
         if(_gNewLANCheck != 1)
         {
	        if((_gSys_Info.nic_1_dhcp_enable == TRUE) || ( _gSys_Info.link_mode == LINK_MODE_NONE))
	        {
	            sysinfo_get_nic_info(_gNic_1_Name, _gSys_Info.nic_1_ip, _gSys_Info.nic_1_netmask);
	        }
	        else
	        {
	            sysinfo_get_nic_info("bond0", _gSys_Info.nic_1_ip, _gSys_Info.nic_1_netmask);

	            if(strlen(_gSys_Info.nic_1_ip) <= 0)
	                sysinfo_get_nic_info(_gNic_1_Name, _gSys_Info.nic_1_ip, _gSys_Info.nic_1_netmask);
	        }

         }else
         {
		sysinfo_get_nic_info(_gNic_1_Name, _gSys_Info.nic_1_ip, _gSys_Info.nic_1_netmask);
         }
    }

//  get lan ip and netmask
    if(1 == _gSys_Info.nic_2_enable)
        sysinfo_get_nic_info(_gNic_2_Name, _gSys_Info.nic_2_ip, _gSys_Info.nic_2_netmask);

    OUT(DEBUG_MODEL_SYSINFO, "");
    return 0;
}

int32_t sysinfo_update_fan(void)
{
    char vPipeCmd[PIPE_CMD_BUF]={0};
    char vRetMsg[PIPE_CMD_BUF]={0};
    char *vCmd_cpu="awk '/^CPU_FAN RPM:/{print $3}' /proc/hwm";
    char *vCmd="awk '/^HDD_FAN%d RPM:/{print $3}' /proc/hwm";

    IN(DEBUG_MODEL_SYSINFO, "");

    //if(MB_TYPE_N4200 == _gSys_Info.mb_type)
    if (1)
    {
        shell_pipe_cmd(vCmd_cpu,vRetMsg,sizeof(vRetMsg));

        if(strlen(vRetMsg) > 0 && atoi(vRetMsg) > 0)
            _gSys_Info.cpu_fan_state=FAN_STATE_OK;
        else
            _gSys_Info.cpu_fan_state=FAN_STATE_FAIL;

        memset(vPipeCmd, 0, sizeof(vPipeCmd));
        memset(vRetMsg, 0, sizeof(vRetMsg));
        sprintf(vPipeCmd, vCmd, 1);
        shell_pipe_cmd(vPipeCmd,vRetMsg,sizeof(vRetMsg));

        if(strlen(vRetMsg) > 0 && atoi(vRetMsg) > 0)
            _gSys_Info.sys_fan_1_state=FAN_STATE_OK;
        else
            _gSys_Info.sys_fan_1_state=FAN_STATE_FAIL;

        memset(vPipeCmd, 0, sizeof(vPipeCmd));
        memset(vRetMsg, 0, sizeof(vRetMsg));
        sprintf(vPipeCmd, vCmd, 2);
        shell_pipe_cmd(vPipeCmd,vRetMsg,sizeof(vRetMsg));

        if(strlen(vRetMsg) > 0 && atoi(vRetMsg) > 0)
            _gSys_Info.sys_fan_2_state=FAN_STATE_OK;
        else
            _gSys_Info.sys_fan_2_state=FAN_STATE_FAIL;

        memset(vPipeCmd, 0, sizeof(vPipeCmd));
        memset(vRetMsg, 0, sizeof(vRetMsg));
        sprintf(vPipeCmd, vCmd, 3);
        shell_pipe_cmd(vPipeCmd,vRetMsg,sizeof(vRetMsg));

        if(strlen(vRetMsg) > 0 && atoi(vRetMsg) > 0)
            _gSys_Info.sys_fan_3_state=FAN_STATE_OK;
        else
            _gSys_Info.sys_fan_3_state=FAN_STATE_FAIL;

        memset(vPipeCmd, 0, sizeof(vPipeCmd));
        memset(vRetMsg, 0, sizeof(vRetMsg));
        sprintf(vPipeCmd, vCmd, 4);
        shell_pipe_cmd(vPipeCmd,vRetMsg,sizeof(vRetMsg));

        if(strlen(vRetMsg) > 0 && atoi(vRetMsg) > 0)
            _gSys_Info.sys_fan_4_state=FAN_STATE_OK;
        else
            _gSys_Info.sys_fan_4_state=FAN_STATE_FAIL;

    }
    return 0;
}

int32_t sysinfo_update_battery(void)
{
    char vRetMsg[PIPE_CMD_BUF]={0};
    char *vCmd="cat /var/tmp/power/bat_flag2";

    IN(DEBUG_MODEL_SYSINFO, "");

    if(access("/var/tmp/power/bat_flag2", F_OK) == -1)
    {
        debug_print(DEBUG_MODEL_SYSINFO, "Battery flag file not exist! \n");
        _gSys_Info.battery_state=BATTERY_NOT_EXIST;
    }
    else
    {
        shell_pipe_cmd(vCmd,vRetMsg,sizeof(vRetMsg));

        switch(vRetMsg[0])
        {
            case '1':
                _gSys_Info.battery_state=BATTERY_LOW;
            break;
            case '2':
                _gSys_Info.battery_state=BATTERY_GOOD;
            break;
            case '3':
                _gSys_Info.battery_state=BATTERY_CHARGING;
            break;
            default:
                _gSys_Info.battery_state=BATTERY_NOT_EXIST;
            break;
        }

    }

    IN(DEBUG_MODEL_SYSINFO, "battery_state %d", _gSys_Info.battery_state);

    return 0;
}

#ifdef SYSINFO_DISK_INFO_ENABLE
int32_t sysinfo_update_disk_info(void)
{
    char vPipeCmd[PIPE_CMD_BUF]={0};
    char vRetMsg[PIPE_CMD_BUF]={0};
    char vTrayList[PIPE_CMD_BUF]={0};
    char *vTotalTrayCmd="/img/bin/check_service.sh 'total_tray'";
    char *vTrayCmd = "cat /proc/scsi/scsi |grep 'Thecus: Tray:'|cut -f3 -d':'|cut -f1 -d' '";
    int8_t *vTmpStrStart=NULL;
    int8_t *vTmpStrP=NULL;
    unsigned char vTotalTrayCount=0;
    unsigned char vStrLen=0;
    unsigned char i=0;

    IN(DEBUG_MODEL_SYSINFO, "");

    shell_pipe_cmd(vTotalTrayCmd, vRetMsg, sizeof(vRetMsg));
    vTotalTrayCount=atoi(vRetMsg);

    if(0 == vTotalTrayCount)
        return -1;

    for(i=0; i<33; i++)
    {
        if(i < vTotalTrayCount)
            _gSys_Info.disk_info[i] = '_';
        else
            _gSys_Info.disk_info[i] = 0;
    }

    shell_pipe_cmd_multiline(vTrayCmd,vTrayList,sizeof(vTrayList));
    vTmpStrP = vTrayList;

    do
    {
        vTmpStrStart = vTmpStrP;
        para_parser(vTmpStrStart, &vTmpStrP, strlen(vTmpStrStart));

        if(strlen(vTmpStrStart) > 0)
        {
            int vDiskNo = 0;

            vDiskNo = atoi(vTmpStrStart);

            if(vDiskNo <= vTotalTrayCount && vDiskNo > 0)
            {
                _gSys_Info.disk_info[vDiskNo-1] = 'O';
            }
        }
    } while(strlen(vTmpStrP) > 0);

    memset(vTrayList, 0, sizeof(vTrayList));
    shell_pipe_cmd_multiline(vTrayCmd,vTrayList,sizeof(vTrayList));
    vStrLen=strlen(vTrayList);
    vTmpStrP = vTrayList;

    if(0 == vStrLen)
    {
        char *vTrayCmd2 = "ls /tmp/TRAY* -d | tr -d '/tmp/TRAY'";

        memset(vTrayList, 0, sizeof(vTrayList));
        shell_pipe_cmd_multiline(vTrayCmd2, vTrayList, sizeof(vTrayList));
        vStrLen=strlen(vTrayList);
        vTmpStrP = vTrayList;
    }

    do
    {
        vTmpStrStart = vTmpStrP;
        para_parser(vTmpStrStart, &vTmpStrP, strlen(vTmpStrStart));

        if(strlen(vTmpStrStart) > 0)
        {
            int vDiskNo = 0;

            vDiskNo = atoi(vTmpStrStart);

            if(vDiskNo <= vTotalTrayCount && vDiskNo > 0)
            {
                memset(vRetMsg, 0, sizeof(vRetMsg));
                memset(vPipeCmd, 0, sizeof(vPipeCmd));
                sprintf(vPipeCmd, "test -e /tmp/TRAY%d;echo $?", vDiskNo);
                shell_pipe_cmd(vPipeCmd, vRetMsg, sizeof(vRetMsg));

                if(0 == atoi(vRetMsg))
                {
                    memset(vRetMsg, 0, sizeof(vRetMsg));
                    memset(vPipeCmd, 0, sizeof(vPipeCmd));
                    sprintf(vPipeCmd, "cat /tmp/TRAY%d", vDiskNo);
                    shell_pipe_cmd(vPipeCmd, vRetMsg, sizeof(vRetMsg));

                    if(strlen(vRetMsg) > 0)
                        _gSys_Info.disk_info[vDiskNo-1] = 'X';
                }
            }
        }
    } while(strlen(vTmpStrP) > 0);

    OUT(DEBUG_MODEL_SYSINFO, "");
    return 0;
}
#endif

int32_t sysinfo_update_raid_status(void)
{
  char vPipeCmd[PIPE_CMD_BUF]={0};
  char vRetMsg[PIPE_CMD_BUF]={0};
  char vTmpFileName[PIPE_CMD_BUF]={0};
  char vRaidList[PIPE_CMD_BUF*2]={0};
  char *vRaidListCmd="ls /var/tmp/raid? -d";
  char *vTotalTrayCmd="/img/bin/check_service.sh 'total_tray'";
  char *vTmpStrStart=NULL;
  char *vTmpStrP=NULL;
  char i=0;
  unsigned char vTotalTrayCount=0;
  unsigned char vRaidIndex=0;
  unsigned int vStrLen=0;


  IN(DEBUG_MODEL_SYSINFO, "");

  memset(_gSys_Info.raid_info, 0, sizeof(_gSys_Info.raid_info));

  shell_pipe_cmd(vTotalTrayCmd, vRetMsg, sizeof(vRetMsg));
  vTotalTrayCount=atoi(vRetMsg);
  //  get list of RAID
  memset(vRaidList, 0, sizeof(vRaidList));
  shell_pipe_cmd_multiline(vRaidListCmd, vRaidList, sizeof(vRaidList));
  vStrLen = strlen(vRaidList);
  vTmpStrP = vRaidList;

  //  process list of RAID
  while(strlen(vTmpStrP) > 0){
    uint8_t *vTmpFolerName=NULL;

    vTmpFolerName = vTmpStrStart = vTmpStrP;
    para_parser((int8_t *)vTmpStrStart, (int8_t **)&vTmpStrP, strlen(vTmpStrStart));

    for(i=0; i<3; i++){
      vTmpFolerName = strchr(vTmpFolerName, '/') + 1;
    }

    debug_print(DEBUG_MODEL_SYSINFO, "folder name %s\n", vTmpFolerName);

    if(vTmpFolerName[4] >= '0' && vTmpFolerName[4] <= '9'){
      char *vTmpStrStart2=NULL;
      char *vTmpStrP2=NULL;
      unsigned char i=0;
      unsigned int vStrLen2=0;

      //  get raid id
      memset(vPipeCmd, 0, sizeof(vPipeCmd));
      memset(vTmpFileName, 0, sizeof(vTmpFileName));
      sprintf(vTmpFileName, "%s/raid_id", vTmpStrStart);

      if(access(vTmpFileName, F_OK) == -1){
        debug_print(DEBUG_MODEL_SYSINFO, "!!!!name %s not exit!!!!\n", vTmpFileName);
        continue;
      }
      sprintf(vPipeCmd, "cat %s/raid_id", vTmpStrStart);
      shell_pipe_cmd(vPipeCmd, _gSys_Info.raid_info[vRaidIndex].id, sizeof(_gSys_Info.raid_info[vRaidIndex].id));

      if(0 == strlen(_gSys_Info.raid_info[vRaidIndex].id))
        sprintf(_gSys_Info.raid_info[vRaidIndex].id, "%s", vTmpFolerName);

      //  get raid level
      memset(vPipeCmd, 0, sizeof(vPipeCmd));
      memset(_gSys_Info.raid_info[vRaidIndex].disk_level, 0, sizeof(_gSys_Info.raid_info[vRaidIndex].disk_level));
      memset(vTmpFileName, 0, sizeof(vTmpFileName));
      sprintf(vTmpFileName, "%s/raid_level", vTmpStrStart);

      if(access(vTmpFileName, F_OK) == -1){
        debug_print(DEBUG_MODEL_SYSINFO, "!!!!name %s not exit!!!!\n", vTmpFileName);
        continue;
      }
      sprintf(vPipeCmd, "cat %s/raid_level", vTmpStrStart);
      shell_pipe_cmd(vPipeCmd, _gSys_Info.raid_info[vRaidIndex].disk_level, sizeof(_gSys_Info.raid_info[vRaidIndex].disk_level));

      //  get raid status
      memset(vPipeCmd, 0, sizeof(vPipeCmd));
      memset(_gSys_Info.raid_info[vRaidIndex].disk_status, 0, sizeof(_gSys_Info.raid_info[vRaidIndex].disk_status));
      memset(vTmpFileName, 0, sizeof(vTmpFileName));
      sprintf(vTmpFileName, "%s/rss", vTmpStrStart);

      if(access(vTmpFileName, F_OK) == -1){
        debug_print(DEBUG_MODEL_SYSINFO, "!!!!name %s not exit!!!!\n", vTmpFileName);
        continue;
      }
      sprintf(vPipeCmd, "cat %s/rss", vTmpStrStart);
      shell_pipe_cmd(vPipeCmd, _gSys_Info.raid_info[vRaidIndex].disk_status, sizeof(_gSys_Info.raid_info[vRaidIndex].disk_status));

      //  get raid disk
      memset(vPipeCmd, 0, sizeof(vPipeCmd));
      memset(vRetMsg, 0, sizeof(vRetMsg));
      memset(vTmpFileName, 0, sizeof(vTmpFileName));
      sprintf(vTmpFileName, "%s/disk_tray", vTmpStrStart);

      if(access(vTmpFileName, F_OK) == -1){
        debug_print(DEBUG_MODEL_SYSINFO, "!!!!name %s not exit!!!!\n", vTmpFileName);
        continue;
      }
      sprintf(vPipeCmd, "cat %s/disk_tray | tr -d '\"' | sort -g | tr -s '\n' '\t'", vTmpStrStart);
      shell_pipe_cmd(vPipeCmd, vRetMsg, sizeof(vRetMsg));

      vStrLen2 = strlen(vRetMsg);
      vTmpStrP2 = vRetMsg;
      //debug_print(DEBUG_MODEL_SYSINFO, "test start, vStrLen2=%d, vRetMsg=%s\n", vStrLen2, vRetMsg);
      memset(_gSys_Info.raid_info[vRaidIndex].disk_tray, 0, sizeof(_gSys_Info.raid_info[vRaidIndex].disk_tray));

      int vTmpTrayId=0;
      int idx=0;
      char hdd_10;
      do{
        vTmpStrStart2 = vTmpStrP2;
        para_parser(vTmpStrStart2, (int8_t **)&vTmpStrP2, strlen(vTmpStrStart2));
        vTmpTrayId = atoi(vTmpStrStart2);
        if(vTmpTrayId > 0){
          if (vTmpTrayId > 9){
            if (vTmpTrayId < 26){
              hdd_10=toascii(vTmpTrayId+55);
              strncpy(_gSys_Info.raid_info[vRaidIndex].disk_tray + idx, &hdd_10,1);
            }else{
              //Enclosure or HV disk member...
              if (vTmpTrayId > 52){
                char tmpstr[10];
                sprintf(tmpstr, ",J%c", toascii(vTmpTrayId/26+47));
                debug_print(DEBUG_MODEL_SYSINFO,"compare %s with %s\n", tmpstr, _gSys_Info.raid_info[vRaidIndex].disk_tray);
                if(idx >=2 && 0 == strncmp(_gSys_Info.raid_info[vRaidIndex].disk_tray + idx -2, tmpstr+1,2)) continue;
                if(idx == 0)
                  strncpy(_gSys_Info.raid_info[vRaidIndex].disk_tray + idx, tmpstr+1,2);
                else
                  strncpy(_gSys_Info.raid_info[vRaidIndex].disk_tray + idx, tmpstr,3);
                idx+=2;
                debug_print(DEBUG_MODEL_SYSINFO,"vTmpStrP2= %s\n", vTmpStrP2);
              }else{
                strncpy(_gSys_Info.raid_info[vRaidIndex].disk_tray + idx, "VE",2);
                break;
              }
            }
          }else
            strncpy(_gSys_Info.raid_info[vRaidIndex].disk_tray + idx, vTmpStrStart2, strlen(vTmpStrStart2));

          idx++;
        }
        
      } while(strlen(vTmpStrP2) > 0);

      //debug_print(DEBUG_MODEL_SYSINFO, "after parse, disk_tray %s\n", _gSys_Info.raid_info[vRaidIndex].disk_tray);
      //  get raid filesystem type
      memset(vRetMsg, 0, sizeof(vRetMsg));
      memset(vTmpFileName, 0, sizeof(vTmpFileName));
      sprintf(vTmpFileName, "/%s/sys/raid.db", vTmpFolerName);
      general_db_select(vTmpFileName, KEY_FILESYSTEM_TYPE, "conf", vRetMsg);

      //  get raid filesystem type
      if(0 == strcmp(vRetMsg, "zfs")){
        debug_print(DEBUG_MODEL_SYSINFO, "%s filesystem type zfs!\n", vTmpFolerName);
        memset(vPipeCmd, 0, sizeof(vPipeCmd));
        memset(vRetMsg, 0, sizeof(vRetMsg));
        sprintf(vPipeCmd, "/opt/zfs-fuse/zpool list -H `/opt/zfs-fuse/zfs list -H /%s/data| awk \'{print $1}\'` | awk '{print $5}' | tr -d '%%'", vTmpFolerName);
        shell_pipe_cmd(vPipeCmd, vRetMsg, sizeof(vRetMsg));
        debug_print(DEBUG_MODEL_SYSINFO, "data use %s%\n", vRetMsg);
        _gSys_Info.raid_info[vRaidIndex].usage=(uint8_t)atoi(vRetMsg);
      }else{
        debug_print(DEBUG_MODEL_SYSINFO, "%s filesystem type ext3/ext4/xfs!\n", vTmpFolerName);
        memset(vPipeCmd, 0, sizeof(vPipeCmd));
        memset(vRetMsg, 0, sizeof(vRetMsg));
        sprintf(vPipeCmd, "df /%s/data | grep /%s | awk '{print $5}' | tr -d '%%'", vTmpFolerName, vTmpFolerName);
        shell_pipe_cmd(vPipeCmd, vRetMsg, sizeof(vRetMsg));
        debug_print(DEBUG_MODEL_SYSINFO, "data use %s%\n", vRetMsg);
        _gSys_Info.raid_info[vRaidIndex].usage=(uint8_t)atoi(vRetMsg);
      }

      vRaidIndex++;
    }
  }

  _gSys_Info.raid_num = vRaidIndex;

  OUT(DEBUG_MODEL_SYSINFO, "raid_num %d", _gSys_Info.raid_num);

  return 0;
}

int32_t sysinfo_update_language(uint8_t init)
{
    char value[PIPE_CMD_BUF] = {0};
    uint8_t vId=0;
    int32_t vRet=0;

    IN(DEBUG_MODEL_SYSINFO, "");
    memset(value, 0, sizeof(value));

    if( conf_db_select(KEY_LANGUAGE, "conf", value) >= 0 )
    {
        vRet=search_tab((cmd_table *)_gLanguage_Table, value, &vId);

        debug_print(DEBUG_MODEL_SYSINFO, "lang \"%s\", id %d\n", value, vId);

        if(init || _gSys_Info.lang != vId)
            sysinfo_set_language(vId, 0);
    }
    else
    {
        sysinfo_set_language(LANG_ENGLISH, 0);
    }

    return 0;
}

int32_t sysinfo_update_all(void)
{
    IN(DEBUG_MODEL_SYSINFO, "");
    sysinfo_update_hostname();
    sysinfo_update_all_nic();
    sysinfo_update_fan();
    sysinfo_update_battery();
#ifdef SYSINFO_DISK_INFO_ENABLE
    sysinfo_update_disk_info();
#endif
    sysinfo_update_raid_status();
    sysinfo_update_language(FALSE);
    return 0;
}

int32_t sysinfo_set_language(uint8_t lang, uint8_t aply_to_sys)
{
    uint8_t vI2C_Data[I2C_SMBUS_BLOCK_MAX]={0};
    uint8_t *vpLang=NULL;

    IN(DEBUG_MODEL_SYSINFO, "lang id %d", lang);

    if(lang > LANG_UNKNOW && lang < LANG_MAX)
        _gSys_Info.lang = lang;
    else
        _gSys_Info.lang = LANG_ENGLISH;

    if(aply_to_sys)
    {
        search_tabbyid(_gLanguage_Table, _gSys_Info.lang, &vpLang);
        conf_db_update(KEY_LANGUAGE, "conf", vpLang);
    }
    vI2C_Data[0]=_gSys_Info.lang;
    i2c_write_block(CMD_LANGUAGE, 1, vI2C_Data);

    return 0;
}

int32_t sysinfo_set_alarm(uint8_t mode, uint8_t aply_to_sys)
{
    char vPipeCmd[PIPE_CMD_BUF]={0};
    char vRetMsg[PIPE_CMD_BUF]={0};

    IN(DEBUG_MODEL_SYSINFO, "alarm %d", mode);

    if(1 == mode)
        _gSys_Info.alarm_mute = 1;
    else
        _gSys_Info.alarm_mute = 0;

    if(0 ==  aply_to_sys)
        return 0;

    if(1 == _gSys_Info.alarm_mute)
    {
        conf_db_update(KEY_BEEP, "conf", "1");
        system("echo Buzzer 1 > /proc/thecus_io");
	sleep(3);
        system("echo Buzzer 0 > /proc/thecus_io");
    }
    else
    {
        conf_db_update(KEY_BEEP, "conf", "0");
        system("echo Buzzer 0 > /proc/thecus_io");
    }

    return 0;
}

int32_t sysinfo_set_linkaggr(uint8_t mode, uint8_t aply_to_sys)
{
    uint8_t vpSysCmd[PIPE_CMD_BUF]={0};
    uint8_t *vpCmd=NULL;
    uint8_t lanstatus;
    uint8_t wanstatus;
    int32_t ha;   
    
    IN(DEBUG_MODEL_SYSINFO, "mode %d, dhcp_enable %d", mode, _gSys_Info.nic_1_dhcp_enable);

    if(_gNewLANCheck != 1)
    {
	    if(_gSys_Info.nic_1_dhcp_enable == 1)
	        _gSys_Info.link_mode = LINK_MODE_NONE;
	    else{
	        if(mode < LINK_MODE_MAX)
	            _gSys_Info.link_mode = mode;
	        else
	            _gSys_Info.link_mode = LINK_MODE_NONE;
	    }
    }else
    {
        if(mode < LINK_MODE_MAX)
            _gSys_Info.link_mode = mode;
        else
            _gSys_Info.link_mode = LINK_MODE_NONE;
    } 
	
    if(0 ==  aply_to_sys)
        return 0;

    if(_gNewLANCheck == 1)
    {
	    ha=system("/img/bin/rc/rc.net check_ha_vip eth0 > /dev/null 2 >&1");
	    lanstatus=system("/img/bin/rc/rc.net check_wan_lan_same_bond > /dev/null 2 >&1");
	    if(ha!=0)
	        return -1;
	    if(lanstatus != 0 && _gSys_Info.link_mode != LINK_MODE_NONE)
	        return -1;
    }
    if(6 <= _gPicVersion)
        search_tabbyid(_g8023ad_Table, _gSys_Info.link_mode, (uint8_t **)&vpCmd);
    else
        search_tabbyid(_g8023ad_Table_old, _gSys_Info.link_mode, (uint8_t **)&vpCmd);
    conf_db_update(KEY_8023AD, "conf", (uint8_t *)vpCmd);
    if(_gNewLANCheck == 1)
        system("/img/bin/rc/rc.net link_wan_lan 'no'");

    sprintf(vpSysCmd,"%s %s %s %s","/img/bin/staticip.sh","eth0",_gSys_Info.nic_1_ip,_gSys_Info.nic_1_netmask);
    system(vpSysCmd);

    if(LINK_MODE_NONE == _gSys_Info.link_mode)
    {
         if(_gNewLANCheck == 1){
              char vBondId[PIPE_CMD_BUF]={0};
              char *vPipCmd="/img/bin/function/get_interface_info.sh check_eth_bond eth0";
              char vCGWCmd[PIPE_CMD_BUF]={0};
              shell_pipe_cmd(vPipCmd,vBondId,sizeof(vBondId));

	      system("/img/bin/rc/rc.net destory_one_link eth0");
              sprintf(vCGWCmd,"%s %s '%s' '%s'","/img/bin/rc/rc.net","change_default_gw",vBondId,"eth0");
	      system(vCGWCmd);
	 }else
	      system("/img/bin/8023ad.sh eth0");
    }

    sysinfo_update_all_nic();

    return 0;
}

int32_t set_dns(){
    FILE *fp;
    char rdbuf[128],str_1[1024],str_2[128];
    int c=0;

    if(1 == _gSys_Info.nic_1_dhcp_enable){
        conf_db_update(KEY_DNS_TYPE, "conf", "1");
    }else{
        conf_db_update(KEY_DNS_TYPE, "conf", "0");
        fp = fopen("/etc/resolv.conf","r");
        if ( fp != NULL){
            while (fgets(rdbuf,sizeof(rdbuf),fp) != NULL){
                if (sscanf(rdbuf,"nameserver %s\n",str_2)){
                    c++;
                    if (c == 1){
                        strcpy(str_1,str_2);
                    }else{
                        sprintf(str_1,"%s\n%s",str_1,str_2);
                    }
                }
            }
            conf_db_update(KEY_DNS, "conf", str_1);
            fclose(fp);
        }
    }
}

int32_t sysinfo_set_nic1_dhcp(uint8_t mode, uint8_t aply_to_sys)
{
    uint8_t cfg_nic_path[30]="/app/cfg/cfg_nic0";
    uint8_t cfg_nic[200]="#!/bin/sh\n/usr/bin/killall udhcpc\n/sbin/udhcpc -s /img/bin/udhcpc_script.sh -b -h `hostname` -i eth0 > /dev/null 2>&1";
    int32_t fd;

    IN(DEBUG_MODEL_SYSINFO, "nic1_dhcp %d, link_mode %d", mode, _gSys_Info.link_mode);
    if(_gNewLANCheck == 1)
    {
	    int32_t ha;
	    ha=system("/img/bin/rc/rc.net check_ha_vip eth0 > /dev/null 2 >&1");
	    if(ha!=0)
	        return -1;
    }
    
    if(_gSys_Info.link_mode != LINK_MODE_NONE && 1 ==  aply_to_sys)
        return -1;

    if(1 == mode)
        _gSys_Info.nic_1_dhcp_enable = 1;
    else
        _gSys_Info.nic_1_dhcp_enable = 0;

    if(0 ==  aply_to_sys || 0 == _gSys_Info.nic_1_dhcp_enable)
        return 0;
    if(1 == _gSys_Info.nic_1_dhcp_enable)
    {
       if(_gNewLANCheck == 1){
           conf_db_update(KEY_WAN_DHCP_IPV4, "conf", "1");
           set_dns(); 
       }else
           conf_db_update(KEY_WAN_DHCP, "conf", "1");
    }else
    {
        if(_gNewLANCheck == 1){
            conf_db_update(KEY_WAN_DHCP_IPV4, "conf", "0");
            set_dns();
	}else
            conf_db_update(KEY_WAN_DHCP, "conf", "0");
    }
    if(_gNewLANCheck == 1){
        char vBondId[PIPE_CMD_BUF]={0};
        char *vPipCmd="/img/bin/function/get_interface_info.sh check_eth_bond eth0";
        char vCGWCmd[PIPE_CMD_BUF]={0};
        shell_pipe_cmd(vPipCmd,vBondId,sizeof(vBondId));
        if(0 != strcmp(vBondId, ""))
            system("/img/bin/rc/rc.net destory_one_link eth0");
        else{
            system("touch '/tmp/eth_up_flag';ifconfig eth0 up");
            system(cfg_nic);
        }
        sprintf(vCGWCmd,"%s %s '%s' '%s'","/img/bin/rc/rc.net","change_default_gw",vBondId,"eth0");
	system(vCGWCmd);
    }else
    {
        system("rm -f /etc/resolv.conf");
        system("/img/bin/8023ad.sh eth0");
        sleep(1);
        system("ifconfig eth0 up");
        system(cfg_nic);
    }

    
    fd = (int32_t)open(cfg_nic_path,O_WRONLY|O_TRUNC, S_IRUSR|S_IWUSR);

    if (fd)
    {
        write(fd,cfg_nic,strlen(cfg_nic));
        close(fd);
    }
    sysinfo_update_all_nic();
    return 0;
}

int32_t sysinfo_set_nic1_ip(uint8_t *pIp)
{
    if(NULL == pIp)
        return -1;
    memset(_gSys_Info.nic_1_ip, 0, sizeof(_gSys_Info.nic_1_ip));
    sprintf(_gSys_Info.nic_1_ip, "%d.%d.%d.%d", pIp[0], pIp[1], pIp[2], pIp[3]);

    return 0;
}

int32_t sysinfo_set_nic1_netmask(uint8_t *pNetmask)
{
    if(NULL == pNetmask)
        return -1;

    memset(_gSys_Info.nic_1_netmask, 0, sizeof(_gSys_Info.nic_1_netmask));
    sprintf(_gSys_Info.nic_1_netmask, "%d.%d.%d.%d", pNetmask[0], pNetmask[1], pNetmask[2], pNetmask[3]);

    return 0;
}

int32_t sysinfo_apply_nic1_to_system(void)
{
    uint8_t vpSysCmd[PIPE_CMD_BUF]={0};
	
    if(_gNewLANCheck == 1)
    {
	    int32_t ha;    
	    
	    ha=system("/img/bin/rc/rc.net check_ha_vip eth0 > /dev/null 2 >&1");
	    if(ha!=0)
	        return -1;
    }
    if(_gNewLANCheck == 1)
        conf_db_update(KEY_WAN_DHCP_IPV4, "conf", "0");
    else
        conf_db_update(KEY_WAN_DHCP, "conf", "0");
    _gSys_Info.nic_1_dhcp_enable=0;
    conf_db_update(KEY_WAN_IP, "conf", _gSys_Info.nic_1_ip);
    conf_db_update(KEY_WAN_NETMASK, "conf", _gSys_Info.nic_1_netmask);
    set_dns();
    if(_gNewLANCheck == 1)
        system("/img/bin/rc/rc.net link_wan_lan 'yes'");

    sprintf(vpSysCmd,"%s %s %s %s","/img/bin/staticip.sh", _gNic_1_Name,_gSys_Info.nic_1_ip, _gSys_Info.nic_1_netmask);
    debug_print(DEBUG_MODEL_SYSINFO, "aply nic1 ip cmd %s\n", vpSysCmd);
    system(vpSysCmd);
    return 0;
}

int32_t sysinfo_set_nic2_ip(uint8_t *pIp)
{
    if(NULL == pIp)
        return -1;
    memset(_gSys_Info.nic_2_ip, 0, sizeof(_gSys_Info.nic_2_ip));
    sprintf(_gSys_Info.nic_2_ip, "%d.%d.%d.%d", pIp[0], pIp[1], pIp[2], pIp[3]);

    return 0;
}

int32_t sysinfo_set_nic2_netmask(uint8_t *pNetmask)
{
    if(NULL == pNetmask)
        return -1;
    memset(_gSys_Info.nic_2_netmask, 0, sizeof(_gSys_Info.nic_2_netmask));
    sprintf(_gSys_Info.nic_2_netmask, "%d.%d.%d.%d", pNetmask[0], pNetmask[1], pNetmask[2], pNetmask[3]);

    return 0;
}

int32_t sysinfo_apply_nic2_to_system(void)
{
    uint8_t vpSysCmd[PIPE_CMD_BUF]={0};
    if(_gNewLANCheck == 1)
    {
	    int32_t ha;    
	    
	    ha=system("/img/bin/rc/rc.net check_ha_vip eth1 > /dev/null 2 >&1");
	    if(ha!=0)
	        return -1;
    }

    conf_db_update(KEY_LAN_IP, "conf", _gSys_Info.nic_2_ip);
    conf_db_update(KEY_LAN_NETMASK, "conf", _gSys_Info.nic_2_netmask);
    sprintf(vpSysCmd,"%s %s %s %s","/img/bin/staticip.sh", _gNic_2_Name, _gSys_Info.nic_2_ip, _gSys_Info.nic_2_netmask);
    system(vpSysCmd);
    return 0;
}

int32_t sysinfo_set_lcm_password(uint8_t *pPassword)
{
    uint8_t vpSysCmd[PIPE_CMD_BUF]={0};
    uint8_t vpPassword[4+1]={0};

    IN(DEBUG_MODEL_SYSINFO, "%d,%d,%d,%d", pPassword[0], pPassword[1], pPassword[2], pPassword[3]);

    if(NULL == pPassword || strlen(pPassword) < 4)
        strncpy(vpPassword, "0000", 4);
    else
        strncpy(vpPassword, pPassword, 4);

    conf_db_update(KEY_PASSWORD, "conf", vpPassword);

    return 0;
}
#ifdef STATUS_LED
int32_t sysinfo_set_statusLED(uint8_t mode, uint8_t aply_to_sys)
{
    IN(DEBUG_MODEL_SYSINFO, "set LED %d", mode);

    if(mode == 1)
    {
    	  system("echo 0 0 SLED 1 > /var/tmp/oled/pipecmd");
    }
/*	
    else
    {
    	  //button control disable only, don't enable Status LED
        system("echo 0 0 SLED 1 > /var/tmp/oled/pipecmd");
    }
*/
    if(0 ==  aply_to_sys)
        return 0;
/*
    if(mode == 1)
	  conf_db_update(KEY_LED, "conf", "0");//disable LED, set notif_led=0
    else	
	  conf_db_update(KEY_LED, "conf", "1");
*/
    return 0;	
}
#endif
