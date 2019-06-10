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

Run babled `-G 999` or update port

# How it works

## vis
vis shell script will connect to local babeld admin interface and read the `dump` command
it will then parse it into valid xml.

If paramter is passed via command like vis will instead download `/cgi-bin/vis` from specified ip address

vis will augment information by  resolving local mac address information and peered mac address information.  It will also attempte to  prefore a `station dump` and mary TX strength data to links.
# map.html

AJAX pulls /cgi-bin/vis xml file
parses as xml
Draws the map

NODE : Blue
Interfaces  on node : grey
Announced networks: pink
Neighbours: Light green

It will parse known /32 ip addresses and iterate trough them asking for their /cgi-bin/vis data

it will also cross out any /32 addresses it encounters routed (indicating that node already crawled)

As more vis data is downloaded more of the map will apper, expanding light green nodes.
