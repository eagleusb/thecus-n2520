#!/bin/sh
###########################################################
#	Event ID (400~499) => Info
#	Event ID (500~599) => Warning
#	Event ID (600~699) => Error
#       Event ID (800~899) => Error
###########################################################

###########################################################
#	Old Information
###########################################################
get997msg(){
	case $1 in
		101)
			echo "The system %s reboot."
			;;
		103)
			echo "The system %s shutdown."
			;;
		104)
			echo "User [ %s ] has been added."
			;;
		105)
			echo "User [ %s ] has been deleted."
			;;
		106)
			echo "Group [ %s ] has been added."
			;;
		107)
			echo "Group [ %s ] has been deleted."
			;;
		108)
			echo "User [ %s ] password changed."
			;;
		114)
			echo "Changed %s network setting, DHCP setting = %s%s%s%s."
			;;
		115)
			echo "The system %s %s network was plugged"
			;;
		116)
			echo "The system %s %s is healthy now."
			;;
		123)
			echo "Network Synchronization : Task %s status [ %s ]."
###########################################################
#	Old Warning
###########################################################

###########################################################
#	Old Email
###########################################################
			;;
		212)
			echo "Network Synchronization : Task %s has failed due to last task still in processing."
			;;
		216)
			echo "The system %s's %s fan has failed. Please shut down the system to prevent overheat."
			;;
		227)
			echo "The FileSystem Check RAID [ %s ] is Success and NO Error to be found."
			;;
		228)
			echo "The FileSystem Check RAID [ %s ] is done.This work have something error.\nThe result code is [ %s ].\nThe result massage is [ %s ]."
###########################################################
#	Old Error
###########################################################
			;;
		308)
			echo "The system %s's %s fan has failed (RPM:%s Temperature:%s)."
			;;
		309)
			echo "The system %s's fan working normally."
			;;
		310)
			echo "The system %s %s network was unplugged."
			;;
		311)
			echo "Unable to get AD server response while request for time checking, will check again in 30 minutes period."
			;;
		318)
			echo "Network Synchronization : Task %s has failed [ %s ]."
			;;
		319)
			echo "Network Synchronization : Task %s has failed [ Previous unfinished task ]."
			;;
		320)
			echo "The system %s's %s fan has failed (RPM:%s)."
			;;

