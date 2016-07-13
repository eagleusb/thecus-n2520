#!/bin/sh
#
# chkconfig: - 39 35
# description: Starts and stops the iSCSI initiator
#
# pidfile: /var/run/iscsid.pid
# config:  /etc/iscsid.conf

ISCSID="/sbin/iscsid"
ISCSIADM="/sbin/iscsiadm"
PIDFILE="/var/run/iscsid.pid"
ISCSIDB="/etc/cfg/stackable.db"
SQLITE="/usr/bin/sqlite"
IFCONFIG="/sbin/ifconfig"
ISCSI_RMOUNT="/raid/data/stackable"
ISCSI_DBFOLDER="/var/db/iscsi"
ISCSI_SMB="/tmp/iscsi_smb.conf"
ISCSI_ATALK="/tmp/iscsi_AppleVolumes.default"
ISCSI_NFS="/tmp/iscsi_exports"
CONFDB="/etc/cfg/ha.db"
ISCSI_SYSDOLDER="/etc/iscsi"
ISCSI_INAME="/etc/iscsi/initiatorname.iscsi"
ISCSID_CONF="/etc/iscsid.conf"
FTPROOT="/raid/data/ftproot"
MOUNTFS="ext4"
MOUNTPARM="user_xattr,acl,rw,noatime"
ATALK_MAC_CHARSET=`/usr/bin/sqlite ${CONFDB} "select v from conf where k='httpd_charset'"`
if [ "${ATALK_MAC_CHARSET}" = "" ];then
  ATALK_MAC_CHARSET="MAC_ROMAN"
fi

if [ -z $ISCSID ] || [ -z $ISCSIADM ]
then
    echo "open-iscsi not installed."
    exit 1
fi

. /img/bin/rc/functions

check_stackable_db(){
  table_exist=`$SQLITE $ISCSIDB ".tables"`
  if [ ! -f "$ISCSIDB" ] || [ "$table_exist" == "" ];
  then
    echo "create new stackable database"
    /bin/rm $ISCSIDB
    /bin/touch $ISCSIDB
    #$SQLITE $ISCSIDB "create table nfs(share,hostname,privilege,rootaccess)"
    $SQLITE $ISCSIDB "create table stackable(enabled,ip,port,iqn,user,pass,share,pshare,comment,browseable,guest_only,quota_limit,quota_used,recursive)"
  else
    echo "stackable database is exist"
  fi
}

iscsidconf() {
echo -e "node.active_cnx = 1 \n\
node.startup = manual \n\
#node.session.auth.username = dima \n\
#node.session.auth.password = aloha \n\
node.session.timeo.replacement_timeout = 60 \n\
node.session.err_timeo.abort_timeout = 10 \n\
node.session.err_timeo.reset_timeout = 30 \n\
node.session.iscsi.InitialR2T = No \n\
node.session.iscsi.ImmediateData = Yes \n\
node.session.iscsi.FirstBurstLength = 262144 \n\
node.session.iscsi.MaxBurstLength = 16776192 \n\
node.session.iscsi.DefaultTime2Wait = 60 \n\
node.session.iscsi.DefaultTime2Retain = 60 \n\
node.session.iscsi.MaxConnections = 1 \n\
node.cnx[0].iscsi.HeaderDigest = None \n\
node.cnx[0].iscsi.DataDigest = None \n\
node.cnx[0].iscsi.MaxRecvDataSegmentLength = 262144 \n\
#discovery.sendtargets.auth.authmethod = CHAP \n\
#discovery.sendtargets.auth.username = dima \n\
#discovery.sendtargets.auth.password = aloha \n"

}

