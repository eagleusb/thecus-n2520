#!/bin/sh

###################################
# Constant define
###################################
httpd_conf="/etc/httpd/conf/httpd_webdav.conf"
httpd_ssl_conf="/tmp/ssl_webdav.conf"
pid_file_name="http_webdav.pid"
sqlite="/usr/bin/sqlite3"
conf_db="/etc/cfg/conf.db"

## Select conf setting from DB
httpd_enabled=`${sqlite} ${conf_db} "select v from conf where k='webdav_enable'"`
httpd_port=`${sqlite} ${conf_db} "select v from conf where k='webdav_port'"`
httpd_ssl_enabled=`${sqlite} ${conf_db} "select v from conf where k='webdav_ssl_enable'"`

## Browser View contstant define
webdav_browser_view=`${sqlite} ${conf_db} "select v from conf where k='webdav_browser_view'"`
if [ "${webdav_browser_view}" == "1" ];then
    browser_option="+Indexes"
else
    browser_option="-Indexes"
fi

## Get Master RAID ID number (default value is 0)
master_raidid=`ls -l /raid | awk -F '/data' '{print $1}' | awk -F 'raid' '{print $NF}'`
[ -z "${master_raidid}" ] && master_raidid="0"
master_raidname=`${sqlite} "/raidsys/${master_raidid}/smb.db" "select v from conf where k='raid_name'"`
[ -z "${master_raidname}" ] && master_raidname="RAID"


###################################
# Function define
###################################
function parser_folder(){
  local folder_name=$1
  local folder_public=$2
  local subfolder_list=""

  ## Process current folder
  insert_folder_conf ${folder_name} ${folder_public}

  ## Find subfolder if this folder is ACL
  if [ "${folder_public}" == "no" ];then
      find "/raid/ftproot/${folder_name}/" -maxdepth 1 -mindepth 1 -type d | grep -v "/\." | \
      while read subfolder
      do
          if [ ! -z "${subfolder}" ];then
              subfolder=`echo $subfolder | awk -F '/raid/ftproot/' '{print $2}'`
              parser_folder ${subfolder} ${folder_public}
          fi
      done
  fi
}


function insert_folder_conf(){
  local folder_name=$1
  local folder_public=$2
  local msg=""

  ## folder necessary part
  msg="${msg}\nAlias \"/${folder_name}\" \"/raid/ftproot/${folder_name}\""
  msg="${msg}\n<Directory \"/raid/ftproot/${folder_name}\">"
  msg="${msg}\n  Options ${browser_option}"
  msg="${msg}\n  AllowOverride All"
  msg="${msg}\n  Order allow,deny"
  msg="${msg}\n  Allow from all"
  msg="${msg}\n</Directory>"
  msg="${msg}\n<Location /${folder_name}>"
  msg="${msg}\n  DAV On"
  msg="${msg}\n  AuthType Basic"
  msg="${msg}\n  AuthName \"${folder_name}\""
  msg="${msg}\n  AuthBasicProvider external"
  msg="${msg}\n  AuthExternal pwauth"
  msg="${msg}\n  AuthzUnixgroup on"
  msg="${msg}\n  AuthzUserAuthoritative off"

  ## Process ACL folder
  if [ "${folder_public}" == "no" ];then
      ## Get ACL user list
      write_user_list=`getfacl /raid/ftproot/${folder_name}/ | awk -F ':' '/^user:.+:rwx$/{printf("\"%s\" "),$2}'`
      write_group_list=`getfacl /raid/ftproot/${folder_name}/ | awk -F ':' '/^group:.+:rwx$/{printf("\"%s\" "),$2}'`
      read_user_list=`getfacl /raid/ftproot/${folder_name}/ | awk -F ':' '/^user:.+:r-x$/{printf("\"%s\" "),$2}'`
      read_group_list=`getfacl /raid/ftproot/${folder_name}/ | awk -F ':' '/^group:.+:r-x$/{printf("\"%s\" "),$2}'`
      ## assemble ACL : Read
      msg="${msg}\n  <Limit PROPFIND GET>"
      msg="${msg}\n    require user ${read_user_list} ${write_user_list}"
      msg="${msg}\n    require group ${read_group_list} ${write_group_list}"
      msg="${msg}\n  </Limit>"

      ## assemble ACL : Write
      msg="${msg}\n  <Limit PROPPATCH PUT DELETE MKCOL LOCK UNLOCK COPY MOVE>"
      msg="${msg}\n    require user ${write_user_list}"
      msg="${msg}\n    require group ${write_group_list}"
      msg="${msg}\n  </Limit>"
  fi

  msg="${msg}\n</Location>"
  echo -e ${msg} >> ${httpd_conf}
}

