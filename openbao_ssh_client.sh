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
[[ -z "$VAULT_ADDR" || -z "$ROLE" || -z "$PRINCIPAL" || -z "$SSH_PUB_FILE" || -z "$SSH_KEY_FILE" || -z "$1" || -z "$LOGIN_METHOD" || -z "$LOGIN_USERNAME" ]] && cat << EOF && exit
Usage: $0 <ssh_arguments>

Following Parameters must be defined in $CONF_INI file
VAULT_ADDR="https://<openbao_url>"
LOGIN_METHOD=<userpass>
LOGIN_USERNAME=<username to login to openbao>
ROLE=<rolename>
PRINCIPAL=<principalname>
SSH_PUB_FILE=<path_to_public_ssh_key>
SSH_KEY_FILE=<path_to_private_ssh_key>
EOF

export VAULT_CLIENT_TIMEOUT=2
export VAULT_ADDR 

# Record SSH arguments
SSH_ARGS=$@

# bao command line
BAO_CMD="bao" 

bao_login(){
  $BAO_CMD login -method=$LOGIN_METHOD username=$LOGIN_USERNAME 
}

# Sign the public key with openbao ssh secrets engine
sign_key(){
  ! check_token && bao_login
  $BAO_CMD write -field=signed_key ssh/sign/${ROLE} public_key="$(cat ${SSH_PUB_FILE})" valid_principals=${PRINCIPAL} > $SIGNED_SSH_PUB_FILE
  chmod 600 $SIGNED_SSH_PUB_FILE
  login_w_key
}

# Check if the signed key is not expired
check_key_is_valid(){
  EXPIRATION_DATE=$(ssh-keygen -L -f ${SIGNED_SSH_PUB_FILE} | sed -nE "/^[ ]*Valid: from/ s/^[ ]*Valid: from .* to (.*)$/\1/p");[[ $(date -d "$EXPIRATION_DATE" +%s) -gt $(date +%s) ]] && true || false
}

check_token(){
  $BAO_CMD token lookup &>/dev/null
}

login_w_key(){
  ssh -o PasswordAuthentication=no -o PubkeyAuthentication=yes -i $SSH_KEY_FILE -o IdentitiesOnly=yes $SSH_ARGS
}

# Check public file access
[[ ! -f $SSH_PUB_FILE ]] && echo "Unable to load $SSH_PUB_FILE" && exit 1


# Check if a signed already exist
if [[ -f $SIGNED_SSH_PUB_FILE ]]
then
  # Check if signed key is expired
  if check_key_is_valid
  then
    # Use the existing signed to login
    login_w_key
  else
    # Request to sign the provided public key
    sign_key
  fi
else
    # Request to sign the provided public key
    sign_key
fi
