#!/bin/bash

[[ -f ~/mygit/various_scripts/include_bash_function.sh ]] && . ~/mygit/various_scripts/include_bash_function.sh

IPV6="$1"

EXTENDED_IPV6=$(sipcalc -6 "$IPV6" | grep "Expanded Address" | cut -f 2 -d '-')

EXTENDED_IPV6_6_7=$(echo $EXTENDED_IPV6 | cut -f 6-7 -d ':')
[[ "$EXTENDED_IPV6_6_7" =~ [0-9a-f]{2}ff:fe[0-9a-f]{2} ]] || die "$IPV6 is not an EUI-64" 1

# Special Bit mask to apply on first Octet
MAC_1=$(echo $EXTENDED_IPV6 | cut -f 5 -d ':' | cut -b 1-2)
# MAC_1 : Special bit mask to apply on first octet
MAC_1="??"
MAC_2=$(echo $EXTENDED_IPV6 | cut -f 5 -d ':' | cut -b 3-4)
MAC_3=$(echo $EXTENDED_IPV6 | cut -f 6 -d ':' | cut -b 1-2)
MAC_4=$(echo $EXTENDED_IPV6 | cut -f 7 -d ':' | cut -b 3-4)
MAC_5=$(echo $EXTENDED_IPV6 | cut -f 8 -d ':' | cut -b 1-2)
MAC_6=$(echo $EXTENDED_IPV6 | cut -f 8 -d ':' | cut -b 3-4)

MAC="$MAC_1:$MAC_2:$MAC_3:$MAC_4:$MAC_5:$MAC_6"

echo "[EUI64] $IPV6 --> [MAC] $MAC"