function insert_folder_conf_deny(){
  local folder_name=$1
  local folder_path=$2
  local msg=""

  [ ! -d "${folder_path}/${folder_name}" ] && return

  ## folder necessary part
  msg="${msg}\nAlias \"/${folder_name}\" \"${folder_path}/${folder_name}\""
  msg="${msg}\n<Directory \"${folder_path}/${folder_name}\">"
  msg="${msg}\n  Options ${browser_option}"
  msg="${msg}\n  AllowOverride All"
  msg="${msg}\n  Order allow,deny"
  msg="${msg}\n  Allow from all"
  msg="${msg}\n</Directory>"
  msg="${msg}\n<Location /${folder_name}>"
  msg="${msg}\n  DAV On"
  msg="${msg}\n  AuthType Basic"
  msg="${msg}\n  AuthName \"${folder_name}\""
  msg="${msg}\n  AuthBasicProvider external"
  msg="${msg}\n  AuthExternal pwauth"
  msg="${msg}\n  AuthzUnixgroup on"
  msg="${msg}\n  AuthzUserAuthoritative off"
  ## assemble ACL
  msg="${msg}\n  <Limit PROPFIND GET>"
  msg="${msg}\n    require user"
  msg="${msg}\n    require group"
  msg="${msg}\n  </Limit>"
  msg="${msg}\n</Location>"
  echo -e ${msg} >> ${httpd_conf}
}


## Delete conf file first
rm -f ${httpd_conf}

########################################
# conf contant (Part 1: common define)
########################################

msg=""
## Static part
msg="${msg}\nDocumentRoot \"/raid/data/ftproot\""
msg="${msg}\nServerRoot \"/etc/httpd\""
msg="${msg}\nDefaultType text/plain"
msg="${msg}\nUser root"
msg="${msg}\nGroup root"
msg="${msg}\nPidFile run/${pid_file_name}"
msg="${msg}\nTimeout 3600"
msg="${msg}\nKeepAlive Off"
msg="${msg}\nMaxKeepAliveRequests 100"
msg="${msg}\nKeepAliveTimeout 15"
msg="${msg}\nTypesConfig /etc/mime.types"
echo -e ${msg} > ${httpd_conf}

msg=""
## Load modules part (common)
msg="${msg}\nLoadModule mime_magic_module  modules/mod_mime_magic.so"
msg="${msg}\nLoadModule mime_module        modules/mod_mime.so      "
msg="${msg}\nLoadModule auth_basic_module  modules/mod_auth_basic.so"
msg="${msg}\nLoadModule authn_file_module  modules/mod_authn_file.so"
msg="${msg}\nLoadModule log_config_module  modules/mod_log_config.so"
msg="${msg}\nLoadModule php5_module        modules/libphp5.so       "
msg="${msg}\nLoadModule ssl_module         modules/mod_ssl.so       "
msg="${msg}\nLoadModule dir_module         modules/mod_dir.so       "
msg="${msg}\nLoadModule rewrite_module     modules/mod_rewrite.so   "
msg="${msg}\nLoadModule setenvif_module    modules/mod_setenvif.so  "
msg="${msg}\nLoadModule cgi_module         modules/mod_cgi.so       "
msg="${msg}\nLoadModule alias_module       modules/mod_alias.so     "
msg="${msg}\nLoadModule actions_module     modules/mod_actions.so   "
msg="${msg}\nLoadModule autoindex_module   modules/mod_autoindex.so "
echo -e ${msg} >> ${httpd_conf}

