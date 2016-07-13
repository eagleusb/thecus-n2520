#!/bin/sh
#
# Start the iSCSI: Generic SCSI Target Subsystem for Linux.
#
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MEM_SIZE=1048576
cmdsqlite="/usr/bin/sqlite"
confdb="/etc/cfg/ha.db"
CONFIGFS=/sys/kernel/config
TARGET=/sys/kernel/config/target/core
FABRIC=/sys/kernel/config/target/iscsi
crond_conf="/etc/cfg/crond.conf"
name=$1
acl_iqn_name=$2
md=$3

script_path="/etc/ha/script/"

. ${script_path}/conf.ha
. ${script_path}/func.ha

set_iqn()
{
	# get domain
	domain=`$cmdsqlite ${confdb} "select v from conf where k='nic1_domainname'"|awk -F. '{print $1 " " $2 " " $3}'`
	revdomain=`reverse_domain $domain`
	
        scst_date="2010-08"

	#MODEL=`cat /etc/manifest.txt  | awk '/^type/{print $2}'|tr [:upper:] [:lower:]`
	
	# set iqn
	macaddr=`ifconfig ${HB_LINE}|awk '/HWaddr/{print $5}'|awk -F: '{printf("%s%s%s%s%s%s",$1,$2,$3,$4,$5,$6)}'|tr /A-Z/ /a-z/`
	DEF_IQN="iqn.$scst_date.$revdomain.nas:iscsi.$name.$macaddr"
}


modprobe configfs
modprobe target_core_mod
modprobe iscsi_target_mod

mount -t configfs none ${CONFIGFS}


set_iqn
crc_data="None"
crc_header="None"
connection_id="8"
error_recovery_id="2"

  PORTAL1=`ifconfig ${HB_LINE}|awk '/inet addr/{print toupper($2)}'| awk -F':' '{printf $2}'`
  if [ "${PORTAL1}" != "" ];then
    mkdir -p "$FABRIC/$DEF_IQN/tpgt_1/np/${PORTAL1}:3260"
  fi

mkdir -p ${TARGET}/iblock_0/ha_${md}
#echo iblock_major=9,iblock_minor=0 > ${TARGET}/iblock_0/ha_${md}/control
echo -n "udev_path=/dev/${md}" > ${TARGET}/iblock_0/ha_${md}/control
echo -n 1 > ${TARGET}/iblock_0/ha_${md}/enable
echo -n 4096 > ${TARGET}/iblock_0/ha_${md}/attrib/block_size

LUN=lun_`echo ${md}|tr -d /md//`
mkdir -p "$FABRIC/$DEF_IQN/tpgt_1/lun/${LUN}"
ln -s $TARGET/iblock_0/ha_${md} "$FABRIC/$DEF_IQN/tpgt_1/lun/${LUN}/lio_west_port"

mkdir -p "$FABRIC/$DEF_IQN/tpgt_1/acls/$acl_iqn_name/${LUN}"
ln -s "$FABRIC/$DEF_IQN/tpgt_1/lun/${LUN}" "$FABRIC/$DEF_IQN/tpgt_1/acls/$acl_iqn_name/${LUN}/."

  echo ${crc_data} > $FABRIC/$DEF_IQN/tpgt_1/param/DataDigest
  echo ${crc_header} > $FABRIC/$DEF_IQN/tpgt_1/param/HeaderDigest
  echo ${error_recovery_id} > $FABRIC/$DEF_IQN/tpgt_1/param/ErrorRecoveryLevel
  echo ${connection_id} > $FABRIC/$DEF_IQN/tpgt_1/param/MaxConnections
  echo "NAS Target" > $FABRIC/$DEF_IQN/tpgt_1/param/TargetAlias
  echo -n 0 > $FABRIC/$DEF_IQN/tpgt_1/attrib/authentication
  echo -n 1 > $FABRIC/$DEF_IQN/tpgt_1/enable
  
