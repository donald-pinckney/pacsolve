#!/bin/bash

# Kill verdaccio server, in case it is still running
killall node

# Nuke all verdaccio packages
rm -rf ~/.local/share/verdaccio/

# Start verdaccio
output=$(mktemp "${TMPDIR:-/tmp/}$(basename 0).XXX")
verdaccio &> $output &
server_pid=$!
echo "Server pid: $server_pid"
echo "Output: $output"
echo "Wait:"
until grep -q -i 'http addres' $output
do
  if ! ps $server_pid > /dev/null
  then
    echo "The server died" >&2
    exit 1
  fi
  echo -n "."
  sleep 1
done
echo
echo "Server is running!"
rm $output


