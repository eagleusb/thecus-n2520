#!/bin/sh
func=$1
if [ "${func}" = '' ];then
	echo "Usage: $0 Function"
	exit 1
fi

if [ ! -f language.db ];then
	echo "please put transdb.sh & checkindb.sh in the path of language.db"
	exit 1
fi

langs="cz de es en fr it ja ko pl pt ru tr tw zh"
global=`sqlite language.db "select value from en where function='global'"`

echo "check duplicate value in global and ${func}"
echo "......"
for value in ${global}; do
	msg=`sqlite language.db "select value from en where function='global' and value='${value}'"`
	duplicate=`sqlite old_language.db "select * from en where function='${func}' and msg like '${msg}'"`
	if [ "${duplicate}" != '' ];then
		echo "${msg} :"
		echo "${duplicate}"
	fi
	item=`sqlite old_language.db "select value from en where function='${func}' and msg like '${msg}'"`
	if [ "${item}" != '' ];then
		items="${items} ${item}"
	fi
done

if [ "${items}" != "" ];then
	echo "delete duplicate items in ${func}?[y/n]"
	read dans
	if [ "${dans}" = "y" -o "${dans}" = "Y" ];then
		clear
		for item in ${items};do
			echo "value = ${item}:"
			for lang in ${langs}; do
				#echo old_language.db "delete from ${lang} where function='${func}' and value='${item}'"
				sqlite old_language.db "delete from ${lang} where function='${func}' and value='${item}'"
			done
			echo "press enter..."
			read
			clear
		done
	fi
else
	echo "no duplicate items in ${func}!"
fi

echo "prepare transfer function: ${func}"
echo "......"
#sqlite old_language.db ".dump" | grep "VALUES('','${func}',"
for lang in ${langs}; do
	echo "in ${lang}:"
	sqlite old_language.db "select * from ${lang} where function='${func}'"
	echo "press enter..."
	read
	clear
done

echo "transfer function: ${func}?[y/n]"
read ans
if [ "${ans}" = "y" -o "${ans}" = "Y" ];then
	/raid/data/module/SVN/svn/bin/svn update language.db
	sqlite old_language.db ".dump" | grep "VALUES('','${func}'," | sqlite language.db
	echo "transfer function: ${func} success"
fi
clear
echo "check in svn?[y/n]"
read cans
if [ "${cans}" = "y" -o "${cans}" = "Y" ];then
	echo "input commit Message:"
	read message
	./checkindb.sh language.db "${Message}"
fi
exit 0
