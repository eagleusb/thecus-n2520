#!/bin/sh

Cmd=$1
Confile="/tmp/smb.conf"
raid_db="/raid/sys/smb.db"
snap_db="/raid/sys/snapshot.db"
temp_db="/tmp/smb.db"
sql="/usr/bin/sqlite"
conf_db="/etc/cfg/conf.db"
ftproot="/raid/data/ftproot"
tmp_stack_smb_conf="/tmp/iscsi_smb.conf"
ethString=""
snapshot=`/img/bin/check_service.sh snapshot`
esata_count=`/img/bin/check_service.sh esata_count`

md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
if [ "${md_list}" == "" ];then
  md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
fi
set_interfacestring(){
 interfacestring=$1
 nic_interface=`ifconfig | awk '/^'${interfacestring}':[0-9]* /{print $1}'`
 if [ "$nic_interface" != "" ];then
    nic_interface=`echo -e "$nic_interface" | sed 'H;$!d;g;s/\n/\,/g'`
 else
    nic_interface=""
 fi
  if [ "$ethString" != "" ];then
        check_interface=`echo $ethString|egrep "^$interfacestring,|,$interfacestring,|,$interfacestring\$"|wc -l`
        if [ $check_interface == 0 ];then
           ethString="${ethString},${interfacestring}${nic_interface}"
        fi
   else
        ethString="${ethString}${interfacestring}${nic_interface}"
  fi
}
boundid_check(){
  interface_id=$1
  Mac_address=$2
  if [ "$Mac_address" != "" ];then
     bondid=`/usr/bin/sqlite /etc/cfg/conf.db "select id from link_interface where mac='$Mac_address'"`
     if [ "$bondid" != "" ];then
        countbound="echo ${ethString}|grep bond\${bondid}|wc -l"
        countbound_d=`eval $countbound`
        if [ $countbound_d == 0 ];then
              set_interfacestring "bond${bondid}"
        fi
      else
        set_interfacestring "${interface_id}"
     fi
    else
        set_interfacestring "${interface_id}"
   fi
                                              
}
setinterface(){
   new_interface=$1
   if [ $new_interface == "eth" ];then
      fList=`ifconfig | grep eth|awk -F' ' '{print $1}'`
      for fIdlist in ${fList}
      do
            check_fList=`echo $fIdlist|grep $new_interface| wc -l`
            if [ $check_fList != 0 ];then
               Mac_address="ifconfig |grep $fIdlist|awk -F'HWaddr' '{print \$2}'"
               Mac_address_d=`eval $Mac_address`
               if [ $fIdlist != "eth0" ];then
                  boundid_check $fIdlist $Mac_address_d
               fi
             fi
      done
      Mac_address=`ifconfig| grep eth0|awk -F'HWaddr' '{print $2}'`
      boundid_check "eth0" $Mac_address
     else
      fList=`ifconfig| grep $new_interface|awk -F' ' '{print $1}'`
      for fIdlist in ${fList}
      do
           check_fList=`echo $fIdlist|grep $new_interface| wc -l`                                                                                           
           if [ $check_fList != 0 ];then
              Mac_address="ifconfig |grep $fIdlist|awk -F'HWaddr' '{print \$2}'"
              Mac_address_d=`eval $Mac_address`
              boundid_check $fIdlist $Mac_address_d
           fi
      done
     fi
}    
                                                                                               
#####Function#####
create_db() {
  if [ -f "${raid_db}" ]; then
    rm -rf ${raid_db}
    echo "${raid_db} exist"
  fi
  /bin/touch ${raid_db}

  if [ "$snapshot" != "0" ];then
    /bin/touch ${snap_db}
  fi
}

create_gtb() {
  #smb global setting
  $sql $raid_db "create table smb_global(k,v,m)"
}

create_stb() {
  #raid setting
  $sql $raid_db "create table conf(k,v)"
  #share folder default setting
  $sql $raid_db "create table smb_share(k,v,m)"
  #service folder setting
  $sql $raid_db "create table smb_specfd('share','comment','browseable','guest only','path','map hidden','recursive','readonly','speclevel')"
  #user folder setting
  $sql $raid_db "create table smb_userfd('share','comment','browseable','guest only','path','map hidden','recursive','readonly','speclevel')"
}

