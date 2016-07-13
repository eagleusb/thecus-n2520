#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
gAction=$1
sqlite="/usr/bin/sqlite"
db="/etc/cfg/backup.db"
PROCESS_NAME="/img/bin/dataguard/iscsi.sh"
. /img/bin/function/libraid
. /img/bin/function/lib_dataguard
if [ ! -d /raid/data/tmp/check_iscsi ];then
     mkdir /raid/data/tmp/check_iscsi
fi
#######################################################
#
# get source folder path for uuid
#
#######################################################
get_src_folder_path(){
    local fFolder_raid
    local fFolder_path
    local fSrc_folder_path
    
    fFolder_raid=`Ldataguard_check_uuid "$OPT_src_uuid"`
    for folder in "${aryPath_list[@]}"
    do
       if [ `echo "$fFolder_raid" | grep -c "/data/stackable/"` -lt 1 ]; then
           fFolder_path="${fFolder_raid}/data${folder}"
       else
           fFolder_name=`echo "${folder}" | awk -F"/" '{print $2}'`
           fFolder_path="${fFolder_raid}/data"`echo "${folder#/${fFolder_name}}"`
       fi
       if [ ! -e "$fFolder_path" ]; then
           fLoss_folder="${fLoss_folder}"`basename "${fFolder_path}"`", "
       else
           fFolder_path=`echo "${fFolder_path}" | sed "s/'/\'\\\\\\''/g"`
           fSrc_folder_path="${fSrc_folder_path}'${fFolder_path}' "
       fi
   done
   echo "${fLoss_folder}//${fSrc_folder_path}"
}
get_folder_info(){
   get_info=`$sqlite /raid/data/tmp/check_iscsi/$tid/smb.db "select * from smb_userfd where share='$1'"`
   share=`echo -e "$get_info" | awk -F '|' '{print $1}'`
   comment=`echo -e "$get_info" | awk -F '|' '{print $2}'`
   browseable=`echo -e "$get_info" | awk -F '|' '{print $3}'`
   guest_only=`echo -e "$get_info" | awk -F '|' '{print $4}'`
   path=`echo -e "$get_info" | awk -F '|' '{print $5}'`
   map_hidden=`echo -e "$get_info" | awk -F '|' '{print $6}'`
   recursive=`echo -e "$get_info" | awk -F '|' '{print $7}'`
   readonly=`echo -e "$get_info" | awk -F '|' '{print $8}'`
   speclevel=`echo -e "$get_info" | awk -F '|' '{print $9}'`
   /img/bin/user_folder.sh add "$2" "$raid_id" "$comment" "$browseable" "$guest_only" "$readonly" "$speclevel"
}
delete_iscsi_table(){
  iscsi_count=`$sqlite /$target/sys/smb.db "select * from iscsi where name='$dest_folder'" | wc -l`
  if [ $iscsi_count -gt 0 ];then
     $sqlite /$target/sys/smb.db "delete from iscsi where name='$dest_folder'"
     lunnamelist=`$sqlite /$target/sys/smb.db "select name from lun where target='$dest_folder'"`
     $sqlite /$target/sys/smb.db "delete from lun where target='$dest_folder'"
     for v in $lunnamelist
      do
      $sqlite /$target/sys/smb.db "delete from lun_acl where lunname='$v'"
      done
  fi
}
insert_iscsi_table(){
   ## Insert Table : iscsi
   get_info=`$sqlite /raid/data/tmp/check_iscsi/$tid/smb.db "select alias,name,enabled,chap,user,pass,chap_mutual,user_mutual,pass_mutual,year,month,crc_data,crc_header,v1,v2,v3,v4,v5 from iscsi where name='$1'"`
   alias=`echo -e "$get_info" | awk -F '|' '{print $1}'`
   name="$2"
   enabled=`echo -e "$get_info" | awk -F '|' '{print $3}'`
   chap=`echo -e "$get_info" | awk -F '|' '{print $4}'`
   user=`echo -e "$get_info" | awk -F '|' '{print $5}'`
   pass=`echo -e "$get_info" | awk -F '|' '{print $6}'`
   chap_mutual=`echo -e "$get_info" | awk -F '|' '{print $7}'`
   user_mutual=`echo -e "$get_info" | awk -F '|' '{print $8}'`
   pass_mutual=`echo -e "$get_info" | awk -F '|' '{print $9}'`
   year=`echo -e "$get_info" | awk -F '|' '{print $10}'`
   month=`echo -e "$get_info" | awk -F '|' '{print $11}'`
   crc_data=`echo -e "$get_info" | awk -F '|' '{print $12}'`
   crc_header=`echo -e "$get_info" | awk -F '|' '{print $13}'`
   v1=`echo -e "$get_info" | awk -F '|' '{print $14}'`
   v2=`echo -e "$get_info" | awk -F '|' '{print $15}'`
   v3=`echo -e "$get_info" | awk -F '|' '{print $16}'`
   v4=`echo -e "$get_info" | awk -F '|' '{print $17}'`
   v5=`echo -e "$get_info" | awk -F '|' '{print $18}'`
   $sqlite /$target/sys/smb.db "insert into iscsi values ('$alias','$name','$enabled','$chap','$user','$pass','$chap_mutual','$user_mutual','$pass_mutual','$year','$month','$crc_data','$crc_header','$v1','$v2','$v3','$v4','$v5')"
   
   ## Process Table : lun & lun_acl
   lunnamelist=`$sqlite /raid/data/tmp/check_iscsi/$tid/smb.db "select name from lun where target='$1'"`
   for v in $lunnamelist
   do
       ## Insert Table : lun
       get_info=`$sqlite /raid/data/tmp/check_iscsi/$tid/smb.db "select target,name,thin,id,percent,block,serial,v1,v2 from lun where target='$1' and name='$v'"`
       target1="$2"
       name=`echo -e "$get_info" | awk -F '|' '{print $2}'`
       if [ "$3" == "2" ];then
          for fRaidmd in ${fRaidIdList}
          do
             iscsi_lun_flag=""
             iscsi_lun_data="${name}"
             for fRaidmd in ${fRaidIdList}
             do
                 flag_lun=`$sqlite /raid$fRaidmd/sys/smb.db ".schema"|grep lun|wc -l`
                 if [ $flag_lun -gt 0 ];then
                       flag_lun=`$sqlite /raid$fRaidmd/sys/smb.db "select * from lun where name='$iscsi_lun_data'"|wc -l`
                       if [ $flag_lun -gt 0 ];then
                             iscsi_lun_flag="1"
                       fi
                 fi     
             done 
          done
          if [ "$iscsi_lun_flag" == "1" ];then
              for ((i=1;i<=10000;i++))
              do
                  iscsi_lun_flag=""
                  iscsi_lun_data="${name}-""$i"
                  for fRaidmd in ${fRaidIdList}
                   do
                     flag_lun=`$sqlite /raid$fRaidmd/sys/smb.db ".schema"|grep lun|wc -l`
                     if [ $flag_lun -gt 0 ];then
                           flag_lun=`$sqlite /raid$fRaidmd/sys/smb.db "select * from lun where name='$iscsi_lun_data'"|wc -l`
                           if [ $flag_lun -gt 0 ];then
                                iscsi_lun_flag="1"
                           fi
                     fi
                   done
                   if [ "$iscsi_lun_flag" == "" ];then
                         iscsi_tmp_lun="$iscsi_lun_data"
                         break
                   fi
              done
              lun_msg="[ ${name} ] to [ ${iscsi_tmp_lun} ]"
              eventlog "$CFG_task_name" "42" "$action" "$LOG_TMP" "$lun_msg" "$CFG_act_type"
           else
              iscsi_tmp_lun="$iscsi_lun_data"
          fi
          strexec="/usr/bin/rsync $RSYNC_PARA $CHMOD_ACL --delete --log-file=\"/raid/data/tmp/rsync_backup.$CFG_task_name\" --progress --timeout=600 --inplace --exclude-from=\"$ISO_TMP\" \"$folder_path/${name}\" \"$dest_folder_n/${iscsi_tmp_lun}\" > $COUNT_FILE"
          eval "$strexec"
          ret=`echo $?`
          name="$iscsi_tmp_lun"
       fi
       thin=`echo -e "$get_info" | awk -F '|' '{print $3}'`
       id=`echo -e "$get_info" | awk -F '|' '{print $4}'`
       percent=`echo -e "$get_info" | awk -F '|' '{print $5}'`
       block=`echo -e "$get_info" | awk -F '|' '{print $6}'`
       serial=`echo -e "$get_info" | awk -F '|' '{print $7}'`
       v1=`echo -e "$get_info" | awk -F '|' '{print $8}'`
       v2=`echo -e "$get_info" | awk -F '|' '{print $9}'`
       $sqlite /$target/sys/smb.db "insert into lun values ('$target1','$name','$thin','$id','$percent','$block','$serial','$v1','$v2')"
       
       ## Insert Table: lun_acl       
       get_info=`$sqlite /raid/data/tmp/check_iscsi/$tid/smb.db "select init_iqn, lunname, privilege,v1,v2 from lun_acl where lunname='$v'"`
       echo -e "$get_info" | \
       while read single_info
       do
           init_iqn=`echo -e "$single_info" | awk -F '|' '{print $1}'`
           if [ "$3" == "2" ];then
               lunname="$iscsi_tmp_lun"
           else
               lunname=`echo -e "$single_info" | awk -F '|' '{print $2}'`
           fi
           privilege=`echo -e "$single_info" | awk -F '|' '{print $3}'`
           v1=`echo -e "$single_info" | awk -F '|' '{print $4}'`
           v2=`echo -e "$single_info" | awk -F '|' '{print $5}'`
           if [ "$init_iqn" != "" ];then
               $sqlite /$target/sys/smb.db "insert into lun_acl values ('$init_iqn','$lunname','$privilege','$v1','$v2')"
           fi
       done
   done
}
######################################################
#
# get target folder path for uuid
#
#######################################################
get_tge_folder_path(){
    local fFolder_raid
    local fFolder_path
    local fTge_folder_path
    
    fFolder_raid=`Ldataguard_check_uuid "$OPT_dest_uuid"`
    folder_basename=`basename "${OPT_folder}"`
    if [ `echo "$fFolder_raid" | grep -c "/data/stackable/"` -lt 1 ]; then
        if [ "$1" == "1" ];then
           fFolder_path="${fFolder_raid}/data${OPT_target}"
         else
           if [ "$1" == "2" ];then
              fFolder_path="${fFolder_raid}/data${OPT_target}""/$folder_basename"
           fi   
        fi   
    else
        fFolder_name=`echo "${OPT_target}" | awk -F"/" '{print $2}'`
        if [ "$1" == "1" ];then
           fFolder_path="${fFolder_raid}/data"`echo "${OPT_target#/${fFolder_name}}"`
         else
           if [ "$1" == "2" ];then
              fFolder_path="${fFolder_raid}/data"`echo "${OPT_target#/${fFolder_name}}"`"/$folder_basename"
           fi
        fi
    fi
    if [ ! -e "$fFolder_path" ]; then
        fLoss_folder="${fLoss_folder}"`basename "${fFolder_path}"`", "
    else
        fFolder_path=`echo "${fFolder_path}" | sed "s/'/\'\\\\\\''/g"`
        fTge_folder_path="${fTge_folder_path}'${fFolder_path}'"
    fi
    echo "${fLoss_folder}//${fTge_folder_path}"
}            
get_iscsiname(){
   if [ ! -f "$1"/.iscsi.bin ];then
         echo ""
         return
   fi
   cd "$1"
   cp .iscsi.bin /tmp
   cd /tmp
   des -D -k iscsi_zip .iscsi.bin .iscsi.tar.gz
   tar zxvf .iscsi.tar.gz > /dev/null 2>&1
   iscsiname=`cat /tmp/iscsi_name`
   rm -rf "/tmp/iscsi_name"
   rm -rf "/tmp/smb.db"
   rm -rf "/tmp/acl_data"
   rm -rf "/tmp/size_data"
   rm -rf "/tmp/.iscsi.tar.gz"
   rm -rf "/tmp/.iscsi.bin"
   echo $iscsiname
}
get_iscsi_use(){
    local Liscsi_name
    local Ltask_id_list
    local Ltask_id
    local check_iscsi_name
    Liscsi_name="$1"
    Ltask_id_list=(`"$Ldataguard_sqlite" "$Ldataguard_backupdb" "select tid from task where (back_type='iscsi' or back_type='import_iscsi') and act_type='local' and status='1'"`)
    for Ltask_id in ${Ltask_id_list[@]}
    do
        if [ -f "/raid/data/tmp/check_iscsi/$Ltask_id/iscsi_name" ];then
            check_iscsi_name=`cat "/raid/data/tmp/check_iscsi/$Ltask_id/iscsi_name"`
            if [ "$check_iscsi_name" == "${Liscsi_name}" ];then
                   echo "1"
                   return
            fi
        fi
    done
    echo "0"
}
check_same_folder(){
   local Liscsi_name
   local Ltask_id_list
   local Ltask_id
   local Ltid
   Ltid=$1
   Liscsi_name=$2
   Ltask_id_list=(`"$Ldataguard_sqlite" "$Ldataguard_backupdb" "select tid from task where (back_type='iscsi' or back_type='import_iscsi') and act_type='local' and status='1'"`)
   for Ltask_id in ${Ltask_id_list[@]}
     do
         if [ "$Ltask_id" != "$Ltid" ];then
           if [ -f "/raid/data/tmp/check_iscsi/$Ltask_id/iscsi_name" ];then
              check_iscsi_name=`cat "/raid/data/tmp/check_iscsi/$Ltask_id/iscsi_name"`
              if [ "iSCSI_$check_iscsi_name" == "${Liscsi_name}" ];then
                    echo "1"
                    return
              fi
           fi   
         fi     
     done
     echo "0"
                                                                   
}
check_iscsifolder(){
     tid="$1"
     Lfolder_data="$2"
     if [ ! -f "$Lfolder_data"/.iscsi.bin ];then
           echo "1"
           return
     fi
     mv "$Lfolder_data"/.iscsi.bin /tmp
     cd "$Lfolder_data"
     ls -l | awk -F ' ' '{printf("%s %s\n",$5,$9)}' > "/tmp/size_data_tmp"
     if [ ! -f "/raid/data/tmp/check_iscsi/$tid/iscsi_name" ];then
         mv /tmp/.iscsi.bin "$Lfolder_data"
         echo "2"
         return
     fi
     if [ ! -f "/raid/data/tmp/check_iscsi/$tid/size_data" ];then
         mv /tmp/.iscsi.bin "$Lfolder_data"
         echo "2"
         return
     fi
     if [ ! -f "/raid/data/tmp/check_iscsi/$tid/smb.db" ];then
         mv /tmp/.iscsi.bin "$Lfolder_data"
         echo "2"
         return
     fi
     if [ ! -f "/raid/data/tmp/check_iscsi/$tid/acl_data" ];then
         mv /tmp/.iscsi.bin "$Lfolder_data"
         echo "2"
         return
     fi
     checkdiff=`diff /tmp/size_data_tmp /raid/data/tmp/check_iscsi/$tid/size_data`
     if [ "$checkdiff" != "" ];then
         mv /tmp/.iscsi.bin "$Lfolder_data"
         echo "3"
         return
     fi
     mv /tmp/.iscsi.bin "$Lfolder_data"
     echo "0"
}
task_create(){
   local fFolder_path
   tid=$1
   gExternal_target_path=$2
   eval `db_to_env $tid`
   if [ "$OPT_device_type" == "1" ]; then
        if [ "$OPT_target" == "" ]; then
           fFolder_path="${gExternal_target_path}"
         else
           fFolder_path="${gExternal_target_path}${OPT_target}"
        fi
        touch "${fFolder_path}/${OPT_target_tag}"
   fi
}
conf(){
  tid=$1
  external_folder=$2
  eval `db_to_env $tid`
  if [ "$CFG_back_type" != "iscsi" ];then
        return
  fi
  LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
  STATUS_FILE="/tmp/rsync_backup_${CFG_task_name}.status"
  COUNT_FILE="/tmp/rsync_backup_${CFG_task_name}.count"
  folder_check=`echo ${OPT_folder}|sed 's/iSCSI_//g'`
  check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${gAction}"
  Ldataguard_get_raid_status "$CFG_task_name" "${gAction}" "$LOG_TMP" "$log_path"
  Ldataguard_get_migrate_status "$CFG_task_name" "${gAction}" "$LOG_TMP" "$log_path"  "$CFG_act_type"
  Ldataguard_check_status "$CFG_task_name" "$STATUS_FILE" "${gAction}" "$CFG_act_type"
  check_same=`check_same_folder "$tid" "$OPT_folder"`
  if [ "$check_same" == "1" ] ; then
       eventlog "$CFG_task_name" "40" "${gAction}" "$LOG_TMP" "$OPT_folder" "$CFG_act_type"
       Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
       exit
  fi
  ISO_TMP="/tmp/rsync_${CFG_task_name}_iso_tmp.log"
  ISO_FILE="/tmp/rsync_${CFG_task_name}_iso.log"
  get_iso_info "$ISO_FILE"
  touch "$ISO_TMP"
  path="${OPT_path}/${OPT_folder}"
  cat "$ISO_FILE" | \
  while read iso_path
  do
         folder_name=`echo "${path}" | awk -F"/" '{print $2}'`
         echo "${iso_path}" | awk -F"/" "{if (\$2==\"$folder_name\")print \$NF}" >> "$ISO_TMP"
  done
  path=`echo "${path}" | sed "s/'/\'\\\\\\''/g"`
  path_list="${path_list}'${path}' "
  eval "aryPath_list=($path_list)"
  fSource_path_list=`get_src_folder_path`
  fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
  fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
  fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`
  if [ ! -z "$fLoss_folder" ]; then
       eventlog "$CFG_task_name" "16" "${gAction}" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
       if [ -z "$fSource_folder" ]; then
            Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
            exit
       fi
  fi
  eval "fSource_folder=($fSource_folder)"
  #####   target path   #####
  if [ "$OPT_device_type" != "1" ]; then
      fTarget_path_list=`get_tge_folder_path 1`
  else
      fTarget_path_list=`Ldataguard_backup_target "$CFG_task_name" "$OPT_target" "$OPT_target_tag" "$OPT_device_type" "$external_folder"`
  fi
  fLoss_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $1}'`
  fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
  fTarget_folder=`echo "$fTarget_path_list" | awk -F"//" '{print $2}'`
  eval "fTarget_folder=($fTarget_folder)"
  if [ -z "$fTarget_folder" ]; then
      eventlog "$CFG_task_name" "37" "${gAction}" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
      Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
      exit
  fi
  if [ "$OPT_device_type" == "0" ]; then
     fTarget_smbdb=`Ldataguard_get_folder_smbdb "$fTarget_folder"`
     fTarget_folder_name=`echo "$fTarget_folder" | awk -F"/" '{print $4}'`
     fGuest_only=`$Ldataguard_sqlite ${fTarget_smbdb} "select \"guest only\" from smb_specfd where share='"$fTarget_folder_name"';select \"guest only\" from smb_userfd where share='"$fTarget_folder_name"'"`
     fTarget_folder_root=`echo "$fTarget_folder"| awk -F"/" '{printf("/%s/%s/%s",$2,$3,$4)}'`
     if [ "$fGuest_only" == "yes" ]; then
         echo "$fTarget_folder_root"
         setfacl --remove-all -d -m user::rwx,group::rwx,other::rwx -P -R "$fTarget_folder_root"; chmod 777 -R "$fTarget_folder_root"
     fi    
  fi
  if [ "$OPT_device_type" == "0" -a "$fGuest_only" == "yes" ]; then
      CHMOD_ACL="--chmod=ugo=rwX"
   else
      CHMOD_ACL="" 
  fi
  if [ ! -d "$fTarget_folder/${OPT_folder}" ];then
             dest_folder_n="$fTarget_folder/${OPT_folder}"
             mkdir -m 777 "$dest_folder_n"
             if [ "$OPT_device_type" == "1" ];then
               chown nobody.nogroup "${dest_folder_n}"
              else
               chown nobody.users "${dest_folder_n}"
             fi
     else
             dest_folder_n="$fTarget_folder/""${OPT_folder}"   
  fi
  raidid=""
  fRaidIdList=`Lraid_get_raidmd_list`
  for fRaidmd in ${fRaidIdList}
  do
        flagc=`$sqlite /raid$fRaidmd/sys/smb.db ".schema"|grep iscsi|wc -l`
        if [ $flagc -gt 0 ];then
             flagc=`$sqlite /raid$fRaidmd/sys/smb.db "select * from iscsi where name='$folder_check'"|wc -l`
             if [ $flagc -gt 0 ];then
                raidid="$fRaidmd"
                break;
             fi
        fi 
  done
  if [ "$raidid" != "" ];then
      /img/bin/rc/rc.iscsi delete "$folder_check" $raidid
      echo "$dest_folder_n"
      cd "$fSource_folder"
      ls -l | awk -F ' ' '{printf("%s %s\n",$5,$9)}' > "$dest_folder_n"/"size_data"
      echo "$folder_check" > "$dest_folder_n"/"iscsi_name"
      cp /raid$raidid/sys/smb.db "$dest_folder_n"
      getfacl "$fSource_folder/" > "$dest_folder_n"/"acl_data"
      cd "$dest_folder_n"
      if [ ! -d "/raid/data/tmp/check_iscsi/$tid" ];then
              mkdir "/raid/data/tmp/check_iscsi/$tid"
      fi
      cp smb.db "/raid/data/tmp/check_iscsi/$tid"
      cp size_data "/raid/data/tmp/check_iscsi/$tid"
      cp iscsi_name "/raid/data/tmp/check_iscsi/$tid"
      cp acl_data "/raid/data/tmp/check_iscsi/$tid"
      tar zcvf .iscsi.tar.gz smb.db size_data iscsi_name acl_data
      des -E -k iscsi_zip .iscsi.tar.gz .iscsi.bin
      rm -rf .iscsi.tar.gz
      rm -rf size_data iscsi_name smb.db acl_data
      if [ "$OPT_device_type" == "0" ];then 
            RSYNC_PARA="-8rltDvHX"
       else
            RSYNC_PARA="-8rltDvH"
      fi      
      strexec="/usr/bin/rsync $RSYNC_PARA $CHMOD_ACL --delete --log-file=\"/raid/data/tmp/rsync_backup.${CFG_task_name}\" --progress --inplace --timeout=600 --exclude-from=\"$ISO_TMP\" \"$fSource_folder/\"*\"\" \"$dest_folder_n/\" > $COUNT_FILE"
      eval "$strexec"
      ret=`echo $?`
      if [ "$ret" != "137" ]; then
           if [ "$ret" != "" ]; then
               tmp_fSource_folder=`basename "${fSource_folder}"`
               eventlog "$CFG_task_name" "$ret" "${gAction}" "$LOG_TMP" "${tmp_fSource_folder}" "$CFG_act_type"
           fi
       else
           tmp_dest_folder_n=`basename "${dest_folder_n}"`
           eventlog "$CFG_task_name" "37" "${gAction}" "$LOG_TMP" "${tmp_dest_folder_n}" "$CFG_act_type"
      fi
      rm -rf /raid/data/tmp/iscsi_backup
      /img/bin/rc/rc.iscsi add "$folder_check" $raidid
      rm -rf "/raid/data/tmp/check_iscsi/$tid"
      Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
  fi
}
start(){
  tid=$1
  conf $1 $2

}
restore(){
  tid=$1
  external_folder=$2
  eval `db_to_env $tid`
  if [ "$gAction" == "import" ]; then
          if [ "$CFG_back_type" != "import_iscsi" ];then
                return
          fi
   else
       if [ "$gAction" == "restore" ]; then
          if [ "$CFG_back_type" != "iscsi" ];then
                return
          fi
       fi   
  fi
  if [ "$gAction" == "import" ];then
        action="start"
   else
        if [ "$gAction" == "restore" ];then
             action="restore"
        fi
  fi        
  COUNT_FILE="/tmp/rsync_backup_${CFG_task_name}.count"
  LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
  STATUS_FILE="/tmp/rsync_backup_${CFG_task_name}.status"
  check_log_folder "${CFG_task_name}" "${OPT_log_folder}" "${action}"
  Ldataguard_get_raid_status "$CFG_task_name" "$action" "$LOG_TMP" "$log_path"
  Ldataguard_get_migrate_status "$CFG_task_name" "$action" "$LOG_TMP" "$log_path"  "$CFG_act_type"
  Ldataguard_check_status "$CFG_task_name" "$STATUS_FILE" "$action" "$CFG_act_type"
  ISO_TMP="/tmp/rsync_${CFG_task_name}_iso_tmp.log"
  ISO_FILE="/tmp/rsync_${CFG_task_name}_iso.log"
  get_iso_info "$ISO_FILE"
  touch "$ISO_TMP"
  path="${OPT_path}/${OPT_folder}"
  cat "$ISO_FILE" | \
   while read iso_path
   do
         folder_name=`echo "${path}" | awk -F"/" '{print $2}'`
         echo "${iso_path}" | awk -F"/" "{if (\$2==\"$folder_name\")print \$NF}" >> "$ISO_TMP"
   done 
   path=`echo "${path}" | sed "s/'/\'\\\\\\''/g"`    
   path_list="${path_list}'${path}' "
   if [ "$gAction" == "import" ]; then
       if [ "$OPT_device_type" == "0" ];then
             fSource_path_list=`Ldataguard_backup_source "$CFG_task_name" "$path_list"`
             fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
             fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`
             if [ ! -z "$fLoss_folder" ]; then
                  echo "$$fLoss_folder" | sed 's/,$//g'
                  eventlog "$CFG_task_name" "16" "$action" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
                  if [ -z "$fSource_folder" ]; then
                          Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
                          exit
                  fi    
             fi
             eval "lsyncd_fList=($fSource_folder)"
             fSource_folder=${lsyncd_fList[0]}
       fi      
       if [ "$OPT_device_type" == "0" ];then
             folder_path="$fSource_folder"
       else
             folder_path="$external_folder""${OPT_path}/${OPT_folder}"
       fi
    else
      if [ "$gAction" == "restore" ]; then
         if [ "$OPT_device_type" != "1" ]; then
             fSource_path_list=`get_tge_folder_path 2`
         else    
             fSource_path_list=`Ldataguard_restore_source "$CFG_task_name" "$path_list" "$OPT_target" "$OPT_target_tag" "$OPT_device_type" ""`
         fi    
         fLoss_folder=`echo "$fSource_path_list" | awk -F"//" '{print $1}'`
         fLoss_folder=`echo "$fLoss_folder" | sed 's/, $//g'`
         fSource_folder=`echo "$fSource_path_list" | awk -F"//" '{print $2}'`
         if [ ! -z "$fLoss_folder" ]; then
            eventlog "$CFG_task_name" "16" "$action" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
            if [ -z "$fSource_folder" ]; then
                Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
                exit
            fi
         fi
         eval "folder_path=($fSource_folder)"
      fi
  fi
  if [ ! -d "/raid/data/tmp/check_iscsi/$tid" ];then
     mkdir "/raid/data/tmp/check_iscsi/$tid"
  fi
             
  cp "$folder_path"/.iscsi.bin "/raid/data/tmp/check_iscsi/$tid"
  cd "/raid/data/tmp/check_iscsi/$tid"
  des -D -k iscsi_zip .iscsi.bin .iscsi.tar.gz
  tar zxvf .iscsi.tar.gz
  rm -rf .iscsi.tar.gz
  rm -rf .iscsi.bin
  check_iscsi=`check_iscsifolder "$tid" "$folder_path"`
  if [ "$check_iscsi" != "0" ];then
         eventlog "$CFG_task_name" "39" "$action" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
         rm -rf "/raid/data/tmp/check_iscsi/$tid"
         Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
         exit
  fi
  check_name=`cat "/raid/data/tmp/check_iscsi/$tid/iscsi_name"`
  check_same=`check_same_folder "$tid" "iSCSI_$check_name"`
  if [ "$check_same" == "1" ];then
        rm -rf "/raid/data/tmp/check_iscsi/$tid"
        eventlog "$CFG_task_name" "40" "$action" "$LOG_TMP" "$iSCSI_$check_name" "$CFG_act_type"
        Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
        exit
  fi
  dest_folder=`cat /raid/data/tmp/check_iscsi/$tid/iscsi_name`
  target=""
  raid_id=""
  target_import=""
  fRaidIdList=`Lraid_get_raidmd_list`
  for fRaidmd in ${fRaidIdList}
   do
      flagc=`$sqlite /raid$fRaidmd/sys/smb.db ".schema"|grep iscsi|wc -l`
      if [ $flagc -gt 0 ];then
           flagc=`$sqlite /raid$fRaidmd/sys/smb.db "select * from iscsi where name='$dest_folder'"|wc -l`
           if [ $flagc -gt 0 ];then
                raid_id="$fRaidmd"
                target="raid""$raid_id"
                target_import="raid""$raid_id"
                break;
           fi
      fi
   done
 if [ "$OPT_device_type" == "0" ];then
        RSYNC_PARA="-8rltDvHX"
  else
        RSYNC_PARA="-8rltDvH"
 fi
 #CHMOD_ACL="--chmod=ugo=rwX"
 CHMOD_ACL=""  
 if [ "$gAction" == "restore" ]; then
     if [ "$target" == "" ];then
       rm -rf "/raid/data/tmp/check_iscsi/$tid"
       fLoss_folder="iSCSI_$check_name"
       eventlog "$CFG_task_name" "37" "$action" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
       Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
       exit
     fi
     restore_raid=`Ldataguard_check_uuid "$OPT_src_uuid"`
     restore_raid=`echo $restore_raid|sed 's/\///g'`
     if [ "$restore_raid" != "$target" ];then
         fLoss_folder="iSCSI_$check_name"
         rm -rf "/raid/data/tmp/check_iscsi/$tid"
         eventlog "$CFG_task_name" "37" "$action" "$LOG_TMP" "$fLoss_folder" "$CFG_act_type"
         Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
         exit
     fi
     dest_folder1="iSCSI_""$dest_folder"
     /img/bin/rc/rc.iscsi delete "$dest_folder" "$raid_id"
     if [ -d "/$target/data/$dest_folder1" ];then
          rm -rf /"$target"/data/"$dest_folder1"
     fi
     dest_folder_n="/raid/data/ftproot/${dest_folder1}"
     $sqlite /$target/sys/smb.db "delete from smb_userfd where share='$dest_folder1'"
     get_folder_info "${dest_folder1}" "${dest_folder1}"
     delete_iscsi_table "${dest_folder}"
     insert_iscsi_table "${dest_folder}" "${dest_folder}" "1"
     strexec="/usr/bin/rsync $RSYNC_PARA $CHMOD_ACL --delete --log-file=\"/raid/data/tmp/rsync_backup.$CFG_task_name\" --progress --timeout=600 --inplace --exclude-from=\"$ISO_TMP\" \"$folder_path/\"*\"\" \"$dest_folder_n/\" > $COUNT_FILE"
     eval "$strexec"
     ret=`echo $?`
     if [ "$ret" != "137" ]; then
             if [ "$ret" != "" ]; then
                   tmp_folder_path=`basename "${folder_path}"`
                   eventlog "$CFG_task_name" "$ret" "$action" "$LOG_TMP" "${tmp_folder_path}" "$CFG_act_type"
             fi
      else
             tmp_dest_folder_n=`basename "${dest_folder_n}"`
             eventlog "$CFG_task_name" "37" "$action" "$LOG_TMP" "${tmp_dest_folder_n}" "$CFG_act_type"
     fi
 else 
    if [ "$gAction" == "import" ]; then
           target="${OPT_target}"
           raid_id=`echo $target|sed 's/\/raid//g'`
           if [ "$target_import" == "" ];then
                   iscsi_tmp_name="${dest_folder}"
              else
                 for ((i=1;i<=10000;i++))
                 do
                   iscsi_no_flag="" 
                   iscsi_no_data="${dest_folder}-""$i"
                   for fRaidmd in ${fRaidIdList}
                    do
                         flagc=`$sqlite /raid$fRaidmd/sys/smb.db ".schema"|grep iscsi|wc -l`
                         if [ $flagc -gt 0 ];then
                               flagc=`$sqlite /raid$fRaidmd/sys/smb.db "select * from iscsi where name='$iscsi_no_data'"|wc -l`
                               if [ $flagc -gt 0 ];then
                                 iscsi_no_flag="1"
                               fi
                         fi
                    done
                    if [ "$iscsi_no_flag" == "" ];then
                           iscsi_tmp_name="$iscsi_no_data"
                           break
                    fi
                    
                 done
                 folder_msg="[ ${dest_folder} ] to [ ${iscsi_tmp_name} ]"
                 eventlog "$CFG_task_name" "41" "$action" "$LOG_TMP" "$folder_msg" "$CFG_act_type"
           fi
           echo "${iscsi_tmp_name}" > /tmp/import_iscsi_check
           dest_folder2="iSCSI_""${dest_folder}"
           dest_folder1="iSCSI_""${iscsi_tmp_name}"
           dest_folder_n="/raid/data/ftproot/${dest_folder1}"
           get_folder_info "${dest_folder2}" "${dest_folder1}"
           insert_iscsi_table "${dest_folder}" "${iscsi_tmp_name}" "2"
           if [ "$ret" != "137" ]; then
                if [ "$ret" != "" ]; then
                      tmp_folder_path=`basename "${folder_path}"`
                      eventlog "$CFG_task_name" "$ret" "$action" "$LOG_TMP" "${tmp_folder_path}" "$CFG_act_type"
                fi
             else
                      tmp_dest_folder_n=`basename "${dest_folder_n}"`
                      eventlog "$CFG_task_name" "37" "$action" "$LOG_TMP" "${tmp_dest_folder_n}" "$CFG_act_type"
           fi
    fi
  fi         
  
  rm -rf "$dest_folder_n"/.iscsi.bin
  setfacl --set-file="/raid/data/tmp/check_iscsi/$tid/acl_data" "/$target/data/$dest_folder1"
  if [ "$gAction" == "import" ]; then
     cd "$dest_folder_n"
     mv * $iscsi_tmp_lun
     /img/bin/rc/rc.iscsi add $iscsi_tmp_name $raid_id
   else
     /img/bin/rc/rc.iscsi add $dest_folder $raid_id
  fi
  rm -rf "/raid/data/tmp/check_iscsi/$tid"
  Ldataguard_change_status "$CFG_task_name" "$LOG_TMP" "$log_path"
  
}

stop(){
  tid=$1
  eval `db_to_env $tid`
  LOG_TMP="/raid/data/tmp/rsync_backup.${CFG_task_name}"
  if [ "$CFG_back_type" == "iscsi" ];then 
       folder_check=`echo ${OPT_folder}|sed 's/iSCSI_//g'` 
       rootpath=`ls -1l "/raid/data/ftproot" | sed -nr 's/.{39}/\2/p' | sed -nr 's/^('"$OPT_folder"') -> (\/.*)/\2/p'` 
       raid_id=`echo "$rootpath" | awk -F"/" '{print $2}'` 
       raid_id_check=`echo ${raid_id}|sed 's/raid//g'` 
       /img/bin/rc/rc.iscsi add "$folder_check" "$raid_id_check"
  fi
  if [ "$CFG_back_type" == "import_iscsi" ];then
       import_iscsi_check=`cat /tmp/import_iscsi_check`
       iscsi_folder_name="iSCSI_$import_iscsi_check"
       rootpath=`ls -1l "/raid/data/ftproot" | sed -nr 's/.{39}/\2/p' | sed -nr 's/^('"$iscsi_folder_name"') -> (\/.*)/\2/p'`
       raid_id=`echo "$rootpath" | awk -F"/" '{print $2}'`   
       raid_id_check=`echo ${raid_id}|sed 's/raid//g'`
       /img/bin/rc/rc.iscsi add "$import_iscsi_check" "$raid_id_check"
  fi
  Ldataguard_stop_task "$CFG_tid" "$CFG_task_name" "$PROCESS_NAME" "$LOG_TMP" "$OPT_log_folder" "$CFG_act_type"
}
allstop(){
  $sqlite $db "select tid from task where (back_type='iscsi' or back_type='import_iscsi') and act_type='local'" | while read file;do
  stop ${file} 
  done
}
allstart(){
  $sqlite $db "select tid from task where back_type='real' and act_type='local'" | while read file;do
    sys_status=`$sqlite $db "select value from opts where tid=$file and key='sys_status'"`
    if [ "$sys_status" == "1" ];then
       start $file
    fi
  done
}

  
case "$1"
in
   create|modify)
     task_create $2 $3
     ;; 
   start)
     start $2 $3
     ;;
   stop)
     stop $2
     ;;
   restore|import)
     restore $2 $4
     ;; 
   allstop)
     allstop
     ;;
   get_iscsiname)
     get_iscsiname "$2"
     ;;
   get_iscsi_use)
     get_iscsi_use "$2"
     ;;
   *)
     echo "Usage: $0 { conf | start | stop }"
     ;;
esac
