#!/bin/sh
global_file="/tmp/global.txt"
language="cz de es en fr it ja ko pl pt ru tr tw zh"
export PATH='/usr/bin':$PATH
db="/var/www/html/language/language.db"

cat "${global_file}" |\
while read item
do
	cmd="sqlite ${db} \"select function,value from en where msg=\"${item}\"\""
	echo $cmd
	del_item=`sqlite ${db} "select function,value from en where msg=\"${item}\""`
	echo "${del_item}" |\
	while read item
	do
		del_function=`echo "${item}" | awk -F '\|' '{print $1}'`
		del_value=`echo "${item}" | awk -F '\|' '{print $2}'`
		echo "${del_function}  ${del_value}"
		for lang in ${language}
		do
			cmd="sqlite ${db} \"del from ${lang} where function=\"${del_function}\" and value=\"${del_value}\"\""
			#echo $cmd
			sqlite ${db} "delete from ${lang} where function='${del_function}' and value='${del_value}'"
		done
	done
done
