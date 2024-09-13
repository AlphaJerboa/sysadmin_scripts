#!/usr/bin/env bash

# Use the base64 to forward its encoded content (and avoid character interpretation) through ansible raw module

REPO=~/repos/servers_setup/inventory/

usage()
{
cat << 'EOF' | sed "s@SCRIPT_NAME@$0@g" # Use @ separator as / might be present in the program path :)
Usage :
  SCRIPT_NAME ansible_host_group "my bash command"

EOF

exit 0
}

IFS='@' read -r HOST_GROUP << EOF
$1
EOF

shift 1

SSH_CMD="$@"
B64_SSH_CMD=$(cat << EOF | base64 -w0 | sed 's/=/\\=/g' # Replace = by \= since raw ansible module interpret it /!\
$SSH_CMD
EOF
)


[[ -z $HOST_GROUP || -z $B64_SSH_CMD ]] && usage
ANSIBLE_HOST_KEY_CHECKING=False ansible -i $REPO $HOST_GROUP -m raw -a "bash <(echo $B64_SSH_CMD | base64 -d)" | tr -d '\r'

