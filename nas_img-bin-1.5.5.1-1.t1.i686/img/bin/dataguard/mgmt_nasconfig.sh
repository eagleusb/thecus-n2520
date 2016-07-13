#!/bin/sh
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
sqlite="/usr/bin/sqlite"
var_tmp="/var/tmp"
create_user_folder="/img/bin/user_folder.sh"
rsync_test="/img/bin/rsync_test.sh"

raid2raid()
{
  local raidno="$1"
  local backup_smbpath="$2"
  local folder_list="$3"
  local smbpath="${backup_smbpath}/smb.db"
  
  if [ -f ${smbpath} ] && [ "${folder_list}" == "" ];then
    folder_list=`${sqlite} ${smbpath} "select share from smb_userfd"`
  fi
  
  if [ "${folder_list}" == "" ];then
    echo "No folder list!"
    return 1
  fi
  
  echo -e "$folder_list" | \
  while read folder
  do
    is_iSCSI=`echo "${folder}" | grep -v "^iSCSI_*"`
    if [ "${is_iSCSI}" == "" ];then
      continue
    fi
    
    folderexist=`checkfolder "${folder}"`
    if [ "${folderexist}" == "" ];then
      folderinfo=`${sqlite} ${smbpath} "select * from smb_userfd where share='${folder}'"`
      if [ "${folderinfo}" != "" ];then
        comment=`echo $folderinfo | awk -F'|' '{print $2}'`
        browseable=`echo $folderinfo | awk -F'|' '{print $3}'`
        guestonly=`echo $folderinfo | awk -F'|' '{print $4}'`
      
        ${create_user_folder} "add" "${folder}" "${raidno}" "${comment}" "${browseable}" "${guestonly}"
      fi
    fi
  done
  
  cd /
  setfacl --restore=/raid/data/tmp/mgmt_nasconfig/backup.acl
}

#######################################################
#
#  get conf file to restore
#
#######################################################
backup_conf_from_remote(){
  local filename=$1
  local username=$2
  local passwd=$3
  local ip=$4
  local port=$5
  local tarfolder="/raid/data/tmp/mgmt_nasconfig"
  
  rm -rf ${tarfolder}
  
  if [ "${port}" == "" ];then
    port=873
  fi
  
  echo "${passwd}" > "/tmp/rsync_passwd"
  chmod 600 "/tmp/rsync_passwd"
  
  rm -rf /tmp/rsync_restore_log
  strExec="/usr/bin/rsync --port=${port} --chmod=ugo=rwX --timeout=600 --log-file=/tmp/rsync_restore_log --password-file=\"/tmp/rsync_passwd\" \"${username}@${ip}::raidroot/_SYS_TMP/remote_conf/${filename}\" \"/raid/data/tmp\""
  eval $strExec
  echo $?
  if [ "$?" == "23" ];then
      echo "No such file or directory"       
      exit
  elif [ "$?" == "10" ];then
      echo "IP incorrect"
      exit
  elif [ "$?" == "5" ];then    
      echo "passwd or username incorrect"
      exit
  fi
  
  /bin/tar xzf "/raid/data/tmp/${filename}" -C /
  
  cd ${tarfolder}
  enckey=`/img/bin/check_service.sh key`;
  /usr/bin/des -k conf_${enckey} -D $tarfolder/conf.bin $tarfolder/conf.tar.gz
  rm $tarfolder/conf.bin
  
  if [ "$?" == "0" ];then 
      mkdir $tarfolder/conf
      tar zxf $tarfolder/conf.tar.gz -C $tarfolder/conf
      rm $tarfolder/conf.tar.gz
      ${sqlite} $tarfolder/conf/etc/cfg/backup.db "update opts set value='0' where key='schedule_enable' and tid in (select tid from task where act_type='remote')"
      ${sqlite} $tarfolder/conf/etc/cfg/backup.db "update task set back_type='schedule', status='7' where act_type='remote'"
      cd $tarfolder/conf
      tar zcvf conf.tar.gz *
      /usr/bin/des -k conf_${enckey} -E $tarfolder/conf/conf.tar.gz $tarfolder/conf.bin
  fi

}

#######################################################
#
#  det remote conf list
#
#######################################################
remote_list(){
  local ip=$1
  local port=$2 
  local username=$3
  local passwd=$4
  
  local passwdfile="/tmp/rsync_${ip}_passwd"
  echo "${passwd}" > ${passwdfile}
  chmod 600 ${passwdfile}

  /usr/bin/rsync --list-only --port=${port} "${username}@${ip}::raidroot/_SYS_TMP/remote_conf/" --password-file=${passwdfile} > /tmp/conf_${ip}_list
  
  rm ${passwdfile}
}

checkfolder(){
  local share="$1"
  md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
  if [ "${md_list}" == "" ];then
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
  fi

  for md in $md_list
  do
    raid="raid${md}"

    if [ -d "/$raid/" ];then
      status=`cat ${var_tmp}/${raid}/rss`
      
      if [ "${status}" == "Damaged" ];then
        echo "The RAID [ ${raid} ] is Damaged!"
        continue
      fi

      tmp_db="/$raid/sys/smb.db"

      db_exist=`$sqlite ${tmp_db} "select share from smb_specfd where share='${share}'"`
      if [ "${db_exist}" == "" ];then
        db_exist=`$sqlite ${tmp_db} "select share from smb_userfd where share='${share}'"`
      fi

      if [ "${db_exist}" != "" ];then
        echo "1"
      fi
    fi
  done
}

