#!/bin/sh
usage(){
echo "Usage $(basename $0): [options] <username>
[options]
	-h		Show usage
	-p <password> 	Password of the new account
	-l		Add local user
	-s		Add samba user
<username>
	The user you want to create
" 1>&2
exit 2
}

log(){
	echo "`date "+%D %T"` "$1" "$2"" >> /tmp/add_user.log
}

init_env(){
	local SHIFT OPTION OPTARG
	while getopts "hlsp:" OPTION ;do
		case $OPTION in
			"l")
				LOCAL_USER=1
				;;
			"s")
				SAMBA_USER=1
				;;
			"p")
				PASSWD="${OPTARG}"
				;;
			"?"|"h")
				usage
				;;
		esac
		SHIFT=$((OPTIND - 1))
	done
	shift ${SHIFT}

	USER="$1"
	[ -z "${USER}" ] && usage
	if [ "${LOCAL_USER}" == 1 -a "${SAMBA_USER}" == 1 -a -z "${PASSWD}" ];then
		log "init_env" "ERROR: You must assign password when adding Samba user."
		exit 1
	fi
}

list_local_uid(){
	getent passwd \
		| awk -F':' -v begin=${LIMIT_BEGIN} -v end=${LIMIT_END} \
				'($3>=begin)&&($3<=end){print $3}'
}
get_user_id(){
	# get "user_id_limit_begin" and  "user_id_limit_end" in webconfig
	local WEBCONFIG=/var/www/html/function/conf/webconfig
	local LIMIT_BEGIN=`grep "user_id_limit_begin" ${WEBCONFIG} | grep -Eo "[0-9]+"`
	local LIMIT_END=`grep "user_id_limit_end" ${WEBCONFIG} | grep -Eo "[0-9]+"`

	#Get the latest uid
	USER_ID=`list_local_uid | tail -n 1`
	if [ -z "${USER_ID}" ];then
		USER_ID=${LIMIT_BEGIN}
	elif [ ${USER_ID} == ${LIMIT_END} ];then
		log "get_user_id" "ERROR: Reaching the maximum UID."
		exit 1
	else
		#Generate new uid
		USER_ID=$((USER_ID+1))
	fi
}

add_local_user(){
	local RET
	get_user_id
	adduser -D -u "${USER_ID}" -G users -s /dev/null -h /dev/null -H -g "${USER}" "${USER}"
	RET=$?
	log "add_local_user" "${USER}:${USER_ID} return:${RET}"
	if [ -n "${PASSWD}" -a ${RET} == 0 ];then
		passwd "${USER}" "${PASSWD}"
		RET=$?
		log "add_local_user" "assigning password return:${RET}"
	fi
	return ${RET}
}

add_samba_user(){
	local RET
	echo -e "${PASSWD}\n${PASSWD}\n" | smbpasswd -s -a ${USER}
	RET=$?
	log "add_samba_user" "${USER}:${USER_ID} return:${RET}"

	if [ ${RET} != 0 -a "${LOCAL_USER}" == 1 ];then
		userdel ${USER}
		log "add_samba_user" "Clean local user ${USER}"
	fi
	return ${RET}
}

main(){
	RET=0
	if [ "${LOCAL_USER}" == 1 ];then
		add_local_user
		RET=$?
		[ ${RET} != 0 ] && exit ${RET}
	fi
	if [ "${SAMBA_USER}" == 1 ];then
		add_samba_user
		RET=$?
	fi
	exit $RET
}
init_env $@
main
