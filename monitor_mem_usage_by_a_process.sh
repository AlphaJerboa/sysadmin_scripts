#!/usr/bin/env bash

# Retrieve PSS, which is more accurate then RSS
# RSS :  total memory actually held in RAM for a process, this total includes all of the shared libraries 
# PSS :  proportional size of its shared libraries

[[ -z "$1" ]] && echo "Usage: $0 <process_name>" && exit 1

pgrep "$1" | while read pid; do grep -i ^pss /proc/$pid/smaps |  awk -v p=$pid '{Total+=$2} END {print p ":" Total/1024" MB"}';done
