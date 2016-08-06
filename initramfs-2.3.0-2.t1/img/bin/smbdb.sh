#!/bin/sh
. /img/bin/functions
Cmd=$1
raid_db="$NEWROOT/raidsys/0/smb.db"
snap_db="$NEWROOT/raidsys/0/snapshot.db"
raidLable="RAID"

#####Function#####
create_db() {
  if [ -f "${raid_db}" ]; then
    rm -rf ${raid_db}
    echo "${raid_db} exist"
  fi
  touch ${raid_db}
  touch ${snap_db}
}

create_gtb() {
  #smb global setting
  $sqlite $raid_db "create table smb_global(k,v,m)"
}

create_stb() {
  #raid setting
  $sqlite $raid_db "create table conf(k,v)"
  #share folder default setting
  $sqlite $raid_db "create table smb_share(k,v,m)"
  #service folder setting
  $sqlite $raid_db "create table smb_specfd('share','comment','browseable','guest only','path','map hidden','recursive','readonly','speclevel')"
  #user folder setting
  $sqlite $raid_db "create table smb_userfd('share','comment','browseable','guest only','path','map hidden','recursive','readonly','speclevel')"
}

insert_global() {
  if [ "$3" = "1" ];then
    $sqlite $raid_db "insert into smb_global (k,v,m) values ('$1','$2','1')"
  else
    $sqlite $raid_db "insert into smb_global (k,v,m) values ('$1','$2','0')"
  fi
}         
          
insert_conf() {
  $sqlite $raid_db "insert into conf (k,v) values ('$1','$2')"

}

update_global() {
  if [ "$3" = "1" ];then
    $sqlite $raid_db "update smb_global set v='$2',m='1' where k='$1'"
  else
    $sqlite $raid_db "update smb_global set v='$2',m='0' where k='$1'"
  fi
}         

insert_share() {
  if [ "$3" = "1" ];then
    $sqlite $raid_db "insert into smb_share (k,v,m) values ('$1','$2','1')"
  else
    $sqlite $raid_db "insert into smb_share (k,v,m) values ('$1','$2','0')"
  fi
}         

insert_specfd() {
  $sqlite $raid_db "insert into smb_specfd ('share','comment','browseable','guest only','path','map hidden','recursive','readonly','speclevel') values ('$1','$2','$3','$4','$1','$5','yes','$6','$7')"
}

init_global() {
  workgroup="Workgroup"
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
  insert_global 'interfaces'       "lo,eth0"
  insert_global 'guest account'       'nobody'
  insert_global 'map to guest'       'Bad User'
  insert_global 'guest only'       'yes'
  insert_global 'workgroup'       "${workgroup}"
  insert_global 'security'       'user'
  insert_global 'auth methods'       'guest sam_ignoredomain'
  insert_global 'password server'     "*"
  insert_global 'realm'         ""
  insert_global 'idmap backend'       "rid:${workgroup}=20000-60000000"
  insert_global 'wins server'       ""
  insert_global 'private dir'     "/etc/cfg/samba/"
}

init_conf() {
  insert_conf 'raid_master'       "1"
  insert_conf 'raid_name'       "${raidLable}"
  insert_conf 'percent_data'       "100"
  insert_conf 'percent_sna'       "0"
  insert_conf 'percent_tu'       "0"
  insert_conf 'fsck_last_time'  ""
  insert_conf 'filesystem'      "ext4"
  insert_conf 'zpoolguid'       ""
}

init_share() {
  #####smb folder value#####
  #$sqlite $raid_db "create table smb_folder(k,v,m)"
  #$sqlite $raid_db "insert into smb_folder (k,v,m) values ('','','0')"
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
  snapshot=`/img/bin/check_service.sh snapshot`
  esata_count=`/img/bin/check_service.sh esata_count`
  #####smb service folder value#####
  #$sqlite $raid_db "create table smb_specfd('share','comment','browseable','guest only','path','map hidden','recursive')"
  #$sqlite $raid_db "insert into smb_specfd ('share','comment','browseable','guest only','path','map hidden','recursive') values ('','','yes','','','','no')"
  #browseable = yes
  #recursive = yes
  #insert_specfd  'share'    'comment'        'browseable'    'guest only'    'map hidden'
  #################################################
  #insert_specfd '_NAS_Picture_'    ''          'yes'      'yes'      'no' '0' '1'
  insert_specfd '_NAS_Media'    ''          'yes'      'yes'      'no' '0' '0'
  insert_specfd 'USBCopy'    ''          'yes'      'yes'      'no' '0' '0'
  insert_specfd 'USBHDD'    'Used for external USB HDDs only.'  'yes'      'yes'      'no' '0' '0'
  if [ "$snapshot" != "0" ];then
    insert_specfd 'eSATAHDD'  'Used for eSATA HDDs only.'    'yes'      'yes'      'no' '0' '0'
  fi

  insert_specfd 'NAS_Public'  ''          'yes'      'yes'      'no' '0' '0'
#  insert_specfd '_NAS_Module_Source_'  ''          'yes'      'yes'      'no' '0' '0'
  if [ "$esata_count" != "0" ];then
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

case "${Cmd}" in
  raidDefault)
    raid_default
  ;;
  *)
    echo $"Usage: $0 {resetDefault}"
    exit 1
esac

exit 0
