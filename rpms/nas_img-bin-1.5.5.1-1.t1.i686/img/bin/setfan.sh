#!/bin/sh
act=$1
fan_chip=`/img/bin/check_service.sh fan_chip`
sys_fan1=`/img/bin/check_service.sh sys_fan1`

if [ "${act}" = "" ] || [ "${act}" = "load" ] ;then
#modprobe fan chip driver
    case "${fan_chip}" in
        tmp401)
            modprobe tmp401
            sleep 1
            echo 50000 > /sys/class/pwm/pwm.4:1/period_ns
            ;;

        f75387sg)
            if [ "`lsmod | grep f75387sg`" != "" ];then
                rmmod f75387sg
            fi

            modprobe f75387sg hwm=1
            echo "REG 1 0x61 0xCA" > /proc/hwm
            ;;
        "Default")
            echo "reset" > /proc/hwm
            sleep 1
            echo "fix" > /proc/hwm
            echo "fan1 pwm" > /proc/hwm
            echo "BT 0 55" > /proc/hwm
            echo "BT 1 40" > /proc/hwm
            echo "BT 2 35" > /proc/hwm
            echo "BT 3 25" > /proc/hwm
            ;;
        "ITE8728")
            if [ "${sys_fan1}" = "2" ];then
              modprobe it87 fan_type=2
            else
              modprobe it87
            fi

            echo "REG 1 0x13 0x77" > /proc/hwm
            echo "REG 1 0x14 0x80" > /proc/hwm 
            echo "REG 1 0x15 0x7F" > /proc/hwm
            echo "REG 1 0x16 0x7F" > /proc/hwm
            echo "REG 1 0x17 0x7F" > /proc/hwm
            echo "REG 1 0x63 0xFF" > /proc/hwm
            echo "REG 1 0x6B 0xFF" > /proc/hwm
            echo "REG 1 0x73 0xFF" > /proc/hwm
            ;;
        "ITE8728|F75387SG")
            modprobe it87 fan_type=1
            echo REG 1 0x60 0x55 > /proc/f75387sg1
            echo REG 1 0x60 0x55 > /proc/f75387sg2
            echo REG 1 0x75 0xFF > /proc/f75387sg1
            echo REG 1 0x85 0xFF > /proc/f75387sg1
            echo REG 1 0x75 0xFF > /proc/f75387sg2
            echo REG 1 0x85 0xFF > /proc/f75387sg2
            ;;
        "W83627EHG")
            modprobe w83627ehf
            ;;
    esac
elif [ "${act}" = "unload" ];then
  killall check_fan_lan.sh
  if [ "${fan_chip}" = "ITE8728" ];then
        echo "REG 1 0x13 0x07" > /proc/hwm
        echo "REG 1 0x14 0x40" > /proc/hwm
  fi
fi

