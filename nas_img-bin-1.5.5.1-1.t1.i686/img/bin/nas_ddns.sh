#!/bin/sh


##################################################################
#
#  First, define some variables globally needed
#
##################################################################
#error_code0x00: "Default Error Code",
#error_code0x01: "Parameter error unnormal ",
#error_code0x02: "Command error",
#error_code0x03: "Parameter error",
#error_code0x04: "Email length error",
#error_code0x05: "Password length error",
#error_code0x06: "DDNS name length error",
#error_code0x07: "User name length error",
#error_code0x11: "Connection timeout",
#error_code0x21: "Server database open fail",
#error_code0x22: "Server database close fail",
#error_code0x23: "Server database execute fail",
#error_code0x31: "Thecus ID exist",
#error_code0x32: "Auth fail",
#error_code0x33: "Thecus ID is not verified",
#error_code0x34: "Update DDNS name fail",
#error_code0x35: "Thecus ID is not exist",
#error_code0x36: "Send verify letter fail",
#error_code0x37: "Resend verify letter fail",
#error_code0x38: "DDNS name is exist",
#error_code0x39: "DDNS name is not exist",
#error_code0x41: "Get MAC address error",
#error_code0x51: "Email is empty",
#error_code0x52: "Password is empty",
#error_code0x53: "maybe be same with E_ID_NOT_EXIST",
#error_code0x54: "Password is wrong",
#error_code0x61: "Database error",

NIC_ETH0_MAC=/sys/class/net/eth0/address
DDNS_UTILITY=/usr/bin/ddns_client
DATABASE=/etc/cfg/conf.db

mac_addr=`cat $NIC_ETH0_MAC`
default_ddns_hostname=N`echo $mac_addr | tr '[:lower:]' '[:upper:]' | awk -F: '{print $3$4$5 }'`
default_ddns_fqdn=$default_ddns_hostname

# Query for "Thecus ID" 
ddns_fqdn=`sqlite $DATABASE 'SELECT v FROM conf WHERE k = "thecus_ddns_fqdn";' | cut -d . -f 1`
ddns_thecus_id=`sqlite $DATABASE 'SELECT v FROM conf WHERE k = "thecus_id";'`

# Query for "DDNS Support"
ddns_domain=`sqlite $DATABASE 'SELECT v FROM conf WHERE k = "ddns_domain";'`
ddns_reg=`sqlite $DATABASE 'SELECT v FROM conf WHERE k = "ddns_reg";' | cut -f2 -d'@'`
ddns_uname=`sqlite $DATABASE 'SELECT v FROM conf WHERE k = "ddns_uname";'`

##################################################################
#
#  Second, declare sub routines needed
#
##################################################################


####################################################################
# Get Thecus ddns name
# Both hostname and fqdn will be return
####################################################################
function getDDNSName() {
  echo -e "$default_ddns_fqdn\t$ddns_fqdn\t$ddns_thecus_id" > /tmp/ddns_fqdn

  # Check Other DDNS Service (ex. no-ip, DynDNS, etc.)
  ddns_ddns=`sqlite $DATABASE 'SELECT v FROM conf WHERE k = "ddns_ddns";'`
  if [ "$ddns_ddns" = "1" ];then
    ddns_fqdn_other="${ddns_domain}.${ddns_reg}"
  else
    ddns_fqdn_other=""
    ddns_uname=""
  fi
    echo -e "$default_ddns_fqdn\t$ddns_fqdn_other\t$ddns_uname" > /tmp/ddns_fqdn_other

  return 0
}


####################################################################
# Create Thecus ID
# param email, password, and name of new account
# only return DDNS_UTILITY command result code
####################################################################
function create_account() {
  $DDNS_UTILITY 1 "$1" "$2" "$3" "$4" "$5"
  ret=$?
  echo $ret > /tmp/ddns.out
}


####################################################################
# Auth Thecus ID
# param email, password, ddns
# only return DDNS_UTILITY command result code
####################################################################
function auth() {
  clean_account_info
  response=`$DDNS_UTILITY 2 $1 $2 $mac_addr $3`
  ret=$?
  echo -e "$response" > /tmp/response
  if [ $ret -eq 0 ];then
    fname=`cat /tmp/response | grep FirstName | awk '{ print $2}'`
    mname=`cat /tmp/response | grep MiddleName | awk '{ print $2}'`
    lname=`cat /tmp/response | grep LastName | awk '{ print $2}'`
    ddns_fqdn=`cat /tmp/response | grep FQDN | awk '{ print $2}'`
    save_account_info $1 $2 "$fname" "$mname" "$lname" "$ddns_fqdn"
    update_ddns $1 $2
    update_ret=$ret
    if [ $update_ret -ne 0 ];then
      clean_account_info
    fi
  fi
  echo $ret > /tmp/ddns.out
}

####################################################################
# Save Thecus ID into database
# param email, password, and name of new account and fqdn for ddns
####################################################################
function save_account_info() {

  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_ddns', 1);"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_id', '$1');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_pwd', '$2');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_fname', '$3');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_mname', '$4');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_lname', '$5');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_ddns_fqdn', '$6');"

  return 0
}

function clean_account_info() {
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_ddns', 0);"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_id', '');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_pwd', '');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_fname', '');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_mname', '');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_lname', '');"
  sqlite $DATABASE "INSERT or REPLACE into conf VALUES('thecus_ddns_fqdn', '');"
}


####################################################################
# Update DDNS
# param email, password
# only return DDNS_UTILITY command result code
####################################################################
function update_ddns() {
  $DDNS_UTILITY 3 $1 $2 $mac_addr
  ret=$?
  echo $ret > /tmp/ddns.out
}

####################################################################
# Send Activation Email
# param email address which you want to send to
# ret {Number} return value of DDNS_UTILITY command
####################################################################
function send_verify_email() {
  $DDNS_UTILITY 4 $1
  ret=$?
  echo $ret > /tmp/ddns.out
}



##################################################################
#
#  Finally, exec main code
#
##################################################################

case $1 in
  0)
    getDDNSName
    ;;
  1)
    create_account $2 $3 $4 $5 $6
    ;;
  2)
    auth $2 $3 $4.thecuslink.com
    ;;
  3)
    update_ddns $2 $3
    ;;
  4)
    send_verify_email $2
    ;;
  5)
    clean_account_info
    ;;
esac

