#FLASH
```
tftpboot 0x80010000 openwrt-18.06.2-ar71xx-generic-mr16-squashfs-kernel.bin; erase 0xbfda0000 +0x240000; cp.b 0x80010000 0xbfda0000 0x240000; 

tftpboot 0x80010000 openwrt-18.06.2-ar71xx-generic-mr16-squashfs-rootfs.bin; erase 0xbf080000 +0xD20000; cp.b 0x80010000 0xbf080000 0xD20000;  setenv bootcmd bootm 0xbfda0000; saveenv; boot;


mtd erase mac
echo -n -e '\x00\x18\x0a\x35\x90\x2c' > /dev/mtd5
sync && reboot


```

### INSTALL PACKAGE -- Configure the network manually to a local ones so new files can be downloaded.  
NETWORKIP=192.168.40.66
GATEWAY=192.168.40.1
#or
NETWORKIP=172.20.4.143
GATEWAY=172.20.4.1
#or
NETWORKIP=10.42.0.111
GATEWAY=10.42.0.1

ifconfig br-lan:1 $NETWORKIP
#or
ifconfig eth0 $NETWORKIP

ip route add 0.0.0.0/0 via $GATEWAY
echo nameserver 8.8.8.8 > /tmp/resolv.conf

opkg update
opkg install babeld iperf3
#---------------------------


### CONFIGURE

MESHID=tomesh
MESHAP=tomesh.net

# OPTIONAL
# Define ip address based on eth0 
mac=$(cat /sys/class/net/eth0/address )
ip2=$(printf "%d" "0x$(echo $mac | cut -f 4 -d \:)")
ip3=$(printf "%d" "0x$(echo $mac | cut -f 5 -d \:)")
ip4=$(printf "%d" "0x$(echo $mac | cut -f 6 -d \:)")
#ip2=$(expr $ip2 % 32 + 96)
#ip4=$(expr $ip4 - $(expr $ip4 % 64 - $ip4 % 32))

IPV4="10.$ip3.$ip4.1"
#IPV4="10.$ip2.$ip3.$ip4"
#IPAP="172.$(expr $ip2 % 16 + 16).$ip3.1"
NODEID=$ip3-$ip4
# ------------------------------------------------------



# ------------------------------------------------------
# Set Name
uci set system.@system[0].hostname="NODE$NODEID"

# Enable radio 2.4 and set channel
uci set wireless.radio0.disabled=0
uci set wireless.radio0.channel=1

# Enable radio 5ghz and set channel
uci set wireless.radio1.disabled=0
uci set wireless.radio1.channel=161
uci set wireless.radio1.htmode='HT40'
uci set wireless.radio1.country='US'
uci set wireless.radio1.legacy_rates='1'


# Unbridge lan from wifi
uci delete network.lan
##config interface 'lan'
uci commit

uci set network.wan.ifname='eth0'
uci commit

uci delete wireless.default_radio1
uci delete wireless.Mesh
# Configure MESH (adhoc) as default
uci set wireless.Mesh=wifi-iface
uci set wireless.Mesh.device='radio1'
uci set wireless.Mesh.mode='adhoc'
uci set wireless.Mesh.ssid="$MESHID"
uci set wireless.Mesh.network="mesh1"
uci commit

# Configure ip address MESH
uci delete network.mesh1
uci set network.mesh1=interface
uci set network.mesh1.proto='static'
uci set network.mesh1.ipaddr=$IPV4
uci set network.mesh1.netmask='255.255.255.255'
uci commit


