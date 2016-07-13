#!/bin/sh
#
# Backup system status for debug 
# backup_systatus.sh
#
##################################################################
#
#  First, define some variables globally needed
#
##################################################################
. /img/bin/functions
. /img/bin/diagnostics/functions

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################

##################################################################
#
#  Finally, exec main code
#
##################################################################
echo "###############################"
echo "# Backup System status for Debug"
echo "###############################"
diag_log "Backup system status for debug..."

mkdir -p ${diag_mpath}/${back_dir}/etc

if [ -f ${NEWROOT}/img/bin/default.list ]; then
    while read line
    do
	[ -z "$line" ] && continue
	[ "${line:0:1}" = "#" ] && continue
	[ ! -f "${NEWROOT}/$line" ] && continue
	cp -af "${NEWROOT}/$line" ${diag_mpath}/${back_dir}/etc/
    done < ${NEWROOT}/img/bin/default.list
fi

if [ -f ${NEWROOT}/etc/cfg/logfile ]; then
    ${NEWROOT}/usr/bin/savelog ${NEWROOT}/etc/cfg/logfile > ${diag_mpath}/${back_dir}/etc/logfile
fi

cp -rfd ${NEWROOT}/raidsys ${diag_mpath}/${back_dir}/

[ -f ${NEWROOT}/etc/nsswitch.conf ] && cp -a ${NEWROOT}/etc/nsswitch.conf ${diag_mpath}/${back_dir}/etc/

ls -la ${NEWROOT}/raidsys/* > ${diag_mpath}/${back_dir}/ls_raidsys.txt  2>&1
ls -la ${NEWROOT}/raid0/data/* > ${diag_mpath}/${back_dir}/ls_raid_data.txt 2>&1

cp -a ${NEWROOT}/var/log ${diag_mpath}/${back_dir}/ 
