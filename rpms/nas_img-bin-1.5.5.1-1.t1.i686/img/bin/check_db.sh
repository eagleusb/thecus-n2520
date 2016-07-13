#!/bin/sh
#mount
table_name=mount
table_exist=`sqlite /etc/cfg/conf.db "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='${table_name}'"`
if [ "${table_exist}" = "0" ];then
  sqlite /etc/cfg/conf.db "CREATE TABLE mount(label,iso,point,size);"
fi

#nfs
table_name=nfs
table_exist=`sqlite /etc/cfg/conf.db "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='${table_name}'"`
if [ "${table_exist}" = "0" ];then
  sqlite /etc/cfg/conf.db "CREATE TABLE nfs(share,hostname,privilege,rootaccess,os_support,sync);"
fi

#nsync
table_name=nsync
table_exist=`sqlite /etc/cfg/conf.db "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='${table_name}'"`
if [ "${table_exist}" = "0" ];then
  sqlite /etc/cfg/conf.db "CREATE TABLE nsync (task_name nvarchar(255) PRIMARY KEY DEFAULT '',manufacturer nvarchar(255) DEFAULT '',ip nvarchar(255) DEFAULT '',folder nvarchar(255) DEFAULT '',username nvarchar(255) DEFAULT '',passwd nvarchar(255) DEFAULT '',crond varchar(255) DEFAULT '',status nvarchar(255) DEFAULT '', end_time nvarchar(255) DEFAULT '', nsync_mode nvarchar(255) DEFAULT '');"
fi

#hot_spare
table_name=hot_spare
table_exist=`sqlite /etc/cfg/conf.db "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='${table_name}'"`
if [ "${table_exist}" = "0" ];then
  sqlite /etc/cfg/conf.db "CREATE TABLE hot_spare(spare varchar);"
fi

#rsyncbackup
table_name=rsyncbackup
table_exist=`sqlite /etc/cfg/conf.db "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='${table_name}'"`
if [ "${table_exist}" = "0" ];then
  sqlite /etc/cfg/conf.db "CREATE TABLE rsyncbackup (taskname CHAR DEFAULT '',desp TEXT DEFAULT '',model DEFAULT '',folder TEXT DEFAULT '',ip DEFAULT '',port DEFAULT '',dest_folder DEFAULT '',subfolder DEFAULT '',username DEFAULT '',passwd DEFAULT '',log_folder DEFAULT '', backup_enable DEFAULT '',backup_time DEFAULT '',end_time DEFAULT '',status DEFAULT '',tmp1 DEFAULT '',tmp2 DEFAULT '',tmp3 DEFAULT '',tmp4 DEFAULT '',tmp5 DEFAULT '');"
fi
