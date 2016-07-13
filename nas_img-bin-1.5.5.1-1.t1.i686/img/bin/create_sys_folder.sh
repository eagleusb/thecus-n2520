#!/bin/sh 
mraid="raid"
share=$1
comment=$2
browseable=$3
guest_only=$4
readonly=$5
var_tmp="/var/tmp"
sqlite="/usr/bin/sqlite"
mkzfs="/usr/bin/zfs"
browseable_default="yes"
guest_only_default="yes"

[ -d /raid/data ] || exit

usage(){
	echo "Usage : create_sys_folder.sh [ folder ] [ comment ] [ browsable(yes/no) ] [ guest_only(yes/no) ][ readonly(0/1) ]"
	exit 1
}

initial(){
	md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
  if [ "${md_list}" == "" ];then
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
  fi
	
  for md in $md_list
	do
		if [ -d "/raid${md}/" ];
		then
			status=`cat ${var_tmp}/raid${md}/rss`
			if [ "${status}" == "Damaged" ];
			then
				echo "The RAID [ raid${md} ] is Damaged!"
				continue
			fi
			raid_db="/raid${md}/sys/smb.db"
			ismaster=`$sqlite $raid_db "select v from conf where k='raid_master'"`
			if [ ${ismaster} == "1" ];
			then
				master_raid="raid${md}"
				raidno="${md}"
				filesystem=`$sqlite $raid_db "select v from conf where k='filesystem'"`
				break
			fi
		fi
	done

	db_exist=`$sqlite /${master_raid}/sys/smb.db "select share from smb_specfd where share='${share}'"`
	if [ "${db_exist}" == "" ];
	then
		db_exist=`$sqlite /${master_raid}/sys/smb.db "select share from smb_userfd where share='${share}'"`
	fi
		
	if [ "${db_exist}" != "" ];
	then
		echo "folder db is exist!"
		exit 1
	fi
}

make_ext3_folder(){
	mkdir -p /$master_raid/data/${share}
	if [ "${readonly}" == "" ];
	then
		$sqlite $raid_db "insert into smb_specfd(share,comment,browseable,'guest only',path,'map hidden', recursive,'readonly') values('${share}','${share}','${browseable}','${guest_only}','${share}','no','yes','0')"
	else
	        $sqlite $raid_db "insert into smb_specfd(share,comment,browseable,'guest only',path,'map hidden', recursive,'readonly') values('${share}','${share}','${browseable}','${guest_only}','${share}','no','yes','${readonly}')"
	fi    
}

make_zfs_folder(){
	zpoolname="zfspool$raidno"
	zfs_sharename=`/img/bin/zfs_getfreename.sh $(($raidno+1))`
	$mkzfs create -o mountpoint=/${master_raid}/data/${share} $zpoolname/$zfs_sharename
	if [ "${readonly}" == "" ];
	then
		$sqlite $raid_db "insert into smb_specfd(share,comment,browseable,'guest only',path,'map hidden', recursive,'readonly') values('${share}','${share}','${browseable}','${guest_only}','${share}','no','yes','0')"
	else
	        $sqlite $raid_db "insert into smb_specfd(share,comment,browseable,'guest only',path,'map hidden', recursive,'readonly') values('${share}','${share}','${browseable}','${guest_only}','${share}','no','yes','${readonly}')"
	fi
}


if [ "${share}" == "" ];
then
	usage
fi

initial

if [ "${browseable}" == "" ];
then
	browseable=${browseable_default}
fi
if [ "${guest_only}" == "" ];
then
	guest_only=${guest_only_default}
fi

if [ "${guest_only}" == "yes" ];
then
        permission=""
else
        permission="root"
fi

if [ ! -d "/${master_raid}/data/${share}" ];
then
	if [ "${filesystem}" == "zfs" ];
	then
		make_zfs_folder
	else
		make_ext3_folder
	fi
fi
chown nobody:users "/$master_raid/data/${share}"
chmod 777 "/$master_raid/data/${share}"
