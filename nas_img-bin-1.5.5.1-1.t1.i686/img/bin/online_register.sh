#!/bin/sh
action=$1
sqlite="/usr/bin/sqlite"
conf_db="/etc/cfg/conf.db"
wget="/usr/bin/wget"
url="https://onlineregister.thecus.com/get_info.php"
#url="https://114.32.20.212/get_info.php"
#url="https://172.16.66.240/get_info.php"
log="/tmp/online.log"
url_path="/etc/webinfo/online_url"
if [ -f ${url_path} ];then
	app_url=`cat ${url_path}`
fi
crond_path="/etc/cfg/crond.conf"
tmp_crond="/tmp/crond.conf"
max_record="50"
online_enabled=`${sqlite} ${conf_db} "select v from conf where k='online_enabled'"`
online_send_hdd_info=`${sqlite} ${conf_db} "select v from conf where k='online_send_hdd_info'"`
online_send_timezone_info=`${sqlite} ${conf_db} "select v from conf where k='online_send_timezone_info'"`
auto_time="00 12 * * *"
if [ "`ls -l /raid/sys/ 2>/dev/null | wc -l`" != "0" ];then
	register_db="/raid/sys/online_register.db"
else
	register_db="/var/log/online_register.db"
fi

####################################################################
#	Update next crontab
####################################################################
function update_crond(){
	crond_time=$1
	cat ${crond_path} | grep -v "online_register.sh" > ${tmp_crond}
	echo "${crond_time} /img/bin/online_register.sh > /dev/null 2>&1" >> ${tmp_crond}
	mv ${tmp_crond} ${crond_path}

	/usr/bin/killall crond
	sleep 1
	/usr/sbin/crond
	/usr/bin/crontab /etc/cfg/crond.conf -u root
}

####################################################################
#	Check RAID exist
####################################################################
raid_exist=`ls -l /raid/sys/ 2>/dev/null | wc -l`
if [ "${raid_exist}" == "0" ];
then
	echo "No RAID volume exist"
	update_crond "${auto_time}"
	exit 0
fi

####################################################################
if [ "${app_url}" != "" ];
then
	url=${app_url}
fi
####################################################################
#	Check enabled/disabled
####################################################################
if [ "${online_enabled}" != "1" ];
then
	echo "This function is disabled"
	exit 0
fi

####################################################################
producer=`cat /etc/manifest.txt | awk '/producer/{print toupper($2)}'`
model=`cat /etc/manifest.txt | awk '/type/{print toupper($2)}'`

version=`cat /etc/version`
#mac=`ifconfig eth0|awk '/HWaddr/{print toupper($5)}'`
mac=`/img/bin/function/get_interface_info.sh get_mac eth0`
lang=`${sqlite} ${conf_db} "select v from conf where k='admin_lang'"`
email=`${sqlite} ${conf_db} "select v from conf where k='notif_addr1'"`
last_report_time=`date "+%Y-%m-%d %H:%M:%S"`
last_upgrade_time=`date "+%Y-%m-%d %H:%M:%S"`

####################################################################
#	Check producer
####################################################################
if [ "${producer}" != "THECUS" ];
then
	echo "Not support this function!"
	exit 1
fi

####################################################################

####################################################################
#	Get HDD information
####################################################################
hdd_info=""
if [ "${online_send_hdd_info}" == "1" ];
then
	total_tray=`/img/bin/check_service.sh total_tray`
	hdd_info=""
	for ((i=1;i<=${total_tray};i=i+1))
	do
		info=`cat /proc/scsi/scsi | awk '/Tray:'${i}' /{print $0}'`
		if [ "${info}" != "" ];
		then
			hdd_tray=$i
			hdd_model=`echo ${info} | awk -F: '{print substr($5,0,length($5)-4)}'`
			hdd_fw=`echo ${info} | awk -F':' '{print substr($6,0,length($6)-10)}'`
			hdd_brand=`cat /proc/scsi/scsi | awk '/Model: '"${hdd_model}"'/{print $2}'`
			#hdd_info[$i]="hdd_${i}_tray=${tray}&hdd_${i}_brand=${brand}&hdd_${i}_model=${model}&hdd_${i}_fw=${fw}&"
			hdd_info=${hdd_info}"hdd${i}_tray_no=${hdd_tray}&hdd${i}_brand=${hdd_brand}&hdd${i}_model=${hdd_model}&hdd${i}_fw_version=${hdd_fw}&"
		fi
	done
fi

