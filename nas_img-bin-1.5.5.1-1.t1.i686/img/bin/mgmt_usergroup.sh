#!/bin/sh
act=$1
tarfile="/tmp/usergroup.tar.gz"
binfile="/tmp/usergroup.bin"
enckey="conf_nas"

list_conf(){
  PASSDB_CFG_PATH="/etc/cfg/samba/passdb.tdb"
  SECRETS_CFG_PATH="/etc/cfg/samba/secrets.tdb"
  SMB_ETC_PATH="/etc/samba"
  SMB_VAR_PATH="/var/lib/samba/private"
  copy_file "$PASSDB_CFG_PATH" "$SMB_ETC_PATH"
  copy_file "$SECRETS_CFG_PATH" "$SMB_ETC_PATH"
  copy_file "$PASSDB_CFG_PATH" "$SMB_VAR_PATH"
  copy_file "$SECRETS_CFG_PATH" "$SMB_VAR_PATH"
  echo /etc/passwd
  echo /etc/group
  echo /etc/cfg/quota.db
  echo /etc/cfg/samba/passdb.tdb
  echo /etc/cfg/samba/secrets.tdb
  echo /etc/samba/passdb.tdb
  echo /etc/samba/secrets.tdb
  echo /var/lib/samba/private/passdb.tdb
  echo /var/lib/samba/private/secrets.tdb
}

backup(){
  tar zcvf ${tarfile} `list_conf`
  /usr/bin/des -k ${enckey} -E ${tarfile} ${binfile}
  rm -f ${tarfile}
  sync
}

copy_file(){
    SOURCE=$1
    TARGET=$2
    
    if [ ! -e "$TARGET" ];then
        mkdir -p $TARGET
    fi
    cp "$SOURCE" "$TARGET"
}
 
copy_to_cfg(){
    BACKUP_PASSDB=`tar -tzvf $tarfile | awk '/passdb.tdb/ {print "/"$6}'| sort | head -n 1`
    BACKUP_SECRETS=`tar -tzvf $tarfile | awk '/secrets.tdb/ {print "/"$6}'| sort | head -n 1`
    BACKUP_PASSDB_DIR=`dirname "$backup_passdb_path"`
    BACKUP_SECRETS_DIR=`dirname "$backup_secrets_path"`
    CFG_SMB="/etc/cfg/samba"
    if [ "$BACKUP_PASSDB_DIR" != "$CFG_SMB" ];then
        copy_file "${BACKUP_PASSDB}" "$CFG_SMB"
    fi
    if [ "$BACKUP_SECRETS_DIR" != "$CFG_SMB" ];then
        copy_file "${BACKUP_SECRETS}" "$CFG_SMB"
    fi
}

restore(){
  TMP_USRROOT="/dev/shm/user_backup_root"
  /usr/bin/des -k ${enckey} -D ${binfile} ${tarfile}
  RET=`echo $?`
  if [ "${RET}" != "0" ];then
    return 1
  fi

  rm -rf $TMP_USRROOT
  mkdir -p $TMP_USRROOT
  tar zxf ${tarfile} -C $TMP_USRROOT
  RET=`echo $?`
  if [ "${RET}" == 0 ];then
      cp -a ${TMP_USRROOT}/* /
      copy_to_cfg
  else
      RET=2
  fi
  return "${RET}"
}

if [ "$act" = "restore" ];then
  #/img/bin/service stop
  restore
  result=`echo $?`
  rm -f ${tarfile}
  rm -f ${binfile}
  rm -fr ${TMP_USRROOT}
  #/img/bin/service start
  echo $result > /tmp/restore_ret
elif [ "$act" = "backup" ];then
  backup
fi
