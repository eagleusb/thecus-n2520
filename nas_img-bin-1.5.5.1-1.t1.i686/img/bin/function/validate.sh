#!/bin/sh

## This program can be used to test some pattern is right or not.
## More regular expression can be found at http://regexlib.com/

RE_IPV4='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
RE_IPV4_MASK='^(((0|128|192|224|240|248|252|254).0.0.0)|(255.(0|128|192|224|240|248|252|254).0.0)|(255.255.(0|128|192|224|240|248|252|254).0)|(255.255.255.(0|128|192|224|240|248|252|254)))$'
RE_IPV6='^(([A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4})$|^([A-Fa-f0-9]{1,4}::([A-Fa-f0-9]{1,4}:){0,5}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){2}:([A-Fa-f0-9]{1,4}:){0,4}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){3}:([A-Fa-f0-9]{1,4}:){0,3}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){4}:([A-Fa-f0-9]{1,4}:){0,2}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){5}:([A-Fa-f0-9]{1,4}:){0,1}[A-Fa-f0-9]{1,4})$|^(([A-Fa-f0-9]{1,4}:){6}:[A-Fa-f0-9]{1,4})$'
RE_HOSTNAME='^([0-9a-zA-Z_\-]){0,15}$'
RE_DOMAIN='^([0-9a-zA-Z_\.\-])*$'
RE_DNS="${RE_IPV4}|${RE_IPV6}"


## Don't modify the following code

UPPER_PAT=`echo $1 | awk '{print toupper($_)}'`

PAT="RE_${UPPER_PAT}"
OTHER_PAT=("IPV6_LEN" "WINS" "ISNUM")
OTHTER_FUN=("check_IPv6_len" "check_wins" "check_num")

check_num(){
    local fRet=0
    local fVal=$1

    expr $fVal "+" 10 &> /dev/null
    if [ $? -ne 0 ];then
        fRet=1
    fi

    echo ${fRet}
}

check_wins(){
    local fVal=$1
    local fRet="0"
    local fStr
    local fIsNum
    local fFirstVal

    fStr=`echo $fVal | grep -E ${RE_IPV4}`
    if [ "$fStr" == "" ];then
        fStr=`echo $fVal | grep -E ${RE_DOMAIN}`
        fFirstVal=`echo "${fVal}" | awk -F '.' '{print $1}'`
        fIsNum=`check_num ${fFirstVal}`
        if [ "${fStr}" == "" ] || [ "${fIsNum}" == "0" ];then
            fRet="1"
        fi
    fi
    
    echo "${fRet}"
}

check_IPv6_len(){
    local fRet="0"
    local fTmpStr
    local fVal=$1

    fRet=`check_num ${fVal}`
    if [ "$fRet" == "1" ];then
        fRet=1
    else 
        if [ $fVal -lt 0 ] || [ $fVal -gt 128 ] || [ $(($fVal % 4)) -ne 0 ];then
            fRet=1
        fi
    fi

    echo "${fRet}"
}

declare -p $PAT > /dev/null 2>&1
if [ $? == 1 ]; then
    Ret=1
    for((i=0;i<${#OTHER_PAT[@]};i++))
    do
        if [ "${OTHER_PAT[$i]}" == "${UPPER_PAT}" ];then
            Ret=0
            break
        fi
    done
    if [ "${Ret}" == "0" ];then
        Ret=`${OTHTER_FUN[$i]} "$2"`
    fi
else
    R=`eval echo '$'$PAT`
    Ret=`echo $2 | grep -E $R`
    if [ "$Ret" != "" ];then
        Ret="0"
    else
        Ret="1"
    fi
fi

if [ "$Ret" == "" ];then
    Ret="1"
fi
echo $Ret
