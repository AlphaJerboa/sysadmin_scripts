#!/usr/bin/env bash

OUT_FILE=$(mktemp)

echo "Tracking connection in $OUT_FILE"
trap "cat $OUT_FILE;rm $OUT_FILE; exit" SIGINT
while true
do
    sleep .1
    # netstat -an | grep ESTA | grep -vE "127.0.0.1" | awk '{print $5}' >> $OUT_FILE
    ss -Hutn state established '! src 127.0.0.0/8 and ! src [::1]' | awk '{print $5}' >> $OUT_FILE
    sort -i $OUT_FILE -o $OUT_FILE -u
    clear; cat $OUT_FILE
done
