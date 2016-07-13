#!/bin/sh
#==================================================
#        FILE:  folder acl backup/restore
#       USAGE:  backup mdnum
#               restore
#               get_all_raid
#               get_match_folder mdnum rec
#               get_result
#               get_upload_path
#               get_download_path
#               get_restore_file_path
#               set_folder_list filename
#               stop
#               cancel
#               check_lock
#               get_raid_status act mdnum
#               get_lock_info
# DESCRIPTION:  backup/restore folder acl
#       NOTES:  none
#      AUTHOR:  enian
#     VERSION:  1.0.0
#     CREATED:  2011/6/30
#    REVISION:  2011/6/30
#==================================================

#==================================================
#   Include File
#==================================================
. /img/bin/function/libshare

#==================================================
#  Variable Defined
#==================================================
Act=$1                                                 #action
TmpPath="/var/tmp/acl_backup"                          #acl backup/restore tmp folder
LockFile="${TmpPath}/lock"                             #acl backup/restore lock file
InfoFolder="info"                                      #tar folder name
InfoPath="${TmpPath}/${InfoFolder}"                    #info folder path
AclPath="${InfoPath}/Acl"                              #acl file store path
RestoreName="Restore"                                  #tmp restore folder name
RestorePath="${TmpPath}/${RestoreName}"                #restore folder path
RestoreAcl="${RestorePath}/${InfoFolder}/Acl"          #restore acl folder path
RestoreFs="${RestorePath}/${InfoFolder}/.filesystem_"  #restore system file path
RestoreBin="${RestorePath}/folder_acl.bin"             #restore bin file path
RestoreFolderList="${RestorePath}/folder_list"         #restore folder list path
AclFSFile="${InfoPath}/.filesystem_"                   #backup acl system file path
#FolderList="${TmpPath}/folder_list" 
ResultFile="${TmpPath}/acl_result"                     #backup/restore result file path
RestoreConf="${RestorePath}/restore_conf"              #restore conf file path
BinFile="${TmpPath}/folder_acl.bin"                    #backup bin file path
TarFile="${TmpPath}/folder_acl.tar.gz"                 #backup tar file path
Event="/img/bin/logevent/event"                        #event command
TmpRaidFile="${TmpPath}/raid_name"                     #record raid_name for stop
TmpActFile="${TmpPath}/act"                            #record action for stop
STmpShareList="${TmpPath}/sshare_list"                 #record temp backup share list
TTmpShareList="${TmpPath}/tshare_list"                 #record temp now raid share list
TmpErrorList="${TmpPath}/error_list"                   #record restore fail folder
AclEnc="conf_nas"                                      #encrypt key
ISOCmd="/img/bin/rc/rc.isomount"                       #isomount command

#==================================================
#  Function Defined
#==================================================

#################################################
#         NAME:  create_folder
#  DESCRIPTION:  if folder does not exist ,
#                will create folder
#      PARAM 1:  folder path
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################

create_folder(){
    local fPath="$1"

    if [ ! -d "${fPath}" ];then
        mkdir -p "${fPath}"
    fi
}


#################################################
#         NAME:  check_lock
#  DESCRIPTION:  check process is working
#      PARAM 1:  none
#       RETURN:  0/1 (no/yes)
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
check_lock(){
    local fLockVal=0 

    if [ -f "${LockFile}" ];then
        fLockVal=1        
    fi
    
    echo "${fLockVal}"
}

