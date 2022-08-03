#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <docker file>"
    exit 1
fi

docker build --no-cache -f $1 -t pacsolve ../
