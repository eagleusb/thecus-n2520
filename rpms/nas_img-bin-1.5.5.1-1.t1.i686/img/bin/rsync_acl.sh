#!/bin/sh
taskname=$2
raidno=$3
realpath=$4
mode=$5
ftp_user=$6
remote_ip=$7
host=$8
is_first=$9
source_acl_file="/tmp/${taskname}_acl"
target_acl_file="/tmp/${taskname}.acl"
log_file="/tmp/${taskname}_log"
diff_acl_file="/tmp/${taskname}_tmp.acl"
rsync="/usr/bin/rsync"
getfacl="/usr/bin/getfacl"
rm="/bin/rm"
mv="/bin/mv"
cat="/bin/cat"
setfacl="/usr/bin/setfacl"
raid_path="/${raidno}/data"
tmp_file="/tmp/${taskname}_file"

get_acl(){
  $getfacl -R --absolute-names "${realpath}"/* > "${source_acl_file}"
  
  if [ "${mode}" == "1" ];then
    if [ "${is_first}" == 0 ];then    
        cat "${log_file}" | awk -F'\+\+\+\+\+\+\+\+\+ ' '{printf("%s\n",$NF)}' > ${tmp_file}
        cat "${tmp_file}" | \
        while read file_acl
        do
          if [ -e "${raid_path}/${file_acl}" ];then
            $getfacl --absolute-names "${raid_path}/${file_acl}" >> "${target_acl_file}"  
          fi
        done
    else
      $mv "${source_acl_file}" "${target_acl_file}"
      
    fi
  else
    $mv "${source_acl_file}" "${target_acl_file}"
  fi
  
  ${rsync} -rvlHDtS --chmod=ugo=rwX --delete --timeout=180 --password-file="/tmp/rsync.${taskname}" "${target_acl_file}" "$ftp_user@$remote_ip::rsync_backup/$host/${taskname}.acl" 
  
  rm "${source_acl_file}"
  rm "${target_acl_file}"
  rm "${diff_acl_file}"
  rm "${tmp_file}"
}

set_acl(){
  $setfacl --restore="${target_acl_file}"
}
#################################################
##      Main
#################################################
case "$1"
in
  get)
    get_acl 
    ;;
  set)
    set_acl
    ;;
  *)
   echo "Usage: $0 {get|set}"
   ;;
esac
