#!/bin/sh 
MODELNAME=`awk -F' ' '/^MODELNAME/{printf($2)}' /proc/thecus_io`
sed -i '/^HOSTNAME/d' /etc/sysconfig/network

hostname_handler(){
    echo "HOSTNAME=`cat /etc/HOSTNAME |cut -d . -f1`" >> /etc/sysconfig/network
    cat /etc/HOSTNAME |cut -d . -f1 > /proc/sys/kernel/hostname
}

if [ -f "/etc/ResetDefault" ];then
	echo "Initial default settings..."
	#check link and busybox link
	rm -f /usr/bin/sqlite
	ln -sf /usr/bin/sqlite3 /usr/bin/sqlite

	rm -f /sbin/udhcpc
	ln -sf /sbin/busybox /sbin/udhcpc

	rm -f /bin/ps
	ln -sf /sbin/busybox /bin/ps

	#rm -f /usr/bin/passwd
	#ln -sf /sbin/busybox /usr/bin/passwd

	rm -f /usr/sbin/stond
	ln -sf /usr/sbin/sshd /usr/sbin/stond

	rm -f /sbin/klogd
	ln -sf /sbin/busybox /sbin/klogd

	if [ "`ls /etc/yum.repos.d/ | wc -l`" != "0" ];then
		rm -rf /etc/yum.repos.d/*
	fi

	# Stop the original sshd.service
	systemctl stop sshd.service
	systemctl disable sshd.service

	systemctl stop httpd.service
	systemctl disable httpd.service

	systemctl stop NetworkManager.service
        systemctl disable NetworkManager.service

	cp -rfd /img/bin/default_cfg/default/* /
	cp -rfd /img/bin/default_cfg/${MODELNAME}/* /
	admin_pwd=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='admin_pwd'"`
	echo "${admin_pwd}" | /usr/bin/passwd "root" --stdin
	rm -f /etc/ResetDefault
	sync
        #httpd reset
        /usr/sbin/httpd.tool reset

        hostname_handler

        /img/bin/rc/rc.router reset
fi

