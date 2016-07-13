#!/bin/sh
#
# check RPM installation 
# check_rpm.sh
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
echo "# Check RPM installation"
echo "###############################"
diag_log "Check RPM installation..."

if [ ! -d /rpm ]; then
	mkdir /rpm
fi
dev_dom=`get_rpm_device`
mount -t ext4 -o ro /dev/${dev_dom} /rpm
if [ $? -eq 0 ]; then
	while read line
	do
		[ -z "$line" ] && continue
		[ "${line:0:1}" = "#" ] && continue
		pkg=`echo "$line" | awk -F'-[0-9][-.0-9]' '{print $1}'`
		ret=0
		echo "rpm -V --root ${NEWROOT} $pkg" >> ${diag_mpath}/${back_dir}/rpm_check.txt
		rpm -V --root ${NEWROOT} $pkg >/tmp/rpm_check 2>&1
		if [ $? -ne 0 ]; then
			grep "is not installed" /tmp/rpm_check >/dev/null 2>/dev/null
			if [ $? -eq 0 ]; then
				ret=1
				diag_log "$pkg is not installed"
			fi
			grep "^missing" /tmp/rpm_check >/dev/null 2>/dev/null	
			if [ $? -eq 0 ]; then
				grep "^missing" /tmp/rpm_check | egrep "/lib/udev/rules.d/65-md-incremental.rules|/etc/hosts.allow|/etc/hosts.deny" >/dev/null 2>/dev/null
				if [ $? -ne 0 ]; then
					ret=1
					diag_log "$pkg missing files"
				fi
			fi
			if [ $ret -ne 0 ]; then
				# need to re-install the rpm
				if [ -f /rpm/$line.rpm ]; then
					echo "rpm -Uv --force --nodeps --root ${NEWROOT} /rpm/$line.rpm" >> ${diag_mpath}/${back_dir}/rpm_install.txt
					rpm -Uv --force --nodeps --root ${NEWROOT} /rpm/$line.rpm >> ${diag_mpath}/${back_dir}/rpm_install.txt 2>&1
					if [ $? -eq 0 ]; then
						diag_log "re-install $line"
					else
						diag_log "re-install $line failed"
					fi
				else
					diag_log "/rpm/$line.rpm doesn't exist"	
				fi
			fi
		fi
		cat /tmp/rpm_check >> ${diag_mpath}/${back_dir}/rpm_check.txt
	done < /img/bin/packages
	rm -f /tmp/rpm_check
	sync
	umount /rpm
	rm -rf /rpm
else
    rm -rf /rpm
    diag_log "Cannot get rpm packages"
fi

diag_log "Check finished"
