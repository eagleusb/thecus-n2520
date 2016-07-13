#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
export LANG=en_US.UTF-8

taskname=$1
key=$2
secret_key=$3
dest_folder=$4
sub_folder=$5

s3cmd="/img/bin/dataguard/s3cmd/s3cmd"
default_conf_file="/img/bin/dataguard/s3cmd/s3_default_conf"
conf_file="/tmp/dataguard_${taskname}_conf_test"
err=0

. "/img/bin/logevent/event_message.sh"

cp ${default_conf_file} ${conf_file}
echo "access_key = ${key}" >> ${conf_file}
echo "secret_key = ${secret_key}" >> ${conf_file}
chmod 600 ${conf_file}

conn_log=`${s3cmd} --config=${conf_file} info "s3://${dest_folder}" 2>&1`
RET=$?

bucket_exist=`echo "${conn_log}" | grep "^s3://${dest_folder}/ (bucket):$"`

if [ "${bucket_exist}" != "" ];then
    if [ "${sub_folder}" != "" ];then
        sub_folder_exist=`${s3cmd} --config=${conf_file} ls "s3://${dest_folder}/${sub_folder}" 2>&1| grep "s3://${dest_folder}/${sub_folder}/"`

        if [ "${sub_folder_exist}" == "" ];then
            event["703"]=`get997msg 703`
            msg=`printf "${event["703"]} 703" "${dest_folder}/${sub_folder}"`
            err=1
        fi
    fi
    
    if [ "${err}" == "0" ];then
        event["707"]=`get997msg 707`
        msg=`printf "${event["707"]} 707" "S3"`
    fi
else
    signature_err=`echo "${conn_log}" | grep "ERROR: S3 error: 403 (SignatureDoesNotMatch)"`
    Key_err=`echo "${conn_log}" | grep "ERROR: S3 error: 403 (InvalidAccessKeyId)"`
    
    if [ "${signature_err}" != "" ] ||  [ "${Key_err}" != "" ];then
        event["701"]=`get997msg 701`
        msg=`printf "${event["701"]} 701"`
        err=1
    fi
    
    if [ "${err}" == "0" ];then
        bucket_err=`echo "${conn_log}" | grep "ERROR: Bucket '${dest_folder}' does not exist"`
        bucket_err2=`echo "${conn_log}" | grep "ERROR: Access to bucket '${dest_folder}' was denied"`
        if [ "${bucket_err}" != "" ] || [ "${bucket_err2}" != "" ];then
            event["703"]=`get997msg 703`
            msg=`printf "${event["703"]} 703" "${dest_folder}"`
            err=1
        fi
    fi

    if [ "${err}" == "0" ];then
        net_err=`echo "${conn_log}" | grep "Network is unreachable"`
        if [ "${net_err}" != "" ];then
            event["700"]=`get997msg 700`
            msg=`printf "${event["700"]} 700"`
            err=1
        fi
    fi

    if [ "${err}" == "0" ];then
        err_log=`echo "${conn_log}" | awk '{if(NR==1) print $0}'`
        event["710"]=`get997msg 710`
        msg=`printf "${event["710"]} -- ${err_log} 710"`
    fi
    
    if [ "${err}" == "0" ];then
        bucket_err3=`echo "${conn_log}" | grep "The difference between the request time and the current time is too large"`
        if [ "${bucket_err3}" != "" ];then
            err_log=`echo "${conn_log}" | awk '{if(NR==1) print $0}'`
            event["714"]=`get997msg 714`
            msg=`printf "${event["714"]} -- ${err_log} 714"`
        fi
    fi
fi

rm ${conf_file}
echo ${msg}


