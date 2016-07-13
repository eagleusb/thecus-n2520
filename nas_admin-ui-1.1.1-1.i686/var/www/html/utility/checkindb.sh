#!/bin/sh
db=$1
message=$2
export PATH='/raid/data/module/SVN/svn/bin':'/usr/bin':$PATH
if [ "${db}" = "" ];then
	echo "Usage: $0 DB Message"
	exit 1
fi
if [ ! -f "${db}" ];then
	echo "DB file: ${db} not exist!"
	exit 1
fi
if [ `svn st ${db} 2>&1|grep -c 'is not a working copy'` -eq 1 ];then
	echo "'${db}' is not a working copy"
	exit 1
fi
if [ `svn st ${db} | grep -c '^M '` -eq 0 ];then
	echo "svn st not changed!"
	exit 1
fi
url=`svn info ${db} | awk '/URL:/{print $2}'`
svn export ${url} ${db}.svn
sqlite ${db}.svn .dump > ${db}.svn.dump
sqlite ${db} .dump > ${db}.dump
echo "SVN << >> UPDATE"
diff ${db}.svn.dump ${db}.dump

ci=''
echo "merge local and svn db?[y/n]"
read ci
if [ "${ci}" = "y" -o "${ci}" = "Y" ];then
	diff ${db}.dump ${db}.svn.dump | awk '/^> /{print substr($0,3)}' | sqlite ${db}
	sqlite ${db} .dump > ${db}.dump
	diff ${db}.svn.dump ${db}.dump
fi
rm -f ${db}.svn ${db}.svn.dump ${db}.dump

ci=''
echo "checkin svn?[y/n]"
read ci
if [ "${ci}" = "y" -o "${ci}" = "Y" ];then
	if [ -f "/usr/bin/sqlite3" -a -x "/usr/bin/sqlite3" -a -f "${db}.v3" ];then
		echo echo "checkin sqlite3 db?[y/n]"
		read ans
		if [ "${ans}" = "y" -o "${ans}" = "Y" ];then
			rm -f ${db}.v3
			echo .dump | sqlite ${db} | /usr/bin/sqlite3 ${db}.v3
			svn ci ${db} ${db}.v3 -m "${message}"
			exit 0
		fi
	fi
	svn ci ${db} -m "${message}"
fi
exit 0
