#!/bin/sh
# task_name remote_ip username password
if [ $# -eq 4 ] || [ $# -eq 5 ]; then

vpnpath="/var/run"
/sbin/modprobe tun >/dev/null 2>&1

pidf="${vpnpath}/vpn.$1.pid"
userf="${vpnpath}/vpn.$1.user"
gwf="${vpnpath}/vpn.$1.gw"

if [ -s $pidf ]; then
  kill `cat $pidf` >/dev/null 2>&1
fi
rm -f $pidf
rm -f $userf
rm -f $gwf

echo $3 > $userf
echo $4 >> $userf


/usr/sbin/openvpn --dev tun --persist-tun --persist-key --proto tcp-client \
--keepalive 10 60 --writepid "$pidf" --verb 0 \
--client --comp-lzo --remote "$2" \
--ca /img/bin/openvpn/keys/tmp-ca.crt --cert /img/bin/openvpn/keys/client.crt \
--key /img/bin/openvpn/keys/client.key \
--auth-user-pass "$userf" --persist-local-ip --persist-remote-ip --resolv-retry 3 \
--route-up "/img/bin/openvpn/route_up.sh \"$gwf\" " --daemon

else
  echo "vpn_client.sh task_name remote_ip username password"
fi

