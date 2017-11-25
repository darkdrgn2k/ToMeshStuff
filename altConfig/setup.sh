#!/bin/bash

dialogTitle="TOMesh Prototype Node"

additionalParam="--ascii-lines "
#sudo apt-get install -y dialog

interfaces=$(ls /sys/class/net/)

function getMAC()
{
        if [[  $1 != '' ]]; then

                cat /sys/class/net/$1/address | tr -d '\n' 
        fi
}

function MainMenu() {

        list=""

        for interface in $interfaces; do

                if [[ ! $interface == 'lo' ]] && [[ ! $interface == 'tun0' ]]; then

                mac=$(getMAC $interface)
                type=$(confget -f /etc/mesh.conf -s $mac type)
                if [[ ! -z "$mac" ]]; then
                        list="$list $interface '$mac $type'"
                fi
        fi



        done
        eval "dialog --menu 'Select interface to configure' 20 51 19 $list"  2> /tmp/res
        intSelected=$(cat /tmp/res)
}


function SelectType() {
        local int=$1;
        eval "dialog --menu 'Set Interface Type ' 20 51 19 none NONE ap AP mesh MESH"  2>/tmp/res
        intType=$(cat /tmp/res)
}
function GetSSID() {
        intSSID=$(confget -f /etc/mesh.conf -s $mac ssid)
       dialog --inputbox "SSID $(intSelected)" 20 51 $intSSID  2>/tmp/res
       intSSID=$(cat /tmp/res)
}
function GetMeshProtocol() {
        intProtocol=$(confget -f /etc/mesh.conf -s $mac protocol)
        list="";
        if [[ $intProtocol == '80211s' ]]; then
                list="80211s 802.11s on adhoc AdHoc off"
        else
                list="80211s 802.11s off adhoc AdHoc on"

        fi
        eval "dialog --radiolist 'Mesh Protocol' 20 51 4 $list "  2>/tmp/res
        intProtocol=$(cat /tmp/res)

}
function GetFrequency() {
        intFreq=$(confget -f /etc/mesh.conf -s $mac freq)

        list=""
        while read -r line
        do      clean=$(echo $line | tr -d '.')
                list="$list $clean '$line Ghz'"
                if [[ "$intFreq" == "$clean" ]]; then
                list="$list on"

                else
                list="$list off"

                fi
        done < <(iwlist wlan0 frequency | grep Channel | awk '{print $4'})

        eval "dialog --radiolist 'Frequency' 20 51 10 $list "  2>/tmp/res
        intFreq=$(cat /tmp/res)


}

MainMenu
SelectType $intSelected
GetSSID


#if [[ "$intType" == "mesh" ]]; then
#echo 1
        GetMeshProtocol
#fi

GetFrequency

echo \[$mac\]
echo type=$intType
echo ssid=$intSSID
echo freq=$intFreq
echo protocol=$intProtocol