check_ftp_link(){
  #delete unexist link
  if [ -d ${ftproot} ];then
    echo "Check link in ftproot"
    cd ${ftproot}

    for folder in *
    do
      if [ "${folder}" != '*' -a "${folder}" != '' ];then
        link=`readlink "${folder}"`
        if [ ! -d "${link}" ];then
          rm -f "${folder}"
        fi
      fi
    done
    cd -
  fi
}

#################################################
#         NAME:  get_one_conf_data
#  DESCRIPTION:  get field vaule from DB,
#                and if not exist , INSERT default value
#      PARAM 1:  db field name
#      PARAM 2:  default value
#       RETURN:  field value
#################################################
get_one_conf_data(){
    local fField="$1"
    local fDefVal="$2"
    local fVal            #field value
    local fCount=`${sql} ${conf_db} "SELECT COUNT(v) FROM conf WHERE k='${fField}'"` #match field count

    if [ "${fCount}" == "0" ];then
        fVal="${fDefVal}"
        ${sql} ${conf_db} "INSERT INTO conf VALUES('${fField}','${fDefVal}')"
    else
        fVal=`${sql} ${conf_db} "SELECT v FROM conf WHERE k='${fField}'"`
    fi
    echo "${fVal}"
}

create_conf() {
  #setting data from /raid#/sys/smb.db to /var/run/smb.conf

  ## "global" part
  ldap_enable=`$sql $conf_db "select v from conf where k='ldap_enabled'"`
  samba_log=`$sql $conf_db "select v from conf where k='smb_log'"`
  echo Confile = ${Confile}
  if [ "${ldap_enable}" == "1" ];then
       ldap_ip=`$sql $conf_db "select v from conf where k='ldap_ip'"`
       ldap_tls=`$sql $conf_db "select v from conf where k='ldap_tls'"`
       if [ "${ldap_tls}" == "SSL" ];then
           update_global 'passdb backend'  "ldapsam:ldaps://${ldap_ip}"
       else
           update_global 'passdb backend'  "ldapsam:ldap://${ldap_ip}"
       fi
  else
       update_global 'passdb backend'  "tdbsam:/etc/cfg/samba/passdb.tdb"
  fi
  update_global 'idmap backend'       "rid"

  #Issue 4749 For user/group backup.
  update_global 'private dir'     "/etc/cfg/samba"

  # Dump the smb_global of smb.db into the file smb.conf.
  $sql $raid_db "select k,v,m from smb_global" | \
  awk -F'|' 'BEGIN{print "[global]"}{if ($3==1) printf "#";printf "%s = %s\n",$1,$2}' \
  > ${Confile}

  if [ -f /tmp/ha_role ] && [ "`cat /tmp/ha_role`" = "active" ];then
    ha_virtual_name=`$sql $conf_db "select v from conf where k='ha_virtual_name'"`
    sed -i "s/server string = %h/server string = $ha_virtual_name/" ${Confile}
    echo "netbios name = ${ha_virtual_name}" >> ${Confile}
  fi
  
  if [ "${ldap_enable}" == "1" ];then
     ldap_ip=`$sql $conf_db "select v from conf where k='ldap_ip'"`
     ldap_domain=`$sql $conf_db "select v from conf where k='ldap_dmname'"`
     ldap_id=`$sql $conf_db "select v from conf where k='ldap_id'"`
     ldap_bind_dn=`$sql $conf_db "select v from conf where k='ldap_bind_dn'"`
     user_dn=`$sql $conf_db "select v from conf where k='ldap_user_dn'" | sed "s/,${ldap_domain}//g"`
     group_dn=`$sql $conf_db "select v from conf where k='ldap_group_dn'" | sed "s/,${ldap_domain}//g"`
     #ldap_passwd=`$sql $conf_db "select v from conf where k='ldap_passwd'"`
     echo "ldap timeout = 5" >> ${Confile}
     echo "ldap admin dn = \"${ldap_bind_dn}\"" >> ${Confile}

     if [ "${ldap_tls}" == "TLS" ];then
         echo "ldap ssl = start tls" >> ${Confile}
     else
         echo "ldap ssl = off" >> ${Confile}
     fi

     echo "ldap suffix = \"${ldap_domain}\"" >> ${Confile}
     echo "ldap delete dn = no" >> ${Confile}
     echo "ldap user suffix = ${user_dn}" >> ${Confile}
     echo "ldap group suffix = ${group_dn}" >> ${Confile}
     echo "ldap passwd sync = yes" >> ${Confile}
     echo "idmap backend = ldap:ldap://${ldap_ip}" >> ${Confile}
  fi
  
  if [ "`/img/bin/check_service.sh smb_preallocate`" = "1" ];then
    echo "preallocate = yes" >> ${Confile}
  fi

  #improve the samba performance for ppc
  soc="`/img/bin/check_service.sh soc`"
  if [ "${soc}" == "ppc" ];then
    advance_receivefile_size=`get_one_conf_data "advance_receivefile_size" "1"`
    if [ "${advance_receivefile_size}" == "1" ];then
        echo "min receivefile size = 32767" >> ${Confile}
    else
        echo "min receivefile size = 0" >> ${Confile}
    fi

    echo "max xmit = 65536" >> ${Confile}
  fi

  ## block size
  blocksize=`get_one_conf_data "advance_smb_blocksize" "1"`
  if [ "${blocksize}" == "1" ];then
    echo "block size = 4096" >> ${Confile}
  else
    echo "block size = 1024" >> ${Confile}
  fi

  ## allocation roundup size
  #Fix the file bigger in issue "4256"
  default_value=`/img/bin/check_service.sh smb_buffering_size`
  roundup=`get_one_conf_data "smb_buffering_size" "$default_value"`
  if [ "${roundup}" == "0" ];then
    echo "allocation roundup size = 0" >> ${Confile}
  else
    echo "allocation roundup size = 1048576" >> ${Confile}
  fi

  ## veto files
  veto=`get_one_conf_data "advance_smb_veto" "1"`
  if [ "${veto}" == "1" ];then
    echo "veto files = /.AppleDouble/.AppleDB/.bin/.AppleDesktop/Network Trash Folder/:2eDS_Store/.DS_Store/:2eTemporaryItems/:2eFBCIndex/" >> ${Confile}
    echo "delete veto files = yes" >> ${Confile}
  fi

  ## Each Share Folder
  ##-- System Folder (smb_specfd)
  md=`ls -la /raid |awk -F\/ '{print $3}' | awk -F'raid' '{print $2}'`
  speclen=`$sql $raid_db 'select count(*) from smb_specfd'`
  offset=0
  smb_recycle_enable=`$sql $conf_db "select v from conf where k='advance_smb_recycle'"`
  recycle_display=`$sql $conf_db "select v from conf where k='recycle_display'"`
  fs=`$sql $raid_db 'select v from conf where k="filesystem"'`
  if [ "$recycle_display" == '1' ];then
     recycle_displaydetail='yes'
  else
     recycle_displaydetail='no'
  fi   
  while [ ${offset} -lt ${speclen} ]
  do
    if [ "`/img/bin/check_service.sh arch`" = "oxnas" ];then
      $sql $raid_db "select * from smb_specfd limit 1 offset ${offset}" | \
      awk -F'|' '{printf "\n[%s]\ncomment = %s\nbrowseable = %s\nguest only = %s\npath = %s\nmap hidden = %s\nstore dos attributes = yes\n",$1,$2,$3,$4,$5,$6}END{if ($1=="USBHDD")printf "strict allocate = no\n";if ($1=="eSATAHDD")printf "strict allocate = no\n";if($8=="1"&&$4=="yes")printf "read only = yes\n";if($8!="1"||$4!="yes")printf "read only = no\n"}' \
      >> ${Confile}
    else
      $sql $raid_db "select * from smb_specfd limit 1 offset ${offset}" | \
    awk -F'|' '{printf "\n[%s]\ncomment = %s\nbrowseable = %s\nguest only = %s\npath = /raid/data/%s\nmap hidden = %s\nstore dos attributes = yes\nfollow symlinks = yes\nwide links = yes\n",$1,$2,$3,$4,$5,$6}END{if ($1=="USBHDD")printf "strict allocate = no\n";if ($1=="eSATAHDD")printf "strict allocate = no\n";if($8=="1"&&$4=="yes")printf "read only = yes\n";if($8!="1"||$4!="yes")printf "read only = no\n"}' \
      >> ${Confile}
    fi
    
    if [ "${fs}" == "xfs" ] || [ "${fs}" == "ext3" ];then
      echo "strict allocate = no" >> ${Confile}
    fi   

    sharename=`$sql $raid_db "select share from smb_specfd limit 1 offset ${offset}"`
    ln -sf  "/raid${md}/data/$sharename" /raid/data/ftproot/
    create_share_default

    ##-- Recycle Bin & Access Log Part
    ##-- Option "vfs object" judge
    local vfs_objects_option=""
    [ "$smb_recycle_enable" == "1" ] && vfs_objects_option=" recycle"
    [ "$samba_log" == "1" ] && vfs_objects_option="$vfs_objects_option full_audit"
    [ ! -z "$vfs_objects_option" ] && echo "vfs objects =$vfs_objects_option" >> ${Confile}

    ##-- Recycle Bin Part
    if [ $smb_recycle_enable == '1' ];then
      raid_id=`$sql $raid_db "select v from conf where k='raid_name'"`
      SMB_MAXSIZE=`$sql $conf_db "select v from conf where k='smb_maxsize'"`
      if [ "$SMB_MAXSIZE" != "" ];then
         if [ "$SMB_MAXSIZE" -gt 0 ];then
            SMB_MAXSIZETOTAL=$((SMB_MAXSIZE*1073741824))
            printf "recycle:keeptree = Yes\nrecycle:versions = Yes\nrecycle:repository = /raid/data/_NAS_Recycle_$raid_id\nrecycle: maxsize=$SMB_MAXSIZETOTAL\n" \
            >> ${Confile}
         else   
            printf "recycle:keeptree = Yes\nrecycle:versions = Yes\nrecycle:repository = /raid/data/_NAS_Recycle_$raid_id\n" \
            >> ${Confile}
         fi
        else
          printf "recycle:keeptree = Yes\nrecycle:versions = Yes\nrecycle:repository = /raid/data/_NAS_Recycle_$raid_id\n" \
          >> ${Confile}
      fi
    fi

    ##-- Access Log Part
    if [ "${samba_log}" == "1" ];then
      echo "full_audit:prefix = %u|%I|%m|%S" >> ${Confile}
      echo "full_audit:failure = none" >> ${Confile}
      echo "full_audit:success = mkdir rmdir read write rename unlink open" >> ${Confile}
      echo "full_audit:facility = local5" >> ${Confile}
      echo "full_audit:priority = notice" >> ${Confile}
    fi

    offset=`expr ${offset} + 1`
  done

  ##-- User Folder (smb_userfd)
  for md in $md_list
  do
    raid_db="/raidsys/$md/smb.db"
    #user folder
    userlen=`$sql $raid_db 'select count(*) from smb_userfd'`
    fs=`$sql $raid_db 'select v from conf where k="filesystem"'`
    offset=0
    while [ ${offset} -lt ${userlen} ]
    do
      $sql $raid_db "select * from smb_userfd limit 1 offset ${offset}" | \
      awk -F'|' '{printf "\n[%s]\ncomment = %s\nbrowseable = %s\nguest only = %s\npath = /raid'$md'/data/%s\nmap hidden = %s\nstore dos attributes = yes\n",$1,$2,$3,$4,$5,$6}END{if($8=="1"&&$4=="yes")printf "read only = yes\n";if($8!="1"||$4!="yes")printf "read only = no\n"}' \
      >> ${Confile}
      
      if [ "${fs}" == "xfs" ] || [ "${fs}" == "ext3" ];then
        echo "strict allocate = no" >> ${Confile}
      fi
      sharename=`$sql $raid_db "select share from smb_userfd limit 1 offset ${offset}"`
      ln -sf  "/raid$md/data/$sharename" /raid/data/ftproot/
      create_share_default

      ##-- Recycle Bin & Access Log Part
      ##-- Option "vfs object" judge
      vfs_objects_option=""
      [ "$smb_recycle_enable" == "1" ] && vfs_objects_option=" recycle"
      [ "$samba_log" == "1" ] && vfs_objects_option="$vfs_objects_option full_audit"
      [ ! -z "$vfs_objects_option" ] && echo "vfs objects =$vfs_objects_option" >> ${Confile}

      ##-- Recycle Bin Part
      if [ $smb_recycle_enable == '1' ];then
        raid_id=`$sql $raid_db "select v from conf where k='raid_name'"`
        SMB_MAXSIZE=`$sql $conf_db "select v from conf where k='smb_maxsize'"`
        if [ "$SMB_MAXSIZE" != "" ];then
          if [ "$SMB_MAXSIZE" -gt 0 ];then
             SMB_MAXSIZETOTAL=$((SMB_MAXSIZE*1073741824))
             printf "recycle:keeptree = Yes\nrecycle:versions = Yes\nrecycle:repository = /raid$md/data/_NAS_Recycle_$raid_id\nrecycle: maxsize=$SMB_MAXSIZETOTAL\n" \
             >> ${Confile}
          else
             printf "recycle:keeptree = Yes\nrecycle:versions = Yes\nrecycle:repository = /raid$md/data/_NAS_Recycle_$raid_id\n" \
             >> ${Confile}
          fi
         else
          printf "recycle:keeptree = Yes\nrecycle:versions = Yes \nrecycle:repository = /raid$md/data/_NAS_Recycle_$raid_id\n" \
          >> ${Confile}
        fi  
      fi

      ##-- Access Log Part
      if [ "${samba_log}" == "1" ];then
        echo "full_audit:prefix = %u|%I|%m|%S" >> ${Confile}
        echo "full_audit:failure = none" >> ${Confile}
        echo "full_audit:success = mkdir rmdir read write rename unlink open" >> ${Confile}
        echo "full_audit:facility = local5" >> ${Confile}
        echo "full_audit:priority = notice" >> ${Confile}
      fi

      offset=`expr ${offset} + 1`
    done
    raid_id=`$sql $raid_db "select v from conf where k='raid_name'"`
    printf "\n[_NAS_Recycle_$raid_id]\nadmin users = admin\ncomment =\nbrowseable = $recycle_displaydetail\nguest only = no\npath = /raid$md/data/_NAS_Recycle_$raid_id\nmap acl inherit = yes\ninherit acls = yes\nread only = no\ncreate mask = 0777\nforce create mode = 0000\ninherit permissions = Yes\nmap archive = no\nstore dos attributes = yes\nstrict allocate = yes\nmap hidden = no"\
    >> ${Confile}
  done

  check_ftp_link
  
  #############################################################
  #     Create stack folder smb.conf and AppleVolumes.default
  #############################################################
  /bin/rm -rf $tmp_stack_smb_conf
  /img/bin/rc/rc.initiator assemble
  if [ -f "$tmp_stack_smb_conf" ];
  then
    echo "" >> ${Confile}
    /bin/cat $tmp_stack_smb_conf >> ${Confile}
  fi
  
  /img/bin/rc/rc.atalk reload
}

