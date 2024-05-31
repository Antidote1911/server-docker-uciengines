#!/bin/sh
set -e

if [ -z "$1" ]; then
  # nc -lk -p 8100 -e /stockfish/stockfish
  # tcpserver -c2 0 8100 /stockfish/stockfish
  /stockfish/server -e /stockfish/stockfish -p $STOCKFISH_PORT
else
  # else default to run whatever the user wanted like "bash" or "sh"
  exec "$@"
fi
