#!/bin/sh
#==================================================
#        FILE:  chkhwinfo.sh
#       USAGE:  none
# DESCRIPTION:  check hardware information
#       NOTES:  none
#      AUTHOR:  Dane
#     VERSION:  1.0.0
#     CREATED:  2012/06/11
#    REVISION:  
#==================================================

#==================================================
#  Constants Defined
#==================================================
MODEL=`cat /var/run/model`
HWINFO="/img/bin/hw/hwinfo.${MODEL}"
TEST_RESULT="/tmp/hwinfo"
LOGEVENT="/img/bin/logevent/event"

#==================================================
#  Variable Defined
#==================================================
GigaNum=0        # Numbers of giga network interface
TengbNum=0       # Numbers of tengb network interface
#Usb2Num=0        # Numbers of USB2.0 device
#Usb3Num=0        # Numbers of USB3.0 device 
BatteryNum=0     # Numbers of battery   
DomNum=0         # Numbers of DOM

#==================================================
#   Include File
#==================================================
. /img/bin/function/libhw
. /img/bin/function/libnetwork

#==================================================
#  Function Defined
#==================================================
#################################################
#         NAME:  read_hwinfo
#  DESCRIPTION:  read NAS hardware info from hwinfo conf
#       RETURN:  none
#       AUTHOR:  Dane
#      CREATED:  2012/06/11
#################################################
read_hwinfo() {
    GigaNum=`/img/bin/check_service.sh "giga"`
    TengbNum=`/img/bin/check_service.sh "tengb"`
    #Usb2Num=`/img/bin/check_service.sh "usb2"`
    #Usb3Num=`/img/bin/check_service.sh "usb3"`
    BatteryNum=`/img/bin/check_service.sh "battery"`
    DomNum=`/img/bin/check_service.sh "dom"`
    DVDrom=`/img/bin/check_service.sh "dvdrom"`
    MPT2SAS=`/img/bin/check_service.sh "mpt2sas"`
    OLED=`/img/bin/check_service.sh "pic16c"`
    if [ ${OLED} == "0" ] 
    then
        OLED=`/img/bin/check_service.sh "pic24"`
    fi
    SOC=`/img/bin/check_service.sh "soc"`
}

#################################################
#         NAME:  output_to_result
#  DESCRIPTION:  output hardware information to result file
#       RETURN:  none
#       AUTHOR:  Dane
#      CREATED:  2012/06/11
#################################################
output_to_result() {
    local fTempIFS=${IFS} 

    IFS=","
    echo "$*" >> $TEST_RESULT
    IFS=${fTempIFS}
}

#==================================================
#  Main code
#==================================================

cat /dev/null > $TEST_RESULT
read_hwinfo

output_to_result "cpu" "`Lhw_get_cpu_info`"
output_to_result "memory" "`Lhw_get_mem_size`"
output_to_result "BIOS" "`Lhw_get_bios_version`"
#--------------------------------------------------
#  Check Network Device 
#--------------------------------------------------
output_to_result "networkdev" " "
NicNum=0
for ((i = 0; i < $GigaNum; i++))
do
    NicNum=`expr $NicNum + 1`
    if [ "${SOC}" == "ppc" ];then
        NicInfo=`Lhw_get_cpu_info`
    else
        NicInfo=`Lhw_get_nic_hwinfo "eth${i}"`
    fi

    if [ "${NicInfo}" != "" ]
    then
        output_to_result "`Lnet_get_nic_name ${NicNum}`" "${NicInfo}" "Y"
    else
        ${LOGEVENT} 997 815 error email "eth${i}"
        output_to_result "`Lnet_get_nic_name ${NicNum}`" "Not Found"  "N"
    fi
done

for ((i = 0; i < $TengbNum; i++))
do
    NicNum=`expr $NicNum + 1`
    NicInfo=`Lhw_get_nic_hwinfo "geth${i}"`
    if [ "${NicInfo}" != "" ]
    then
        output_to_result "`Lnet_get_nic_name ${NicNum}`" "${NicInfo}" "Y"
    else
        ${LOGEVENT} 997 815 error email "geth${i}"
        output_to_result "`Lnet_get_nic_name ${NicNum}`" "Not Found" "N"
    fi
done

#--------------------------------------------------
#  Check USB Device 
#--------------------------------------------------
output_to_result "usbdev" " "
if [ "${SOC}" == "ppc" ];then
    UsbInfo=`Lhw_get_cpu_info`
    output_to_result "USB" "${UsbInfo}"
else
    AllUsb=`Lhw_get_usb_dev`
    AllUsb2=(`echo ${AllUsb}|sed 's/\;/\n/g'|grep 2.0|sed 's/ /\*/g'|sed 's/,2.00/\n/g'`)
    Usb2Num=${#AllUsb2[@]}
    for ((i = 0; i < ${Usb2Num}; i++))
    do
        output_to_result "USB2.0-`expr $i + 1`" "`echo ${AllUsb2[$i]}|sed 's/\*/ /g'|sed 's/^ //'`" "Y"
    done

    AllUsb3=(`echo ${AllUsb}|sed 's/\;/\n/g'|grep 3.0|sed 's/ /\*/g'|sed 's/,3.00/\n/g'`)
    Usb3Num=${#AllUsb3[@]}
    for ((i = 0; i < ${Usb3Num}; i++))
    do
        output_to_result "USB3.0-`expr $i + 1`" "`echo ${AllUsb3[$i]}|sed 's/\*/ /g'|sed 's/^ //'`" "Y"
    done
fi

#--------------------------------------------------
#  Check DOM 
#--------------------------------------------------
if [ "${DomNum}" != "0" ];then
    DomFound=`Lhw_check_dom`
    #output_to_result "DOM" "${DomFound}"
    if [ "${DomNum}" == "2" ] && [ "${DomFound}" == "Single DOM" ]
    then
        ${LOGEVENT} 997 817 error email 
        output_to_result "DOM" "${DomFound}" "N"
    else
        output_to_result "DOM" "${DomFound}" "Y"
    fi
fi

#--------------------------------------------------
#  Check Sata 
#--------------------------------------------------
output_to_result "SATA Controller"
AllSata=""

if [ "${SOC}" == "ppc" ];then
    AllSata=`Lhw_get_cpu_info`
    output_to_result "SATA" "${AllSata}"
else
    AllSata=`Lhw_get_sata_controller|sed 's/ /\*/g'`
    SataIndex=1
    for sata in ${AllSata}
    do
        output_to_result "SATA${SataIndex}" "`echo $sata |sed 's/\*/ /g'`"
        SataIndex=`expr $SataIndex + 1`
    done

    if [ "${MPT2SAS}" == "1" ]
    then
        MptCardsInfo=`Lhw_get_mptinfo`
        MptNum=`Lhw_get_mptinfo |wc -l`
        for ((i = 1; i <= ${MptNum}; i++))
        do
            output_to_result "SATA${SataIndex}" "`Lhw_get_mptinfo|sed -n ${i}p`"
            SataIndex=`expr $SataIndex + 1`
        done
    fi
fi

#--------------------------------------------------
#  Check OLED 
#--------------------------------------------------
if [ "${OLED}" == "1" ]; 
then
    OLEDInfo=`Lhw_check_oled`
    if [ "$OLEDInfo" == "" ]
    then
        output_to_result "OLED" "Not Found" "N"
    else
        output_to_result "OLED" "${OLEDInfo}" "Y"
    fi
fi

