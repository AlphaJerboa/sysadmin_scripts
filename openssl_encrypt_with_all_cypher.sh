#!/bin/bash

TMP=$(mktemp)
echo -n password > $TMP
CIPHERS=$(openssl enc -ciphers | sed "s/ /\n/g" | grep "^-")

for CIPHER in $CIPHERS;do
  echo == $CIPHER ==
  openssl enc $CIPHER -salt -in $TMP -out - -k secret
  echo
done
