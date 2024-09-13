#!/usr/bin/env bash

# ########################################
# Goal: This script will:
# - Generate gpg key and subkeys
# - Passphrase will be stored in KeepassXC if available
# - Import the subkeys in an Yubikey
# - Export a public key for ssh auth
# - Setup git to use the new signin key

# ########################################

set -o pipefail # Do not remove it

KPRI_EXPIRE=5y
KSEC_EXPIRE=3y
KPASS_GROUP_NAME="/GPG"
KPASS_KEY_NAME="master_private_key" 
GPG_HOME_DIR=${GNUGHOME:-~/.gnupg}
GPG_CMD="gpg --homedir $GPG_HOME_DIR"


log_message() {
    local message="$1"
    local log_level="$2"

    local color=""
    local icon=""

    case "$log_level" in
        title)
            color="\e[32m"  # Green
            icon='' 
            ;;
        info)
            color="\e[33m"  # Yellow
            icon="👉" 
            ;;
        warn|warning)
            color="\e[91m"  # Orange
            icon="⚠️ "
            ;;
        crit|critical)
            color="\e[31m"  # Red
            icon="🚫"
            ;;
        done)
            color="\e[32m"  # Green
            icon="✅"
            ;;
        input)
            color="\e[34m"  # Blue
            icon="🗪 "
            ;;
        *)
            echo "Invalid log level: $log_level"
            return 1
            ;;
    esac

    # Reset color after the message
    local reset_color="\e[0m"

    echo -e "${color}${icon} ${message}${reset_color}"
}

user_mail=$1
[[ ! "$user_mail" =~ [a-z]+@[a-z0-9].com ]] && cat << EOF && exit 1
Usage: $0 <username@company.com>
EOF

log_message "# ###########" "title"
log_message "# GPG SETUP #" "title"
log_message "# ###########" "title"

# Checking if gpg and a setup  is already present
if command -v gpg >/dev/null 2>&1; then
    log_message "gpg is present" "info"
    if $GPG_CMD -K 2>/dev/null | grep -q "uid.*\b$user_mail"; then
        log_message "You have already a gpg setup for the email $user_mail do not use this script" "critical"
        exit 1
    fi
else
    sudo apt-get install gpg
fi

log_message "Please exit any other gpg interactive session during this installation process" "warn"
echo

# Checking GPG algo support
! gpg --version | grep -qi ECDSA && log_message "Your GPG version do not support ECDSA algo !" "critical" && exit 1

# Use keepassxc to store the GPG passphrase or prompt the user for it
if command -v keepassxc-cli >/dev/null 2>&1; then
    log_message "keepassxc-cli is present, looking for existing databases" "info"
    # Getting the list of recent keepassXC opened database
    DB_PATH_LIST=$(grep LastOpenedDatabases ~/.cache/keepassxc/keepassxc.ini | awk -F '[=,]' -v 'OFS=\t' '{$1="";print $0}')
    log_message "Here is the list of keepassXC database found:" "info"
    for DB_PATH in $DB_PATH_LIST
    do
        echo "- $DB_PATH"
    done
    # Prompting the user to enter the path of database I want to use to store the GPG passphrase
    log_message "Please enter the path of the database you want to use to store your private GPG passphrase:" "input"
    read KPASS_DB
    # Prompting user to get the keepassXC passphrase
    # Keeping it in a variable, to avoid passphrase prompt at each call of keepassxc-cli 
    if [[ -f $KPASS_DB ]];then
        log_message "Enter your password to unlock $KPASS_DB:" "input"
        read -s KPASS_PW
        echo
        # Create a new group and a new entry in keepassXC
        if echo "$KPASS_PW" | keepassxc-cli mkdir $KPASS_DB $KPASS_GROUP_NAME >/dev/null 2>&1 && echo "$KPASS_PW" | keepassxc-cli add -g --lower --upper --numeric --length 32 $KPASS_DB $KPASS_GROUP_NAME/$KPASS_KEY_NAME >/dev/null 2>&1;then
            # Getting the GPG passphrase auto-generated
            KPRI_PASS=$(set -o pipefail;echo "$KPASS_PW" | keepassxc-cli show -s $KPASS_DB $KPASS_GROUP_NAME/$KPASS_KEY_NAME 2>/dev/null | awk '$1 == "Password:" {print $2}')
            if [[ $? -gt 0 ]];then
                log_message "Unable to retrieve passphrase from your keepassXC database" "critical"
            else
                log_message "Your GPG passphrase has been succesfully saved in your keepassXC" "done"
            fi
        else
            log_message "Unable to add entry in keepassXC database $KPASS_DB" "critical"
        fi
    else
        log_message "Unable to open KeepassXC database $KPASS_DB" "critical"
    fi
