#!/usr/bin/env bash


PASS=$(python3 -c "import string;import secrets;alphabet = string.ascii_letters + string.digits;print(''.join(secrets.choice(alphabet) for i in range(20)))")

FOLDER=$(mktemp -d)
URL=${1:-0.0.0.0}

cat << EOF
Starting ftp server in $FOLDER, url ftp://ftp:$PASS@$URL:2121
Do not forget to delete $FOLDER afterwards
EOF

cd $FOLDER
[[ -z "$1" ]] && python3 -m pyftpdlib -u ftp -P $PASS || python3 -m pyftpdlib -i $1 -u ftp -P $PASS

