#!/bin/sh
# connect to NODE2 IP Tunnel for internet
key=$(sudo grep -m 1 '"publicKey"' /etc/cjdroute.conf | awk '{ print $2 }' | sed 's/[",]//g')
curl http://[fc6e:691e:dfaa:b992:a10a:7b49:5a1a:5e09]/test.php?key=$key
/opt/cjdns/tools/cexec  "IpTunnel_connectTo('ksdkzmw2uryvkfg187kxmkdup8k78urqzpn29zh1nxvl6wfdbjk0.k')"
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
