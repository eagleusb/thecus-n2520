#!/bin/sh
#
# Decrypt diagnostics backup configure file
# decrypt.sh encrypt_file decrypt_file
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
usage() {
	echo "Usage:"
	echo "	decrypt.sh encrypt_file decrypt_file"
}

##################################################################
#
#  Finally, exec main code
#
##################################################################
if [ $# -ne 2 ]; then
	usage
	exit 1
fi

enc_file="$1"
dec_file="$2"
if [ ! -f ${enc_file} ]; then
	echo "${enc_file} doesn't exist!"
	exit 1
fi
if [ -f ${dec_file} ]; then
	echo "${dec_file} already exists!"
	exit 1
fi

des -k ${enckey} -D ${enc_file} ${dec_file}
exit $?
