#!/bin/sh
sudo systemctl stop hostapd
sudo systemctl disable hostapd
sudo sed -i s/wlan0/eth0/ radvd.conf
sudo sed -i s/wlan0/eth0/ dnsmasq.conf
sudo sed -i s/eth0/eth1/   /etc/network/interfaces
sudo sed -i s/wlan0/eth0/ /etc/network/interfaces
sudo sed -i s/eth0/tun0/   /etc/hostapd/nat.sh
sudo sed -s 's/exit 0/\/etc\/hostapd\/nat.sh\nexit 0/' /etc/rc.local  
reboot

