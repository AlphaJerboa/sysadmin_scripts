NOTIF_USER=user
NOTIF_UID=1000

sudo -u $NOTIF_USER DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$NOTIF_USERID/bus notify-send -u critical "Problem !"
