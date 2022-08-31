#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <exp_dir> <task_name>"
    exit 1
fi

exp_dir=$1
task_name=$2

unchunked_array_jobs="${task_name}_array_jobs"

rm -f "$unchunked_array_jobs"
touch "$unchunked_array_jobs"

for F in $exp_dir/*; do
    #rm "$F/package/vanilla-lockfile.json"
    #rm "$F/package/auditfix-lockfile.json"
    #rm "$F/package/auditfixforce-lockfile.json"
    #rm "$F/package/maxnpmcveoldness-lockfile.json"
    #rm "$F/package/maxnpmcveoldness_pip-else-npm-lockfile.json"
   
 
    #rm "$F/package/vanilla-lockfile.json.csv"
    #rm "$F/package/auditfix-lockfile.json.csv"
    #rm "$F/package/auditfixforce-lockfile.json.csv"
    #rm "$F/package/maxnpmcveoldness-lockfile.json.csv"
    #rm "$F/package/maxnpmcveoldness_pip-else-npm-lockfile.json.csv"
 
    echo "$F/package/vanilla-lockfile.json" >> "$unchunked_array_jobs"
    echo "$F/package/auditfix-lockfile.json" >> "$unchunked_array_jobs"
    echo "$F/package/auditfixforce-lockfile.json" >> "$unchunked_array_jobs"
    echo "$F/package/maxnpmcveoldness-lockfile.json" >> "$unchunked_array_jobs"
    echo "$F/package/maxnpmcveoldness_pip-else-npm-lockfile.json" >> "$unchunked_array_jobs"
done

split -d -l1000 --verbose "$unchunked_array_jobs" "$unchunked_array_jobs.chunk."
rm "$unchunked_array_jobs"
