#!/bin/sh
#
# Check the Quota size
#
QUOTAPATH="/usr/sbin"
logevent="/img/bin/logevent/event"

check_list()
{
  userlist=$1
  role=$2
  namelist=""
  
  if [ "${userlist}" != "" ];then
    for t_user in ${userlist}
    do
      if [ "${name}" != ${t_user} ];then
        name=${t_user}
      
        if [ "${namelist}" == "" ];then
          namelist=${t_user}
        else
          namelist="${namelist}, ${t_user}"
        fi
      fi
    done
    
    $logevent 997 512 warning email "${role}" "${namelist}"
  fi
}

users=`${QUOTAPATH}/repquota -a | grep +- | awk -F " " '{print $1}' | sort -u`
check_list "${users}" "User"

groups=`${QUOTAPATH}/repquota -ag | grep +- | awk -F " " '{print $1}' | sort -u`
check_list "${groups}" "Group"