raidnum_id(){
  local path="$1"
  
  cd ${path}
  folderlist=`ls`
  
  for folder in ${folderlist}
  do
    if [ -d "${path}/${folder}" ];then
      if [ -f "${path}/${folder}/smb.db" ];then
        raidid=`$sqlite "${path}/${folder}/smb.db" "select v from conf where k='raid_name'"`
        echo "${folder}|${raidid}"
      fi
    fi
  done
}

check_nas_folder(){
  local taskname=$1
  local ip=$2
  local port=$3 
  local username=$4
  local passwd=$5
  local folder=$6
  
  local smbpath="/raid/data/tmp/dataguard.check_nas_folder"
  local cmdscript="${smbpath}/cmdscript"
  local passwdfile="/tmp/dataguard.check_nas_folder.${taskname}"
  echo "${passwd}" > "${passwdfile}"
  chmod 600 "${passwdfile}"
  
  if [ ! -d "${smbpath}" ];then
    mkdir -p ${smbpath}
  fi
  
  rm ${cmdscript}
  
  if [ "${port}" == "" ];then
    port="873"
  fi

  if [ "`echo ${ip}|grep '^\['`" == "" ];then
    ret=`/usr/bin/ipv6check -p "${ip}"`
    if [ "${ret}" != "ipv6 format Error" ];then
      ip="[${ip}]"
    fi
  fi
  
  /usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --timeout=15 --contimeout=15 --password-file="${passwdfile}" "${username}@${ip}::raidroot/sys/smb.db" "${smbpath}" 
  
  if [ ! -f "${smbpath}/smb.db" ];then
    echo "1"
    exit
  fi

  md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
  if [ "${md_list}" == "" ];then
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
  fi
  
  folder_count=`echo "$folder" | awk -F'/' '{print NF}'`
  for ((i=1;i<=$folder_count;i++))
  do
    strExec="echo '$folder' | awk -F'/' '{print \$$i}'"
    single_folder=`eval $strExec`
    test_result=`${rsync_test} "${ip}" "${ip}" "${port}" "${single_folder}" "${username}" "${passwd}"`
    test_ret=`echo ${test_result}|awk '{print $NF}'`
    
    if [ "${test_ret}" == "703" ];then
      system_folder=`${sqlite} "${smbpath}/smb.db" "select * from smb_specfd where share='${single_folder}'"`
      ret=`${sqlite} "${smbpath}/smb.db" "select * from smb_userfd where share='${single_folder}'"`
      guest_only="no"
      browseable="yes"
      map_hidden="no"
      recursive="yes"
      readonly="0"

      for md in $md_list
      do
        raid="raid${md}"
        tmp_db="/$raid/sys/smb.db"

        data_exist=`$sqlite ${tmp_db} "select [guest only], browseable, [map hidden], recursive, comment, readonly from smb_userfd where share='${single_folder}'"`
        if [ "${data_exist}" != "" ];then
          guest_only=`echo ${data_exist} | awk -F'|' '{print $1}'`
          browseable=`echo ${data_exist} | awk -F'|' '{print $2}'`
          map_hidden=`echo ${data_exist} | awk -F'|' '{print $3}'`
          recursive=`echo ${data_exist} | awk -F'|' '{print $4}'`
          comment=`echo ${data_exist} | awk -F'|' '{print $5}'`
          readonly=`echo ${data_exist} | awk -F'|' '{print $6}'`
          break;
        fi
      done
      

      if [ "${ret}" == "" ] && [ "${system_folder}" == "" ];then
        ${sqlite} "${smbpath}/smb.db" "insert into smb_userfd(share,comment,browseable,'guest only',path,'map hidden', recursive, readonly, speclevel) values('${single_folder}','${comment}', '${browseable}', '${guest_only}', '${single_folder}','${map_hidden}','${recursive}', '${readonly}','')"
        echo "chown nobody:users /raid/data/${single_folder}" >> ${cmdscript}

        if [ "${guest_only}" == "yes" ];then
          echo "chmod 777 /raid/data/${single_folder}" >> ${cmdscript}
        fi

        test_result=`${rsync_test} "${ip}" "${ip}" "${port}" "raidroot" "${username}" "${passwd}" "0" "/${single_folder}"`
      fi
    fi
  done 
  
  if [ "`cat ${cmdscript}`" != "" ];then
    echo "/img/bin/rc/rc.samba reload" >> ${cmdscript}
    echo "/img/bin/rc/rc.atalk reload" >> ${cmdscript}
    echo "/img/bin/rc/rc.rsyncd rebuildconf" >> ${cmdscript}
    /usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --timeout=30 --password-file="${passwdfile}" "${smbpath}/smb.db" "${username}@${ip}::raidroot/sys/smb.db"
    /usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --timeout=30 --password-file="${passwdfile}" "${cmdscript}" "${username}@${ip}::raidroot/tmp/"
    sleep 15
  fi
  
  rm -rf "${smbpath}"
  rm "${passwdfile}"
}

case "$1" in
  raid)
    raid2raid "$2" "$3"
    ;;
  folder)
    raid2raid "$2" "$3" "$4"
    ;;
  getconf)
    backup_conf_from_remote "$2" "$3" "$4" "$5" "$6" 
    ;;
  raidnum_id)
    raidnum_id "$2"
    ;;
  check_nas_folder)
    check_nas_folder "$2" "$3" "$4" "$5" "$6" "$7"
    ;;
  *)
    echo "Usage: {raid|folder|getconf|raidnum_id|check_nas_folder}"  >&2
    exit 1
    ;;
esac