create_share_default() {
  #apply default settings for every share folder
  $sql $raid_db "select k,v,m from smb_share" |grep -v "^read only"| \
  awk -F'|' '{if ($3==1) printf "#";printf "%s = %s\n",$1,$2}' \
  >> ${Confile}
}

insert_global() {
  if [ "$3" = "1" ];then
    $sql $raid_db "insert into smb_global (k,v,m) values ('$1','$2','1')"
  else
    $sql $raid_db "insert into smb_global (k,v,m) values ('$1','$2','0')"
  fi
}         
          
insert_conf() {
  $sql $raid_db "insert into conf (k,v) values ('$1','$2')"

}

update_global() {
  HAS_FIELD=`$sql $raid_db "select * from smb_global where k='$1'"`
  if [ "$HAS_FIELD" == "" ];then
    insert_global "$1" "$2" "$3"
  else
    if [ "$3" = "1" ];then
      $sql $raid_db "update smb_global set v='$2',m='1' where k='$1'"
    else
      $sql $raid_db "update smb_global set v='$2',m='0' where k='$1'"
    fi
  fi
}

insert_share() {
  if [ "$3" = "1" ];then
    $sql $raid_db "insert into smb_share (k,v,m) values ('$1','$2','1')"
  else
    $sql $raid_db "insert into smb_share (k,v,m) values ('$1','$2','0')"
  fi
}         