#################################################
#         NAME:  set_result
#  DESCRIPTION:  set backup/restore result to file
#                and send log
#      PARAM 1:  fAct:action (backup/restore)
#      PARAM 2:  fRet:error code 
#      PARAM 3:  fEvent:does send log event (0/1)(no/yes)
#      PARAM 4:  fPara1:Raid Name
#      PARAM 5:  fPara3:wording parameter
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
set_result(){
    local fAct=$1
    local fRet=$2
    local fEvent=$3
    local fPara1=$4         ## Raid Name 
    local fPara2="${fAct}"
    local fPara3=$5         ## wording parameter 
    local fRet_key          ## wording key
    local fEvent_id         ## Event id
    local fLevel            ## result level (info/warning/error)

    case "$fRet"
    in
        0) ##Finish
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="466"
            else
                fEvent_id="464"
            fi

            fRet_key="acl_${fAct}_finish"
            fLevel="info"
            ;; 
        1) ##Start
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="465"
            else
                fEvent_id="463"
            fi
            
            fRet_key="acl_${fAct}_start"
            fLevel="info" 
            ;;
        2)  ##Stop
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="517"
            else
                fEvent_id="517"
            fi
            
            fRet_key="acl_${fAct}_cancel"
            fLevel="warning"
            ;;
        3)  ##process duplicate
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="518"
            else
                fEvent_id="518"
            fi
            
            fRet_key="acl_duplicate"
            fLevel="warning"            
            ;;
        4)  ##Raid Error
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="689"
            else
                fEvent_id="684"
            fi
            
            fRet_key="acl_${fAct}_raid_error"
            fLevel="error"
            ;;
        5)  ## zfs fs not match
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="691"
            else
                fEvent_id="686"
            fi
            
            fRet_key="acl_${fAct}_not_match"
            fLevel="error"
            ;;
        7)  ## restore error no bin
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="693"
            else
                fEvent_id="688"
            fi
            
            fRet_key="acl_restore_no_bin"
            fLevel="error"
            ;;
        8)  ## restore error no raid
            ;;
        9)
            if [ "${Lraid_NasKey}" == "x86_32" ];then
                fEvent_id="519"
            else
                fEvent_id="519"
            fi
            
            fRet_key="acl_restore_missing"
            fLevel="warning"
            ;; 
    esac
    
    if [ "${fPara1}" == "" ] && [ "${fRet}" != "3" ];then
        if [ "${Lraid_NasKey}" == "x86_32" ];then
            fEvent_id="690"
        else
            fEvent_id="685"
        fi
        fLevel="error"
        if [ "${fRet}" == "8" ];then
            fPara1=" "
            fPara2="get folder info"
        fi
        fRet_key="acl_no_raid"
    fi
    
    if [ "${fRet}" == "6" ];then
        fPara1=""
                                                                           
        if [ "${Lraid_NasKey}" == "x86_32" ];then
            fEvent_id="692"
        else
            fEvent_id="687"
        fi
        fRet_key="acl_restore_no_conf"
        fLevel="error"
    fi 

    if [ "${fEvent}" == "1" ];then
        ${Event} 997 ${fEvent_id} ${fLevel} email "${fPara1}" "${fPara2}" "${fPara3}"
    fi

    echo "${fRet}|${fAct}|${fLevel}|${fRet_key}|${fPara1}|${fPara3}" > "${ResultFile}"
    
    if [ "${fRet}" != "1" ] && [ "${fRet}" != "3" ];then
        rm -rf ${LockFile}
    fi
}

#################################################
#         NAME:  del_restore_file
#  DESCRIPTION:  delete tmp restore file
#      PARAM 1:  none
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
del_restore_file(){
    local fTmpFile=`ls ${RestorePath} | grep -v "folder_acl.bin"`  
    cd "${RestorePath}"
    if [ "${fTmpFile}" != "" ];then
        rm -rf ${fTmpFile}
    fi 
    cd - > /dev/null
}

#################################################
#         NAME:  del_some_file
#  DESCRIPTION:  delete tmp backup file
#      PARAM 1:  none
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
del_some_file(){
   rm -rf ${InfoPath}
#   rm -rf ${FolderList}
   rm -rf ${ResultFile}
   rm -rf ${BinFile}
   rm -rf ${TarFile}
}

#################################################
#         NAME:  del_all_file
#  DESCRIPTION:  delete all tmp file unless rstore folder
#      PARAM 1:  none
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
del_all_file(){
    local fTmpFile=`ls ${TmpPath} | grep -v "${RestoreName}"`
    cd "${TmpPath}"
    if [ "${fTmpFile}" != "" ];then
        rm -rf ${fTmpFile}
    fi 
    cd - > /dev/null
}