smb_folder() {
	share_name=$1
	comment=$2
	browseable=$3
	guest_only=$4
	
	if [ "$browseable" != "yes" ];then
		browseable="no"
	fi
	
	if [ "$guest_only" != "yes" ];then
		guest_only="no"
		maphidden="yes"
	else
		maphidden="no"
	fi
	
  echo -e [$share_name]"\n"\
comment = $comment"\n"\
browseable = $browseable"\n"\
guest only = $guest_only"\n"\
path = $ISCSI_RMOUNT/$share_name/data"\n"\
map acl inherit = yes"\n"\
inherit acls = yes"\n"\
read only = no"\n"\
create mask = 0777"\n"\
force create mode = 0000"\n"\
inherit permissions = Yes"\n"\
map archive = yes"\n"\
map hidden = $maphidden"\n"

}

assemble_iscsi() {
	if [ -d $ISCSI_RMOUNT ] && [ -f $ISCSIDB ];then
		if [ -f $ISCSI_SMB ];then
			rm -rf $ISCSI_SMB
			touch $ISCSI_SMB
		fi
		if [ -f $ISCSI_ATALK ];then
			rm -rf $ISCSI_ATALK
			touch $ISCSI_ATALK
		fi
		
		master_raid=`ls -al /raid| awk '{print $11}'`
    count_rmount=`echo "${master_raid}/stackable/"|wc -c`
		strExec=`printf "/bin/df|grep \"/raid[0-9]/data/stackable/\"|awk '{print substr(\\$6,%d)}'" $count_rmount`
		mount_list=`eval "$strExec"`
		for share in $mount_list
		do
			iscsi_data=`$SQLITE $ISCSIDB "select browseable,guest_only from stackable where share='$share' limit 0,1"`
			if [ "$iscsi_data" != "" ];then
				iscsi_browseable=`echo "$iscsi_data"|awk -F\| '{print $1}'`
				iscsi_guest_only=`echo "$iscsi_data"|awk -F\| '{print $2}'`
				iscsi_comment=`$SQLITE $ISCSIDB "select comment from stackable where share='$share' limit 0,1"`
				smb_folder "$share" "$iscsi_comment" "$iscsi_browseable" "$iscsi_guest_only" >> $ISCSI_SMB
				###########################################
				#	Assemble afp conf
				###########################################
				echo -e "\"${ISCSI_RMOUNT}/${share}/data\" \"$share\" options:usedots,noadouble maccharset:$ATALK_MAC_CHARSET volcharset:UTF8" >> $ISCSI_ATALK
				###########################################
				#	Link stack folder to ftproot
				###########################################
				ln -s "${ISCSI_RMOUNT}/${share}/data" "${FTPROOT}/${share}"
			fi
		done
		
	else
		echo "[Error]Mount Folder [$ISCSI_RMOUNT] or Database [$ISCSIDB] Lost!!"
	fi
}

