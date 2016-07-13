#!/bin/sh
lang_array="cz de es en fr it ja ko pl pt ru tr tw zh"
export PATH='/usr/bin':$PATH
db=$1
if [ "${db}" == "" ];
then
	db="/var/www/html/language/language.db"
fi

for lang in ${lang_array}
do
	count=`sqlite ${db} "select count(*) from ${lang}"`
	echo "${lang} count is ${count}"
done
