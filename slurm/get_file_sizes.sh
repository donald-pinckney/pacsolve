#!/bin/bash

cd "$1"

for F in *; do
	if [ -d "$F/package/node_modules" ]; then
		du -s $F/package/node_modules | cut -f1 | tr -d '\n'; 
		echo -e "\t$F";
	else
		echo -e "NA\t$F";
       	fi
done