#################################################
#         NAME:  stop_acl_act
#  DESCRIPTION:  stop acl backup/restore
#      PARAM 1:  none
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
stop_acl_act(){
    local fActPs
    local fPid
    local fAct
    local fRaidName

    if [ `check_lock` == "1" ];then
        fPid=`cat "${LockFile}" | awk -F'=' '/pid/{print $2}'`
        kill -9 $fPid
    
        fRaidName=`cat ${TmpRaidFile}`
        fAct=`cat ${TmpActFile}`
    
        del_some_file
        set_result "${fAct}" "2" "1" "${fRaidName}" 
    fi
}

#################################################
#         NAME:  set_acl_info
#  DESCRIPTION:  set acl backup/restore info
#      PARAM 1:  fRaidName: raid name
#      PARAM 2:  fact: action (backup/restore)
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
set_acl_info(){
    local fRaidName="$1"
    local fAct=$2

    echo "${fRaidName}" > ${TmpRaidFile}
    echo "${fAct}" > ${TmpActFile}
}

#################################################
#         NAME:  create_lock_file
#  DESCRIPTION:  create lock file and record 
#                this pid and md number
#      PARAM 1:  fMdNum: md number
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
create_lock_file(){
    local fMdNum="$1"
    echo "md=${fMdNum}" > ${LockFile}
    echo "pid=$$" >> ${LockFile}
}

#################################################
#         NAME:  backup_acl
#  DESCRIPTION:  backup foldr acl
#      PARAM 1:  fMdNum: md number
#       RETURN:  result
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
backup_acl(){
    local fMdNum="$1"
    local fRet="0"          ## error code
    local fFolderList       ## all folder list
    local fShare            ## share name
    local fRaidName         ## raid name
    local fRaidStatus       ## raid status
    local fAct="backup"     ## action
    local fUUID             ## raid uuid
    local fMaster           ## raid is master raid
    local fRaidId=`Lraid_md_to_raidid "${fMdNum}"`  ## raid id
    local fFs               ## raid file system
    local fGuestVal         ## share guest value
    local fGuestName        ## share guest field name

    if [ `check_lock` == "0" ];then
        del_all_file
        create_lock_file "${fMdNum}"
        fRaidStatus=`Lraid_get_raid_status "${fMdNum}"`
        fRaidName=`Lraid_get_raid_info "${fMdNum}" "raid_name"`
        set_acl_info "${fRaidName}" "${fAct}"
        fRaidStatus=`echo "$fRaidStatus" | awk  '/Healthy/||/Degraded/||/Recovering/||/Rebuild/||/Build/{print $0}'`
        if [ "${fRaidStatus}" != "" ];then
            set_result "${fAct}" "1" "1" "${fRaidName}"
            if [ "${fRaidName}" == "" ];then
                exit
            fi
            fFolderList=`Lshare_get_raid_share ${fMdNum}`
            create_folder "${AclPath}"
            fFs=`Lraid_get_raid_info "${fMdNum}" "filesystem"`
            
            echo "/raid${fRaidId}/data"
            cd /raid${fRaidId}/data 
            echo -e "${fFolderList}" | \
            while read fShare
            do
                if [ "${fShare}" != "" ];then
                    getfacl --numeric "${fShare}" > "${AclPath}/${fShare}"
                    if [ "${Lraid_NasKey}" == "x86_32" ];then
                         fGuestName="guest_only"
                    else
                         fGuestName="guest only"
                    fi
                    fGuestVal=`Lshare_get_share_attr "${fMdNum}" "${fShare}" "${fGuestName}"`
                    echo "fGuestVal=${fGuestVal}" > "${AclPath}/${fShare}_guest"
                fi
            done
            cd -

            if [ "${fFs}" == "zfs" ];then
                cp /raid${fRaidId}/sys/raid.db ${AclPath}
            fi
            
            fMaster=`Lraid_check_ismasterraid "${fMdNum}"` 
            fUUID=`Lraid_get_raid_uuid "${fMdNum}"`
            echo "local fMaster=${fMaster}" > ${AclFSFile}
            echo "local fUuid=${fUUID}" >> ${AclFSFile}
            echo "local fOrgFs=${fFs}" >> ${AclFSFile}
            cd ${TmpPath}
            tar zcvf ${TarFile} ${InfoFolder}
            des -k ${AclEnc} -E ${TarFile} ${BinFile}
            rm ${TarFile} 
            cd -
        else
            del_some_file
            fRet="4"    
        fi
    else
        fRet="3"
    fi
    sleep 1
    set_result "${fAct}" "${fRet}" "1" "${fRaidName}"

    if [ "${fRet}"  == "0" ];then
        echo "$fRet"
    else
        get_result
    fi

}

