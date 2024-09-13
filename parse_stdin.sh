#!/bin/bash

if [ "$( tty )" == 'not a tty' ]
then
    STDIN_DATA_PRESENT=1
else
    STDIN_DATA_PRESENT=0
fi

if [[ $# -ne 1 && $STDIN_DATA_PRESENT -eq 0 ]]
then
  cat << EOF
Syntax: $0 [FILE (or - for STDIN)]
$0 - Highlight mail issue in FILE
Will also process piped STDIN if no arguments are given.
EOF
  exit 1
fi

while read LINE
do
  echo $LINE
done <<< "$([[ $1 && $1 != "-" ]] && cat "$1" || cat -)"

