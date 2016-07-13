#!/bin/sh

dir="/var/www/db"
db="$dir/thecus_ddns.db"

mkdir -p $dir
chown apache:apache $dir

[ -f $db ] && exit

#sqlite3 $db "CREATE TABLE 'ddns' (
#'mac'		text,
#'email'		text,
#'passwd'	text,
#'sn'		text,
#'model'		text)"

sqlite3 $db "CREATE TABLE 'account' (
'email'     text,
'passwd'    text,
'verify'    text,
'time'      INTEGER)"

chown apache:apache $db
