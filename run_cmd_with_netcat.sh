#!/usr/bin/env bash

# Run command/script on a listening port via netcat /!\ DANGEROUS /!\

CMD=${1:-bash -i}
IP=${2:-127.0.0.1}
PORT=${3:-8888}

FIFO_FILE=$(mktemp -u)
mkfifo $FIFO_FILE
trap "rm $FIFO_FILE" SIGINT SIGTERM SIGHUP
cat $FIFO_FILE | $CMD 2>&1 | nc -knl $IP $PORT > $FIFO_FILE
