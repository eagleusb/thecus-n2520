#!/bin/sh
alarm="/usr/bin/alarm"
sql="/usr/bin/sqlite"
db="/etc/cfg/conf.db"
power_on_list=""

cmd="select v from conf where k='schedule_on'"
if [ "`${sql} ${db} \"${cmd}\"`" = "0" ];then
	${alarm} --off
	exit
fi

case "`date +%u`" in
	1)Week="Mon1 Mon2 Tue1 Tue2 Wed1 Wed2 Thu1 Thu2 Fri1 Fri2 Sat1 Sat2 Sun1 Sun2"
;;
	2)Week="Tue1 Tue2 Wed1 Wed2 Thu1 Thu2 Fri1 Fri2 Sat1 Sat2 Sun1 Sun2 Mon1 Mon2"
;;
	3)Week="Wed1 Wed2 Thu1 Thu2 Fri1 Fri2 Sat1 Sat2 Sun1 Sun2 Mon1 Mon2 Tue1 Tue2"
;;
	4)Week="Thu1 Thu2 Fri1 Fri2 Sat1 Sat2 Sun1 Sun2 Mon1 Mon2 Tue1 Tue2 Wed1 Wed2"
;;
	5)Week="Fri1 Fri2 Sat1 Sat2 Sun1 Sun2 Mon1 Mon2 Tue1 Tue2 Wed1 Wed2 Thu1 Thu2"
;;
	6)Week="Sat1 Sat2 Sun1 Sun2 Mon1 Mon2 Tue1 Tue2 Wed1 Wed2 Thu1 Thu2 Fri1 Fri2"
;;
	7)Week="Sun1 Sun2 Mon1 Mon2 Tue1 Tue2 Wed1 Wed2 Thu1 Thu2 Fri1 Fri2 Sat1 Sat2"
;;
esac

for w in ${Week}
do
	cmd="select v from conf where k='power_schedule_${w}'"
	if [ "`${sql} ${db} \"${cmd}\"`" = "1" ];then
		power_on_list="${power_on_list} ${w}"
	fi
done
if [ "${power_on_list}" = "" ];then
	${alarm} --off
	exit
fi
set $power_on_list
#echo $*,$#
tow=`date +%a`
tohm=`date +%H%M`
#echo $tow $tohm
for w in $*
do
	power_on="power_schedule_${w}"
	cmd="select v from conf where k='${power_on}_hh'"
	power_hh=`$sql $db "$cmd"`
	cmd="select v from conf where k='${power_on}_mm'"
	power_mm=`${sql} ${db} "${cmd}"`
	if [ "$#" = "1" ];then
		w=`echo ${w} | cut -b 1-3`
		echo SET RTC ON ${w} ${power_hh} ${power_mm}
		${alarm} --on -w ${w} -h ${power_hh} -m ${power_mm}
		exit
	elif [ "${tow}1" = "${w}" -o "${tow}2" = "${w}" ];then
		power_hm=${power_hh}${power_mm}
		if [ ${power_hm} -gt ${tohm} ];then
			w=`echo ${w} | cut -b 1-3`
			echo SET RTC ON ${w} ${power_hh} ${power_mm}
			${alarm} --on -w ${w} -h ${power_hh} -m ${power_mm}
			exit
		fi
	else
		w=`echo ${w} | cut -b 1-3`
		echo SET RTC ON ${w} ${power_hh} ${power_mm}
		${alarm} --on -w ${w} -h ${power_hh} -m ${power_mm}
		exit
	fi
done
