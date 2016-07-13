#!/bin/bash
input_port=$1
type=$2
interface=$3
tmp_file="/tmp/tmp_all_ip"
sqlite="/usr/bin/sqlite"
get_interface_info="/img/bin/function/get_interface_info.sh"
. /img/bin/service_def_port_map
service_id=$[D_$4]

#################################################
##  check arg is int
##  para arg
#################################################
check_int_arg(){
  arg=$1
  str="echo '${arg}' | grep -v [0-9]"
  check_number=`eval $str`
  echo $check_number
}

#################################################
##  assemble interface pattern
#################################################
assemble_pattern(){
  if [ "$interface" == "all" ];then
    pattern=""
  else
    pattern='/0.0.0.0/'
    for name in $interface
    do
      if [ "$name" != "" ];then
        ip=`$get_interface_info get_ip $name`
        if [ "$ip" != "" ];then
          pattern="${pattern}||/${ip}/"
        fi
      fi
    done
  fi
}

###########check isnumber#############
check_port_type=`check_int_arg "${input_port}"`
if [ "$check_port_type" != "" ];then
  echo "port is not number"
  exit 2
fi

input_port=`echo "$input_port" | awk '{printf("%d",$0)}'`

###########is default port the same as input port###########

str="echo ' ${tcp[$service_id]} '| awk '/ ${input_port} /{print \$0}'"
tcp_default_port=`eval $str`

str="echo ' ${udp[$service_id]} '| awk '/ ${input_port} /{print \$0}'"
udp_default_port=`eval $str`

if [ "$type" == "t" ];then
  is_defalut=${tcp_default_port}
elif [ "$type" == "u" ];then
  is_defalut=${udp_default_port}
else
  is_default=""
  if [ "${tcp_default_port}" != "" ] && [ "${udp_default_port}" != "" ];then
    is_defalut="yes"
  fi
fi

if [ "$is_defalut" == "" ];then
  if [ ${input_port} -gt 65535 ];then
    echo "port is > 65535"
    exit 3
  fi
  if [ ${input_port} -lt 1024 ];then
    echo "port is < 1024"
    exit 4
  fi
  
  ###########check port in fix port############
  if [ "$type" == "t" ];then
    fix_port=${tcp[@]}
  elif [ "$type" == "u" ];then
    fix_port="${udp[@]}"
  else
    fix_port="${tcp[@]} ${udp[@]}"
  fi
  
  str="echo ' ${fix_port} '| awk '/ ${input_port} /{print \$0}'"
  port_ret=`eval $str`
  
  if [ "${port_ret}" != "" ];then
    echo "port is reserved by system"
    exit 5
  fi
fi

##########check port in use port###########
#####set type#####
if [ "$type" == "t" ];then
  arg="t"
elif [ "$type" == "u" ];then
  arg="u"
else
  arg="ut"
fi

##### assemble pattern######
assemble_pattern
#use_port=`/bin/netstat -tuan | awk '{print $4}' | grep -v 'Local' | grep -v 'server' | awk -F':' '{print $2}'`
str="/bin/netstat -an${arg} | awk '!(/Local/)&&!(/server/){print \$4}' | awk -F':' '${pattern}{print \$2}'"
use_port=`eval $str`
str="echo ' ${use_port} ' | awk '/ ${input_port} /'"
ret=`eval $str`

if [ "${ret}" != "" ];then
  echo "port is using"
  exit 1
fi
echo 0
exit 0
