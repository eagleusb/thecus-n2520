#!/bin/sh
username=$1
password=$2
winad_enable=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='winad_enable'"`
ldap_enable=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ldap_enabled'"`
ldap_ip=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ldap_ip'"`
ldap_base_dn=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ldap_dmname'"`
ldap_id=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ldap_id'"`
ldap_passwd=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='ldap_passwd'"`
local_auth="/usr/bin/auth"
ad_auth="/usr/bin/ntlm_auth"

if [ ${ldap_enable} = "1" ];then
   echo "ldap_host ${ldap_ip}" > /tmp/ldapauth.ini
   echo "ldap_port 389" >> /tmp/ldapauth.ini

   if [ `echo "${ldap_id}" | grep "," | wc -l` -eq 0 ]; then
     echo "ldap_mgr_dn cn=${ldap_id},${ldap_base_dn}" >> /tmp/ldapauth.ini
   else
     echo "ldap_mgr_dn ${ldap_id}" >> /tmp/ldapauth.ini
   fi

   echo "ldap_mgr_pw ${ldap_passwd}" >> /tmp/ldapauth.ini
   echo "ldap_search_name uid" >> /tmp/ldapauth.ini
   echo "ldap_search_name cn" >> /tmp/ldapauth.ini
   echo "ldap_objectclass account" >> /tmp/ldapauth.ini
   echo "ldap_objectclass posixAccount" >> /tmp/ldapauth.ini
   echo "ldap_search_base ${ldap_base_dn}" >> /tmp/ldapauth.ini
fi

uid_list=`/usr/bin/getent passwd | grep "^${username}:" | awk -F":" '{print $3}'`
if [ "${username}" = "admin" ] || [ "${username}" = "root" ] || [ "${username}" = "sshd" ] || [ "${uid_list}" = "" ] || [ "${password}" = "" ]; then
	exit 1
fi

ret="1"

if [ "$winad_enable" == "1" ] || [ "$ldap_enable" == "1" ];
then
	for uid in $uid_list
	do
		if [ "$uid" -lt "20000" ];
		then
			${local_auth} "${username}" "${password}" > /dev/null 2>&1
			ret=$?
			if [ "$ret" == "0" ];
			then
				echo "user"
				exit $ret
			fi
		fi
		if [ "${winad_enable}" = "1" -a $uid -ge 20000 ];
		then
			${ad_auth} --username="${username}" --password="${password}" > /dev/null 2>&1
			ret=$?
			echo "aduser"
			exit $ret
		fi
		if [ "${ldap_enable}" = "1" ];then
			printf "%s\0%s\0"  "${username}" "${password}" | /bin/checkpassword-pam -H -s checkpassword --debug --stdout 3<&0 > /dev/null 2>&1
			ret=$?
			echo "ldapuser"        
			exit $ret

		fi
	done
	exit $ret
else
	${local_auth} "${username}" "${password}" > /dev/null 2>&1
	ret=$?
	echo "user"
	exit $ret
fi