###########################################################
#	Information
###########################################################
		400)
			echo "Power supply healthy"
			;;
		401)
			echo "Power supply %s healthy"
			;;
		402)
			echo ""
			;;
		403)
			echo "Migration Start [ %s ] [ %s ] >> [ %s ]."
			;;
		404)
			echo "Migration End [ %s ] [ %s ] >> [ %s ]."
			;;
		405)
			echo "[ Quota ] Folder [ %s ] add to Quota Management."
			;;
		406)
			echo "[ Quota ] Folder [ %s ] is removed from Quota Management.%s"
			;;
		407)
			echo "You have add folder [ %s ]."
			;;
		408)
			echo "You have delete folder [ %s ]."
			;;
		409)
			echo "You have change folder [%s] info in %s : %s"
			;;
		410)
			echo "Start Upgrade Firmware ....."
			;;
		411)
			echo "Upgrade Firmware Success !!"
			;;
		412)
			echo "[Batch] Create Success"
			;;
		413)
			echo "Expansion Start [ %s ] [ %s ]."
			;;
		414)
			echo "Expansion End [ %s ] [ %s ]."
			;;
		415)
			echo "Disk stackable [ %s ] on %s has been formated."
			;;
		416)
			echo "Disk stackable [ %s ] on %s formatting failed."
			;;
		417)
			echo "Disk stackable [ %s ] on %s has been mounted."
			;;
		418)
			echo "Disk stackable [ %s ] on %s mount failed."
			;;
		419)
			echo "Starting FileSystem Check."
			;;
		420)
			echo "End of FileSystem Check"
			;;
		421)
			echo "%s : RAID [ %s ] %s."
			;;
		422)
			echo "%s : RAID [ %s ] %s : %s = %s , %s."
			;;
		423)
			echo "Changed %s network setting, IP = %s, Netmask = %s."
			;;
		424)
			echo "Changed %s network setting, DHCP setting = %s%s%s%s%s."
			;;
		425)
			echo "Network Synchronization : Task %s status [ %s ]."
			;;
		426)
			echo "[Snapshot] Take snapshot success [ %s ]."
			;;
		427)
			echo "[Snapshot] Auto delete first record [ %s ]."
			;;
		428)
			echo "[Snapshot] Delete snapshot success [ %s ]."
			;;
		429)
			echo "Due to the system has recorded abnormal shut down previously; folder quota synchronization will take place in 10 minutes time. During this period you may face system performance is going down."
			;;
		430)
			echo "Update system quota info done."
			;;
		431)
			echo "Migration End [ %s ] [ %s ] >> [ %s ].Now will doing raid recovery."
			;;
		432)
			echo "Bad block(HD Tray No: %s) scanning start."
			;;
		433)
			echo "Bad block(HD Tray No: %s) scanning has completed, the result is normal."
			;;
		434)
			echo "SMART(HD Tray No: %s) testing start."
			;;
		435)
			echo "SMART(HD Tray No: %s) testing has completed, the result is normal."
			;;
		436)
			echo "System boot up from 2nd DOM."
			;;
		437)
			echo "Online expand fail. Start Offline expand. "
			;;
		438)
			echo "AC Recover"
			;;
		439)
			echo "The system %s shutdown on battery power due to unexpected lost of power."
			;;
		440)
			echo "TFTP service is enabled."
			;;
		441)
			echo "TFTP service is disabled."
			;;
		442)
			echo "TFTP service start.(IP: %s , Port: %s , folder:%s)"
			;;
		443)
			echo "Syslog service start."
			;;
		444)
			echo "Syslog service stop."
			;;
		445)
			echo "Module[%s]: Install success."
			;;
		446)
			echo "Module[%s]: Upgrade success."
			;;
		447)
			echo "Module[%s]: Uninstall success."
			;;
		448)
			echo "Module[%s]: Enable success."
			;;
		449)
			echo "Module[%s]: Disable success."
			;;
		450)
			echo "The current used SSL certification is provided by user."
			;;
		451)
			echo "DataBase[%s] Check Ok."
			;;
		452)
			echo "DataBase[%s] Recovery Start."
			;;
		453)
			echo "DataBase[%s] Recovery success."
			;;
		454)
			echo "Initializing [User Quota] finish."
			;;
		455)
			echo "DataGuard module enabled. [ %s ]"
			;;
		456)
			echo "DataGuard schedule service is disabled. [ %s ]"
			;;
		457)
			echo "DataGuard : Task [ %s ] status [%s Start]."
			;;
		458)
			echo "DataGuard : Task [ %s ] status [%s Success]."
			;;
		459)
			echo "DataGuard : Task [ %s ] status [%s Cancel], Cancel by user."
			;;
		460)
			echo "DataGuard : Task [ %s ] status [ %s ]."
			;;
		461)
			echo "[iSCSI] %s iSCSI Target (%s)."
			;;
		462)
			echo "[iSCSI] %s LUN (%s) on iSCSI Target (%s)."
			;;
		463)
		  echo "Folder Acl Backup : Raid[ %s ] acl %s start."
			;;
		464)
			echo "Folder Acl Backup : Raid[ %s ] acl %s finish."
			;;
		467)
			echo "LDAP client Enable success."
			;;
		468)
			echo "LDAP client Disable success."
			;;
		469)
			echo "SSH service starts."
			;;
		470)
			echo "SSH service stops."
			;;
		471)
			echo "Synchronizing [User Quota] start."
			;;
		472)
			echo "Synchronizing [User Quota] finish."
			;;
		473)
			echo "Synchronizing [User Quota] stop."
			;;
		474)
			echo "Erase disc end."
			;;
		475)
			echo "ISO File buring to CD start."
			;;
		476)
			echo "ISO File buring to CD end."
			;;
		477)
			echo "Generate ISO Data file start."
			;;
		478)
			echo "Generate ISO Data file end."
			;;
		479)
			echo "CD to ISO File start."
			;;
		480)
			echo "CD to ISO File end."
			;;
		481)
			echo "Burning Data disc start."
			;;
		482)
			echo "Burning Data disc end."
			;;
		483)
			echo "Erase disc start."
			;;
		484)
			echo "Burning Cancel."
			;;
		485)
			echo "DataGuard : Task [ %s ] status [%s Start] share folder rename from %s"
			;;
		486)
			echo "DataGuard : Task [ %s ] status [%s Start] lun rename from %s"
			;;
		487)
			echo "Generate ISO Data file Cancel."
			;;                         
		488)
			echo "File system check done."
			;;
		489)
			echo "File system checking ..."
			;;
		490)
			echo "%s resize successfully."
			;;
		491)
			echo "%s resize fail."
			;;
		492)
			echo "The latest update for %s is available."
			;;
		493)
			echo "According to SMART, the %s value[%s] of Disk %s has changed with the previously different [%s]. %s"
			;;
		494)
			echo "The %s of Disk %s has reached %s hours. %s"
			;;
