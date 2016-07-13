#!/bin/bash
taskname=$1
ip=$2
port=$3
dest_folder=$4
username=$5
passwd=$6
encrypt_on=$7
build_subfolder=$8

binpath="/img/bin"

. "${binpath}/logevent/event_message.sh"

tmpfolder=""
rm -rf "/tmp/rsync_${taskname}"
mkdir "/tmp/rsync_${taskname}"
log="/tmp/${taskname}_log"
echo "${passwd}" > "/tmp/rsync.${taskname}"
chmod 600 "/tmp/rsync.${taskname}"

if [ "${port}" == "" ];then
    port="873"
fi

if [ "`echo ${ip}|grep '^\['`" == "" ];then
  ret=`/usr/bin/ipv6check -p "${ip}"`
  if [ "${ret}" != "ipv6 format Error" ];then
    ip="[${ip}]"
  fi
fi

if [ "${encrypt_on}" == "1" ] || [ "${encrypt_on}" == "2" ];then
  if [ -f "/etc/ssh/id_dsa.new" ] && [ -f "/etc/ssh/id_dsa.pub.new" ];then
    ssh_option=" -i /etc/ssh/id_dsa.new"
  else
    ssh_option=" -i /etc/ssh/id_dsa"
  fi
fi

if [ "${encrypt_on}" == "1" ];then
  /usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --contimeout=18 --timeout=15 --log-file="${log}" --password-file="/tmp/rsync.${taskname}" "/tmp/rsync_${taskname}/" "${username}@${ip}::${dest_folder}" > /dev/null 2>&1
  RET=$?
  if [ "${RET}" == "0" ]; then
    /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --timeout=15 -e "/usr/bin/ssh ${ssh_option} -p 23 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" --log-file="${log}" "/tmp/rsync_${taskname}/" "root@${ip}:/raid/data/ftproot/" > /tmp/rsync_ssh_log_${taskname} 2>&1
    RET=$?
  fi
elif [ "${encrypt_on}" == "2" ];then
  #check SSH if enabled
  /usr/bin/rsync -rvlHDtS --chmod=ugo=rwX --timeout=15 -e "/usr/bin/ssh ${ssh_option} -p 23 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" --log-file="${log}" "/tmp/rsync_${taskname}/" "root@${ip}:/raid/data/ftproot/" > /tmp/rsync_ssh_log_${taskname} 2>&1
  RET=$?
else
  /usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --contimeout=18 --timeout=15 --log-file="${log}" --password-file="/tmp/rsync.${taskname}" "/tmp/rsync_${taskname}/" "${username}@${ip}::${dest_folder}" > /dev/null 2>&1
  RET=$?
fi

if [ "${RET}" != "" ];
then
    if [ "${RET}" == "0" ]; then
        event["707"]=`get997msg 707`
        msg=`printf "${event["707"]} 707" "${ip}"`
        #automatically building subfolder for later backup
        if [ "${build_subfolder}" != "" ];then
          RES=`/usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --contimeout=18 --timeout=15 --log-file="${log}" --password-file="/tmp/rsync.${taskname}" "/tmp/rsync_${taskname}/" "${username}@${ip}::${dest_folder}${build_subfolder}" 2>/dev/null`
          RET=$?

          if [ "${RET}" != "0" ];then
            folder_count=`echo "$build_subfolder" | awk -F'/' '{print NF}'`
            for ((i=2;i<=$folder_count;i++))
            do
              strExec="echo '$build_subfolder' | awk -F'/' '{print \$$i}' "
              folder=`eval $strExec| awk -F'/' '{print $1}'`
              tmpfolder="${tmpfolder}${folder}/"
              RES=`/usr/bin/rsync -rvlHDtS --port="${port}" --chmod=ugo=rwX --timeout=30 --log-file="${log}" --password-file="/tmp/rsync.${taskname}" "/tmp/rsync_${taskname}/" "${username}@${ip}::${dest_folder}/${tmpfolder}" 2>/dev/null`              
            done
          fi
        fi
    elif [ "${RET}" == "5" ]; then
        RET="100"
        err_msg=`cat "${log}" | grep " @ERROR: auth failed on module"`
        if [ "${err_msg}" != "" ];then
            event["701"]=`get997msg 701`
            msg=`printf "${event["701"]} 701"`
        fi

        err_msg=`cat "${log}" | grep "@ERROR: Unknown module"`
        if [ "${err_msg}" != "" ];then
            event["703"]=`get997msg 703`
            msg=`printf "${event["703"]} 703" "${dest_folder}"`
        fi

        err_msg=`cat "${log}" | grep "@ERROR: chroot failed"`
        if [ "${err_msg}" != "" ];then
            event["704"]=`get997msg 704`
            msg=`printf "${event["704"]} 704"`
        fi
        
        err_msg=`cat "${log}" | grep "@ERROR: max connections"`
        if [ "${err_msg}" != "" ];then
            event["709"]=`get997msg 709`
            msg=`printf "${event["709"]} 709"`
        fi
    elif [ "${RET}" == "10" ] || [ "${RET}" == "35" ]; then
        event["700"]=`get997msg 700`
        msg=`printf "${event["700"]} 700"`
    elif [ "${RET}" == "11" ]; then
        event["706"]=`get997msg 706`
        msg=`printf "${event["706"]} 706"`
    elif [ "${RET}" == "12" ]; then
      if [ "${encrypt_on}" == "1" ];then
        event["711"]=`get997msg 711`
        msg=`printf "${event["711"]} 711"`
      else
          err_msg=`cat "${log}" | grep "No space left"`
          if [ "${err_msg}" != "" ];then
              event["708"]=`get997msg 708`
              msg=`printf "${event["708"]} 708"`
          else
              err_msg=`cat "${log}" | grep "File too large (27)"`
              if [ "${err_msg}" != "" ];then
                  event["706"]=`get997msg 706`
                  msg=`printf "${event["706"]} 706"`
              else
                  event["703"]=`get997msg 703`
                  msg=`printf "${event["703"]} 703" "${dest_folder}"`
              fi
          fi
      fi
    elif [ "${RET}" == "30" ]; then
        event["702"]=`get997msg 702`
        msg=`printf "${event["702"]} 702"`
    else
        ssh_msg=`cat "/tmp/rsync_ssh_log_${taskname}"|grep "ssh:"|grep "Connection refused"`
        ssh_msg2=`cat "/tmp/rsync_ssh_log_${taskname}"|grep "Connection closed by remote host."`
        if [ "${ssh_msg}" != "" ];then
          event["712"]=`get997msg 712`
          msg=`printf "${event["712"]} 712"`
        elif [ "${ssh_msg2}" != "" ];then
          event["713"]=`get997msg 713`
          msg=`printf "${event["713"]} 713"`
        else 
          event["710"]=`get997msg 710`
          msg=`printf "${event["710"]} 710"`
        fi
    fi

    rm -rf "/tmp/rsync.${taskname}"
    rm -rf "/tmp/rsync_${taskname}"
    rm -rf "${log}"
    rm -rf "/tmp/rsync_ssh_log_${taskname}"
    echo ${msg}
fi