msg=""
## Load modules part (for DAV & auth)
msg="${msg}\nLoadModule dav_module             modules/mod_dav.so            "
msg="${msg}\nLoadModule dav_fs_module          modules/mod_dav_fs.so         "
msg="${msg}\nLoadModule dav_lock_module        modules/mod_dav_lock.so       "
msg="${msg}\nLoadModule authz_host_module      modules/mod_authz_host.so     "
msg="${msg}\nLoadModule authz_user_module      modules/mod_authz_user.so     "
msg="${msg}\nLoadModule authz_unixgroup_module modules/mod_authz_unixgroup.so"
msg="${msg}\nLoadModule authnz_external_module modules/mod_authnz_external.so"
echo -e ${msg} >> ${httpd_conf}

msg=""
## mpm part
msg="${msg}\n<IfModule mpm_prefork_module>"
msg="${msg}\n  StartServers          5"
msg="${msg}\n  MinSpareServers       5"
msg="${msg}\n  MaxSpareServers      10"
msg="${msg}\n  MaxClients          150"
msg="${msg}\n  MaxRequestsPerChild   0"
msg="${msg}\n</IfModule>"
echo -e ${msg} >> ${httpd_conf}

msg=""
## WebDAV static part
msg="${msg}\nAddExternalAuth pwauth /usr/bin/pwauth"
msg="${msg}\nSetExternalAuthMethod pwauth pipe"
msg="${msg}\nDAVLockDB /tmp/DAVLock"
msg="${msg}\nBrowserMatch \"Microsoft Data Access Internet Publishing Provider\" redirect-caref"
msg="${msg}\nBrowserMatch \"MS FrontPage\" redirect-carefully"
msg="${msg}\nBrowserMatch \"^WebDrive\" redirect-carefully"
msg="${msg}\nBrowserMatch \"^WebDAVFS/1.[0123]\" redirect-carefully"
msg="${msg}\nBrowserMatch \"^gnome-vfs/1.0\" redirect-carefully"
msg="${msg}\nBrowserMatch \"^XML Spy\" redirect-carefully"
msg="${msg}\nBrowserMatch \"^Dreamweaver-WebDAV-SCM1\" redirect-carefully"
echo -e ${msg} >> ${httpd_conf}

## Port part
echo '' >> ${httpd_conf}
if [ "${httpd_enabled}" == "1" ];then
    echo 'Listen 0.0.0.0:'${httpd_port} >> ${httpd_conf}
else
    echo '# Listen 0.0.0.0:'${httpd_port} >> ${httpd_conf}
fi

## SSL part
echo '' >> ${httpd_conf}
if [ "${httpd_ssl_enabled}" == "1" ];then
    ## Assemble SSL conf file
    /img/bin/assemble_ssl_webdav_conf.sh
    ret=$?
    
    ## Judge assemble SSL conf file sucess ?
    if [ "${ret}" != "0" ];then
        rm -f ${httpd_conf} ${httpd_ssl_conf}
        echo "Assemble SSL conf file fail"
        exit 1
    fi
    
    echo 'Include '${httpd_ssl_conf} >> ${httpd_conf}
else
    echo '# Include '${httpd_ssl_conf} >> ${httpd_conf}
fi


## Include wconf part
## ( wconf files are defined and used for WebDAV protocol only)
echo 'Include conf.d/*.wconf' >> ${httpd_conf}

## Add tphp setting
echo 'AddType application/x-httpd-php tphp' >> ${httpd_conf}

msg=""
## Alias "api" system folder part
msg="${msg}\nAlias \"/sys\" \"/var/www/html/api\""
msg="${msg}\n<Directory \"/var/www/html/api\">"
msg="${msg}\nOptions -Indexes"
msg="${msg}\n</Directory>"
echo -e ${msg} >> ${httpd_conf}


msg=""
## Log part
msg="${msg}\nLogFormat \"%h %l %u %t \\\\\"%r\\\\\" %>s %b \\\\\"%{Referer}i\\\\\" \\\\\"%{User-Agent}i\\\\\"\" combined"
msg="${msg}\nLogFormat \"%h %l %u %t \\\\\"%r\\\\\" %>s %b\" common"
msg="${msg}\nLogFormat \"%{Referer}i -> %U\" referer"
msg="${msg}\nLogFormat \"%{User-agent}i\" agent"
msg="${msg}\nLogLevel debug"
msg="${msg}\nErrorLog logs/error_webdav_log"
msg="${msg}\nCustomLog logs/access_webdav_log common"
echo -e ${msg} >> ${httpd_conf}