else
    log_message "keepassxc-cli is missing" "warn"
fi

# If the GPG passphrase has not been generated and stored in KeepassXC, prompt the user to enter one and request him to store it securely
if [[ -z "$KPRI_PASS" ]]; then
    KPASSXC_WORKING=1
    log_message "Unable to use KeepassXC, defaulting to password prompt" "info"
    log_message "Please enter a complex passphrase to protect your GPG private key, store it in a VERY secure way !!!!" "input"
    read KPRI_PASS
    log_message "Store this passphrase in a VERY secure way !!!!" "warn"
    log_message "and press any key to continue" "input"
    read k
else
    KPASSXC_WORKING=0
fi

# Generate primary key
log_message "Primary key generation !" "info"
$GPG_CMD --batch --passphrase "$KPRI_PASS" --quick-generate-key $user_mail ed25519 sign $KPRI_EXPIRE &>/dev/null

# Get Primary fingerprint
KPRI_FINGERPRINT=$($GPG_CMD -K --list-options show-only-fpr-mbox $user_mail | awk '{print $1}')
[[ ! "$KPRI_FINGERPRINT" =~ ([A-F0-9]{40}) ]] && log_message "Primary key not found, error during generation" "critical" && exit 1
log_message "Your primary key has been successfully generated" "done"

# Add a Subkey for authentication
log_message "Creation of a subkey for authentication" "info"
$GPG_CMD -v --batch --passphrase "$KPRI_PASS" --pinentry-mode loopback --quick-add-key $KPRI_FINGERPRINT ed25519 auth $KSEC_EXPIRE &>/dev/null

# Add a Subkey for sign
log_message "Creation of a subkey for signin" "info"
$GPG_CMD -v --batch --passphrase "$KPRI_PASS" --pinentry-mode loopback --quick-add-key $KPRI_FINGERPRINT ed25519 sign $KSEC_EXPIRE &>/dev/null

# Add a Subkey for encryption ed25519 not supported yet
log_message "Creation of a subkey for encryption" "info"
$GPG_CMD -v --batch --passphrase "$KPRI_PASS" --pinentry-mode loopback --quick-add-key $KPRI_FINGERPRINT rsa4096 encr $KSEC_EXPIRE &>/dev/null


# Get all subkey ID
# https://github.com/gpg/gnupg/blob/master/doc/DETAILS
KSEC_S_ID=$($GPG_CMD -K --with-colons $user_mail | awk -F: '$1=="ssb" && $2!="e" && $12=="s" {print $5}')
KSEC_A_ID=$($GPG_CMD -K --with-colons $user_mail | awk -F: '$1=="ssb" && $2!="e" && $12=="a" {print $5}')
KSEC_E_ID=$($GPG_CMD -K --with-colons $user_mail | awk -F: '$1=="ssb" && $2!="e" && $12=="e" {print $5}')

# Checking all subkey
[[ -z "$KSEC_S_ID" ]] && log_message "Subkey for signin is missing !" "crit" && exit 1
[[ -z "$KSEC_A_ID" ]] && log_message "Subkey for authentication is missing !" "crit" && exit 1
[[ -z "$KSEC_E_ID" ]] && log_message "Subkey for encryption is missing !" "crit" && exit 1
log_message "All subkeys has been successfully generated" "done"

# Backup primary private key before its deletion
GPG_KEY_FILE=$(mktemp)
$GPG_CMD -v --batch --passphrase "$KPRI_PASS" --pinentry-mode loopback -a --armor --export-secret-key $KPRI_FINGERPRINT > $GPG_KEY_FILE 2>/dev/null
if [[ ! -s $GPG_KEY_FILE ]];then
    log_message "Unable to export private key !" "critical"
