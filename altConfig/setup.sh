#!/bin/bash

dialogTitle="TOMesh Prototype Node"

additionalParam="--ascii-lines "
#sudo apt-get install -y dialog

interfaces=$(ls /sys/class/net/)


function removeSection()
{
res=""
    while read -r line
        do

        if [[ "$line" != "$1" ]]; then

                res="$res\n[$line]"

                while read -r line2
                do
                        res="$res\n$line2"
                done < <(confget -f /etc/mesh.conf  -s $line -l)

        fi
        done < <(cat /etc/mesh.conf  | grep "\[" | awk -F "\[" '{print $2}' | awk -F "\]" '{print $1}')
        echo -e $res >/etc/mesh.conf


}


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
        do
                clean=$(echo $line | awk '{print $4}')
                clean=$(echo $clean | tr -d '.')
                list="$list $clean '$line Ghz'"
                if [[ "$intFreq" == "$clean" ]]; then
                list="$list on"

                else
                list="$list off"

                fi
        done < <(iwlist $intSelected frequency | grep Channel | awk '{print "Channel "$2" Freq "$4'})

        eval "dialog --radiolist 'Frequency' 20 51 10 $list "  2>/tmp/res
        intFreq=$(cat /tmp/res)


}

function GetChannel() {
        intFreq=$(confget -f /etc/mesh.conf -s $mac freq)

        list=""
        while read -r line
        do      clean=$(echo $line)
                list="$list $clean 'Chan $line'"
                if [[ "$intFreq" == "$clean" ]]; then
                list="$list on"

                else
                list="$list off"

                fi
        done < <(iwlist $intSelected frequency | grep Channel | awk '{print $2'})

        eval "dialog --radiolist 'Channe' 20 51 10 $list "  2>/tmp/res
        intChan=$(cat /tmp/res)


}

echo $list
MainMenu
SelectType $intSelected
GetSSID



if [ "$intType" == "mesh" ]; then
        GetMeshProtocol
        GetFrequency
        mac=$(getMAC $intSelected)
        removeSection $mac

        echo \[$mac\] >> /etc/mesh.conf
        echo type=$intType  >> /etc/mesh.conf
        echo ssid=$intSSID  >> /etc/mesh.conf
        echo freq=$intFreq   >> /etc/mesh.conf
        echo protocol=$intProtocol  >> /etc/mesh.conf
fi

if [ "$intType" == "ap" ]; then
        mac=$(getMAC $intSelected)
        GetChannel
        removeSection $mac

        echo \[$mac\] >> /etc/mesh.conf
        echo type=$intType  >> /etc/mesh.conf
        echo ssid=$intSSID  >> /etc/mesh.conf
        echo chan=$intChan   >> /etc/mesh.conf

fi
