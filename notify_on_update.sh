#!/bin/bash

# Run a command and check output updates, use notify-send on any line output change

CMD_TO_CHECK="$1"
TYPE=${2:-normal}

MYSELF="$(basename "$0")"

[[ -z $CMD_TO_CHECK ]] && /bin/cat << EOF && exit 0
$0 <cmd_to_check> <notification_type=(low,normal,critical)
EOF

SCRIPT_NAME=$(basename $CMD_TO_CHECK | /bin/sed 's/[\._-]//g')

TRACKING_DIR="/tmp/${MYSELF%.sh}"
TRACKING_FILE="$TRACKING_DIR/$SCRIPT_NAME"
[[ ! -f $TRACKING_FILE ]] && mkdir -p $TRACKING_DIR && echo "First run : creating $TRACKING_FILE" && $CMD_TO_CHECK > $TRACKING_FILE && exit 0 # First occurence, create file

TMP_FILE=$(/bin/mktemp)
$CMD_TO_CHECK > $TMP_FILE

# Keep only add in the second file
# Why perfer diff : comm requires sorted files
DIFF=$(diff --changed-group-format='%>' --unchanged-group-format='' $TRACKING_FILE $TMP_FILE)

[[ -z "$DIFF" ]] && echo "No update found" && rm $TMP_FILE && exit 0

date
echo "=== New updates ==="
echo "$DIFF"
echo "==================="
echo "Sending notification for update found"

# DBUS_SESSION_BUS_ADDRESS needs to be exported to be able to run notify-send via cron
MYUSER=$(/usr/bin/whoami)
NAUTILUS_PID=$(pgrep -u $MYUSER nautilus)
MYDBUS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$NAUTILUS_PID/environ | /bin/sed 's/DBUS_SESSION_BUS_ADDRESS=//' )
export DBUS_SESSION_BUS_ADDRESS=$MYDBUS

[[ $(echo "$DIFF" | wc -l ) -gt 5 ]] && /usr/bin/notify-send -u "$TYPE" "Multiples updates on $SCRIPT_NAME" "$DIFF" && /bin/cat $TMP_FILE > $TRACKING_FILE && rm $TMP_FILE && exit 0

while read -r L_DIFF
do
  SUBJECT="$(echo "$L_DIFF" | /usr/bin/awk '{print $1}' | sed 's@http[s]*://\(.*\).xxxxxxxxx.c[omh]\+/issues/\([0-9]\+\)@\1 #\2@')"
  BODY="$(echo "$L_DIFF" | /usr/bin/awk '{$1="";print $0}' | sed 's/^[-,_;\[:space:]]*\(.*\)$/\1/')"
  /usr/bin/notify-send -u "$TYPE" "$SUBJECT" "$BODY"
done <<< "$DIFF"


/bin/cat $TMP_FILE > $TRACKING_FILE
/bin/rm $TMP_FILE
