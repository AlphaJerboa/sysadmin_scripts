#!/usr/bin/env bash
if [ -p /dev/stdin ]; then
        # read the input line by line
        while IFS= read line; do
                echo $line | perl -pe 's/([^[:print:]\n])/sprintf("<%02X>", ord($1))/ge'
        done
else
	echo "$@" | perl -pe 's/([^[:print:]\n])/sprintf("<%02X>", ord($1))/ge'
fi
