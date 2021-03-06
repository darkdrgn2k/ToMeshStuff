#FLASH i uboot

tftpboot 0x80010000 openwrt-18.06.2-ar71xx-generic-mr16-squashfs-kernel.bin; erase 0xbfda0000 +0x240000; cp.b 0x80010000 0xbfda0000 0x240000; 

tftpboot 0x80010000 openwrt-18.06.2-ar71xx-generic-mr16-squashfs-rootfs.bin; erase 0xbf080000 +0xD20000; cp.b 0x80010000 0xbf080000 0xD20000;  setenv bootcmd bootm 0xbfda0000; saveenv; boot;

# After boot... set mac based on sticker

mtd erase mac
echo -n -e '\x00\x18\x0a\x35\x90\x2c' > /dev/mtd5
sync && reboot



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


### CONFIGURE Settings

MESHID=tomesh
MESHAP=tomesh.net
# AP radio 
APRADIO=0
APIF="wlan0"
#MESH RADIO
MESHRADIO=1
MESHWLAN="wlan1"

WANIF="eth0"

# ------------------------------------------------------
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

#-----

# GENERAL SETUP
# ------------------------------------------------------
# Set hostname
uci set system.@system[0].hostname="NODE$NODEID"

## FIREWALL ## Reset firewall
echo > /etc/config/firewall
uci add firewall defaults
uci set firewall.@defaults[0].syn_flood=1
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'
uci set firewall.@defaults[0].forward='ACCEPT'
uci commit

# REMOVE LAN
uci delete network.lan
uci commit

# SET WAN INTERFACE
uci delete network.wan
uci set network.wan="interface"
uci set network.wan.ifname="$WANIF"
uci set network.wan.proto='dhcp'
uci commit

# BABELD BASIC CONFIG

# Configure babeld
echo  > /etc/babeld.conf 
echo "package babeld" > /etc/config/babeld
echo "config general" >> /etc/config/babeld
echo "    option 'local_port' '999'" >> /etc/config/babeld

### CONFIGURE MESH INTERFACE

# RADIO CONFIGURATION

# Enable radio 5ghz and set channel
uci delete wireless.default_radio$MESHRADIO
uci set wireless.radio$MESHRADIO.disabled=0
uci set wireless.radio$MESHRADIO.channel=161
uci set wireless.radio$MESHRADIO.htmode='HT40'
uci set wireless.radio$MESHRADIO.country='US'
uci set wireless.radio$MESHRADIO.legacy_rates='1'

#WIRELESS
uci delete wireless.Mesh
# Configure MESH (adhoc) as default
uci set wireless.Mesh=wifi-iface
uci set wireless.Mesh.device="radio$MESHRADIO"
uci set wireless.Mesh.mode='adhoc'
uci set wireless.Mesh.ssid="$MESHID"
uci set wireless.Mesh.network="mesh1"
uci commit

#NETWORK
# Configure ip address MESH
uci delete network.mesh1
uci set network.mesh1=interface
uci set network.mesh1.proto='static'
uci set network.mesh1.ipaddr=$IPV4
uci set network.mesh1.netmask='255.255.255.255'
uci commit

# Disable DHCP for MESH
uci delete dhcp.mesh1
uci set dhcp.mesh1=dhcp
uci set dhcp.mesh1.interface="mesh1"
uci set dhcp.mesh1.ignore="1"
uci commit

#BABELD for mesh
# Add access point to babeld
uci set babeld.$MESHIF=interface
uci set babeld.$MESHIF.ifname="$MESHIF"
uci commit

### ACCESS POINT CONFIG


# Enable radio  and set channel
uci delete wireless.default_radio$APRADIO
uci set wireless.radio$APRADIO.disabled=0
uci set wireless.radio$APRADIO.channel=1


# Configure AP 
uci delete wireless.default_radio$APRADIO
uci delete wireless.AP
# Confiure Access Point
uci set wireless.AP=wifi-iface
uci set wireless.AP.device="radio$APRADIO"
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
uci set network.AP.dns="$IPV4"
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
uci set babeld.$APIF=interface
uci set babeld.$APIF.ifname="$APIF"
uci commit

# Announce AP ips on babeld
echo redistribute if $APIF metric 128 >> /etc/babeld.conf
echo redistribute local if $APIF metric 128 >> /etc/babeld.conf
echo redistribute local deny >> /etc/babeld.conf


####################### FAKE_NODE_EXPORTER #######################3

uci set uhttpd.node=uhttpd
uci set uhttpd.node.listen_http='0.0.0.0:9100'
uci set uhttpd.node.home='/www'
uci set uhttpd.node.rfc1918_filter='1'
uci set uhttpd.node.max_requests='3'
uci set uhttpd.node.max_connections='100'
uci set uhttpd.node.script_timeout='60'
uci set uhttpd.node.network_timeout='30'
uci set uhttpd.node.http_keepalive='20'
uci set uhttpd.node.tcp_keepalive='1'
uci set uhttpd.node.cgi_prefix='/metrics'
uci commit
/etc/init.d/uhttpd restart

cat <<"EOF"> /www/metrics
#!/bin/sh
printf "Content-type: text/html\n\n"

for net in /sys/class/net/*; do
   int="$(basename "$net")"
   echo node_network_receive_bytes{device=\"$int\"} $(cat /sys/class/net/$int/statistics/rx_bytes)
   echo node_network_transmit_bytes{device=\"$int\"} $(cat /sys/class/net/$int/statistics/tx_bytes)
   echo node_network_receive_packets{device=\"$int\"} $(cat /sys/class/net/$int/statistics/rx_packets)
   echo node_network_transmit_packets{device=\"$int\"} $(cat /sys/class/net/$int/statistics/tx_packets)
   echo node_network_receive_errs{device=\"$int\"} $(cat /sys/class/net/$int/statistics/rx_errors)
   echo node_network_transmit_errs{device=\"$int\"} $(cat /sys/class/net/$int/statistics/tx_errors)
   echo node_network_receive_drop{device=\"$int\"} $(cat /sys/class/net/$int/statistics/rx_dropped)
   echo node_network_transmit_drop{device=\"$int\"} $(cat /sys/class/net/$int/statistics/tx_dropped)
   
  if [ -d "/sys/class/net/$int/wireless" ]; then
    for ST in $(iw $int station dump | grep Station  | awk '{print $2}')
    do
      mac="$(cat /sys/class/net/$int/address)"
      res=$(iw $int station dump | grep -A 15 $ST | grep rx\ bytes | awk '{print $3}')
      echo mesh_node_rx{sourcemac=\"$mac\",device=\"$int\",target=\"$ST\"} $res
      res=$(iw $int station dump | grep -A 15 $ST | grep tx\ bytes | awk '{print $3}')  
      echo mesh_node_tx{sourcemac=\"$mac\",device=\"$int\",target=\"$ST\"} $res
      res=$(iw $int station dump | grep -A 15 $ST | grep signal\: | awk '{print $2}')  
      echo mesh_node_signal{sourcemac=\"$mac\",device=\"$int\",target=\"$ST\"} $res  
    done
  fi

done
cat /proc/loadavg | awk '{print "node_load1 "$1"\nnode_load5 "$2"\nnode_load15 "$3}'
cat /proc/uptime | awk '{print "node_boot_time "$1}'

EOF
chmod +x /www/metrics


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