#-----------
# Meshpoint on 2.4 instaed of mesh (above) on radio0
uci delete wireless.default_radio0
uci delete wireless.Mesh24
# Configure MESH (meshpoint) as default
uci set wireless.Mesh24=wifi-iface
uci set wireless.Mesh24.device='radio0'
uci set wireless.Mesh24.mode='mesh'
uci set wireless.Mesh24.mesh_fwding='0'
uci set wireless.Mesh24.mesh_id="$MESHID"
uci set wireless.Mesh24.network="mesh2"
uci commit
# Configure ip address MESH
uci delete network.mesh24
uci set network.mesh24=interface
uci set network.mesh24.proto='static'
uci set network.mesh24.ipaddr=$IPV4
uci set network.mesh24.netmask='255.255.255.255'
uci commit
#----------end of ap


# Disable DHCP for MESH
uci delete dhcp.mesh1
uci set dhcp.mesh1=dhcp
uci set dhcp.mesh1.interface="mesh1"
uci set dhcp.mesh1.ignore="1"
uci commit


# Configure babeld
echo  > /etc/babeld.conf 
echo "package babeld" > /etc/config/babeld
echo "config general" >> /etc/config/babeld
echo "    option 'local_port' '999'" >> /etc/config/babeld
echo "config interface 'wlan1'" >> /etc/config/babeld
echo "    option 'ifname' 'wlan1'" >> /etc/config/babeld


## FIREWALL ## Reset firewall
echo > /etc/config/firewall
uci add firewall defaults
uci set firewall.@defaults[0].syn_flood=1
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'
uci set firewall.@defaults[0].forward='ACCEPT'
uci commit

# Configure 2.4 Ghz AP 
uci delete wireless.default_radio0
uci delete wireless.AP
# Confiure Access Point
uci set wireless.AP=wifi-iface
uci set wireless.AP.device='radio0'
uci set wireless.AP.encryption='none'
uci set wireless.AP.mode='ap'
uci set wireless.AP.network='AP'
uci set wireless.AP.ssid="$MESHAP"
uci commit

#####AP network
uci set dhcp.@dnsmasq[0].server=1.1.1.1

# Configur AP ip address
uci delete network.AP
uci set network.AP=interface
uci set network.AP.proto='static'
uci set network.AP.ipaddr="$IPV4"
uci set network.AP.'netmask'='255.255.255.0'
uci set network.AP.dns='1.1.1.1'
uci commit

# Configure AP DHCP
uci delete dhcp.AP
uci set dhcp.AP=dhcp
uci set dhcp.AP.interface='AP'
uci set dhcp.AP.start='2'
uci set dhcp.AP.limit='254'
uci set dhcp.AP.leasetime='15m'
uci commit

# Add AP (wlan0) to Babled
# Add access point to babeld
uci set babeld.wlan0=interface
uci set babeld.wlan0.ifname='wlan0'
uci commit

# Announce AP  on babeld
echo redistribute if wlan0 metric 128 > /etc/babeld.conf
echo redistribute local if wlan1 metric 128 >> /etc/babeld.conf
echo redistribute local deny >> /etc/babeld.conf



###### GATEWAY OVER WG #########
# WAN over eth0

uci delete network.wan
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.ifname='eth0'
uci commit

# Create wg
opkg install wireguard
wg genkey > privatekey
#wg pubkey < privatekey > publickey
privatekey=$(cat privatekey)
publickey=$(wg pubkey < privatekey)

uci delete network.wg0
uci set network.wg0=interface
uci set network.wg0.proto='wireguard'
uci set network.wg0.private_key="$privatekey"
uci set network.wg0.listen_port='1234'
uci add_list network.wg0.addresses="$IPV4/32"
nodehex=$(printf '%X\n' $ip3)$(printf '%X\n' $ip4)
uci add_list network.wg0.addresses="fe80::e495:6eff:fe47:$nodehex/64"
uci commit

uci delete network.wireguard_wg0
int=`uci add network wireguard_wg0`
uci set network.$int.public_key='1zR1mOMjfzyEtnJk5eafvKiuh1HdjD7dGJxWVO5mmTA='
uci set network.$int.endpoint_host='199.195.250.209'
uci set network.$int.endpoint_port='51820'
uci set network.$int.persistent_keepalive='30'
uci add_list network.$int.allowed_ips='0.0.0.0/0'
uci add_list network.$int.allowed_ips='::/0'
uci set network.$int.route_allowed_ips=true
uci commit

