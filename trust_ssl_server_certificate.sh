#!/bin/bash

URL="$1" # Such as nas-ha.synology.me:5006
TEMPFILE=$(mktemp)
CERT_DIR="/usr/share/ca-certificates/mytrust"
CERT_NAME="$(echo $URL | tr -dc '[:alnum:]\n\r').crt"

openssl s_client -showcerts -connect "$1"  < /dev/null 2>/dev/null | openssl x509 -text |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $TEMPFILE

echo "Certificate found :"
openssl x509 -in $TEMPFILE -noout -text

sudo mkdir -p $CERT_DIR 
sudo cp $TEMPFILE $CERT_DIR/$CERT_NAME

rm $TEMPFILE

sudo dpkg-reconfigure ca-certificates
