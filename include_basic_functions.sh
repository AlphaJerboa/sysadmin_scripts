#!/bin/bash

# Generic options
# -n option is needed for using ssh inside a while loop !!!! # In some case also add </dev/null
SSH_OPTS="-n -q -o StrictHostKeyChecking=no -o PubkeyAuthentication=yes -o PasswordAuthentication=no" # -i /home/j.marin/.ssh/id_rsa"

# Generic function
die() { #bash only
  [[ $1 ]] || {
     printf >&2 -- "Usage:\n\tdie <message> [return code]\n"
     [[ $- == *i* ]] && return 1 || exit 1 # Test if interactive shell
  }

  printf >&2 -- '%s\n' "$1"
  exit ${2:-1}
}

trim() { #bash only
  echo "$@" | awk '{gsub(/^ +| +$/,"")} {print $0}'
}

getprogramname() {
# Call this function with getprogramname $0 for instance
# Could be replaced by readlink -f $0 ?
PRG=$1
while [ -h "$PRG" ]; do
  ls=`ls -ld "$PRG"`
  link=`expr "$ls" : '.*-> \(.*\)$'`
  if expr "$link" : '/.*' > /dev/null; then
    PRG="$link"
  else
    PRG=`dirname "$PRG"`/"$link"
  fi
done
}

