#!/bin/sh
httpd_conf="/tmp/httpd.conf"
rm -f ${httpd_conf}
sqlite="/usr/bin/sqlite"
conf_db="/etc/cfg/conf.db"
TMPIPV6EN="/var/tmp/ipv6_en"

httpd_port=`${sqlite} ${conf_db} "select v from conf where k='httpd_port'"`
httpd_enabled=`${sqlite} ${conf_db} "select v from conf where k='httpd_nic1_httpd'"`
type=`cat /etc/manifest.txt | awk '/type/{print $2}'`
hostname=`${sqlite} ${conf_db} "select v from conf where k='nic1_hostname'"`
wan_domain=".`${sqlite} ${conf_db} "select v from conf where k='nic1_domainname'"`"

echo 'AccessFileName .htaccess' >> ${httpd_conf}
echo 'AddType    application/x-httpd-php php htm html' >> ${httpd_conf}
echo 'CustomLog logs/access_log common' >> ${httpd_conf}
#echo 'CustomLog /dev/null common' >> ${httpd_conf}
echo 'DefaultType text/plain' >> ${httpd_conf}
echo 'DirectoryIndex index.html index.html.var index.php' >> ${httpd_conf}
echo 'DocumentRoot "/opt/apache/htdocs"' >> ${httpd_conf}
#echo 'ErrorLog logs/error_log' >> ${httpd_conf}
if [ "$1" != "" ]; then
	echo 'ErrorLog logs/error_log' >> ${httpd_conf}
else
	echo 'ErrorLog /tmp/httpd.log' >> ${httpd_conf}
fi
echo 'EnableMMAP off' >> ${httpd_conf}
echo 'EnableSendfile off' >> ${httpd_conf}
echo 'HostnameLookups Off' >> ${httpd_conf}
echo 'KeepAlive Off' >> ${httpd_conf}
echo 'KeepAliveTimeout 15' >> ${httpd_conf}
if [ "${httpd_enabled}" == "1" ];
then
	echo 'Listen 0.0.0.0:'${httpd_port} >> ${httpd_conf}
else
	echo '#Listen 0.0.0.0:'${httpd_port} >> ${httpd_conf}
fi
ENABLE_IPV6=`cat ${TMPIPV6EN}`
if [ "$ENABLE_IPV6" == "1" ];then
        echo 'Listen [::]:'${httpd_port} >> ${httpd_conf}
fi
echo 'LoadModule mime_magic_module  modules/mod_mime_magic.so' >> ${httpd_conf}
echo 'LoadModule mime_module        modules/mod_mime.so' >> ${httpd_conf}
echo '#LoadModule auth_module        modules/mod_auth.so' >> ${httpd_conf}
echo 'LoadModule log_config_module  modules/mod_log_config.so' >> ${httpd_conf}
echo 'LoadModule php5_module        modules/libphp5.so' >> ${httpd_conf}
echo 'LoadModule ssl_module         modules/mod_ssl.so' >> ${httpd_conf}
echo 'LoadModule dir_module         modules/mod_dir.so' >> ${httpd_conf}
echo 'LoadModule rewrite_module     modules/mod_rewrite.so' >> ${httpd_conf}
echo '#LoadModule auth_pam_module    modules/mod_auth_pam.so' >> ${httpd_conf}
echo 'LoadModule setenvif_module    modules/mod_setenvif.so' >> ${httpd_conf}
echo 'LoadModule cgi_module         modules/mod_cgi.so' >> ${httpd_conf}
echo 'LoadModule alias_module		modules/mod_alias.so' >> ${httpd_conf}
echo 'LoadModule actions_module		modules/mod_actions.so' >> ${httpd_conf}
echo 'LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined' >> ${httpd_conf}
echo 'LogFormat "%h %l %u %t \"%r\" %>s %b" common' >> ${httpd_conf}
echo 'LogFormat "%{Referer}i -> %U" referer' >> ${httpd_conf}
echo 'LogFormat "%{User-agent}i" agent' >> ${httpd_conf}
echo 'LogLevel warn' >> ${httpd_conf}
echo 'MaxKeepAliveRequests 100' >> ${httpd_conf}
echo 'ServerAdmin you@example.com' >> ${httpd_conf}
echo 'ServerName '${hostname}${wan_domain}'' >> ${httpd_conf}
echo 'ServerRoot "/opt/apache"' >> ${httpd_conf}
echo 'ServerSignature Off' >> ${httpd_conf}
echo 'ServerTokens Prod' >> ${httpd_conf}
echo 'Timeout 300' >> ${httpd_conf}
echo 'TypesConfig conf/mime.types' >> ${httpd_conf}
echo 'UseCanonicalName Off' >> ${httpd_conf}
echo 'ScriptAlias /cgi-bin/ "/img/bin/cgi-bin/"' >> ${httpd_conf}
echo 'AddHandler cgi-script .cgi' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo '<Directory />' >> ${httpd_conf}
echo 'Options FollowSymLinks' >> ${httpd_conf}
echo 'AllowOverride AuthConfig' >> ${httpd_conf}
echo '</Directory>' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo '<Directory "/img/bin/cgi-bin">' >> ${httpd_conf}
echo 'Options ExecCGI' >> ${httpd_conf}
echo 'AllowOverride None' >> ${httpd_conf}
echo '</Directory>' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo '<Directory "/opt/apache/htdocs">' >> ${httpd_conf}
echo 'Options Indexes FollowSymLinks' >> ${httpd_conf}
echo '</Directory>' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo '## Server-Pool Size Regulation (MPM specific)' >> ${httpd_conf}
echo '# prefork MPM' >> ${httpd_conf}
echo '<IfModule prefork.c>' >> ${httpd_conf}
echo 'StartServers         5' >> ${httpd_conf}
echo 'MinSpareServers      5' >> ${httpd_conf}
echo 'MaxSpareServers     10' >> ${httpd_conf}
echo 'MaxClients         150' >> ${httpd_conf}
echo 'MaxRequestsPerChild  0' >> ${httpd_conf}
echo '</IfModule>' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo 'User root' >> ${httpd_conf}
echo 'Group root' >> ${httpd_conf}
echo 'PidFile logs/httpd.pid' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo '<IfModule mod_mime_magic.c>' >> ${httpd_conf}
echo 'MIMEMagicFile conf/magic' >> ${httpd_conf}
echo '</IfModule>' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo 'Include conf/ssl.conf' >> ${httpd_conf}
echo '' >> ${httpd_conf}
echo '<IfModule mod_rewrite.c>' >> ${httpd_conf}
echo 'RewriteEngine On' >> ${httpd_conf}
echo 'RewriteCond %{REQUEST_METHOD} ^(TRACE|TRACK)' >> ${httpd_conf}
echo 'RewriteRule .* - [F]' >> ${httpd_conf}
echo '</IfModule>' >> ${httpd_conf}
echo '' >> ${httpd_conf}