insert_specfd() {
  $sql $raid_db "insert into smb_specfd ('share','comment','browseable','guest only','path','map hidden','recursive','readonly','speclevel') values ('$1','$2','$3','$4','$1','$5','yes','$6','$7')"
}

init_global() {
  #init settings from /etc/cfg/conf.db to /raid/sys/smb.db
  workgroup=`$sql $conf_db "select v from conf where k='winad_domain'"`
  ads_authtype=`$sql $conf_db "select v from conf where k='winad_AuthType'"`
  server=`$sql $conf_db "select v from conf where k='winad_ip'"`
  realm=`$sql $conf_db "select v from conf where k='winad_realm'"`
  wins=`$sql $conf_db "select v from conf where k='winad_wins'"`
  ethString=""
  setinterface "lo"
  setinterface "wlan"
  setinterface "wth"
  setinterface "geth"
  setinterface "eth"
  insert_global 'server string'       '%h'
  insert_global 'deadtime'       '15'
  insert_global 'hide unreadable'      'yes'
  insert_global 'load printers'       'no'
  insert_global 'log file'       '/var/log/samba.%m'
  insert_global 'log level'       '0'
  insert_global 'max log size'       '50'
  insert_global 'encrypt passwords'     'yes'
  insert_global 'case sensitive'       'auto'
  insert_global 'passdb backend'       'tdbsam'
  insert_global 'socket options'       'TCP_NODELAY'
  insert_global 'use sendfile'       'yes'
  insert_global 'strict allocate'       'yes'
  insert_global 'local master'      'yes'
  insert_global 'domain master'       'no'
  insert_global 'preferred master'     'no'
  insert_global 'unix extensions'      'no'
  insert_global 'dns proxy'       'no'
  insert_global 'dos charset'       'cp850'
  insert_global 'unix charset'       'utf8'
  insert_global 'display charset'     'utf8'
  insert_global 'allow trusted domains'     'no'
  insert_global 'idmap uid'       '20000-60000000'
  insert_global 'idmap gid'       '20000-60000000'
  insert_global 'winbind separator'     '+'
  insert_global 'winbind nested groups'     'yes'
  insert_global 'winbind enum users'     'yes'
  insert_global 'winbind enum groups'     'yes'
  insert_global 'winbind use default domain'  'yes'
  insert_global 'create mask'       '0644'
  insert_global 'map acl inherit'     'yes'
  insert_global 'nt acl support'       'yes'
  insert_global 'map system'       'yes'          '1'
  insert_global 'bind interfaces only'     'yes'
  insert_global 'interfaces'       "${ethString}"
  insert_global 'guest account'       'nobody'
  insert_global 'map to guest'       'Bad User'
  insert_global 'guest only'       'yes'
  insert_global 'workgroup'       "${workgroup}"
  insert_global 'security'       'user'
  insert_global 'auth methods'       'guest sam_ignoredomain'
  insert_global 'password server'     "*"
  insert_global 'private dir'     "/etc/cfg/samba/"
  if [ "${realm}" != "" ];then
    realm=`echo ${realm} | tr "[:lower:]" "[:upper:]"`
  fi
  insert_global 'realm'         "${realm}"
  insert_global 'idmap backend'       "rid:${workgroup}=20000-60000000"
  insert_global 'wins server'       "${wins}"
}

