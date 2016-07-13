#!/bin/sh

###################################
# Constant define
###################################
ssl_conf="/tmp/ssl_webdav.conf"
sqlite="/usr/bin/sqlite3"
conf_db="/etc/cfg/conf.db"
SSLCertificateFile="\/etc\/httpd\/ssl.d\/now\/server.crt"
SSLCertificateKeyFile="\/etc\/httpd\/ssl.d\/now\/server.key"
SSLCACertificateFile="\/etc\/httpd\/ssl.d\/now\/ca-bundle.crt"

## Select conf setting from DB
httpd_ssl_port=`${sqlite} ${conf_db} "select v from conf where k='webdav_ssl_port'"`

###################################
# Produce conf file
###################################

## Delete conf file first
rm -f ${ssl_conf}

## Copy Default conf file
cp /etc/httpd/conf.d/ssl.conf.tpl ${ssl_conf}

## Replace setting
sed -i "s/@ENA@//g" ${ssl_conf}
sed -i "s/@PORT@/${httpd_ssl_port}/g" ${ssl_conf}
sed -i "s/@CERT@/${SSLCertificateFile}/g" ${ssl_conf}
sed -i "s/@KEY@/${SSLCertificateKeyFile}/g" ${ssl_conf}
sed -i "s/@CACERT@/${SSLCACertificateFile}/g" ${ssl_conf}

exit 0
