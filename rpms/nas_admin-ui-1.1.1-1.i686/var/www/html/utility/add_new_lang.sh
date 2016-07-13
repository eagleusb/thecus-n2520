#!/bin/sh
lang_array="cz de es en fr it ja ko pl pt ru tr tw zh"
export PATH='/usr/bin':$PATH
fun=$1
value=$2
msg=$3
db=$4

if [ "${fun}" == "" ] || [ "${value}" == "" ] || [ "${msg}" == "" ] || [ "${db}" == "" ];
then
	echo "USAGE : $0 function value msg db_path"
	exit 1
fi

for lang in ${lang_array}
do
	echo "insert into ${lang} (group_id,function,value,msg) values ('',${fun}','${value}',\"${msg}\");" >> /etc/insert_lang.txt
	echo "\"\",\"${fun}\",\"${value}\",\"${msg}\"" >> /etc/new_lang.txt

	#if the database lock, then repeat the insert action
	ret=1
	count=0
	while [ "$ret" != "0" ] && [ "${count}" -lt "7" ]
	do
  		sqlite ${db} "insert into ${lang} (function,value,msg) values ('${fun}','${value}',\"${msg}\")"
		ret=`echo $?`
		if [ "$ret" != "0" ];then
			count=$(($count + 1))
			sleep 1
		fi
	done
done