###########################################################
#	Warning
###########################################################
		500)
			echo "Assemble RAID warning, try to force assemble RAID"
			;;
		501)
			echo "Your system is doing [ %s ], so can't poweroff or reboot system"
			;;
		502)
			echo "Your system is doing [ File system check ], so can't poweroff or reboot system"
			;;
		503)
			echo "Your system is doing [ Upgrade Firmware ], so can't poweroff or reboot system"
			;;
		504)
			echo "[Snapshot] Each folder only support %s snapshot record."
			;;
		505)
			echo "Your system last shutdown is abnormal."
			;;
		506)
			echo "Bad block(HD Tray No: %s) scanning has aborted."
			;;
		507)
			echo "SMART(HD Tray No: %s) testing has aborted."
			;;
		508)
			echo "RAID[ %s ] : iSCSI(%s) LUN(%s) used over %s%%."
			;;
		509)
			echo "Your additional lan card has change, but previous setting will remain the same except jumbo frame is see back to disable."
			;;
		510)
			echo "AC Lose"
			;;
		511)
			echo "The battery power is low."
			;;
		512)
			echo "Quota limit has exceeded: %s [ %s ]."
			;;
		513)
			echo "%s Please reload SSL Certificate file."
			;;
		514)
			echo "DataGuard : Task [ %s ] status [%s Skip] , this task is processing."
			;;
		515)
			echo "DataGuard : Task [ %s ] status [%s Skip] , raid is migrating."
			;;
		516)
			echo "DataGuard : Task [ %s ] status [%s Skip] , raid is busy."
            ;;
		517)
			echo "Folder Acl Backup : Raid[ %s ] acl %s stop."
			;;
		518)
			echo "Folder Acl Backup : Root folder acl backup/restore is processing."
			;;
		519)
			echo "Folder Acl Backup : Raid[ %s ] acl %s finish, but some folder [%s] have error."
			;;
		520)
			echo "IPv4 of dhcp Server [%s] disable, because [%s] disable."
			;;
		521)
			echo "IPv4 of dhcp Server [%s] disable, because connection type of [%s] is auto."
			;;
		522)
			echo "IPv6 of dhcp Server [%s] disable, because [%s] disable."
			;;
		523)
			echo "IPv6 of dhcp Server [%s] disable, because connection type of [%s] is auto."
			;;
		524)
			echo "IPv4 of dhcp Server [%s] disable, [%s] is heartbeat."
			;;
		525)
			echo "IPv6 of dhcp Server [%s] disable, [%s] is heartbeat."
			;;
		526)
			echo "IPv4 of dhcp Server [%s] disable, [%s] is linking aggreation."
			;;
		527)
			echo "IPv6 of dhcp Server [%s] disable, [%s] is linking aggreation."
			;;
		528)
			echo "[%s] does not get ip, and default ip is used by other interface ,so setting [0.0.0.0]."
			;;
		529)
			echo "Link%s delete, because some interfaces do not exist."
			;;
		530)
			echo "Link%s delete, because [%s] is heartbeat."
			;;
		531)
			echo "[%s] does not get ipv6, and default ip is used by other interface ,so does not set."
			;;
		532)
			echo "Modify default gw as [None], because [%s] is heartbeat."
			;;
		533)
			echo "Modify default gw as [None], because interface of default gw does exist."
			;;
		534)
			echo "Default gateway has cheanged [%s], because ha enable."
			;;
		535)
			echo "NAS Stacking Target name [ %s ] of iSCSI Target - [ %s %s ] used over %s%%."
			;;
		536)
			echo "IPv4 of dhcp Server [%s] disable, [%s] is virtual interface."
			;;
		537)
			echo "IPv4 of dhcp Server [%s] disable, [%s] is virtual interface."
			;;
		538)
			echo "Link%s becomes Link%s."
                        ;;
		539)
			echo "According to SMART, the %s of Disk %s has reached %s. Please check the status of this disk. %s"
			;;
		540)
			echo "Critical error is detected on Disk %s. Please check the health status of this disk. %s"
			;;
		###############
	        # NO. 555 is for mail monitor to send message
                ###############
                555)
                        echo "%s"
                        ;;
