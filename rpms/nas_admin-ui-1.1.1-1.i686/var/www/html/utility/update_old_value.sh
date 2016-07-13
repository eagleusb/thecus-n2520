#!/bin/sh
global_file="/tmp/global.txt"
language="cz de es en fr it ja ko pl pt ru tr tw zh"
export PATH='/usr/bin':$PATH

fun=$1
old_val=$2
new_val=$3
db=$4
#db="/var/www/html/language/language.db"

if [ "${fun}" == "" ] || [ "${old_val}" == "" ] ||[ "${new_val}" == "" ] ||[ "${db}" == "" ];
then
	echo "Usage : $0 funcion old_value new_value db_path"
	exit 1
fi

for lang in ${language}
do
	cmd="sqlite ${db} \"update ${lang} set value='${new_val}' where function='${fun}' and value='${old_val}'"
	echo $cmd
	sqlite ${db} "update ${lang} set value='${new_val}' where function='${fun}' and value='${old_val}'"
done
