#!/bin/sh 
mraid="raid"
act=$1
share=$2
mdnum=$3
comment=$4
browseable=$5
guest_only=$6
readonly=$7
speclevel=$8
var_tmp="/var/tmp"
sqlite="/usr/bin/sqlite"
mkzfs="/usr/bin/zfs"
browseable_default="yes"
guest_only_default="yes"

[ -d /raid/data ] || exit

usage(){
	echo "Usage : manage_folder.sh [ act(add/del/modify/update) ] [ folder ] [ mdnum ] [ comment ] [ browsable(yes/no) ] [ guest_only(yes/no) ] [ readonly(0/1) ] [ speclevel(0/1) ]"
	exit 1
}

initial(){
  md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
  if [ "${md_list}" == "" ];then
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
  fi
  
	for md in $md_list
	do
		raid="raid${md}"
		
    if [ -d "/$raid/" ];
		then
			status=`cat ${var_tmp}/${raid}/rss`
			if [ "${status}" == "Damaged" ];
			then
				echo "The RAID [ ${raid} ] is Damaged!"
				continue
			fi
			
      tmp_db="/$raid/sys/smb.db"

      db_exist=`$sqlite ${tmp_db} "select share from smb_specfd where share='${share}'"`
      if [ "${db_exist}" == "" ];then
        db_exist=`$sqlite ${tmp_db} "select share from smb_userfd where share='${share}'"`
      fi
		
      if [ "${db_exist}" != "" ];then
        echo "folder db is exist!"
        exit 1
      fi
		fi
	done
}

modify_folder_name(){
  mv "/$target_raid/data/${share}" "/$target_raid/data/${comment}"
  $sqlite $raid_db "update smb_userfd set share='${comment}', comment='${comment}', path='${comment}' where share='${share}'"
}

modify_folder(){
  md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
  if [ "${md_list}" == "" ];then
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
  fi
  
  for md in $md_list
  do
    raid="raid${md}"
    tmp_db="/$raid/sys/smb.db"
    db_exist=`$sqlite ${tmp_db} "select share from smb_userfd where share='${share}'"`
    if [ "${db_exist}" != "" ];then
      raid_db=${tmp_db}
    fi
  done

  $sqlite $raid_db "update smb_userfd set comment='${comment}',browseable='${browseable}','guest only'='${guest_only}',readonly='${readonly}',speclevel='${speclevel}' where share='${share}'"
}

make_ext3_folder(){
	mkdir -p "/$target_raid/data/${share}"
	$sqlite $raid_db "insert into smb_userfd(share,comment,browseable,'guest only',path,'map hidden', recursive, readonly, speclevel) values('${share}','${comment}','${browseable}','${guest_only}','${share}','no','yes', '${readonly}','${speclevel}')"
}

make_zfs_folder(){
	zpoolname="zfspool$raidno"
	zfs_sharename=`/img/bin/zfs_getfreename.sh $raidno`
	$mkzfs create -o mountpoint="/${target_raid}/data/${share}" $zpoolname/$zfs_sharename
	$sqlite $raid_db "insert into smb_userfd(share,comment,browseable,'guest only',path,'map hidden', recursive, readonly, speclevel) values('${share}','${comment}','${browseable}','${guest_only}','${share}','no','yes', '${readonly}', '${speclevel}')"
}

del_ext3_folder(){
  cd /$target_raid/data/
	rm -rf "${share}"
	$sqlite $raid_db "delete from smb_userfd where share = '${share}'"
}

del_zfs_folder(){
	zpoolname="zfspool$raidno"
	zfs_sharename=`/img/bin/zfs_getfreename.sh $raidno`
	$mkzfs create -o mountpoint="/${target_raid}/data/${share}" $zpoolname/$zfs_sharename
	$sqlite $raid_db "delete from smb_userfd where share = '${share}'"
}

if [ "${share}" == "" ];
then
	usage
fi

if [ "${mdnum}" == "" ];then
    target_raid="raid0"
else
    target_raid="raid${mdnum}"
fi

raid_db="/${target_raid}/sys/smb.db"
raidno=`echo ${target_raid} | awk '{print substr($0,5,length($0)-4)}'`
filesystem=`$sqlite $raid_db "select v from conf where k='filesystem'"`

if [ "${act}" == "del" ];then
    if [ -d "/${target_raid}/data/${share}" ];then
        if [ "${filesystem}" == "zfs" ];then
            del_zfs_folder
        else
            del_ext3_folder
        fi
    fi
elif [ "${act}" == "modify" ];then
    modify_folder_name
elif [ "${act}" == "update" ];then
    modify_folder
else
    initial

    if [ "${browseable}" == "" ];then
	   browseable=${browseable_default}
    fi

    if [ "${guest_only}" == "" ];then
	   guest_only=${guest_only_default}
    fi

    if [ "${guest_only}" == "yes" ];then
        permission=""
    else
        permission="root"
    fi

    if [ ! -d "/${target_raid}/data/${share}" ];then
      if [ "${filesystem}" == "zfs" ];then
        make_zfs_folder
        
        chmod 777 "/$target_raid/data/${share}"
        chown nobody:users "/$target_raid/data/${share}"
      else
        make_ext3_folder

        chmod 774 "/$target_raid/data/${share}"
        chown nobody:users "/$target_raid/data/${share}"
    
        if [ "${guest_only}" == "yes" ];then
          setfacl -P -m other::rwx "/$target_raid/data/${share}"
        else
          chmod 700 "/$target_raid/data/${share}"
        fi
    
        setfacl -P -d -m other::rwx "/$target_raid/data/${share}"
      fi
    fi
    
fi

/img/bin/rc/rc.samba reload