#################################################
#         NAME:  get_zfs_acl_user
#  DESCRIPTION:  get zfs folder acl user name
#      PARAM 1:  fUserIdData: user id list
#       RETURN:  User name list
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_zfs_acl_user(){
    local fUserIdData="$1"
    local fUserIdList       ## tmp user id list
    local fUserId           ## one user id
    local fNUserList=""     ## new user name list
    local fNUserId          ## after parse user id
    local fNUser            ## one new user name
    
    fUserIdList=`echo "${fUserIdData}" | sed "s/,/ /g"`
    
    for fUserId in ${fUserIdList}
    do
        if [ "${fUserId}" != "" ];then
            fNUserId=`echo "${fUserId}" | awk '{print substr($0,4)}'` 
            fNUser=`getent passwd | awk -F':' '/:'${fNUserId}':/{print $1}'`

            if [ "${fNUserList}" == "" ];then
                fNUserList="${fNUser}"
            else
                fNUserList="${fNUserList},${fNUser}"
            fi
        fi
    done

    echo ${fNUserList}
}


#################################################
#         NAME:  check_zfs_fs
#  DESCRIPTION:  check restore fs is match for zfs
#      PARAM 1:  fTFs: Target file system
#      PARAM 2:  fOrgFs: Orginal file system
#       RETURN:  0/1 (match/no match)
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
check_zfs_fs(){
    local fTFs="$1"
    local fOrgFs="$2"
    local fRet=0

    if [ "${fTFs}" == "zfs" ] || [ "${fOrgFs}" == "zfs" ];then
      if [ "${fTFs}" != "${fOrgFs}" ];then
         fRet=1
      fi
    fi

    echo "${fRet}"
}

