HA_VER=2.1

HA_SCRIPT="/etc/ha/script/"
RC_HA="${HA_SCRIPT}/rc.ha"
RC_ISCSI="${HA_SCRIPT}/iscsi.sh"
RC_INITIATOR="${HA_SCRIPT}/initiator.sh"
Export_iSCSI="${HA_SCRIPT}/iscsi_export.sh"
DEV_MAP="${HA_SCRIPT}/iscsi_dev_map.sh"
NIC2="${HA_SCRIPT}/cfg_nic2"
RAID_IBLOCK="${HA_SCRIPT}/raid2iblock.sh"
ISCSI_BLOCK="${HA_SCRIPT}/iscsi_block.sh"
sqlite="/usr/bin/sqlite"
cfgdb="/etc/cfg/conf.db"
confdb="/etc/cfg/ha.db"
if [ ! -f $confdb ] || [ ! -f /tmp/ha_role ];then
  confdb=$cfgdb
fi
CHK_TREE="/img/bin/rc/rc.treemenu hd_tree"
HA_STAT="${HA_SCRIPT}/ha_status.sh"
ASSUME_CLEAN=1
HA_SYNC_CHECK="${HA_SCRIPT}/ha_sync_check.sh"
RAID_UUID="${HA_SCRIPT}/raid_uuid.sh"
HB_LINE=`${sqlite} ${cfgdb} "select v from conf where k = 'ha_heartbeat'"`
if [ "${HB_LINE}" = "" ];then
  HB_LINE="eth2"
fi
HA_CHECK="${HA_SCRIPT}/check_setting.sh"
NAS_PIE="${HA_SCRIPT}/nas_pie.sh"
NAS_ACT="nas_act.sh"
HA_NAS_FIFO="/tmp/ha_fifo"
NAS_FTPD="${HA_SCRIPT}/bftpd -d -c /etc/ha/script/bftpd.conf"

WGET="/usr/bin/wget --quiet --connect-timeout=10 --tries=1 "
WPUT="/usr/bin/wput --quiet --timeout=10 --tries=1 --reupload "
#WPUT="/img/bin/ha/script/wput --quiet --timeout=10 --tries=1 --reupload "

WWW_PATH="/tmp/www"
############ Flag ##################
FLAG_HA="${WWW_PATH}/ha_flag"
FLAG_HALT="${WWW_PATH}/ha_flag_halt"
FLAG_REBOOT="${WWW_PATH}/ha_flag_reboot"
FLAG_POWER="${WWW_PATH}/ha_flag_power"
FLAG_ENABLE="${WWW_PATH}/ha_flag_enable"
FLAG_CHECK_DISK="${WWW_PATH}/ha_flag_check_disk"
FLAG_CREATE_RAID="${WWW_PATH}/ha_flag_create_raid"
FLAG_CHECK_REBUILD="${WWW_PATH}/ha_flag_check_rebuild"
FLAG_REBUILD="${WWW_PATH}/ha_flag_rebuild"
FLAG_UPGRADE="${WWW_PATH}/ha_flag_upgrade"

############ Conf ##################
CONF_HW="/tmp/www/ha_conf_hw"
CONF_DISK="/tmp/www/ha_conf_disk"
CONF_NEW_RAID="/tmp/www/ha_conf_new_raid"
CONF_REBUILD="/tmp/www/ha_conf_rebuild"

############ Log ##################
LOG_UPGRADE="/tmp/www/ha_log_upgrade"


HA_STAT_LOG="/dev/null"
if [ -f /etc/ha_debug ];then
  HA_STAT_LOG="/tmp/ha_stat.log"
fi

ISCSI_ROOT="/sys/kernel/config"
TARGET_CORE="${ISCSI_ROOT}/target/core"
TARGET_ISCSI="${ISCSI_ROOT}/target/iscsi"

reverse_domain() {
        domain1=$1
        domain2=$2
        domain3=$3
        rdomain=""

        if [ "$domain3" != "" ];then
                rdomain="$domain3"
        fi
        if [ "$domain2" != "" ];then
                if [ "$rdomain" != "" ];then
                        rdomain="$rdomain.$domain2"
                else
                        rdomain="$domain2"
                fi
        fi
        if [ "$domain1" != "" ];then
                if [ "$rdomain" != "" ];then
                        rdomain="$rdomain.$domain1"
                else
                        rdomain="$domain1"
                fi
        fi

        echo -n $rdomain |tr [:upper:] [:lower:]
}

