#!/usr/bin/env bash
#
# by aphajerboa

set -o pipefail



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

# Variables definition
DOMAINS_LIST=$SCRIPT_PATH/domains.lst
EMAIL=it-team@example.com

# bao function client
bao(){
  VAULT_ADDR="https://vault.example.com" VAULT_SKIP_VERIFY=1 /usr/bin/bao $*
}

! command -v lego >/dev/null && cat <<INSTALL
Please download and install the lego ACME client
Check https://go-acme.github.io/lego/installation/
Bianry available https://github.com/go-acme/lego/releases
INSTALL

[[ ! -f $DOMAINS_LIST ]] && echo "Unable to open $DOMAINS_LIST" && exit 1


cmd_domain_lego(){
  local API_KEY=$(gandi_get_key)
  [[ $? -ne 0 || -z "$API_KEY" ]] && echo "Failure to retrieve gandi api key" && quit 1
  GANDIV5_API_KEY=$API_KEY GANDI_PROPAGATION_TIMEOUT=5 lego --key-type rsa4096 --path $TMP_DIR --email $EMAIL --accept-tos --dns gandiv5 --dns.resolvers 1.1.1.1 $*
}

quit(){
  rm -Rf $TMP_DIR
  exit $1
}
gandi_get_key(){
  bao kv get -format json -mount kv cloud/gandi | jq -r '.data.data.api_key'
}

lego_configuration_extract(){
  VAULT_DATA=$(bao kv get -format json -mount kv services/lego)
  [[ $? -ne 0 || -z "$VAULT_DATA" ]] && echo "Unable to retrieve lego configuration" && quit 1
  LEGO_ACCOUNT_FOLDER=$TMP_DIR/accounts/acme-v02.api.letsencrypt.org/$EMAIL
  LEGO_ACCOUNT_FILE=$LEGO_ACCOUNT_FOLDER/account.json
  LEGO_KEY_FILE=$LEGO_ACCOUNT_FOLDER/keys/$EMAIL.key
  LEGO_CERT_FOLDER=$TMP_DIR/certificates
  mkdir -p $LEGO_ACCOUNT_FOLDER $LEGO_ACCOUNT_FOLDER/keys $LEGO_CERT_FOLDER
  echo "$VAULT_DATA" | jq -r '.data.data.account_json' > $LEGO_ACCOUNT_FILE
  echo "$VAULT_DATA" | jq -r '.data.data.private_key' > $LEGO_KEY_FILE
  [[ ! -f $LEGO_ACCOUNT_FILE || ! -f $LEGO_KEY_FILE ]] && echo "Unable to prepare lego configuration" && quit 1
}

get_certificate_recorded(){
  set -o pipefail
  local DOMAIN=$(echo $1 | cut -f 1 -d ',')
  local VAULT_DATA="$(bao kv get -format json -mount kv services/$DOMAIN)"
  [[ -z "$VAULT_DATA" ]] && return 1
  local CERT="$(echo \"$VAULT_DATA\" | jq -r '.data.data.public_key' 2>/dev/null | base64 -d)" || return 1
  local KEY="$(echo \"$VAULT_DATA\" | jq -r '.data.data.private_key' 2>/dev/null | base64 -d)" || return 1
  [[ -z "$KEY" || -z "$CERT" ]] && return 1
  echo "$CERT" > $LEGO_CERT_FOLDER/$DOMAIN.crt
  echo "$KEY" > $LEGO_CERT_FOLDER/$DOMAIN.key
  return 0
}

upload_certificate(){
  local DOMAIN=$(echo $1 | cut -f 1 -d ',')
  local CRT_FILE="${LEGO_CERT_FOLDER}/${DOMAIN}.crt"
  local KEY_FILE="${LEGO_CERT_FOLDER}/${DOMAIN}.key"
  [[ ! -f "$CRT_FILE" || ! -f "$KEY_FILE" ]] && echo No certificate can be uploaded for $DOMAIN && quit 1
  bao kv put -mount kv services/$DOMAIN public_key="$(cat $CRT_FILE | base64 -w0)" private_key="$(cat $KEY_FILE | base64 -w0)" 
}

create_certificate(){
  local DOMAINS=$1
  # Create options for domains
  DOMAIN_OPTS="-domains $(echo $DOMAINS | sed 's/,/ -domains /g')"
  ! cmd_domain_lego $DOMAIN_OPTS run && echo Unable to create a certificate for $DOMAIN && quit 1
  upload_certificate $DOMAINS
}

renew_certificate(){
  local DOMAINS=$1
  # Create options for domains
  DOMAIN_OPTS="-domains $(echo $DOMAINS | sed 's/,/ -domains /g')"
  local OUT=$(cmd_domain_lego $DOMAIN_OPTS renew 2>&1)
  local RTR=$?
  echo "$OUT" | grep -q ": no renewal.$" && echo "Certificate for $DOMAIN will not expired in the next 30 days, no renewal" && return 0
  [[ $RTR -ne 0 ]] && echo "Error during $DOMAIN renewal" && echo "OUT" && quit 1
  upload_certificate $DOMAINS
}

TMP_DIR=$(mktemp -d)
trap quit SIGINT SIGTERM SIGHUP


lego_configuration_extract

while read DOMAINS
do

  if get_certificate_recorded $DOMAINS
  then
    renew_certificate $DOMAINS
  else
    create_certificate $DOMAINS
  fi
done <<< "$(grep -vE '^$|^#' $DOMAINS_LIST)"