init_conf() {
  insert_conf 'raid_master'       "0"
  insert_conf 'raid_name'       "${raidLable}"
  insert_conf 'percent_data'       "100"
  insert_conf 'percent_sna'       "0"
  insert_conf 'percent_tu'       "0"
  insert_conf 'fsck_last_time'  ""
  insert_conf 'filesystem'      "${fsmode}"
  insert_conf 'zpoolguid'       ""
}

init_share() {
  #####smb folder value#####
  #$sql $raid_db "create table smb_folder(k,v,m)"
  #$sql $raid_db "insert into smb_folder (k,v,m) values ('','','0')"
  #################################################
  insert_share 'map acl inherit'       'yes'
  insert_share 'inherit acls'       'yes'
  insert_share 'read only'       'no'
  insert_share 'create mask'       '0777'
  insert_share 'force create mode'     '0000'
  insert_share 'inherit permissions'     'yes'
  insert_share 'map archive'       'yes'
}

init_specfd() {
  #####smb service folder value#####
  #$sql $raid_db "create table smb_specfd('share','comment','browseable','guest only','path','map hidden','recursive')"
  #$sql $raid_db "insert into smb_specfd ('share','comment','browseable','guest only','path','map hidden','recursive') values ('','','yes','','','','no')"
  #browseable = yes
  #recursive = yes
  #insert_specfd  'share'    'comment'        'browseable'    'guest only'    'map hidden'
  #################################################
  insert_specfd '_NAS_Media'    ''          'yes'      'yes'      'no' '0' '0'
  insert_specfd 'USBCopy'    ''          'yes'      'yes'      'no' '0' '0'
  insert_specfd 'USBHDD'    'Used for external USB HDDs only.'  'yes'      'yes'      'no' '0' '0'

  if [ "$esata_count" != "0" ];then
    insert_specfd 'eSATAHDD'  'Used for eSATA HDDs only.'    'yes'      'yes'      'no' '0' '0'
  fi

  insert_specfd 'NAS_Public'  ''          'yes'      'yes'      'no' '0' '0'
#  insert_specfd '_NAS_Module_Source_'  ''          'yes'      'yes'      'no' '0' '0'

  if [ "$snapshot" != "0" ];then
    insert_specfd 'snapshot'    'Used for snapshots only.'  'yes'      'no'      'no' '0' '0'
  fi
}


