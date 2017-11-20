#!/bin/sh
apt-get install -y batctl 
modprobe batman-adv

batctl if add wlan0
batctl if add mesh0

cp /etc/cjdroute.conf /etc/cjdroute-bat.conf
sed -i 's/"bind": "all"/ "bind": "bat0"/' /etc/cjdroute-bat.conf 
service cjdns stop
ifconfig bat0 up
cjdroute < /etc/cjdroute-bat.conf