else
    # If keepassXC is working, use import key in keepassxc else prompt the user to backup it
    if [[ $KPASSXC_WORKING == 0 ]];then
        
        # Save the primary key in keepassxc
        echo "$KPASS_PW" | keepassxc-cli attachment-import $KPASS_DB $KPASS_GROUP_NAME/$KPASS_KEY_NAME private_key.asc $GPG_KEY_FILE 2>/dev/null
        
        # Test for successful import
        GPG_KEY=$(echo "$KPASS_PW" | keepassxc-cli attachment-export $KPASS_DB $KPASS_GROUP_NAME/$KPASS_KEY_NAME private_key.asc --stdout 2>/dev/null)
    
        if echo "$GPG_KEY" | grep -q -e "-\+BEGIN.*PRIVATE.*KEY.*-\+" && [[ ${#GPG_KEY} -gt 1000 ]];then
            log_message "Your private key has been successfully imported in your KeepassXC" "done"
            GPG_KEY_SAVED=0
        else
            log_message "The import of your private key in your keepassXC database has failed" "crit"
            GPG_KEY_SAVED=1
        fi
    else
        GPG_KEY_SAVED=1
    fi
    
    if [[ $GPG_KEY_SAVED != 0 ]];then
        log_message "Please keep of a backup of your private primary key in a VERY secure place" "warn"
        log_message "You may store it in an offline encrypted media for instance" "warn"
        cat $GPG_KEY_FILE
        log_message "Press any key once you have saved your private key" "input"
        read k
    fi

fi
# Remove the temporary file containing the private key !!!
rm -f $GPG_KEY_FILE
# Unset the Keepassxc passphrase !!!
unset KPASS_PW

# Getting the keygrip id of your primary key
KPRI_KEYGRIP=$($GPG_CMD -K --with-keygrip $user_mail | grep -Pom1 '^ *Keygrip += +\K.*')

# Remove the primary key
KPRI_PATH="$GPG_HOME_DIR/private-keys-v1.d/$KPRI_KEYGRIP.key"
if [[ -f $KPRI_PATH ]]; then
    log_message "Removing your private key $KPRI_PATH" "info"
    rm $KPRI_PATH
else
    log_message "Unable to find the location of your private key file" "crit"
    log_message "Please remove it manually, and press any key once ok" "input"
    read k
fi
# Remove secring if it exist
[[ -s $GPG_HOME_DIR/secring.gpg ]] && rm $GPG_HOME_DIR/secring.gpg

if ! $GPG_CMD -K $user_mail | grep -q "sec#";then
    log_message "Your primary private key has not been removed !!!" "crit"
    log_message "Please remove it manually" "warn"
else
    log_message "Your primary private key has been removed successfully" "done"
    #FIXME Change passphrase for the subkeys
    # gpg --batch --pinentry-mode loopback --passwd ...
fi

log_message "Your GPG setup is completed !" "info"
echo
echo
#
# GPG configuration is now done
# It is time for yubikey setup
#
log_message "# ################" "title"
log_message "# YUBIKEY IMPORT #" "title"
log_message "# ################" "title"

log_message "Please insert your yubikey !" "info"
echo
log_message "Press any key once you are ready" "input"
read k
echo


# Testing if an yubikey is detected
echo
GPG_OUTPUT="$($GPG_CMD --card-status 2>/dev/null)"
if [[ $? != 0 ]] ; then
    log_message "No Yubikey found, exiting" "crit"
    log_message "Please import your subkeys manually" "info"
else
    log_message "Yubikey detected" "info"

    # Checking if there is already any key imported in the yubikey
    if echo "$GPG_OUTPUT" | grep -P "(Signature key|Encryption key|Authentication key)[ .]*: [A-Z0-9 ]+$";then
        log_message "Your yubikey already stores some keys, this script won't overwrite them !" "crit"
        log_message "Please import your new subkeys manually if you like so" "info" 
    else

        # Find the subkey order, to select subkey type accordingly
        SUBKEY_TYPE_LIST=$($GPG_CMD -K $KPRI_FINGERPRINT 2>/dev/null | sed -n "/^ssb/ s/.*\[\([ASEC]\)\].*/\1/p")
        SUBKEY_INDEX=1
        if [[ "$SUBKEY_TYPE_LIST" =~ ^[ASEC[:space:]]\+$ ]];then
            log_message "Unable to retrieve your subkey's type list" "crit"
        fi

        log_message "You will have to enter the admin PIN of your yubikey" "info"
        log_message "If you haven't configured your yubikey yet :" "info"
        echo
        log_message "The default PIN is : 123456" "info"
        log_message "The default admin PIN is : 12345678" "info"
        echo

        for SUBKEY_TYPE in $SUBKEY_TYPE_LIST
        do
            case $SUBKEY_TYPE in
            A) SELECTION=3;;
            E) SELECTION=2;;
            S|SC) SELECTION=1;;
            *) log_message "Unknown subkey type found: $SUBKEY_TYPE" "crit";SELECTION=1;;
            esac

            log_message "Writing subkey $SUBKEY_INDEX [$SUBKEY_TYPE] to yubikey" "info"
            # Push subkey to yubikey
            # Based on https://github.com/brucify/g/blob/main/g
            # The --command-fd 0 option instructs gpg2 to read commands from file descriptor 0, 
            # which is the pipe that receives the commands from printf.
            printf "key $SUBKEY_INDEX\nkeytocard\n$SELECTION\ny\nsave\n" | $GPG_CMD --batch --command-fd 0 --edit-key $KPRI_FINGERPRINT &>/dev/null 2>&1

            SUBKEY_INDEX=$((SUBKEY_INDEX+1))
        done


        # Checking that each subkey has been push to the yubikey
        GPG_OUTPUT=$($GPG_CMD -K)
        ! echo "$GPG_OUTPUT" | grep -q "ssb>.*[A]" && log_message "Subkey for authentication has not been pushed on your Yubikey !" "warn" || log_message "Subkey for authentication has been pushed on your Yubikey" "done"

        ! echo "$GPG_OUTPUT" | grep -q "ssb>.*[S]" && log_message "Subkey for signin has not been pushed on your Yubikey !" "warn" || log_message "Subkey for signin has been pushed on your Yubikey" "done"
        ! echo "$GPG_OUTPUT" | grep -q "ssb>.*[E]" && log_message "Subkey for encryption has not been pushed on your Yubikey !" "warn" || log_message "Subkey for encryption has been pushed on your Yubikey" "done"
        echo
    fi
