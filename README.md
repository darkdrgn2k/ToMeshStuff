cjdnsDump.php

Scans cjdns using node list as a white list to find all tomesh nodes and links. Writes a links.json file to be used with the map

cjdnsPING.php

Pings all node list nodes and record rtt in ping.json to be used with the map

prometheusnodes.php

Generates prometheus compatible json file from crawling the tomehs node list and looking for active node exporter ports

Us the following instead of static_configs: - targets:

```
    file_sd_configs:
        - files:
            - "/etc/prometheus.json"
```

