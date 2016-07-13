#!/bin/sh

wep_enabled=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wep_enabled'"`
wep_key1=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wepkey1'"`
wep_key2=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wepkey2'"`
wep_key3=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wepkey3'"`
wep_key4=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wepkey4'"`
wireless_essid=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_essid'"`
wireless_dhcp=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_dhcp'"`
wireless_netmask=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_netmask'"`
wireless_ip=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_ip'"`
wireless_startip=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_startip'"`
wireless_endip=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_endip'"`
wireless_essid_broadcast=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_essid_broadcast'"`
wireless_channel=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_channel'"`
wireless_txpw=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_txpw'"`
wireless_wep_index=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wep_index'"`
wireless_wep_key_length=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_wep_key_length'"`
wireless_authmode=`/usr/bin/sqlite /etc/cfg/conf.db "select v from conf where k='wireless_authmode'"`
if [ "$wireless_authmode" = "" ];then
wireless_authmode=2;
fi

inprocom(){
#enable wep
/sbin/iwpriv wlan0 datarate 0

if [ "$wep_enabled" = "1" ];then
	/sbin/iwpriv wlan0 authmode $wireless_authmode 
	/sbin/iwpriv wlan0 cipher $wireless_wep_key_length
	/sbin/iwpriv wlan0 wepkeyid 0
	iwpriv wlan0 wepkey $wep_key1
	/sbin/iwpriv wlan0 wepkeyid 1
	iwpriv wlan0 wepkey $wep_key2
	/sbin/iwpriv wlan0 wepkeyid 2
	iwpriv wlan0 wepkey $wep_key3
	/sbin/iwpriv wlan0 wepkeyid 3
	iwpriv wlan0 wepkey $wep_key4
	iwpriv wlan0 defwepkeyid $wireless_wep_index
else 
/sbin/iwpriv wlan0 authmode 0
/sbin/iwpriv wlan0 cipher 0
fi

#change ESSID
/sbin/iwpriv wlan0 essid $wireless_essid


#broadcast
/sbin/iwpriv wlan0 broadcastssid $wireless_essid_broadcast

#channel
/sbin/iwpriv wlan0 channel $wireless_channel
}

zd1211(){
#change mode
/sbin/iwconfig wlan0 mode master
sleep 1

if [ "$wireless_authmode" = "2" ];then
wireless_authmode=1;
fi

#enable wep
echo "zd1211"
if [ "$wep_enabled" = "1" ];then
        /sbin/iwpriv wlan0 set_auth $wireless_authmode 
	/sbin/iwconfig wlan0 key open
	/sbin/iwconfig wlan0 key on
	case $wireless_wep_index
		in
			0)
				/sbin/iwconfig wlan0 key $wep_key1 [1];;
			1)
        			/sbin/iwconfig wlan0 key $wep_key2 [2];;
			2)
				/sbin/iwconfig wlan0 key $wep_key3 [3];;
			3)
				/sbin/iwconfig wlan0 key $wep_key4 [4];;
	esac

else
/sbin/iwconfig wlan0 key off
/sbin/iwpriv wlan0 set_auth $wireless_authmode
fi

#change ESSID
/sbin/iwconfig wlan0 essid $wireless_essid

#channel
/sbin/iwconfig wlan0 channel $wireless_channel

sleep 2
/sbin/iwconfig wlan0 essid $wireless_essid
}

Ralink(){
  if [ "$wireless_authmode" = "2" ];then
    wireless_authmode="SHARED";
  else
    wireless_authmode="OPEN";
  fi

  #enable wep
  if [ "$wep_enabled" = "1" ];then
    if [ "$wep_key1" != "" ];then
        iwpriv wlan0 set Key1=$wep_key1
    fi
    if [ "$wep_key2" != "" ];then
        iwpriv wlan0 set Key2=$wep_key2
    fi
    if [ "$wep_key3" != "" ];then
        iwpriv wlan0 set Key3=$wep_key3
    fi
    if [ "$wep_key4" != "" ];then
        iwpriv wlan0 set Key4=$wep_key4
    fi
    /sbin/iwpriv wlan0 set DefaultKeyID=`expr $wireless_wep_index + 1`
    /sbin/iwpriv wlan0 set EncrypType=WEP
  else
    /sbin/iwpriv wlan0 set EncrypType=NONE
  fi
  /sbin/iwpriv wlan0 set AuthMode=$wireless_authmode

  #change ESSID
  /sbin/iwpriv wlan0 set SSID=$wireless_essid

  #channel
  /sbin/iwpriv wlan0 set Channel=$wireless_channel

  #txpower
  /sbin/iwpriv wlan0 set TxPower=$wireless_txpw

  #broadcast
  if [ $wireless_essid_broadcast -eq 0 ];then
    /sbin/iwpriv wlan0 set HideSSID=1
  else
    /sbin/iwpriv wlan0 set HideSSID=0
  fi
}

WLAN_CARD="zd1211"
WLAN=`cat /proc/bus/pci/devices | grep 17fe2220 | wc -l`
if [ $WLAN = 1 ]; then
   WLAN_CARD="inprocom"
fi
WLAN=`cat /proc/bus/pci/devices | grep 1814030 | wc -l`
if [ $WLAN = 1 ]; then
   WLAN_CARD="Ralink"
fi

case $WLAN_CARD
  in
     "inprocom")
	inprocom;;
     "Ralink")
	Ralink;;
     "zd1211")
	zd1211;;
esac

#udhcpd
if [ -f /var/run/udhcpd_wlan0.pid ]; then
  pidofwlan0=`cat /var/run/udhcpd_wlan0.pid`
  kill -9 $pidofwlan0
  rm -f /var/run/udhcpd_wlan0.pid
fi

if [ "$wireless_dhcp" = "0" ];then
	dns1=`/bin/grep nameserver /etc/resolv.conf | sed -n '1p' |awk '{print $2}'`
	dns2=`/bin/grep nameserver /etc/resolv.conf | sed -n '2p' |awk '{print $2}'`
	dns3=`/bin/grep nameserver /etc/resolv.conf | sed -n '3p' |awk '{print $2}'`
        echo "start      $wireless_startip" > /var/state/udhcpd_wlan0.conf
        echo "end        $wireless_endip" >> /var/state/udhcpd_wlan0.conf
        echo "interface  wlan0" >> /var/state/udhcpd_wlan0.conf
        echo "option     subnet       $wireless_netmask" >> /var/state/udhcpd_wlan0.conf
        echo "opt        router  $wireless_ip" >> /var/state/udhcpd_wlan0.conf
		if [ "$dns1" != "" ];then
		  echo "opt        dns     $dns1" >> /var/state/udhcpd_wlan0.conf
		fi
		if [ "$dns2" != "" ];then
		  echo "opt        dns     $dns2" >> /var/state/udhcpd_wlan0.conf
		fi
	    echo "pidfile    /var/run/udhcpd_wlan0.pid" >> /var/state/udhcpd_wlan0.conf
	    echo "lease_file /var/lib/misc/udhcpd_wlan0.leases" >> /var/state/udhcpd_wlan0.conf
        if [ ! "$dns3" = "" ]; then
        echo "option     dns     "$dns3 >> /var/state/udhcpd_wlan0.conf
        fi
        /usr/sbin/udhcpd /var/state/udhcpd_wlan0.conf
fi

