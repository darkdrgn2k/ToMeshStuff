# Installation

place map.html in html root

/var/www/html  or /www

Place vis in cgi-bin and make +x

/var/www/html/cgi-bin  or /www/cgi-bin

For OpenWrt
change `#!/bin/bash` to `#!/bin/sh`
remove `-w 1` in `nc :: 999` line
install uhttpd (opkg install uhttpd)

*NOTE*
Debian NC does not work with ipv6 you need to update to differnt version

Front end currentyl pulls vis.js nad css from CDN
Copy local and update header of map.html for offline use.
