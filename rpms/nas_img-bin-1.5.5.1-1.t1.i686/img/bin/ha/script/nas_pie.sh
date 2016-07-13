#!/bin/sh
act=$1
req=$2
attr1=$3
attr2=$4
attr3=$5
attr4=$6
attr5=$7

. /img/bin/ha/ha.d/shellfuncs
. /img/bin/ha/script/conf.ha
. /img/bin/ha/script/func.ha

if [ "$act" = "send" ];then
  ha_t=ip-request
elif [ "$act" = "resp" ];then
  ha_t=ip-request-resp
else
  echo "No action!"
  exit
fi

ha_clustermsg <<!MSG
t=$ha_t
nas_cmd=$act
nas_req=$req
nas_source_ip=$ip3
nas_target_ip=$ipx3
nas_attr1=$attr1
nas_attr2=$attr2
nas_attr3=$attr3
nas_attr4=$attr4
nas_attr5=$attr5
!MSG

