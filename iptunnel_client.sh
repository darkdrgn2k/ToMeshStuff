#!/bin/sh
# connect to NODE2 IP Tunnel for internet
key=$(sudo grep -m 1 '"publicKey"' /etc/cjdroute.conf | awk '{ print $2 }' | sed 's/[",]//g')
curl http://[fc96:47e7:2115:dffa:d406:8765:e260:5a72]/api/api.php?key=$key
/opt/cjdns/tools/cexec  "IpTunnel_connectTo('kb2j7m6rqv3lyt5xm0zz4g8jfdc2qws1kdf8fb8wyjs2ysqbfr30.k')"
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
