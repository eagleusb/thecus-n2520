#!/bin/sh
lang_array="cz de es en fr it ja ko pl pt ru tr tw zh"
sqlite="/usr/bin/sqlite"
db="/var/www/html/language/language.db"
fun=$1
value=$2
if [ "${fun}" == "" ] || [ "${value}" == "" ];
then
	echo "Usage : $0 function [ value | value_file ]"
	exit 1
fi

for lang in ${lang_array}
do
	if [ -f "${value}" ];
	then
		cat ${value} | \
		while read v
		do
			if [ "${v}" != "" ];
			then
				${sqlite} ${db} "delete from ${lang} where function='${fun}' and value='${v}'"
				echo "delete \"${fun} | ${v}\" in ${lang}"
			fi
		done
	else
		${sqlite} ${db} "delete from ${lang} where function='${fun}' and value='${value}'"
		echo "delete \"${fun} | ${value}\" in ${lang}"
	fi
done