connect_iscsi() {
	if [ -f $ISCSIDB ];then
		if [ ! -d $ISCSI_RMOUNT ];then
			mkdir -p $ISCSI_RMOUNT
		fi
		datalit=`$SQLITE $ISCSIDB "select ip,port,iqn from stackable where enabled='1' group by ip,port,iqn"|awk -F\| '{printf("ip=\"%s\" and port=\"%s\" and iqn=\"%s\"\n",$1,$2,$3)}'`
		echo "$datalit" | \
			while read datakey
      do
      	if [ "$datakey" = "" ];then
      		break
      	fi
      	##Discovery iSCSI target
      	iscsi_portal=`$SQLITE $ISCSIDB "select ip,port from stackable where $datakey limit 0,1"|awk -F\| '{printf("%s:%s",$1,$2)}'`
      	iscsi_iqn=`$SQLITE $ISCSIDB "select iqn from stackable where $datakey limit 0,1"`
      	iscsi_user=`$SQLITE $ISCSIDB "select user from stackable where $datakey limit 0,1"`
      	iscsi_pass=`$SQLITE $ISCSIDB "select pass from stackable where $datakey limit 0,1"`
      	iscsi_share=`$SQLITE $ISCSIDB "select share from stackable where $datakey limit 0,1"`
      	if [ "$iscsi_portal" != "" ];then
      		$ISCSIADM -m discovery -tst --portal $iscsi_portal
      		##login iSCSI iqn
      		TARGETS=`$ISCSIADM -m node |grep  $iscsi_portal|grep $iscsi_iqn | sed 's@\[\(.*\)\] .*@\1@g'`
					RETVAL=-1
#					for rec in $TARGETS
#					do
						##Setting vlaue
						RETVAL=-1
					if [ "$TARGETS" != "" ];then
						if [ "$iscsi_iqn" != "" ] && [ "$iscsi_portal" != "" ];then
							if [ "$iscsi_user" != "" ];then
								$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.session.auth.authmethod -v CHAP
								$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.session.auth.username -v $iscsi_user
								$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.session.auth.password -v $iscsi_pass
							else
								$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.session.auth.authmethod -v None
								$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.session.auth.username -v ""
								$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.session.auth.password -v ""
							fi
							$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.conn[0].iscsi.HeaderDigest -v "None"
							$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -o update -n node.conn[0].iscsi.DataDigest -v "None"
        			$ISCSIADM -m node -T $iscsi_iqn -p $iscsi_portal -l
        			RETVAL="$?"
        		fi
					fi
	#				done
      		##Mount iSCSI iqn
      		if [ "$RETVAL" = "0" ];then
      			sleep 3
      			iscsi_traykey=`$ISCSIADM -m session |grep  $iscsi_portal|grep $iscsi_iqn | head -1|awk '{print $2}'|sed 's/\[//'|sed 's/\]//'`
      			##get disk name
      			TARGETS=`ls -laR /sys/class/iscsi_session/session${iscsi_traykey}/device/|awk -F/ '/block\/sd.*:$/&&!/block\/sd.*\//{print substr(\$10,0,length(\$10)-1)}'`
      			for iscsi_diskname in $TARGETS
            do
              if [ "$iscsi_diskname" != "" ];
        			then
        				diskname_exist=`cat /proc/partitions | grep "${iscsi_diskname}1"`
        				if [ "${diskname_exist}" != "" ];
        				then
                  iscsi_diskname="${iscsi_diskname}1"
      	   			else
                  iscsi_diskname="${iscsi_diskname}"
        				fi
        			fi
        			echo "name = ${iscsi_diskname}"
        			if [ "$iscsi_diskname" != "" ] && [ "$iscsi_share" != "" ];then
				  			if [ ! -d $ISCSI_RMOUNT/$iscsi_share ];then
                  mkdir -p $ISCSI_RMOUNT/$iscsi_share
                fi
        	
      				  mount -t $MOUNTFS -o $MOUNTPARM /dev/$iscsi_diskname $ISCSI_RMOUNT/$iscsi_share
        				smb_path="$ISCSI_RMOUNT/$iscsi_share/data"
        				if [ ! -d "$smb_path" ];
        				then
        				  /bin/mkdir "$smb_path"
                  /bin/chown nobody:users "$smb_path"
                  guest_only=`$SQLITE $ISCSIDB "select guest_only from stackable where share='$iscsi_share'"`
        				  if [ "$guest_only" == "yes" ];
        				  then
        				    /bin/chmod 777 "$smb_path"
        				  else
                    /bin/chmod 700 "$smb_path"
        				  fi
        				fi
        			fi
          	done
      		fi
      	fi
			done
	fi
}

initiatoriqn() {
	#initiator iqn.2007-08.{reverse domain}:storage-server.{MAC address}
	# Ex: Target iqn.2007-08.com.thecus:stackable-server.0014FD109C22
	
	domainname=`$SQLITE $CONFDB "select v from conf where k='nic1_domainname'"|awk -F. '{print $1 " " $2 " " $3}'`

	revdomain=`reverse_domain $domainname`
	
	year="2007"
	month="08"
	ha_name=`$SQLITE $CONFDB "select v from conf where k='ha_virtual_name'" |tr [:upper:] [:lower:]`
	echo "iqn.$year-$month.$revdomain:stackable-server.$ha_name" |tr [:upper:] [:lower:]
}