#################################################
#         NAME:  restore_acl
#  DESCRIPTION:  restore acl
#      PARAM 1:  none
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
restore_acl(){
    local fAct="restore"                    #action
    local fShare                            #share name
    local fZfsAclId[1]="valid_id"           #zfs user id field array
    local fZfsAclId[2]="invalid_id"         #zfs user id field array
    local fZfsAclId[3]="read_list_id"       #zfs user id field array
    local fZfsAclId[4]="write_list_id"      #zfs user id field array
    local fZfsAclUser[1]="valid_users"      #zfs user name field array
    local fZfsAclUser[2]="invalid_users"    #zfs user name field array
    local fZfsAclUser[3]="read_list"        #zfs user name field array
    local fZfsAclUser[4]="write_list"       #zfs user name field array
    local fZfsAcl                           #zfs acl data
    local fZfsAclCount                      #zfs need field count
    local fTmpField=""                      #zfs tmp field
    local fAclVal                           #file acl value
    local fZfsNUser                         #zfs new user name
    local fRet="0"                          #error cod
    local fFs                               #file system
    local fErrorFolder=""                   #error folder list in restore
    local fGuestVal                         #org guest value

    if [ `check_lock` == "0" ];then
        if [ ! -f "${RestoreConf}" ] || [ ! -f "${RestoreFs}" ] || [ ! -f "${RestoreFolderList}" ];then
            fRet="6"
        else 
            . ${RestoreConf}
            . ${RestoreFs}
            local fRaidId=`Lraid_md_to_raidid "${fMdNum}"`
            create_lock_file "${fMdNum}" 
            fRaidStatus=`Lraid_get_raid_status "${fMdNum}"`
            fRaidName=`Lraid_get_raid_info "${fMdNum}" "raid_name"`
            set_acl_info "${fRaidName}" "${fAct}"

            if [ "${fRaidStatus}" == "Healthy" ] || [ "${fRaidStatus}" == "Degraded" ];then
                set_result "${fAct}" "1" "1" "${fRaidName}"
                if [ "${fRaidName}" == "" ];then
                    exit
                fi
            
                fFs=`Lraid_get_raid_info "${fMdNum}" "filesystem"`
                fRet=`check_zfs_fs "${fFs}" "${fOrgFs}"`

                if [ "${fRet}" == "0" ];then
                    if [ "${fFs}" != "zfs" ];then
                        cd /raid${fRaidId}/data
                        cat "${RestoreFolderList}" | \
                        while read fShare
                        do
                            if [ "${fShare}" != "" ];then
                                ${ISOCmd} "modify" "$fShare" "${fRaidId}" "${fShare}" "acl_umount" "${fRec}"
                                if [ "${fRec}" == "1" ];then
                                    fRecCmd="-R"
                                else
                                    fRecCmd=""
                                fi
                                if [ "${fShare}" == "USBHDD" ] || [ "${fShare}" == "usbhdd" ];then
                                    fRecCmd=""
                                fi
                                setfacl ${fRecCmd} --remove-all "${fShare}"
                                setfacl ${fRecCmd} --modify-file="${RestoreAcl}/${fShare}" "${fShare}"
                                if [ "$?" != "0" ];then
                                     echo "${fShare}" >> "${TmpErrorList}"
                                fi

                                if [ "${Lraid_NasKey}" == "x86_32" ];then
                                     fGuestName="guest_only"
                                else
                                     fGuestName="guest only"
                                fi
                                
                                fGuestVal=`cat "${RestoreAcl}/${fShare}_guest" | awk -F'=' '/^fGuestVal=/{print $2}'`
                                Lshare_set_share_attr "${fMdNum}" "${fShare}" "${fGuestName}" "${fGuestVal}"

                            fi
                            ${ISOCmd} "modify" "$fShare" "${fRaidId}" "${fShare}" "acl_mount" "${fRec}"
                        done
                    else
                        fZfsAclCount=${#fZfsAclId[@]}
                        for ((i=1;i<=$fZfsAclCount;i++))
                        do
                            if [ "$i" == "1" ];then
                                fTmpField="${fZfsAclId[$i]}"
                            else
                                fTmpField="${fTmpField},${fZfsAclId[$i]}"
                            fi
                        done
               
                        cat "${RestoreFolderList}" | \
                        while read fShare
                        do
                            if [ "${fShare}" != "" ];then
                                if [ -e "/raid${fRaidId}/data/${fShare}" ];then
                                    fZfsAcl=`${Lraid_Sqlite} ${RestoreAcl}/raid.db "select ${fTmpField} from folder where share='${fShare}'"`
                                    for ((i=1;i<=$fZfsAclCount;i++))
                                    do
                                        fAclVal=`echo "${fZfsAcl}" | awk -F'|' '{print $'$i'}'`
                                        fZfsNUser=`get_zfs_acl_user "${fAclVal}"` 
                                        ${Lraid_Sqlite} /raid${fRaidId}/sys/raid.db "update folder set ${fZfsAclId[$i]}='${fAclVal}',${fZfsAclUser[$i]}='${fZfsNUser}' where share='${fShare}'"
                                    done
                                else
                                    echo "${fShare}" >> "${TmpErrorList}"
                                fi
                                
                                if [ "${Lraid_NasKey}" == "x86_32" ];then
                                     fGuestName="guest_only"
                                else
                                     fGuestName="guest only"
                                fi
                                
                                fGuestVal=`cat "${RestoreAcl}/${fShare}_guest" | awk -F'=' '/^fGuestVal=/{print $2}'`
                                Lshare_set_share_attr "${fMdNum}" "${fShare}" "${fGuestName}" "${fGuestVal}"
                            fi
                        done
                    fi

                    fErrorFolder=`cat "${TmpErrorList}" | sed -e :x -e '$!N;s/\n/,/;tx' | awk '{if(substr($0,length($0))==",")print substr($0,0,length($0)-1); else print $0}'`
                    if [ "${fErrorFolder}" != "" ];then
                        fRet="9"
                    fi
                    rm "${TmpErrorList}"
                else
                    del_restore_file
                    fRet="5"
                fi
            else    
                del_restore_file
                fRet="4"
            fi
        fi
    else
       fRet="3" 
    fi

    rm ${RestoreFolderList}
    sleep 1
    set_result "${fAct}" "${fRet}" "1" "${fRaidName}" "${fErrorFolder}"
}

#################################################
#         NAME:  get_all_raid
#  DESCRIPTION:  get all raid info mdnum/filesystem/raid name
#      PARAM 1:  none
#       RETURN:  return all mdnum/raid name/filesystem
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_all_raid(){
    local fRaidIdList=`Lraid_get_raidmd_list`
    local fRaidInfo=""
    local fRaidmd
    
    for fRaidmd in ${fRaidIdList}
    do  
        if [ "${fRaidmd}" != "" ];then
            fRaidName=`Lraid_get_raid_info "${fRaidmd}" "raid_name"`
            fRaidFS=`Lraid_get_raid_info "${fRaidmd}" "filesystem"`
        if [ "${fRaidInfo}" == "" ];then
          fRaidInfo="${fRaidmd},${fRaidName},${fRaidFS}"
        else
          fRaidInfo="${fRaidInfo}|${fRaidmd},${fRaidName},${fRaidFS}"
        fi
    fi
    done
    echo "${fRaidInfo}"
}

#################################################
#         NAME:  get_result
#  DESCRIPTION:  get backup/restore result
#      PARAM 1:  none
#       RETURN:  return result
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_result(){
    cat ${ResultFile}
}

#################################################
#         NAME:  set_restore_conf
#  DESCRIPTION:  set raid info for restore
#      PARAM 1:  fRaidmd: md number
#      PARAM 1:  fRec: Recursive value
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
set_restore_conf(){
    local fRaidmd="$1"
    local fRec="$2"
    echo "local fMdNum=${fRaidmd}" > ${RestoreConf}
    echo "local fRec=${fRec}" >> ${RestoreConf}
}

#################################################
#         NAME:  get_match_folder
#  DESCRIPTION:  get raid / restore file match folder result
#      PARAM 1:  fRaidmd: md number
#      PARAM 1:  fRec: Recursive value
#       RETURN:  folder list / error result
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_match_folder(){
    local fRaidmd="$1"
    local fRec="$2"
    local fTUuid
    local fTFs
    local fRet
    local fRaidName
    local fErr="0"
    local fErrCode="0"

    if [ `check_lock` == "0" ];then
        del_restore_file > /dev/null 2>&1
        fTFs=`Lraid_get_raid_info "${fRaidmd}" "filesystem"`
        fRaidName=`Lraid_get_raid_info "${fRaidmd}" "raid_name"`
        if [ "${fTFs}" != "" ];then
            if [ -f "${RestoreBin}" ];then
                set_restore_conf "$fRaidmd" "$fRec"
                cd ${RestorePath}
                des -k ${AclEnc} -D ${RestoreBin} | tar zxvf - > /dev/null 2>&1
                cd - > /dev/null 2>&1
                if [ -f "${RestoreFs}" ];then
                    . ${RestoreFs}
                    fRet=`check_zfs_fs "${fTFs}" "${fOrgFs}"`
 
                    if [ "${fRet}" == "0" ];then
                        fTUuid=`Lraid_get_raid_uuid "${fRaidmd}"`
                        ls "${RestoreAcl}" | sort -u > ${STmpShareList}
                        Lshare_get_raid_share ${fRaidmd} | sort -u > ${TTmpShareList}
                        echo "0"
                        if [ "${fTUuid}" == "${fUuid}" ];then
                            echo ""
                        else
                            echo "acl_uuid_not_match"
                        fi
                        diff -y --left-colum ${STmpShareList} ${TTmpShareList} | awk '/ \(/ {print $1}'
                        rm ${STmpShareList} ${TTmpShareList}
                        exit
                    else
                        fErr="1"
                        fErrCode="5"
                    fi
                else
                    fErr="1"
                    fErrCode="6"
                fi
            else
                fErr="1"
                fErrCode="7"
            fi
        else
            fErr="1"
            fErrCode="8"
        fi
    else
        fErr="1"
        fErrCode="3"
    fi
    echo "${fErr}"
    set_result "restore" "${fErrCode}" "0" "${fRaidName}" 
    if [ "${fErr}" == "1" ];then
        get_result
    fi 
}

#################################################
#         NAME:  get_download_path
#  DESCRIPTION:  get download file path
#      PARAM 1:  none
#       RETURN:  download path
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_download_path(){
    echo "${BinFile}"
}

#################################################
#         NAME:  get_upload_path
#  DESCRIPTION:  get upload file path
#      PARAM 1:  none
#       RETURN:  upload path
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_upload_path(){
    echo "${RestoreBin}"
}

#################################################
#         NAME:  acl_cancel
#  DESCRIPTION:  cancel
#      PARAM 1:  none
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
acl_cancel(){
    del_all_file 
}

#################################################
#         NAME:  set_folder_list
#  DESCRIPTION:  set restore folder list
#      PARAM 1:  fFolderName: folder name
#       RETURN:  none
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
set_folder_list(){
    fFolderName="$1"    
    echo "${fFolderName}" >> "${RestoreFolderList}"
}

#################################################
#         NAME:  get_raid_status
#  DESCRIPTION:  get raid status
#      PARAM 1:  fAct: action (restore/backup)
#      PARAM 2:  fMdNum: md number
#       RETURN:  return raid result
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_raid_status(){
    fAct="$1"
    fMdNum="$2"
    fRet="0"
    if [ "$fMdNum" == "" ];then
        if [ -f "${RestoreConf}" ];then   
            . ${RestoreConf}
        fi
    fi
    if [ `check_lock` == "0" ];then
        fRaidStatus=`Lraid_get_raid_status "${fMdNum}"`
        fRaidName=`Lraid_get_raid_info "${fMdNum}" "raid_name"`
        set_acl_info "${fRaidName}" "${fAct}"
        if [ "$fAct" == "backup" ];then
            fRaidStatus=`echo "$fRaidStatus" | awk  '/Healthy/||/Degraded/||/Recovering/||/Rebuild/||/Build/{print $0}'`
        else
            fRaidStatus=`echo "$fRaidStatus" | awk  '/Healthy/||/Degraded/{print $0}'`
        fi
        if [ "${fRaidStatus}" != "" ];then
            if [ "${fRaidName}" == "" ];then
               fRet="1" 
            fi
        else
            del_some_file
            fRet="4"    
        fi
    else
        fRet="3"
    fi

    set_result "${fAct}" "${fRet}" "0" "${fRaidName}"

    if [ "${fRet}"  == "0" ];then
        echo "$fRet"
    else
        get_result
    fi
}

#################################################
#         NAME:  get_restore_file_path
#  DESCRIPTION:  get folder list file path
#      PARAM 1:  none
#       RETURN:  return folder list file path
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_restore_file_path(){
    echo "${RestoreFolderList}"
}

#################################################
#         NAME:  get_lock_md_info
#  DESCRIPTION:  get lock md number
#      PARAM 1:  none
#       RETURN:  return md number
#       AUTHOR:  enian
#      CREATED:  30,06,2011
#################################################
get_lock_md_info(){
    local fMdnum
    fMdnum=`cat ${LockFile} 2> /dev/null | awk -F'=' '/^md=/{print $2}'`
    echo "${fMdnum}"
}

#==================================================
#  Main Code
#==================================================
create_folder "${RestorePath}"
case "$Act"
in
    backup)
        MdNum=$2
        backup_acl "$MdNum" 
        ;;
    restore)
        restore_acl
        ;;
    get_all_raid)
        get_all_raid
        ;;
    get_match_folder)
        MdNum=$2
        Rec=$3
        get_match_folder "$MdNum" "$Rec"
        ;;
    get_result)
        get_result
        ;;
    get_upload_path)
        get_upload_path
        ;;
    get_download_path)
        get_download_path
        ;;
    get_restore_file_path)
        get_restore_file_path
        ;;
    set_folder_list)
        set_folder_list "$2"
        ;;
    stop)
        stop_acl_act
        ;;
    cancel)
        acl_cancel
        ;;
    check_lock)
        check_lock
        ;;
    get_raid_status)
        NowAct=$2
        MdNum=$3
        get_raid_status "${NowAct}" "${MdNum}"
        ;;
    get_lock_md_info)
        get_lock_md_info
        ;;
    *)
        echo "Usage: $0 {backup mdnum|restore|get_all_raid|get_match_folder mdnum rec|get_result|get_upload_path|get_download_path|get_restore_file_path|set_folder_list filename|stop|cancel|check_lock|get_raid_status act mdnum |get_lock_md_info}"
        ;;
esac