raid_default() {
  echo "generate default"
  create_db
  create_gtb
  create_stb
  init_global
  init_conf
  init_share
  init_specfd
}

reset_default() {
  echo "reset default"
  if [ -f ${raid_db} ]; then
    cp ${raid_db} ${temp_db}
    raid_db=${temp_db}
    $sql $raid_db "drop table smb_global"
    create_gtb
    init_global
    cp ${temp_db} /raid/sys/smb.db
  fi
}

Check_SMB() {
  #update settings from /etc/cfg/conf.db to /raid/sys/smb.db, called by rc.samba while booting
  echo Check SMB
  smb_enable=`$sql $conf_db "select v from conf where k='httpd_nic1_cifs'"`
  if [ "${smb_enable}" = "1" ];then
    ethString=""
    setinterface "lo"
    setinterface "wlan"
    setinterface "wth"
    setinterface "geth"
    setinterface "eth"
    interfaces=$ethString
  else
    ethString=""
    setinterface "lo"
    interfaces=$ethString
  fi
  update_global 'interfaces'  "${interfaces}"

  $sql $raid_db "delete from smb_global where k='vfs object' and v='recycle'"
  $sql $raid_db "delete from smb_global where k='recycle: repository'"
  $sql $raid_db "delete from smb_global where k='recycle: maxsize'"
  $sql $raid_db "delete from smb_global where k='recycle: keeptree'"

  smb_recycle_enable=`$sql $conf_db "select v from conf where k='advance_smb_recycle'"`
  if [ -z "${smb_recycle_enable}" ];then
    $sql $conf_db "insert into conf values('advance_smb_recycle','0')"
#  elif [ "${smb_recycle_enable}" = "1" ];then
#    insert_global 'vfs object'       'recycle'
#    insert_global 'recycle: keeptree'     'yes'
#    insert_global 'recycle: repository'    '.Recycle'
#    insert_global 'recycle: maxsize'    '1073741824'
  fi

  $sql $raid_db "delete from smb_global where k='restrict anonymous'"
  smb_restrict_anonymous=`$sql $conf_db "select v from conf where k='advance_smb_restrict_anonymous'"`
  if [ -z "${smb_restrict_anonymous}" ];then
    $sql $conf_db "insert into conf values('advance_smb_restrict_anonymous','0')"
  elif [ "${smb_restrict_anonymous}" = "1" ];then
    insert_global 'restrict anonymous' '2'
  fi

  local_master=`$sql $conf_db "select v from conf where k='advance_smb_localmaster'"`
  if [ "${local_master}" != "0" ];then
    if [ "${local_master}" = "" ];then
      $sql $conf_db "insert into conf values('advance_smb_localmaster','1')"
    fi
    update_global 'local master'  'yes'
  else
    update_global 'local master'  'no'
  fi

  trusted_conf=`$sql $conf_db "select v from conf where k='advance_smb_trusted'" | awk '{if ($1 == "1") print "yes";else print "no"}'`
  trusted_smbdb=`$sql $raid_db "select v from smb_global where k='allow trusted domains'"`
  if [ "${trusted_conf}" == "" ]; then
    trusted_conf="no"    
  fi
  if [ "${trusted_smbdb}" != "${trusted_conf}" ]; then
    update_global 'allow trusted domains' "${trusted_conf}"
  fi

  $sql $raid_db "delete from smb_global where k='unix extensions'"
  unix_extensions=`$sql $conf_db "select v from conf where k='advance_smb_unix_exten'"`
  if [ "${unix_extensions}" != "1" ];then
    if [ "${unix_extensions}" = "" ];then
      $sql $conf_db "insert into conf values('advance_smb_unix_exten','0')"
    fi
    insert_global 'unix extensions'  'no'
  else
    insert_global 'unix extensions'  'yes'
  fi
}

