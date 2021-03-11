#!/bin/bash

# Kill verdaccio server, in case it is still running
killall node

# Start verdaccio
output=$(mktemp "${TMPDIR:-/tmp/}$(basename 0).XXX")
verdaccio --config Configs/npm/verdaccio_config.yaml &> $output &
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


# Login to verdaccio
# See:
# https://stackoverflow.com/questions/23460980/set-up-npm-credentials-over-npm-login-without-reading-input-from-interactively
TOKEN=$(curl -s \
  -H "Accept: application/json" \
  -H "Content-Type:application/json" \
  -X PUT --data '{"name": "admin", "password": "admin"}' \
  http://localhost:4873/-/user/org.couchdb.user:admin 2>&1 | \
  jq -r '.token'
  )
  
npm set //localhost:4873/:_authToken $TOKEN

