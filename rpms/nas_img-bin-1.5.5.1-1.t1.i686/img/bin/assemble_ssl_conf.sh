#!/bin/sh
ssl_conf="/tmp/ssl.conf"
sqlite="/usr/bin/sqlite"
conf_db="/etc/cfg/conf.db"
event_triger="/img/bin/logevent/event"
TMPIPV6EN="/var/tmp/ipv6_en"
rm -f /tmp/ssl.conf

ssl_port=`${sqlite} ${conf_db} "select v from conf where k='httpd_ssl'"`
ssl_enabled=`${sqlite} ${conf_db} "select v from conf where k='httpd_nic1_ssl'"`
hostname=`${sqlite} ${conf_db} "select v from conf where k='nic1_hostname'"`
wan_domain=".`${sqlite} ${conf_db} "select v from conf where k='nic1_domainname'"`"

echo 'SSLRandomSeed startup builtin' >> ${ssl_conf}
echo 'SSLRandomSeed connect builtin' >> ${ssl_conf}
echo '' >> ${ssl_conf}
if [ "${ssl_enabled}" == "1" ];
then
	echo 'Listen 0.0.0.0:'${ssl_port} >> ${ssl_conf}
else
	echo '#Listen 0.0.0.0:'${ssl_port} >> ${ssl_conf}
fi
ENABLE_IPV6=`cat ${TMPIPV6EN}`;
if [ "$ENABLE_IPV6" == "1" ];then
  echo 'Listen [::]:'${ssl_port} >> ${ssl_conf}
fi
echo 'AddType application/x-x509-ca-cert .crt' >> ${ssl_conf}
echo 'AddType application/x-pkcs7-crl    .crl' >> ${ssl_conf}
echo 'SSLPassPhraseDialog  builtin' >> ${ssl_conf}
echo 'SSLSessionCache         dbm:/etc/httpd/logs/ssl_scache' >> ${ssl_conf}
echo 'SSLSessionCacheTimeout  300' >> ${ssl_conf}
echo 'SSLMutex  file:/etc/httpd/logs/ssl_mutex' >> ${ssl_conf}
echo '' >> ${ssl_conf}
echo '<VirtualHost _default_:'${ssl_port}'>' >> ${ssl_conf}
echo '<IfModule mod_rewrite.c>' >> ${ssl_conf}
echo 'RewriteEngine On' >> ${ssl_conf}
echo 'RewriteCond %{REQUEST_METHOD} ^(TRACE|TRACK)' >> ${ssl_conf}
echo 'RewriteRule .* - [F]' >> ${ssl_conf}
echo '</IfModule>' >> ${ssl_conf}
echo 'DocumentRoot "/etc/httpd/htdocs"' >> ${ssl_conf}
echo 'ServerName '${hostname}${wan_domain}':'${ssl_port} >> ${ssl_conf}
echo 'ServerAdmin you@example.com' >> ${ssl_conf}
#echo 'ErrorLog /etc/httpd/logs/error_log' >> ${ssl_conf}
if [ "$1" != "" ]; then
	echo 'ErrorLog /etc/httpd/logs/error_log' >> ${ssl_conf}
else
	echo 'ErrorLog /tmp/httpd.log' >> ${ssl_conf}
fi
#echo 'TransferLog /etc/httpd/logs/access_log' >> ${ssl_conf}
echo 'TransferLog /etc/httpd/logs/access_log' >> ${ssl_conf}
echo 'SSLEngine on' >> ${ssl_conf}
echo 'SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL' >> ${ssl_conf}
if [ "$1" != "sslerror" ] && [ -e "/raid/sys/httpd/server.crt" ] && [ -e "/raid/sys/httpd/server.key" ] && [ -e "/raid/sys/httpd/ca-bundle.crt" ]; then
	echo 'SSLCertificateFile /raid/sys/httpd/server.crt' >> ${ssl_conf}
	echo 'SSLCertificateKeyFile /raid/sys/httpd/server.key' >> ${ssl_conf}
	echo 'SSLCACertificateFile /raid/sys/httpd/ca-bundle.crt' >> ${ssl_conf}
	${event_triger} 997 450 "info" "email"
else
	echo 'SSLCertificateFile /etc/httpd/conf/ssl.crt/server.crt' >> ${ssl_conf}
	echo 'SSLCertificateKeyFile /etc/httpd/conf/ssl.key/server.key' >> ${ssl_conf}
	echo 'SSLCACertificateFile /etc/httpd/conf/ssl.crt/ca-bundle.crt' >> ${ssl_conf}
fi
echo '' >> ${ssl_conf}
echo '<Files ~ "\.(cgi|shtml|phtml|php3?)$">' >> ${ssl_conf}
echo 'SSLOptions +StdEnvVars' >> ${ssl_conf}
echo '</Files>' >> ${ssl_conf}
echo '<Directory "/img/bin/cgi-bin">' >> ${ssl_conf}
echo 'SSLOptions +StdEnvVars' >> ${ssl_conf}
echo '</Directory>' >> ${ssl_conf}
echo '' >> ${ssl_conf}
echo 'SetEnvIf User-Agent ".*MSIE.*" \' >> ${ssl_conf}
echo 'nokeepalive ssl-unclean-shutdown \' >> ${ssl_conf}
echo 'downgrade-1.0 force-response-1.0' >> ${ssl_conf}
echo '' >> ${ssl_conf}
#echo 'CustomLog /etc/httpd/logs/ssl_request_log \' >> ${ssl_conf}
echo 'CustomLog /etc/httpd/logs/ssl_request_log \' >> ${ssl_conf}
echo '"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"' >> ${ssl_conf}
echo '</VirtualHost>' >> ${ssl_conf}