########################################
# conf contant (Part 1: Folder List)
########################################

msg=""
## root path (mapping DocumentRoot)
msg="${msg}\n<Directory \"/raid/data/ftproot\">"
msg="${msg}\n  Options ${browser_option}"
msg="${msg}\n  AllowOverride All"
msg="${msg}\n  Order allow,deny"
msg="${msg}\n  Allow from all"
msg="${msg}\n</Directory>"
msg="${msg}\n<Location />"
msg="${msg}\n  DAV On"
msg="${msg}\n  AuthType Basic"
msg="${msg}\n  AuthName \"Root Folder\""
msg="${msg}\n  AuthBasicProvider external"
msg="${msg}\n  AuthExternal pwauth"
msg="${msg}\n  AuthzUnixgroup on"
msg="${msg}\n  AuthzUserAuthoritative off"
msg="${msg}\n</Location>"
echo -e ${msg} >> ${httpd_conf}

msg=""
## Specical Folder for app: On-The-Go
## Thecus WebDav Check -- app will check this folder
msg="${msg}\nAlias \"/73f366c8cfff9d59\" \"/tmp\""
msg="${msg}\n<Directory \"/raid/tmp\">"
msg="${msg}\n  Options ${browser_option}"
msg="${msg}\n  AllowOverride All"
msg="${msg}\n  Order allow,deny"
msg="${msg}\n  Allow from all"
msg="${msg}\n</Directory>"
msg="${msg}\n<Location /73f366c8cfff9d59>"
msg="${msg}\n  DAV On"
msg="${msg}\n  AuthType Basic"
msg="${msg}\n  AuthName \"73f366c8cfff9d59\""
msg="${msg}\n  AuthBasicProvider external"
msg="${msg}\n  AuthExternal pwauth"
msg="${msg}\n  AuthzUnixgroup on"
msg="${msg}\n  AuthzUserAuthoritative off"
msg="${msg}\n</Location>"
echo -e ${msg} >> ${httpd_conf}

## Set System folder Deny 
## (Under master RAID /raid/data/)
master_raiddata="/raid${master_raidid}/data"
insert_folder_conf_deny "module"                          "${master_raiddata}"
insert_folder_conf_deny "_NAS_NFS_Exports_"               "${master_raiddata}"
insert_folder_conf_deny "_NAS_Recycle_${master_raidname}" "${master_raiddata}"
insert_folder_conf_deny "stackable"                       "${master_raiddata}"
insert_folder_conf_deny "_SYS_TMP"                        "${master_raiddata}"
insert_folder_conf_deny "tmp"                             "${master_raiddata}"

#### System folder
${sqlite} /raid/sys/smb.db "select share,\"guest only\" from smb_specfd" | \
while read sys_folder
do
    ## Get folder information
    folder_name=`echo $sys_folder | awk -F '|' '{print $1}'`
    folder_public=`echo $sys_folder | awk -F '|' '{print $2}'`

    ## call function: parser_folder 
    parser_folder ${folder_name} ${folder_public}
done

#### User folder (each)
## HA RAID
md_list=`cat /proc/mdstat | awk -F: '/^md6[0-9] :/{print substr($1,3)}' | sort -u`
if [ "${md_list}" == "" ];then
    ## Normal RAID
    md_list=`cat /proc/mdstat | awk -F: '/^md[0-9] :/{print substr($1,3)}' | sort -u`
fi

for md in $md_list
do
    ${sqlite} /raidsys/${md}/smb.db "select share,\"guest only\" from smb_userfd" | \
    while read sys_folder
    do
        ## Get folder information
        folder_name=`echo $sys_folder | awk -F '|' '{print $1}'`
        folder_public=`echo $sys_folder | awk -F '|' '{print $2}'`

        ## call function: parser_folder
        parser_folder ${folder_name} ${folder_public}
    done    
done


########################################
# Produce http.conf end
# Execute check http.conf syntax
########################################
/usr/sbin/httpd -f ${httpd_conf} -t

if [ "$?" != "0" ];then
    rm -f ${httpd_conf} ${httpd_ssl_conf}
    echo "Assemble httpd_webdav.conf fail"
    exit 1
else
    echo "Assemble httpd_webdav.conf sucess"
    exit 0
fi