Check_AD() {
  echo Check AD
  ads_enable=`$sql $conf_db "select v from conf where k='winad_enable'"`
  ads_authtype=`$sql $conf_db "select v from conf where k='winad_AuthType'"`
  wins=`$sql $conf_db "select v from conf where k='winad_wins'"`
  workgroup=`$sql $conf_db "select v from conf where k='winad_domain'"`
  server=`$sql $conf_db "select v from conf where k='winad_ip'"`
  realm=`$sql $conf_db "select v from conf where k='winad_realm'"`
  smb_ext_auth=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='smb_ext_auth_switch'"`
  if [ "${ads_enable}" = "1" ];then
    if [ "${ads_authtype}" = "nt" ];then
      ads_security="domain"
    else
      ads_security="ads"
    fi
    auth_methods="guest sam_ignoredomain winbind"
  elif [ "$smb_ext_auth" == "1" ];then
    echo Skip Check AD
    return
  else
    ads_security="user"
    auth_methods="guest sam_ignoredomain"
    workgroup=`$sql $conf_db "select v from conf where k='winad_domain'"`
  fi

  update_global 'security'       "${ads_security}"
  update_global 'auth methods'       "${auth_methods}"
  update_global 'wins server'       "${wins}"
  update_global 'workgroup'       "${workgroup}"
  update_global 'password server'     "*"
  if [ "${realm}" != "" ];then
    realm=`echo ${realm} | tr "[:lower:]" "[:upper:]"`
  fi
  update_global 'realm'         "${realm}"
  update_global 'idmap backend'       "rid:${workgroup}=20000-60000000"
}

