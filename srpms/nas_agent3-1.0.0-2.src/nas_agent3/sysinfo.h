/* 
 * File:   sysinfo.h
 * Author: dorianko
 *
 */

#ifndef _SYSINFO_H
#define	_SYSINFO_H

#ifdef	__cplusplus
extern "C" {
#endif

    #define __WISHLIST_LINK_AGGREGAGTION_2009__
//    #define SYSINFO_DISK_INFO_ENABLE

    #define MAX_DISK_NUM        255
    #define MAX_RAID_INFO       8
    #define MB_TYPE_N4200       500
    #define MB_TYPE_N4200PRO  	501
    #define MB_TYPE_N4200ECO  	502
    #define MB_TYPE_N16000  	600
    #define MB_TYPE_N12000  	601
    #define MB_TYPE_N8900  	602
    #define MB_TYPE_N16000PRO  	603
    #define MB_TYPE_N12000PRO  	604
    #define MB_TYPE_N8900PRO  	605


    #define KEY_WAN_ENABLE_IPV4      "nic1_ipv4_enable"
    #define KEY_WAN_DHCP_IPV4        "nic1_ipv4_dhcp_client"
    #define KEY_LAN_ENABLE_IPV4      "nic2_ipv4_enable"
    #define KEY_DNS_TYPE        "nic1_dns_type"
    #define KEY_DNS             "nic1_dns"
    #define KEY_WAN_ENABLE      "nic1_enable"
    #define KEY_WAN_DHCP        "nic1_dhcp"
    #define KEY_LAN_ENABLE      "nic2_enable"
 

    #define KEY_WAN_IP          "nic1_ip"
    #define KEY_WAN_NETMASK     "nic1_netmask"
    #define KEY_LAN_DHCP        "nic2_dhcp"
    #define KEY_LAN_IP          "nic2_ip"
    #define KEY_LAN_NETMASK     "nic2_netmask"
    #define KEY_8023AD          "nic1_mode_8023ad"
    #define KEY_LANGUAGE        "admin_lang"
    #define KEY_BEEP            "notif_beep"
    #define KEY_PASSWORD        "lcmcfg_pwd"
    #define KEY_FILESYSTEM_TYPE "filesystem"
    #define KEY_HA              "ha_enable"
#ifdef STATUS_LED	
    #define KEY_LED			"notif_led"
#endif
    #define MIN_PIC_VERSION     6 

    #define FAN_CPU_1_ID	0
    #define FAN_SYS_1_ID	1
    #define FAN_SYS_2_ID	2

    #define FAN_STATE_FAIL      0
    #define FAN_STATE_OK        1
    #define FAN_NOT_EXIST       0xff
    #define SYS_INFO_TIMEOUT    20
    #define PIPE_CMD_BUF        256

    enum
    {
        LINK_MODE_8023AD,
        LINK_MODE_ACTBKP,
        LINK_MODE_LBRR,
#ifdef __WISHLIST_LINK_AGGREGAGTION_2009__
        LINK_MODE_LBXOR,
        LINK_MODE_LBTLB,
        LINK_MODE_LBALB,
#endif  //__WISHLIST_LINK_AGGREGAGTION_2009__
        LINK_MODE_NONE,
        LINK_MODE_MAX
    };

    enum
    {
        SYSINFO_HOST_NAME,
        SYSINFO_WAN_IP,
        SYSINFO_LAN_IP,
        SYSINFO_LINK_AGGR,
        SYSINFO_CPU_FAN,
        SYSINFO_SYS_FAN_1,
        SYSINFO_SYS_FAN_2,
        SYSINFO_SYS_FAN_3,
        SYSINFO_SYS_FAN_4,
        SYSINFO_BATTERY,
        SYSINFO_DATE,
    #ifdef SYSINFO_DISK_INFO_ENABLE
        SYSINFO_DISK_INFO,
    #endif
        SYSINFO_RAID_INFO,
        SYSINFO_RAID_INFO2,
        SYSINFO_RAID_INFO3,
        SYSINFO_RAID_INFO4,
        SYSINFO_RAID_INFO5,
        SYSINFO_RAID_INFO6,
        SYSINFO_RAID_INFO7,
        SYSINFO_RAID_INFO8,
        SYSINFO_RAID_INFO9,
        SYSINFO_RAID_INF10,
        SYSINFO_RAID_USAGE_INFO,
        SYSINFO_MAX,
    };

    enum
    {
        LANG_UNKNOW,
        LANG_ENGLISH,
        LANG_T_CHINESE,
        LANG_S_CHINESE,
        LANG_FRANCH,
        LANG_GERMAN,
        LANG_ITALIAN,
        LANG_JAPANESE,
        LANG_KOREAN,
        LANG_POLISH,
        LANG_RUSSIAN,
        LANG_SPANISH,
        LANG_MAX,
    };

    enum
    {
        BATTERY_NOT_EXIST,
        BATTERY_LOW,
        BATTERY_GOOD,
        BATTERY_CHARGING,
        BATTERY_MAX,
    };

    typedef struct
    {
        uint8_t     id[16+1];
        uint8_t     disk_level[8];
        uint8_t     disk_tray[MAX_DISK_NUM+1];
        uint8_t     disk_status[MAX_DISK_NUM+1];
        uint8_t     usage;
    } raid_info_t;

    typedef struct
    {
        uint16_t    mb_type;
        uint8_t     have_swtich_board;
        uint8_t     cpu_fan_enable;
        uint8_t     sys_fan_1_enable;
        uint8_t     sys_fan_2_enable;
        uint8_t     sys_fan_3_enable;
        uint8_t     sys_fan_4_enable;
        uint8_t     nic_1_enable;
        uint8_t     nic_2_enable;
        uint8_t     host_name[32];
        uint8_t     nic_1_dhcp_enable;
        uint8_t     nic_1_ip[16];
        uint8_t     nic_1_netmask[16];
        uint8_t     nic_2_dhcp_enable;
        uint8_t     nic_2_ip[16];
        uint8_t     nic_2_netmask[16];
        uint8_t     link_mode;
        uint8_t     cpu_fan_state;
        uint8_t     sys_fan_1_state;
        uint8_t     sys_fan_2_state;
        uint8_t     sys_fan_3_state;
        uint8_t     sys_fan_4_state;
        uint8_t     battery_state;
    #ifdef SYSINFO_DISK_INFO_ENABLE
        uint8_t     disk_info[MAX_DISK_NUM+1];
    #endif
        uint8_t     raid_num;
        raid_info_t raid_info[MAX_RAID_INFO];
        uint8_t     lang;
        uint8_t     alarm_mute;
        uint8_t     lcmcfg_password[4];
    } sys_info;

int32_t sysinfo_update_init(void);
int32_t sysinfo_update_hostname(void);
int32_t sysinfo_get_nic_info(char* nic_name, char *out_ip, char *out_netmask);
int32_t sysinfo_update_switchboard(void);
int32_t sysinfo_update_all_nic(void);
int32_t sysinfo_update_fan(void);
int32_t sysinfo_update_battery(void);
int32_t sysinfo_update_disk_info(void);
int32_t sysinfo_update_raid_status(void);
int32_t sysinfo_update_language(uint8_t init);
int32_t sysinfo_update_all(void);
int32_t sysinfo_timeout_cb(uint32_t event, void *pData);
int32_t sysinfo_set_language(uint8_t lang, uint8_t aply_to_sys);
int32_t sysinfo_set_alarm(uint8_t mode, uint8_t aply_to_sys);
int32_t sysinfo_set_linkaggr(uint8_t mode, uint8_t aply_to_sys);
int32_t sysinfo_set_nic1_dhcp(uint8_t mode, uint8_t aply_to_sys);
int32_t sysinfo_set_nic1_ip(uint8_t *pIp);
int32_t sysinfo_set_nic1_netmask(uint8_t *pNetmask);
int32_t sysinfo_apply_nic1_to_system(void);
int32_t sysinfo_set_nic2_ip(uint8_t *pIp);
int32_t sysinfo_set_nic2_netmask(uint8_t *pNetmask);
int32_t sysinfo_apply_nic2_to_system(void);
int32_t sysinfo_set_lcm_password(uint8_t *pPassword);
int32_t sysinfo_update_screen(int8_t offset);
#ifdef STATUS_LED
int32_t sysinfo_set_statusLED(uint8_t mode, uint8_t aply_to_sys);
#endif

#ifdef	__cplusplus
}
#endif

#endif	/* _SYSINFO_H */