# Add babeld if to wg0
uci set babeld.wg0=interface
uci set babeld.wg0.ifname='wg0'
uci commit

## wg-quick adds routes. disable it for exit node

## Add ipv spprt


uci delete network.AP.ip6prefix
uci delete network.AP.ip6addr
nodehex=$(printf '%X\n' $ip3)$(printf '%X\n' $ip4)

uci set network.AP.ip6prefix="2001:470:b384:$nodehex:0:0:0:0/64"
uci add_list network.AP.ip6addr="2001:470:b384:$nodehex:0:0:0:1/64"
uci set network.lan.ra_management='1'
uci set network.lan.dhcpv6='server'
uci set network.lan.ra='server'
uci set network.AP.ra='server'
uci commit


###
#MR16

cat <<"EOF"> /usr/bin/leds
#!/bin/ash

while [ 1 ]; do
high=-99
low=0

for i in $( iw wlan1 station dump | grep signal\: | awk '{print $2}' )
   do
     if [ "$i" -ge "$high" ]; then
         high=$i
     fi
     if [ "$i" -le "$low" ]; then
         low=$i
     fi
   done


echo $(if [ $high -ge -40 ]; then echo 1; else echo 0; fi) > /sys/class/leds/mr16\:green\:wifi4/brightness
echo $(if [ $high -ge -55 ]; then echo 1; else echo 0; fi) > /sys/class/leds/mr16\:green\:wifi3/brightness
echo $(if [ $high -ge -75 ]; then echo 1; else echo 0; fi) > /sys/class/leds/mr16\:green\:wifi2/brightness
echo $(if [ $high -ge -80 ]; then echo 1; else echo 0; fi) > /sys/class/leds/mr16\:green\:wifi1/brightness

echo $(if [ -z "$(iw dev wlan0 station dump)" ]; then echo 0; else echo 1; fi) > /sys/class/leds/mr16:orange:power/brightness

sleep 1
done
EOF
chmod +x /usr/bin/leds
cat <<"EOF"> /etc/rc.local
#!/bin/sh
/usr/bin/leds &
exit 0
EOF
chmod +x /etc/rc.local
#TPLINK
cat <<"EOF"> /usr/bin/leds
#!/bin/ash

while [ 1 ]; do
high=-99
low=0

for i in $( iw wlan0 station dump | grep signal\: | awk '{print $2}' )
   do
     if [ "$i" -ge "$high" ]; then
         high=$i
     fi
     if [ "$i" -le "$low" ]; then
         low=$i
     fi
   done

echo $(if [ $high -ge -40 ]; then echo 255; else echo 0; fi) > /sys/class/leds/tp-link\:blue\:signal5/brightness
echo $(if [ $high -ge -50 ]; then echo 255; else echo 0; fi) > /sys/class/leds/tp-link\:blue\:signal4/brightness
echo $(if [ $high -ge -60 ]; then echo 255; else echo 0; fi) > /sys/class/leds/tp-link\:blue\:signal3/brightness
echo $(if [ $high -ge -70 ]; then echo 255; else echo 0; fi) > /sys/class/leds/tp-link\:blue\:signal2/brightness
echo $(if [ $high -ge -80 ]; then echo 255; else echo 0; fi) > /sys/class/leds/tp-link\:blue\:signal1/brightness

echo $(if [ -z "$(iw dev wlan0-1 station dump)" ]; then echo 0; else echo 255; fi) > /sys/class/leds/tp-link\:blue\:re/brightness

sleep 1
done
EOF
chmod +x /usr/bin/leds
cat <<"EOF"> /etc/rc.local
/usr/bin/leds
exit 0
EOF
