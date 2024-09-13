#!/bin/bash

IPV6="$1"

MAC=$(ip nei sh | grep -F "$IPV6" | sed "s/.*dev.*\([0-9a-f]\{2\}:[0-9a-f]\{2\}:[0-9a-f]\{2\}:[0-9a-f]\{2\}:[0-9a-f]\{2\}:[0-9a-f]\{2\}\).*/\1/g" | xargs | tr ' ' '|')

[[ -z $MAC ]] && echo "$IPV6 not found" || ip nei sh | grep -E $MAC
