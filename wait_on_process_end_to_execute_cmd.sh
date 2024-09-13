#!/bin/bash

set -x 
PROCESS_TO_WAIT="$1"
PROC_FILE=/proc/$(pgrep $PROCESS_TO_WAIT | head -n1)
shift

while [ -e $PROC_FILE ];do sleep 5;done;$@
