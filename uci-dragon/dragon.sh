#!/bin/sh
set -e

if [ -z "$1" ]; then
  # nc -lk -p 8200 -e /dragon/dragon
  # tcpserver -c2 0 8200 /dragon/dragon
  /dragon/server -e /dragon/dragon -p $DRAGON_PORT
else
  # else default to run whatever the user wanted like "bash" or "sh"
  exec "$@"
fi
