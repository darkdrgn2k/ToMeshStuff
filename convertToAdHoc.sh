#!/bin/bash

sudo systemctl daemon-reload
sudo systemctl disable hostapd.service
sudo systemctl  stop hostapd.service


cat << 'EOF' > /usr/bin/mesh
#!/bin/bash

set -e

mesh_dev="wlan0"

# Shut down the mesh_dev interface
sudo ifconfig $mesh_dev down

# Convert mesh_dev to 802.11s Mesh Point interface
sudo iw $mesh_dev set type ibss

# Bring up the mesh_dev interface
sudo ifconfig $mesh_dev up

# Optionally assign IPv4 address to the mesh_dev interface
# sudo ifconfig $mesh_dev 192.168.X.Y

# Join the mesh network with radio in HT40+ htmode to enable 802.11n rates
sudo iw dev $mesh_dev ibss join tomesh 2412 HT40+

# Restart cjdns
sudo killall cjdroute
EOF

chmod +x /usr/bin/mesh
 sed -i 's/type mesh point/type IBSS/' /usr/local/bin/status  >status2