start_iscsid()
{
    RETVAL=0
 		if [ ! -d $ISCSI_DBFOLDER ];then
			mkdir -p $ISCSI_DBFOLDER
		fi
		if [ ! -d $ISCSI_SYSDOLDER ];then
			mkdir -p $ISCSI_SYSDOLDER
		fi
    KVER=`uname -r`

		insmod /lib/modules/$KVER/kernel/drivers/scsi/scsi_transport_iscsi.ko
		insmod /lib/modules/$KVER/kernel/drivers/scsi/libiscsi.ko
		insmod /lib/modules/$KVER/kernel/drivers/scsi/libiscsi_tcp.ko
		insmod /lib/modules/$KVER/kernel/drivers/scsi/iscsi_tcp.ko
		
		##create initiator iqn
		iscsi_initiatoriqn=`initiatoriqn`
		change=1
		if [ -f $ISCSI_INAME ];then
			oiqn=`cat $ISCSI_INAME|awk -F\= '{print $2}'`
			if [ "$oiqn" = "$iscsi_initiatoriqn" ];then
				change=0
			fi
		fi
		if [ "$change" = "1" ];then
			echo "InitiatorName=$iscsi_initiatoriqn" > $ISCSI_INAME
		fi
		
		if [ ! -f $ISCSID_CONF ];then
			iscsidconf > $ISCSID_CONF
		fi

    daemon $ISCSID
    RETVAL=$?
    
    ##Connect the iscsi target & try to mount 
    #connect_iscsi

    return $RETVAL
}

stop_iscsid()
{
    RETVAL=0
    sync
    ##umount all stackable device
		devlist=`/bin/df|awk '/\/raid[0-9]\/data\/stackable\//{print $1}'`
    for mountitem in $devlist
    do
    	umount -l $mountitem
    done 
    $ISCSIADM -m node -U all
    pid=`pidofproc $ISCSID`
    if [ "$pid" != "" ];then
    	kill -9 $pid
    fi
    rmmod iscsi_tcp libiscsi_tcp libiscsi scsi_transport_iscsi
    RETVAL=$?
    return $RETVAL
}

start()
{
    RETVAL=0
    echo -n "Starting iSCSI initiator service: "
    
    check_stackable_db
    
    PID=`pidofproc $ISCSID`
    if [ -z "$PID" ]
    then
        start_iscsid
    fi
    if [ $RETVAL == "0" ]
    then
        echo "OK"
    else
        echo "Fail"
    fi
    echo
    return $RETVAL
}

stop()
{
    RETVAL=0
    echo -n "Stopping iSCSI initiator service: "
    PID=`pidofproc $ISCSID`
    if [ "$PID" != "" ]
    then
        stop_iscsid
    fi
    if [ $RETVAL == "0" ]
    then
        echo "OK"
    else
        echo "Fail"
    fi
    echo
    return $RETVAL
}


restart()
{
    stop
    start
}

status()
{
    PID=`pidofproc $ISCSID`
    if [ ! "$PID" ]
    then
        echo "iSCSI initiator is stopped."
        exit 1
    else
        echo "iSCSI initiator is running."
    fi
}


if [ "$1" != "stop" ];then
	runstackable=`/img/bin/check_service.sh stackable`
	if [ "$runstackable" = "" ];then 
		runstackable="0"
	fi
	if [ ! $runstackable -gt 0 ];then
		echo "Not support stackable function"
		exit
	fi
fi

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  status)
        status
        ;;
  connect)
  			connect_iscsi
  			;;
  assemble)
  			assemble_iscsi
  			;;
  initiator_iqn)
  			initiatoriqn
  			;;
  *)
        echo $"Usage: $0 {start|stop|restart|connect|assemble|status}"
        exit 1
esac

exit 0
