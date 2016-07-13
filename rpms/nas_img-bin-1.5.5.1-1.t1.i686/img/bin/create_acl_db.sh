#!/bin/sh
sqlite="/usr/bin/sqlite"
conf_db="/etc/cfg/conf.db"
text_file="/raid/sys/ad.txt"
get_ldap_passwd="/raid/sys/ldap.txt"
get_ldap_group="/raid/sys/ldap_g.txt"
tmp_db="/raid/sys/ad_account_tmp.db"
acl_db="/raid/sys/ad_account.db"
wbinfo="/usr/bin/wbinfo"
winad_enable=`$sqlite $conf_db "select v from conf where k='winad_enable'"`

if [ -f "$tmp_db" ];
then
  $sqlite $tmp_db "delete from acl"
else
  touch $tmp_db
  $sqlite $tmp_db "create table acl(user,id,role)"
fi

rm -f ${text_file}

get_wb_user(){
  #work arounds for winbind panic on button "Synchoronize" in "ACL setting" in "Share Folders"
  #${wbinfo} -u | sort | awk -F':' '!($2 in a){a[$2];if(($1!="admin")&&($2>20000)){printf("%s|%s|ad_user\n",$1,$2)}}' >> ${text_file}
  local TMP_FILE="/tmp/get_wb_user.$$"
  getent passwd | awk -F: '{print $1":"$3}' > ${TMP_FILE}
  #filter local users
  cat /etc/passwd | awk -F: '{print $1":"$3}' | while read local_user ;do
    sed -i "/$local_user/ d" ${TMP_FILE}
  done
  cat ${TMP_FILE}
  rm -rf ${TMP_FILE}
}

if [ "${winad_enable}" == "1" ];then
  get_wb_user | sort | awk -F':' '!($2 in a){a[$2];if(($1!="admin")&&($2>20000)){printf("%s|%s|ad_user\n",$1,$2)}}' >> ${text_file}
  ${wbinfo} -g | sort | awk -F':' '!($2 in a){a[$2];if(($1!="admingroup")&&($2>20000)){printf("%s|%s|ad_group\n",$1,$2)}}' >> ${text_file}
else
  cat ${get_ldap_passwd} | sort | awk -F':' '!($3 in a){a[$3];if(($1!="admin")){printf("%s|%s|ad_user\n",$1,$3)}}' >> ${text_file}  
  cat ${get_ldap_group} | sort | awk -F':' '!($3 in a){a[$3];if(($1!="admingroup")){printf("%s|%s|ad_group\n",$1,$3)}}' >> ${text_file}
fi

$sqlite $tmp_db ".import $text_file acl"

mv $tmp_db $acl_db
rm -rf $text_file

#echo -e "$acl_info" | \
#while read line
#do
#  echo $line
#  username=`echo -e "$line" | awk -F',' '{printf $1}'`
#  #echo $username
#done
