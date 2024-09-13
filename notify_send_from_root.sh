#!/bin/bash

# Display X output to another session. Might be needed also when running X command via cron (no tty)

X_USER=$(w | grep tty | awk '{print $1}' | head -n1)
NAUTILUS_PID=$(pgrep -u $X_USER nautilus)
MYDBUS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$NAUTILUS_PID/environ | /bin/sed 's/DBUS_SESSION_BUS_ADDRESS=//' )
sudo -u $X_USER DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=$MYDBUS notify-send 'Hello $X_USER' 'This is an notification from Root.'