assemble_Conf() {
  echo "assemble Conf to" $1
  [ "$1" != "" ] && Confile=$1 || echo "Use default file '${Confile}'"
  create_conf
}

case "${Cmd}" in
  raidDefault)
    model=`cat /var/run/model`
    if [ "`cat /img/bin/conf/sysconf.${model}.txt | awk -F'=' '/m_raid/{print $2}'`" = "1" ];then
      lun=`echo $2| tr -d raid`
      raid_db="/raidsys/${lun}/smb.db"
      snap_db="/raidsys/${lun}/snapshot.db"
      raidLable=$3
      fsmode=$4
    fi
    raid_db_final=${raid_db}
    raid_db=${raid_db}.tmp
    rm -f ${raid_db}
    raid_default
    cp -f ${raid_db} ${raid_db_final}
    if [ $? != 0 ];then
      echo `date`-try_smbdb_1_${lun} >> /syslog/smbdb.log
      cp -f ${raid_db} ${raid_db_final}
      if [ $? != 0 ];then
        echo `date`-try_smbdb_2_${lun} >> /syslog/smbdb.log
      fi
    fi
  ;;
  resetDefault)
    reset_default
  ;;
  assembleConf)
    assemble_Conf $2
  ;;
  chkAD)
    Check_AD
  ;;
  chkSMB)
    Check_SMB
  ;;
  *)
    echo $"Usage: $0 {resetDefault|assembleConf|chkAD|chkSMB}"
    exit 1
esac

exit 0