###########################################################
#	Error
###########################################################

		600)
			echo "Error : Your folder [ %s ] is not exist, sytem will create this folder!"
			;;
		601)
			echo "Power supply failed"
			;;
		602)
			echo "Power supply %s failed"
			;;
		603)
			echo ""
			;;
		604)
			echo ""
			;;
		605)
			echo ""
			;;
		606)
			echo "[%s Fail] Umount other volume fail ... "
			;;
		607)
			echo "[%s Fail] LVM-%s stop fail ..."
			;;
		608)
			echo "[%s Fail] Swap Disk can't Stop!"
			;;
		609)
			echo "[%s Fail] RAID Disk [ %s ] can't Stop!"
			;;
		610)
			echo "Upgrade Firmware Fail M[1]..."
			;;
		611)
			echo "Upgrade Firmware Fail M[2]..."
			;;
		612)
			echo "Upgrade Firmware Fail M[3]..."
			;;
		613)
			echo "Upgrade Firmware Fail M[6]..."
			;;
		614)
			echo "Upgrade Firmware Fail C[1]..."
			;;
		615)
			echo "Upgrade Firmware Fail C[2]..."
			;;
		616)
			echo "Upgrade Firmware Fail C[3]..."
			;;
		617)
			echo "Upgrade Firmware Fail C[6]..."
			;;
		618)
			echo "Upgrade Firmware Fail C[5]..."
			;;
		619)
			echo "Upgrade Firmware Fail W[51]..."
			;;
		620)
			echo "[Batch Fail] Data duplicate!"
			;;
		621)
			echo "[Batch Fail] Data format error!"
			;;
		622)
			echo "[Batch Fail] User Name duplicate!"
			;;
		623)
			echo "[Batch Fail] User Name Empty!"
			;;
		624)
			echo "[Batch Fail] User Name Format Error!"
			;;
		625)
			echo "[Batch Fail] Password only support A~Z a~z 0~9"
			;;
		626)
			echo "[Batch Fail] Group Name format error!"
			;;
		627)
			echo "[Batch Fail] At most 300 local users are allowed!"
			;;
		628)
			echo "[DHCP Failed] DHCP can't get ip address, so set to default ip [ 192.168.1.100 ]"
			;;
		629)
			echo "[%s Fail] Umount data volume fail ... "
			;;
		630)
			echo "[%s Fail] Umount system volume fail ... "
			;;
		631)
			echo "[%s Fail] LVM-%s resize fail ... "
			;;
		632)
			echo "[Expansion Fail] Resize file system fail ... "
			;;
		633)
			echo "[%s Fail] Mount data volume fail ... "
			;;
		634)
			echo "[%s Fail] Mount system volume fail ... "
			;;
		635)
			echo "[Migration Fail] Transfer RAID fail ..."
			;;
		636)
			echo "[%s Fail] LVM-%s start fail ..."
			;;
		637)
			echo "Can't mount %s, and you can do filesystem check try to recovery your data."
			;;
		638)
			echo "[Snapshot] Create snapshot failed! [ %s ]"
			;;
		639)
			echo "[Snapshot] Create clone failed! [ %s ]"
			;;
		640)
			echo "[Snapshot] Unmount snapshot failed! [ %s ]"
			;;
		641)
			echo "[Snapshot] Set mount point failed! [ %s ]"
			;;
		642)
			echo "[Snapshot] Mount snapshot failed! [ %s ]"
			;;
		643)
			echo "[Snapshot] Unknow fail is happened!"
			;;
		644)
			echo "[Snapshot] Destory clone failed! [ %s ]"
			;;
		645)
			echo "[Snapshot] Destory snapshot failed! [ %s ]"
			;;
		646)
			echo " %s temperature is abnormal! The system is shutting down to prevent overheat."
			;;
		647)
			echo "[ %s ] is system user, you can't batch it."
			;;
		648)
			echo "[ %s ] is system group, you can't batch it."
			;;
		649)
			echo "Bad block(HD Tray No: %s) scanning has completed ,the HD has bad blocks found."
			;;
		650)
			echo "SMART(HD Tray No: %s) testing has completed, the HD has error found."
			;;
		651)
			echo "Can't start encrypt raid[ %s ], you have to plug correct usb key before you can use it."
			;;
		651)
			echo "Can't start encrypt raid[ %s ], you have to plug correct usb key before you can use it."
			;;
		652)
			echo "Create system dom backup Fail."
			;;
		653)
			echo "Upgrade Firmware Fail C[7]..."
			;;
		654)
			echo "TFTP starts fail, folder is not exist."
			;;
		655)
			echo "TFTP starts fail, port is used by other service."
			;;
		656)
			echo "TFTP starts fail."
			;;
		657)
			echo "TFTP starts fail, do not get any ip"
			;;
		658)
			echo "Fail to add local user [ %s ], user name is duplicate."
			;;
		659)
			echo "Module[%s]: Install Fail."
			;;
		660)
			echo "Module[%s]: Upgrade Fail."
			;;
		661)
			echo "Module[%s]: Enable Fail."
			;;
		662)
			echo "Module[%s]: Disable Fail."
			;;
		663)
			echo "Module[%s]: Uninstall Fail."
			;;
		664)
			echo "Module database does not exist, then create it."
			;;
		665)
			echo "DataBase[%s] Recovery failed."
			;;
		666)
			echo "Upgrade Firmware Fail C[8]..."
			;;
		667)
			echo "DataGuard : Task [ %s ] status [%s Error], Target server connection failed."
			;;
		668)
			echo "DataGuard : Task [ %s ] status [%s Error], Source folder [ %s ] do not exist."
			;;
		669)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Target folder is read only."
			;;
		670)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Out of space."
			;;
		671)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Transfer file error."
			;;
		672)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Transfer file timeout."
			;;
		673)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Unknown error. Please check the log file."
			;;
		674)
			echo "DataGuard : Task [ %s ] status [%s Error], This task has %s errors."
			;;
		675)
			echo "DataGuard : Task [ %s ] status [%s Error], Some files or folders rename."
			;;
		676)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Some files are deleted, when proccess."
			;;
		677)
			echo "DataGuard : Task [ %s ] status [%s Error], Target folder [ %s ] does not exist."
			;;
		678)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Target Server Permission deny."
			;;
		679)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, Max connections of target are reached."
			;;
		680)
			echo "DataGuard : Task [ %s ] status [%s Error]%s, User authentication failed."
			;;
		681)
			echo "NTP server connected fail."
			;;
		682)
			echo "DataGuard : Task [ %s ] status [%s Error], Encryption connection error."
			;;
		683)
			echo "DataGuard : Task [ %s ] status [%s Error], Target Server Encryption connection failed or key is not correct,press Restore Default Key."
			;;
		684)
			echo "Folder Acl Backup : Raid[ %s ] status is not healthy or degrade."
			;;
		685)
			echo "Folder Acl Backup : No this Raid%s, %s fail."
			;;
		686)
			echo "Folder Acl Backup : Raid[ %s ] %s fail, because file system(zfs) does not match."
			;;
		687)
			echo "Folder Acl Backup :%s%s fail, because restore information file loses."
			;;
		688)
			echo "Folder Acl Backup : Raid[ %s ] %s fail, because restore bin file loses."
			;;
		689)
			echo "Battery failed to charge, please replace your battery!"
			;;
		694)
			echo "LDAP client fail to enable."
			;;
		695)
			echo "SSH starts fail, port is used by other service."
			;;
		696)
			echo "SSH starts fail."
			;;
		697)
			echo "Can't contact LDAP server"
			;;
		698)
			echo "Cannot erase disc, aborting."
			;;
		699)
			echo "mount media is incorrent."
			;;
		800)
			echo "Could not write Lead in."
			;;
		801)
			echo "md5 file checksum error."
			;;
		802)
			echo "burning write failed."
			;;
		803)
			echo "No Volume Expansion member raid to build iSCSI Target."
			;;
		804)
			echo "The Volume Expansion management's iqn is different with the database."
			;;
		805)
			echo "There was not Volume Expansion management's iqn to set iSCSI ACL."
			;;
		806)
			echo "The Volume Expansion member [ %s ] from %s has been connected."
			;;
		807)
			echo "The Volume Expansion member [ %s ] from %s has been disconnected."
			;;
		808)
			echo "The raid [ %s ] of Volume Expansion management is started."
			;;
		809)
			echo "The raid [ %s ] of Volume Expansion management is stopped."
			;;
		810)
			echo "The iSCSI device [%s] connection failed."
			;;
		811)
			echo "DataGuard : Task [ %s ] status [%s Error],backup bin file is error format."
			;;
		812)
			echo "DataGuard : Task [ %s ] status [%s Error],iscsi folder [ %s ] backup or restore is processing."
			;;
		813)
			echo "The raid [ %s ] of Volume Expansion member has been %s."
			;;
		814)
			echo "The connection between Volume Expansion management(%s) and member(%s) has been disconnected."
			;;
                815)
                        echo "The network device %s not found"
                        ;;
                816)
                        echo "Serial devices %s not found"
                        ;;
                817)
                        echo "Backup DOM not found"
                        ;;
                818)
                        echo "Need 10G nic to support Volume Expansion member. Please check the 10G nic and reboot system."
                        ;;
		819)
			echo "Mount %s failed, and now do file system check."
			;;
		820)
			echo "File system check failed."
			;;
		821)
			echo "File system checking ..."
			;;
###########################################################
#	Test Connection
###########################################################			
		700)
			echo "Target server connection failed."
			;;
		701)
			echo "User authentication failed."
			;;
		702)
			echo "Target Server Connection timeout."
			;;
		703)
			echo "Target folder [ %s ] is not exist."
			;;
		704)
			echo "Permission deny."
			;;
		705)
			echo "Test create target directory error."
			;;
		706)
			echo "Test transfer file error."
			;;
		707)
			echo "Connection test on %s success."
			;;
		708)
			echo "Out of space."
			;;
		709)
			echo "Max connections of target are reached."
			;;
		710)
			echo "Unknown failed."
			;;
		711)
			echo "Encryption connection failed."
			;;
		712)
		        echo "Encryption Connection refused."
		        ;;
		713)
		        echo "Connection closed by remote host."
		        ;;
		714)
            echo "The difference between the request time and the current time is too large."
            ;;
		*)
			echo "No Such Event ID"
			;;
      esac
}

