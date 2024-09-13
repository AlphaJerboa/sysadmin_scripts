#!/bin/bash

TEMP_FILE=$(mktemp)

\cat > $TEMP_FILE << EOF
screen 0
stuff "watch ls -1 /tmp\n"
split
focus down
screen 1
stuff "watch ls /var/log/\n"
focus up
EOF

screen -c $TEMP_FILE
rm $TEMP_FILE
