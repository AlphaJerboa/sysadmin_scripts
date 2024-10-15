#!/usr/bin/env bash

# Find script directory location
pushd . > '/dev/null';
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}";

while [ -h "$SCRIPT_PATH" ];
do
    cd "$( dirname -- "$SCRIPT_PATH"; )";
    SCRIPT_PATH="$( readlink -f -- "$SCRIPT_PATH"; )";
done

cd "$( dirname -- "$SCRIPT_PATH"; )" > '/dev/null';
SCRIPT_PATH="$( pwd; )";
popd  > '/dev/null';


# Load settings
CONF_INI="$SCRIPT_PATH/config.ini"
[[ -f $CONF_INI ]] && . $CONF_INI

# check settings definition
[[ -z "$VAULT_ADDR" || -z "$ROLE" || -z "$PRINCIPAL" || -z "$SSH_PUB_FILE" ]] && cat << EOF && exit
Usage: $0 

Following Parameters must be defined in $CONF_INI file
VAULT_ADDR="https://<openbao_url>"
ROLE=<rolename>
PRINCIPAL=<principalname>
SSH_PUB_FILE=<path_to_public_ssh_key>
EOF

# Record SSH arguments
SSH_ARGS=$@

sign_key(){
  VAULT_ADDR=${VAULT_ADDR:-https://127.0.0.1} bao write -field=signed_key ssh/sign/${ROLE} public_key="$(cat ${SSH_PUB_FILE})" valid_principals=${PRINCIPAL} > $SIGNED_SSH_PUB_FILE
  login_w_key
}

login_w_key(){
  ssh -i $SIGNED_SSH_PUB_FILE $SSH_ARGS
}

# Check public file access
[[ ! -f $SSH_PUB_FILE ]] && echo "Unable to load $SSH_PUB_FILE" && exit 1


# Check if a signed already exist
if [[ -f $SIGNED_SSH_PUB_FILE ]]
then
  # Check if signed key is expired
  CREATION_DURATION=$(( $(date +%s) - $(stat -c %W $SIGNED_SSH_PUB_FILE) ))
  if [[ $CREATION_DURATION < $KEY_DURATION ]]
  then
    login_w_key
  else
    sign_key
  fi
else
    sign_key
fi
