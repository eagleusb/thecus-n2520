#!/bin/sh 
# network netmask
## OpenVPN will listen on port 1194

pidf="/var/run/openvpn.pid"
openvpn_start() {
echo -n $"Starting openvpn: "

/sbin/modprobe tun >/dev/null 2>&1

if [ -s $pidf ]; then
  kill `cat $pidf` >/dev/null 2>&1
fi
rm -f $pidf

if [ "$1" != "" ] && [ "$2" != "" ]; then

/usr/sbin/openvpn --dev tun --persist-tun --persist-key --proto tcp-server \
--keepalive 10 60 --verb 0 --writepid $pidf \
--client-cert-not-required --username-as-common-name \
--mode server --comp-lzo \
--server $1 $2 --duplicate-cn \
--auth-user-pass-verify /img/bin/openvpn/auth.sh via-env \
--tls-server --dh /img/bin/openvpn/keys/dh1024.pem --ca /img/bin/openvpn/keys/tmp-ca.crt \
--cert /img/bin/openvpn/keys/server.crt --key /img/bin/openvpn/keys/server.key --daemon

if [ $? = 0 ]; then
  echo "success"
else
  echo "failure"
fi

else
  echo "vpn_server.sh start network netmask"
fi

}

openvpn_stop() {
echo -n $"Shutting down openvpn: "

if [ -s $pidf ]; then
  kill `cat $pidf` >/dev/null 2>&1
fi
rm -f $pidf

echo "success"
}

case "$1" in
   'start')
      openvpn_start $2 $3
      ;;
   'stop')
      openvpn_stop
      ;;
   *)
      echo "usage $0 start network netmask|stop"
      ;;
esac

