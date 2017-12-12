#!/bin/bash

limit="-60"

cat << 'EOF' > /tmp/mesh.awk 

$1 == "Station" {
    MAC = $2
}
$1 == "signal" {
    wifi[MAC]["signal"] = $3
}
$1 == "mesh" && $2 == "plink:" {
    wifi[MAC]["status"] = $3
}
END {


    for (w in wifi) {
        printf "%s %s %s \n",w,wifi[w]["signal"],wifi[w]["status"]
    }
}
EOF
v=$(iw wlan1 station dump | awk -f /tmp/mesh.awk)
rm /tmp/mesh.awk

printf '%s\n' "$v" | while IFS= read -r line
do
  if [[ "$(echo $line | awk  '{print $2'})" -lt "$limit" ]]; then
        if [[ "$(echo $line | awk  '{print $3'})" == 'ESTAB' ]]; then
                mac="$(echo $line | awk  '{print $1'})"
                iw dev wlan1 station set $mac plink_action block
                echo Blocking $mac Signal TO LOW
        fi
  fi
  if [[ "$(echo $line | awk  '{print $2'})" -gt "$limit" ]]; then
        if [[ "$(echo $line | awk  '{print $3'})" == 'BLOCKED' ]]; then
                mac="$(echo $line | awk  '{print $1'})"
                iw dev wlan1 station set $mac plink_action open
                echo Unblocking  $mac Signal back to normal
        fi
  fi

done

