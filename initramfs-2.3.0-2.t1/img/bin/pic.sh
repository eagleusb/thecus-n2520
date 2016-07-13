#!/bin/sh
if [ $# -lt 3 ];then
  echo $0 TYPE MSG1 MSG2
  exit 1
fi

TYPE=$1
MSG1=$2
MSG2=$3
MSG3=$4

THECUS_IO=/proc/thecus_io
THECUS_AGENT3=/var/tmp/oled/pipecmd
AVRPIPE="/tmp/avrpipe"
PIC24_OK=/var/tmp/oled/PIC24F_OK

if [ "`/img/bin/check_service.sh pic16c`" = "1" ];then
  DEVICE=LCM
elif [ "`/img/bin/check_service.sh pic24`" = "1" ];then
  DEVICE=OLED
  if [ `pidof agent3 | wc -l` = 0 ];then
    rm -f ${THECUS_AGENT3}
    exit 1
  elif [ ! -e ${PIC24_OK} ];then
    exit 1
  fi
elif [ "`/img/bin/check_service.sh atmega168`" = "1" ];then
  DEVICE=ATMEGA168
fi

#for N4520
DEVICE=LCM
#DEVICE=OLED

if [ "${DEVICE}" = "LCM" ];then
  case "${TYPE}" in
    LCM_HOSTNAME|LCM_WANIP|LCM_LANIP|LCM_FAN|LCM_TEMP|LCM_DATE|LCM_UPTIME|LCM_USB)
      #echo ${TYPE} ${MSG1}
      echo ${TYPE} ${MSG1} > ${THECUS_IO}
    ;;
    LCM_MSG)
      if [ "${MSG3}" = "" ];then
        MSG3=0
      fi
      echo ${TYPE} -U"${MSG1}" -L"${MSG2}" -S${MSG3} > ${THECUS_IO}
    ;;
    PWR_S)
      #echo ${TYPE} ${MSG1}
      echo ${TYPE} ${MSG1} > ${THECUS_IO}
    ;;
    *)
      echo "Unknow ${DEVICE} type : ${TYPE}"
      exit 1
    ;;
  esac
elif [ "${DEVICE}" = "OLED" ];then
  case "${TYPE}" in
    LCM_MSG)
      if [ "${MSG3}" = "" ];then
        MSG3="agent2"
      fi
      echo "${MSG3}" 0 BTMSG "${MSG1} ${MSG2}" > ${THECUS_AGENT3}
      if [ ! -f /tmp/boot_ok1 ];then
        if [ `cat /var/tmp/oled/PIC24F_OK | awk -F: '/Pic Revision/{print $2}'` -le 8 ];then
          #workaround for piechart show in pic ver 8
          sleep 2
        fi
      fi
    ;;
    LCM_USB)
      MSG=3
      if [ "${MSG1}" = "104" -o "${MSG1}" = "105" ];then
        MSG=0
      elif [ "${MSG1}" = "103" ];then
        MSG=1
      elif [ "${MSG1}" = "102" ];then
        MSG=2
      fi
      if [ $MSG -lt 3 ];then
        echo 0 0 USBCP "${MSG}" > ${THECUS_AGENT3}
      fi
    ;;
    PWR_S)
      echo 0 0 STARTWD > ${THECUS_AGENT3}
    ;;
    ACPWR)
      echo 0 0 ${TYPE} ${MSG1} > ${THECUS_AGENT3}
    ;;
    UPGRADE_MSG)
      echo UPGRADE 0 ${MSG1} > ${THECUS_AGENT3}
    ;;
    UPGRADE_ACT) #UPGRADE_PIC_START/BOOT_LOADER/UPGRADE_PIC_END
      echo 0 0 ${MSG1} > ${THECUS_AGENT3}
    ;;
    UPGRADE_PIC)
      echo 0 0 ${TYPE} ${MSG1} ${MSG2} > ${THECUS_AGENT3}
    ;;
    POWER_OFF)
      echo 0 0 ${TYPE} > ${THECUS_AGENT3}
    ;;
    SLED)
      echo 0 0 ${TYPE} ${MSG1} ${MSG2} > ${THECUS_AGENT3}
    ;;
    *)
      echo "Unknow ${DEVICE} type : ${TYPE}"
      exit 1
    ;;
  esac
elif [ "${DEVICE}" = "ATMEGA168" ];then
  checkflag=`ps | grep agent2  | grep -v grep | wc -l`
  if [ $checkflag -gt 0 ];then
    
    case "${TYPE}" in
        LCM_MSG)
          if [ ! -f /tmp/agent2_ok ];then
             if [ "${MSG3}" = "" ];then
                     MSG3="agent2"
             fi
             echo "${MSG3} 0 BTMSG ${MSG1} ${MSG2} " > ${AVRPIPE}
          else
             echo "UPGRADE 2 ${MSG1} ${MSG2}  " > ${AVRPIPE}
          fi
        ;;
        LCM_USB)
          MSG=3
          if [ "${MSG1}" = "104" -o "${MSG1}" = "105" ];then
             MSG=0
          elif [ "${MSG1}" = "103" ];then
             MSG=1
          elif [ "${MSG1}" = "102" ];then
             MSG=2
          fi
          if [ $MSG -lt 3 ];then
              echo "usbcp 0 USBCP ${MSG} " > ${AVRPIPE}
          fi
        ;;
        PWR_S)
          echo "agent2 0 STARTWD " > ${AVRPIPE}
          echo "agent2 0 SETEXCFG 90 " > ${AVRPIPE}
        ;;
        POWER_OFF)
          echo "0 0 ${TYPE} 0 " > ${AVRPIPE}
        ;;
        ACPWR)
          echo "0 0 ${TYPE} ${MSG1} " > ${AVRPIPE}
        ;;
        UPGRADE_MSG)
          echo "UPGRADE 2 ${MSG1}  " > ${AVRPIPE}
        ;;
        UPGRADE_ACT) #UPGRADE_PIC_START/BOOT_LOADER/UPGRADE_PIC_END
          echo "0 0 ${MSG1} " > ${AVRPIPE}
        ;;
        UPGRADE_PIC)
          echo "0 0 ${TYPE} ${MSG1} ${MSG2} " > ${AVRPIPE}
        ;;
        START)
          echo "agent2 0 SETBTO 100 " > ${AVRPIPE}
        ;;
        SETLOGO)
          echo "agent2 0 SETLOGO ${MSG1} ${MSG2}" > ${AVRPIPE}
        ;;
    esac
  fi  
else
  echo "Unknow device : ${DEVICE}"
  exit 1
fi
exit 0