fi

# Export SSH public key
# Do not force it use
# We are not exporting keys for PGP mail sign/encr
# to avoid exposing plain-text private key in a file
echo
log_message "# #############" "title"
log_message "# KEYS EXPORT #" "title"
log_message "# #############" "title"

if [[ "$KSEC_A_ID" =~ ^[A-F0-9]+$ ]];then
    SSH_KEY_NAME=~/.ssh/yk_${user_mail%@*}.pub
    log_message "Generating ssh public key for authentication $SSH_KEY_NAME" "info"
    $GPG_CMD -o $SSH_KEY_NAME --export-ssh-key $KSEC_A_ID && log_message "SSH public key exported in $SSH_KEY_NAME" "done"
else
    log_message "Unable to find your subkey for authentication" "crit"
fi

echo
log_message "# ############" "title"
log_message "# GIT CONFIG #" "title"
log_message "# ############" "title"

# If user is using git, add the signin key in the git configuration
if command -v git >/dev/null 2>&1; then
    CURRENT_GIT_S_KEY=$(git config --get user.signingkey 2>/dev/null)
    # If the user has no signin key already defined, use the new one
    if [[ -z ${#CURRENT_GIT_S_KEY} ]];then
        if [[ "$KSEC_S_ID" =~ ^[A-F0-9]+$ ]];then
            echo
            log_message "Updating your git config to use your new signin key" "info"
            git config --global --user.signingkey $KSEC_S_ID && log_message "GIT signin key setup done" "done"
        else
            log_message "Unable to find your subkey for Signin" "crit"
        fi
    else
        log_message "You have already a signin key defined $CURRENT_GIT_S_KEY in your GIT configuration" "warn"
        log_message "You may update your git configuration to use your new signin key if you like" "info"
        log_message "To do so, run : git config --global --user.signingkey $KSEC_S_ID" "info"
    fi
fi

unset KPRI_PASS

# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