####################################################################
#	Get timezone
####################################################################
if [ "${online_send_timezone_info}" == "1" ];
then
	#timezone=`${sqlite} ${conf_db} "select v from conf where k='time_timezone'"`
	timezone=`ls -l /etc/localtime | awk '{print substr($11,21)}'`
else
	timezone=""
fi
####################################################################

echo $producer $model $version $mac $lang $timezone $email $last_report_time $last_upgrade_time $total_tray

####################################################################
#	wget command
####################################################################
${wget} -T 10 -t 5 --no-check-certificate --post-data "\
action=add&\
producer=${producer}&\
model=${model}&\
version=${version}&\
mac_address=${mac}&\
ui_lang=${lang}&\
tz=${timezone}&\
email=${email}&\
${hdd_info}\
last_rep=${last_report_time}&\
last_upgrade=${last_upgrade_time}" \
${url} -O ${log}

wget_res=`echo $?`
if [ "${wget_res}" != "0" ];
then
	update_crond "${auto_time}"
	exit 1
fi

####################################################################

line=`cat ${log} | wc -l`
echo "line = $line"

if [ ! -f "${register_db}" ];
then
	touch ${register_db}
fi

####################################################################
#	Check table exist ( online_register )
####################################################################
table_exist=`${sqlite} ${register_db} "select count(*) from sqlite_master where type='table' and name='online_register'"`
if [ "${table_exist}" == "0" ];
then
	#########################################################################################################
	#	Datatase schema
	#########################################################################################################
	#	online1=whether read
	#	online2=type (fw,module,news)
	#       online3=is beta (0=no, 1=yes)
	#       online4=display message
	#       online5=new version
	#       online6=download url
	#       online7=next update
	#       online8=current time
	#       online9=publish date
	#       online10=
	#       online11=
	#       online12=
	#       online13=
	#       online14=
	#       online15=
	#########################################################################################################
	${sqlite} ${register_db} "create table online_register (online1,online2,online3,online4,online5,online6,online7,online8,online9,online10,online11,online12,online13,online14,online15)"
	#########################################################################################################
fi

####################################################################
#	Insert into DB
####################################################################
for ((i=1;i<=${line};i=i+1))
do
	info=`cat ${log} | awk '{if(NR=='${i}'){print $0}}'`
	line_info[${i}]=${info}
	if [ -f ${url_path} ];then
		app_url=`cat ${url_path}`
	fi
	if [ "${line_info[1]}" != "${app_url}" ];
	then
		if [ "${line_info[1]}" != "N/A" ];
		then
			echo "${line_info[1]}" > ${url_path}
		fi
		#echo "${line_info[1]}" > ${url_path}
	fi
	#########################################################################################################
	#	Information structure
	#########################################################################################################
	#	info1=type (fw,module,news)
	#	info2=is beta (0=no, 1=yes)
	#       info3=display message
	#       info4=version number
	#       info5=download url
	#       info6=next update
	#       info7=publish date
	#       info8=
	#       info9=
	#       info10=
	#       info11=
	#       info12=
	#       info13=
	#########################################################################################################
	if [ "${line_info[i]}" == "begin" ];
	then
		j=1
		continue
	fi
	if [ "${info}" == "end" ];
	then
		echo "${info[1]} ${info[2]} ${info[3]} ${info[4]} ${info[5]} ${info[6]} ${info[7]} 8${info[8]}8"
		record_exist=`${sqlite} ${register_db} "select count(*) from online_register where online4='${info[3]}' and online5='${info[4]}' and online6='${info[5]}'"`
		echo "record = ${record_exist}"
		if [ ${record_exist} == 0 ];
		then
			current_date=`date "+%Y/%m/%d %H:%M:%S"`
			${sqlite} ${register_db} "insert into online_register values ('0','${info[1]}','${info[2]}','${info[3]}','${info[4]}','${info[5]}','${info[6]}','${current_date}','${info[7]}','','','','','','')"
			####################################################################
			#	Delete oldest record
			####################################################################
			current_record=`${sqlite} ${register_db} "select count(*) from online_register"`
			if [ ${current_record} -gt ${max_record} ];
			then
				old_record=`${sqlite} ${register_db} "select online9 from online_register limit 1"`
				echo "delete from online_register where online9='${old_record}'"
				${sqlite} ${register_db} "delete from online_register where online9='${old_record}'"
			fi
			####################################################################
		fi
		continue
	fi
	info[${j}]=${info}
	j=$((${j}+1))
done

if [ "${info[6]}" == "" ];
then
	cmd="cat ${log} | awk '{if(NR=="${line}"){print \$0}}'"
	info[6]=`eval ${cmd}`
fi
update_crond "${info[6]}"
