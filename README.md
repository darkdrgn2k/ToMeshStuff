# cjdnsDump.php

Scans cjdns using node list as a white list to find all tomesh nodes and links. Writes a links.json file to be used with the map

# cjdnsPING.php

Pings all node list nodes and record rtt in ping.json to be used with the map

# prometheusnodes.php

Generates prometheus compatible json file from crawling the tomehs node list and looking for active node exporter ports

Us the following instead of static_configs: - targets:

```
    file_sd_configs:
        - files:
            - "/etc/prometheus.json"
```


# vis

Dynamically generated js map for cjdnsDump.php


# dual5Ghz.txt

Configuration of second 5ghz card for WIFI

# iptunnel_client.sh


Bash script to request ip tunnel information

# iptunnel_server.php

php script to use client script with



# deb folder

CJDNS in DEB pkg and build scripts

# CJDNS-BIN

CJDNS Bin files incluiding NSA_APPROVED for debugging
