#!/bin/sh
real_ha_cf=/etc/cfg/ha.cf
ha_cf=/tmp/ha.cf
ha_debug=/var/log/ha-debug
ha_log=/var/log/ha-log
SQL=/usr/bin/sqlite
DB=/etc/cfg/ha.db
ha_resources=/etc/cfg/haresources

puch_to_hacf(){
	echo $@ >> /tmp/ha.cf
}

getvar(){
	${SQL} ${DB} "select v from conf where k='$1'"
}

#check auto_failback
auto_failback=`getvar ha_auto_failback`
ha_auto_failback=off
if [ ${auto_failback} = 1 ];then
	ha_auto_failback=on
elif [ ${auto_failback} = 2 ];then
	ha_auto_failback=legacy
fi

udpport=`getvar ha_udpport`


#---------------------------------------------------------------
echo '# ha config'> ${ha_cf}
puch_to_hacf '# Logging'
puch_to_hacf debug 1
puch_to_hacf use_logd false
puch_to_hacf logfacility none
if [ -f /etc/ha_debug ];then
  puch_to_hacf debugfile ${ha_debug}
else
  puch_to_hacf "#debugfile ${ha_debug}"
fi
puch_to_hacf logfile ${ha_log}
puch_to_hacf auto_failback ${ha_auto_failback}
puch_to_hacf
#---------------------------------------------------------------
puch_to_hacf '# Misc Options'
puch_to_hacf traditional_compression off
puch_to_hacf compression bz2
puch_to_hacf coredumps true
puch_to_hacf
#---------------------------------------------------------------
puch_to_hacf '# Communications'
puch_to_hacf udpport ${udpport}
#--hearbeat-----------------------------------------------------
#puch_to_hacf bcast eth2
heart_beat=`getvar ha_heartbeat`
if [ "${heart_beat}" = "" ];then
  heart_beat=eth2
fi
puch_to_hacf bcast ${heart_beat}

role=`getvar ha_role`
if [ "`getvar ha_primary_ip1 | grep -c '[[:alnum:]],[0-9]*.[0-9]*.[0-9]*.[0-9]*,'`" != "0" ];then
  wan_interface=`getvar ha_primary_ip1 | awk -F',' '{print $1}'`
  primary_ip1=`getvar ha_primary_ip1 | awk -F',' '{print $2}'`
  standy_ip1=`getvar ha_standy_ip1 | awk -F',' '{print $2}'`
else
  wan_interface=eth0
  bond=`/img/bin/function/get_interface_info.sh check_eth_bond eth0`
  if [ "${bond}" != "" ];then
    wan_interface=bond0
  fi

  primary_ip1=`getvar ha_primary_ip1`
  standy_ip1=`getvar ha_standy_ip1`
fi
if [ x$role = x1 ];then
  puch_to_hacf ucast ${wan_interface} ${primary_ip1}
else
  puch_to_hacf ucast ${wan_interface} ${standy_ip1}
fi

#--node---------------------------------------------------------
primary_name=`getvar ha_primary_name`
standy_name=`getvar ha_standy_name`
puch_to_hacf node ${primary_name}
puch_to_hacf node ${standy_name}
puch_to_hacf
#---------------------------------------------------------------
puch_to_hacf '# Thresholds (in seconds)'
for key in keepalive warntime deadtime initdead
do
	puch_to_hacf ${key} `getvar ha_${key}`
done
puch_to_hacf

if [ "`getvar ha_indicator_ip | grep -c '[[:alnum:]],[0-9]*.[0-9]*.[0-9]*.[0-9]*,'`" != "0" ];then
  indicator_ip=`getvar ha_indicator_ip | awk -F',' '{print $2}'`
else
  indicator_ip=`getvar nic1_gateway`
fi
puch_to_hacf ping ${indicator_ip}
puch_to_hacf respawn root /usr/lib/heartbeat/ipfail
puch_to_hacf apiauth ipfail gid=root uid=root

cp -f ${real_ha_cf} ${real_ha_cf}.bak
cp -f ${ha_cf} ${real_ha_cf}

if [ `cat /etc/hosts | wc -l` -eq 2 ];then
 if [ x$role = x1 ];then
   echo -e "${primary_ip1}\t${primary_name}" >> /etc/hosts
 else
   echo -e "${standy_ip1}\t${standy_name}" >> /etc/hosts
 fi
else
 if [ x$role = x1 ];then
   if [ `cat /etc/hosts | grep -c "^${primary_ip1}	"` -eq 1 ];then
     if [ `cat /etc/hosts | grep -c " ${primary_name}	"` -eq 0 ];then
       cat /etc/hosts | grep -v "^${primary_ip1}	" > /tmp/hosts
       echo -e "${primary_ip1}\t${primary_name}" >> /tmp/hosts
       cp /tmp/hosts /etc/hosts
     fi
   fi
 else
   if [ `cat /etc/hosts | grep -c "^${standy_ip1}	"` -eq 1 ];then
     if [ `cat /etc/hosts | grep -c " ${standy_name}	"` -eq 0 ];then
       cat /etc/hosts | grep -v "^${standy_ip1}	" > /tmp/hosts
       echo -e "${standy_ip1}\t${standy_name}" >> /tmp/hosts
       cp /tmp/hosts /etc/hosts
     fi
   fi
 fi
fi

if [ "`getvar ha_virtual_ip | grep -c '[[:alnum:]],[0-9]*.[0-9]*.[0-9]*.[0-9]*,'`" != "0" ];then
  virtual_ip=`getvar ha_virtual_ip | awk -F',' '{print $2}'`
else
  virtual_ip=`getvar ha_virtual_ip`
fi
ip1=`ifconfig ${wan_interface} | awk '/inet addr:/{gsub(/addr:/,"");print $2}'`
mask1=`ifconfig ${wan_interface} | awk '/inet addr:/{gsub(/Mask:/,"");print $4}'`
netmask_prifix=`/bin/ipcalc -p ${ip1} ${mask1} | awk -F= '{print $2}'`
echo ${primary_name} IPaddr::${virtual_ip}/${netmask_prifix}/${wan_interface} > $ha_resources

